#include "tables.h"
#include "stage.h"
#include "input_xbar.h"

DEFINE_TABLE_TYPE(ProxyHashMatchTable)

void ProxyHashMatchTable::setup(VECTOR(pair_t) &data) {
    common_init_setup(data, false, P4Table::MatchEntry);
    for (auto &kv : MapIterChecked(data)) {
        if (common_setup(kv, data, P4Table::MatchEntry)) {
        } else if (kv.key == "proxy_hash_group") {
            if (CHECKTYPE(kv.value, tINT)) {
                proxy_hash_group = kv.value.i;
            }
        } else if (kv.key == "proxy_hash_algorithm") {
            if (CHECKTYPE(kv.value, tSTR)) {
                proxy_hash_alg = kv.value.s;
            }
        } else if (kv.key == "search_bus" || kv.key == "result_bus") {
            // already dealt with in Table::setup_layout via common_init_setup
        } else {
            common_sram_setup(kv, data);
        }
    }
}

bool ProxyHashMatchTable::verify_match_key() {
    for (auto &match_key : match) {
        if (!dynamic_cast<HashMatchSource *>(match_key)) {
            error(match_key->get_lineno(), "A proxy hash table %s has a non hash key", name());
            continue;
        }
    }
    auto match_format = format->field("match");
    if (match_format && match.empty())
        BUG_CHECK("Proxy hash table has no match");
    return error_count == 0;
}

int ProxyHashMatchTable::determine_pre_byteswizzle_loc(MatchSource *ms, int lo, int hi, int word) {
    return (ms->slicelobit() + lo) / 8;
}

void ProxyHashMatchTable::pass1() {
    LOG1("### Proxy Hash table " << name() << " pass1");
    SRamMatchTable::pass1();
}

void ProxyHashMatchTable::setup_ways() {
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

void ProxyHashMatchTable::setup_word_ixbar_group() {
    word_ixbar_group.resize(match_in_word.size());
    for (size_t i = 0; i < match_in_word.size(); i++) {
        // Basically the value per row/bus of rams.row.vh_xbar.exactmatch_row_vh_xbar_ctl,
        // based on the diagram in uArch section 6.2.3 Exact Match Row Vertical/Horizontal (VH)
        // Xbars
        word_ixbar_group[i] = BYTE_XBAR_GROUPS + proxy_hash_group;
    }
}

void ProxyHashMatchTable::pass2() {
    LOG1("### Proxy Hash table " << name() << " pass2");
    input_xbar->pass2();
    setup_word_ixbar_group();
     
    if (actions) actions->pass2(this);
    if (gateway) gateway->pass2();
    if (idletime) idletime->pass2();
    if (format) format->pass2(this);
}

void ProxyHashMatchTable::pass3() {
    LOG1("### Proxy Hash match table " << name() << " pass3");
}

template<class REGS> void ProxyHashMatchTable::write_regs(REGS &regs) {
    LOG1("### Proxy Hash match table " << name() << " write_regs");
    SRamMatchTable::write_regs(regs);

    for (auto &row : layout) {
        auto &rams_row = regs.rams.array.row[row.row];
        for (auto col : row.cols) {
            auto &way = way_map[std::make_pair(row.row, col)];
            auto &ram = rams_row.ram[col];
            ram.match_nibble_s0q1_enable = version_nibble_mask.getrange(way.word*32U, 32);
            ram.match_nibble_s1q0_enable = UINT64_C(0xffffffff); } }

}

/**
 * The purpose of this function is to add the proxy_hash_function cJSON node.  This is used
 * by the driver in order to build the match key for the proxy hash table.
 *
 * By using the group from the proxy hash table, only pull the relevant bits for the proxy
 * hash lookup.
 */
void ProxyHashMatchTable::add_proxy_hash_function(json::map &stage_tbl) const {
    bitvec hash_matrix_use;
    for (auto *match_key : match) {
        hash_matrix_use.setrange(match_key->fieldlobit(), match_key->size());
    }

    json::map &proxy_hash_function = stage_tbl["proxy_hash_function"] = json::map();
    json::vector &hash_bits = proxy_hash_function["hash_bits"] = json::vector();
    auto *hash_group = input_xbar->get_hash_group(proxy_hash_group);
    if (hash_group) {
        for (unsigned hash_table_id : bitvec(hash_group->tables)) {
            auto hash_table = input_xbar->get_hash_table(hash_table_id);
            gen_hash_bits(hash_table, hash_table_id, hash_bits, proxy_hash_group, hash_matrix_use);
        }
        proxy_hash_function["hash_function_number"] = proxy_hash_group;
        proxy_hash_function["ghost_bit_to_hash_bit"] = json::vector();
        proxy_hash_function["ghost_bit_info"] = json::vector();
    }
}

void ProxyHashMatchTable::gen_tbl_cfg(json::vector &out) const {
    unsigned size = get_number_entries();
    json::map &tbl = *base_tbl_cfg(out, "match", size);
    json::map &stage_tbl = *add_common_sram_tbl_cfgs(tbl, "exact", "proxy_hash_match");
    stage_tbl["memory_resource_allocation"] = nullptr;
    //FIXME: stash_allocation being null is a placeholder until implemented.
    stage_tbl["stash_allocation"] = nullptr;
    add_pack_format(stage_tbl, format, true, false);
    json::map &match_attributes = tbl["match_attributes"];
    match_attributes["uses_dynamic_key_masks"] = false;
    if (ways.size() > 0) {
        json::vector &way_stage_tables = stage_tbl["ways"] = json::vector();
        unsigned way_number = 0;
        for (auto &way : ways) {
            json::map way_tbl;
            way_tbl["stage_number"] = stage->stageno;
            way_tbl["way_number"] = way_number++;
            way_tbl["stage_table_type"] = "hash_way";
            auto fmt_width = get_format_width();
            BUG_CHECK(fmt_width);
            way_tbl["size"] = way.rams.size()/fmt_width * format->groups() * 1024;
            add_pack_format(way_tbl, format, false);
            way_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg(way);
            way_stage_tables.push_back(std::move(way_tbl));
        }
    }
    add_proxy_hash_function(stage_tbl);
    stage_tbl["proxy_hash_algorithm"] = proxy_hash_alg; 
    int proxy_hash_width = 0;
    for (auto m : match) {
        proxy_hash_width += m->size();
    }
    stage_tbl["proxy_hash_bit_width"] = proxy_hash_width;
}