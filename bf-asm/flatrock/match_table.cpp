/* mau table template specializations for flatrock -- #included directly in match_tables.cpp */

template<> void MatchTable::write_next_table_regs(Target::Flatrock::mau_regs &regs, Table *tbl) {
    BUG("TBD");
}

template<> void MatchTable::write_regs(Target::Flatrock::mau_regs &regs, int type, Table *result) {
    if (input_xbar) input_xbar->write_regs(regs);
}
