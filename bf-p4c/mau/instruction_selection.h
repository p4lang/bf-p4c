#ifndef BF_P4C_MAU_INSTRUCTION_SELECTION_H_
#define BF_P4C_MAU_INSTRUCTION_SELECTION_H_

#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/mau/mau_visitor.h"

class PhvInfo;

/** The general purpose of instruction selection is to completely transform all P4 frontend code
 *  to parallel instructions that the compiler can completely understand.  These parallel
 *  instructions are encoded in IR::MAU::Instruction.
 *
 *  Currently the following classes exist to perform the conversion:
 *    - InstructionSelection: generic all-purpose class for handling the complete translation
 *      between frontend IR and backend.
 *    - StatefulHashDistSetup: specifically to create or possibly link IR::MAU::HashDist units
 *      with their associated IR::MAU::BackendAttached tables
 *    - ConvertCastsToSlices: Conversion of all IR::Casts to IR::Slices as expressions.
 *      Specifically on assignment, will extend or possibly not extend the value that is being
 *      written
 *    - VerifyActions: Verifies that all generated instructions will be correctly understood
 *      and interpreted by the remainder of the compiler
 */
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
    // const IR::Expression *postorder(IR::Cast *) override;
    const IR::Expression *postorder(IR::Mux *) override;
    const IR::Expression *postorder(IR::BoolLiteral *) override;
    const IR::Node *postorder(IR::Primitive *) override;
    const IR::MAU::Instruction *postorder(IR::MAU::Instruction *i) override { return i; }

    bool checkPHV(const IR::Expression *);
    bool checkSrc1(const IR::Expression *);
    bool checkConst(const IR::Expression *ex, long &value);
    bool equiv(const IR::Expression *a, const IR::Expression *b);
    IR::Member *genIntrinsicMetadata(gress_t gress, cstring header, cstring field);

 public:
    explicit InstructionSelection(PhvInfo &phv);
};

/** This pass was specifically created to deal with adding the HashDist object to different
 *  stateful objects.  On one particular case, execute_stateful_alu_from_hash was creating
 *  two separate instructions, a TempVar = hash function call, and an execute stateful call
 *  addressed by this TempVar.  This pass combines these instructions into one instruction,
 *  and correctly saves the HashDist IR into these attached tables
 */
class StatefulHashDistSetup : public PassManager {
    const PhvInfo &phv;
    const IR::TempVar *saved_tempvar;
    const IR::MAU::HashDist *saved_hashdist;
    ordered_set<cstring> remove_tempvars;
    ordered_set<const IR::Node *> remove_instr;
    ordered_map<cstring, const IR::MAU::HashDist *> stateful_alu_from_hash_dists;
    ordered_map<const IR::Node *, const IR::MAU::HashDist *> update_hd;
    profile_t init_apply(const IR::Node *root) override {
        remove_tempvars.clear();
        remove_instr.clear();
        stateful_alu_from_hash_dists.clear();
        update_hd.clear();
        return PassManager::init_apply(root); }
    class Scan : public MauInspector, TofinoWriteContext {
        StatefulHashDistSetup &self;
        bool preorder(const IR::MAU::Action *) override;
        bool preorder(const IR::MAU::Instruction *) override;
        bool preorder(const IR::TempVar *) override;
        bool preorder(const IR::MAU::HashDist *) override;
        void postorder(const IR::MAU::Instruction *) override;
        void postorder(const IR::MAU::Table *) override;
     public:
        explicit Scan(StatefulHashDistSetup &self) : self(self) {}
    };
    class Update : public MauTransform {
        StatefulHashDistSetup &self;
        const IR::MAU::Table *postorder(IR::MAU::Table *) override;
        const IR::MAU::Synth2Port *preorder(IR::MAU::Synth2Port *sp) override;
        const IR::MAU::Instruction *preorder(IR::MAU::Instruction *sp) override;
     public:
        explicit Update(StatefulHashDistSetup &self) : self(self) {}
    };

    const IR::MAU::HashDist *find_hash_dist(const IR::Expression *expr, const IR::Primitive *prim);
    IR::MAU::HashDist *create_hash_dist(const IR::Expression *e, const IR::Primitive *prim);

 public:
    explicit StatefulHashDistSetup(const PhvInfo &p) : phv(p) {
        addPasses({ new Scan(*this), new Update(*this) }); }
};

class ConvertCastToSlice : public MauTransform, P4WriteContext {
    bool contains_cast = false;
    const IR::MAU::Instruction *preorder(IR::MAU::Instruction *) override;
    const IR::Expression *preorder(IR::Slice *) override;
    const IR::Node *preorder(IR::Cast *) override;
    const IR::MAU::SaluAction *preorder(IR::MAU::SaluAction *) override;
    const IR::Node *postorder(IR::MAU::Instruction *) override;
};

class DoInstructionSelection : public PassManager {
 public:
     explicit DoInstructionSelection(PhvInfo &);
};

#endif /* BF_P4C_MAU_INSTRUCTION_SELECTION_H_ */
