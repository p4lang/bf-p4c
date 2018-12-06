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

/**
 * Any bits that are not matched directly against, but appear in the key of the p4 table,
 * are ghost bits.  The rules for ghost bits on exact match tables are:
 *
 *    1. Any field that does not appear in the match key must appear in the hash function.  This
 *       is considered a ghost bit
 *    2. A hash column can have at most one ghost bit, in order to maintain the linear
 *       independence of the impact of each ghost bit.  
 *
 * The following function verifies these two properties, and saves them in a map to be output
 * in the gen_ghost_bits function call
 */
void ExactMatchTable::determine_ghost_bits() {
    std::set<std::pair<std::string, int>> ghost_bits;
    // Determine ghost bits by determine what is not in the match
    for (auto p4_param : p4_params_list) {
        for (int bit = p4_param.start_bit; bit < p4_param.start_bit + p4_param.bit_width; bit++) {
            bool found = false;
            for (auto ms : match) {
                std::string field_name = ms->name();
                remove_aug_names(field_name);
                int field_bit_lo = remove_name_tail_range(field_name) + ms->fieldlobit();
                int field_bit_hi = field_bit_lo + ms->size() - 1;
                if (field_name == p4_param.name && field_bit_lo <= bit && field_bit_hi >= bit) {
                    found = true;
                    break;
                }
            }
            if (found)
                continue;
            ghost_bits.emplace(p4_param.name, bit);
        }
    }

    int way_index = 0;
    for (auto way : ways) {
        auto *hash_group = input_xbar->get_hash_group(way.group);
        BUG_CHECK(hash_group != nullptr);

        // key is the field name/field bit that is the ghost bit
        // value is the bits that the ghost bit appears in within this way
        std::map<std::pair<std::string, int>, bitvec> ghost_bit_impact;

        // Calculate the ghost bit per hash way
        for (unsigned hash_table_id : bitvec(hash_group->tables)) {
            auto &hash_table = input_xbar->get_hash_table(hash_table_id);
            for (auto hash_bit : way.select_bits()) {
                if (hash_table.count(hash_bit) == 0)
                    continue;
                const HashCol &hash_col = hash_table.at(hash_bit);
                for (const auto &input_bit : hash_col.data) {
                    if (auto ref = input_xbar->get_hashtable_bit(hash_table_id, input_bit)) {
                        std::string field_name = ref.name();
                        remove_aug_names(field_name);
                        int field_bit = remove_name_tail_range(field_name) + ref.fieldlobit();
                        auto key = std::make_pair(field_name, field_bit);
                        auto ghost_bit_it = ghost_bits.find(key);
                        if (ghost_bit_it == ghost_bits.end())
                            continue;

                        // This is a check to make sure that the ghost bit appears only once
                        // in the hash column, as an even number of appearances would
                        // xor each other out, and cancel the hash out.  This check
                        // should be done on all hash bits
			if (ghost_bit_impact[key].getbit(hash_bit)) {
                            error(input_xbar->lineno, "Ghost bit %s:%d appears multiple times "
                                  "in the same hash col %d", key.first.c_str(), key.second,
                                  way_index);
                            return;
                        }
                        ghost_bit_impact[key].setbit(hash_bit); 
                    }
                }
            }
        }

        // Verify that each ghost bit appears in the hash function
        for (auto gb : ghost_bits) {
            if (ghost_bit_impact.find(gb) == ghost_bit_impact.end()) {
                error(input_xbar->lineno, "Ghost bit %s:%d does not appear on the hash function "
                      "for way %d", gb.first.c_str(), gb.second, way_index);
                return;
            }
        }

        // Verify that the ghost bits are linearly independent, that only one ghost bit
        // exists per column
        bitvec total_use;
        for (auto gbi : ghost_bit_impact) {
            if (!(total_use & gbi.second).empty())
                error(input_xbar->lineno, "The ghost bits are not linear independent on way %d",
                      way_index);
            total_use |= gbi.second;
        }

        auto &ghost_bit_position = ghost_bit_positions[way.group];
        for (auto gbi : ghost_bit_impact) {
            ghost_bit_position[gbi.first] |= gbi.second;
        }
        way_index++;
    }
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
    determine_ghost_bits();
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

/**
 * The ghost_bits information is required by the driver to correctly run an entry read from
 * hardware.  Ghost bits are bits that do not appear in the key, and must be calculated
 * from the hash matrix.
 *
 * The ghost_bits information is broken into two vectors:
 *
 * - ghost_bit_info: a vector of information on ghost bits, maps of 2 fields
 *      1. field_name - name of the field being ghosted
 *      2. bit_in_match_spec - awfully named for the field bit (not the bit in the entire key)
 *
 * - ghost_bit_to_hash_bit: a vector per each entry in the ghost_bit_info describing which
 *   hash bits coordinate to which ghost bits
 */
void ExactMatchTable::gen_ghost_bits(int hash_function_number,
        json::vector &ghost_bits_to_hash_bits, json::vector &ghost_bits_info) const {
    if (ghost_bit_positions.count(hash_function_number) == 0)
        return;
    auto ghost_bit_pos = ghost_bit_positions.at(hash_function_number);
    
    for (auto kv : ghost_bit_pos) {
        json::map ghost_bit_info;
        auto field_name = kv.first.first;
        auto p4_param = find_p4_param(field_name);
        if (p4_param && !p4_param->key_name.empty())
            field_name = p4_param->key_name;
        ghost_bit_info["field_name"] = field_name;
        ghost_bit_info["bit_in_match_spec"] = kv.first.second;
        ghost_bits_info.push_back(std::move(ghost_bit_info));

        json::vector ghost_bit_to_hash_bits;
        for (auto hash_bit : kv.second)
            ghost_bit_to_hash_bits.push_back(hash_bit); 
        ghost_bits_to_hash_bits.push_back(std::move(ghost_bit_to_hash_bits));
    }
}
