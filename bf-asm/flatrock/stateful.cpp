/* mau table template specializations for flatrock -- #included directly in stateful.cpp */

int StatefulTable::parse_counter_mode(Target::Flatrock target, const value_t &v) {
    BUG("TBD");
}

void StatefulTable::set_counter_mode(Target::Flatrock target, int mode) {
    BUG("TBD");
}

void StatefulTable::gen_tbl_cfg(Target::Flatrock, json::map&, json::map&) const {
    BUG("TBD");
}
