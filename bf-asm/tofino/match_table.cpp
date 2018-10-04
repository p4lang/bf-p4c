/* mau table template specializations for tofino -- #included directly in match_tables.cpp */

template<> void MatchTable::setup_next_table_map(Target::Tofino::mau_regs &regs, Table *tbl) {
    auto &merge = regs.rams.match.merge;
    merge.next_table_map_en |= (1U << logical_id);
    auto &mp = merge.next_table_map_data[logical_id];
    ubits<8> *map_data[8] = { &mp[0].next_table_map_data0, &mp[0].next_table_map_data1,
        &mp[0].next_table_map_data2, &mp[0].next_table_map_data3, &mp[1].next_table_map_data0,
        &mp[1].next_table_map_data1, &mp[1].next_table_map_data2, &mp[1].next_table_map_data3 };
    unsigned  next_bits = 0;
    std::map<std::string, unsigned> next_table_encodings;
    if (auto nf = tbl->get_format()) {
        if (auto next_field = nf->field("next")) {
            // next_table_map is indexed through "next" bits if present and if
            // we dont use all 8 bits in match overhead for next tables
            assert((1U << next_field->size) <= NEXT_TABLE_SUCCESSOR_TABLE_DEPTH);
            next_bits = next_field->size; 
            unsigned next_bits_encoding = 0;
            // Generate unique encodings for next tables
            for (auto &n : tbl->hit_next) {
                if (n.name == "END") continue;
                if (next_table_encodings.count(n->name()) == 0)
                    next_table_encodings[n->name()] = next_bits_encoding++; 
            }
            assert(next_bits_encoding <= (1U << next_bits)); } }

    // If there is only one default next table then the format may not have an
    // 'action' or 'next' field. In this case we set a default encoding to 0
    if ((tbl->hit_next.size() == 1) && (next_table_encodings.empty())) 
            if (tbl->hit_next[0].name != "END")
                next_table_encodings[tbl->hit_next[0]->name()] = 0;

    // Action bits or Next bits form the index for next table map data. Next
    // bits if present are directly used as index. This is used for > 8 actions
    // which call < 8 tables so there cant be a 1:1 mapping from action bits to
    // next table map data index. This index is then specified as 'next_table'
    // in the 'action_format'  
    int hit_next_index = 0;
    for (auto &n : tbl->hit_next) {
        if (n.name == "END") {
            if (tbl->hit_next.size() == 1)
                *map_data[0] = 0xFF;
            // If table has gateway, do not increment for first index reserved for gateway
            if (!((hit_next_index == 0) && (tbl->get_gateway())))
                hit_next_index++;
            continue; }
        if (auto acts = tbl->get_actions()) {
            for (auto &act : *acts) {
                // Index into the original action order in assembly as hit_next
                // is setup according to this order
                if (act.position_in_assembly == hit_next_index) {
                    // If next bits are used, encoding is based on next bits
                    // only
                    if (next_table_encodings.size() > 0) { 
                        if (next_table_encodings.count(n->name()) > 0) {
                            act.next_table_encode = next_table_encodings[n->name()];
                            *map_data[act.next_table_encode] = n->table_id(); } 
                    } else if (act.code >= 0) {
                        // If action bits are used the instruction index is used
                        // to index in both instruction map data and 
                        assert(act.code < 8);
                        act.next_table_encode = act.code;
                        *map_data[act.next_table_encode] = n->table_id(); } } }
            hit_next_index++; } }
}

template<> void MatchTable::write_regs(Target::Tofino::mau_regs &regs, int type, Table *result) {
    write_common_regs<Target::Tofino>(regs, type, result);
}
