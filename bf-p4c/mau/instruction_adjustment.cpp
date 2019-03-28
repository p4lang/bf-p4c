#include <boost/optional.hpp>
#include "bf-p4c/mau/instruction_adjustment.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/asm_output.h"

/** SplitInstructions */

const IR::Node *SplitInstructions::preorder(IR::MAU::Instruction *inst) {
    le_bitrange bits;
    auto* field = phv.field(inst->operands.at(0), &bits);
    if (!field) return inst;  // error?

    std::vector<le_bitrange> slices;
    field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice& alloc) {
        slices.push_back(alloc.field_bits());
    });
    if (slices.size() == 1) return inst;  // nothing to split

    auto split = new IR::Vector<IR::Primitive>();
    cstring opcode = inst->name;
    bool check_pairing = false;
    for (auto slice : slices) {
        auto *n = inst->clone();
        n->name = opcode;
        for (auto &operand : n->operands)
            operand = MakeSlice(operand, slice.lo - bits.lo, slice.hi - bits.lo);
        split->push_back(n);
        // FIXME -- addc/subc only work if there are exactly 2 slices and they're in
        // an even-odd pair of PHVs.  Check for failure to meet that constraint and
        // give an error?
        if (opcode == "add" || opcode == "sub") {
            opcode += "c";
            check_pairing = true; } }
    if (check_pairing) {
        BUG_CHECK(slices.size() == 2, "PHV pairing failure for wide %s", inst->name);
        auto &s1 = field->for_bit(slices[0].lo);
        auto &s2 = field->for_bit(slices[1].lo);
        BUG_CHECK(s1.container.index() + 1 == s2.container.index() &&
                  (s1.container.index() & 1) == 0,
                  "PHV alloc failed to put wide %s into even/odd PHV pair", inst->name); }
    return split;
}

/** ConvertConstantsToActionData */

/** The purpose of this pass is to either convert all constants that are necessarily supposed
 *  to be action data, to action data, or if the action formats were decided before PHV
 *  allocation was known, throw a Backtrack exception back to TableLayout in order to determine
 *  the best allocation.
 *
 *  If a container is determined to need conversion, then all of the constants are converted into
 *  action data for that container.  The reasons constants are converted are detailed in the
 *  action_analysis pass, but summarized are restricted from a load_const, and a src2 limitation
 *  on all instructions.
 */
const IR::MAU::Action *ConstantsToActionData::preorder(IR::MAU::Action *act) {
    container_actions_map.clear();
    constant_containers.clear();
    auto tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, true, true, tbl);
    aa.set_verbose();
    aa.set_container_actions_map(&container_actions_map);
    act->apply(aa);

    bool proceed = false;
    for (auto &container_action_entry : container_actions_map) {
        auto container = container_action_entry.first;
        auto &cont_action = container_action_entry.second;
        if (cont_action.convert_constant_to_actiondata()) {
            proceed = true;
            constant_containers.insert(container);
        }
    }
    if (!proceed) {
        prune();
        return act;
    }

    action_name = act->name;
    return act;
}


const IR::Node *ConstantsToActionData::preorder(IR::Node *node) {
    visitOnce();
    return node;
}

const IR::MAU::Instruction *ConstantsToActionData::preorder(IR::MAU::Instruction *instr) {
    write_found = false;
    has_constant = false;
    constant_rename_key.action_name = findContext<IR::MAU::Action>()->name;
    return instr;
}

const IR::MAU::ActionArg *ConstantsToActionData::preorder(IR::MAU::ActionArg *arg) {
    return arg;
}

const IR::Primitive *ConstantsToActionData::preorder(IR::Primitive *prim) {
    prune();
    return prim;
}

const IR::Constant *ConstantsToActionData::preorder(IR::Constant *constant) {
    has_constant = true;
    unsigned constant_value;
    if (constant->value.fits_uint_p())
        constant_value = constant->value.get_ui();
    else
        constant_value = static_cast<unsigned>(constant->asInt());
    ActionData::Parameter *param = new ActionData::Constant(constant_value,
                                                            constant->type->width_bits());
    constant_rename_key.param = param;
    return constant;
}

void ConstantsToActionData::analyze_phv_field(IR::Expression *expr) {
        le_bitrange bits;
    auto *field = phv.field(expr, &bits);

    if (field == nullptr)
        return;

    if (isWrite()) {
        if (write_found)
            BUG("Multiple writes found within a single field instruction");

        int write_count = 0;
        le_bitrange container_bits;
        PHV::Container container;
        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
            write_count++;
            container_bits = alloc.container_bits();
            container = alloc.container;
        });

        if (write_count != 1)
            BUG("Splitting of writes did not work in ConstantsToActionData");

        constant_rename_key.container = container;
        constant_rename_key.phv_bits = container_bits;
        write_found = true;
    }
}

const IR::Slice *ConstantsToActionData::preorder(IR::Slice *sl) {
    if (phv.field(sl))
        analyze_phv_field(sl);

    prune();
    return sl;
}

const IR::Expression *ConstantsToActionData::preorder(IR::Expression *expr) {
    if (!findContext<IR::MAU::Instruction>()) {
        prune();
        return expr;
    }

    if (phv.field(expr)) {
        prune();
        analyze_phv_field(expr);
    }
    return expr;
}

const IR::MAU::AttachedOutput *ConstantsToActionData::preorder(IR::MAU::AttachedOutput *ao) {
    prune();
    return ao;
}

const IR::MAU::StatefulAlu *ConstantsToActionData::preorder(IR::MAU::StatefulAlu *salu) {
    prune();
    return salu;
}

const IR::MAU::HashDist *ConstantsToActionData::preorder(IR::MAU::HashDist *hd) {
    prune();
    return hd;
}

/** Replace any constant in these particular instructions with the an IR::MAU::ActionDataConstant
 */
