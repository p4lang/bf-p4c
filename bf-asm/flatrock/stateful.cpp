/* mau table template specializations for flatrock -- #included directly in stateful.cpp */

int StatefulTable::parse_counter_mode(Target::Flatrock target, const value_t &v) {
    return parse_jbay_counter_mode(v);
}

void StatefulTable::set_counter_mode(Target::Flatrock target, int mode) {
    error(lineno, "%s:%d: Flatrock stateful not implemented yet!", __FILE__, __LINE__);
}

void StatefulTable::gen_tbl_cfg(Target::Flatrock, json::map&, json::map&) const {
    error(lineno, "%s:%d: Flatrock stateful not implemented yet!", __FILE__, __LINE__);
}
