#ifndef _TOFINO_MAU_INSTRUCTION_SELECTION_H_
#define _TOFINO_MAU_INSTRUCTION_SELECTION_H_

#include "mau_visitor.h"

class InstructionSelection : public MauTransform {
    const IR::ActionFunction *preorder(IR::ActionFunction *) override;
    const IR::ActionFunction *postorder(IR::ActionFunction *) override;
    const IR::Primitive *postorder(IR::Primitive *) override;
};

#endif /* _TOFINO_MAU_INSTRUCTION_SELECTION_H_ */
