#ifndef _TOFINO_MAU_INSTRUCTION_SELECTION_H_
#define _TOFINO_MAU_INSTRUCTION_SELECTION_H_

#include "mau_visitor.h"
#include "tofino/phv/phv_fields.h"

class InstructionSelection : public MauTransform {
    PhvInfo &phv;
    const IR::ActionFunction *af = nullptr;
    class SplitInstructions;
    std::map<const IR::ActionFunction *, std::vector<const IR::Primitive *>> stateful;

    profile_t init_apply(const IR::Node *root) override;
    const IR::ActionFunction *preorder(IR::ActionFunction *) override;
    const IR::ActionFunction *postorder(IR::ActionFunction *) override;
    const IR::Expression *postorder(IR::Add *) override;
    const IR::Expression *postorder(IR::Sub *) override;
    const IR::Expression *postorder(IR::Shr *) override;
    const IR::Expression *postorder(IR::Shl *) override;
    const IR::Expression *postorder(IR::BAnd *) override;
    const IR::Expression *postorder(IR::BOr *) override;
    const IR::Expression *postorder(IR::BXor *) override;
    const IR::Expression *postorder(IR::Cmpl *) override;
    const IR::Expression *postorder(IR::Cast *) override;
    const IR::Primitive *postorder(IR::Primitive *) override;
    const IR::MAU::Instruction *postorder(IR::MAU::Instruction *i) override { return i; }
    const IR::MAU::Table *postorder(IR::MAU::Table *) override;

    bool checkPHV(const IR::Expression *);
    bool checkSrc1(const IR::Expression *);
    bool checkConst(const IR::Expression *ex, long &value);
    IR::Member *gen_stdmeta(cstring field);
 public:
    explicit InstructionSelection(PhvInfo &phv);
};

#endif /* _TOFINO_MAU_INSTRUCTION_SELECTION_H_ */
