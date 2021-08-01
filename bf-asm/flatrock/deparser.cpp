/* deparser template specializations for flatrock -- #included directly in top-level deparser.cpp */

template<> unsigned Deparser::FDEntry::Checksum::encode<Target::Flatrock>() {
    BUG("TBD");
}

template<> unsigned Deparser::FDEntry::Constant::encode<Target::Flatrock>() {
    BUG("TBD");
}

template<> void Deparser::write_config(Target::Flatrock::deparser_regs&) {
    BUG("TBD");
}
