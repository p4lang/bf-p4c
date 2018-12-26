#ifndef EXTENSIONS_BF_P4C_PHV_ANALYSIS_LIVE_RANGE_SHRINKING_H_
#define EXTENSIONS_BF_P4C_PHV_ANALYSIS_LIVE_RANGE_SHRINKING_H_

#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/map_tables_to_actions.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_flow_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/analysis/dominator_tree.h"
#include "bf-p4c/phv/analysis/meta_live_range.h"
#include "bf-p4c/phv/pragma/pa_no_init.h"
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

    /// @returns true if the def of field @f in unit @u is the definition corresponding to implicit
    /// initialization in the parser.
    bool isUninitializedDef(const PHV::Field* f, const IR::BFN::Unit* u) const;

    /// @returns true if any of the dominator units in @doms is a parser node.
    bool hasParserUse(ordered_set<const IR::BFN::Unit*> doms) const;

    /// Summarizes the uses and defs of field @f and stores the result in the associated map @units,
    /// contains both the list of units for usedef and the kind of access (read or write). Also
    /// populates @f_dominators with the set of dominators for uses of field @f.
    bool summarizeUseDefs(
            const PHV::Field* f,
            ordered_map<const PHV::Field*, ordered_map<const IR::BFN::Unit*, unsigned>>& units,
            ordered_set<const IR::BFN::Unit*>& f_dominators) const;

    /// @returns true if any defuse units in @f_units can reach any defuse units in @g_units.
    bool canFUnitsReachGUnits(
            const ordered_set<const IR::BFN::Unit*>& f_units,
            const ordered_set<const IR::BFN::Unit*>& g_units) const;

    /// @returns true if @table reachs any defuse units in @g_units.
    bool canInitTableReachGUnits(
            const IR::MAU::Table* table,
            const ordered_set<const IR::BFN::Unit*>& g_units) const;

    /// Trim the set of dominators by removing nodes that are dominated by other dominator nodes
    /// already in the set.
    void getTrimmedDominators(ordered_set<const IR::BFN::Unit*>& candidates) const;

    /// @returns a set of actions where field @f with uses @u can be initialized, given group
    /// dominator @t for the defuse units of @f and a stage @lastAllowedStage, after which the
    /// initialization should be performed. @prevField is the overlapping field that has the
    /// adjacent earlier live range to @f.
    boost::optional<const PHV::Allocation::ActionSet>
        getInitializationCandidates(
                const PHV::Container& c,
                const PHV::Field* f,
                const IR::MAU::Table* t,
                const ordered_map<const IR::BFN::Unit*, unsigned>& u,
                const int lastAllowedStage,
                const ordered_set<const IR::MAU::Table*>& fStrictDominators,
                const PHV::Field* prevField,
                const ordered_map<const PHV::Field*, ordered_set<const IR::BFN::Unit*>>& g_units,
                const PHV::Transaction& alloc) const;

    /// @returns a set of actions where field @f must be initialized in @tbl.
    boost::optional<const PHV::Allocation::ActionSet> getInitPointsForTable(
            const PHV::Container& c,
            const IR::MAU::Table* t,
            const PHV::Field* f,
            const ordered_set<const IR::MAU::Table*>& prevUses,
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
        const ordered_set<const PHV::Field*>& fields,
        const PHV::Transaction& alloc) const;

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
            const std::vector<FlowGraph*>& fg)
        : domTree(d), phv(p), defuse(u), dg(g), noInit(i), tablesToActions(t), metaLiveMap(l),
          actionConstraints(a), tableMutex(m), flowGraph(fg) { }
};

/** This pass is the pass manager for metadata initialization and provides external interfaces to
  * PHV analysis for the same purpose.
  */
class LiveRangeShrinking : public PassManager {
 private:
    TablesMutuallyExclusive         tableMutex;
    std::vector<FlowGraph*>         flowGraph;
    BuildDominatorTree              domTree;
    MapTablesToActions              tableActionsMap;
    FindInitializationNode          initNode;

 public:
    boost::optional<PHV::Allocation::LiveRangeShrinkingMap> findInitializationNodes(
            const ordered_set<PHV::AllocSlice>& alloced,
            const PHV::Transaction& alloc) const {
        ordered_set<const PHV::Field*> fields;
        PHV::Container c;
        for (auto& sl : alloced) {
            fields.insert(sl.field());
            if (c == PHV::Container()) {
                c = sl.container();
            } else {
                BUG_CHECK(c == sl.container(),
                          "Containers for metadata overlay candidates are different");
            }
        }
        BUG_CHECK(c != PHV::Container(),
                  "Container candidate for metadata overlay cannot be NULL.");
        return initNode.findInitializationNodes(c, fields, alloc);
    }

    boost::optional<PHV::Allocation::LiveRangeShrinkingMap> findInitializationNodes(
            const ordered_set<PHV::AllocSlice>& alloced,
            const PHV::AllocSlice& slice,
            const PHV::Transaction& alloc) const {
        ordered_set<PHV::AllocSlice> candidates;
        candidates.insert(alloced.begin(), alloced.end());
        candidates.insert(slice);
        return findInitializationNodes(candidates, alloc);
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
            const ActionPhvConstraints& a);
};

/** A helper class that maps PHV::Field to an IR::Expression.
  * It also provides a helper function to generate an IR::MAU::Instruction* to initialize a field to
  * 0.
  */
class MapFieldToExpr : public Inspector {
 public:
    using AllocSlice = PHV::Field::alloc_slice;

