/**
 * \defgroup stateful_alu Stateful ALU Overview
 * \brief Content related to stateful ALU
 *
 * A register is referred to as a stateful table.
 *
 * Note that a stateful ALU (SALU) is referred to as meter ALU
 * in micro-architecture specificaion (MAS) documents.
 * * Represented by P4::IR::MAU::StatefulAlu IR node.
 * * Contains:
 *   * %Instruction memory:
 *     * Four rows, each one contains a SALU VLIW instruction
 *       represented by a register action in P4 code and P4::IR::MAU::SaluAction IR node
 *       * The SALU VLIW instruction contains instructions for particular units
 *         (four sub-ALUs, two comparators, output sub-ALU) represented by primitives
 *         (P4::IR::MAU::Primitive) both in backend and assembler.
 *   * Register file:
 *     * Four rows, each one is 32b (Tofino) / 34b (Tofino 2) register
 *       represented by a register parameter in P4 code and P4::IR::MAU::SaluRegfileRow IR node
 *       TOF3-DOC: 34b (Tofino 3).
 *     * Shared by "large" constants and register parameters
 * * There are four SALUs in a MAU stage.
 *
 * Front-end passes involved:
 *
 * * P4V1::StatefulAluConverter (fromv1.0 folder)
 *   * Registered via singleton pattern
 *   * Transforms the IR from P4-14 to P4-16
 *   * E.g.
 * ```
 * blackbox stateful_alu reg_alu_4 {
 *   reg: reg_4;
 *   update_lo_1_value: register_lo + 1;
 * }
 * ```
 * is transformed to
 * ```
 * RegisterAction<Picasso, bit<32>, bit<32>>(reg_4) Rembrandt = {
 *     void apply(inout Picasso Morrow, out bit<32> Elkton) {
 *     Morrow.lo = Morrow.lo + 1;
 *   }
 * }
 * ```
 *
 * Mid-end passes involved:
 *
 * * P4::SynthesizeActions
 *   * Moves the statements placed directly in an apply block of a control block
 *     to newly created \@hidden actions (which are further placed into \@hidden tables
 *     in the P4::MoveActionsToTables pass).
 *   * BFN::ActionSynthesisPolicy checks whether successive statements in an apply block
 *     of a control block can be combined into a single new action. This is necessary
 *     for post-mid-end and back-end passes that process the actions independently
 *     of each other. The policy detects Register.write()-after-read(), which can be
 *     transformed into a single register action.
 * * BFN::RegisterReadWrite (see the description of the sub-passes above)
 *   1. BFN::RegisterReadWrite::MoveRegisterParameters
 *   2. BFN::RegisterReadWrite::CollectRegisterReadsWrites
 *   3. BFN::RegisterReadWrite::AnalyzeActionWithRegisterCalls
 *   4. BFN::RegisterReadWrite::UpdateRegisterActionsAndExecuteCalls
 *   5. BFN::RegisterReadWrite::CheckRegisterActions
 *
 * Post-mid-end passes involved:
 *
 * * BFN::BridgedPacking and BFN::SubstitutePackedHeaders
 *   * BFN::BackendConverter (converts mid-end IR into back-end IR)
 *     * BFN::ProcessBackendPipe
 *       * BFN::AttachTables (see the description of the sub-passes above)
 *         1. BFN::AttachTables::InitializeStatefulAlus
 *         2. BFN::AttachTables::InitializeRegisterParams
 *         3. BFN::AttachTables::InitializeStatefulInstructions
 *            * CreateSaluInstruction
 *         4. BFN::AttachTables::DefineGlobalRefs
 */

#ifndef EXTENSIONS_BF_P4C_MAU_STATEFUL_ALU_H_
#define EXTENSIONS_BF_P4C_MAU_STATEFUL_ALU_H_

#include <map>
#include <vector>

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "mau_visitor.h"
#include "bf-p4c/device.h"

struct Device::StatefulAluSpec {
    bool                        CmpMask;  // are cmp oprerands maskable?
    std::vector<cstring>        CmpUnits;
    int                         MaxSize;
    int                         MaxDualSize;
    int                         MaxPhvInputWidth;
    int                         MaxInstructions;
    int                         MaxInstructionConstWidth;
    int                         MinInstructionConstValue;
    int                         MaxInstructionConstValue;
    int                         OutputWords;
    bool                        DivModUnit;
    bool                        FastClear;
    int                         MaxRegfileRows;

    cstring cmpUnit(unsigned idx) const;
};

