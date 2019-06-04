#ifndef EXTENSIONS_BF_P4C_PHV_FINALIZE_STAGE_ALLOCATION_H_
#define EXTENSIONS_BF_P4C_PHV_FINALIZE_STAGE_ALLOCATION_H_

#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_summary.h"

/** Until this point, the allocation of PHV slices to containers uses logical stages to denote
  * liveness. These logical stages are based on the static table dependency graph.
  *
  * However, for the allocation to be translated to assembly, we need to change the liveness to one
  * based on physical stages. This pass makes that change based on the results of table placement.
  */
class FinalizeStageAllocation : public Inspector {
 private:
    PhvInfo& phv;
    const FieldDefUse& defuse;
    const DependencyGraph& dg;
    const TableSummary& tables;

    // Map of field to its allocated slices.
    ordered_map<const PHV::Field*, std::vector<PHV::Field::alloc_slice>> fieldToSlicesMap;

    // Map of container to the stages where it is read.
    ordered_map<PHV::Container, bitvec> containerToReadStages;

    // Map of container to the stages where it is written.
    ordered_map<PHV::Container, bitvec> containerToWriteStages;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::Table* tbl) override;

    void updateAllocation(PHV::Field* f);

 public:
    explicit FinalizeStageAllocation(
            PhvInfo& p,
            const FieldDefUse& u,
            const DependencyGraph& d,
            const TableSummary& t)
        : phv(p), defuse(u), dg(d), tables(t) { }

    static void summarizeUseDefs(
            const PhvInfo& phv,
            const DependencyGraph& dg,
            const FieldDefUse::LocPairSet& refs,
            ordered_map<int, ordered_set<const IR::MAU::Table*>>& stageToTables,
            bool& usedInParser,
            bool& usedInDeparser,
            bool usePhysicalStages = true);
};

#endif  /*  EXTENSIONS_BF_P4C_PHV_FINALIZE_STAGE_ALLOCATION_H_  */