 private:
    const PhvInfo& phv;
    ordered_map<int, const IR::Expression*> fieldExpressions;

    profile_t init_apply(const IR::Node* root) override {
        fieldExpressions.clear();
        return Inspector::init_apply(root);
    }

    /// For every IR::Expression object in the program, populate the fieldExpressions map. This
    /// might return a Field for slice and cast expressions on fields. It will work out okay solely
    /// because this is a preorder and we don't prune, so it will also visit the child, which is the
    /// field, and then replace the entry in the map.
    bool preorder(const IR::Expression* expr) override;

 public:
    explicit MapFieldToExpr(const PhvInfo& p) : phv(p) { }

    const IR::Expression* getExpr(const PHV::Field* field) const {
        BUG_CHECK(fieldExpressions.count(field->id),
                  "Missing IR::Expression mapping of %1%", field->name);
        return fieldExpressions.at(field->id)->clone();
    }

    /// @returns an instruction that initializes the field slice @f.
    const IR::MAU::Instruction*
        generateInitInstruction(const AllocSlice& slice) const;
};

class ComputeFieldsRequiringInit : public Inspector {
 private:
    const PhvInfo&                  phv;

    // Map of action names to the set of fields that must be initialized at that action.
    ordered_map<const IR::MAU::Action*, std::vector<MapFieldToExpr::AllocSlice>> actionInits;

    // Map of all fields that must be initialized (across all actions).
    ordered_set<const PHV::Field*> fieldsForInit;

    profile_t init_apply(const IR::Node* root) override;

 public:
    explicit ComputeFieldsRequiringInit(const PhvInfo& p) : phv(p) { }

    // @returns the set of all fields that must be initialized across all actions.
    const ordered_set<const PHV::Field*>& getComputeFieldsRequiringInit() const {
        return fieldsForInit;
    }

    // @returns the map of all actions and the metadata fields to be initialized in those actions.
    const ordered_map<const IR::MAU::Action*, std::vector<MapFieldToExpr::AllocSlice>>&
    getAllActionInits() const {
        return actionInits;
    }

    // @returns the set of fields that must be initialized at action @act.
    const std::vector<MapFieldToExpr::AllocSlice>
    getInitsForAction(const IR::MAU::Action* act) const {
        std::vector<MapFieldToExpr::AllocSlice> empty;
        if (!actionInits.count(act))
            return empty;
        return actionInits.at(act);
    }
};

/** This pass determines all the fields to be initialized because of live range shrinking, and
  * adds the relevant initialization operation to the corresponding actions where those fields must
  * be initialized.
  */
class AddInitialization : public Transform {
 private:
    const MapFieldToExpr&                   fieldToExpr;
    const ComputeFieldsRequiringInit&       fieldsForInit;
    const MapTablesToActions&               actionsMap;

    const IR::MAU::Action* postorder(IR::MAU::Action* act) override;

 public:
    explicit AddInitialization(
            const MapFieldToExpr& e,
            const ComputeFieldsRequiringInit& i,
            const MapTablesToActions& a)
        : fieldToExpr(e), fieldsForInit(i), actionsMap(a) { }
};

/** LiveRangeShrinking makes assumptions about the disjoint live ranges of metadata fields
  * (separated by the compiler-defined dependence distance). For each pair of fields overlapping in
  * a container due to live range shrinking, we need to maintain the invariant that the uses of the
  * field with the earlier live range must all happen before the initializations of the field with
  * the later live range (initialization by definition is the first def of the field, and the field
  * ceases to have uninitialized reads after metadata initialization). This is equivalent to
  * creating new dependencies between the earlier field use tables and the tables initializing the
  * next field.
  *
  * This dependency information is currently memoized in the PhvInfo object by this pass. In the
  * long run, this could be (and probably should be) added to the DependencyGraph structure.
  */
class ComputeDependencies : public Inspector {
 private:
    PhvInfo&                                    phv;
    const MapTablesToActions&                   actionsMap;
    const ComputeFieldsRequiringInit&           fieldsForInit;
    const FieldDefUse&                          defuse;
    const MetadataLiveRange&                    liverange;

    profile_t init_apply(const IR::Node* root) override;

    // @fields: Map of a field being initialized to the overlapping fields.
    // @inits: Map of a field being initialized to the tables where the initialization is inserted.
    // Note down all the dependencies that would be induced because of the initialization.
    void noteDependencies(
            const ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>>& fields,
            const ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Table*>>& inits);

 public:
    explicit ComputeDependencies(
            PhvInfo& p,
            const MapTablesToActions& a,
            const ComputeFieldsRequiringInit& i,
            const FieldDefUse& d,
            const MetadataLiveRange& r)
        : phv(p), actionsMap(a), fieldsForInit(i), defuse(d), liverange(r) { }
};

/** This is the pass manager, which takes the results of PHV allocation and then inserts the right
  * initialization for metadata fields into various initialization points (actions). This must be
  * run after the AllocatePHV pass.
  */
class AddMetadataInitialization : public PassManager {
 private:
    MapTablesToActions          actionsMap;
    MapFieldToExpr              fieldToExpr;
    ComputeFieldsRequiringInit  init;
    ComputeDependencies         dep;

 public:
    explicit AddMetadataInitialization(
            PhvInfo& p,
            const FieldDefUse& d,
            const MetadataLiveRange& r);
};

#endif  /* EXTENSIONS_BF_P4C_PHV_ANALYSIS_LIVE_RANGE_SHRINKING_H_ */
