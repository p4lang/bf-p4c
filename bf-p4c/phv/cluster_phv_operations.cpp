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
    bool is_salu_op = (findContext<IR::MAU::SaluAction>() != nullptr);

    // SALU operands have special constraints.
    bool has_reg_operand = false;
    for (auto* operand : inst->operands)
        if (operand->is<IR::MAU::SaluReg>())
            has_reg_operand = true;

    // For each PHV field operand of this instruction, update its operations()
    // with info about this instruction.
    if (!inst->operands.empty()) {
        le_bitrange dest_bits;
        auto* dst_i = phv.field(inst->operands[0], &dest_bits);
        for (int idx = 0; idx < int(inst->operands.size()); ++idx) {
            le_bitrange field_bits;
            PHV::Field* field = phv.field(inst->operands[idx], &field_bits);
            if (!field) continue;

            // Attach info for this instruction to the field.
            auto accessType = idx == 0 ? PHV::FieldAccessType::W : PHV::FieldAccessType::R;
            auto op = PHV::FieldOperation(is_move_op,
                                          is_salu_op,
                                          inst->name,
                                          accessType,
                                          field_bits);
            field->operations().push_back(op);

            // For non-move operations, if the source field is smaller in size than the
            // destination field, we need to set the no_pack property for the source field
            // so that the missing bits (in the source compared to the destination) do not
            // contain any value that can affect the result of the operation
            if (dst_i && dst_i != field
                      && !is_move_op
                      && field_bits.size() < dest_bits.size()) {
                LOG3("Marking " << field->name << " as 'no pack' because it is a source of a "
                     "non-MOVE operation to a larger field " << dst_i->name);
                field->set_no_pack(true); }

            // XXX(cole) [Artificial Constraint]: Require SALU operands
            // to be placed in the bottom bits of their PHV containers.
            // In the future, this can be handled by allocating a hash
            // table to arbitrarily swizzle the bits to get them into
            // the right place.
            if (has_reg_operand)
                field->set_deparsed_bottom_bits(true); } }

    return true;
}

void PHV_Field_Operations::end_apply() {
    for (auto &f : phv) {
        for (auto &op : f.operations()) {
            bool is_write = op.rw_type == PHV::FieldAccessType::W
                            || op.rw_type == PHV::FieldAccessType::RW;
            if (!op.is_move_op && !op.is_salu_op) {
                // Apply no_pack constraint on carry-based operation. If
                // sliced, apply on the slice only.  If f can't be split but is
                // larger than 32 bits, report an error.
                auto sz = op.range ? (*op.range).size() : f.size;
                if (sz > 32) {
                    P4C_UNIMPLEMENTED(
                        "Operands of arithmetic operations cannot be greater than "
                        "32b, but field %1%%2% has %3%b and is involved in '%4%'",
                        cstring::to_cstring(f), op.range ? cstring::to_cstring(*op.range) : "",
                        sz, op.inst_name); }
                LOG3("Marking " << f.name << *op.range << " as 'no split' for its use in "
                     "instruction " << op.inst_name << ".");

                // TODO(cole): Unify no_split and no_split_at.
                if (sz == f.size)
                    f.set_no_split(true);
                else
                    f.set_no_split_at(*op.range);

                // For sources of writes involved in a non-MOVE operation, the bits not involved in
                // the non-move operations do not change. Therefore, it is safe to not put a
                // no_pack() constraint on those sources.
                if (is_write) {
                    LOG3("Marking " << f.name << " as 'no pack' because it is written in "
                         "non-MOVE instruction " << op.inst_name << ".");
                    f.set_no_pack(true); } } } }
}
