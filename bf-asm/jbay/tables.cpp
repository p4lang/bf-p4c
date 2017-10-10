/* mau table template specializations for jbay -- #included directly in tables.cpp */

template<> void MatchTable::setup_next_table_map(Target::JBay::mau_regs &regs, Table *tbl) {
    auto &merge = regs.rams.match.merge;
    merge.next_table_map_en |= (1U << logical_id);
    int i = 0;
    for (auto &n : tbl->hit_next)
        merge.pred_map_loca[logical_id][i++].pred_map_loca_next_table = n ? n->table_id() : 0x1ff;
}

template<> void MatchTable::write_regs(Target::JBay::mau_regs &regs, int type, Table *result) {
    write_common_regs<Target::JBay>(regs, type, result);
    auto &merge = regs.rams.match.merge;
    if (pred.empty()) {
        merge.pred_always_run[gress] |= 1 << logical_id;
        merge.mpr_always_run |= 1 << logical_id; }
}
