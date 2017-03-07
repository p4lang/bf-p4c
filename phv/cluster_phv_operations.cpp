#include "cluster_phv_operations.h"
#include "lib/log.h"
#include "base/logging.h"

//***********************************************************************************
//
// Mark field if used in move-based (defined below) operations.
// A field can be used (read or write) in multiple instructions.
// This pass collects all operations on a field, and append a record of the operation
// (represented as a tuple3 (op, mode, dst/src)) to the vec of operations in the field.
//
//***********************************************************************************
//
bool PHV_Field_Operations::preorder(const IR::MAU::Instruction *inst) {
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
    static const std::set<cstring> move_based_ops = {"set"};
    bool is_move_op = move_based_ops.count(inst->name);

    dst_i = nullptr;
    // get pointer to inst
    if (!inst->operands.empty()) {
        dst_i = const_cast<PhvInfo::Field*> (phv.field(inst->operands[0]));
        if (dst_i) {
            // insert operation in field.operations with tuple3<operation, mode>
            // most of the information in the tuple is for debugging purpose
            auto op = std::make_tuple(is_move_op, inst->name, PhvInfo::Field_Ops::W);
            dst_i->operations.push_back(op);
        }
        // get src operands (if more than 1?)
        if (inst->operands.size() > 1) {
            // iterate 1+
            for (auto operand = ++inst->operands.begin();
                    operand != inst->operands.end();
                    ++operand) {
                PhvInfo::Field* field = phv.field(*operand);
                if (field) {
                    // insert operation in field.operations with tuple3
                    auto op = std::make_tuple(is_move_op, inst->name, PhvInfo::Field_Ops::R);
                    field->operations.push_back(op);
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
        if (f.ccgf != &f
            && f.phv_use_width() > 1) {
            //
            for (auto &op : f.operations) {
                // element 0 in tuple is 'is_move_op'
                if (std::get<0>(op) != true) {
                    f.mau_phv_no_pack = true;
                    //
                    // recompute phv_use_width
                    // do not change width for deparser fields
                    //
                    if (!f.deparser_no_pack) {
                        ceil_phv_use_width(&f);
                    }
                    LOG3("...packing_constraint... " << f);
                    break;
                }
            }
        }
    }
    // recompute width for ccgf owners
    for (auto &f : phv) {
        f.phv_use_width(f.ccgf == &f);
    }
    LOG3("..........End PHV_Field_Operations..........");
}

void PHV_Field_Operations::ceil_phv_use_width(PhvInfo::Field* f) {
    assert(f);
    if (f->mau_phv_no_pack) {
        if (f->size <= PHV_Container::PHV_Word::b8) {
            f->phv_use_hi = PHV_Container::PHV_Word::b8 - 1;
        } else {
            if (f->size <= PHV_Container::PHV_Word::b16) {
                f->phv_use_hi = PHV_Container::PHV_Word::b16 - 1;
            } else {
                if (f->size <= PHV_Container::PHV_Word::b32) {
                    f->phv_use_hi = PHV_Container::PHV_Word::b32 - 1;
                }
            }
        }
    }
}
