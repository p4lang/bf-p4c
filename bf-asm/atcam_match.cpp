#include "action_bus.h"
#include "algorithm.h"
#include "hex.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(AlgTcamMatchTable)

void AlgTcamMatchTable::setup(VECTOR(pair_t) &data) {
    common_init_setup(data, false, P4Table::MatchEntry);
    for (auto &kv : MapIterChecked(data)) {
        if (common_setup(kv, data, P4Table::MatchEntry)) {
        } else if (kv.key == "number_partitions") {
            if (CHECKTYPE(kv.value, tINT))
                number_partitions = kv.value.i;
        } else if (kv.key == "partition_field_name") {
            if (CHECKTYPE(kv.value, tSTR)) {
                partition_field_name = kv.value.s;
                if (auto* p = find_p4_param(partition_field_name))
                    if (!p->key_name.empty())
                        partition_field_name = p->key_name; }
        } else if (kv.key == "subtrees_per_partition") {
            if (CHECKTYPE(kv.value, tINT))
                max_subtrees_per_partition = kv.value.i;
        } else common_sram_setup(kv, data); }
    common_sram_checks();
}

// XXX(Amresh): This could probably be rewritten in a simpler way. Below
// function checks the ways extracted from assembly for atcam and assumes the
// way no's are not sorted with column priority. Therefore the code sorts the
// first ram column and sets the column priority based on this column. Then this
// ordering is used to check if column priority is maintained if the ways are
// traversed in this column priority order for all other columns
void AlgTcamMatchTable::setup_column_priority() {
    int no_ways = ways.size();
    int no_entries_per_way = ways[0].rams.size();
    int ram = -1;
    // FIXME: Brig currently does not support rams 6 & 7 on both sides, once
    // that supported is added this function should accommodate these rams in
    // lrams and rrams and the traversal mechanism must be changed to determine
    // column priority
    std::set<int> lrams = { 2, 3, 4, 5, 6 };
    std::set<int> rrams = { 7, 8, 9, 10, 11 };
    // Check if column is on left(0) or right(1) RAMs
    // Sort ways based on column priority for first column
    for (int w = 0; w < no_ways; w++) {
        int col_ram = ways[w].rams[0].second;
        int col_row = ways[w].rams[0].first;
        col_priority_way[col_ram] = w;
        if (ram == 0) {
            if (lrams.find(col_ram) == lrams.end())
                error (lineno,
                    "ram %d and %d not in same column as rest", col_row, col_ram);
        } else if (ram == 1) {
            if (rrams.find(col_ram) == rrams.end())
                error (lineno,
                    "ram %d and %d not in same column as rest", col_row, col_ram);
        } else if (lrams.find(col_ram) != lrams.end()) ram = 0;
          else if (rrams.find(col_ram) != rrams.end())ram = 1; }
    // Use sorted ways to validate column priority on remaining columns
    int prev_ram = -1;
    int prev_way = -1;
    int prev_row = -1;
    for (int i = 1; i < no_entries_per_way; i++) {
        auto col = col_priority_way.begin();
        while(col != col_priority_way.end()) {
            int col_ram = ways[col->second].rams[i].second;
            int col_row = ways[col->second].rams[i].first;
            int col_way = col->second;
            if (col != col_priority_way.begin()) {
                if (((col_ram <= prev_ram) && (rrams.find(col_ram) != rrams.end()) 
                      && (ram == 1) && (prev_row == col_row))
                   || ((col_ram >= prev_ram) && (rrams.find(col_ram) != rrams.end()) 
                       && (ram == 0) && (prev_row == col_row)))
                    error(lineno,
                        "ram's [%d,%d] and [%d,%d] not in column priority order for ways %d and %d"
                            ,col_row, col_ram, prev_row, prev_ram, col_way, prev_way);
                if (((col_ram <= prev_ram) && (lrams.find(col_ram) != lrams.end()) 
                      && (ram == 0) && (prev_row == col_row))
                   || ((col_ram >= prev_ram) && (lrams.find(col_ram) != lrams.end()) 
                       && (ram == 1) && (prev_row == col_row)))
                    error(lineno,
                        "ram's [%d,%d] and [%d,%d] not in column priority order for ways %d and %d"
                            ,col_row, col_ram, prev_row, prev_ram, col_way, prev_way);
            } 
            prev_ram = col_ram;
            prev_way = col_way; 
            prev_row = col_row; 
            col++; } }
}

void AlgTcamMatchTable::pass1() {
    LOG1("### ATCAM match table " << name() << " pass1");
    SRamMatchTable::pass1();
    if (format) {
        setup_column_priority();
        find_tcam_match(); }
}

void AlgTcamMatchTable::setup_nibble_mask(Table::Format::Field *match, int group,
                              std::map<int, match_element> &elems, bitvec &mask) {
    for (auto &el : Values(elems)) {
        int bit = match->bit(el.offset);
        if (match->hi(bit) < bit + el.width - 1)
            error(el.field->lineno, "match bits for %s not contiguous in match(%d)",
                  el.field->desc().c_str(), group);
        else if ((bit % 4U) != 0) {
            // Ignore warnings for single valid bits
            if ((el.width == 1) && (el.field->desc().find("$valid") != std::string::npos)) {}
            else
                warning(el.field->lineno, "match bits for %s not nibble aligned in match(%d)",
                  el.field->desc().c_str(), group);
            if (el.width < 4)
                mask.setrange(bit/4U, el.width);
            else
                mask.setrange(bit/4U, el.width/4U);
        } else
            mask.setrange(bit/4U, el.width/4U); }
}

