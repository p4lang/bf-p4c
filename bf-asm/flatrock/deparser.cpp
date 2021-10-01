/* deparser template specializations for flatrock -- #included directly in top-level deparser.cpp */

// minimal intrinsics for now
DEPARSER_INTRINSIC(Flatrock, EGRESS, egress_unicast_port, 1) { }
DEPARSER_INTRINSIC(Flatrock, INGRESS, egress_unicast_port, 1) { }

template<> unsigned Deparser::FDEntry::Checksum::encode<Target::Flatrock>() {
    BUG("TBD");
}

template<> unsigned Deparser::FDEntry::Constant::encode<Target::Flatrock>() {
    BUG("TBD");
}

template<> void Deparser::write_config(Target::Flatrock::deparser_regs&) {
    BUG("TBD");
}