const IR::MAU::Instruction *ConstantsToActionData::postorder(IR::MAU::Instruction *instr) {
    if (!write_found)
        BUG("No write found in an instruction in ConstantsToActionData?");

    if (constant_containers.find(constant_rename_key.container) == constant_containers.end())
        return instr;
    if (!has_constant)
        return instr;

    auto tbl = findContext<IR::MAU::Table>();
    auto &action_format = tbl->resources->action_format;

    auto *alu_parameter = action_format.find_param_alloc(constant_rename_key, nullptr);
    bool constant_found = alu_parameter != nullptr;

    if (constant_found != has_constant)
        BUG("Constant lookup does not match the ActionFormat");

    if (!constant_found)
        return instr;

    auto alias = alu_parameter->param->to<ActionData::Constant>()->alias();

    for (size_t i = 0; i < instr->operands.size(); i++) {
        const IR::Constant *c = instr->operands[i]->to<IR::Constant>();
        if (c == nullptr)
            continue;
        int size = c->type->width_bits();
        auto *adc = new IR::MAU::ActionDataConstant(IR::Type::Bits::get(size), alias, c);
        instr->operands[i] = adc;
    }
    return instr;
}

const IR::MAU::Action *ConstantsToActionData::postorder(IR::MAU::Action *act) {
    return act;
}


/** Merge Instructions */

/** Run an analysis on the instructions to determine which instructions should be merged.  The
 *  merged instructions must be initially removed, and then added back as a single instruction
 *  over a container
 */
const IR::MAU::Action *MergeInstructions::preorder(IR::MAU::Action *act) {
    container_actions_map.clear();
    merged_fields.clear();
    auto tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, true, true, tbl);
    // aa.set_verbose();
    aa.set_container_actions_map(&container_actions_map);
    act->apply(aa);
    if (aa.misaligned_actiondata())
        throw ActionFormat::failure(act->name);

    unsigned allowed_errors = ActionAnalysis::ContainerAction::PARTIAL_OVERWRITE
                            | ActionAnalysis::ContainerAction::REFORMAT_CONSTANT
                            | ActionAnalysis::ContainerAction::UNRESOLVED_REPEATED_ACTION_DATA;
    unsigned error_mask = ~allowed_errors;

    for (auto &container_action : container_actions_map) {
        auto container = container_action.first;
        auto &cont_action = container_action.second;
        if ((cont_action.error_code & error_mask) != 0) continue;
        if (cont_action.field_actions.size() == 1) {
            if (!cont_action.convert_instr_to_deposit_field
                && !cont_action.convert_instr_to_bitmasked_set
                && (cont_action.error_code & ~error_mask) == 0)
                continue;
        // Currently skip unresolved ActionAnalysis issues
        }
        merged_fields.insert(container);
    }

    if (merged_fields.empty())
        prune();

    return act;
}

const IR::Node *MergeInstructions::preorder(IR::Node *node) {
    visitOnce();
    return node;
}

const IR::MAU::Instruction *MergeInstructions::preorder(IR::MAU::Instruction *instr) {
    merged_location = merged_fields.end();
    write_found = false;
    return instr;
}

void MergeInstructions::analyze_phv_field(IR::Expression *expr) {
    le_bitrange bits;
    auto *field = phv.field(expr, &bits);
    if (field != nullptr && isWrite()) {
        if (merged_location != merged_fields.end())
            BUG("More than one write within an instruction");

        int split_count = 0;
        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &) {
            split_count++;
        });
        if (split_count != 1)
            BUG("Instruction on field %s not a single container instruction", field->name);
        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
            auto container = alloc.container;
            merged_location = merged_fields.find(container);
            write_found = true;
        });
    }
}

const IR::Slice *MergeInstructions::preorder(IR::Slice *sl) {
    if (phv.field(sl))
        analyze_phv_field(sl);
    prune();
    return sl;
}

/** Mark instructions that have a write corresponding to the expression being removed
 */
const IR::Expression *MergeInstructions::preorder(IR::Expression *expr) {
    if (!findContext<IR::MAU::Instruction>()) {
        prune();
        return expr;
    }

    if (phv.field(expr))
        analyze_phv_field(expr);
    prune();
    return expr;
}

const IR::MAU::ActionArg *MergeInstructions::preorder(IR::MAU::ActionArg *aa) {
    prune();
    return aa;
}

const IR::MAU::ActionDataConstant *MergeInstructions::preorder(IR::MAU::ActionDataConstant *adc) {
    prune();
    return adc;
}

const IR::Constant *MergeInstructions::preorder(IR::Constant *cst) {
    prune();
    return cst;
}

const IR::Primitive *MergeInstructions::preorder(IR::Primitive *prim) {
    prune();
    return prim;
}

const IR::MAU::AttachedOutput *MergeInstructions::preorder(IR::MAU::AttachedOutput *ao) {
    prune();
    return ao;
}

const IR::MAU::StatefulAlu *MergeInstructions::preorder(IR::MAU::StatefulAlu *salu) {
    prune();
    return salu;
}

const IR::MAU::HashDist *MergeInstructions::preorder(IR::MAU::HashDist *hd) {
    prune();
    return hd;
}

/** If marked for a merge, remove the original instruction to be added back later
 */
const IR::MAU::Instruction *MergeInstructions::postorder(IR::MAU::Instruction *instr) {
    if (!write_found)
        BUG("No write found within the instruction");

    if (merged_location == merged_fields.end()) {
        return instr;
    } else {
        return nullptr;
    }
}

/** Merge the Expressions as a MultiOperand, and then set the operands of these instructions
 *  as a multi-operand
 */
const IR::MAU::Action *MergeInstructions::postorder(IR::MAU::Action *act) {
    if (merged_fields.empty())
        return act;

    for (auto &container_action_info : container_actions_map) {
        auto container = container_action_info.first;
        auto &cont_action = container_action_info.second;
        if (merged_fields.find(container) == merged_fields.end()) continue;
        act->action.push_back(build_merge_instruction(container, cont_action));
    }
    return act;
}