void AlgTcamMatchTable::find_tcam_match() {
    std::map<Phv::Slice, match_element>                                 exact;
    std::map<Phv::Slice, std::pair<match_element, match_element>>       tcam;
    unsigned off = 0;
    /* go through the match fields and find duplicates -- those are the tcam matches */
    for (auto &match_field : match) {
        auto sl = *match_field;
        if (!sl) continue;
        if (exact.count(sl)) {
            if (tcam.count(sl))
                error(match_field.lineno, "%s appears more than twice in atcam match",
                      match_field.desc().c_str());
            if ((sl.size() % 4U) != 0) {
                if ((sl.size() == 1) && (match_field.desc().find("$valid") != std::string::npos)) {}
                else 
                    warning(match_field.lineno, "tcam match field %s not a multiple of 4 bits",
                      match_field.desc().c_str()); }
            tcam.emplace(sl, std::make_pair(exact.at(sl),
                            match_element{ &match_field, off, sl->size() }));
            exact.erase(sl);
        } else {
            exact.emplace(sl, match_element{ &match_field, off, sl->size() }); }
        off += sl.size(); }
    for (auto e : exact)
        for (auto t : tcam)
            if (e.first.overlaps(t.first))
                error(e.second.field->lineno, "%s overlaps %s in atcam match",
                      e.second.field->desc().c_str(), t.second.first.field->desc().c_str());
    if (error_count > 0) return;
    /* for the tcam pairs, treat first as s0q1 and second as s1q0 */
    for (auto &el : Values(tcam)) {
        s0q1[el.first.offset] = el.first;
        s1q0[el.second.offset] = el.second; }
    /* now find the bits in each group that match with the tcam pairs, ensure that they
     * are nibble-aligned, and setup the nibble masks */
    for (unsigned i = 0; i < format->groups(); i++) {
        if (Format::Field *match = format->field("match", i)) {
            setup_nibble_mask(match, i, s0q1, s0q1_nibbles);
            setup_nibble_mask(match, i, s1q0, s1q0_nibbles);
        } else {
            error(format->lineno, "no 'match' field in format group %d", i); } }
}

void AlgTcamMatchTable::pass2() {
    LOG1("### ATCAM match table " << name() << " pass2");
    if (logical_id < 0) choose_logical_id();
    input_xbar->pass2();
    setup_word_ixbar_group();
    ixbar_subgroup.resize(word_ixbar_group.size());
    ixbar_mask.resize(word_ixbar_group.size());
    // FIXME -- need a method of specifying these things in the asm code?
    // FIXME -- should at least check that these are sane
    for (unsigned i = 0; i < word_ixbar_group.size(); ++i) {
        if (word_ixbar_group[i] < 0) {
            // Word with no match data, only version/valid; used for direct lookup
            // tables -- can it happen with an atcam table?
            continue; }
        bitvec ixbar_use = input_xbar->hash_group_bituse(word_ixbar_group[i]);
        // Which 10-bit address group to use for this word -- use the lowest one with
        // a bit set in the hash group.  Can it be different for different words?
        ixbar_subgroup[i] = ixbar_use.min().index() / EXACT_HASH_ADR_BITS;
        // Assume that any hash bits usuable for select are used for select
        ixbar_mask[i] = ixbar_use.getrange(EXACT_HASH_FIRST_SELECT_BIT, EXACT_HASH_SELECT_BITS); }
    if (actions) actions->pass2(this);
    if (gateway) gateway->pass2();
    if (idletime) idletime->pass2();
    if (format) format->pass2(this);
}

void AlgTcamMatchTable::pass3() {
    LOG1("### ATCAM match table " << name() << " pass3");
    if (action_bus) action_bus->pass3(this);
}

template<class REGS> void AlgTcamMatchTable::write_regs(REGS &regs) {
    LOG1("### ATCAM match table " << name() << " write_regs");
    SRamMatchTable::write_regs(regs);

    for (auto &row : layout) {
        auto &rams_row = regs.rams.array.row[row.row];
        for (auto col : row.cols) {
            auto &way = way_map[std::make_pair(row.row, col)];
            auto &ram = rams_row.ram[col];
            ram.match_nibble_s0q1_enable =
                version_nibble_mask.getrange(way.word*32U, 32) &~ s1q0_nibbles.getrange(way.word*32U, 32);
            ram.match_nibble_s1q0_enable = 0xffffffffUL &~ s0q1_nibbles.getrange(way.word*32U, 32); } }
}

