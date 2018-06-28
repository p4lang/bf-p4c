#include "bf-p4c/phv/cluster_phv_operations.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/ir/bitrange.h"
#include "lib/log.h"

void PHV_Field_Operations::processSaluInst(const IR::MAU::Instruction* inst) {
    // SALU operands have the following constraints:
    //
    //  - If the SALU instruction is the same size as the container sources,
    //    eg. 8b SALU with operands in 8b containers, then the operands must be
    //    aligned
    //
    //  - If the SALU instruction is smaller than the containers holding its
    //    operands, eg. 8b SALU drawing 8b operands from 16b containers, then the
    //    operands must be allocated at bytes 0 and 1 in their respective
    //    containers (but it doesn't matter which is allocated at 0 and which at 1).
    //
    //  - SALUs have a byte mask, not a bit mask, so nothing can be packed in
    //    the same byte as an SALU operand.
    //
    //    XXX(cole): This last constarint is not implemented!

    auto* statefulAlu = findContext<IR::MAU::StatefulAlu>();
    BUG_CHECK(statefulAlu, "Found an SALU instruction not in a Stateful ALU IR node: %1%", inst);
    int sourceWidth = statefulAlu->source_width();

    bool is_bitwise_op = bitwise_ops.count(inst->name);
    if (!inst->operands.empty()) {
        for (int idx = 0; idx < int(inst->operands.size()); ++idx) {
            le_bitrange field_bits;
            PHV::Field* field = phv.field(inst->operands[idx], &field_bits);
            if (!field) continue;

            // Add details of this operation to the field object.
            field->operations().push_back({
                is_bitwise_op,
                true /* is_salu_inst */,
                inst,
                idx == 0 ? PHV::FieldAccessType::W : PHV::FieldAccessType::R,
                field_bits });

            // Require SALU operands to be placed in the bottom bits of their
            // PHV containers.  In the future, this can be handled by
            // allocating a hash table to arbitrarily swizzle the bits to get
            // them into the right place.
            //
            // Moreover, when an SALU operand is placed in a larger PHV
            // container, it must be placed such that it can be loaded into the
            // right place on the input crossbar.
            //
            // IXBAR byte indices
            //  8 <--  8b, 16b, 32b SALU operand 1 starts here
            //  9 <--  8b SALU operand 2 starts here
            // 10 <-- 16b SALU operand 2 starts here
            // 11
            // 12 <-- 32b SALU operand 2 starts here
            // ..
            //
            // PHV containers by size:
            //      [ X ]: X can be loaded to any byte of the IXBAR
            //     [ XY ]: X can be loaded to IXBAR index % 2
            //             Y can be loaded to IXBAR index % 2 + 1
            //   [ XYZA ]: X can be loaded to IXBAR index % 4
            //             Y can be loaded to IXBAR index % 4 + 1
            //             ...
            //
            // Therefore, if the size of the SALU operand (sourceWidth) is
            // placed in a larger container, it must start at a position that
            // corresponds to one of the two SALU operand slots in the IXBAR.
            //
            // XXX(cole) [ ARTIFICIAL CONSTRAINT ]: We require that the first
            // operand be allocated in a place that can be loaded into the
            // first SALU operand slot, and the second be allocated such that
            // it can be loaded into the second slot.  However, they could be
            // allocated in reverse.  We don't handle that kind of conditional
            // constraint (choice of two possibilities) yet.
            //
            // XXX(cole): In the future, this can also be treated as a soft
            // constraint: If not satisfiable, SALU operands can be sourced
            // through a hash table, as long as the sum of the sizes of the
            // operands is less than 51 bits.
            for (auto size : Device::phvSpec().containerSizes()) {
                if (sourceWidth <= int(size))
                    field->setStartBits(size, bitvec(0, 1));
                else
                    field->setStartBits(size, bitvec(idx * int(size), 1)); } } }
}

