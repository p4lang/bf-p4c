#ifndef EXTENSIONS_BF_P4C_PHV_ADD_INITIALIZATION_H_
#define EXTENSIONS_BF_P4C_PHV_ADD_INITIALIZATION_H_

#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/map_tables_to_actions.h"
#include "bf-p4c/phv/analysis/meta_live_range.h"
#include "bf-p4c/mau/table_dependency_graph.h"

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

    const IR::MAU::Instruction* generateInitInstruction(
            const AllocSlice& dest,
            const AllocSlice& source) const;
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
    using StageFieldUse = ordered_map<const PHV::Field*, ordered_map<int, ordered_set<const
        IR::MAU::Table*>>>;
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
            const ordered_map<PHV::AllocSlice, ordered_set<PHV::AllocSlice>>& slices,
            const ordered_map<PHV::AllocSlice, ordered_set<const IR::MAU::Table*>>& initNodes);

 public:
    ComputeDependencies(
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
class AddSliceInitialization : public PassManager {
 private:
    MapTablesToActions          actionsMap;
    MapFieldToExpr              fieldToExpr;
    ComputeFieldsRequiringInit  init;
    ComputeDependencies         dep;

 public:
    explicit AddSliceInitialization(
            PhvInfo& p,
            FieldDefUse& d,
            const MetadataLiveRange& r);
};

#endif  /* EXTENSIONS_BF_P4C_PHV_ADD_INITIALIZATION_H_ */
