#ifndef EXTENSIONS_BF_P4C_PHV_FINALIZE_STAGE_ALLOCATION_H_
#define EXTENSIONS_BF_P4C_PHV_FINALIZE_STAGE_ALLOCATION_H_

#include "backends/tofino/common/field_defuse.h"
#include "backends/tofino/phv/phv_fields.h"
#include "backends/tofino/mau/table_dependency_graph.h"

/** Calculate the maximum number of physical stages after table allocation.
  */
class CalcMaxPhysicalStages : public Inspector {
 private:
    // Deparser stage for each gress.
    int deparser_stage[3] = { 0, 0, 0 };
    int dep_stage_overall = -1;
    bool preorder(const IR::MAU::Table* tbl) override;
    void end_apply() override;

 public:
    int getDeparserStage(gress_t gress) const {
        return deparser_stage[gress];
    }

    int getDeparserStage() const {
        return dep_stage_overall;
    }
};

class FinalizeStageAllocation;

/** Until this point, the allocation of PHV slices to containers uses logical stages to denote
  * liveness. These logical stages are based on the static table dependency graph.
  *
  * However, for the allocation to be translated to assembly, we need to change the liveness to one
  * based on physical stages. This pass makes that change based on the results of table placement.
  */
class UpdateFieldAllocation : public Inspector {
 private:
    PhvInfo& phv;
    const FieldDefUse& defuse;
    const DependencyGraph& dg;
    const CalcMaxPhysicalStages& depStages;

    // Map of field to its allocated slices.
    ordered_map<const PHV::Field*, std::vector<PHV::AllocSlice>> fieldToSlicesMap;

    // Map of container to the stages where it is read.
    ordered_map<PHV::Container, bitvec> containerToReadStages;

    // Map of container to the stages where it is written.
    ordered_map<PHV::Container, bitvec> containerToWriteStages;

    PHV::StageAndAccess parserMin;
    PHV::StageAndAccess deparserMax;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::Table* tbl) override;
    void end_apply() override;

    void updateAllocation(PHV::Field* f);

 public:
    explicit UpdateFieldAllocation(PhvInfo& p, const FieldDefUse& u,
            const DependencyGraph& d, const CalcMaxPhysicalStages& s)
        : phv(p), defuse(u), dg(d), depStages(s) { }
};

class FinalizeStageAllocation : public PassManager {
 public:
     using TableExprRanges = ordered_map<const IR::MAU::Table*, ordered_set<le_bitrange>>;
     using StageFieldEntry = ordered_map<int, TableExprRanges>;
     using StageFieldUse = ordered_map<const PHV::Field*, StageFieldEntry>;

 private:
    CalcMaxPhysicalStages depStages;

 public:
    static void summarizeUseDefs(
            const PhvInfo& phv,
            const DependencyGraph& dg,
            const FieldDefUse::LocPairSet& refs,
            StageFieldEntry& stageToTables,
            bool& usedInParser,
            bool& usedInDeparser,
            bool usePhysicalStages = true);

    explicit FinalizeStageAllocation(PhvInfo& p, const FieldDefUse& u,
            const DependencyGraph& d);
};

#endif  /*  EXTENSIONS_BF_P4C_PHV_FINALIZE_STAGE_ALLOCATION_H_  */
