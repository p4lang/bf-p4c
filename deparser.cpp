#include "deparser.h"
#include "phv.h"
#include "range.h"

Deparser Deparser::singleton_object;

Deparser::Deparser() : Section("deparser") {
    declare_registers(&inp_regs, sizeof(inp_regs),
        [](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.input_phase"; });
    declare_registers(&hdr_regs, sizeof(inp_regs),
        [](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.header_phase"; });
}
Deparser::~Deparser() {
    undeclare_registers(&inp_regs);
    undeclare_registers(&hdr_regs);
}

struct Deparser::Intrinsic {
    gress_t     gress;
    std::string name;
    int         max;
    static std::map<std::string, Intrinsic *> all[2];
protected:
    Intrinsic(gress_t gr, const char *n, int m) : gress(gr), name(n), max(m) {
        assert(!all[gr].count(name));
        all[gress][name] = this; }
    ~Intrinsic() { all[gress].erase(name); }
public:
    virtual void setregs(Deparser *dep, std::vector<Phv::Ref> &vals) = 0;
};
std::map<std::string, Deparser::Intrinsic *> Deparser::Intrinsic::all[2];
#define INTRINSIC(GR, NAME, MAX, CODE) \
static struct INTRIN##GR##NAME : public Deparser::Intrinsic {           \
    INTRIN##GR##NAME() : Deparser::Intrinsic(GR, #NAME, MAX) {}         \
    void setregs(Deparser *dep, std::vector<Phv::Ref> &vals) { CODE; }  \
} INTRIN##GR##NAME##_singleton;
#define HIR_INTRINSIC(NAME) INTRINSIC(INGRESS, NAME, 1,                 \
    dep->hdr_regs.hir.ingr.NAME.phv = vals[0]->reg.index;               \
    dep->hdr_regs.hir.ingr.NAME.valid = 1; )
#define HER_INTRINSIC(NAME) INTRINSIC(EGRESS, NAME, 1,                  \
    dep->hdr_regs.her.egr.NAME.phv = vals[0]->reg.index;                \
    dep->hdr_regs.her.egr.NAME.valid = 1; )

INTRINSIC(INGRESS, egress_unicast_port, 1,
    dep->inp_regs.iir.main_i.egress_unicast_port.phv = vals[0]->reg.index;
    dep->inp_regs.iir.main_i.egress_unicast_port.valid = 1; )
INTRINSIC(INGRESS, copy_to_cpu, 1,
    dep->inp_regs.iir.ingr.copy_to_cpu.phv = vals[0]->reg.index;
    dep->inp_regs.iir.ingr.copy_to_cpu.valid = 1;)
INTRINSIC(INGRESS, egress_multicast_group, 2,
    int i = 0;
    for (auto &el : vals) {
        dep->hdr_regs.hir.ingr.egress_multicast_group[i].phv = el->reg.index;
        dep->hdr_regs.hir.ingr.egress_multicast_group[i++].valid = 1; } )
INTRINSIC(INGRESS, hash_lag_ecmp_mcast, 2,
    int i = 0;
    for (auto &el : vals) {
        dep->hdr_regs.hir.ingr.hash_lag_ecmp_mcast[i].phv = el->reg.index;
        dep->hdr_regs.hir.ingr.hash_lag_ecmp_mcast[i++].valid = 1; } )
HIR_INTRINSIC(copy_to_cpu_cos)
INTRINSIC(INGRESS, ingress_port_source, 1,
    dep->hdr_regs.hir.ingr.ingress_port.phv = vals[0]->reg.index;
    dep->hdr_regs.hir.ingr.ingress_port.sel = 0; )
HIR_INTRINSIC(deflect_on_drop)
HIR_INTRINSIC(meter_color)
HIR_INTRINSIC(icos)
HIR_INTRINSIC(qid)
HIR_INTRINSIC(xid)
HIR_INTRINSIC(yid)
HIR_INTRINSIC(rid)
HIR_INTRINSIC(warp)

INTRINSIC(EGRESS, egress_unicast_port, 1,
    dep->inp_regs.ier.main_e.egress_unicast_port.phv = vals[0]->reg.index;
    dep->inp_regs.ier.main_e.egress_unicast_port.valid = 1; )
HER_INTRINSIC(force_tx_err)
HER_INTRINSIC(capture_tx_ts)
HER_INTRINSIC(ecos)

void Deparser::start(int lineno, VECTOR(value_t) args) {
    if (args.size == 0) {
        this->lineno[INGRESS] = this->lineno[EGRESS] = lineno;
        return; }
    if (args.size != 1 || (args[0] != "ingress" && args[0] != "egress"))
        error(lineno, "parser must specify ingress or egress");
    gress_t gress = args[0] == "egress" ? EGRESS : INGRESS;
    if (!this->lineno[gress]) this->lineno[gress] = lineno;
}
void Deparser::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (args.size > 0) {
            if (args[0] == "ingress" && gress != INGRESS) continue;
            if (args[0] == "egress" && gress != EGRESS) continue;
        } else if (error_count > 0)
            break;
        for (auto &kv : MapIterChecked(data.map, true)) {
            if (kv.key == "dictionary") {
                if (!CHECKTYPE(kv.value, tMAP)) continue;
                for (auto &ent : kv.value.map)
                    dictionary[gress].emplace_back(RefOrChksum(gress, ent.key),
                                                   Phv::Ref(gress, ent.value));
            } else if (kv.key == "pov") {
                if (!CHECKTYPE(kv.value, tVEC)) continue;
                for (auto &ent : kv.value.vec)
                    pov_order[gress].emplace_back(gress, ent);
            } else if (kv.key == "learning" && (gress == INGRESS || args.size == 0)) {
                if (gress != INGRESS) continue;
                if (!CHECKTYPE(kv.value, tMAP)) continue;
                for (auto &l : kv.value.map) {
                    if (l.key == "select")
                        learn.select = Phv::Ref(gress, l.value);
                    else if (!CHECKTYPE(l.key, tINT))
                        continue;
                    else if (l.key.i < 0 || l.key.i >= DEPARSER_LEARN_GROUPS)
                        error(l.key.lineno, "Learning index %d out of range", l.key.i);
                    else if (l.value.type != tVEC)
                        learn.layout[l.key.i].emplace_back(gress, l.value);
                    else for (auto &v : l.value.vec)
                        learn.layout[l.key.i].emplace_back(gress, v); }
                if (!learn.select)
                    error(kv.value.lineno, "No select key in leanring spec");
            } else if (kv.key == "checksum") {
                if (kv.key.type != tCMD || kv.key.vec.size != 2 || kv.key[1].type != tINT ||
                    kv.key[1].i < 0 || kv.key[1].i >= DEPARSER_CHECKSUM_UNITS)
                    error(kv.key.lineno, "Invalid checksum unit number");
                else if (CHECKTYPE(kv.value, tVEC)) {
                    int unit = kv.key[1].i;
                    for (auto &ent : kv.value.vec)
                        checksum[gress][unit].emplace_back(gress, ent); }
            } else if (auto *intrin = ::get(Intrinsic::all[gress], value_desc(&kv.key))) {
                intrinsics.emplace_back(intrin, std::vector<Phv::Ref>());
                std::vector<Phv::Ref> &vec = intrinsics.back().second;
                if (kv.value.type == tVEC)
                    for (auto &val : kv.value.vec)
                        vec.emplace_back(gress, val);
                else
                    vec.emplace_back(gress, kv.value);
            } else
                error(kv.key.lineno, "Unknown deparser tag %s", value_desc(&kv.key));
        }
    }
}
void Deparser::process() {
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        for (auto &ent : pov_order[gress])
            if (ent.check())
                phv_use[gress][ent->reg.index] = 1;
        for (auto &ent : dictionary[gress]) {
            if (ent.first.check()) {
                phv_use[gress][ent.first->reg.index] = 1;
                if (ent.first->lo != 0 || ent.first->hi != ent.first->reg.size - 1)
                    error(ent.first.lineno, "Can only output full phv registers, not slices, "
                          "in deparser"); }
            if (ent.second.check()) {
                phv_use[gress][ent.second->reg.index] = 1;
                if (ent.second->lo != ent.second->hi)
                    error(ent.second.lineno, "POV bits should be single bits"); } }
        for (int i = 0; i < DEPARSER_CHECKSUM_UNITS; i++)
            for (auto &ent : checksum[gress][i])
                if (ent.check() && (ent->lo != 0 || ent->hi != ent->reg.size - 1))
                    error(ent.lineno, "Can only do checksums on full phv registers, not slices"); }
    for (auto &intrin : intrinsics) {
        for (auto &el : intrin.second)
            el.check();
        if (intrin.second.size() > (size_t)intrin.first->max)
            error(intrin.second[0].lineno, "Too many values for %s", intrin.first->name.c_str()); }
    if (phv_use[INGRESS].intersects(phv_use[EGRESS]))
        error(lineno[INGRESS], "Registers used in both ingress and egress in deparser: %s",
              Phv::db_regset(phv_use[INGRESS] & phv_use[EGRESS]).c_str());
    if (options.match_compiler) {
        Phv::setuse(INGRESS, phv_use[INGRESS]);
        Phv::setuse(EGRESS, phv_use[EGRESS]); }
    if (learn.select) {
        learn.select.check();
        for (auto &set : learn.layout)
            for (auto &reg : set.second)
                reg.check(); }
}

