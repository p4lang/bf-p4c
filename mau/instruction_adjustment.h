#ifndef _TOFINO_MAU_INSTRUCTION_ADJUSTMENT_H_
#define _TOFINO_MAU_INSTRUCTION_ADJUSTMENT_H_

#include "mau_visitor.h"
#include "resource.h"
#include "tofino/phv/phv.h"

/** The purpose of this class is to adjust the instructions in a single action that perform on
 *  multiple containers into one single action for the entire container.  The pass also
 *  verifies that many Tofino specific constraints for the individual ALUs either through the
 *  PHVs being adapted or the action data being manipulated.
 *
 *  The adjustment specificially is from a field to field instruction into a container by
 *  container instruction for the more complex requirements.  This either can break an field
 *  by field instruction into multiple container instructions, or combine them into a single one.
 *
 *  For example, the instructions before this pass look like the following:
 *      -set header.field1, header.field2
 *      -set header.field3, header.field4
 *      -set header.field5, action_data_param
 *
 *  In these instructions, there is only one field written to, and up to two fields read from,
 *  in i.e. a bit or an arithmetic operation.  However, if header.field1 and header.field3 were
 *  in the same PHV container, the assembler does not understand multiple instruction calls on
 *  the same container, and would fail.  Thus this pass would remove these instruction, and in
 *  their place put the names of the PHV containers instead, along the lines of:
 *      -set W1(0..23), W5(8..31)
 *
 *  The other major case is the splitting of fields. Say header.field5 is in multiple containers.
 *  The action_data_param may not come into the ALUs contiguously, and thus must be broken into
 *  instruction based on the allocation within the containers:
 *      -set header.field5.0-31 action_data_param.0-31
 *      -set header.field5.32-47 action_data_param.32-47
 */
class InstructionAdjustment : public MauTransform, P4WriteContext {
    PhvInfo &phv;
    const IR::MAU::Table *tbl;

    /** A way to encapsulate the information contained within a single operand of an instruction,
     *  whether the instruction is read from or written to.  Also contains the information on
     *  what particular bits of the mask are encapsulated.
     */
    struct ActionParam {
        enum type_t { PHV, ACTIONDATA, CONSTANT, TOTAL_TYPES } type;
        const IR::Expression *expr;
        cstring name;
        bool is_split = false;
        int lo = -1;
        int hi = -1;
        int cont_bit = -1;

        ActionParam() : expr(nullptr) {}
        ActionParam(type_t t, const IR::Expression *e, int size)
            : type(t), expr(e), lo(0), hi(size - 1) {}
        void set_split(int l, int h) {
            is_split = true;
            lo = l; hi = h;
        }
    };

    /** Information on the entire instruction, essentially what field is written and from which
     *  fields the field is written from.  These can be broken down and analyzed on a container
     *  by container basis.
     */
    struct InstructionProcess {
        bool write_found = false;
        cstring name;
        ActionParam write;
        bitvec write_cont_bits;
        vector<ActionParam> reads;
        void clear() {
            write_found = false;
            reads.clear();
        }

        void setWrite(ActionParam w) {
            write_found = true;
            write = w;
        }
    };

    /** Information on the PHV fields that are read by an individual field instruction.  Used
     *  for verification and combining the PHV fields into MultiOperands.
     */
    struct ReadInfo {
        bitvec write_bits;
        bitvec read_bits;
        ReadInfo(bitvec wb, bitvec rb) : write_bits(wb), read_bits(rb) {}
    };
    /** Information on the action data field contained within the instruction.  The action data
     *  could be affected by multiple individual fields.  Assumes that only one action data field
     *  appears in each instruction, as the ALU can only use one action data field.
     */
    struct ActionDataInfo {
        cstring action_data_name;
        bool immediate = false;
        int start = -1;
        int total_field_affects = 0;
        int field_affects = 0;
        vector<ReadInfo> read_action_data;
        bitvec total_write_bits;
        bitvec total_read_bits;
    };


    /** Information on all PHV reads affecting a single container.  Again used for verification
     *  and combining fields into MultiOperands
     */
    struct TotalReadPhvInfo {
        vector<ReadInfo> read_phvs;
        bool aligned = false;
        bitvec total_write_bits;
        bitvec total_read_bits;
    };

    /** Information on all of the indivdidual reads and writes within a single PHV container
     *  in an action function.  Essentially coordinate to all the action that can happen
     *  within a single VLIW ALU
     */
    struct ContainerProcess {
        bool requires_adjustment = false;
        bool unhandled_action = false;
        cstring name;
        ActionDataInfo adi;
        std::map<PHV::Container, TotalReadPhvInfo> total_reads_phvs;

