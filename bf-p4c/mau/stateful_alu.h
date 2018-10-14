#ifndef EXTENSIONS_BF_P4C_MAU_STATEFUL_ALU_H_
#define EXTENSIONS_BF_P4C_MAU_STATEFUL_ALU_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "mau_visitor.h"
#include "bf-p4c/device.h"

struct Device::StatefulAluSpec {
    bool                        CmpMask;  // are cmp oprerands maskable?
    std::vector<cstring>        CmpUnits;
    int                         MaxSize;
    int                         OutputWords;
    bool                        DivModUnit;

    cstring cmpUnit(unsigned idx) const { return idx < CmpUnits.size() ? CmpUnits.at(idx) : "??"; }
};

/**
Converts a P4_14 stateful_alu extern object (a Declaration_Instance
of type stateful_alu) into an MAU::SaluAction for an MAU::StatefulAlu,
converting all of the properties into the corresponding instructions or
whatever else is needed.

The pass is designed to be applied to a subtree of IR containing a single
Declaration_Instance object of type register_action or selector_action,
and creates an SaluAction for it, adding it to the StatefulAlu passed
to the pass constructor.

This is really a kind of "reconstruction transform" rather than an
Inspector, but the normal Transform isn't right for it, as we want to
rebuild some things with a very different object (turning Properties into
Instructions) which won't work 'in place'.  It also really wants to do
pattern matching across expression trees, which our Visitor infrastructure
does not support very well.

It can be thought of as a state machine + code accumulator that is run
over the body of the register_action.  The 'etype' state tracks what
the currently visited expression is needed for (left or right side of
an assignment, or condition in an 'if').  Operands of an instruction
are accumulated, existence and uses of local variables are tracked,
and instructions are generated and added to the body of the SaluAction
that is being created.  Along the way and at the end, various problems
that exceeed the capabilities of the salu are diagnosed.

*/
class CreateSaluInstruction : public Inspector {
    IR::MAU::StatefulAlu                *salu;
    const IR::Type                      *regtype;
    const IR::Declaration_Instance      *reg_action = nullptr;
    cstring                             action_type_name;
    enum class param_t { VALUE, OUTPUT, HASH, LEARN, MATCH };
    const std::vector<param_t>          *param_types;
    IR::MAU::SaluAction                 *action = nullptr;
    const IR::ParameterList             *params = nullptr;
    struct LocalVar {
        cstring                 name;
        bool                    pair;
        enum use_t { NONE, ALUHI, MEMLO, MEMHI, MEMALL }
                                use = NONE;
        LocalVar(cstring name, bool pair, use_t use = NONE)
        : name(name), pair(pair), use(use) {}
    }                           *dest = nullptr;  // destination of current assignment
    std::map<cstring, LocalVar> locals;
    enum etype_t {
        // tracks the use (context) of the expression we're currently visiting
        NONE,    // unknown (generally, an lvalue)
        IF,      // condition -- operand of an if
        VALUE,   // value to be written to memory -- alu output
        OUTPUT,  // value to be written to action data bus output
        MATCH,   // value to be written to match output
        }                       etype = NONE;
    bool                        negate = false;
    bool                        alu_write[2] = { false, false };
    cstring                     opcode;
    IR::Vector<IR::Expression>                  operands, pred_operands;
    int                                         output_index;
    std::vector<const IR::MAU::Instruction *>   cmp_instr;
    const IR::MAU::Instruction                  *divmod_instr = nullptr, *minmax_instr = nullptr;
    const IR::Expression                        *predicate = nullptr;
    const IR::MAU::Instruction                  *onebit = nullptr;  // the single 1-bit alu op
    bool                                        onebit_cmpl = false;  // 1-bit op needs cmpl
    int                                         address_subword = 0;
    std::vector<IR::MAU::Instruction  *>        outputs;  // add to end of action body
    std::map<int, const IR::Expression  *>      output_address_subword_predicate;
    IR::MAU::StatefulAlu::MathUnit              math;
    IR::MAU::SaluFunction                       *math_function = nullptr;

    const IR::MAU::Instruction *createInstruction();
    bool applyArg(const IR::PathExpression *, cstring);
    const IR::Expression *reuseCmp(const IR::MAU::Instruction *cmp, int idx);
    const IR::MAU::Instruction *setup_output();

