/* mau gateway template specializations for tofino -- #included directly in gateway.cpp */

template<> void GatewayTable::write_next_table_regs(Target::Tofino::mau_regs &regs) {
    auto &merge = regs.rams.match.merge;
    int idx = 3;
    if (need_next_map_lut)
        error(lineno, "Tofino does not support using next_map_lut in gateways");
    for (auto &line : table) {
        BUG_CHECK(idx >= 0);
        if (!line.run_table)
            merge.gateway_next_table_lut[logical_id][idx] = line.next.next_table_id();
        --idx; }
    if (!miss.run_table)
        merge.gateway_next_table_lut[logical_id][4] = miss.next.next_table_id();
}
