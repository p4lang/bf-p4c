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
        } else common_sram_setup(kv, data); }
    common_sram_checks();
}

void ExactMatchTable::pass1() {
    LOG1("### Exact match table " << name() << " pass1");
    SRamMatchTable::pass1();
}

void ExactMatchTable::setup_ways() {
    SRamMatchTable::setup_ways();
    // FIXME -- check to ensure that ways that share a bus use the same hash group?
    //Setup unique hash_function_id for each way group
    unsigned hash_fn_id = 0;
    for (auto &w : ways) {
        if (hash_fn_ids.count(w.group) == 0)
            hash_fn_ids[w.group] = hash_fn_id++; }
}

void ExactMatchTable::pass2() {
    LOG1("### Exact match table " << name() << " pass2");
    if (logical_id < 0) choose_logical_id();
    input_xbar->pass2();
    setup_word_ixbar_group();
    if (actions) actions->pass2(this);
    if (action_bus) action_bus->pass2(this);
    if (gateway) gateway->pass2();
    if (idletime) idletime->pass2();
    if (format) format->pass2(this);
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
            ram.match_nibble_s1q0_enable = 0xffffffffUL; } }
}

std::unique_ptr<json::map> ExactMatchTable::gen_memory_resource_allocation_tbl_cfg(Way &way) {
    json::map mra;
    unsigned vpn_ctr = 0;
    unsigned fmt_width = format ? (format->size + 127)/128 : 0;
    if (hash_fn_ids.count(way.group) > 0)
        mra["hash_function_id"] = hash_fn_ids[way.group];
    mra["hash_entry_bit_lo"] = way.subgroup*10;
    mra["hash_entry_bit_hi"] = way.subgroup*10 + 9;
    mra["number_entry_bits"] = 10;
    if (way.mask) {
        int lo = ffs(way.mask) - 1, hi = floor_log2(way.mask);
        mra["hash_select_bit_lo"] = 40 + lo;
        mra["hash_select_bit_hi"] = 40 + hi;
        if (way.mask != (1 << (hi+1)) - (1 << lo)) {
            warning(way.lineno, "driver does not support discontinuous bits in a way mask");
            mra["hash_select_bit_mask"] = way.mask >> lo; }
    } else
        mra["hash_select_bit_lo"] = mra["hash_select_bit_hi"] = 40;
    mra["number_select_bits"] = bitcount(way.mask);
    json::vector mem_units;
    json::vector &mem_units_and_vpns = mra["memory_units_and_vpns"] = json::vector();
    for (auto &ram : way.rams) {
        if (mem_units.empty())
            vpn_ctr = layout_get_vpn(ram.first, ram.second);
        else
            assert(vpn_ctr == layout_get_vpn(ram.first, ram.second));
        mem_units.push_back(memunit(ram.first, ram.second));
        if (mem_units.size() == fmt_width) {
            json::map tmp;
            tmp["memory_units"] = std::move(mem_units);
            mem_units = json::vector();
            json::vector vpns;
            for (unsigned i = 0; i < format->groups(); i++)
                vpns.push_back(vpn_ctr++);
            tmp["vpns"] = std::move(vpns);
            mem_units_and_vpns.push_back(std::move(tmp)); } }
    assert(mem_units.empty());
    return json::mkuniq<json::map>(std::move(mra));
}

void ExactMatchTable::gen_tbl_cfg(json::vector &out) {
    unsigned size = get_number_entries();
    json::map &tbl = *base_tbl_cfg(out, "match", size);
    add_all_reference_tables(tbl);
    json::map &stage_tbl = *add_common_sram_tbl_cfgs(tbl, "exact", "hash_match");
    add_pack_format(stage_tbl, format, true, false);
    stage_tbl["memory_resource_allocation"] = nullptr;
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
        json::map &match_attributes = tbl["match_attributes"];
        match_attributes["match_type"] = "match_with_no_key";
        stage_tbl["stage_table_type"] = "match_with_no_key";
        stage_tbl["size"] = 1024; }
}

// Generate hash_functions node in cjson.
// Loop through each way and get the associated hash group. Output hash bits for
// each table accessed by the hash group with seed and bits_to_xor info.
// 'bits_to_xor' has a field_bit and field_name which correspond to the xor'd
// fields bit position and field's (p4) name. Check that the name appears in the
// match key fields (p4_params_list) as this is verified by the driver.  Do not
// repeat a hash group if already visited.
void ExactMatchTable::add_hash_functions(json::map &stage_tbl) {
    bitvec visited_groups(EXACT_HASH_GROUPS,0);
    auto &ht = input_xbar->get_hash_tables();
    // Output cjson node only if hash tables present
    if (ht.size() > 0) {
        json::vector &hash_functions = stage_tbl["hash_functions"] = json::vector();
        for (auto &way : ways) {
            int hash_group_no = way.group;
            // Do not output json for already processed hash groups
            if (visited_groups[hash_group_no]) continue;
            // Setup cjson hash_function
            json::map hash_function;
            json::vector &hash_bits = hash_function["hash_bits"] = json::vector();
            // Get the hash group data
            auto *hash_group = input_xbar->get_hash_group(hash_group_no);
            if (hash_group) {
                // Process only hash tables used per hash group
                for (unsigned hash_table_id: bitvec(hash_group->tables)) {
                    auto hash_table = input_xbar->get_hash_table(hash_table_id);
                    gen_hash_bits(hash_table, hash_table_id, hash_bits); }
            hash_functions.push_back(std::move(hash_function));
            // Mark hash group as visited
            visited_groups[hash_group_no] = 1; } } }
}

