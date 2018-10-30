#include <bf-p4c/mau/resource.h>
#include "attached_output.h"
#include "bf-p4c/mau/table_layout.h"

/**
 * MAU Figure 6-73: LPF meter block diagram
 *
 * The 32-bit Vnew is passed to the RED logic (when enabled) to generate the 8b drop indicator.  If
 * RED is enabled, then the drop indicator is output to the action data bus.  Otherwise the 32b Vnew
 * (optionally scaled by the LPF action scale field of the meter RAM word) value is sent.
 *
 * Note:
 *
 * The output format is encoded as a bitvec of 4 bit. Each bit represents the use of 1 byte on
 * action data bus. The encoded value is computed from 'read.size()' and 'container_bit'.
 * The 'container_bit' gives the offset into 32 bit block. The 'read.size()' gives the size
 * of used bits in the 32 bit block.
 *
 * @param adp: output format on action data bus for single alu.
 */
void CollectMeterOutput::create_action_data_from_meter_alu(
        ActionFormat::ActionDataForSingleALU &adp,
        const ActionAnalysis::ActionParam &read,
        int container_bit) {
    // meter alu output may be saved to multiple phvs, see stateful2x16phv.p4
    bitvec data_location;
    bool single_loc = true;
    int field_bit = 0;
    if (auto *sl = read.expr->to<IR::Slice>()) {
        single_loc = false;
        field_bit = sl->getL();
    }
    data_location.setrange(container_bit, read.size());
    cstring arg_name;
    if (read.speciality == ActionAnalysis::ActionParam::METER_ALU) {
        arg_name = "meter_alu";
    } else {
        BUG("Currently cannot handle the speciality %d in ActionFormat creation",
            read.speciality);
    }
    adp.arg_locs.emplace_back(arg_name, data_location, field_bit, single_loc);
    adp.arg_locs.back().speciality = read.speciality;

    if (read.speciality != ActionAnalysis::ActionParam::NO_SPECIAL)
        adp.specialities |= 1 << read.speciality;
    adp.phv_bits |= data_location;
}

/**
 * MAU Figure 6-74: Stateful ALU block diagram
 *
 * The alu-hi/lo outputs are also sent to the output ALU where they can be passed to the action data
 * bus.  If the output ALU is predicated off, then its output is gated to 0.  The exception to this
 * is when the 4b predication output from cmp-hi/lo is being sent directly to the action data bus.
 *
 * Note:
 *
 * Same as meter alu above, the output format is encoded as a bitvec of 4 bit.
 *
 * MAU Sec 6.2.12.7: ALU output
 *
 * Multiple stateful ALU outputs can be OR’ed together onto the action data bus by configuring the
 * shift values the same across each stateful ALU.
 */

/**
 * Tofino can support at most one meter_alu or stateful alu in each action, because the they share
 * the same address bus to meter ram or stateful ram.
 *
 * This function uses the container information from action analysis to generate the meter_alu
 * output format on action data bus.  Note that the output from meter_alu is usually 32-bit, and
 * PHV allocation determines how many container(s) are needed to operate on the 32-bit output.
 * The PHV allocation may allocate four 8bit container, or two 16bit container, or other
 * configurations.
 *
 * The meter_alu format should reflect the PHV allocation result, since the action data bus has
 * constraints on where a certain size can be placed.
 *
 * init_alu_format is initialized with (one or more) alu_output data for each action.
 */
void CollectMeterOutput::create_placement(
        const ActionAnalysis::ContainerActionsMap &container_actions_map, cstring action_name) {
    // aout_vector is the action data placement for all containers used by meter_alu in this action.
    safe_vector<ActionFormat::ActionDataForSingleALU> aout_vector;

    // container_actions_map saves all containers used by the action
    for (auto &container_action_info : container_actions_map) {
        auto container = container_action_info.first;
        auto &cont_action = container_action_info.second;
        ActionFormat::ActionDataForSingleALU aout;
        aout.container_valid = true;

        for (auto &field_action : cont_action.field_actions) {
            le_bitrange bits;
            auto *write_field = phv.field(field_action.write.expr, &bits);
            le_bitrange container_bits;
            int write_count = 0;

            write_field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
                write_count++;
                container_bits = alloc.container_bits();
                BUG_CHECK(container_bits.lo >= 0, "Invalid negative container bit");
                if (!alloc.container)
                    ERROR("Phv field " << write_field->name << " written in action "
                                       << action_name << " is not allocated?");
                aout.container = alloc.container;
            });

            if (write_count > 1)
                BUG("Splitting of writes handled incorrectly");

            for (auto &read : field_action.reads) {
                // only handle meter alu outputs
                if (read.speciality != ActionAnalysis::ActionParam::METER_ALU)
                    continue;

                // only append to aout if the action read from meter alu.
                create_action_data_from_meter_alu(aout, read, container_bits.lo);
                aout.alu_size = container.size();

                auto attachedOutput = read.unsliced_expr()->to<IR::MAU::AttachedOutput>();
                auto attachedMemory = attachedOutput->attached->to<IR::MAU::AttachedMemory>();
                ActionFormat::TotalALUPlacement empty_tap;
                if (!meter_output_placement.count(attachedMemory)) {
                    meter_output_placement.emplace(attachedMemory, empty_tap);
                }
                auto& action_data = meter_output_placement.at(attachedMemory);
                ActionFormat::SingleActionALUPlacement saap_empty;
                if (!action_data.count(action_name))
                    action_data.emplace(action_name, saap_empty);
                auto& single_alu_action = action_data.at(action_name);
                single_alu_action.push_back(aout);
            }
        }
    }
}

