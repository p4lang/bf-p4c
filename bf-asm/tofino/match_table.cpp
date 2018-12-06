/* mau table template specializations for tofino -- #included directly in match_tables.cpp */

template<> void MatchTable::setup_next_table_map(Target::Tofino::mau_regs &regs, Table *tbl) {
    auto &merge = regs.rams.match.merge;
    // Copies the values directly from the hit map provided by the compiler directly into the
    // map
    if (tbl->get_hit_next().empty())
        return;
    merge.next_table_map_en |= (1U << logical_id);
    auto &mp = merge.next_table_map_data[logical_id];
    ubits<8> *map_data[8] = { &mp[0].next_table_map_data0, &mp[0].next_table_map_data1,
        &mp[0].next_table_map_data2, &mp[0].next_table_map_data3, &mp[1].next_table_map_data0,
        &mp[1].next_table_map_data1, &mp[1].next_table_map_data2, &mp[1].next_table_map_data3 };
    int index = 0;
    for (auto &n : tbl->get_hit_next()) {
        if (n.name == "END") {
            *map_data[index] = 0xff;
        } else {
            *map_data[index] = n->table_id();
        }
        index++;
    }
}

template<> void MatchTable::write_regs(Target::Tofino::mau_regs &regs, int type, Table *result) {
    write_common_regs<Target::Tofino>(regs, type, result);
}