/** Given that a constant will only appear once, this will find the IR::Constant node within
 *  the field actions.  Thus the size of the IR node is still maintained.
 */
const IR::Constant *MergeInstructions::find_field_action_constant(
         ActionAnalysis::ContainerAction &cont_action) {
    for (auto &fa : cont_action.field_actions) {
        for (auto read : fa.reads) {
            if (read.type == ActionAnalysis::ActionParam::CONSTANT) {
                BUG_CHECK(read.expr->is<IR::Constant>(), "Value incorrectly saved as a constant");
                return read.expr->to<IR::Constant>();
            }
        }
    }
    BUG("Should never reach this point in find_field_action_constant");
    return nullptr;
}

/** In order to keep the IR holding the fields that are contained within the container, this
 *  holds every single IR field within these individual container.  It walks over the reads of
 *  field actions within the container action, and adds them to the list.  Currently we don't
 *  use these fields in any way after this.  However, we may at some point.
 */
void MergeInstructions::fill_out_read_multi_operand(ActionAnalysis::ContainerAction &cont_action,
        ActionAnalysis::ActionParam::type_t type, cstring match_name,
        IR::MAU::MultiOperand *mo) {
    for (auto &fa : cont_action.field_actions) {
         for (auto read : fa.reads) {
             if (read.type != type) continue;
             if (type == ActionAnalysis::ActionParam::ACTIONDATA) {
                 mo->push_back(read.expr);
             } else if (type == ActionAnalysis::ActionParam::PHV) {
                le_bitrange bits;
                auto *field = phv.field(read.expr, &bits);
                int split_count = 0;
                field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
                    split_count++;
                    if (alloc.container.toString() != match_name)
                       return;
                    const IR::Expression* read_mo_expr = read.expr;
                    if (alloc.width != read.size()) {
                        int start = alloc.field_bit - bits.lo;
                        read_mo_expr = MakeSlice(read.expr, start, start + alloc.width - 1);
                    }
                    mo->push_back(read_mo_expr);
                });
             }
         }
    }
}

/** Fills out the IR::MAU::MultiOperand will all of the underlying fields that are part of a
 *  write.
 */
void MergeInstructions::fill_out_write_multi_operand(ActionAnalysis::ContainerAction &cont_action,
        IR::MAU::MultiOperand *mo) {
    for (auto &fa : cont_action.field_actions) {
        mo->push_back(fa.write.expr);
    }
}


/** The purpose of this is to convert any full container instruction destination to the container
 *  in order for the container to be the correct size.  The assembler will only parse full
 *  container instruction if the destination is the correct size.  This is based on the
 *  verify_overwritten check in ActionAnalysis in order to determine that a partial overwrite of
 *  the container is actually valid, due to the rest of the container being unoccupied.
 */
IR::MAU::Instruction *MergeInstructions::dest_slice_to_container(PHV::Container container,
        ActionAnalysis::ContainerAction &cont_action) {
    BUG_CHECK(cont_action.field_actions.size() == 1, "Can only call this function on an operation "
                                                     "that has one field action");
    IR::MAU::Instruction *rv = new IR::MAU::Instruction(cont_action.name);
    IR::Vector<IR::Expression> components;
    auto *dst_mo = new IR::MAU::MultiOperand(components, container.toString(), true);
    fill_out_write_multi_operand(cont_action, dst_mo);
    rv->operands.push_back(dst_mo);
    for (auto &read : cont_action.field_actions[0].reads) {
        rv->operands.push_back(read.expr);
    }
    return rv;
}

/** The purpose of this function is to morph together instructions over an individual container.
 *  If multiple field actions are contained within an individual container action, then they
 *  have to be merged into an individual ALU instruction.
 *
 *  This will have to happen to instructions like the following:
 *    - set hdr.f1, param1
 *    - set hdr.f2, param2
 *
 *  where hdr.f1 and hdr.f2 are contained within the same container.  This would be translated
 *  to something along the lines of:
 *    - set $(container), $(action_data_name)
 *
 *  where $(container) is the container in which f1 and f2 are in, and $(action_data_name)
 *  is the assembly name of this combined action data parameter.  This also works between
 *  instructions with PHVs, and can even slice PHVs
 *
 *  This will also directly convert into bitmasked-sets and deposit-field.  Bitmasked-set is
 *  necessary, when the fields in the container are not contingous.  Deposit-field is necessary
 *  when there are two sources.  In any other set case, the actual instruction encoding can be
 *  directly translated from a set instruction.
 *
 *  The instruction formats are setup as a destination and two sources.  ActionAnalysis can
 *  now determine which parameters go to which source.
 */