        int counts[ActionParam::TOTAL_TYPES] = {0, 0, 0};
        vector<InstructionProcess> instr_procs;
        int total_types() {
            return counts[ActionParam::PHV] + counts[ActionParam::ACTIONDATA]
                   + counts[ActionParam::CONSTANT];
        }

        int operands() {
            if (instr_procs.size() == 0)
                BUG("Cannot call operands function on empty container process");
            return instr_procs[0].reads.size();
        }

        bitvec total_write() {
            bitvec writes;
            for (auto &total_read : total_reads_phvs) {
                writes |= total_read.second.total_write_bits;
            }
            writes |= adi.total_write_bits;
            return writes;
        }
    };

    /** This is the structure that holds all of the ALUs that are affected by the individual action
     *  function.  The map is the container being written into.
     */
    typedef std::map<PHV::Container, ContainerProcess> ContainerActions;
    ContainerActions container_actions;

    /** This inspector builds the container_actions structure for a single action.  Builds
     *  the writes and reads vector of each InstructionProcess, and then will be break the
     *  write into how it's broken throughout each of the containers the write is contained in.
     */
    class BuildContainerActions : public MauInspector, P4WriteContext {
        PhvInfo &phv;
        ContainerActions &container_actions;
        InstructionProcess instr_process;
        bool preorder(const IR::ActionArg *arg) override;
        bool preorder(const IR::Expression *expr) override;
        bool preorder(const IR::Constant *constant) override;
        bool preorder(const IR::MAU::Instruction *instr) override;
        bool preorder(const IR::Primitive *prim) override;
        void postorder(const IR::MAU::Instruction *instr) override;
        bool preorder(const IR::MAU::AttachedOutput *) override {
            // ignore these for now -- DON'T recurse into the stateful object
            return false; }
     public:
        BuildContainerActions(PhvInfo &p, ContainerActions &ca)
           : phv(p), container_actions(ca), instr_process() {}
    };

    typedef std::map<PHV::Container, vector<IR::MAU::Instruction *>> RemovedInstr;
    RemovedInstr removed_instrs;

    /** Structure to help build the MultiOperands if the write is affected by multiple PHVs.
     */
    struct MultiOperandInfo {
        IR::MAU::MultiOperand *write = nullptr;
        vector<IR::MAU::MultiOperand *> reads;
    };

    cstring action_name;
    PhvInfo::Field *written_field;
    void analyze_container_actions(cstring action_name);
    bool verify_action_data(const ActionParam &write, ActionParam &read,
        cstring action_name, ActionDataInfo &adi, int &count, const PHV::Container &container);
    bool verify_phv_field(const ActionParam &write, ActionParam &read,
                          ContainerProcess &cont_proc, int &count);
    bool verify_constant(const ActionParam &write, ActionParam &read, int &count);
    void verify_all_constraints(ContainerProcess &cont_proc, cstring action_name,
                                PHV::Container container);
    bool verify_alignment(bitvec &total_wb, bitvec &total_rb, PHV::Container container,
            bool &is_aligned, ContainerProcess &cont_proc);

    void combine_cont_instr(ContainerProcess &cont_proc, MultiOperandInfo &mo,
        PHV::Container container);

    void perform_simple_split(ContainerProcess &cont_proc, IR::MAU::Action *act,
         PHV::Container container);


    const IR::MAU::Action *preorder(IR::MAU::Action *) override;
    const IR::MAU::Instruction *preorder(IR::MAU::Instruction *) override;
    const IR::ActionArg *preorder(IR::ActionArg *) override;
    const IR::Expression *preorder(IR::Expression *) override;
    const IR::Constant *preorder(IR::Constant *) override;
    const IR::Primitive *preorder(IR::Primitive *) override;
    const IR::MAU::Instruction *postorder(IR::MAU::Instruction *) override;
    const IR::MAU::Action *postorder(IR::MAU::Action *) override;
    // ignore stuff related to stateful alus
    const IR::MAU::AttachedOutput *preorder(IR::MAU::AttachedOutput *ao) override {
        prune(); return ao; }
    const IR::MAU::StatefulAlu *preorder(IR::MAU::StatefulAlu *salu) override {
        prune(); return salu; }

 public:
    explicit InstructionAdjustment(PhvInfo &p, const IR::MAU::Table *t) : phv(p), tbl(t) {}
};


class TotalInstructionAdjustment : public MauTransform, P4WriteContext {
    PhvInfo &phv;
    const IR::MAU::Table *preorder(IR::MAU::Table *) override;
 public:
    explicit TotalInstructionAdjustment(PhvInfo &p) : phv(p) {}
};

#endif /* _TOFINO_MAU_INSTRUCTION_ADJUSTMENT_H_ */