template<typename IPO, typename HPO> static
void dump_checksum_units(checked_array_base<IPO> &main_csum_units,
                         checked_array_base<HPO> &tagalong_csum_units,
                         std::vector<Phv::Ref> checksum[DEPARSER_CHECKSUM_UNITS])
{
    for (int i = 0; i < DEPARSER_CHECKSUM_UNITS; i++) {
        if (checksum[i].empty()) continue;
        auto &main_unit = main_csum_units[i].csum_cfg_entry;
        auto &tagalong_unit = tagalong_csum_units[i].csum_cfg_entry;
        for (auto &ent : main_unit) {
            ent.zero_l_s_b = 1;
            ent.zero_l_s_b.rewrite();
            ent.zero_m_s_b = 1;
            ent.zero_m_s_b.rewrite(); }
        for (auto &ent : tagalong_unit) {
            ent.zero_l_s_b = 1;
            ent.zero_l_s_b.rewrite();
            ent.zero_m_s_b = 1;
            ent.zero_m_s_b.rewrite(); }
        int polarity = 0;
        for (auto &reg : checksum[i]) {
            int idx = reg->reg.index;
            if (idx >= 256) {
                idx -= 256;
                if (idx < 32) {
                    tagalong_unit[idx*2].zero_l_s_b = 0;
                    tagalong_unit[idx*2].zero_m_s_b = 0;
                    tagalong_unit[idx*2].swap = polarity;
                    tagalong_unit[idx*2+1].zero_l_s_b = 0;
                    tagalong_unit[idx*2+1].zero_m_s_b = 0;
                    tagalong_unit[idx*2+1].swap = polarity;
                } else {
                    tagalong_unit[idx+32].zero_l_s_b = 0;
                    tagalong_unit[idx+32].zero_m_s_b = 0;
                    if (reg->reg.size == 8)
                        polarity ^= 1;
                    tagalong_unit[idx+32].swap = polarity; }
            } else {
                if (idx < 64) {
                    main_unit[idx*2].zero_l_s_b = 0;
                    main_unit[idx*2].zero_m_s_b = 0;
                    main_unit[idx*2].swap = polarity;
                    main_unit[idx*2+1].zero_l_s_b = 0;
                    main_unit[idx*2+1].zero_m_s_b = 0;
                    main_unit[idx*2+1].swap = polarity;
                } else {
                    main_unit[idx+64].zero_l_s_b = 0;
                    main_unit[idx+64].zero_m_s_b = 0;
                    if (reg->reg.size == 8)
                        polarity ^= 1;
                    main_unit[idx+64].swap = polarity; } } } }
}