IR::MAU::Instruction *MergeInstructions::build_merge_instruction(PHV::Container container,
         ActionAnalysis::ContainerAction &cont_action) {
    if (cont_action.is_shift()) {
        unsigned error_mask = ActionAnalysis::ContainerAction::PARTIAL_OVERWRITE;
        BUG_CHECK((cont_action.error_code & error_mask) != 0,
            "Invalid call to build a merged instruction");
        return dest_slice_to_container(container, cont_action);
    }


    const IR::Expression *dst = nullptr;
    const IR::Expression *src1 = nullptr;
    const IR::Expression *src2 = nullptr;
    bitvec src1_writebits;
    bitvec src2_writebits;
    IR::Vector<IR::Expression> components;

    BUG_CHECK(cont_action.counts[ActionAnalysis::ActionParam::ACTIONDATA] <= 1, "At most "
              "one section of action data is allowed in a merge instruction");

    BUG_CHECK(!(cont_action.counts[ActionAnalysis::ActionParam::ACTIONDATA] == 1 &&
                cont_action.counts[ActionAnalysis::ActionParam::CONSTANT] >= 1), "Before "
              "merge instructions, some constant was not converted to action data");

    if (cont_action.counts[ActionAnalysis::ActionParam::ACTIONDATA] == 1) {
        if (cont_action.ad_renamed()) {
            auto &adi = cont_action.adi;
            auto mo = new IR::MAU::MultiOperand(components, adi.action_data_name, false);
            fill_out_read_multi_operand(cont_action, ActionAnalysis::ActionParam::ACTIONDATA,
                                        adi.action_data_name, mo);
            src1 = mo;
            src1_writebits = adi.alignment.write_bits();
            bitvec src1_read_bits = adi.alignment.read_bits();
            /*
            if (src1_read_bits.popcount() != static_cast<int>(container.size())) {
                src1 = MakeSlice(src1, src1_read_bits.min().index(), src1_read_bits.max().index());
            }
            */
        } else {
            bool single_action_data = true;
            auto &adi = cont_action.adi;
            for (auto &field_action : cont_action.field_actions) {
                for (auto &read : field_action.reads) {
                    if (read.type != ActionAnalysis::ActionParam::ACTIONDATA)
                        continue;
                    if (read.is_conditional)
                        continue;
                    BUG_CHECK(single_action_data, "Action data that shouldn't require an alias "
                              "does require an alias");
                    src1 = read.expr;
                    src1_writebits = adi.alignment.write_bits();
                    single_action_data = false;
                }
            }
        }
    } else if (cont_action.counts[ActionAnalysis::ActionParam::CONSTANT] > 0) {
        // Constant merged into a single constant over the entire container
        int constant_value = cont_action.ci.valid_instruction_constant(container.size());
        int width_bits;
        if ((cont_action.error_code & ActionAnalysis::ContainerAction::REFORMAT_CONSTANT) == 0)
            width_bits = cont_action.ci.alignment.bitrange_size();
        else
            width_bits = container.size();
        src1 = new IR::Constant(IR::Type::Bits::get(width_bits), constant_value);
        src1_writebits = cont_action.ci.alignment.write_bits();
    }


    // Go through all PHV sources and create src1/src2 if a source is contained within these
    // PHV fields
    for (auto &phv_ta : cont_action.phv_alignment) {
        auto read_container = phv_ta.first;
        auto read_alignment = phv_ta.second;
        if (read_alignment.is_src1) {
            auto mo = new IR::MAU::MultiOperand(components, read_container.toString(), true);
            fill_out_read_multi_operand(cont_action, ActionAnalysis::ActionParam::PHV,
                                        read_container.toString(), mo);
            src1 = mo;
            src1_writebits = read_alignment.write_bits();
            bitvec src1_read_bits = read_alignment.read_bits();
            int wrapped_lo = 0;  int wrapped_hi = 0;
            if (read_alignment.is_wrapped_shift(container, &wrapped_lo, &wrapped_hi)) {
                src1 = MakeWrappedSlice(src1, wrapped_lo, wrapped_hi, container.size());
            } else if (src1_read_bits.popcount() != static_cast<int>(read_container.size())) {
                if (src1_read_bits.is_contiguous()) {
                    src1 = MakeSlice(src1, src1_read_bits.min().index(),
                                     src1_read_bits.max().index());
                }
            }
        } else {
            auto mo = new IR::MAU::MultiOperand(components, read_container.toString(), true);
            fill_out_read_multi_operand(cont_action, ActionAnalysis::ActionParam::PHV,
                                        read_container.toString(), mo);
            src2 = mo;
            src2_writebits = read_alignment.write_bits();
        }
    }

    // Src1 is not sources from parameters, but instead is equal to the destination: BRIG-914
    if (cont_action.implicit_src1) {
        BUG_CHECK(src1 == nullptr, "Src1 found in an implicit_src1 calculation");
        src1 = new IR::MAU::MultiOperand(components, container.toString(), true);
        bitvec reverse = bitvec(0, container.size()) - src2_writebits;
        src1 = MakeSlice(src1, reverse.min().index(), reverse.max().index());
        src1_writebits = reverse;
    }

    // Src2 is not sources from parameters, but instead is equal to the destination: BRIG-883
    if (cont_action.implicit_src2) {
        BUG_CHECK(src2 == nullptr, "Src2 found in an implicit_src2 calculation");
        src2 = new IR::MAU::MultiOperand(components, container.toString(), true);
    }

    auto *dst_mo = new IR::MAU::MultiOperand(components, container.toString(), true);
    fill_out_write_multi_operand(cont_action, dst_mo);
    dst = dst_mo;
    if (!cont_action.partial_overwrite() && src1_writebits.popcount()
                                          != static_cast<int>(container.size())) {
        dst = MakeSlice(dst, src1_writebits.min().index(), src1_writebits.max().index());
    }

    cstring instr_name = cont_action.name;
    if (cont_action.convert_instr_to_bitmasked_set)
        instr_name = "bitmasked-set";
    else if (cont_action.convert_instr_to_deposit_field)
        instr_name = "deposit-field";

    IR::MAU::Instruction *merged_instr = new IR::MAU::Instruction(instr_name);
    merged_instr->operands.push_back(dst);
    if (!cont_action.no_sources()) {
        BUG_CHECK(src1 != nullptr, "No src1 in a merged instruction");
        merged_instr->operands.push_back(src1);
    }
    if (src2)
        merged_instr->operands.push_back(src2);
    // Currently bitmasked-set requires at least 2 source operands, or it crashes
    if (cont_action.convert_instr_to_bitmasked_set && !src2)
        merged_instr->operands.push_back(dst);
    return merged_instr;
}

/** The purpose of this pass it to convert any field within an SaluAction to either a slice of
 *  phv_lo or phv_hi.  This is because a field could potentially be split in the PHV, and
 *  be a single SALU instruction.
 *
 *  This also verifies that the allocation on the input xbar is correct, by checking the location
 *  of these individual bytes and coordinating their location to guarantee correctness.
 *
 *  This assumes that the stateful alu is accessing its data through the search bus rather
 *  than the hash bus, as the input xbar algorithm can only put it on the search bus.  When
 *  we add hash matrix support for stateful ALUs, we will add that as well.
 */
const IR::Annotations *AdjustStatefulInstructions::preorder(IR::Annotations *annot) {
    prune();
    return annot;
}