/**
 * \ingroup stateful_alu
 * \brief The pass creates SALU VLIW instructions.
 *
 * The pass converts a RegisterAction into an MAU::SaluAction for an MAU::StatefulAlu,
 * converting all of the properties and code into the corresponding instructions
 * or whatever else is needed.
 *
 * The pass is designed to be applied to a subtree of IR containing a single
 * Declaration_Instance object of type RegisterAction, LearnAction, MinMaxAction
 * or SelectorAction, and creates an SaluAction for it, adding it to the StatefulAlu
 * passed to the pass constructor.  We arrange for exactly one instance of this pass
 * to be created for each SALU, and reuse it to create all the individual
 * instructions in that SALU, so we can accumulate information about things
 * that need to be shared between instructions here.
 *
 * This is really a kind of "reconstruction transform" rather than an
 * Inspector, but the normal Transform isn't right for it, as we want to
 * rebuild some things with a very different object (turning Properties into
 * Instructions) which won't work 'in place'.  It also really wants to do
 * pattern matching across expression trees, which our Visitor infrastructure
 * does not support very well.
 *
 * It can be thought of as a state machine + code accumulator that is run
 * over the body of the register_action.  The 'etype' state tracks what
 * the currently visited expression is needed for (left or right side of
 * an assignment, or condition in an 'if').  Operands of an instruction
 * are accumulated, existence and uses of local variables are tracked,
 * and instructions are generated and added to the body of the SaluAction
 * that is being created.  Along the way and at the end, various problems
 * that exceeed the capabilities of the salu are diagnosed.
 *
 * It also checks if an instruction about to be created can be merged with
 * another existing instruction. The instructions must have the same opcode
 * and operands, but their predicates can differ. The predicates are merged
 * via | operation.
 */
class CreateSaluInstruction : public Inspector {
    P4::IR::MAU::StatefulAlu                *salu;
    const P4::IR::Type                      *regtype;
    const P4::IR::Declaration_Instance      *reg_action = nullptr;
    cstring                             action_type_name;
    enum class param_t { VALUE, OUTPUT, HASH, LEARN, MATCH };
    const std::vector<param_t>          *param_types = nullptr;
    P4::IR::MAU::SaluAction                 *action = nullptr;
    const P4::IR::ParameterList             *params = nullptr;

    struct LocalVar {
        cstring                 name;
        bool                    pair;
        const P4::IR::MAU::SaluRegfileRow   *regfile = nullptr;
        enum use_t { NONE, ALUHI, MEMLO, MEMHI, MEMALL, REGFILE }
                                use = NONE;
        LocalVar(cstring name, bool pair, use_t use = NONE,
            const P4::IR::MAU::SaluRegfileRow *regfile = nullptr)
            : name(name), pair(pair), regfile(regfile), use(use) {}
    }                           *dest = nullptr;  // destination of current assignment
    std::map<cstring, LocalVar> locals;
    enum etype_t {
        // tracks the use (context) of the expression we're currently visiting
        // lvalue contexts
        NONE,    // unknown
        MINMAX_IDX,  // output index of min/max
        // rvalue contexts
        IF,      // condition -- operand of an if
        MINMAX_SRC,  // 128-bit input to min/max instruction
        VALUE,   // value to be written to memory -- alu output
        OUTPUT_ALUHI,   // value to be written to adb via alu_hi alu (non-dual)
        OUTPUT,  // value to be written to action data bus output
        MATCH,   // value to be written to match output
        }                       etype = NONE;
    static bool islvalue(etype_t t) { return t < IF; }
    bool                        negate = false;
    bool                        negate_regfile = false;
    bool                        alu_write[2] = { false, false };
    cstring                     opcode;
    P4::IR::Vector<P4::IR::Expression>                  operands, pred_operands;
    int                                         output_index = -1;
    std::vector<const P4::IR::MAU::SaluInstruction *> cmp_instr;
    const P4::IR::MAU::SaluInstruction              *divmod_instr = nullptr, *minmax_instr = nullptr;
    int                                         minmax_width = -1;  // 0 = min/max8, 1 = min/max16
    const P4::IR::Expression                        *predicate = nullptr;
    const P4::IR::MAU::SaluInstruction              *onebit = nullptr;  // the single 1-bit alu op
    bool                                        onebit_cmpl = false;  // 1-bit op needs cmpl
    int                                         address_subword = 0;
    std::vector<P4::IR::MAU::SaluInstruction  *>    outputs;  // add to end of action body
    std::map<int, const P4::IR::Expression  *>      output_address_subword_predicate;
    P4::IR::MAU::StatefulAlu::MathUnit              math;
    P4::IR::MAU::SaluFunction                       *math_function = nullptr;
    bool                                        assignDone = false;
    int                                         comb_pred_width = 0;
    P4::IR::MAU::SaluAction::ReturnEnumEncoding     *return_encoding = nullptr;
    int                                         return_enum_word = -1;
    bool                                        split_ifs = false;
    std::map<int, const P4::IR::Expression*>        output_param_operands;
    std::map<int, const P4::IR::Expression*>        output_predicates;
    std::set<const P4::IR::Expression*>             or_targets;