// iterate through all tables in the program to collect meter output usage,
// map each meter instance to the use of meter output in each table.
// if a meter is used by multiple tables, the mapping is from the meter
// to another map that maps tables that use the meter and the usage in the table.
// map<IR::BFN::Meter*, map<(table, action), vector<ActionDataForSingleALU>>
bool CollectMeterOutput::preorder(const IR::MAU::Table* tbl) {
    ActionAnalysis::FieldActionsMap field_actions_map;
    ActionAnalysis::ContainerActionsMap container_actions_map;
    for (auto action : Values(tbl->actions)) {
        field_actions_map.clear();
        container_actions_map.clear();

        ActionAnalysis aa(phv, true, false, tbl);
        aa.set_field_actions_map(&field_actions_map);
        aa.set_container_actions_map(&container_actions_map);
        action->apply(aa);

        create_placement(container_actions_map, action->name);
    }
    return true;
}

// compute the slot_loc and slot_bits fields for meter action data from other
// fields gathered from the action analysis pass.  the slot_loc field is
// defined as the offset in the allocated slot on action data bus.  A slot on
// action data bus could be 8 bit, 16 bit or 32 bit, depending on the ALU that
// operates on the action data.  In this pass, we always assume that the action
// data are only used by meter output, as the create_placement function only
// process reads with METER_ALU speciality.
void AllocMeterOutput::alloc_format(ActionFormat::TotalALUPlacement &init_alu_format) {
    for (auto &mp : init_alu_format) {
        for (auto &alu : mp.second) {
            // the slot_loc for meter action data is computed in two steps:
            // First, because meter action data must start from the bottom bit
            // of the home row bus. we shift the phv_bits down to bottom bit 0.
            // for example, given a 19-bit lpf output using 2 16-bit action
            // data slot.
            //
            // ALU:H19 PHV: 0xffff Slot 0xffff ArgLocs: { meter_alu[0:15] PHV
            // 0xffff slot 0xffff } ALU:H20 PHV: 0x380 Slot 0x7 ArgLocs: {
            // meter_alu[16:18] PHV 0x380 slot 0x7 }
            //
            // the slot_loc is computed as 0xffff and 0x7.
            int shift = alu.phv_bits.min().index();
            for (auto &arg_loc : alu.arg_locs) {
                arg_loc.slot_loc = arg_loc.phv_loc >> shift;
            }

            // Next, some corner case arises when the meter action data is
            // sliced at an offset that does not equal to the size of the slot.
            // We need to shift the phv_bits UP by the modulo of offset in
            // meter alu and the slot size. This is a little hard to
            // understand, see the example below: if a 19-bit lpf output uses 2
            // 32-bit action data slot.
            //
            // ALU:W18 PHV: 0x7f80000 Slot 0xff ArgLocs: {
            // meter_alu[0:7] PHV 0x7f80000 slot 0xff }
            // ALU:W19 PHV: 0x3ff80000 Slot 0x7ff00 ArgLocs: {
            // meter_alu[8:18] PHV 0x3ff80000 slot 0x7ff00 }
            //
            // If we do not perform the second step, the computed slot_loc
            // would be 0x7ff.  In the case of a 32-bit slot, this means the
            // bottom 11 bit of the slot, which is incorrect offset to read
            // meter_alu[8..18].
            for (auto &arg_loc : alu.arg_locs) {
                arg_loc.slot_loc <<= arg_loc.field_bit % alu.alu_size;
            }

            // Finally, the slot bit used by the alu is computed by OR-ing all
            // arg_loc's slot_loc in the same alu.
            for (auto &arg_loc : alu.arg_locs) {
                alu.slot_bits |= arg_loc.slot_loc;
            }

            int max = 0;
            std::set<int> all_starts;
            for (auto &arg_loc : alu.arg_locs) {
                auto arg_start = arg_loc.field_bit / 8;
                if (arg_start > max)
                    max = arg_start;
                all_starts.insert(arg_start);
            }
            BUG_CHECK(all_starts.size() == 1, "cannot read from different start "
                                              "bytes in the same alu");
            alu.start = max;
        }
    }
}

