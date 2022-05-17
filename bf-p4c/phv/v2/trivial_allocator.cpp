#include "bf-p4c/phv/v2/trivial_allocator.h"

#include <sstream>

#include "bf-p4c/device.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/slicing/types.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/phv/v2/allocator_base.h"
#include "bf-p4c/phv/v2/tx_score.h"
#include "bf-p4c/phv/v2/utils_v2.h"

namespace PHV {
namespace v2 {

namespace {

Logging::FileLog* trivial_allocator_file_log(int pipeId, int loglevel) {
    if (!LOGGING(loglevel)) return nullptr;
    auto filename = Logging::PassManager::getNewLogFileName("phv_trivial_allocation_history_");
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

TrivialAllocator::TrivialAllocator(const PhvKit& kit, PhvInfo& phv, int pipe_id)
    : kit_i(kit), phv_i(phv), pipe_id_i(pipe_id) {}

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

cstring TrivialAllocator::make_error_msg(const SuperCluster* sc,
                                         const PartialAllocResult* rst) const {
    std::stringstream unsat_err;
    unsat_err << "Trivial allocator has found unsatisfiable constraints.\n";
    unsat_err << "Error code: " << to_str(rst->err->code) << "\n";
    unsat_err << "In this super clusters: " << sc << "\n";
    if (rst->err->code != ErrorCode::NO_SLICING_FOUND) {
        unsat_err << "(Trace) Last error we saw during allocation is: " << rst->err->msg;
        if (rst->err->code == ErrorCode::ACTION_CANNOT_BE_SYNTHESIZED &&
            rst->err->reslice_required) {
            unsat_err << "Please check action(s) that write to these slice lists";
        }
    }
    return unsat_err.str();
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

TrivialAllocator::PreSlicingResult TrivialAllocator::pre_slice(const Allocation& empty_alloc,
                                                               SuperCluster* sc,
                                                               const int max_pre_slicing_try,
                                                               bool baseline_mode) const {
    const bool try_minimal_packing_first = !baseline_mode;
    PreSlicingResult rst;
    rst.sliced = {sc};
    rst.invalid = sc;
    int n_pre_slicing_tried = 0;
    auto pre_slicing_ctx = kit_i.make_slicing_ctx(sc);
    // max-packing mode with loose action constraints checks.
    pre_slicing_ctx->set_config(Slicing::IteratorConfig{false, true, true});
    pre_slicing_ctx->iterate([&](std::list<SuperCluster*> sliced) {
        n_pre_slicing_tried++;
        LOG3("Pre-slicing-attempt-" << n_pre_slicing_tried);
        rst.sliced = std::move(sliced);
        rst.invalid = nullptr;
        rst.baseline_cont_req.clear();
        for (auto* sc : rst.sliced) {
            LOG3("Check possibility of allocation of " << sc);
            auto sc_rst = slice_and_allocate_sc(empty_alloc, sc, PhvStatus(),
                                                make_container_groups_merged_by_size(),
                                                try_minimal_packing_first, max_pre_slicing_try);
            if (!sc_rst->ok()) {
                LOG3("Unallocatable cluster found: SC-" << sc->uid);
                rst.invalid = sc;
                return n_pre_slicing_tried < max_pre_slicing_try;
            }
            LOG3("This is an allocatable cluster: SC-" << sc->uid);
            // update baseline for this pre-sliced cluster.
            rst.baseline_cont_req[sc] = {};
            ordered_map<Container, ordered_set<AllocSlice>> container_slices;
            for (const auto& sl : sc_rst->alloc_slices) {
                container_slices[sl.container()].insert(sl);
            }
            for (const auto& c_slices : container_slices) {
                PHV::Kind updated_kind = Kind::normal;
                if (Device::phvSpec().hasContainerKind(PHV::Kind::mocha) &&
                    std::all_of(
                        c_slices.second.begin(), c_slices.second.end(),
                        [](const AllocSlice& sl) { return sl.field()->is_mocha_candidate(); })) {
                    updated_kind = Kind::mocha;
                }
                if (Device::phvSpec().hasContainerKind(PHV::Kind::tagalong) &&
                    std::all_of(c_slices.second.begin(), c_slices.second.end(),
                                [&](const AllocSlice& sl) {
                                    return sl.field()->is_tphv_candidate(kit_i.uses);
                                })) {
                    updated_kind = Kind::tagalong;
                }
                rst.baseline_cont_req[sc][{updated_kind, c_slices.first.type().size()}]++;
            }
        }
        // found one valid slicing
        return false;
    });
    return rst;
}

const TrivialAllocator::PartialAllocResult* TrivialAllocator::slice_and_allocate_sc(
    const Allocation& empty_alloc, const PHV::SuperCluster* sc, PhvStatus phv_status,
    const ContainerGroupsBySize& container_groups, bool minimal_packing_slicing,
    const int max_slicings, std::ostream* history) const {
    const auto base = AllocatorBase(kit_i);
    auto slicing_ctx = kit_i.make_slicing_ctx(sc);
    // use @p minimal_packing_slicing mode with strict action packing checking mode.
    slicing_ctx->set_config(Slicing::IteratorConfig{minimal_packing_slicing, false, true});
    auto* search_config = new SearchConfig();
    search_config->n_dfs_steps_sc_alloc = 256;
    search_config->n_best_of_sc_alloc = 1;  // trivial alloc stops at the first ok solution.
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
            for (auto* sc : sliced) LOG3(sc);
        }
        std::vector<AllocSlice> this_split_alloc_slices;
        auto this_split_status = phv_status;
        for (const auto* sc : sliced) {
            if (kit_i.is_clot_allocated(kit_i.clot, *sc)) {
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
                // found a slice list that cannot be allocated because of packing issue.
                if (rst.err->code == ErrorCode::ACTION_CANNOT_BE_SYNTHESIZED &&
                    rst.err->reslice_required) {
                    for (const auto* sl : *rst.err->reslice_required) {
                        LOG3("Found invalid packing slice list: " << sl);
                        *last_err << "Found unsatisfiable action constraints in this list: " << sl
                                  << "\n";
                    }
                    for (const auto* sl : *rst.err->reslice_required) {
                        slicing_ctx->invalidate(sl);
                    }
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
    // clusters = create_strided_clusters(kit_i.strided_headers, clusters);

    PHV::ConcreteAllocation empty_alloc = PHV::ConcreteAllocation(phv_i, kit_i.uses);
    auto container_groups = make_container_groups_merged_by_size();
    const int max_try_alloc_slicing_try = 256;
    std::stringstream history;
    PhvStatus phv_status;
    bool ok = true;
    for (auto* unsliced_sc : clusters) {
        // TODO(yumin): we can integrate pre_slice into this allocation progress by
        // taking copy of phv status and handle errors correctly. This will save us
        // some time because the validation process inside pre_slice are basically calling
        // slice_and_allocate_sc.
        LOG3("Trying to pre-slice original (unsliced) cluster: " << unsliced_sc);
        auto pre_sliced = pre_slice(empty_alloc, unsliced_sc, max_try_alloc_slicing_try);
        if (LOGGING(3)) {
            LOG3("Pre-slicing result of super cluster uid " << unsliced_sc->uid << ":");
            for (const auto* sc : pre_sliced.sliced) {
                LOG3(sc);
            }
            if (pre_sliced.invalid) {
                LOG3("But we found an unallocatable cluster: " << pre_sliced.invalid);
            }
        }
        if (pre_sliced.invalid) {
            auto rst = slice_and_allocate_sc(empty_alloc, pre_sliced.invalid, phv_status,
                                             container_groups,
                                             true, max_try_alloc_slicing_try, &history);
            BUG_CHECK(!rst->ok(), "invalid supercluster can be allocated?");
            const cstring err_log = make_error_msg(unsliced_sc, rst);
            history << err_log;
            ::error(err_log);
            ok = false;
            break;
        }
        for (const auto* sc : pre_sliced.sliced) {
            LOG3("Allocating: \n " << sc);
            history << "Allocating: \n" << sc;
            auto rst = slice_and_allocate_sc(empty_alloc, sc, phv_status, container_groups,
                                             true, max_try_alloc_slicing_try, &history);
            if (!rst->ok()) {
                const cstring err_log = make_error_msg(sc, rst);
                history << err_log;
                ::error(err_log);
                ok = false;
                break;
            }
            phv_status = rst->phv_status;
            bind_alloc_slices(rst->alloc_slices);
            LOG3(">>>>>>> pre-sliced cluster allocation Succeeded: " << sc);
        }
        if (!ok) break;
    }

    if (ok) {
        LOG3("Trivial Allocation Successfully Allocated All Clusters.");
        history << "Trivial Allocation Successfully Allocated All Clusters.\n";
        PhvKit::sort_and_merge_alloc_slices(phv_i);
        phv_i.set_done(true);
    }

    auto logfile = trivial_allocator_file_log(pipe_id_i, 1);
    LOG1("Trivial Allocation history");
    LOG1(history.str());
    Logging::FileLog::close(logfile);
    return ok;
}

bool TrivialAllocator::can_be_allocated(const Allocation& empty_alloc,
                                        const PHV::SuperCluster* sc,
                                        const int max_slicings) const {
    const auto rst = slice_and_allocate_sc(
        empty_alloc, sc, PhvStatus(), make_container_groups_merged_by_size(), true, max_slicings);
    return rst->ok();
}

}  // namespace v2
}  // namespace PHV