void dump_field_dictionary(checked_array_base<fde_pov> &fde_control,
                           checked_array_base<fde_phv> &fde_data,
                           checked_array_base<ubits<8>> &pov_layout,
                           std::vector<Phv::Ref> &pov_order,
                           std::vector<std::pair<Deparser::RefOrChksum, Phv::Ref>> &dict)
{
    std::map<unsigned, unsigned>        pov;
    unsigned pov_byte = 0, pov_size = 0;
    for (auto &ent : pov_order)
        if (pov.count(ent->reg.index) == 0) {
            pov[ent->reg.index] = pov_size;
            pov_size += ent->reg.size;
            for (unsigned i = 0; i < ent->reg.size; i += 8) {
                if (pov_byte >= DEPARSER_MAX_POV_BYTES) {
                    error(ent.lineno, "Ran out of space in POV in deparser");
                    return; }
                pov_layout[pov_byte++] = ent->reg.index; } }
    for (auto &ent : dict)
        if (pov.count(ent.second->reg.index) == 0) {
            pov[ent.second->reg.index] = pov_size;
            pov_size += ent.second->reg.size;
            for (unsigned i = 0; i < ent.second->reg.size; i += 8) {
                if (pov_byte >= DEPARSER_MAX_POV_BYTES) {
                    error(ent.second.lineno, "Ran out of space in POV in deparser");
                    return; }
                pov_layout[pov_byte++] = ent.second->reg.index; } }
    while (pov_byte < DEPARSER_MAX_POV_BYTES)
        pov_layout[pov_byte++] = 0xff;

    int row = -1, prev_pov = -1;
    bool prev_is_checksum = false;
    unsigned pos = 0;
    for (auto &ent : dict) {
        unsigned size = ent.first->reg.size/8;
        int pov_bit = pov[ent.second->reg.index] + ent.second->lo;
        if (options.match_compiler) {
            if (ent.first->reg.index >= 224 && ent.first->reg.index < 236) {
                /* checksum unit -- make sure it gets its own dictionary line */
                prev_pov = -1;
                prev_is_checksum = true;
            } else {
                if (prev_is_checksum) prev_pov = -1;
                prev_is_checksum = false; } }
        while (size--) {
            if (pov_bit != prev_pov || pos >= 4 /*|| (pos & (size-1)) != 0*/) {
                if (row >= 0) {
                    fde_control[row].num_bytes = pos & 3;
                    fde_data[row].num_bytes = pos & 3; }
                if (row >= DEPARSER_MAX_FD_ENTRIES) {
                    error(ent.first.lineno, "Ran out of space in field dictionary");
                    return; }
                fde_control[++row].pov_sel = pov_bit;
                fde_control[row].version = 0xf;
                fde_control[row].valid = 1;
                pos = 0; }
            fde_data[row].phv[pos++] = ent.first->reg.index;
            prev_pov = pov_bit; } }
    if (pos) {
        fde_control[row].num_bytes = pos & 3;
        fde_data[row].num_bytes = pos & 3; }
}

