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

struct ftr_str_info_t {
    int                                 len;
    unsigned                            use;
    checked_array_base<ubits<1>>        &en;
    checked_array_base<ubits<2>>        &sel;
};


typedef std::map<const Phv::Register *, unsigned> pov_map_t;

template<class REG, class ITER>
void fill_string(int idx, int seq, ITER begin, ITER end, const pov_map_t &pov_map, REG &reg) {
    unsigned i = 0;
    reg.sel[idx].seq = seq;
    for (auto &pov : begin->pov)
        reg.sel[idx].pov_sel[i++] = pov_map.at(&pov->reg) + pov->lo;
    i = 0;
    for (auto it = begin; it != end; ++it) {
        for (int j = 0; j < it->what->size(); ++j) {
            reg.el_type[idx].el_type[i] = 1;  // PHV only for now
            BUG_CHECK(it->what->template is<Deparser::FDEntry::Phv>(), "not PHV");
            reg.el_value[idx].value[i] = it->what->encode() + j;
            ++i; } }
}

template<> void Deparser::write_config(Target::Flatrock::deparser_regs &regs) {
    unsigned i = 0;
    pov_map_t pov_map;
    auto &phvxb = regs.dprsr_phvxb_rspec;
    for (auto &ent : pov_order[EGRESS]) {
        pov_map.emplace(&ent->reg, i*8);
        for (unsigned j = 0; j < ent->reg.size/8; ++j) {
            phvxb.phe2pov[i/4].phe_byte[i%4] = ent->reg.deparser_id() + j;
            ++i; } }

    ftr_str_info_t info[3] = {
        // FIXME the chip supports 16 different configs for the strings, selected by a tcam
        // match.  We just always program config 0 here
        { 8, 0, phvxb.str8.str8_cfg[0].en, phvxb.str8.str8_cfg[0].sel },
        { 16, 0, phvxb.str16.str16_cfg[0].en, phvxb.str16.str16_cfg[0].sel },
        { 32, 0, phvxb.str32.str32_cfg[0].en, phvxb.str32.str32_cfg[0].sel },
    };

    auto next = dictionary[EGRESS].begin();
    unsigned max_bytes = 32;
    int seq = 0;
    for (auto it = next; it != dictionary[EGRESS].end(); it = next) {
        int entries = 1;
        unsigned bytes = it->what->size();
        while (++next != dictionary[EGRESS].end()) {
            if (next->pov != it->pov) break;   // need a different string for different POV
            // other checks that mean it and next can't be in the same string here
            if (bytes + next->what->size() > max_bytes) break;
            bytes += next->what->size(); }
        auto *i = info;
        while (i < std::end(info) && (bytes > i->len || i->use >= i->en.size())) ++i;
        BUG_CHECK(i < std::end(info), "ran off end of possible string types");
        i->en[i->use] = 1;
        i->sel[i->use] = 0;
        switch (i->len) {
        case 8: fill_string(i->use*4, seq, it, next, pov_map, regs.dprsr_sd_rspec.str8); break;
        case 16: fill_string(i->use*4, seq, it, next, pov_map, regs.dprsr_sd_rspec.str16); break;
        case 32: fill_string(i->use*4, seq, it, next, pov_map, regs.dprsr_sd_rspec.str32); break;
        default: BUG("bad size"); }
        ++seq;
        ++i->use;
        while (i->use == i->en.size()) {
            if (i->len != max_bytes) break;
            BUG_CHECK(i != std::begin(info), "ran out of strings?");
            max_bytes = (--i)->len; }
    }

    if (!intrinsics.empty())
        error(intrinsics.front().lineno, "Flatrock intrinsics not implemented yet!");
    if (!digests.empty())
        error(digests.front().lineno, "Flatrock digests not implemented yet!");
}

template<> void Deparser::gen_learn_quanta(Target::Flatrock::deparser_regs&,
                                           json::vector &) {
}
