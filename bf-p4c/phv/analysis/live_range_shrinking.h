#ifndef EXTENSIONS_BF_P4C_PHV_ANALYSIS_LIVE_RANGE_SHRINKING_H_
#define EXTENSIONS_BF_P4C_PHV_ANALYSIS_LIVE_RANGE_SHRINKING_H_

#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/map_tables_to_actions.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_flow_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/analysis/dominator_tree.h"
#include "bf-p4c/phv/analysis/meta_live_range.h"
#include "bf-p4c/phv/pragma/pa_no_init.h"
#include "bf-p4c/phv/transforms/auto_alias.h"
#include "bf-p4c/phv/utils/utils.h"

/** Find the actions in which to initialize metadata fields after live range shrinking.
  */
class FindInitializationNode : public Inspector {
 private:
    const BuildDominatorTree&               domTree;
    const PhvInfo&                          phv;
    const FieldDefUse&                      defuse;
    const DependencyGraph&                  dg;
    const ordered_set<const PHV::Field*>&   noInit;
    const MapTablesToActions&               tablesToActions;
    const MetadataLiveRange&                metaLiveMap;
    const ActionPhvConstraints&             actionConstraints;
    const TablesMutuallyExclusive&          tableMutex;
    const std::vector<FlowGraph*>&          flowGraph;
    const DetermineCandidateHeaders&        noInitPacketFields;
    const MauBacktracker&                   tableAlloc;

    /// Actions where we cannot initialize metadata because they use hash distributions (and
    // therefore, cannot have a bitmasked-set operation in them).
    // XXX(Deep): For now, disable initialization at all such actions (and tables that contain those
    // actions). In the longer term, change this to recognize when a bitmasked-set operation/action
    // data is necessary to realize the initialization operation.
    ordered_set<const IR::MAU::Action*>     doNotInitActions;

    /// Maximum number of stages required as per the table dependency graph (resource insensitive).
    int maxStages;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::Table* tbl) override;
    bool preorder(const IR::MAU::Action* act) override;

    /// @returns true if @f is an auto-alias field that is only alive in the f_dominators and
    /// therefore its deparser use can be ignored.
    bool ignoreDeparserUseForPacketField(
            const PHV::Field* f,
            const ordered_set<const IR::BFN::Unit*>& f_dominators) const;

    /// Summarizes the uses and defs of field @f and stores the result in the associated map @units,
    /// contains both the list of units for usedef and the kind of access (read or write). Also
    /// populates @f_dominators with the set of dominators for uses of field @f.
    bool summarizeUseDefs(
            const PHV::Field* f,
            const ordered_set<const IR::BFN::Unit*>& initPoints,
            ordered_map<const PHV::Field*, ordered_map<const IR::BFN::Unit*, unsigned>>& units,
            ordered_set<const IR::BFN::Unit*>& f_dominators) const;

    /// @returns true if @table reachs any defuse units in @g_units.
    bool canInitTableReachGUnits(
            const IR::MAU::Table* table,
            const ordered_set<const IR::BFN::Unit*>& g_units) const;

    /// @returns true if any defuse units in @f_units reach @initTable.
    bool canFUsesReachInitTable(
            const IR::MAU::Table* initTable,
            const ordered_set<const IR::BFN::Unit*>& f_units) const;

    /// @returns a set of actions where field @f with uses @u can be initialized, given group
    /// dominator @t for the defuse units of @f and a stage @lastAllowedStage, after which the
    /// initialization should be performed. @prevField is the overlapping field that has the
    /// adjacent earlier live range to @f.
    boost::optional<const PHV::Allocation::ActionSet> getInitializationCandidates(
            const PHV::Container& c,
            const PHV::Field* f,
            const IR::MAU::Table* t,
            const ordered_map<const IR::BFN::Unit*, unsigned>& u,
            const int lastAllowedStage,
            const ordered_set<const IR::MAU::Table*>& fStrictDominators,
            const PHV::Field* prevField,
            const ordered_map<const PHV::Field*, ordered_set<const IR::BFN::Unit*>>& g_units,
            const PHV::Allocation::MutuallyLiveSlices& container_state,
            const PHV::Transaction& alloc) const;

    /** Given @initField that is being initialized at @initTable, and @container_state that is live
      * at the same time as @initField within the same container, this method returns true, if:
      * 1. initTable and any table t, where any slice in container_state is written, are in the same
      *    stage (as per previous, container conflict free rounds of table placement), and
      * 2. initTable and table t are not mutually exclusive.
      */
    bool mayViolatePackConflict(
            const IR::MAU::Table* initTable,
            const PHV::Field* initField,
            const PHV::Allocation::MutuallyLiveSlices& container_state,
            const PHV::Transaction& alloc) const;

    /// @returns a set of actions where field @f must be initialized in @tbl.
    boost::optional<const PHV::Allocation::ActionSet> getInitPointsForTable(
            const PHV::Container& c,
            const IR::MAU::Table* t,
            const PHV::Field* f,
            const ordered_set<const IR::MAU::Table*>& prevUses,
            const PHV::Allocation::MutuallyLiveSlices& container_state,
            const PHV::Transaction& alloc,
            bool ignoreMutex = false) const;

    /// @return true if the length of the dependence critical path in the table dependency graph is
    /// likely to increase, in response to metadata initialization inducing a dependency from table
    /// @use to table @init. TODO: This method should eventually be offered as a call in the
    /// TableDependencyGraph class.
    bool increasesDependenceCriticalPath(
            const IR::MAU::Table* use,
            const IR::MAU::Table* init) const;

    /// @returns the set of tables which contain defuse for field @f. If @uses or @defs is false,
    /// then the corresponding uses and defs are not returned in the set.
    ordered_set<const IR::MAU::Table*> getTableUsesForField(
            const PHV::Field* f,
            bool uses = true,
            bool defs = true) const;

    /// Checks if any of the fields in the container state (summarized in @fieldsInOrder) prevent
    /// the allocation because of overlapping live ranges. While checking overlapping ranges, make
    /// sure that the overlapping live ranges are not because of mutual exclusion properties of
    /// those fields.
    /// @returns true if the fields can be initialized, and @false if they cannot. @fields may be
    /// mutated to remove all but one mutual exclusive field (only the field with the largest live
    /// range will remain).
    bool identifyFieldsToInitialize(
            std::vector<const PHV::Field*>& fields,
            const ordered_map<int, std::pair<int, int>>& livemap) const;

    /// @returns true if metadata initialization is forbidden in @action.
    bool cannotInitInAction(
            const PHV::Container& c,
            const IR::MAU::Action* action,
            const PHV::Transaction& alloc) const;

 public:
    /// @returns a map of field to the actions in which initialization must be done for the set of
    /// fields in @fields to be overlayed in the same container. @returns boost::none if metadata
    /// initialization cannot be realized.
    boost::optional<PHV::Allocation::LiveRangeShrinkingMap>
    findInitializationNodes(
        const PHV::Container c,
        const ordered_set<PHV::AllocSlice>& alloced,
        const PHV::Transaction& alloc,
        const PHV::Allocation::MutuallyLiveSlices& container_state) const;

    /// Pretty prints the PHV::Allocation::LiveRangeShrinkingMap @m. The basic indentation is
    /// specified by @indent.
    cstring printLiveRangeShrinkingMap(
            const PHV::Allocation::LiveRangeShrinkingMap& m,
            cstring indent) const;

    explicit FindInitializationNode(
            const BuildDominatorTree& d,
            const PhvInfo& p,
            const FieldDefUse& u,
            const DependencyGraph& g,
            const ordered_set<const PHV::Field*>& i,
            const MapTablesToActions& t,
            const MetadataLiveRange& l,
            const ActionPhvConstraints& a,
            const TablesMutuallyExclusive& m,
            const std::vector<FlowGraph*>& fg,
            const DetermineCandidateHeaders& c,
            const MauBacktracker& bt)
        : domTree(d), phv(p), defuse(u), dg(g), noInit(i), tablesToActions(t),
          metaLiveMap(l), actionConstraints(a), tableMutex(m), flowGraph(fg),
          noInitPacketFields(c), tableAlloc(bt) { }
};

