#ifndef BF_P4C_PHV_V2_UTILS_V2_H_
#define BF_P4C_PHV_V2_UTILS_V2_H_

#include <iterator>
#include <ostream>
#include <sstream>
#include <vector>

#include <boost/optional/optional.hpp>

#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/cstring.h"
#include "bf-p4c/phv/utils/utils.h"

#include "bf-p4c/phv/v2/tx_score.h"
#include "lib/exceptions.h"

namespace PHV {
namespace v2 {

/// map field slices to their starting position in a container.
using FieldSliceAllocStartMap = ordered_map<PHV::FieldSlice, int>;
std::ostream& operator<<(std::ostream& out, const FieldSliceAllocStartMap& fs);

/// type of container groups grouped by sizes.
using ContainerGroupsBySize = std::map<PHV::Size, std::vector<ContainerGroup>>;

/// ErrorCode classifies all kinds of PHV allocation error.
/// NOTE: when adding a new error, remember to update to_str function.
enum class ErrorCode {
    /// The container bits has been occupied by allocated fields.
    NOT_ENOUGH_SPACE,
    /// The candidate list of AllocSlices that are packed into a specific container with
    /// specific starting positions will violate action constraints.
    /// NOTE: this error does not necessarily mean candidates are invalid. For example,
    /// the reason could be that source operands are not allocated accordingly.
    CANNOT_PACK_CANDIDATES,
    /// The candidate list of AllocSlices, together with AllocSlices that has already been
    /// assigned to the container, will violate action constraints.
    CANNOT_PACK_WITH_ALLOCATED,
    /// container type constraint not satisfied, e.g., try non-mocha field against mocha container.
    CONTAINER_TYPE_MISMATCH,
    /// container gress assignment mismatches field gress.
    CONTAINER_GRESS_MISMATCH,
    /// mixed parser write mode for a parser group.
    CONTAINER_PARSER_WRITE_MODE_MISMATCH,
    /// packing extracted with uninitialized is not allowed.
    CONTAINER_PARSER_PACKING_INVALID,
    /// violating max container bytes constraint on field.
    FIELD_MAX_CONTAINER_BYTES_EXCEEDED,
    /// no container can be used to allocate candidate slices.
    NO_CONTAINER_AVAILABLE,
    /// when allocate the aligned cluster, no valid start position was found.
    ALIGNED_CLUSTER_NO_VALID_START,
    /// aligned cluster cannot be allocated to any container group.
    ALIGNED_CLUSTER_CANNOT_BE_ALLOCATED,
    /// super cluster does not any have suitable container group width.
    NO_VALID_CONTAINER_SIZE,
    /// no valid alignment was found for the candidate super cluster
    NO_VALID_SC_ALLOC_ALIGNMENT,
    /// failed to allocate wide arithmetic slice lists
    WIDE_ARITH_ALLOC_FAILED,
    /// no slicing has been found by slicing iterator.
    NO_SLICING_FOUND,
    /// when copacker has identified invalid allocation that sources can never be
    /// packed correctly.
    INVALID_ALLOC_FOUND_BY_COPACKER,
};

/// convert @p to string.
cstring to_str(const ErrorCode& e);

/// AllocError contains a code of the failure reason and detailed messages.
/// The additional cannot_allocate_sl may be specified if some allocation process
/// has found that allocation cannot proceed because a slice list cannot be allocated,
/// which is usually caused by field packing in the slice that violates action phv constraints.
struct AllocError {
    ErrorCode code;
    cstring msg;
    const SuperCluster::SliceList* cannot_allocate_sl = nullptr;
    explicit AllocError(ErrorCode code) : code(code), msg("") {}
    AllocError(ErrorCode code, cstring msg) : code(code), msg(msg) {}
    std::string str() const {
        std::stringstream ss;
        ss << "code:" << to_str(code) << ", msg:" << msg;
        if (cannot_allocate_sl) {
            ss << " => cannot allocate " << cannot_allocate_sl;
        }
        return ss.str();
    }
};

template<class T>
AllocError& operator<<(AllocError& e, const T& v) {
    std::stringstream ss;
    ss << v;
    e.msg += ss.str();
    return e;
}

/// AllocResult is the most common return type of an allocation function. It is either an error
/// or a PHV::Transaction if succeeded.
struct AllocResult {
    const AllocError* err = nullptr;
    boost::optional<PHV::Transaction> tx;
    explicit AllocResult(const AllocError* err): err(err) {}
    explicit AllocResult(const Transaction& tx): tx(tx) {}
    bool ok() const { return err == nullptr; }
    std::string err_str() const;
    std::string tx_str(cstring prefix) const;
};

/// ScAllocAlignment is the alignment arrangement for a super cluster based on its alignment
/// constraints of slice lists.
/// TODO(yumin): @a slice_starts is redundant, cluster_starts.at(sc->aligned_cluster(fs)) is
/// equivalent.
struct ScAllocAlignment {
    /// a slice_alignment maps field slice to start bit location in a container.
    ordered_map<FieldSlice, int> slice_starts;
    /// a cluster_alignment maps aligned cluster to start bit location in a container.
    ordered_map<const AlignedCluster*, int> cluster_starts;
    /// @returns merged alignment constraint if no conflict was found.
    boost::optional<ScAllocAlignment> merge(const ScAllocAlignment& other) const;
    /// @returns pretty print string for the alignment of @p sc.
    cstring pretty_print(cstring prefix, const SuperCluster* sc) const;
    /// @returns true if there is no alignment scheduled: cluster without slice lists.
    bool empty() const { return slice_starts.empty(); }
};

/// Factory function to build up to @p max_n alignment for @p sc in @p width container group.
/// The process is a DFS on all combinations of different alignments of all slice lists within
/// the cluster @p sc. The DFS order can be tuned by providing a non-null @p sl_alloc_order.
/// NOTE: when @p sl_order is provided, it must have exactly all the slice list in @p sc and
/// no more.
std::vector<ScAllocAlignment> make_sc_alloc_alignment(
    const SuperCluster* sc, const PHV::Size width, const int max_n,
    const std::list<const SuperCluster::SliceList*>* sl_order = nullptr);

/// a collection of allocation configurations that balances speed and performance of allocation.
struct SearchConfig {
    int n_max_sc_alignments = 8;

