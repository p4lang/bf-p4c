#ifndef EXTENSIONS_BF_P4C_PHV_PRIVATIZATION_H_
#define EXTENSIONS_BF_P4C_PHV_PRIVATIZATION_H_

#include "ir/ir.h"
#include "bf-p4c/mau/action_analysis.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/field_defuse.h"

/// Backtracking structure intercepted by EnterPrivatizationPasses.
/// doNotPrivatize contains the list of field names that, if privatized, cause PHV allocation to
/// fail.
struct PrivatizationTrigger {
    struct failure : public Backtrack::trigger {
        ordered_set<cstring> doNotPrivatize;
        explicit failure(ordered_set<cstring> s) : trigger(OTHER), doNotPrivatize(s) { }
    };
};

/** This is the entry point to intercept any backtracking exceptions that result from PHV allocation
  * failing due to privatization.
  */
class EnterPrivatizationPasses : public Inspector, Backtrack {
 private:
    /// Set of fields that should not be privatized because they caused PHV allocation to fail.
    ordered_set<cstring>& doNotPrivatize;

    /// This catches the backtracking exception from ValidateAllocation.
    bool backtrack(trigger &) override;

    profile_t init_apply(const IR::Node* root) override;

 public:
    explicit EnterPrivatizationPasses(ordered_set<cstring>& f) : doNotPrivatize(f) { }
};

/** This class identifies the fields that are candidates for privatization (read-only fields that
  * are used only in the first LAST_STAGE_FOR_PRIVATIZATION stages of the pipeline) by setting the
  * privatizable property of those fields.
  */
class CollectFieldsForPrivatization : public Inspector {
 private:
    static constexpr int LAST_STAGE_FOR_PRIVATIZATION = 2;

    PhvInfo&                            phv;
    const DependencyGraph&              dg;
    const ordered_set<cstring>&         doNotPrivatize;

    /// Represents fields that are written in the MAU pipeline.
    bitvec  fieldsWritten;
    /// Represents fields that are read in the MAU pipeline.
    bitvec  fieldsRead;

    /// Number of fields identified as privatizable.
    size_t count;
    /// Total size of fields identified as privatizable.
    size_t size;

    /// Map of a field to the set of tables it is read in.
    ordered_map<PHV::Field*, ordered_set<const IR::MAU::Table*>> tablesReadFields;

    /// @returns true when @f is a field from a packet (not metadata, pov, or bridged field)
    static bool isPacketField(const PHV::Field* f) {
        return (f && !f->metadata && !f->pov && !f->bridged && !f->overlayable &&
                f->exact_containers() && f->deparsed());
    }

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::Action* act) override;
    void end_apply() override;

    /// Given an action and a FieldActionsMap related to that action, analyze all the reads and
    /// writes in that action and populate CollectFieldsForPrivatization object's data members.
    void populateMembers(const IR::MAU::Action*, const ActionAnalysis::FieldActionsMap&);

    /// @returns true if all the tables in @tables have their min_stage less than the defined
    /// threshold LAST_STAGE_FOR_PRIVATIZATION.
    bool readInEarlyStages(const ordered_set<const IR::MAU::Table*>& tables) const;

 public:
    explicit CollectFieldsForPrivatization(
            PhvInfo& p, const DependencyGraph& d, const ordered_set<cstring>& s)
        : phv(p), dg(d), doNotPrivatize(s) { }
};

/** This class transforms the backend IR as follows:
  * 0. This pass creates a privatized temporary variable for each privatizable field, named
  *    "field_name.PHV::Field::TPHV_PRIVATIZE_SUFFIX" that uniquely identifies the privatized
  *    temporary variable.
  * 1. Parser now extracts the same range to both the PHV (privatizable) and TPHV (privatized) copy
  *    of the same field.
  * 2. Deparser emits the container for the TPHV (privatized) copy.
  */
class AddPrivatizedFieldUses : public Transform {
 private:
    /// PhvInfo object.
    const PhvInfo& phv;
    /// @true if we are traversing the Parser part of the IR.
    bool inParser;

    /// Map of ParserState to the new extracts that must be added to that state.
    ordered_map<const IR::BFN::ParserState*, ordered_set<IR::BFN::Extract*>> listOfNewExtracts;
    /// Map of original field to the new TempVar (TPHV) that must replace their deparser emits.
    ordered_map<const PHV::Field*, const IR::TempVar*> deparsedFields;

    /// Parser state (and its children) being currently visited.
    IR::BFN::ParserState* currentParserState = nullptr;
    /// Current extract during IR traversal.
    const IR::BFN::ParserRVal* currentExtractSource = nullptr;

    profile_t init_apply(const IR::Node* root) override;
    IR::Node* preorder(IR::BFN::ParserState* p) override;
    IR::Node* preorder(IR::BFN::Extract* e) override;
    IR::Node* preorder(IR::BFN::EmitField* e) override;
    IR::Node* preorder(IR::Expression* expr) override;
    IR::Node* postorder(IR::BFN::ParserState* p) override;
    IR::Node* postorder(IR::BFN::Extract* e) override;

 public:
    explicit AddPrivatizedFieldUses(const PhvInfo& p) : phv(p) { }
};

/** For cases where PHV allocation fails only for privatized fields, and there is no overlay for the
  * PHV (privatizable) copies of these privatized fields, we do not need to invoke the entire
  * backtracking mechanism again. Instead, it is sufficient to undo the changes to the backend IR,
  * replacing every use of the inserted privatized field with the privatizable copy. This pass
  * effects those changes. Note: defuse must be rerun after this pass.
  */
class UndoPrivatization : public Transform {
 private:
    /// PhvInfo object.
    PhvInfo& phv;
    /// List of fields whose privatization must be undone.
    const ordered_set<cstring>& doNotPrivatize;

    /// @true if we are traversing the Parser part of the IR.
    bool inParser;

    /// Map of ParserState to the new extracts that must be added to that state.
    ordered_set<const IR::BFN::ParserState*> listOfErasedExtracts;
    /// Map of field to an expression corresponding to it.
    ordered_map<const PHV::Field*, IR::Expression*> fieldToExpressionMap;

    /// Parser state (and its children) being currently visited.
    IR::BFN::ParserState* currentParserState = nullptr;
    /// Current extract during IR traversal.
    IR::BFN::Extract* currentExtract = nullptr;

    profile_t init_apply(const IR::Node* root) override;
    IR::Node* preorder(IR::BFN::ParserState* p) override;
    IR::Node* preorder(IR::BFN::Extract* e) override;
    IR::Node* preorder(IR::BFN::EmitField* e) override;
    IR::Node* preorder(IR::Expression* expr) override;
    IR::Node* postorder(IR::BFN::ParserState* p) override;

 public:
    explicit UndoPrivatization(PhvInfo& p, const ordered_set<cstring>& f)
        : phv(p), doNotPrivatize(f) { }
};

/** Pass to perform the PHV-TPHV privatization
  */
class Privatization : public PassManager {
 private:
    FieldDefUse& defuse;
 public:
    Privatization(PhvInfo& phv, DependencyGraph& dg, ordered_set<cstring>& s, FieldDefUse& d) :
        defuse(d) {
        addPasses({
            new CollectPhvInfo(phv),
            &defuse,
            new EnterPrivatizationPasses(s),
            new FindDependencyGraph(phv, dg),
            new CollectFieldsForPrivatization(phv, dg, s),
            new AddPrivatizedFieldUses(phv)
        });
    }
};

#endif  /*  EXTENSIONS_BF_P4C_PHV_PRIVATIZATION_H_  */