void Deparser::output() {
    if (dictionary[INGRESS].empty() && dictionary[EGRESS].empty())
        return;
    inp_regs.icr.inp_cfg.disable();
    inp_regs.icr.inp_int_stat.disable();
    inp_regs.icr.inp_int_inj.disable();
    inp_regs.icr.inp_int_en0.disable();
    inp_regs.icr.inp_int_en1.disable();
    hdr_regs.hem.he_edf_cfg.disable();
    hdr_regs.him.hi_edf_cfg.disable();
    dump_checksum_units(inp_regs.iim.ii_phv_csum.csum_cfg, hdr_regs.him.hi_tphv_csum.csum_cfg,
                        checksum[INGRESS]);
    dump_checksum_units(inp_regs.iem.ie_phv_csum.csum_cfg, hdr_regs.hem.he_tphv_csum.csum_cfg,
                        checksum[EGRESS]);
    dump_field_dictionary(inp_regs.iim.ii_fde_pov.fde_pov, hdr_regs.him.hi_fde_phv.fde_phv,
        inp_regs.iir.main_i.pov.phvs, pov_order[INGRESS], dictionary[INGRESS]);
    dump_field_dictionary(inp_regs.iem.ie_fde_pov.fde_pov, hdr_regs.hem.he_fde_phv.fde_phv,
        inp_regs.ier.main_e.pov.phvs, pov_order[EGRESS], dictionary[EGRESS]);

    if (options.match_compiler) {
        phv_use[INGRESS] |= Phv::use(INGRESS);
        phv_use[EGRESS] |= Phv::use(EGRESS);
        if (phv_use[INGRESS].intersects(phv_use[EGRESS]))
            error(lineno[INGRESS], "Registers used in both ingress and egress in phv: %s",
                  Phv::db_regset(phv_use[INGRESS] & phv_use[EGRESS]).c_str()); }
    for (unsigned i = 0; i < 7; i++) {
        /* FIXME -- should use the registers used by ingress here, but to match compiler
         * FIXME -- output we instead use registers not used by egress */
        inp_regs.iir.ingr.phv.in_ingress_thread[i] =
            phv_use[EGRESS].getrange(i*32, 32) ^ 0xffffffff;
        inp_regs.ier.egr.phv.in_egress_thread[i] = phv_use[EGRESS].getrange(i*32, 32); }
    for (unsigned i = 0; i < 8; i++) {
        if (phv_use[EGRESS].intersects(Phv::tagalong_groups[i])) {
            inp_regs.icr.tphv_cfg.i_e_assign |= 1 << i;
            if (phv_use[INGRESS].intersects(Phv::tagalong_groups[i])) {
                error(lineno[INGRESS], "tagalong group %d used in both ingress and "
                      "egress deparser", i); } } }

    for (auto &intrin : intrinsics)
        intrin.first->setregs(this, intrin.second);
    if (!hdr_regs.hir.ingr.ingress_port.sel.modified())
        hdr_regs.hir.ingr.ingress_port.sel = 1;

    if (learn.select) {
        inp_regs.iir.ingr.learn_cfg.phv = learn.select->reg.index;
        inp_regs.iir.ingr.learn_cfg.valid = 1;
        for (auto &set : learn.layout) {
            int idx = 0;
            for (auto &reg : set.second)
                for (int i = reg->reg.size/8; i > 0; i--)
                    inp_regs.iir.ingr.learn_tbl[set.first].phvs[idx++] = reg->reg.index;
            inp_regs.iir.ingr.learn_tbl[set.first].valid = 1;
            inp_regs.iir.ingr.learn_tbl[set.first].len = idx; } }

    inp_regs.emit_json(*open_output("regs.all.deparser.input_phase.cfg.json"));
    hdr_regs.emit_json(*open_output("regs.all.deparser.header_phase.cfg.json"));
}

bool Deparser::RefOrChksum::check() const {
    if (name_ == "checksum") {
        if (lo != hi || lo < 0 || lo >= DEPARSER_CHECKSUM_UNITS) {
            error(lineno, "Invalid checksum unit number");
            return false; }
        return true; }
    return Phv::Ref::check();
}

Phv::Register Deparser::RefOrChksum::checksum_units[12] = {
    { 224, 16 }, { 225, 16 }, { 226, 16 }, { 227, 16 }, { 228, 16 }, { 229, 16 },
    { 230, 16 }, { 231, 16 }, { 232, 16 }, { 233, 16 }, { 234, 16 }, { 235, 16 } };

Phv::Slice Deparser::RefOrChksum::operator *() const {
    if (name_ == "checksum") {
        if (lo != hi || lo < 0 || lo >= DEPARSER_CHECKSUM_UNITS) {
            error(lineno, "Invalid checksum unit number");
            return Phv::Slice(); }
        return Phv::Slice(checksum_units[gress*DEPARSER_CHECKSUM_UNITS+lo], 0, 15); }
    return Phv::Ref::operator*();
}