const IR::MAU::IXBarExpression *AdjustStatefulInstructions::preorder(IR::MAU::IXBarExpression *e) {
    prune();
    return e;
}

/** Guarantees that all bits of a particular field are aligned correctly given a size of a
 *  field and beginning position on the input xbar
 */
bool AdjustStatefulInstructions::check_bit_positions(std::map<int, le_bitrange> &salu_inputs,
        int field_size, int starting_bit) {
    bitvec all_bits;
    for (auto entry : salu_inputs) {
        int ixbar_bit_start = entry.first - starting_bit;
        if (ixbar_bit_start != entry.second.lo)
            return false;
        all_bits.setrange(entry.second.lo, entry.second.size());
    }

    if (all_bits.popcount() != field_size || !all_bits.is_contiguous())
        return false;
    return true;
}

bool AdjustStatefulInstructions::verify_on_search_bus(const IR::MAU::StatefulAlu *salu,
        const IXBar::Use &salu_ixbar, const PHV::Field *field, le_bitrange bits, bool &is_hi) {
    std::map<int, le_bitrange> salu_inputs;
    bitvec salu_bytes;
    int group = 0;
    bool group_set = false;
    // Gather up all of the locations of the associated bytes within the input xbar
    for (auto &byte : salu_ixbar.use) {
        bool byte_used = true;
        for (auto fi : byte.field_bytes) {
            if (fi.field != field->name || fi.lo < bits.lo || fi.hi > bits.hi) {
                byte_used = false;
            }
        }
        if (!byte_used)
            continue;

        if (!group_set) {
            group = byte.loc.group;
        } else if (group == byte.loc.group) {
            ::error("Input %s for a stateful alu %s allocated across multiple groups, and "
                     "cannot be resolved", field->name, salu->name);
             return false;
        }
        salu_bytes.setbit(byte.loc.byte);
        for (auto fi : byte.field_bytes) {
            le_bitrange field_bits = { fi.lo, fi.hi };
            salu_inputs[byte.loc.byte * 8 + fi.cont_lo] = field_bits;
        }
    }

    int phv_width = salu->source_width();
    if (salu_bytes.popcount() > (phv_width / 8)) {
        ::error("The input %s to stateful alu %s is allocated to more input xbar bytes than the "
                "width than the ALU and cannot be resolved.", field->name, salu->name);
        return false;
    }

    if (!salu_bytes.is_contiguous()) {
        ::error("The input %s to stateful alu %s is not allocated contiguously by byte on the "
                "input xbar and cannot be resolved.", field->name, salu->name);
       return false;
    }


    std::set<int> valid_start_positions;

    int initial_offset = 0;
    if (Device::currentDevice() == Device::TOFINO)
        initial_offset = IXBar::TOFINO_METER_ALU_BYTE_OFFSET;


    valid_start_positions.insert(initial_offset);
    valid_start_positions.insert(initial_offset + (phv_width / 8));

    if (valid_start_positions.count(salu_bytes.min().index()) == 0) {
        ::error("The input %s to stateful alu %s is not allocated in a valid region on the input "
                "xbar to be a source of an ALU operation", field->name, salu->name);
        return false;
    }

    if (!check_bit_positions(salu_inputs, bits.size(), salu_bytes.min().index() * 8)) {
        ::error("The input %s to stateful alu %s is not allocated contiguously by bit on the "
                "input xbar and cannot be resolved.", field->name, salu->name);
        return false;
    }

    is_hi = salu_bytes.min().index() != initial_offset;
    return true;
}

bool AdjustStatefulInstructions::verify_on_hash_bus(const IR::MAU::StatefulAlu *salu,
        const IXBar::Use::MeterAluHash &mah, const IR::Expression *expr,
        bool &is_hi) {
    for (auto &exp : mah.computed_expressions) {
        if (exp.second->equiv(*expr)) {
            is_hi = exp.first != 0;
            return true; } }

    BUG("The input %s to the stateful alu %s cannot be found on the hash input",
        expr, salu->name);
    return false;
}

/** The entire point of this pass is to convert any field name in a Stateful ALU instruction
 *  to either phv_lo or phv_hi, depending on the input xbar allocation.  If the field
 *  comes through the hash bus, then the stateful ALU cannot resolve the name without
 *  phv_lo or phv_hi anyway.
 */
const IR::Expression *AdjustStatefulInstructions::preorder(IR::Expression *expr) {
    visitAgain();
    if (!findContext<IR::MAU::SaluAction>()) {
        return expr;
    }

    le_bitrange bits;
    auto field = phv.field(expr, &bits);
    if (field == nullptr) {
        return expr;
    }

    auto tbl = findContext<IR::MAU::Table>();
    auto salu = findContext<IR::MAU::StatefulAlu>();
    auto &salu_ixbar = tbl->resources->salu_ixbar;
    bool is_hi = false;
    if (!salu_ixbar.meter_alu_hash.allocated) {
        if (!verify_on_search_bus(salu, salu_ixbar, field, bits, is_hi)) {
            prune();
            return expr;
        }
    } else {
        if (!verify_on_hash_bus(salu, salu_ixbar.meter_alu_hash, expr, is_hi)) {
            prune();
            return expr;
        }
    }

    cstring name = "phv";
    if (is_hi)
        name += "_hi";
    else
        name += "_lo";

    IR::MAU::SaluReg *salu_reg
        = new IR::MAU::SaluReg(expr->srcInfo, IR::Type::Bits::get(salu->source_width()), name,
                               is_hi);
    int phv_width = ((bits.size() + 7) / 8) * 8;
    salu_reg->phv_src = expr;
    const IR::Expression *rv = salu_reg;
    // Sets the byte_mask for the input for the stateful alu
    if (phv_width < salu->source_width()) {
        rv = MakeSlice(rv, 0, phv_width - 1);
    }
    prune();
    return rv;
}

