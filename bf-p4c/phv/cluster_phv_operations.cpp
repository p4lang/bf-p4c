#include "cluster_phv_container.h"
#include "cluster_phv_operations.h"
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
    static const ordered_set<cstring> move_based_ops = {"set"};
    bool is_move_op = move_based_ops.count(inst->name);

    dst_i = nullptr;
    // get pointer to inst
    if (!inst->operands.empty()) {
        dst_i = const_cast<PHV::Field*> (phv.field(inst->operands[0]));
        if (dst_i) {
            // insert operation in field.operations with tuple3<operation, mode>
            // most of the information in the tuple is for debugging purpose
            auto op = std::make_tuple(is_move_op, inst->name, PHV::Field_Ops::W);
            dst_i->operations().push_back(op);
        }
        // get src operands (if more than 1?)
        if (inst->operands.size() > 1) {
            // iterate 1+
            for (auto operand = ++inst->operands.begin();
                    operand != inst->operands.end();
                    ++operand) {
                PHV::Field* field = phv.field(*operand);
                if (field) {
                    // insert operation in field.operations with tuple3
                    auto op = std::make_tuple(is_move_op, inst->name, PHV::Field_Ops::R);
                    field->operations().push_back(op);
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
        if (f.phv_use_width() > 1) {
            for (auto &op : f.operations()) {
                // element 0 in tuple is 'is_move_op'
                if (std::get<0>(op) != true) {
                    f.set_mau_phv_no_pack(true);                     // set mau_phv_no_pack
                    break;
                }
            }  // for
        }
    }
    // recompute phv_use_width for no_cohabit fields
    for (auto &f : phv) {
        if (PHV_Container::constraint_no_cohabit(&f)) {
            f.set_phv_use_hi(PHV_Container::ceil_phv_use_width(&f) - 1);
            LOG3("...packing_constraint... " << f);
        }
    }
    // recompute phv_use_width for ccgf owners
    for (auto &f : phv) {
        if (f.is_ccgf()) {
            f.set_ccgf_phv_use_width();
        }
    }
    LOG3("..........End PHV_Field_Operations..........");
}  // end_apply()