    bool stop_first_succ_sc_alignment = true;

    bool stop_first_succ_fs_alignment = false;

    bool stop_first_succ_empty_normal_container = false;
};

/// ScoreContext is the allocation context that is updated and passed down during allocation.
class ScoreContext {
    /// current super cluster that we are trying to allocate.
    const SuperCluster* sc_i = nullptr;

    /// current container group that we are trying to allocate.
    const ContainerGroup* cont_group_i = nullptr;

    /// slice lists are better to be allocated in this order.
    const std::list<const SuperCluster::SliceList*>* sl_alloc_order_i = {};

    /// decided allocation alignment under current context.
    const ScAllocAlignment* alloc_alignment_i = nullptr;

    /// factory for allocation score.
    const TxScoreMaker* score_i = nullptr;

    /// t is the log level.
    int t_i = 0;

    /// search time related parameters.
    const SearchConfig* search_config_i = new SearchConfig();

 private:
    static constexpr const char* tab_table[] = {
        "", " ", "  ", "   ", "    ", "     ", "      ", "       ", "        ",
    };
    static constexpr int max_log_level = sizeof(tab_table) / sizeof(tab_table[0]) - 1;

 public:
    ScoreContext() {}

    const SuperCluster* sc() const {
        BUG_CHECK(sc_i, "sc not added in ctx.");
        return sc_i;
    }
    ScoreContext with_sc(const SuperCluster* sc) const {
        auto cloned = *this;
        cloned.sc_i = sc;
        return cloned;
    }

    const ContainerGroup* cont_group() const {
        BUG_CHECK(cont_group_i, "container group not added in ctx.");
        return cont_group_i;
    }
    ScoreContext with_cont_group(const ContainerGroup* cont_group) const {
        auto cloned = *this;
        cloned.cont_group_i = cont_group;
        return cloned;
    }

    const std::list<const SuperCluster::SliceList*>* sl_alloc_order() const {
        BUG_CHECK(sl_alloc_order_i, "sl alloc order not added in ctx.");
        return sl_alloc_order_i;
    }
    ScoreContext with_sl_alloc_order(
            const std::list<const SuperCluster::SliceList*>* order) const {
        auto cloned = *this;
        cloned.sl_alloc_order_i = order;
        return cloned;
    }

    const ScAllocAlignment* alloc_alignment() const {
        BUG_CHECK(alloc_alignment_i, "alloc alignment not added in ctx.");
        return alloc_alignment_i;
    }
    ScoreContext with_alloc_alignment(const ScAllocAlignment* alignment) const {
        auto cloned = *this;
        cloned.alloc_alignment_i = alignment;
        return cloned;
    }

    const TxScoreMaker* score() const {
        BUG_CHECK(score_i, "score not added in ctx.");
        return score_i;
    }
    ScoreContext with_score(const TxScoreMaker* score) const {
        auto cloned = *this;
        cloned.score_i = score;
        return cloned;
    }

    int t() const { return t_i; }
    cstring t_tabs() const {
        return tab_table[t_i];
    }
    ScoreContext with_t(int t) const {
        if (t > max_log_level) t = max_log_level;
        auto cloned = *this;
        cloned.t_i = t;
        return cloned;
    }

    const SearchConfig* search_config() const { return search_config_i; }
    ScoreContext with_search_config(const SearchConfig* c) const {
        auto cloned = *this;
        cloned.search_config_i = c;
        return cloned;
    }
};

}  // namespace v2
}  // namespace PHV

#endif /* BF_P4C_PHV_V2_UTILS_V2_H_ */
