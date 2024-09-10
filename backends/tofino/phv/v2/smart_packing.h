#ifndef SMART_PACKING_H_
#define SMART_PACKING_H_

#include "ir/ir.h"

#include "backends/tofino/common/field_defuse.h"
#include "backends/tofino/ir/bitrange.h"
#include "backends/tofino/mau/table_dependency_graph.h"
#include "backends/tofino/mau/table_mutex.h"
#include "backends/tofino/phv/collect_table_keys.h"
#include "backends/tofino/phv/mau_backtracker.h"
#include "backends/tofino/phv/phv_fields.h"
#include "backends/tofino/phv/utils/utils.h"
#include "backends/tofino/phv/v2/allocator_metrics.h"
#include "backends/tofino/phv/v2/parser_packing_validator.h"
#include "backends/tofino/phv/v2/types.h"

namespace PHV {
namespace v2 {

class IxbarFriendlyPacking {
    PhvInfo &phv_i;
    const CollectTableKeys& tables_i;
    const TablesMutuallyExclusive& table_mutex_i;
    const FieldDefUse& defuse_i;
    const DependencyGraph& deps_i;
    const HasPackConflict has_pack_conflict_i;
    const ParserPackingValidator* parser_packing_validator_i;
    const AllocVerifier& can_alloc_i;
    const MauBacktracker* mau_i;
    AllocatorMetrics& alloc_metrics;

    bool can_pack(const std::vector<FieldSlice>& slices,
                  const FieldSlice& fs) const;

    struct MergedCluster {
        SuperCluster* merged;
        ordered_set<SuperCluster*> from;
        ordered_map<const Field*, std::optional<FieldAlignment>> original_alignments;
    };
    MergedCluster merge_by_packing(const std::vector<FieldSlice>& packing,
                                   const ordered_map<FieldSlice, SuperCluster*>& fs_sc);

    /// @returns a sorted order of packing of keys of tables.
    /// Each table will have at most 1 entry.
    std::vector<std::pair<const IR::MAU::Table*, std::vector<FieldSlice>>>
    make_table_key_candidates(const std::list<SuperCluster*>& clusters) const;

 public:
    IxbarFriendlyPacking(PhvInfo& phv,
                         const CollectTableKeys& tables,
                         const TablesMutuallyExclusive& table_mutex,
                         const FieldDefUse& defuse,
                         const DependencyGraph& deps,
                         HasPackConflict has_pc,
                         const ParserPackingValidator* parser_packing_validator,
                         const AllocVerifier& can_alloc,
                         const MauBacktracker* mau,
                         AllocatorMetrics &alloc_metrics)
        : phv_i(phv),
          tables_i(tables),
          table_mutex_i(table_mutex),
          defuse_i(defuse),
          deps_i(deps),
          has_pack_conflict_i(has_pc),
          parser_packing_validator_i(parser_packing_validator),
          can_alloc_i(can_alloc),
          mau_i(mau),
          alloc_metrics(alloc_metrics){}

    std::list<SuperCluster *> pack(const std::list<SuperCluster *> &clusters);
    static bool may_create_container_conflict(const FieldSlice& a, const FieldSlice& b,
                                              const FieldDefUse& defuse,
                                              const DependencyGraph& deps,
                                              const TablesMutuallyExclusive& table_mutex,
                                              int n_stages,
                                              const MauBacktracker* mau);
};

}  // namespace v2
}  // namespace PHV

#endif /* SMART_PACKING_H_ */