std::unique_ptr<json::vector> AlgTcamMatchTable::gen_memory_resource_allocation_tbl_cfg() {
    if (col_priority_way.size() == 0)
        error(lineno, "No column priority determined for table %s", name());
    int col_priority = 0;
    unsigned fmt_width = format ? (format->size + 127)/128 : 0;
    json::vector mras;
    //for (auto &col : col_priority_way) {
    auto col_priority_way_revitr = col_priority_way.rbegin();
    while(col_priority_way_revitr != col_priority_way.rend()) {
        json::map mra;
        mra["column_priority"] = col_priority++;
        json::vector mem_units;
        json::vector &mem_units_and_vpns = mra["memory_units_and_vpns"] = json::vector();
        auto &way = ways[col_priority_way_revitr->second];
        unsigned vpn_ctr = 0;
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
        mras.push_back(std::move(mra));
        ++col_priority_way_revitr;
    }
    return json::mkuniq<json::vector>(std::move(mras));
}

std::string AlgTcamMatchTable::get_match_mode(Phv::Ref &pref, int offset) {
    for (auto &p : s0q1) {
        if ((p.first == offset) && (*p.second.field == pref))
            return "s0q1";
    }
    for (auto &p : s1q0) {
        if ((p.first == offset) && (*p.second.field == pref))
            return "s1q0";
    }
    return "unused";
}

void AlgTcamMatchTable::gen_unit_cfg(json::vector &units, int size) {
    json::map tbl;
    tbl["direction"] = gress ? "egress" : "ingress";
    tbl["handle"] = p4_table ? is_alpm() ? p4_table->get_alpm_atcam_table_handle(): p4_table->get_handle() : 0;
    tbl["name"] = name();
    tbl["size"] = size;
    tbl["table_type"] = "match";
    json::map &stage_tbl = *add_common_sram_tbl_cfgs(tbl, "algorithmic_tcam_unit", "algorithmic_tcam_match");
    // Assuming atcam next hit table cannot be multiple tables
    stage_tbl["default_next_table"] = (hit_next.size() > 0 && hit_next[0].name != "END")
                                    ? hit_next[0]->table_id() : Target::END_OF_PIPE();
    stage_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg();
    add_pack_format(stage_tbl, format, false);
    units.push_back(std::move(tbl));
}

void AlgTcamMatchTable::gen_alpm_cfg(json::vector &out) {
}

void AlgTcamMatchTable::gen_tbl_cfg(json::vector &out) {
    json::map *atcam_tbl_ptr;
    unsigned number_entries = layout_size()/match.size() * 512;
    if (is_alpm()) {
        // Add ALPM ATCAM config to ALPM table (generated by pre-classifier in
        // previous ostage)
        json::map *alpm_tbl_ptr = base_tbl_cfg(out, "match", number_entries);
        if (!alpm_tbl_ptr) {
            error(lineno, "No alpm table generated by alpm pre-classifier");
            return; }
        json::map &alpm_tbl = *alpm_tbl_ptr;
        common_tbl_cfg(alpm_tbl);
        // FIXME-DRIVER
        // 'actions' and 'table_refs' on the alpm are redundant as they are
        // already present in the atcam table. These should probably be cleaned
        // up from the context json and driver parsing.
        if (actions) {
            actions->gen_tbl_cfg(alpm_tbl["actions"]);
        } else if (action && action->actions) {
            action->actions->gen_tbl_cfg(alpm_tbl["actions"]); }
        add_all_reference_tables(alpm_tbl);
        json::map &alpm_match_attributes = alpm_tbl["match_attributes"];
        alpm_match_attributes["max_subtrees_per_partition"] = max_subtrees_per_partition;
        alpm_match_attributes["partition_field_name"] = get_partition_field_name();
        alpm_match_attributes["lpm_field_name"] = get_lpm_field_name();
        alpm_match_attributes["bins_per_partition"] = p4_size()/number_partitions + 1;
        alpm_match_attributes["set_partition_action_handle"] = get_partition_action_handle();
        alpm_match_attributes["stage_tables"] = json::vector();
        json::map &atcam_tbl = alpm_match_attributes["atcam_table"];
        if (number_entries == 0)
            number_entries = p4_size() / max_subtrees_per_partition;
        base_alpm_atcam_tbl_cfg(atcam_tbl, "match", number_entries);
        atcam_tbl_ptr = &atcam_tbl;
    } else {
        atcam_tbl_ptr = base_tbl_cfg(out, "match", number_entries); }
    json::map &tbl = *atcam_tbl_ptr;
    common_tbl_cfg(tbl);
    json::map &match_attributes = tbl["match_attributes"];
    match_attributes["match_type"] = "algorithmic_tcam";
    if (actions) {
        actions->gen_tbl_cfg(tbl["actions"]);
    } else if (action && action->actions) {
        action->actions->gen_tbl_cfg(tbl["actions"]); }
    json::vector &units = match_attributes["units"];
    gen_unit_cfg(units, number_entries);
    match_attributes["number_partitions"] = number_partitions;
    match_attributes["partition_field_name"] = partition_field_name;
    add_all_reference_tables(tbl);
    // Empty stage table node in atcam. These are moved inside the
    // units->MatchTable->stage_table node
    match_attributes["stage_tables"] = json::vector();
}