    bool preorder(const IR::Declaration_Instance *di) override;
    bool preorder(const IR::Declaration_Variable *v) override;
    bool preorder(const IR::Property *) override { BUG("unconverted p4_14"); }
    void postorder(const IR::Property *) override { BUG("unconverted p4_14"); }
    bool preorder(const IR::Function *) override;
    void postorder(const IR::Function *) override;
    bool preorder(const IR::Annotations *) override { return false; }
    bool preorder(const IR::AssignmentStatement *) override;
    bool preorder(const IR::IfStatement *) override;
    bool preorder(const IR::BlockStatement *) override { return true; }
    bool preorder(const IR::Statement *s) override {
        error("%s: statement too complex for register action", s->srcInfo);
        return false; }
    bool preorder(const IR::PathExpression *) override;

    bool preorder(const IR::Constant *) override;
    bool preorder(const IR::AttribLocal *) override { BUG("unconverted p4_14"); }
    bool preorder(const IR::Member *) override;
    bool preorder(const IR::Slice *) override;
    bool preorder(const IR::Primitive *) override;
    bool preorder(const IR::Operation::Relation *, cstring op, bool eq);
    bool preorder(const IR::Equ *r) override { return preorder(r, "equ", true); }
    bool preorder(const IR::Neq *r) override { return preorder(r, "neq", true); }
    bool preorder(const IR::Grt *r) override { return preorder(r, "grt", false); }
    bool preorder(const IR::Lss *r) override { return preorder(r, "lss", false); }
    bool preorder(const IR::Geq *r) override { return preorder(r, "geq", false); }
    bool preorder(const IR::Leq *r) override { return preorder(r, "leq", false); }
    bool preorder(const IR::Cast *) override { return true; }
    bool preorder(const IR::LNot *) override { return true; }
    void postorder(const IR::LNot *) override;
    bool preorder(const IR::LAnd *) override { return true; }
    void postorder(const IR::LAnd *) override;
    bool preorder(const IR::LOr *) override { return true; }
    void postorder(const IR::LOr *) override;
    bool preorder(const IR::Add *) override;
    bool preorder(const IR::Sub *) override;
    bool preorder(const IR::Cmpl *) override { return true; }
    void postorder(const IR::Cmpl *) override;
    bool preorder(const IR::BAnd *) override;
    void postorder(const IR::BAnd *) override;
    bool preorder(const IR::BOr *) override;
    bool preorder(const IR::BXor *) override;
    bool preorder(const IR::Concat *) override;
    void postorder(const IR::Concat *) override;
    bool divmod(const IR::Operation::Binary *, cstring op);
    bool preorder(const IR::Div *e) override { return divmod(e, "div"); }
    bool preorder(const IR::Mod *e) override { return divmod(e, "mod"); }
    bool preorder(const IR::Expression *e) override {
        error("%s: expression too complex for register action", e->srcInfo);
        return false; }

    friend std::ostream &operator<<(std::ostream &, CreateSaluInstruction::LocalVar::use_t);
    friend std::ostream &operator<<(std::ostream &, CreateSaluInstruction::etype_t);
    static std::map<std::pair<cstring, cstring>, std::vector<param_t>>  function_param_types;

 public:
    explicit CreateSaluInstruction(IR::MAU::StatefulAlu *salu) : salu(salu) {
        if (auto spec = salu->reg->type->to<IR::Type_Specialized>())
            regtype = spec->arguments->at(0);  // register_action
        else
            regtype = IR::Type::Bits::get(1);  // selector_action
        visitDagOnce = false; }
};

/** Check all IR::MAU::StatefulAlu objects to make sure they're implementable
 */
class CheckStatefulAlu : public MauModifier {
    bool preorder(IR::MAU::StatefulAlu *) override;
    // FIXME -- Type_Typedef should have been resolved and removed by Typechecking in the
    // midend?  But we're running into it here, so a helper to skip over typedefs.
    static const IR::Type *getType(const IR::Type *t) {
        while (auto td = t->to<IR::Type_Typedef>()) t = td->type;
        return t; }
};

#endif /* EXTENSIONS_BF_P4C_MAU_STATEFUL_ALU_H_ */
