#ifndef EXTENSIONS_BF_P4C_PHV_ANALYSIS_DARK_H_
#define EXTENSIONS_BF_P4C_PHV_ANALYSIS_DARK_H_

#include "ir/ir.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/analysis/mocha.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

/** XXX(Deep): The PhvUse pass only classifies a field as being used in the MAU or in the
  * parser/deparser. It does not break down the MAU uses into normal, dark, mocha. In fact, in the
  * long term, I would like to remove this class altogether and instead, reconstruct this information
  * using FieldDefUse.
  */

/** This pass analyses all fields used in the program and marks fields that have nondark uses in the
  * MAU (used on the input crossbar). This pass is used by two different passes:
  * CollectDarkCandidates and CollectDarkPrivatizationCandidates.
  */
class CollectNonDarkUses : public MauInspector {
 private:
    const PhvInfo&    phv;
    bitvec            nonDarkMauUses;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::Table*) override;
    bool preorder(const IR::Expression *) override;
    bool contextNeedsIXBar();

 public:
    explicit CollectNonDarkUses(const PhvInfo& p) : phv(p) { }

    bool hasNonDarkUse(const PHV::Field* f) const;
};

/** This pass analyzes all fields used in the program and marks fields suitable for allocation in
  * dark containers by setting the `is_dark_candidate()` property of the corresponding PHV::Field
  * object to true. Fields amenable for allocation to dark containers must satisfy all the
  * requirements for allocation to mocha containers, and also the following additional requirements:
  * 1. Dark fields cannot be used in the parser/deparser.
  * 2. Dark fields cannot be used on the input crossbar.
  *
  * This pass must be run after the CollectMochaCandidates pass as we use the fields marked with
  * is_mocha_candidate() as the starting point for this pass.
  */
class MarkDarkCandidates : public Inspector {
 private:
    PhvInfo&                    phv;
    const PhvUse&               uses;
    const CollectNonDarkUses&   nonDarkUses;

    /// Represents all fields with MAU uses that prevent allocation into dark containers.
    /// E.g. use on input crossbar, participation in meter operations, etc.
    bitvec          nonDarkMauUses;

    /// Number of dark candidates detected.
    size_t          darkCount;
    /// Size in bits of mocha candidates.
    size_t          darkSize;

    profile_t init_apply(const IR::Node* root) override;
    void end_apply() override;

 public:
    explicit MarkDarkCandidates(PhvInfo& p, const PhvUse& u, const CollectNonDarkUses& d)
        : phv(p), uses(u), nonDarkUses(d), darkCount(0), darkSize(0) { }
};

/** This pass marks all the fields used in the program and determines the mocha field candidates
  * suitable for privatization into dark containers. The candidate fields here are mocha fields that
  * are:
  * 1. not read on the input crossbar.
  * 2. is never written in the pipeline.
  * 3. is not bridged and is not a padding field.
  */
class CollectDarkPrivatizationCandidates : public Inspector {
 private:
    PhvInfo&                    phv;
    const CollectNonDarkUses&   nonDarkUses;
    const PragmaContainerType&  pragma;

    /// Represents fields written in the MAU.
    bitvec              fieldsWritten;

    /// Number of fields identified for dark privatization.
    size_t              darkPrivCandidates;
    /// Number of bits identified for privatization and allocation to dark candidates.
    size_t              darkPrivCandidatesSize;

    profile_t init_apply(const IR::Node* root) override;
    void end_apply() override;

 public:
    explicit CollectDarkPrivatizationCandidates(
            PhvInfo& p,
            const PhvUse&,
            const CollectNonDarkUses& d,
            const PragmaContainerType& t)
        : phv(p), nonDarkUses(d), pragma(t) { }
};

/** This class takes as constructor arguments, an empty map of PHV::Field* to PHV::Expression* and
  * populates it with a dark privatization candidate and the corresponding expression for the
  * original field.
  */
class MapDarkFieldToExpr : public Inspector {
 private:
    const PhvInfo&      phv;
    ordered_map<const PHV::Field*, const IR::Expression*>& fieldExpressions;

    profile_t init_apply(const IR::Node* root) override;

    /// For every IR::Expression object in the program, populate the fieldExpressionMap. This might
    /// return a Field for a slice and cast expression on fields. It will work out ok solely because
    /// this is a preorder and we don't prune, so it will also visit the child, which is the field,
    /// and replace the relevant entry in the map.
    bool preorder(const IR::Expression* expr) override;

