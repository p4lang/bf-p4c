#ifndef BF_P4C_MAU_INSTRUCTION_ADJUSTMENT_H_
#define BF_P4C_MAU_INSTRUCTION_ADJUSTMENT_H_

#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/mau/action_analysis.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/phv/phv.h"
#include "lib/safe_vector.h"

namespace PHV {
class Field;
}  // namespace PHV

/** The purpose of these classes is to adjust the instructions in a single action that perform on
 *  multiple containers into one single action for the entire container.  The pass also
 *  verifies that many Tofino specific constraints for the individual ALUs either through the
 *  PHVs being adapted or the action data being manipulated.
 *
 *  The adjustment specificially is from a field to field instruction into a container by
 *  container instruction for the more complex requirements.  This either can break an field
 *  by field instruction into multiple container instructions, performed by SplitInstructions, 
 *  or combine them into a single one, performed by MergeInstructions.
 *
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
 *  Another major case is the splitting of fields. Say header.field5 is in multiple containers.
 *  The action_data_param may not come into the ALUs contiguously, and thus must be broken into
 *  instruction based on the allocation within the containers:
 *      -set header.field5.0-31 action_data_param.0-31
 *      -set header.field5.32-47 action_data_param.32-47
 *
 *  In particular, some constants have to be converted to action data, based on how they are
 *  use in an instruction within a container.  These constraints are fully detailed by 
 *  comments in action_analysis, but are summarized by the restrictions from load const and one
 *  of the sources of an action
 */


/** Responsible for splitting all field instructions over multiple containers into multiple
 *  field instructions over a single container, for example, let's say the program has
 *  the following field instruction:
 *     -set hdr.f1, hdr.f2
 *
 *  where hdr.f1 is in two PHV containers.  This will split this into
 *
 *     -set hdr.f1(A..B), hdr.f2(A..B)
 *     -set hdr.f1(C..D), hdr.f2(C..D)
 *
 *  where A..B and C..D are the write ranges of f1 within its associated container
 */
class SplitInstructions : public MauTransform, TofinoWriteContext {
    const PhvInfo &phv;
    ActionAnalysis::ContainerActionsMap container_actions_map;
    ordered_set<const PHV::Field *> split_fields;
    ordered_map<const PHV::Field *, IR::MAU::Instruction *> removed_instrs;

    bool write_found = false;
    bool meter_color = false;
    ordered_set<const PHV::Field *>::iterator split_location;

    const IR::MAU::Action *preorder(IR::MAU::Action *) override;
    const IR::MAU::Instruction *preorder(IR::MAU::Instruction *) override;
    const IR::ActionArg *preorder(IR::ActionArg *) override;
    const IR::Expression *preorder(IR::Expression *) override;
    const IR::Constant *preorder(IR::Constant *) override;
    const IR::Primitive *preorder(IR::Primitive *) override;
    const IR::MAU::Instruction *postorder(IR::MAU::Instruction *) override;
    const IR::MAU::Action *postorder(IR::MAU::Action *) override;
    // ignore stuff related to stateful alus
    const IR::Node *preorder(IR::Node *) override;
    const IR::MAU::AttachedOutput *preorder(IR::MAU::AttachedOutput *ao) override;
    const IR::MAU::StatefulAlu *preorder(IR::MAU::StatefulAlu *salu) override;
    const IR::MAU::HashDist *preorder(IR::MAU::HashDist *hd) override;

 public:
    explicit SplitInstructions(const PhvInfo &p) : phv(p) { visitDagOnce = false; }
};

/** Responsible for converting IR::Constant to IR::MAU::ActionDataConstants when necessary.
 *  If a constant is not able to be saved within an instruction, this will turn the constant
 *  into an action data slot location
 */
class ConstantsToActionData : public MauTransform, TofinoWriteContext {
    const PhvInfo &phv;
    ActionAnalysis::ContainerActionsMap container_actions_map;

    const IR::MAU::Action *preorder(IR::MAU::Action *) override;
    const IR::MAU::Instruction *preorder(IR::MAU::Instruction *) override;
    const IR::ActionArg *preorder(IR::ActionArg *) override;
    const IR::Expression *preorder(IR::Expression *) override;
    const IR::Constant *preorder(IR::Constant *) override;
    const IR::Slice *preorder(IR::Slice *) override;
    void analyze_phv_field(IR::Expression *);
    const IR::Primitive *preorder(IR::Primitive *) override;
    const IR::MAU::Instruction *postorder(IR::MAU::Instruction *) override;
    const IR::MAU::Action *postorder(IR::MAU::Action *) override;

