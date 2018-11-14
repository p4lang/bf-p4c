#include "action_bus.h"
#include "algorithm.h"
#include "hex.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(ExactMatchTable)

void ExactMatchTable::setup(VECTOR(pair_t) &data) {
    common_init_setup(data, false, P4Table::MatchEntry);
    for (auto &kv : MapIterChecked(data)) {
        if (common_setup(kv, data, P4Table::MatchEntry)) {
        // Dynamic key masks are only on exact match tables
        } else if (kv.key == "dynamic_key_masks") {
            if (CHECKTYPE(kv.value, tSTR))
                dynamic_key_masks = (strncmp(kv.value.s, "true", 4) == 0);
        } else common_sram_setup(kv, data); }
    common_sram_checks();
}

void ExactMatchTable::pass1() {
    LOG1("### Exact match table " << name() << " pass1");
    SRamMatchTable::pass1();
}

void ExactMatchTable::setup_ways() {
    SRamMatchTable::setup_ways();
    for (auto &row : layout) {
        int first_way = -1;
        for (auto col : row.cols) {
            int way = way_map.at(std::make_pair(row.row, col)).way;
            if (first_way < 0) {
                first_way = way;
            } else if (ways[way].group != ways[first_way].group) {
                error(row.lineno, "Ways %d and %d of table %s share address bus on row %d, "
                      "but use different hash groups", first_way, way, name(), row.row);
                break; } } }
}

void ExactMatchTable::pass2() {
    LOG1("### Exact match table " << name() << " pass2");
    if (logical_id < 0) choose_logical_id();
    input_xbar->pass2();
    setup_word_ixbar_group();
    if (actions) actions->pass2(this);
    if (gateway) gateway->pass2();
    if (idletime) idletime->pass2();
    if (format) format->pass2(this);
}

void ExactMatchTable::pass3() {
    LOG1("### Exact match table " << name() << " pass3");
    if (action_bus) action_bus->pass3(this);
}

/* FIXME -- should have ExactMatchTable::write_merge_regs write some of the merge stuff
 * from write_regs? */
template<class REGS> void ExactMatchTable::write_regs(REGS &regs) {
    LOG1("### Exact match table " << name() << " write_regs");
    SRamMatchTable::write_regs(regs);

    for (auto &row : layout) {
        auto &rams_row = regs.rams.array.row[row.row];
        for (auto col : row.cols) {
            auto &way = way_map[std::make_pair(row.row, col)];
            auto &ram = rams_row.ram[col];
            ram.match_nibble_s0q1_enable = version_nibble_mask.getrange(way.word*32U, 32);
            ram.match_nibble_s1q0_enable = UINT64_C(0xffffffff); } }
}

void ExactMatchTable::gen_tbl_cfg(json::vector &out) const {
    unsigned size = get_number_entries();
    json::map &tbl = *base_tbl_cfg(out, "match", size);
    add_all_reference_tables(tbl);
    json::map &stage_tbl = *add_common_sram_tbl_cfgs(tbl, "exact", "hash_match");
    add_pack_format(stage_tbl, format, true, false);
    stage_tbl["memory_resource_allocation"] = nullptr;
    //FIXME: stash_allocation being null is a placeholder until implemented.
    stage_tbl["stash_allocation"] = nullptr;
    json::map &match_attributes = tbl["match_attributes"];
    match_attributes["uses_dynamic_key_masks"] = dynamic_key_masks;
    if (ways.size() > 0) {
        json::vector &way_stage_tables = stage_tbl["ways"] = json::vector();
        unsigned way_number = 0;
        for (auto &way : ways) {
            json::map way_tbl;
            way_tbl["stage_number"] = stage->stageno;
            way_tbl["way_number"] = way_number++;
            way_tbl["stage_table_type"] = "hash_way";
            way_tbl["size"] = way.rams.size()/get_format_width() * format->groups() * 1024;
            add_pack_format(way_tbl, format, false);
            way_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg(way);
            way_stage_tables.push_back(std::move(way_tbl)); } }
    if (size == 0) {
        match_attributes["match_type"] = "match_with_no_key";
        stage_tbl["stage_table_type"] = "match_with_no_key";
        stage_tbl["size"] = 1024; }
}

// Create json node for ghost bits - exact match only
void ExactMatchTable::gen_ghost_bits(const std::map<int, HashCol> &hash_table,
        unsigned hash_table_id, json::vector &ghost_bits_to_hash_bits,
        json::vector &ghost_bits_info, bitvec hash_bits_used) const {
    // Return if this function is already visited
    bitvec bit_position;
    for (auto &col: hash_table) {
        auto hash_bit = col.first;
        if (!hash_bits_used.getbit(hash_bit)) continue;
        for (const auto &bit : col.second.data) {
            if (auto ref = input_xbar->get_hashtable_bit(hash_table_id, bit)) {
                std::string field_name = ref.name();
                remove_aug_names(field_name);
                auto field_bit = remove_name_tail_range(field_name) + ref.lobit();
                // Ghost bits are bits not present in the match overhead
                if (!is_match_bit(field_name, field_bit)) {
                    auto bit_in_match_spec = get_param_start_bit_in_spec(field_name) + field_bit;
                    auto p4_param = find_p4_param(field_name);
                    // Generate ghost_bit_info element if not already present
                    if (!bit_position.getbit(bit_in_match_spec)) {
                        json::map ghost_bit_info;
                        ghost_bit_info["bit_in_match_spec"] = bit_in_match_spec;
                        if (p4_param && !p4_param->key_name.empty()) {
                            field_name = p4_param->key_name;
                        }
                        ghost_bit_info["field_name"] = field_name;
                        ghost_bits_info.push_back(std::move(ghost_bit_info));
                        bit_position.setbit(bit_in_match_spec);
                    }
                    // Ghost bit index in 'ghost_bit_info' &
                    // 'ghost_bit_to_hash_bit' is same. Find index in
                    // 'ghost_bit_info' for this ghost bit since we have already
                    // populated it and use it to add hash bit to
                    // 'ghost_bit_to_hash_bit' node
                    unsigned index = 0;
                    for (auto &g : ghost_bits_info) {
                        auto &m = g->to<json::map>();
                        if (m["bit_in_match_spec"]->to<json::number>() 
                                    == bit_in_match_spec) break;
                        index++;
                    }
                    if (ghost_bits_to_hash_bits.size() > index) {
                        json::vector &gbhb = ghost_bits_to_hash_bits[index]->to<json::vector>();
                        gbhb.push_back(hash_bit);
                    } else {
                        json::vector ghost_bit_to_hash_bit;
                        ghost_bit_to_hash_bit.push_back(hash_bit);
                        ghost_bits_to_hash_bits.push_back(std::move(ghost_bit_to_hash_bit));
                    }

                    break;
                }
            }
        }
    }
}