 public:
    explicit MapDarkFieldToExpr(
            const PhvInfo& p,
            ordered_map<const PHV::Field*, const IR::Expression*>& f)
        : phv(p), fieldExpressions(f) { }
};

/** This pass generates copies of dark privatizable fields marked by
  * CollectDarkPrivatizationCandidates and replaces all MAU uses of those fields by the privatized
  * copies.
  */
class AddDarkFieldUses : public MauTransform {
 private:
    const PhvInfo&  phv;
    ordered_map<const PHV::Field*, const IR::TempVar*>& darkFields;
    /// true if the expression being replaced is used in an action.
    bool inAction;
    /// Current action being encountered by the IR walk.
    const IR::MAU::Action* currentAction = nullptr;

    profile_t init_apply(const IR::Node* root) override;
    const IR::Node* preorder(IR::MAU::Action* act) override;
    const IR::Node* preorder(IR::Expression* expr) override;
    const IR::Node* postorder(IR::MAU::Action* act) override;

 public:
    explicit AddDarkFieldUses(
            const PhvInfo& p,
            ordered_map<const PHV::Field*, const IR::TempVar*>& d)
        : phv(p), darkFields(d) { }
};

/** This pass adds a table at the beginning of the pipeline to initialize dark privatized candidates
  * using the original mocha field.
  */
class AddPrivatizedDarkTableInit : public MauTransform {
 private:
    const ordered_map<const PHV::Field*, const IR::TempVar*>&       darkFields;
    const ordered_map<const PHV::Field*, const IR::Expression*>&    fieldExpressions;

    /// Generate an instruction that assigns the @rhs to the @lhs.
    const IR::MAU::Instruction* generateInitInstruction(
            const PHV::Field* rhs,
            const IR::TempVar* lhs) const;

    /// Retrieve the expression object corresponding to @field.
    const IR::Expression* getExpression(const PHV::Field* field) const;

    /// Given a TableSeq @seq belonging to @gress, add the dark privatized initialization table at
    /// the beginning of the table sequence.
    const IR::MAU::TableSeq* addInit(const IR::MAU::TableSeq* seq, gress_t gress);

    /// Ensure that the new TableSeq is reflected in the pipeline @pipe.
    const IR::BFN::Pipe* postorder(IR::BFN::Pipe* pipe) override;

 public:
    AddPrivatizedDarkTableInit(
            const PhvInfo&,
            const ordered_map<const PHV::Field*, const IR::TempVar*>& d,
            const ordered_map<const PHV::Field*, const IR::Expression*>& f)
        : darkFields(d), fieldExpressions(f) { }
};

class CollectDarkCandidates : public PassManager {
 private:
    CollectNonDarkUses  nonDarkUses;
 public:
    explicit CollectDarkCandidates(PhvInfo& p, PhvUse& u) : nonDarkUses(p) {
        addPasses({
            &nonDarkUses,
            new MarkDarkCandidates(p, u, nonDarkUses)
        });
    }
};

/** The occupancy of dark containers for most programs is negligible as most fields are used in the
  * parser/deparser, or the input crossbar. The best utilization of dark containers requires their
  * use as extra PHVs available for spilling fields that are not used in particular stages. However,
  * this would require us to move to a stage-aware allocation. Until we make that transition, we
  * introduce the DarkPrivatization pass, which makes a new copy of a mocha candidate field, inserts
  * a table in the earliest stage of each gress to initialize this copy from the original field, and
  * replaces all uses of the mocha field in the pipeline with this dark-privatized copy. This allows
  * us to allocate more fields to dark containers.
  */
class DarkPrivatization : public PassManager {
 private:
    PhvUse              uses;
    CollectNonDarkUses  nonDarkUses;
    PragmaContainerType pragma;

    ordered_map<const PHV::Field*, const IR::TempVar*>      darkFields;
    ordered_map<const PHV::Field*, const IR::Expression*>   fieldExpressions;

 public:
    explicit DarkPrivatization(PhvInfo& p)
        : uses(p), nonDarkUses(p), pragma(p) {
        addPasses({
            &uses,
            new CollectMochaCandidates(p, uses),
            &nonDarkUses,
            new MarkDarkCandidates(p, uses, nonDarkUses),
            &pragma,
            new CollectDarkPrivatizationCandidates(p, uses, nonDarkUses, pragma),
            new MapDarkFieldToExpr(p, fieldExpressions),
            new AddDarkFieldUses(p, darkFields),
            new AddPrivatizedDarkTableInit(p, darkFields, fieldExpressions)
        });
    }
};

#endif  /*  EXTENSIONS_BF_P4C_PHV_ANALYSIS_DARK_H_  */
