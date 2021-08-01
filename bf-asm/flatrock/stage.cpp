/* mau stage template specializations for jbay -- #included directly in top-level stage.cpp */

template<> void Stage::output<Target::Flatrock>(json::map &ctxt_json) {
    BUG("TBD");
}

void AlwaysRunTable::write_regs(Target::Flatrock::mau_regs &regs) {
    BUG("TBD");
}