Util::JsonObject *GeneratePrimitiveInfo::add_op_json(Util::JsonObject *prim,
        const std::string op, const std::string type, cstring name) {
    auto op_json = new Util::JsonObject();
    op_json->emplace("type", type);
    op_json->emplace("name", name);
    prim->emplace(op, op_json);
    return op_json;
}

Util::JsonObject *GeneratePrimitiveInfo::add_stful_op_json(Util::JsonObject *prim,
        const std::string op, const std::string op_pfx, const std::string type, cstring name) {
    auto op_json = new Util::JsonObject();
    op_json->emplace(op_pfx + "_type", type);
    op_json->emplace(op_pfx + "_value", name);
    prim->emplace(op, op_json);
    return op_json;
}

void GeneratePrimitiveInfo::add_hash_dist_json(Util::JsonObject *_primitive,
        const std::string prim_name, const std::string dst_type, const cstring dst_name,
        const IR::Expression *dst, const IR::MAU::HashDist *hd) {
    _primitive->emplace("name", prim_name);
    if (dst)
        validate_add_op_json(_primitive, "dst", dst);
    else
        add_op_json(_primitive, "dst", dst_type, dst_name);
    // FIXME: hash_name must be the meter field list name, which is
    // currently not available here.
    auto hash_name = "hash_" + dst_name;
    auto idx = add_op_json(_primitive, "idx", "hash", hash_name);
    idx->emplace("algorithm", hd->algorithm.name());
    if (auto fl = hd->field_list) {
        Util::JsonArray *hash_inputs = new Util::JsonArray();
        if (auto le = fl->to<IR::ListExpression>()) {
            for (auto &c : le->components) {
                hash_inputs->append(canon_name(c->toString()));
            }
        } else {
            hash_inputs->append(canon_name(fl->toString()));
        }
        _primitive->emplace("hash_inputs", hash_inputs);
    }
}