    // Map for detection of WAW data hazards
    // * Key is the lvalue
    // * Value is the set of predicates for a given expression and source code position
    // of given assignment
    struct AssignmentProperties {
        const P4::IR::Expression   *predicate;
        const Util::SourceInfo &srcInfo;
        explicit AssignmentProperties(const P4::IR::Expression *pred, const Util::SourceInfo &src) :
            predicate(pred), srcInfo(src) {}
    };
    std::map<cstring,
        std::vector<AssignmentProperties>>   written_dest;
    const P4::IR::AssignmentStatement           *assig_st = nullptr;
    const P4::IR::Expression                    *assig_pred = nullptr;
    void captureAssigstateProps();
    void checkWriteAfterWrite();

    bool isComplexInstruction(const P4::IR::Operation_Binary *op) const;
    void checkAndReportComplexInstruction(const P4::IR::Operation_Binary* op) const;

    /**
     * @brief Insert the instruction into the SALU body.
     *
     * The method tries to search for already inserted instructions if they are same
     * but they have a different predicate at the same time. If so, both instructions are
     * merged together and predicates are aggregated using the | operator.
     */
    void insert_instruction(const P4::IR::MAU::SaluInstruction *si);

    void clearFuncState();
    const P4::IR::MAU::SaluInstruction *createInstruction();
    bool applyArg(const P4::IR::PathExpression *, cstring);
    const P4::IR::Expression *reuseCmp(const P4::IR::MAU::SaluInstruction *cmp, int idx);
    void setupCmp(cstring op);
    void splitWideInstructions();
    void assignOutputAlus();
    const P4::IR::MAU::SaluInstruction *setup_output();
    bool outputEnumAsPredicate(const P4::IR::Member *);
    bool canBeIXBarExpr(const P4::IR::Expression *);
    bool outputAluHi();
    void checkActions(const Util::SourceInfo &srcInfo);

    bool preorder(const P4::IR::Declaration_Instance *di) override;
    bool preorder(const P4::IR::Declaration_Variable *v) override;
    bool preorder(const P4::IR::Property *) override { BUG("unconverted p4_14"); }
    void postorder(const P4::IR::Property *) override { BUG("unconverted p4_14"); }
    bool preorder(const P4::IR::Function *) override;
    void postorder(const P4::IR::Function *) override;
    bool preorder(const P4::IR::Annotations *) override { return false; }
    void doAssignment(const Util::SourceInfo &srcInfo);
    bool preorder(const P4::IR::AssignmentStatement *) override;
    bool preorder(const P4::IR::IfStatement *) override;
    bool preorder(const P4::IR::BlockStatement *) override { return true; }
    bool preorder(const P4::IR::EmptyStatement *) override { return true; }
    bool preorder(const P4::IR::Statement *s) override {
        error("%s: statement too complex for register action %s", s->srcInfo, s);
        return false; }

    void doPrimary(const P4::IR::Expression *, const P4::IR::PathExpression *, cstring);
    bool preorder(const P4::IR::PathExpression *pe) override;
    bool preorder(const P4::IR::Member *m) override;
    bool preorder(const P4::IR::StructExpression *m) override;

