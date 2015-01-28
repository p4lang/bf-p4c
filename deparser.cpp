#include "deparser.h"
#include "phv.h"
#include "range.h"
#include <fstream>

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
        for (auto &kv : MapIterChecked(data.map)) {
            if (kv.key == "dictionary") {
                if (!CHECKTYPE(kv.value, tMAP)) continue;
                for (auto &ent : kv.value.map)
                    dictionary[gress].emplace_back(Phv::Ref(gress, ent.key),
                                                   Phv::Ref(gress, ent.value));
            } else if (kv.key == "pov") {
                if (!CHECKTYPE(kv.value, tVEC)) continue;
                for (auto &ent : kv.value.vec)
                    pov_order[gress].emplace_back(gress, ent);
            } else if (kv.key == "egress_unicast_port") {
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
                    error(ent.second.lineno, "POV bits shoudl be single bits"); } } }
    if (phv_use[INGRESS].intersects(phv_use[EGRESS]))
        error(lineno[INGRESS], "Registers used in both ingress and egress in deparser");
    else {
        phv_use[INGRESS] |= Phv::use(INGRESS);
        phv_use[EGRESS] |= Phv::use(EGRESS);
        if (phv_use[INGRESS].intersects(phv_use[EGRESS]))
            error(lineno[INGRESS], "Registers used in both ingress and egress in phv"); }
}

void dump_field_dictionary(checked_array_base<fde_pov> &fde_control,
                           checked_array_base<fde_phv> &fde_data,
                           checked_array_base<ubits<8>> &pov_layout,
                           std::vector<Phv::Ref> &pov_order,
                           std::vector<std::pair<Phv::Ref, Phv::Ref>> &dict)
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
    unsigned pos = 0;
    for (auto &ent : dict) {
        unsigned size = ent.first->reg.size/8;
        int pov_bit = pov[ent.second->reg.index] + ent.second->lo;
        if (pov_bit != prev_pov || pos >= 4 || (pos & (size-1)) != 0) {
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
        while (size--)
            fde_data[row].phv[pos++] = ent.first->reg.index;
        prev_pov = pov_bit; }
    if (pos) {
        fde_control[row].num_bytes = pos & 3;
        fde_data[row].num_bytes = pos & 3; }
}

void Deparser::output() {
    inp_regs.icr.inp_cfg.disable();
    inp_regs.icr.inp_int_stat.disable();
    inp_regs.icr.inp_int_inj.disable();
    inp_regs.icr.inp_int_en0.disable();
    inp_regs.icr.inp_int_en1.disable();
    hdr_regs.hem.he_edf_cfg.disable();
    hdr_regs.him.hi_edf_cfg.disable();
    hdr_regs.him.hi_pv_table.disable();
    /* TODO -- checksum units */
    dump_field_dictionary(inp_regs.iim.ii_fde_pov.fde_pov, hdr_regs.him.hi_fde_phv.fde_phv,
        inp_regs.iir.main_i.pov.phvs, pov_order[INGRESS], dictionary[INGRESS]);
    dump_field_dictionary(inp_regs.iem.ie_fde_pov.fde_pov, hdr_regs.hem.he_fde_phv.fde_phv,
        inp_regs.ier.main_e.pov.phvs, pov_order[EGRESS], dictionary[EGRESS]);

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

    std::ofstream reg_inp("regs.all.deparser.input_phase.cfg.json");
    inp_regs.emit_json(reg_inp);
    std::ofstream reg_hdr("regs.all.deparser.header_phase.cfg.json");
    hdr_regs.emit_json(reg_hdr);
}
