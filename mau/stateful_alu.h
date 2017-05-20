#ifndef EXTENSIONS_TOFINO_MAU_STATEFUL_ALU_H_
#define EXTENSIONS_TOFINO_MAU_STATEFUL_ALU_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "mau_visitor.h"

/**
Converts a P4_14 stateful_alu extern object (a Declaration_Instance
of type stateful_alu) into an MAU::SaluAction for an MAU::StatefulAlu,
converting all of the properties into the corresponding instructions or
whatever else is needed.

The pass is designed to be applied to a subtree of IR containing one or
more Declaration_Instance objects of type stateful_alu, and creates an
SaluAction for each, adding them to the StatefulAlu passed to the pass
constructor.  In practice it will always be called directly on a single
Declaration_Instance.

This is really a kind of "reconstruction transform" rather than an
Inspector, bu the normal Transform isn't right for it, as we want to
rebuild some things with a very different object (turning Properties into
Instructions) which won't work 'in place'.  It also really wants to do
pattern matching across expression trees, which our Visitor infrastructure
does not support very well.
*/
class CreateSaluInstruction : public Inspector {
    IR::MAU::StatefulAlu        *salu;
    IR::MAU::SaluAction         *action = nullptr;
    enum { NONE, COND, PRED, VALUE, OUTPUT, BIT_INSTR } etype = NONE;
    bool                        negate = false;
    cstring                     opcode;
    std::vector<const IR::Expression *> operands;
    const IR::Expression        *predicates[5];
    const IR::MAU::Instruction  *output;
    IR::MAU::StatefulAlu::MathUnit      math;
    IR::MAU::SaluMathFunction   *math_function = nullptr;
    const IR::Expression        *math_input = nullptr;

    bool preorder(const IR::Declaration_Instance *di) override;
    bool preorder(const IR::Property *) override;
    void postorder(const IR::Property *) override;
    bool preorder(const IR::Constant *) override;
    bool preorder(const IR::AttribLocal *) override;
    bool preorder(const IR::Member *) override;
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
    bool preorder(const IR::BOr *) override;
    bool preorder(const IR::BXor *) override;
    bool preorder(const IR::Expression *e) override {
        error("%s: expression too complex for stateful alu", e->srcInfo);
        return false; }

 public:
    explicit CreateSaluInstruction(IR::MAU::StatefulAlu *salu) : salu(salu) {}
};

/** Check all IR::MAU::StatefulAlu objects to make sure they're implementable
 */
class CheckStatefulAlu : public MauModifier {
    bool preorder(IR::MAU::StatefulAlu *) override;
};

#endif /* EXTENSIONS_TOFINO_MAU_STATEFUL_ALU_H_ */