void GeneratePrimitiveInfo::gen_action_json(const IR::MAU::Action *act,
        Util::JsonObject *_action) {
    LOG3("GeneratePrimitiveInfo Act: " << canon_name(act->name));
    auto _primitives = new Util::JsonArray();
    for (auto call : act->stateful_calls) {
        // FIXME: Add info for hash_inputs, related to context.json schema 1.5.8
        bool is_hash_dist = false;
        const IR::MAU::HashDist *hd = nullptr;
        if (auto ci = call->index) {
            if ((hd = ci->to<IR::MAU::HashDist>()) != nullptr) {
                is_hash_dist = true;
            }
        }
        auto _primitive = new Util::JsonObject();
        auto *at = call->attached_callee;
        auto *salu = at->to<IR::MAU::StatefulAlu>();
        if (salu) {
            if (auto ci = call->index) {
                if (auto hd = ci->to<IR::MAU::HashDist>()) {
                    add_hash_dist_json(_primitive, "ExecuteStatefulAluFromHashPrimitive",
                        "stateful", canon_name(at->name), nullptr, hd);
                } else {
                    _primitive->emplace("name", "ExecuteStatefulAluPrimitive");
                    add_op_json(_primitive, "dst", "stateful", canon_name(salu->name));
                    if (auto *k = ci->to<IR::Constant>()) {
                        add_op_json(_primitive, "idx", "immediate", k->toString());
                    } else if (auto *a = ci->to<IR::MAU::ActionArg>()) {
                        add_op_json(_primitive, "idx", "action_param", a->name.toString());
                    }
                }
            } else {
                _primitive->emplace("name", "ExecuteStatefulAluPrimitive");
                add_op_json(_primitive, "dst", "stateful", canon_name(salu->name));
            }
            auto *salu_details = new Util::JsonObject();
            auto single_bit_mode = salu->source_width() == 1 ? true : false;
            salu_details->emplace("single_bit_mode", single_bit_mode);
            if (salu->instruction.size() > 0) {
                auto *sact = salu->instruction.begin()->second;
                salu_details->emplace("name", canon_name(sact->name));
                for (auto &sact_inst : sact->action) {
                    std::string inst_name = sact_inst->name.c_str();
                    auto *sact_update = new Util::JsonObject();
                    if (inst_name == "alu_a" || inst_name == "alu_b"
                            || inst_name == "add" || inst_name == "sub") {
                        if (sact_inst->operands.size() == 2) {
                            auto src = sact_inst->operands[1];
                            auto src_string = src->toString();
                            if (auto *k = src->to<IR::Constant>()) {
                                sact_update->emplace("operand_1_type", "immediate");
                                sact_update->emplace("operand_1_value", k->toString());
                            } else if (phv.field(src_string)) {
                                sact_update->emplace("operand_1_type", "phv");
                                sact_update->emplace("operand_1_value", src_string);
                            }
                        } else if (sact_inst->operands.size() == 3) {
                            auto src1 = sact_inst->operands[1];
                            auto src2 = sact_inst->operands[2];
                            std::string op = "";
                            if (inst_name == "add") op = "+";
                            if (inst_name == "sub") op = "-";
                            sact_update->emplace("operation", op);
                            if (auto *s = src1->to<IR::MAU::SaluReg>()) {
                                sact_update->emplace("operand_1_type", "memory");
                                sact_update->emplace("operand_1_value", "register_" + s->name);
                            }
                            if (auto *k = src2->to<IR::Constant>()) {
                                sact_update->emplace("operand_2_type", "immediate");
                                sact_update->emplace("operand_2_value", k->toString());
                            } else if (auto phv_field = phv.field(src2)) {
                                sact_update->emplace("operand_2_type", "phv");
                                sact_update->emplace("operand_2_value",
                                        canon_name(phv_field->externalName()));
                            }
                        }
                        if (sact_inst->operands.size() > 1) {
                            if (auto *dst = sact_inst->operands[0]->to<IR::MAU::SaluReg>()) {
                                if (dst->name == "lo") {
                                    salu_details->emplace("update_lo_1_value", sact_update);
                                } else if (dst->name == "hi") {
                                    salu_details->emplace("update_hi_1_value", sact_update);
                                }
                            }
                        }
                    } else if (inst_name == "output") {
                        if (sact_inst->operands.size() == 1) {
                            if (auto dst = sact_inst->operands[0]->to<IR::MAU::SaluReg>()) {
                                sact_update->emplace("operand_1_type", "memory");
                                auto dst_name = (dst->name == "alu_lo") ? "memory_lo" :
                                                (dst->name == "alu_hi") ? "memory_hi" :
                                                dst->name;
                                sact_update->emplace("operand_1_value", dst_name);
                                salu_details->emplace("output_value", sact_update);
                            }
                        }
                    }
                }
            }
            _primitive->emplace("stateful_alu_details", salu_details);
            _primitives->append(_primitive);
        }
        auto *meter = at->to<IR::MAU::Meter>();
        if (meter) {
            if (is_hash_dist) {
               add_hash_dist_json(_primitive, "ExecuteMeterFromHashPrimitive",
                   "meter", canon_name(meter->name), nullptr, hd);
               _primitives->append(_primitive);
            } else {
                _primitive->emplace("name", "ExecuteMeterPrimitive");
                add_op_json(_primitive, "dst", "meter", canon_name(meter->name));
                if (auto pc = meter->pre_color) {
                    if (auto hd = pc->to<IR::MAU::HashDist>()) {
                        if (auto fl = hd->field_list) {
                            if (auto sl = fl->to<IR::Slice>()) {
                                if (auto e0 = sl->e0) {
                                    add_op_json(_primitive, "idx", "action_param",
                                            canon_name(e0->toString()));
                                    _primitives->append(_primitive);
                                }
                            }
                        }
                    }
                }
            }
        }
        auto *counter = at->to<IR::MAU::Counter>();
        if (counter) {
            if (is_hash_dist) {
                add_hash_dist_json(_primitive, "CountFromHashPrimitive",
                    "counter", canon_name(counter->name), nullptr, hd);
                _primitives->append(_primitive);
            } else {
                _primitive->emplace("name", "CountPrimitive");
                add_op_json(_primitive, "dst", "counter", canon_name(counter->name));
                _primitives->append(_primitive);
            }
        }
    }

    std::vector<std::string> modifyPrimVec = { "set" };
    std::vector<std::string> modifyCondPrimVec { "conditionally-set" };
    std::vector<std::string> invalidatePrimVec = { "invalidate" };
    std::vector<std::string> shiftPrimVec = { "shru", "shl", "shrs" };
    std::vector<std::string> directAluPrimVec = {
        "add", "addc", "saddu", "sadds",
        "and", "andca", "andcb", "nand",
        "nor", "not", "or", "orca", "orcb",
        "xnor", "xor", "maxu", "minu",
        "sub", "subc", "ssubu", "ssubs" };
    std::map<std::string, std::vector<std::string>* > prims = {
        { "ModifyFieldPrimitive", &modifyPrimVec },
        { "ModifyFieldConditionallyPrimitive", &modifyCondPrimVec },
        { "InvalidatePrimitive", &invalidatePrimVec },
        { "ShiftPrimitive", &shiftPrimVec },
        { "DirectAluPrimitive", &directAluPrimVec }
    };
    for (auto inst : act->action) {
        auto _primitive = new Util::JsonObject();
        std::string inst_name = inst->name.c_str();
        bool skip_prim_check = false;
        if ((inst_name == "set")
                && (inst->operands.size() == 2)) {
            auto dst = inst->operands[0];
            cstring dst_name = inst->operands[0]->toString();
            auto src = inst->operands[1];
            if (dst_name.endsWith("$valid")) {
                if (auto val = src->to<IR::Constant>()) {
                    if (val->value == 1) {
                        _primitive->emplace("name", "AddHeaderPrimitive");
                        skip_prim_check = true;
                    } else if (val->value == 0) {
                        _primitive->emplace("name", "RemoveHeaderPrimitive");
                        skip_prim_check = true;
                    }
                    add_op_json(_primitive, "dst", "header", canon_name(dst_name));
                }
            } else if (dst_name.endsWith("drop_ctl")) {
                if (auto val = src->to<IR::Constant>()) {
                    if (val->value == 1) {
                        _primitive->emplace("name", "DropPrimitive");
                        skip_prim_check = true;
                        add_op_json(_primitive, "dst", "phv", canon_name(dst_name));
                        add_op_json(_primitive, "src1", "immediate", "1");
                    }
                }
            } else if (auto hd = src->to<IR::MAU::HashDist>()) {
                add_hash_dist_json(_primitive, "SetFieldToHashIndexPrimitive",
                        "", canon_name(dst_name), dst, hd);
                skip_prim_check = true;
            }
        }
        bool is_stful_dest = false;
        if (!skip_prim_check) {
            for (auto &p : prims) {
                auto pv = *p.second;
                if (std::any_of(pv.begin(), pv.end(),
                        [&inst_name](std::string const& elem) {
                        return inst_name == elem; })) {
                    _primitive->emplace("name", p.first);
                    _primitive->emplace("operation", inst_name);
                    if (inst->operands.size() == 2) {
                        auto src = inst->operands[1];
                        if (auto *ao = src->to<IR::MAU::AttachedOutput>()) {
                            if (ao->attached->to<IR::MAU::StatefulAlu>()) {
                                cstring dst = inst->operands[0]->toString();
                                // Add output_dst to previously added stateful
                                // primitive
                                for (auto _prim : *_primitives) {
                                    auto _prim_o = _prim->to<Util::JsonObject>();
                                    auto _prim_o_name = _prim_o->get("name");
                                    if (!_prim_o_name) continue;
                                    auto _prim_o_name_val = _prim_o_name->to<Util::JsonValue>();
                                    auto _prim_o_name_val_str = _prim_o_name_val->getString();
                                    std::string sprim_1 = "ExecuteStatefulAluPrimitive";
                                    std::string sprim_2 = "ExecuteStatefulAluFromHashPrimitive";
                                    bool stful_prim =
                                        ((_prim_o_name_val_str == sprim_1) ||
                                        (_prim_o_name_val_str == sprim_2));
                                    if (!stful_prim) continue;
                                    auto _salu_d = _prim_o->get("stateful_alu_details");
                                    if (_salu_d) {
                                        auto _salu_d_o = _salu_d->to<Util::JsonObject>();
                                        _salu_d_o->emplace("output_dst", canon_name(dst));
                                        is_stful_dest = true;
                                    }
                                }
                                break;
                            }
                        }
                    } else if (inst->operands.size() == 1) {
                        if (inst_name == "invalidate") {
                            auto dst = inst->operands[0]->to<IR::Expression>();
                            if (auto phv_field = phv.field(dst)) {
                                add_op_json(_primitive,
                                        "dst", "phv", canon_name(phv_field->externalName()));
                            }
                        }
                    }
                }
            }
            // Don't output operand json if instruction is a stateful destination,
            // this info goes within the stateful primitive evaluated above.


            if ((inst->operands.size() >= 2) && (!is_stful_dest)) {
                // Add dst operands
                auto dst = inst->operands[0]->to<IR::Expression>();
                le_bitrange bits = {0, 0};
                if (auto phv_field = phv.field(dst, &bits)) {
                    add_op_json(_primitive, "dst", "phv", canon_name(phv_field->externalName()));
                    add_op_json(_primitive, "dst_mask", "immediate",
                            std::to_string((1U << bits.size()) - 1));
                }

                if (inst->name == "conditionally-set") {
                    auto iteration = 0;
                    for (int idx = inst->operands.size() - 1; idx > 0; idx--) {
                        std::string src_name;
                        switch (iteration) {
                            case 0: src_name = "cond"; break;
                            case 1: src_name = "src1"; break;
                            case 2: src_name = "src2"; break;
                            default: BUG("Too many operands in a conditional-set");
                        }
                        auto src = inst->operands.at(idx);
                        if (iteration == 0)
                            src = src->to<IR::MAU::ConditionalArg>()->orig_arg;
                        validate_add_op_json(_primitive, src_name, src);
                        iteration++;
                    }
                } else {
                    // Add src operands
                    auto idx = 0;
                    for (auto src : inst->operands) {
                        if (idx++ == 0) continue;  // skip 1st op which is dst
                        auto src_name = "src" + std::to_string(idx - 1);
                        validate_add_op_json(_primitive, src_name, src);
                    }
                }
            }
        }
        // FIXME: This name should be set above.
        // 'name' is a required attribute for primitives.
        if (_primitive->find("name") == _primitive->end()) {
            _primitive->emplace("name", "PrimitiveNameNeeded");
        }
        if (!is_stful_dest) _primitives->append(_primitive);
    }
    _action->emplace("primitives", _primitives);
}

