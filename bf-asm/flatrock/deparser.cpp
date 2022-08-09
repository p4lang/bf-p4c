/* deparser template specializations for flatrock -- #included directly in top-level deparser.cpp */

#include "ubits.h"

#define YES(X)  X
#define NO(X)

#define FLATROCK_SIMPLE_INTRINSIC(GRESS, VAL, REG, REGNAME, IFSHIFT) \
    REG.phv_n_##REGNAME = VAL.val->reg.deparser_id();                \
    IFSHIFT(REG.REGNAME##_shft = intrin.vals[0].val->lo;)

#define FLATROCK_BYTE_PAIR_INTRINSIC(GRESS, VAL, REG, REGNAME, IFSHIFT) \
    /* FIXME: what are the two deparser IDs? */                         \
    REG.phv_n_b0_##REGNAME = VAL.val->reg.deparser_id();                \
    REG.phv_n_b1_##REGNAME = VAL.val->reg.deparser_id();                \
    IFSHIFT(REG.REGNAME##_shft = intrin.vals[0].val->lo;)

#define MDP_INTRINSIC(NAME, R1, IFSHIFT)                                      \
    DEPARSER_INTRINSIC(Flatrock, INGRESS, NAME, 1) {                                          \
        FLATROCK_SIMPLE_INTRINSIC(INGRESS, intrin.vals[0], regs.mdp_mem.R1, NAME, IFSHIFT) \
    }

#define MDP_INTRINSIC_BP(NAME, R1, IFSHIFT)                                      \
    DEPARSER_INTRINSIC(Flatrock, INGRESS, NAME, 1) {                                          \
        FLATROCK_BYTE_PAIR_INTRINSIC(INGRESS, intrin.vals[0], regs.mdp_mem.R1, NAME, IFSHIFT) \
    }

#define MDP_INTRINSIC_RENAME(NAME, R1, REGNAME, IFSHIFT)                                      \
    DEPARSER_INTRINSIC(Flatrock, INGRESS, NAME, 1) {                                          \
        FLATROCK_SIMPLE_INTRINSIC(INGRESS, intrin.vals[0], regs.mdp_mem.R1, REGNAME, IFSHIFT) \
    }

#define MDP_INTRINSIC_BP_RENAME(NAME, R1, REGNAME, IFSHIFT)                                      \
    DEPARSER_INTRINSIC(Flatrock, INGRESS, NAME, 1) {                                          \
        FLATROCK_BYTE_PAIR_INTRINSIC(INGRESS, intrin.vals[0], regs.mdp_mem.R1, REGNAME, IFSHIFT) \
    }

#define DPR_INTRINSIC_RENAME(NAME, R1, REGNAME, IFSHIFT)                                       \
    DEPARSER_INTRINSIC(Flatrock, EGRESS, NAME, 1) {                                            \
        FLATROCK_SIMPLE_INTRINSIC(EGRESS, intrin.vals[0], regs.dprsr.R1, REGNAME, IFSHIFT) \
    }

// minimal intrinsics for now
// only supporting instance 0 for now
MDP_INTRINSIC_RENAME(meter_color, tmm_ext_ram.tmm_ext[0], color, YES)
MDP_INTRINSIC(icos, tmm_ext_ram.tmm_ext[0], YES)
MDP_INTRINSIC_RENAME(copy_to_cpu_cos, tmm_ext_ram.tmm_ext[0], c2c_cos, YES)
// TODO: c2c_qid
MDP_INTRINSIC_RENAME(mirr_icos, tmm_ext_ram.tmm_ext[0], mrr_cos, YES)
MDP_INTRINSIC_RENAME(egress_unicast_pipe, tmm_ext_ram.tmm_ext[0], epipe_id, YES)
MDP_INTRINSIC_RENAME(egress_unicast_port, tmm_ext_ram.tmm_ext[0], epipe_port, YES)
MDP_INTRINSIC_RENAME(qid, tmm_ext_ram.tmm_ext[0], eport_qid, YES)
// TODO: epipe_id -- split from egress_unicast_port?
// TODO: b0_mrr_bmp
// TODO: b1_mrr_bmp
MDP_INTRINSIC_BP_RENAME(egress_multicast_group_0, tmm_ext_ram.tmm_ext[0], mcid1, YES)
MDP_INTRINSIC_BP_RENAME(egress_multicast_group_1, tmm_ext_ram.tmm_ext[0], mcid2, YES)
MDP_INTRINSIC_BP(rid, tmm_ext_ram.tmm_ext[0], YES)
MDP_INTRINSIC_BP(yid, tmm_ext_ram.tmm_ext[0], YES)
MDP_INTRINSIC_BP(xid, tmm_ext_ram.tmm_ext[0], YES)
MDP_INTRINSIC_BP_RENAME(hash_lag_ecmp_mcast_0, tmm_ext_ram.tmm_ext[0], hash1, YES)
MDP_INTRINSIC_BP_RENAME(hash_lag_ecmp_mcast_1, tmm_ext_ram.tmm_ext[0], hash2, YES)
// TODO: b0_pkt_len
// TODO: b1_pkt_len

DEPARSER_INTRINSIC(Flatrock, INGRESS, valid_vec, 2) {
    // FIXME: b0_sel/b1_sel should be from the extracted POV
    // Works with either 1 x 16b container or 2 x 8b containers
    regs.mdp.vld_vec_ext.b1_sel = intrin.vals.front().val->reg.deparser_id();
    regs.mdp.vld_vec_ext.b0_sel = intrin.vals.back().val->reg.deparser_id();
    regs.mdp.vld_vec_ext.shift_amt = intrin.vals.back().val->lo;
}

// FIXME: egress_unicast_port should be removed from EGRESS
DEPARSER_INTRINSIC(Flatrock, EGRESS, egress_unicast_port, 1) { }


#undef FLATROCK_BYTE_PAIR_INTRINSIC
#undef FLATROCK_SIMPLE_INTRINSIC
#undef MDP_INTRINSIC
#undef MDP_INTRINSIC_BP
#undef MDP_INTRINSIC_RENAME
#undef MDP_INTRINSIC_BP_RENAME
#undef DPR_INTRINSIC_RENAME

template<> unsigned Deparser::FDEntry::Checksum::encode<Target::Flatrock>() {
    error(-1, "%s:%d: Flatrock deparser not implemented yet!", __FILE__, __LINE__);
    return 0;
}

template<> unsigned Deparser::FDEntry::Constant::encode<Target::Flatrock>() {
    error(lineno, "%s:%d: Flatrock deparser not implemented yet!", __FILE__, __LINE__);
    return 0;
}

struct ftr_str_info_t {
    int                                 len;
    unsigned                            use;
    checked_array_base<ubits<1>>        &en;
    checked_array_base<ubits<2>>        &sel;
};


typedef std::map<const Phv::Register *, unsigned> pov_map_t;

template <class REG, class ITER>
void fill_string(int idx, int seq, ITER begin, ITER end, const pov_map_t &pov_map, REG &reg,
                 unsigned int bytes) {
    unsigned i = 0;
    reg.sel[idx].seq = seq;
    // FIXME: Change to actual header_id of the string, for now sets 0xfe (payload) because it's
    // always valid.
    reg.sel[idx].hdr = 0xfe;
    reg.sel[idx].str_len_type = 0;
    reg.sel[idx].str_len = bytes;
    for (auto &pov : begin->pov)
        reg.sel[idx].pov_sel[i++] = pov_map.at(&pov->reg) + pov->lo;
    i = 0;
    for (auto it = begin; it != end; ++it) {
        for (int j = it->what->size() - 1; j >= 0; --j) {
            reg.el_type[idx].el_type[i] = 1;  // PHV only for now
            BUG_CHECK(it->what->template is<Deparser::FDEntry::Phv>(), "not PHV");
            reg.el_value[idx].value[i] = it->what->encode() + j;
            ++i; } }
}

template<> void Deparser::write_config(Target::Flatrock::deparser_regs &regs) {
    // NOTE: Some of the sections listed below may be programmed via intrinsics (see above)

    // Ingress "deparser" -- metadata packer
    // -------------------------------------
    //
    // See: https://wiki.ith.intel.com/pages/viewpage.action?pageId=1767709001

    // POV extraction
    auto &mdp_pov_ext = regs.mdp.pov_ext;
    unsigned i = 0;
    pov_map_t i_pov_map;
    ubits<8>* mdp_pov_ext_bytes[16] = {
        &mdp_pov_ext.b0_src_iphv_num,
        &mdp_pov_ext.b1_src_iphv_num,
        &mdp_pov_ext.b2_src_iphv_num,
        &mdp_pov_ext.b3_src_iphv_num,
        &mdp_pov_ext.b4_src_iphv_num,
        &mdp_pov_ext.b5_src_iphv_num,
        &mdp_pov_ext.b6_src_iphv_num,
        &mdp_pov_ext.b7_src_iphv_num,
        &mdp_pov_ext.b8_src_iphv_num,
        &mdp_pov_ext.b9_src_iphv_num,
        &mdp_pov_ext.b10_src_iphv_num,
        &mdp_pov_ext.b11_src_iphv_num,
        &mdp_pov_ext.b12_src_iphv_num,
        &mdp_pov_ext.b13_src_iphv_num,
        &mdp_pov_ext.b14_src_iphv_num,
        &mdp_pov_ext.b15_src_iphv_num,
    };
    for (auto &ent : pov_order[INGRESS]) {
        i_pov_map.emplace(&ent->reg, i*8);
        for (unsigned j = 0; j < ent->reg.size/8; ++j) {
            *mdp_pov_ext_bytes[i++] = ent->reg.deparser_id() + j; }
    }

    // Valid vector
    // TODO: regs.mdp.vld_vec_ext

    // Default select vector
    // TODO: regs.mdp.dflt_vec_ext

    // Bridge metadata
    // TODO: regs.mdp.brm_ext
    // TODO: regs.mdp.br_meta_cfg_tcam
    // TODO: regs.mdp_mem.rem_brm_ext_ram
    // Match on entry 0 always
    // Ensure that bridged metadata never overwrites header pointers:
    //   - Byte 0: 0 (start hdr offset)
    //   - Byte 1: 0xFF (not compressed)
    //   - Byte 2-11: header ids
    //   - Byte 12-21: compressed header lengths (if using -- not in use yet)
    regs.mdp.br_meta_cfg_tcam.tcam[0].key_wh = 0xFFFFFFFFUL;
    regs.mdp.br_meta_cfg_tcam.tcam[0].key_wl = 0xFFFFFFFFUL;
    regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[0].rem_brm_start = 1 + 1 + 10;

    // TM metadata
    // TODO: regs.mdp.tmm_ext
    // TODO: regs.mdp.tm_meta_cfg_tcam
    // TODO: regs.mdp.default_tm_meta*
    // TODO: regs.mdp_mem.tmm_ext_ram
    // Match on entry 0 always
    regs.mdp.tm_meta_cfg_tcam.tcam[0].key_wh = 0xFFFFFFFFUL;
    regs.mdp.tm_meta_cfg_tcam.tcam[0].key_wl = 0xFFFFFFFFUL;

    // Learn quanta
    // TODO: regs.mdp.lq_ext
    // TODO: regs.mdp.lq_cfg_tcam
    // TODO: regs.mdp_mem.lq_ext_ram

    // IAFC - ingress advanced flow control
    // TODO: regs.mdp.iafc_ext
    // TODO: regs.mdp.iafc_ext_ram

    // Packet gen
    // TODO: regs.mdp.pgen_ext
    // TODO: regs.mdp.pgen_cfg_tcam
    // TODO: regs.mdp_mem.pgen_ext_ram

    // Header ID table
    // Program Header ID compression TCAM with the 255 chosen sequences
    auto &hdr_id_tcam = regs.mdp_mem.hdr_id_compr_tcam;

    // Header ID compression RAM should always program each entry with its index
    // FIXME: only program as many entries as we have in the TCAM
    // FIXME: this register is now gone?
    // auto &hdr_id_ram = regs.mdp.hdr_id_compr_ram;
    // for (int i = 0; i < Target::Flatrock::MDP_HDR_ID_COMP_ROWS; i++)
    //    hdr_id_ram.compr_hdr_id[i] = i;

    // Header len compression
    // TODO: regs.mdp.hdr_len_comr_tab (asked to rename to hdr_len_compr_tab)


    // Egress deparser
    // ---------------
    //
    // See: https://wiki.ith.intel.com/display/ITS51T/Deparser

    // Crossbar config
    auto &phvxb = regs.dprsr.dprsr_phvxb_rspec;

    // POV extraction
    i = 0;
    pov_map_t e_pov_map;
    for (auto &ent : pov_order[EGRESS]) {
        e_pov_map.emplace(&ent->reg, i*8);
        for (unsigned j = 0; j < ent->reg.size/8; ++j) {
            phvxb.phe2pov[i/4].phe_byte[i%4] = ent->reg.deparser_id() + j;
            ++i; } }

    // Content memory
    // TODO: regs.dprsr.dprsr_phvxb_rspec.cm
    // TODO: regs.dprsr_mem.cm

    // Checksum configuration
    // TODO: regs.dprsr.dprsr_phvxb_rspec.csm_phe_xb
    // TODO: regs.dprsr.dprsr_phvxb_rspec.final_csum_cfg
    // TODO: regs.dprsr.dprsr_ipkt_rspec.*
    // TODO: regs.dprsr.dprsr_output_rspec.*

    // Advanced flow control (AFC)
    // TODO: regs.dprsr.dprsr_phvxb_rspec.afc_xb

    // Egress MAC metadata
    // TODO: regs.dprsr.dprsr_phvxb_rspec.md_xb
    regs.dprsr.dprsr_phvxb_rspec.md_xb.key[0].key_wh = 0xFFFFFFFFUL;
    regs.dprsr.dprsr_phvxb_rspec.md_xb.key[0].key_wl = 0xFFFFFFFFUL;

    // Egress header mirror (EHM)
    // TODO: regs.dprsr.dprsr_phvxb_rspec.ehm_xb

    // String configuration
    // TODO: regs.dprsr.dprsr_phvxb_rspec.str*
    // TODO: regs.dprsr.dprsr_phvxb_rspec.lp_str
    // TODO: regs.dprsr.dprsr_sd_rspec.*
    ftr_str_info_t info[3] = {
        // FIXME the chip supports 16 different configs for the strings, selected by a tcam
        // match.  We just always program config 0 here
        { 8, 0, phvxb.str8.str8_cfg[0].en, phvxb.str8.str8_cfg[0].sel },
        { 16, 0, phvxb.str16.str16_cfg[0].en, phvxb.str16.str16_cfg[0].sel },
        { 32, 0, phvxb.str32.str32_cfg[0].en, phvxb.str32.str32_cfg[0].sel },
    };

    // FIXME: Select the desired config, for now always config 0.
    phvxb.str8.key[0].key_wh = 0xFFFFFFFFUL;
    phvxb.str8.key[0].key_wl = 0xFFFFFFFFUL;

    phvxb.str16.key[0].key_wh = 0xFFFFFFFFUL;
    phvxb.str16.key[0].key_wl = 0xFFFFFFFFUL;

    phvxb.str32.key[0].key_wh = 0xFFFFFFFFUL;
    phvxb.str32.key[0].key_wl = 0xFFFFFFFFUL;

    auto next = dictionary[EGRESS].begin();
    unsigned max_bytes = 32;
    int seq = 0;
    auto &strings = regs.dprsr.dprsr_sd_rspec;
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
        case 8: fill_string(i->use*4, seq, it, next, e_pov_map, strings.str8, bytes); break;
        case 16: fill_string(i->use*4, seq, it, next, e_pov_map, strings.str16, bytes); break;
        case 32: fill_string(i->use*4, seq, it, next, e_pov_map, strings.str32, bytes); break;
        default: BUG("bad size"); }
        ++seq;
        ++i->use;
        while (i->use == i->en.size()) {
            if (i->len != max_bytes) break;
            BUG_CHECK(i != std::begin(info), "ran out of strings?");
            max_bytes = (--i)->len; }
    }

    // Configure payload byte offset
    // FIXME: currently only entry 0
    phvxb.pbo_cfg.key[0].key_wh = 0xFFFFFFFF;
    phvxb.pbo_cfg.key[0].key_wl = 0xFFFFFFFF;
    phvxb.pbo_cfg.data[0].hdr = pbo[EGRESS].hdr;
    phvxb.pbo_cfg.data[0].offset = pbo[EGRESS].offset;
    phvxb.pbo_cfg.data[0].var_start = pbo[EGRESS].var_start;
    phvxb.pbo_cfg.data[0].var_len = pbo[EGRESS].var_len;

    for (auto &intrin : intrinsics)
        intrin.type->setregs(regs, *this, intrin);

    if (!intrinsics.empty())
        warning(intrinsics.front().lineno, "Flatrock intrinsics not fully implemented yet!");
    if (!digests.empty())
        error(digests.front().lineno, "Flatrock digests not implemented yet!");

    // Verify that TopLevel::regs<>() is non-null before attempting to set.
    // Will sometimes be nullptr when running in a gtest context
    if (TopLevel::regs<Target::Flatrock>()) {
        TopLevel::regs<Target::Flatrock>()->mem_pipe.mdp_mem.set("mem.mdp_mem", &regs.mdp_mem);
        TopLevel::regs<Target::Flatrock>()->reg_pipe.mdp.set("regs.mdp", &regs.mdp);
        TopLevel::regs<Target::Flatrock>()->reg_pipe.dprsr.set("regs.dprsr", &regs.dprsr);
        TopLevel::regs<Target::Flatrock>()->mem_pipe.dprsr_mem.set("mem.dprsr_mem",
                                                                   &regs.dprsr_mem);
    }
}

template<> void Deparser::gen_learn_quanta(Target::Flatrock::deparser_regs&,
                                           json::vector &) {
}