    const IR::MAU::AttachedOutput *preorder(IR::MAU::AttachedOutput *) override;
    const IR::MAU::StatefulAlu *preorder(IR::MAU::StatefulAlu *) override;
    const IR::MAU::HashDist *preorder(IR::MAU::HashDist *) override;
    const IR::Node *preorder(IR::Node *) override;
    bool has_constant = false;
    bool write_found = false;
    ordered_set<PHV::Container> constant_containers;
    ActionFormat::ArgKey constant_renames_key;
    cstring action_name;

 public:
    explicit ConstantsToActionData(const PhvInfo &p) : phv(p) { visitDagOnce = false; }
};

/** Responsible for converting all FieldInstructions within a single Container operation into
 *  one large Container Instruction over IR::MAU::MultiOperands.  Let say the following fields
 *  f1 and f2 are in container B1, while f3 and f4 are in container B2.  The instructions:
 *
 *      -set hdr.f1, hdr.f3
 *      -set hdr.f2, hdr.f4
 *
 *  will get converted to:
 *      -set B1, B2
 *
 *  This will also merge many constants into a single container constant if the action is
 *  possible to do.
 */
class MergeInstructions : public MauTransform, TofinoWriteContext {
 private:
    const PhvInfo &phv;
    ActionAnalysis::ContainerActionsMap container_actions_map;

    const IR::MAU::Action *preorder(IR::MAU::Action *) override;
    const IR::MAU::Instruction *preorder(IR::MAU::Instruction *) override;
    const IR::Expression *preorder(IR::Expression *) override;
    const IR::Slice *preorder(IR::Slice *) override;
    void analyze_phv_field(IR::Expression *);
    const IR::MAU::ActionDataConstant *preorder(IR::MAU::ActionDataConstant *) override;
    const IR::ActionArg *preorder(IR::ActionArg *) override;
    const IR::Constant *preorder(IR::Constant *) override;
    const IR::Primitive *preorder(IR::Primitive *) override;

    const IR::MAU::AttachedOutput *preorder(IR::MAU::AttachedOutput *ao) override;
    const IR::MAU::StatefulAlu *preorder(IR::MAU::StatefulAlu *salu) override;
    const IR::MAU::HashDist *preorder(IR::MAU::HashDist *hd) override;


    const IR::Node *preorder(IR::Node *) override;
    const IR::MAU::Instruction *postorder(IR::MAU::Instruction *) override;
    const IR::MAU::Action *postorder(IR::MAU::Action *) override;

    ordered_set<PHV::Container> merged_fields;

    bool write_found = false;
    ordered_set<PHV::Container>::iterator merged_location;

    IR::MAU::Instruction *dest_slice_to_container(PHV::Container container,
        ActionAnalysis::ContainerAction &cont_action);
    IR::MAU::Instruction *build_merge_instruction(PHV::Container container,
        ActionAnalysis::ContainerAction &cont_action);
    void fill_out_write_multi_operand(ActionAnalysis::ContainerAction &cont_action,
        IR::MAU::MultiOperand *mo);
    void fill_out_read_multi_operand(ActionAnalysis::ContainerAction &cont_action,
        ActionAnalysis::ActionParam::type_t type, cstring match_name,
        IR::MAU::MultiOperand *mo);
    const IR::Constant *find_field_action_constant(ActionAnalysis::ContainerAction &cont_action);

 public:
    explicit MergeInstructions(const PhvInfo &p) : phv(p) { visitDagOnce = false; }
};

class AdjustStatefulInstructions : public MauTransform {
 private:
    const PhvInfo &phv;
    const IR::MAU::AttachedOutput *preorder(IR::MAU::AttachedOutput *) override;
    const IR::MAU::Instruction *preorder(IR::MAU::Instruction *) override;
    const IR::Expression *preorder(IR::Expression *expr) override;
    const IR::Node *preorder(IR::Node *) override;
    bool check_bit_positions(std::map<int, le_bitrange> &salu_inputs, int field_size,
        int starting_bit);

 public:
    explicit AdjustStatefulInstructions(const PhvInfo &p) : phv(p) { visitDagOnce = false; }
};

class InstructionAdjustment : public PassManager {
 public:
    explicit InstructionAdjustment(const PhvInfo &p);
};

#endif /* BF_P4C_MAU_INSTRUCTION_ADJUSTMENT_H_ */
