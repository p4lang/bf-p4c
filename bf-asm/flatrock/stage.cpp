/* mau stage template specializations for jbay -- #included directly in top-level stage.cpp */

template<> void Stage::fixup_regs(Target::Flatrock::mau_regs &) {
}
template<> void Stage::gen_configuration_cache(Target::Flatrock::mau_regs &, json::vector &) {
}
template<> void Stage::gen_gfm_json_info(Target::Flatrock::mau_regs &, std::ostream &) {
}
template<> void Stage::gen_mau_stage_characteristics(Target::Flatrock::mau_regs &, json::vector &) {
}
template<> void Stage::gen_mau_stage_extension(Target::Flatrock::mau_regs &, json::map &) {
}
template<> void Stage::write_regs(Target::Flatrock::mau_regs &) {
}

void AlwaysRunTable::write_regs(Target::Flatrock::mau_regs &regs) {
    BUG("TBD");
}