void GeneratePrimitiveInfo::validate_add_op_json(Util::JsonObject *_primitive,
        const std::string op_name, const IR::Expression *exp) {
    if (auto phv_field = phv.field(exp)) {
         add_op_json(_primitive, op_name, "phv", canon_name(phv_field->externalName()));
    } else  if (auto cnst = exp->to<IR::Constant>()) {
         add_op_json(_primitive, op_name, "immediate", cnst->toString());
     } else if (auto aarg = exp->to<IR::MAU::ActionArg>()) {
         add_op_json(_primitive, op_name, "action_param", canon_name(aarg->name));
     } else if (auto *sl = exp->to<IR::Slice>()) {
         if (auto e0 = sl->e0) {
            if (auto *ao = e0->to<IR::MAU::AttachedOutput>()) {
                if (auto stful = ao->attached->to<IR::MAU::StatefulAlu>()) {
                    if (op_name == "dst")
                        add_op_json(_primitive, op_name, "stateful", canon_name(stful->name));
                    else
                        add_op_json(_primitive, op_name, "phv", canon_name(stful->name));
                } else if (auto meter = ao->attached->to<IR::MAU::Meter>()) {
                   if (op_name == "src1")
                       add_op_json(_primitive, op_name, "action_param", canon_name(meter->name));
                   else
                       add_op_json(_primitive, op_name, "phv", canon_name(meter->name));
                }
            }
        }
    }
}

bool GeneratePrimitiveInfo::preorder(const IR::MAU::Table *tbl) {
    auto tname = tbl->match_table ? tbl->match_table->externalName() : tbl->name;
    LOG3("Table: " << canon_name(tname));
    bool alpm_preclassifier = tbl->name.endsWith("preclassifier");

    if (tbl->actions.empty()) return true;

    auto _table = new Util::JsonObject();
    auto _actions = new Util::JsonArray();
    for (auto act : Values(tbl->actions)) {
        if (act->miss_action_only) continue;
        auto _action = new Util::JsonObject();
        _action->emplace("name", canon_name(act->name));
        gen_action_json(act, _action);
        _actions->append(_action);
    }

    _table->emplace("name", canon_name(tname));
    if (alpm_preclassifier) {
        auto _match_attr = new Util::JsonObject();
        auto _pre_classifier = new Util::JsonObject();
        _pre_classifier->emplace("actions", _actions);
        _match_attr->emplace("pre_classifier", _pre_classifier);
        _table->emplace("match_attributes", _match_attr);
    } else {
        _table->emplace("actions", _actions);
    }

    _tables->append(_table);
    return true;
}

void GeneratePrimitiveInfo::end_apply() {
    // Write to primitive json file
    auto _pNode = new Util::JsonObject();
    _pNode->emplace("tables", _tables);
    _primNode = *_pNode;
}

/** Instruction Adjustment */
InstructionAdjustment::InstructionAdjustment(const PhvInfo &phv, Util::JsonObject &primNode) {
    addPasses({
        new GeneratePrimitiveInfo(phv, primNode),
        new SplitInstructions(phv),
        new ConstantsToActionData(phv),
        new MergeInstructions(phv),
        new AdjustStatefulInstructions(phv)
    });
}
