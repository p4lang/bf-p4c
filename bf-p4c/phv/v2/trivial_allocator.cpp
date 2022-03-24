#include "bf-p4c/phv/v2/trivial_allocator.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/phv/v2/allocator_base.h"
#include "bf-p4c/phv/v2/tx_score.h"
#include "bf-p4c/phv/v2/utils_v2.h"

namespace PHV {
namespace v2 {

namespace {

Logging::FileLog* createFileLog(int pipeId, const cstring& prefix, int loglevel) {
    if (!LOGGING(loglevel)) return nullptr;

    auto filename = Logging::PassManager::getNewLogFileName(prefix);
    return new Logging::FileLog(pipeId, filename, Logging::Mode::AUTO);
}

}  // namespace

TrivialAllocator::PhvStatus::PhvStatus() {
    for (const auto& s : {PHV::Size::b8, PHV::Size::b16, PHV::Size::b32}) {
        next_container_idx[s] = 0;
    }
}

PHV::Container TrivialAllocator::PhvStatus::next_container(PHV::Size s) const {
    BUG_CHECK(next_container_idx.count(s), "cannot find next container for this size: %1%", s);
    return PHV::Container(PHV::Type(PHV::Kind::normal, s), unsigned(next_container_idx.at(s)));
}

void TrivialAllocator::PhvStatus::inc_next_container(PHV::Size s) {
    BUG_CHECK(next_container_idx.count(s), "cannot find next container for this size: %1%", s);
    next_container_idx[s]++;
}

TrivialAllocator::TrivialAllocator(const PHV::AllocUtils& utils, PhvInfo& phv, int pipe_id)
    : utils_i(utils), phv_i(phv), pipe_id_i(pipe_id) {}

std::vector<PHV::AllocSlice> TrivialAllocator::gen_alloc_slices_from_tx(
    const PHV::Transaction& tx, PhvStatus& phv_status) const {
    std::vector<PHV::AllocSlice> rst;
    for (const auto& container_status : tx.getTransactionStatus()) {
        const auto& original_container = container_status.first;
        const auto& alloc_status = container_status.second;
        if (alloc_status.slices.empty()) {
            continue;
        }
        PHV::Container c = phv_status.next_container(original_container.type().size());
        phv_status.inc_next_container(original_container.type().size());
        for (const PHV::AllocSlice& slice : alloc_status.slices) {
            auto* field = phv_i.field(slice.field()->id);
            rst.push_back(PHV::AllocSlice(field, c, slice.field_slice().lo,
                                          slice.container_slice().lo,
                                          slice.container_slice().size(), {}));
        }
    }
    return rst;
}

void TrivialAllocator::bind_alloc_slices(const std::vector<PHV::AllocSlice>& slices) {
    for (const auto& slice : slices) {
        auto* field = phv_i.field(slice.field()->id);
        field->add_alloc(slice);
        phv_i.add_container_to_field_entry(slice.container(), field);
    }
}

ContainerGroupsBySize TrivialAllocator::make_container_groups_merged_by_size() const {
    ContainerGroupsBySize rv;

    // merge container groups of the same size to one group.
    const PhvSpec& phv_spec = Device::phvSpec();
    for (const PHV::Size s : phv_spec.containerSizes()) {
        bitvec containers;
        for (auto group : phv_spec.mauGroups(s)) {
            containers |= group;
        }
        // Create group.
        rv[s].emplace_back(PHV::ContainerGroup(s, containers));
    }
    return rv;
}

const TrivialAllocator::PartialAllocResult* TrivialAllocator::slice_and_allocate_sc(
    const Allocation& empty_alloc, const PHV::SuperCluster* sc, PhvStatus phv_status,
    const ContainerGroupsBySize& container_groups, const int max_slicings,
    std::ostream* history) const {
    const auto base = AllocatorBase(utils_i);
    auto slicing_ctx = utils_i.make_slicing_ctx(sc);
    slicing_ctx->set_minimal_packing_mode(true);
    auto* search_config = new SearchConfig();
    search_config->n_max_sc_alignments = 8;
    search_config->stop_first_succ_sc_alignment = true;
    search_config->stop_first_succ_fs_alignment = true;
    search_config->stop_first_succ_empty_normal_container = true;

    // setup allocator context.
    auto ctx = PHV::v2::ScoreContext()
                   .with_score(new MinPackTxScoreMaker())
                   .with_search_config(search_config)
                   .with_t(0);

    int n_tried = 0;
    AllocError* last_err = new AllocError(ErrorCode::NO_SLICING_FOUND);
    *last_err << "found unsatisfiable constraints.";
    PartialAllocResult* rst = nullptr;
    slicing_ctx->iterate([&](std::list<PHV::SuperCluster*> sliced) {
        n_tried++;
        if (LOGGING(3)) {
            LOG3("Clusters of slicing-attempt-" << n_tried << ":");
            for (auto* sc : sliced) LOG_DEBUG4(sc);
        }
        std::vector<AllocSlice> this_split_alloc_slices;
        auto this_split_status = phv_status;
        for (const auto* sc : sliced) {
            if (utils_i.is_clot_allocated(utils_i.clot, *sc)) {
                LOG3("skip clot allocated cluster: " << sc->uid);
                continue;
            }
            auto rst = base.try_sliced_super_cluster(ctx, empty_alloc, sc, container_groups);
            if (rst.ok()) {
                for (const auto& new_slice :
                         gen_alloc_slices_from_tx(*rst.tx, this_split_status)) {
                    this_split_alloc_slices.push_back(new_slice);
                }
            } else {
                last_err = new AllocError(rst.err->code);
                LOG3("slicing-attempt-" << n_tried << " failed, while allocating: " << sc);
                *last_err << " failed when allocating this sliced " << sc;
                // found a slice list that cannot be allocated because packing issue.
                if (rst.err->code == ErrorCode::CANNOT_PACK_CANDIDATES &&
                    rst.err->cannot_allocate_sl) {
                    LOG3("Found cannot_allocate slice list: " << rst.err->cannot_allocate_sl);
                    *last_err << "Found unsatisfiable action constraints in this list: "
                              << rst.err->cannot_allocate_sl;
                    slicing_ctx->invalidate(rst.err->cannot_allocate_sl);
                } else {
                    *last_err << rst.err_str();
                }
                return n_tried < max_slicings;
            }
        }
        // history logging
        if (history) {
            *history << "Successfully Allocated\n";
            *history << "By slicing into the following superclusters:\n";
            for (auto* sc : sliced) {
                *history << sc << "\n";
            }
            *history << "Allocation Decisions: \n";
            for (const auto& s : this_split_alloc_slices) {
                *history << "allocate: " << s.container() << "[" << s.container_slice().lo << ":"
                         << s.container_slice().hi << "] <- "
                         << FieldSlice(s.field(), s.field_slice()) << "\n";
            }
            *history << "\n";
        }
        LOG3("slicing-attempt-" << n_tried << " succeeded. ");
        rst = new PartialAllocResult(this_split_alloc_slices, this_split_status);
        return false;
    });
    if (rst) {
        return rst;
    }
    return new PartialAllocResult(last_err);
}

bool TrivialAllocator::allocate(const std::list<PHV::SuperCluster*>& clusters) {
    LOG1("Run TrivialAllocator");

    // XXX(yumin): it seems okay to ignore strided headers in trivial allocator for now.
    // but we should add support for them in the future, to check whether they can be
    // allocated or not.
    // create strided clusters
    // clusters = create_strided_clusters(utils_i.strided_headers, clusters);

    PHV::ConcreteAllocation empty_alloc = PHV::ConcreteAllocation(phv_i, utils_i.uses);
    auto container_groups = make_container_groups_merged_by_size();
    const int max_slicing_try = 128;
    std::stringstream history;
    PhvStatus phv_status;
    bool ok = true;
    for (auto* sc : clusters) {
        LOG3("Allocating: \n " << sc);
        history << "Allocating: \n" << sc;
        auto rst = slice_and_allocate_sc(empty_alloc, sc, phv_status, container_groups,
                                         max_slicing_try, &history);
        if (!rst->ok()) {
            history << "Trivial Allocation Failed because:" << rst->err->str() << "\n";
            ::error("Trivial allocation failed. Cannot allocate %1%Reason: %2%",
                    cstring::to_cstring(sc), rst->err->str());
            ok = false;
            break;
        }
        phv_status = rst->phv_status;
        bind_alloc_slices(rst->alloc_slices);
        LOG3(">>>>>>> Allocation Succeeded: " << sc);
    }

    if (ok) {
        LOG3("Trivial Allocation Successfully Allocated All Clusters.");
        history << "Trivial Allocation Successfully Allocated All Clusters.\n";
        PHV::AllocUtils::sort_and_merge_alloc_slices(phv_i);
        phv_i.set_done(true);
    }

    // TODO(yumin): complete history logs to include slicing and result.
    // print out history logs
    auto logfile = createFileLog(pipe_id_i, "phv_trivial_allocation_history_", 1);
    LOG1("Trivial Allocation history");
    LOG1(history.str());
    Logging::FileLog::close(logfile);
    return ok;
}

bool TrivialAllocator::can_be_allocated(const Allocation& empty_alloc,
                                        const PHV::SuperCluster* sc,
                                        const int max_slicings) const {
    const auto rst = slice_and_allocate_sc(empty_alloc, sc, PhvStatus(),
                                           make_container_groups_merged_by_size(), max_slicings);
    return rst->ok();
}

}  // namespace v2
}  // namespace PHV