/** This pass is the pass manager for metadata initialization and provides external interfaces to
  * PHV analysis for the same purpose.
  */
class LiveRangeShrinking : public PassManager {
 private:
    TablesMutuallyExclusive         tableMutex;
    MapTablesToActions              tableActionsMap;
    DetermineCandidateHeaders       noInitPacketFields;
    FindInitializationNode          initNode;

 public:
    const MapTablesToActions& getTableActionsMap() const {
        return tableActionsMap;
    }

    boost::optional<PHV::Allocation::LiveRangeShrinkingMap> findInitializationNodes(
            const ordered_set<PHV::AllocSlice>& alloced,
            const PHV::Transaction& alloc,
            const PHV::Allocation::MutuallyLiveSlices& container_state) const {
        PHV::Container c;
        for (auto& sl : alloced) {
            if (c == PHV::Container()) {
                c = sl.container();
            } else {
                BUG_CHECK(c == sl.container(),
                          "Containers for metadata overlay candidates are different");
            }
        }
        BUG_CHECK(c != PHV::Container(),
                  "Container candidate for metadata overlay cannot be NULL.");
        return initNode.findInitializationNodes(c, alloced, alloc, container_state);
    }

    boost::optional<PHV::Allocation::LiveRangeShrinkingMap> findInitializationNodes(
            const ordered_set<PHV::AllocSlice>& alloced,
            const PHV::AllocSlice& slice,
            const PHV::Transaction& alloc,
            const PHV::Allocation::MutuallyLiveSlices& container_state) const {
        ordered_set<PHV::AllocSlice> candidates;
        candidates.insert(alloced.begin(), alloced.end());
        candidates.insert(slice);
        return findInitializationNodes(candidates, alloc, container_state);
    }

    /// Pretty prints the LiveRangeShrinkingMap @m. The basic indentation is specified by
    /// @indent.
    cstring printLiveRangeShrinkingMap(
            const PHV::Allocation::LiveRangeShrinkingMap& m,
            cstring indent) const {
        return initNode.printLiveRangeShrinkingMap(m, indent);
    }

    explicit LiveRangeShrinking(
            const PhvInfo& p,
            const FieldDefUse& u,
            const DependencyGraph& g,
            const PragmaNoInit& i,
            const MetadataLiveRange& l,
            const ActionPhvConstraints& a,
            const BuildDominatorTree& d,
            const MauBacktracker& bt);
};

#endif  /* EXTENSIONS_BF_P4C_PHV_ANALYSIS_LIVE_RANGE_SHRINKING_H_ */