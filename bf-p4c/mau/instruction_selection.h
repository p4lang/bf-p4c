#ifndef _TOFINO_MAU_INSTRUCTION_SELECTION_H_
#define _TOFINO_MAU_INSTRUCTION_SELECTION_H_

#include "mau_visitor.h"
#include "tofino/phv/phv_fields.h"

class InstructionSelection : public MauTransform {
    PhvInfo &phv;
    const IR::MAU::Action *af = nullptr;
    class SplitInstructions;
    std::vector<const IR::Primitive *>  stateful;

    profile_t init_apply(const IR::Node *root) override;
    const IR::GlobalRef *preorder(IR::GlobalRef *) override;
    const IR::MAU::Action *preorder(IR::MAU::Action *) override;
    const IR::MAU::Action *postorder(IR::MAU::Action *) override;
    const IR::Expression *postorder(IR::Add *) override;
    const IR::Expression *postorder(IR::Sub *) override;
    const IR::Expression *postorder(IR::Shr *) override;
    const IR::Expression *postorder(IR::Shl *) override;
    const IR::Expression *postorder(IR::BAnd *) override;
    const IR::Expression *postorder(IR::BOr *) override;
    const IR::Expression *postorder(IR::BXor *) override;
    const IR::Expression *postorder(IR::Cmpl *) override;
    const IR::Expression *postorder(IR::Cast *) override;
    const IR::Expression *postorder(IR::Mux *) override;
    const IR::Expression *postorder(IR::BoolLiteral *) override;
    const IR::Expression *postorder(IR::Primitive *) override;
    const IR::MAU::Instruction *postorder(IR::MAU::Instruction *i) override { return i; }

    bool checkPHV(const IR::Expression *);
    bool checkSrc1(const IR::Expression *);
    bool checkConst(const IR::Expression *ex, long &value);
    IR::Member *gen_stdmeta(cstring field);

 public:
    explicit InstructionSelection(PhvInfo &phv);
};

class StatefulHashDistSetup : public MauTransform, TofinoWriteContext {
    const PhvInfo &phv;
    IR::TempVar *saved_tempvar;
    IR::MAU::HashDist *saved_hashdist;
    ordered_set<cstring> remove_tempvars;
    ordered_map<cstring, IR::MAU::HashDist *> stateful_alu_from_hash_dists;
    const IR::MAU::Action *preorder(IR::MAU::Action *) override;
    const IR::MAU::Instruction *preorder(IR::MAU::Instruction *) override;
    const IR::TempVar *preorder(IR::TempVar *) override;
    const IR::MAU::HashDist *preorder(IR::MAU::HashDist *) override;
    const IR::MAU::Instruction *postorder(IR::MAU::Instruction *) override;
    const IR::MAU::Table *postorder(IR::MAU::Table *) override;
    IR::MAU::HashDist *create_hash_dist(const IR::Expression *e, const IR::Primitive *prim);

 public:
    explicit StatefulHashDistSetup(const PhvInfo &p) : phv(p) {}
};

class DoInstructionSelection : public PassManager {
 public:
     explicit DoInstructionSelection(PhvInfo &);
};

#endif /* _TOFINO_MAU_INSTRUCTION_SELECTION_H_ */
