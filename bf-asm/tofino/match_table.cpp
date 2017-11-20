/* mau table template specializations for tofino -- #included directly in match_tables.cpp */

template<> void MatchTable::setup_next_table_map(Target::Tofino::mau_regs &regs, Table *tbl) {
    auto &merge = regs.rams.match.merge;
    merge.next_table_map_en |= (1U << logical_id);
    auto &mp = merge.next_table_map_data[logical_id];
    ubits<8> *map_data[8] = { &mp[0].next_table_map_data0, &mp[0].next_table_map_data1,
        &mp[0].next_table_map_data2, &mp[0].next_table_map_data3, &mp[1].next_table_map_data0,
        &mp[1].next_table_map_data1, &mp[1].next_table_map_data2, &mp[1].next_table_map_data3 };
    int i = 0;
    for (auto &n : tbl->hit_next)
        *map_data[i++] = n ? n->table_id() : 0xff;
}

template<> void MatchTable::write_regs(Target::Tofino::mau_regs &regs, int type, Table *result) {
    write_common_regs<Target::Tofino>(regs, type, result);
}
