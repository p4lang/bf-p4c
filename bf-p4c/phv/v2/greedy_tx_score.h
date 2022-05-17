#ifndef BF_P4C_PHV_V2_GREEDY_TX_SCORE_H_
#define BF_P4C_PHV_V2_GREEDY_TX_SCORE_H_

#include "bf-p4c/phv/v2/tx_score.h"
#include "bf-p4c/phv/v2/kind_size_indexed_map.h"

namespace PHV {
namespace v2 {

/// Vision stores
/// (1) available bits in the PHV v.s. unallocated candidates.
/// (2) TODO: table layout status.
struct Vision {
    /// ContGress represents the hardware gress constraint of a container.
    enum class ContGress {
        ingress,
        egress,
        unassigned,
    };

    /// Map super clusters to required number of containers grouped by kind and size, based
    /// on their baseline allocations.
    ordered_map<const SuperCluster*, KindSizeIndexedMap> sc_cont_required;
    /// The estimated number of containers that will be required for unallocated
    /// super clusters, by gress and size.
    ordered_map<gress_t, KindSizeIndexedMap> cont_required;
    /// Available empty containers. Container without gress assignments will
    /// be counted twice as in ingress and in egress.
    ordered_map<ContGress, KindSizeIndexedMap> cont_available;

    // TODO(yumin): maybe a good idea to add learning quanta and pov bits limit here?
    // ordered_map<gress_t, int> pov_bits_used;
    // ordered_map<gress_t, int> pov_bits_unallocated;

    /// supply vs demand in terms of bits.
    int bits_demand(const PHV::Kind& k) const;
    int bits_supply(const PHV::Kind& k) const;
    bool has_more_than_enough(const PHV::Kind& k) const {
        return bits_supply(k) >= bits_demand(k);
    };
};

std::ostream& operator<<(std::ostream&, const Vision&);

class GreedyTxScoreMaker : public TxScoreMaker {
 private:
    const PhvKit& kit_i;

    Vision vision_i;

    friend class GreedyTxScore;
    friend std::ostream& operator<<(std::ostream&, const Vision&);

 public:
    GreedyTxScoreMaker(const PhvKit& utils,
                       const std::list<ContainerGroup*>& container_groups,
                       const std::list<SuperCluster*>& sorted_clusters,
                       const ordered_map<const SuperCluster*, KindSizeIndexedMap>& baseline);

    TxScore* make(const Transaction& tx) const override;

    /// update @a vision_i.
    void record_commit(const Transaction& tx, const SuperCluster* presliced_sc);

    cstring status() const;
};


/// GreedyTxScore is the default allocation heuristics.
class GreedyTxScore : public TxScore {
 private:
    const GreedyTxScoreMaker* maker_i;
    const Vision* vision_i;

    /// the most precious container bits: normal container and potentially mocha bits
    /// depending on current context.
    int used_L1_bits() const;

    /// mocha and t-phv bits.
    int used_L2_bits() const;

    friend class GreedyTxScoreMaker;

 private:
    /// The number of `newly used` (not used in parent but used in this tx) container bits,
    /// for each kind of container. This should also account for bits that cannot be
    /// used in future allocation, e.g., unused bits packed with solitary fields,
    /// or unused bits of mocha/dark container, should be considered as `used`, because we cannot
    /// pack other fields in those containers. This value unifies many metrics:
    /// (1) overlay_bits: less used bits.
    /// (2) wasted_bits: higher used bits.
    /// (3) clot_bits: less used bits.
    KindSizeIndexedMap used_bits;

    /// The number of containers that were not used in parent, but used in this tx.
    KindSizeIndexedMap used_containers;

    /// The number of containers that their gress was newly assigned in this tx.
    KindSizeIndexedMap n_set_gress;
    KindSizeIndexedMap n_set_parser_gress;
    KindSizeIndexedMap n_set_deparser_gress;
    KindSizeIndexedMap n_mismatched_deparser_gress;
    // TODO
    // {n_mismatched_deparser_gress, weighted_delta[n_mismatched_deparser_gress], false},

    /// For table key fields, how many new bytes will be used, by stages.
    /// This can potentially optimize cross-table key field packing.
    ordered_map<int, int> ixbar_bytes;

    /// the number of overflow created.
    int n_size_overflow = 0;

    /// It is not rare that two allocations have the same number of container size overflow.
    /// Consider this example:
    ///      Supply v.s. demand
    /// H:    30           35
    /// B:    31           95
    /// Assume the width the super cluster is 3. Either allocated to B, or H, the
    /// number of overflow is the same. But overflow problem on B-sized containers are
    /// more severe. This value is used to characterize this property.
    int n_max_overflowed = 0;

    /// For tofino1, as long as there are redundant TPHV bits, always prefer to allocate to tphv
    /// than to overlay on normal containers.
    int n_tphv_on_phv_bits = 0;

    /// the number of new tphv collection used.
    int n_inc_used_tphv_collection = 0;

    /// the delta of the number of bits that will be read by deparser when pov bits are allocated
    /// in a container. It can be 0 when packing with existing pov bits.
    int n_pov_deparser_read_bits = 0;

    /// the delta of the number of bytes that will be read by deparser
    /// when learning fields are allocated to containers.
    int n_deparser_read_learning_bytes = 0;

 public:
    explicit GreedyTxScore(const Vision* vision) : vision_i(vision) {}

    /// @returns true if better
    bool better_than(const TxScore* other) const override;

    /// @returns string representation.
    std::string str() const override;
};

}  // namespace v2
}  // namespace PHV

#endif /* BF_P4C_PHV_V2_GREEDY_TX_SCORE_H_ */
