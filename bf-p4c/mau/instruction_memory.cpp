#include "bf-p4c/mau/instruction_memory.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/table_format.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/device.h"

bool GenerateVLIWInstructions::preorder(const IR::MAU::Action *) {
    current_vliw.clear();
    return true;
}

bool GenerateVLIWInstructions::preorder(const IR::Expression *expr) {
    if (isWrite()) {
        le_bitrange bits;
        auto field = phv.field(expr, &bits);
        BUG_CHECK(field != nullptr, "Instruction writing to a non-phv allocated object");
        // Mark which containers are to have non noop instructions
        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
            current_vliw.setbit(Device::phvSpec().containerToId(alloc.container));
        });
        return false;
    }
    return true;
}

void GenerateVLIWInstructions::postorder(const IR::MAU::Action *act) {
    table_instrs[act] = current_vliw;
}

bool InstructionMemory::is_noop_slot(int row, int color) {
    return row == NOOP_ROW && color == NOOP_COLOR;
}

bool InstructionMemory::find_row_and_color(bitvec current_bv, gress_t gress, int &row, int &color) {
    auto &use = imem_use(gress);
    auto &slot_in_use = imem_slot_inuse(gress);

    // Reserve all noops for the first line
    if (current_bv.empty()) {
        row = NOOP_ROW;
        color = NOOP_COLOR;
        return true;
    }

    for (int i = 0; i < IMEM_ROWS; i++) {
        bitvec current_row;
        bool occupied = true;
        for (int j = 0; j < IMEM_COLORS; j++) {
            if (is_noop_slot(i, j))
                continue;

            if (use[i][j].isNull())
                occupied = false;
            current_row |= slot_in_use[i][j];
        }
        if (occupied)
            continue;

        // Make sure that no color collision exists
        if (!(current_row & current_bv).empty())
            continue;

        for (int j = 0; j < IMEM_COLORS; j++) {
            if (is_noop_slot(i, j))
                continue;
            if (!use[i][j].isNull())
                continue;
            row = i;
            color = j;
            return true;
        }
        BUG("Unreachable section of the instruction memory allocation");
    }
    return false;
}


bool InstructionMemory::allocate_imem(const IR::MAU::Table *tbl, Use &alloc, const PhvInfo &phv,
        bool gw_linked) {
    // Action Profiles always have the same instructions for every table
    LOG1("Allocating action data bus for " << tbl->name);
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        auto ad = at->to<IR::MAU::ActionData>();
        if (ad == nullptr) continue;
        if (shared_action_profiles.count(ad)) {
            LOG2("Already shared through the action profile");
            auto cached = shared_action_profiles.at(ad);
            alloc.all_instrs = cached;
            return true;
        }
        shared_action_profiles.emplace(ad, alloc.all_instrs);
    }
    GenerateVLIWInstructions gen_vliw(phv);
    tbl->apply(gen_vliw);
    auto &use = imem_use(tbl->gress);
    auto &slot_in_use = imem_slot_inuse(tbl->gress);

    // TODO: potentially sharing mem_codes between identical actions
    int hit_actions = tbl->hit_actions();
    if (gw_linked)
        hit_actions += 1;

    bool can_use_hitmap = hit_actions <= TableFormat::IMEM_MAP_TABLE_ENTRIES;

    int hit_action_index = gw_linked ? 1 : 0;
    for (auto action : Values(tbl->actions)) {
        LOG2("Allocating action " << action->name);
        auto current_bv = gen_vliw.get_instr(action);
        int row = -1;
        int color = -1;
        if (!find_row_and_color(current_bv, tbl->gress, row, color))
            return false;
        LOG2("Row and color " << row << " " << color);
        Use::VLIW_Instruction single_instr(current_bv, row, color);
        if (!action->miss_only()) {
            if (can_use_hitmap)
                single_instr.mem_code = hit_action_index;
            else
                single_instr.mem_code = single_instr.gen_addr();
            LOG2("Mem code " << single_instr.mem_code);
            hit_action_index++;
        }
        alloc.all_instrs.emplace(action->name, single_instr);
        use[row][color] = tbl->name + "$" + action->name.originalName;
        slot_in_use[row][color] = current_bv;
    }
    return true;
}

void InstructionMemory::update(cstring name, const Use &alloc, gress_t gress) {
    auto &use = imem_use(gress);
    auto &slot_in_use = imem_slot_inuse(gress);

    for (auto &entry : alloc.all_instrs) {
        auto a_name = name + "$" + entry.first;
        auto instr = entry.second;
        int row = instr.row;
        int color = instr.color;
        if (is_noop_slot(row, color)) {
            BUG_CHECK(instr.non_noop_instructions.empty(), "Allocating %s, which has ALU "
                      "operations, to the noop slot in the instruction memory", a_name);

            if (!use[row][color].isNull())
                use[row][color] = a_name;

        } else {
            if (!use[row][color].isNull() && use[row][color] != a_name) {
                BUG("Instructions %s and %s are assigned to the same slot.",
                     use[row][color], a_name);
            }
            use[row][color] = a_name;
        }

        int opposite_color = color == 1 ? 0 : 1;
        if (!(slot_in_use[row][opposite_color] & instr.non_noop_instructions).empty())
            BUG("Colliding instructions on row %d for action %s and action %s", row,
                use[row][opposite_color], a_name);
        slot_in_use[row][color] = instr.non_noop_instructions;
    }
}

void InstructionMemory::update(cstring name, const TableResourceAlloc *alloc, gress_t gress) {
    update(name, alloc->instr_mem, gress);
}

void InstructionMemory::update(cstring name, const TableResourceAlloc *alloc,
        const IR::MAU::Table *tbl) {
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        auto ad = at->to<IR::MAU::ActionData>();
        if (ad == nullptr) continue;
        if (shared_action_profiles.count(ad))
            return;
        shared_action_profiles.emplace(ad, alloc->instr_mem.all_instrs);
    }
    update(name, alloc, tbl->gress);
}

void InstructionMemory::update(const IR::MAU::Table *tbl) {
    if (tbl->layout.atcam && tbl->is_placed()) {
        auto orig_name = tbl->name.before(tbl->name.findlast('$'));
        if (atcam_updates.count(orig_name))
            return;
        atcam_updates.emplace(orig_name);
    }
    update(tbl->name, tbl->resources, tbl);
}