// A meter ALU can output to one or more PHV containers. A PHV container
// (8/16/32) uses one or more bytes on the action output xbar. This function
// encodes the use of PHV containers as ByteEnables on action output xbar.
// ByteEnables are represented with bitvec. One bitvec is used for each
// container size. If multiple containers of the same size are used, the
// ByteEnable of the containers are concatenated with each other.
void AllocMeterOutput::setup_layout(ActionFormat::TotalALUPlacement &init_alu_format,
                                    const IR::MAU::Table* tbl,
                                    const IR::MAU::AttachedMemory* am) {
    MeterFormat::Use use;
    use.attached = am;

    int counts[ActionFormat::CONTAINER_TYPES] = {0, 0, 0};
    // slot_uses is used to count how many slots are used for each size (8, 16,
    // 32).  Each bit in slot_use represents a slot being used for that size.
    // for example, 1111 in slot_use[BYTE] means four byte slot are used,
    // whereas 0001 in slot_use[FULL] mean one full-word slot is used.
    bitvec slot_uses[ActionFormat::CONTAINER_TYPES];

    // for each use of meter in an action
    for (auto &single_action : init_alu_format) {
        // for all alu operations associated with the meter
        for (auto &alu : single_action.second) {
            int index = alu.gen_index();
            auto &single_slot_use = slot_uses[index];
            for (auto &arg_loc : alu.arg_locs) {
                auto bit_loc = arg_loc.field_hi() / alu.alu_size;
                if (arg_loc.field_hi() % alu.alu_size != 0)
                    bit_loc += 1;
                single_slot_use.setbit(bit_loc);
            }
            counts[index] = single_slot_use.popcount();
        }
    }

    int count_byte = counts[ActionFormat::BYTE];
    int count_half = counts[ActionFormat::HALF];
    int count_full = counts[ActionFormat::FULL];
    LOG3("count " << count_byte << " " << count_half << " " << count_full);

    bitvec byte_range;
    for (int i = 0; i < count_byte; i++) {
        byte_range.setbit(i);
    }
    use.total_layouts[ActionFormat::BYTE] |= byte_range;

    bitvec half_range;
    for (int i = 0; i < count_half; i++) {
        half_range.setrange(2*i, 2);
    }
    use.total_layouts[ActionFormat::HALF] |= half_range;

    bitvec full_range;
    for (int i = 0; i < count_full; i++) {
        full_range.setrange(4*i, 4);
    }
    use.total_layouts[ActionFormat::FULL] |= full_range;

    use.action_data_format = init_alu_format;

    layoutChoices.total_meter_output_format[tbl->name] = use;

    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++) {
        LOG3("Layout ADT: 0x" << use.total_layouts[i] << " IMMED: "
                              << use.total_layouts[i] << " METER: "
                              << use.total_layouts[i]);
    }
}

bool AllocMeterOutput::preorder(const IR::MAU::Table* tbl) {
    MeterFormat::Use use;

    bool found_meter = false;
    const IR::MAU::AttachedMemory *am = nullptr;
    ActionFormat::TotalALUPlacement meter_placement;
    for (auto at : tbl->attached) {
        // IR::MAU::Meter is used by LPF
        // IR::MAU::StatefulALU is used by salu.
        if (!at->attached->is<IR::MAU::Meter>() &&
            !at->attached->is<IR::MAU::StatefulAlu>())
            continue;
        am = at->attached->to<IR::MAU::AttachedMemory>();
        if (am == nullptr) continue;
        if (!meter_output_placement.count(am)) continue;
        meter_placement = meter_output_placement.at(am);
        found_meter = true;
    }
    if (!found_meter)
        return true;

    alloc_format(meter_placement);
    setup_layout(meter_placement, tbl, am);
    return true;
}

/** Meter ALU output is often saved to a PHV container to be used in next
 * stage. The path to the PHV goes through action data bus and VLIW ALU. A PHV
 * container is 'shared' between meter ALUs if multiple meter ALUs outputs to
 * the same PHV container.
 *
 *  1. Different actions in the same table invoke the same meter ALU, and the
 *  results are written to the same PHV container.
 *
 *  action act_1 { f = meter.execute(1); }
 *  action act_2 { f = meter.execute(2); }
 *  action act_3 { f = meter.execute(3); }
 *  table t { actions = { act_1; act_2; act_3; } }
 *
 *  2. Different actions in different tables invoke the same meter ALU, and the
 *  results are written to the same PHV container.
 *
 *  action act_1 { f = meter.execute(1); }
 *  action act_2 { f = meter.execute(2); }
 *  action act_3 { f = meter.execute(3); }
 *  table t_1 { actions = { act_1; } }
 *  table t_2 { actions = { act_2; } }
 *  table t_3 { actions = { act_3; } }
 *
 *  3. Different actions in different tables invoke different meter ALU and the
 *  results are written to the same PHV container.
 *
 *  action act_1 { f = meter_1.execute(); }
 *  action act_2 { f = meter_2.execute(); }
 *  action act_3 { f = meter_3.execute(); }
 *  table t1 { actions = { act_1; } }
 *  table t2 { actions = { act_2; } }
 *  table t3 { actions = { act_3; } }
 */

