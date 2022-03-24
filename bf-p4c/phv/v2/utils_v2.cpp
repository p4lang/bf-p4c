#include <bf-p4c/phv/v2/utils_v2.h>
#include "bf-p4c/phv/utils/utils.h"
#include "lib/exceptions.h"

namespace PHV {
namespace v2 {

cstring to_str(const ErrorCode& e) {
    using ec = ErrorCode;
    switch (e) {
        case ec::NOT_ENOUGH_SPACE:
            return "NOT_ENOUGH_SPACE";
        case ec::CANNOT_PACK_CANDIDATES:
            return "CANNOT_PACK_CANDIDATES(found unsatisfiable action constraints)";
        case ec::CANNOT_PACK_WITH_ALLOCATED:
            return "CANNOT_PACK_WITH_ALLOCATED";
        case ec::CONTAINER_TYPE_MISMATCH:
            return "CONTAINER_TYPE_MISMATCH";
        case ec::CONTAINER_GRESS_MISMATCH:
            return "CONTAINER_GRESS_MISMATCH";
        case ec::CONTAINER_PARSER_WRITE_MODE_MISMATCH:
            return "CONTAINER_PARSER_WRITE_MODE_MISMATCH";
        case ec::CONTAINER_PARSER_PACKING_INVALID:
            return "CONTAINER_PARSER_PACKING_INVALID";
        case ec::FIELD_MAX_CONTAINER_BYTES_EXCEEDED:
            return "FIELD_MAX_CONTAINER_BYTES_EXCEEDED";
        case ec::NO_CONTAINER_AVAILABLE:
            return "NO_CONTAINER_AVAILABLE";
        case ec::ALIGNED_CLUSTER_NO_VALID_START:
            return "ALIGNED_CLUSTER_NO_VALID_START";
        case ec::ALIGNED_CLUSTER_CANNOT_BE_ALLOCATED:
            return "ALIGNED_CLUSTER_CANNOT_BE_ALLOCATED";
        case ec::NO_VALID_CONTAINER_SIZE:
            return "NO_VALID_CONTAINER_SIZE";
        case ec::NO_VALID_SC_ALLOC_ALIGNMENT:
            return "NO_VALID_SC_ALLOC_ALIGNMENT";
        case ec::WIDE_ARITH_ALLOC_FAILED:
            return "WIDE_ARITH_ALLOC_FAILED";
        case ec::NO_SLICING_FOUND:
            return "NO_SLICING_FOUND";
        default:
            BUG("unimplemented errorcode: %1%", int(e));
    }
}

constexpr const char* ScoreContext::tab_table[];
constexpr int ScoreContext::max_log_level;

namespace {

std::vector<ScAllocAlignment> make_slicelist_alignment(const SuperCluster* sc,
                                                       const PHV::Size width,
                                                       const SuperCluster::SliceList* sl) {
    std::vector<ScAllocAlignment> rst;
    const auto valid_list_starts = sc->aligned_cluster(sl->front()).validContainerStart(width);
    for (const int le_offset_start : valid_list_starts) {
        int le_offset = le_offset_start;
        ScAllocAlignment curr;
        bool success = true;
        for (auto& slice : *sl) {
            const AlignedCluster& cluster = sc->aligned_cluster(slice);
            auto valid_start_options = cluster.validContainerStart(width);

            // if the slice 's cluster cannot be placed at the current offset.
            if (!valid_start_options.getbit(le_offset)) {
                success = false;
                break;
            }

            // Return if the slice is part of another slice list but was previously
            // placed at a different start location.
            if (curr.cluster_starts.count(&cluster) &&
                curr.cluster_starts.at(&cluster) != le_offset) {
                success = false;
                break;
            }

            // Otherwise, update the alignment for this slice's cluster.
            curr.cluster_starts[&cluster] = le_offset;
            curr.slice_starts[slice] = le_offset;
            le_offset += slice.size();
        }
        if (success) {
            rst.push_back(curr);
        }
    }
    return rst;
}

}  // namespace


std::string AllocResult::err_str() const {
    BUG_CHECK(err, "cannot call err_str when err does not exists");
    std::stringstream ss;
    ss << err->str();
    return ss.str();
}

std::string AllocResult::tx_str(cstring prefix) const {
    BUG_CHECK(tx, "cannot call tx_str when tx does not exists");
    std::stringstream ss;
    cstring new_line = "";
    for (const auto& container_status : tx->getTransactionStatus()) {
        const auto& status = container_status.second;
        for (const auto& a : status.slices) {
            auto fs = PHV::FieldSlice(a.field(), a.field_slice());
            ss << new_line << prefix << "allocate: " << a.container() << "["
               << a.container_slice().lo << ":" << a.container_slice().hi << "] <- " << fs
               << " @[" << a.getEarliestLiveness() << "," << a.getLatestLiveness() << "]";
            new_line = "\n";
        }
    }
    return ss.str();
}

boost::optional<ScAllocAlignment> ScAllocAlignment::merge(const ScAllocAlignment& other) const {
    ScAllocAlignment rst;
    for (auto& alignment : std::vector<const ScAllocAlignment*>{this, &other}) {
        // wont' be conflict
        for (auto& sl_start : alignment->slice_starts) {
            rst.slice_starts.emplace(sl_start.first, sl_start.second);
        }
        // may conflict
        for (auto& cluster_start : alignment->cluster_starts) {
            const auto* cluster = cluster_start.first;
            const int start = cluster_start.second;
            if (rst.cluster_starts.count(cluster) &&
                rst.cluster_starts[cluster] != start) {
                return boost::none;
            }
            rst.cluster_starts[cluster] = start;
        }
    }
    return rst;
}

/// Compute super cluster alignment of @p sc for @p width containers.
/// Example
/// Super Cluster:
/// 1. [f0<9> ^0, f1<8> ^1]
/// 2. [f2<1> ^0, f3<8> ^1]
/// Rot: [ Aligned:[f3, f1] ]
/// => 32-bit container
/// 1: *0*, 8, 16
/// 2: 0, *8*, 16
/// Because f3 and f1 must be perfectly aligned, there are only two possible cluster alignment:
///  (1) slice list 1 at 0, 2 at 8
///  (2) slice list 1 at 8, 2 at 16.
std::vector<ScAllocAlignment> make_sc_alloc_alignment(
    const SuperCluster* sc,
    const PHV::Size width,
    const int max_n,
    const std::list<const SuperCluster::SliceList*>* sl_order) {
    // collect all possible alignments for each slice_list
    std::vector<std::vector<ScAllocAlignment>> all_alignments;
    if (sl_order == nullptr) {
        sl_order = new std::list<const SuperCluster::SliceList*>{
            sc->slice_lists().begin(), sc->slice_lists().end()};
    }
    for (const auto* sl : *sl_order) {
        auto curr_sl_alignment = make_slicelist_alignment(sc, width, sl);
        if (curr_sl_alignment.size() == 0) {
            LOG5("FAIL to build alignment for " << sl);
            break;
        }
        all_alignments.push_back(curr_sl_alignment);
    }
    // not all slice list has valid alignment, simply skip.
    if (all_alignments.size() < sc->slice_lists().size()) {
        return {};
    }

    // build alignment for the super cluster by trying all (limited to max_n)
    // possible combination of alignments of slice lists, by picking one alignment
    // for each slice lists, while making sure none of them are conflicting with others.
    std::vector<ScAllocAlignment> rst;
    std::function<void(int depth, const ScAllocAlignment& curr)> dfs =
        [&](int depth, const ScAllocAlignment& curr)  {
            if (depth == int(all_alignments.size())) {
                rst.push_back(curr);
                return;
            }
            for (const auto& align_choice : all_alignments[depth]) {
                auto next = curr.merge(align_choice);
                if (next) {
                    dfs(depth + 1, *next);
                }
                if (int(rst.size()) == max_n) {
                    return;
                }
            }
        };
    dfs(0, ScAllocAlignment());
    return rst;
}

cstring ScAllocAlignment::pretty_print(cstring prefix, const SuperCluster* sc) const {
    std::stringstream ss;
    cstring new_line = "";
    for (const auto* sl : sc->slice_lists()) {
        ss << new_line << prefix << "[";
        new_line = "\n";
        cstring sep = "";
        for (const auto& fs : *sl) {
            ss << sep << "{" << fs << ", " << slice_starts.at(fs) << "}";
            sep = ", ";
        }
        ss << "]";
    }
    return ss.str();
}

std::ostream& operator<<(std::ostream& out, const FieldSliceAllocStartMap& fs) {
    for (const auto& kv : fs) {
        out << kv.first.field()->name << " " << kv.first.range() << ":" << kv.second << ";";
    }
    return out;
}

}  // namespace v2
}  // namespace PHV

