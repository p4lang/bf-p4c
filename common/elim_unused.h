#ifndef TOFINO_COMMON_ELIM_UNUSED_H_
#define TOFINO_COMMON_ELIM_UNUSED_H_

#include "field_defuse.h"

class ElimUnused : public Transform {
    const PhvInfo       &phv;
    const FieldDefUse   &defuse;

    IR::Primitive *preorder(IR::Primitive *prim) override {
        if (prim->name == "extract" && phv.field(prim->operands[0]) &&
            defuse.getUses(prim->operands[0]).empty()) {
            return nullptr; }
        return prim; }
    IR::MAU::Instruction *preorder(IR::MAU::Instruction *i) override {
        if (defuse.getUses(i->operands[0]).empty())
            return nullptr;
        return i; }

 public:
    ElimUnused(const PhvInfo &phv, const FieldDefUse &defuse) : phv(phv), defuse(defuse) {}
};

#endif /* TOFINO_COMMON_ELIM_UNUSED_H_ */