    bool preorder(const P4::IR::Constant *) override;
    bool preorder(const P4::IR::BoolLiteral *) override;
    bool preorder(const P4::IR::AttribLocal *) override { BUG("unconverted p4_14"); }
    bool preorder(const P4::IR::Slice *) override;
    bool preorder(const P4::IR::MAU::Primitive *) override;
    bool preorder(const P4::IR::MAU::SaluRegfileRow *) override;
    bool preorder(const P4::IR::Operation::Relation *, cstring op, bool eq);
    bool preorder(const P4::IR::Equ *r) override { return preorder(r, "equ"_cs, true); }
    bool preorder(const P4::IR::Neq *r) override { return preorder(r, "neq"_cs, true); }
    bool preorder(const P4::IR::Grt *r) override { return preorder(r, "grt"_cs, false); }
    bool preorder(const P4::IR::Lss *r) override { return preorder(r, "lss"_cs, false); }
    bool preorder(const P4::IR::Geq *r) override { return preorder(r, "geq"_cs, false); }
    bool preorder(const P4::IR::Leq *r) override { return preorder(r, "leq"_cs, false); }
    bool preorder(const P4::IR::Cast *) override;
    void postorder(const P4::IR::Cast *) override;
    bool preorder(const P4::IR::BFN::SignExtend *) override;
    bool preorder(const P4::IR::BFN::ReinterpretCast *) override { return true; }
    void postorder(const P4::IR::BFN::ReinterpretCast *) override;
    bool preorder(const P4::IR::LNot *) override { return true; }
    void postorder(const P4::IR::LNot *) override;
    bool preorder(const P4::IR::LAnd *) override { return true; }
    void postorder(const P4::IR::LAnd *) override;
    bool preorder(const P4::IR::LOr *) override { return true; }
    void postorder(const P4::IR::LOr *) override;
    bool preorder(const P4::IR::Mux *) override;
    bool preorder(const P4::IR::Add *) override;
    bool preorder(const P4::IR::AddSat *) override;
    bool preorder(const P4::IR::Sub *) override;
    bool preorder(const P4::IR::SubSat *) override;
    bool preorder(const P4::IR::Neg *) override;
    void postorder(const P4::IR::Neg *) override;
    bool preorder(const P4::IR::Cmpl *) override { return true; }
    void postorder(const P4::IR::Cmpl *) override;
    bool preorder(const P4::IR::BAnd *) override;
    void postorder(const P4::IR::BAnd *) override;
    bool preorder(const P4::IR::BOr *) override;
    void postorder(const P4::IR::BOr *) override;
    bool preorder(const P4::IR::BXor *) override;
    void postorder(const P4::IR::BXor *) override;
    bool preorder(const P4::IR::Concat *) override;
    void postorder(const P4::IR::Concat *) override;
    bool divmod(const P4::IR::Operation::Binary *, cstring op);
    bool preorder(const P4::IR::Div *e) override { return divmod(e, "div"_cs); }
    bool preorder(const P4::IR::Mod *e) override { return divmod(e, "mod"_cs); }
    bool preorder(const P4::IR::Expression *e) override {
        error("%s: expression too complex for register action", e->srcInfo);
        return false; }

    friend std::ostream &operator<<(std::ostream &, CreateSaluInstruction::LocalVar::use_t);
    friend std::ostream &operator<<(std::ostream &, CreateSaluInstruction::etype_t);
    static std::map<std::pair<cstring, cstring>, std::vector<param_t>>  function_param_types;

 public:
    explicit CreateSaluInstruction(P4::IR::MAU::StatefulAlu *salu) : salu(salu) {
        if (auto spec = salu->reg->type->to<P4::IR::Type_Specialized>())
            regtype = spec->arguments->at(0);  // RegisterAction
        else
            regtype = P4::IR::Type::Bits::get(1);  // SelectorAction
        visitDagOnce = false; }
};

/** Check all P4::IR::MAU::StatefulAlu objects to make sure they're implementable
 */
class CheckStatefulAlu : public MauModifier {
    // There's a nasty problem outputting the address on jbay -- we have a way of
    // specifying an extra bit via lmatch on the output, but it is shared across
    // all the instructions in the salu.  So we have to ensure all instructions that
    // use lmatch have identical lmatch usage, possibly modifying them.
    struct AddressLmatchUsage : public Inspector {
        static unsigned regmasks[];
        void clear();
        unsigned eval_cmp(const P4::IR::Expression *);
        bool preorder(const P4::IR::MAU::SaluAction *) override;
        bool preorder(const P4::IR::MAU::SaluFunction *) override;
        bool preorder(const P4::IR::MAU::SaluCmpReg *) override;
        bool safe_merge(const P4::IR::Expression *a, const P4::IR::Expression *b, unsigned inuse);
        const P4::IR::MAU::StatefulAlu      *salu;
        unsigned                inuse_mask;      // cmp registers used in this action
        const P4::IR::Expression    *lmatch_operand;
        unsigned                lmatch_inuse_mask;
    } lmatch_usage;

