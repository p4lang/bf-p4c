#include "bf-p4c/phv/cluster_phv_operations.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/ir/bitrange.h"
#include "lib/log.h"

bool PHV_Field_Operations::preorder(const IR::MAU::Instruction *inst) {
    //
    // see mau/instruction-selection.cpp for all supported instructions
    // operations considered as move-based ops:
    // - set
    // operations not considered as move-based ops
    // - add, sub, substract
    // - bit-mask set
    // - invalidate
    // operations not handled by instruction-selection pass:
    // - noop, load-const, pair-dpf
    // - shifts, byte-rotate-merge, conditional-move/mux
    // - stateful alu instructions (count, meter, extern)

    // 'set' is a special case of 'deposit-field', with no rotation of source data,
    // and all destination data will be replaced.
    // TODO hanw, more ops to moved_based_ops ?
    //
    static const ordered_set<cstring> move_based_ops = {
        "set",
        "and",
        "or",
        "not",
        "nor",
        "andca",
        "andcb",
        "nand",
        "orca",
        "orcb",
        "xnor"
    };
    bool is_move_op = move_based_ops.count(inst->name);

    // SALU operands have special constraints.
    bool has_reg_operand = false;
    for (auto* operand : inst->operands)
        if (operand->is<IR::MAU::SaluReg>())
            has_reg_operand = true;

    dst_i = nullptr;
    // get pointer to inst
    if (!inst->operands.empty()) {
        le_bitrange dest_bits;
        dst_i = phv.field(inst->operands[0], &dest_bits);
        int dst_size = 0;
        if (dst_i) {
            // insert operation in field.operations with tuple3<operation, mode>
            // most of the information in the tuple is for debugging purpose
            auto op = std::make_tuple(is_move_op, inst->name, PHV::Field_Ops::W);
            dst_i->operations().push_back(op);
            dst_size = dest_bits.size(); }

        // get src operands (if more than 1?)
        if (inst->operands.size() > 1) {
            // iterate 1+
            for (auto operand = ++inst->operands.begin();
                    operand != inst->operands.end();
                    ++operand) {
                le_bitrange field_bits;
                PHV::Field* field = phv.field(*operand, &field_bits);
                if (field) {
                    // insert operation in field.operations with tuple3
                    auto op = std::make_tuple(is_move_op, inst->name, PHV::Field_Ops::R);
                    field->operations().push_back(op);

                    // For non-move operations, if the source field is smaller in size than the
                    // destination field, we need to set the no_pack property for the source field
                    // so that the missing bits (in the source compared to the destination) do not
                    // contain any value that can affect the result of the operation
                    if (!is_move_op && dst_i && field_bits.size() < dst_size) {
                        LOG1("    ...setting no pack because " << field->name << " is a source of "
                             "a non-MOVE operation to a larger field " << dst_i->name);
                        field->set_no_pack(true); }

                    // XXX(cole) [Artificial Constraint]: Require SALU operands
                    // to be placed in the bottom bits of their PHV containers.
                    // In the future, this can be handled by allocating a hash
                    // table to arbitrarily swizzle the bits to get them into
                    // the right place.
                    if (has_reg_operand)
                        field->set_deparsed_bottom_bits(true);
                }
            }
        }
    }
    return true;
}  // PHV_Field_Operations::preorder Instruction

//***********************************************************************************
//
// end of IR walk epilogue
// determine field cohabitable in PHV container
// due to operations (non "move based") constraint
//
//***********************************************************************************

void PHV_Field_Operations::end_apply() {
    LOG3("..........Begin PHV_Field_Operations..........");
    for (auto &f : phv) {
        for (auto &op : f.operations()) {
            bool is_move_op = std::get<0>(op);
            bool is_write = std::get<2>(op) == PHV::Field_Ops::W
                            || std::get<2>(op) == PHV::Field_Ops::RW;
            if (!is_move_op) {
                // Don't split carry operations.
                f.set_no_split(true);

                // If f can't be split but is larger than 32 bits, report an error.
                if (f.size > 32)
                    P4C_UNIMPLEMENTED("Operands of arithmetic operations cannot be greater than "
                                      "32b, but field %1% has %2%b and is involved in '%3%'",
                                      cstring::to_cstring(f), f.size, std::get<1>(op));

                // For sources of writes involved in a non-MOVE operation, the bits not involved in
                // the non-move operations do not change. Therefore, it is safe to not put a
                // no_pack() constraint on those sources.
                if (is_write) {
                    LOG1("    ...setting no pack because " << f.name << " is involved in a "
                         "write by non-MOVE");
                    f.set_no_pack(true); } } } }

    LOG3("..........End PHV_Field_Operations..........");
}  // end_apply()
