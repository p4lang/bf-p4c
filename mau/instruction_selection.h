#ifndef _TOFINO_MAU_INSTRUCTION_SELECTION_H_
#define _TOFINO_MAU_INSTRUCTION_SELECTION_H_

#include "mau_visitor.h"
#include "tofino/phv/phv_fields.h"

class InstructionSelection : public MauTransform {
    const PhvInfo &phv;
    const IR::ActionFunction *preorder(IR::ActionFunction *) override;
    const IR::ActionFunction *postorder(IR::ActionFunction *) override;
    const IR::Primitive *postorder(IR::Primitive *) override;

 public:
    explicit InstructionSelection(const PhvInfo &phv) : phv(phv) {}
};

#endif /* _TOFINO_MAU_INSTRUCTION_SELECTION_H_ */