    bool preorder(P4::IR::MAU::StatefulAlu *) override;
    bool preorder(P4::IR::MAU::SaluFunction *) override;
    bool preorder(P4::IR::MAU::Primitive *) override;

    /**
     * @brief Check that register params and large constants used in register actions associated
     * with a given register fit in the device's register file rows.
     *
     */
    void postorder(P4::IR::MAU::StatefulAlu *) override;
    void postorder(P4::IR::MAU::SaluInstruction *) override;

    // FIXME -- Type_Typedef should have been resolved and removed by Typechecking in the
    // midend?  But we're running into it here, so a helper to skip over typedefs.
    static const P4::IR::Type *getType(const P4::IR::Type *t) {
        while (auto td = t->to<P4::IR::Type_Typedef>()) t = td->type;
        return t; }

    std::set<big_int> large_constants;
};

class FixupStatefulAlu : public PassManager {
    /** When a SaluAction (RegisterAction) returns an enum type from its execute
     * method (out arg from the apply method), we use the 'predicate' output to output
     * a 4 bit (tofino) or 16 bit (tofinof2) one-hot encoding of all the predicate tests
     * in the action, and encode the enum that way.  This results in a mask value for
     * each enum tag recording the bits that might be set when we return that tag
     * value.  So all uses of the enum type in the rest of the mau pipeline have to
     * be reencoded appropriately
     *
     * - all metadata fields with the enum type are changed to bit<4> or bit<16>
     * - all tests of a field against a tag (in a gateway) are rewritten to be the
     *   appropriate masked test that will match any one-hot value with its set bit
     *   in the mask computed for that tag
     * - setting a tag value in a VLIW action uses the lowest one-hot matching value.
     * - other operations involving tags are not supported (should be rejected by
     *   frontend typechecker -- can't d add/subtract or other operations on tags
     * - reading an enum tag from an execute call needs to shift down 4 bits, because
     *   the predicate output is output starting from bit 4.
     */

    struct return_enum_info_t {
        cstring                                         enum_name;
        ordered_set<const P4::IR::MAU::SaluAction *>        actions;
        const P4::IR::MAU::SaluAction::ReturnEnumEncoding   *encoding;
    };
    ordered_map<const P4::IR::Type_Enum *, return_enum_info_t>      encodings;
    int                                 pred_type_size;
    const P4::IR::Type::Bits                *pred_type;

    struct FindEncodings : public MauInspector {
        FixupStatefulAlu        &self;
        bool preorder(const P4::IR::MAU::SaluAction *) override;
        bool preorder(const P4::IR::MAU::Action *) override { return false; }
        explicit FindEncodings(FixupStatefulAlu &self) : self(self) {}
    };
    struct UpdateEncodings : public Transform {
        FixupStatefulAlu        &self;
        const P4::IR::BFN::Pipe *preorder(P4::IR::BFN::Pipe *p) override {
            if (self.encodings.empty()) prune();
            return p; }
        const P4::IR::MAU::SaluAction *preorder(P4::IR::MAU::SaluAction *) override;
        const P4::IR::Operation::Relation *preorder(P4::IR::Operation::Relation *) override;
        const P4::IR::Expression *preorder(P4::IR::Member *) override;
        const P4::IR::Expression *preorder(P4::IR::Expression *) override;
        const P4::IR::BFN::ParserRVal *postorder(P4::IR::BFN::SavedRVal *) override;

        explicit UpdateEncodings(FixupStatefulAlu &self) : self(self) {}
    };
    struct ReplaceUpdatedEnumTypes : public Transform {
        FixupStatefulAlu        &self;
        const P4::IR::Expression *postorder(P4::IR::Expression *exp) {
            visit(exp->type, "type");
            return exp; }
        const P4::IR::Type *preorder(P4::IR::Type_Enum *enum_t) {
            if (self.encodings.count(getOriginal<P4::IR::Type_Enum>()))
                return self.pred_type;
            return enum_t; }
        explicit ReplaceUpdatedEnumTypes(FixupStatefulAlu &self) : self(self) {}
    };

 public:
    FixupStatefulAlu() : PassManager({
        new CheckStatefulAlu,
        new FindEncodings(*this),
        new UpdateEncodings(*this),
        new ReplaceUpdatedEnumTypes(*this),
    }) {
        pred_type_size = 1 << Device::statefulAluSpec().CmpUnits.size();
        pred_type = P4::IR::Type::Bits::get(pred_type_size);
    }
};

#endif /* EXTENSIONS_BF_P4C_MAU_STATEFUL_ALU_H_ */