void PHV_Field_Operations::processInst(const IR::MAU::Instruction* inst) {
    if (inst->operands.empty())
        return;

    le_bitrange dest_bits;
    auto* dst = phv.field(inst->operands[0], &dest_bits);
    for (int idx = 0; idx < int(inst->operands.size()); ++idx) {
        le_bitrange field_bits;
        PHV::Field* field = phv.field(inst->operands[idx], &field_bits);
        if (!field) continue;

        // Add details of this operation to the field object.
        bool is_bitwise_op = bitwise_ops.count(inst->name) > 0;
        field->operations().push_back({
            is_bitwise_op,
            false /* is_salu_inst */,
            inst,
            idx == 0 ? PHV::FieldAccessType::W : PHV::FieldAccessType::R,
            field_bits });

        // The remaining constraints only apply to non-bitwise operations.
        if (is_bitwise_op)
            continue;

        // Apply no_pack constraint on carry-based operation. If sliced, apply
        // on the slice only.  If f can't be split but is larger than 32 bits,
        // report an error.
        if (field_bits.size() > 32)
            P4C_UNIMPLEMENTED(
                "Operands of arithmetic operations cannot be greater than 32b, but field %1%%2% "
                "has %3%b and is involved in '%4%'", cstring::to_cstring(field),
                field_bits.size() != field->size ? cstring::to_cstring(field_bits) : "",
                field_bits.size(), inst->name);
        LOG3("Marking " << field->name << field_bits << " as 'no split' for its use in "
             "instruction " << inst->name << ".");

        // TODO(cole): Unify no_split and no_split_at.
        if (field_bits.size() == field->size)
            field->set_no_split(true);
        else
            field->set_no_split_at(field_bits);

        // The destination of a non-bitwise instruction must be placed alone in
        // its PHV container, because carry or shift instructions might
        // overflow from writing to the destination and clobber adjacently
        // packed fields.
        //
        // However, the sources may be packed with other fields, because other
        // bits of the container can't influence the destination.
        // For example:
        //
        // Container 1               Container 2               Container 3
        // [ 0000 XXXX XXXX 0000 ] = [ AAAA YYYY YYYY BBBB ] + [ CCCC ZZZZ ZZZZ DDDD ]
        //
        // where the instruction in question is X = Y + Z.  The result is
        // [ ____ RRRR RRRR ____ ], where '_' is some unknown value and R is
        // the result stored in the destination in question.

        // XXX(cole): Actually, this only works if the other bits in the
        // destination container are guaranteed to be zero, which is not true
        // after this instruction executes.  Hence, two back-to-back addition
        // instructions could overflow the lower bits of the destination
        // container and modify the destination field.
        //
        // Until we add a "don't pack the lower order bits" constraint, we'll
        // have to rely on validate allocation to catch bad packings that hit
        // this corner case.  Unfortunately, it's too restrictive to not pack
        // any sources of non-bitwise instructions.

        // XXX(cole): In some circumstances, it may be possible to pack these
        // fields in the same container if enough padding is left between them.

        if (dst == field) {
            LOG3("Marking " << field->name << " as 'no pack' because it is written in "
                 "non-MOVE instruction " << inst->name << ".");
            field->set_no_pack(true); }

        // For non-move operations, if the source field is smaller in size than the
        // destination field, we need to set the no_pack property for the source field
        // so that the missing bits (in the source compared to the destination) do not
        // contain any value that can affect the result of the operation
        if (dst && dst != field && field_bits.size() < dest_bits.size()) {
            LOG3("Marking " << field->name << " as 'no pack' because it is a source of a "
                 "non-MOVE operation to a larger field " << dst->name);
            field->set_no_pack(true); }

        // For shift operations, the sources must be assigned no-pack.
        if (shift_ops.count(inst->name)) {
            LOG3("Marking "  << field->name << " as 'no pack' because it is a source of a "
                 "shift operation " << inst);
            field->set_no_pack(true); } }
}

bool PHV_Field_Operations::preorder(const IR::MAU::Instruction *inst) {
    if (findContext<IR::MAU::SaluAction>())
        processSaluInst(inst);
    else
        processInst(inst);
    return true;
}
