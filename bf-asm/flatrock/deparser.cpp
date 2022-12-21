/* deparser template specializations for flatrock -- #included directly in top-level deparser.cpp */

#include "flatrock/deparser.h"
#include "ubits.h"

#define YES(X)  X
#define NO(X)

#define FLATROCK_SIMPLE_INTRINSIC(GRESS, VAL, REG, REGNAME, IFSHIFT) \
    REG.phv_n_##REGNAME = VAL.val->reg.deparser_id();                \
    IFSHIFT(REG.REGNAME##_shft = VAL.val->lo;)

#define FLATROCK_BYTE_PAIR_INTRINSIC(GRESS, VAL, REG, REGNAME, IFSHIFT) \
    /* FIXME: what are the two deparser IDs? */                         \
    REG.phv_n_b0_##REGNAME = VAL.val->reg.deparser_id();                \
    REG.phv_n_b1_##REGNAME = VAL.val->reg.deparser_id() + 1;            \
    IFSHIFT(REG.REGNAME##_shft = intrin.vals[0].val->lo;)

#define MDP_INTRINSIC(NAME, R1, IFSHIFT)                                                   \
    DEPARSER_INTRINSIC(Flatrock, INGRESS, NAME, 1) {                                       \
        FLATROCK_SIMPLE_INTRINSIC(INGRESS, intrin.vals[0], regs.mdp_mem.R1, NAME, IFSHIFT) \
    }

#define MDP_INTRINSIC_BP(NAME, R1, IFSHIFT)                                                   \
    DEPARSER_INTRINSIC(Flatrock, INGRESS, NAME, 1) {                                          \
        FLATROCK_BYTE_PAIR_INTRINSIC(INGRESS, intrin.vals[0], regs.mdp_mem.R1, NAME, IFSHIFT) \
    }

#define MDP_INTRINSIC_RENAME(NAME, R1, REGNAME, IFSHIFT)                                      \
    DEPARSER_INTRINSIC(Flatrock, INGRESS, NAME, 1) {                                          \
        FLATROCK_SIMPLE_INTRINSIC(INGRESS, intrin.vals[0], regs.mdp_mem.R1, REGNAME, IFSHIFT) \
    }

#define MDP_INTRINSIC_BP_RENAME(NAME, R1, REGNAME, IFSHIFT)                                      \
    DEPARSER_INTRINSIC(Flatrock, INGRESS, NAME, 1) {                                             \
        FLATROCK_BYTE_PAIR_INTRINSIC(INGRESS, intrin.vals[0], regs.mdp_mem.R1, REGNAME, IFSHIFT) \
    }

#define DPR_INTRINSIC_RENAME(NAME, R1, REGNAME, IFSHIFT)                                   \
    DEPARSER_INTRINSIC(Flatrock, EGRESS, NAME, 1) {                                        \
        FLATROCK_SIMPLE_INTRINSIC(EGRESS, intrin.vals[0], regs.dprsr.R1, REGNAME, IFSHIFT) \
    }

#define DPR_INTRINSIC_TBL_RENAME(NAME, R1, REGNAME, CNT, IFSHIFT)                    \
    DEPARSER_INTRINSIC(Flatrock, EGRESS, NAME, 1) {                                  \
        for (int i = 0; i < CNT; i++) {                                              \
            regs.dprsr.R1[i].REGNAME##_phes = intrin.vals[0].val->reg.deparser_id(); \
            regs.dprsr.R1[i].REGNAME##_sel = 1;                                      \
            regs.dprsr.R1[i].REGNAME##_dflt = 0;                                     \
            IFSHIFT(regs.dprsr.R1[i].REGNAME##_shft = intrin.vals[0].val->lo;)       \
        }                                                                            \
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
MDP_INTRINSIC_BP_RENAME(mirror_bitmap, tmm_ext_ram.tmm_ext[0], mrr_bmp, YES)
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
    // Works with either 1 x 16b/32b container or 2 x 8b containers
    const auto* reg_b0 = &intrin.vals.back().val->reg;
    const auto* reg_b1 = &intrin.vals.front().val->reg;

    BUG_CHECK(deparser.pov[INGRESS].count(reg_b0), "Cannot find register %s in POV map",
              reg_b0->name);
    BUG_CHECK(deparser.pov[INGRESS].count(reg_b1), "Cannot find register %s in POV map",
              reg_b1->name);

    // POV bytes: lo = reg_b0 + number of bytes offset in val->lo
    //            hi = reg_b0 == reg_b1 ? lo + 1 : reg_b1
    regs.mdp.vld_vec_ext.b0_sel =
        deparser.pov[INGRESS].at(reg_b0) / 8 + intrin.vals.back().val->lo / 8;
    regs.mdp.vld_vec_ext.b1_sel = deparser.pov[INGRESS].at(reg_b1) / 8 +
                                  (reg_b0 == reg_b1 ? 1 + intrin.vals.back().val->lo / 8 : 0);
    regs.mdp.vld_vec_ext.shift_amt = intrin.vals.back().val->lo % 8;
}

DPR_INTRINSIC_TBL_RENAME(mirr_io_sel, dprsr_phvxb_rspec.ehm_xb.mirr_cfg, mirr_src, 8, YES)

// FIXME: egress_unicast_port should be removed from EGRESS
DEPARSER_INTRINSIC(Flatrock, EGRESS, egress_unicast_port, 1) { }


#undef FLATROCK_BYTE_PAIR_INTRINSIC
#undef FLATROCK_SIMPLE_INTRINSIC
#undef MDP_INTRINSIC
#undef MDP_INTRINSIC_BP
#undef MDP_INTRINSIC_RENAME
#undef MDP_INTRINSIC_BP_RENAME
#undef DPR_INTRINSIC_RENAME
#undef DPR_INTRINSIC_TBL_RENAME

// Configure the mirror digest
DEPARSER_DIGEST(Flatrock, EGRESS, mirror, 8, can_shift = true;) {
    auto &ehm_xb = regs.dprsr.dprsr_phvxb_rspec.ehm_xb;

    const auto* reg_sel = &data.select.val->reg;
    int reg_sel_shift = data.select.val->lo;

    const auto* reg_en = &data.select.pov.front()->reg;
    int reg_en_shift = data.select.pov.front()->lo;

    BUG_CHECK(deparser.pov[EGRESS].count(reg_sel), "Cannot find register %s in POV map",
              reg_sel->name);
    BUG_CHECK(deparser.pov[EGRESS].count(reg_en), "Cannot find register %s in POV map",
              reg_en->name);

    int en_pov_bit = deparser.pov[EGRESS].at(reg_en) + reg_en_shift;

    // Configure the select expression extraction
    ehm_xb.pov_key_sel.pov_byte[0] = deparser.pov[EGRESS].at(reg_sel) / 8;

    int idx = 0;
    for (auto &set : data.layout) {
        int id = set.first >> data.shift;
        unsigned key_wl = ~(0xfu << reg_sel_shift) | (unsigned)(id << reg_sel_shift);
        unsigned key_wh = (0xfu << reg_sel_shift) ^ key_wl;
        ehm_xb.key[idx].key_wh = key_wh;
        ehm_xb.key[idx].key_wl = key_wl;

        ehm_xb.mirr_cfg[idx].mirr_en_phes = data.select.pov.front()->reg.deparser_id();
        ehm_xb.mirr_cfg[idx].mirr_en_sel = 1;
        ehm_xb.mirr_cfg[idx].mirr_en_dflt = 0;
        ehm_xb.mirr_cfg[idx].mirr_en_shft = data.select.pov.front()->lo;

        // FIXME: set the payload length appropriately
        // ehm_xb.pld_len_cfg[idx].ehm_pld_len_phes = 0;
        ehm_xb.pld_len_cfg[idx].ehm_pld_len_pov0 = en_pov_bit;
        ehm_xb.pld_len_cfg[idx].ehm_pld_len_pov1 = en_pov_bit;
        ehm_xb.pld_len_cfg[idx].ehm_pld_len_sel = 0;
        ehm_xb.pld_len_cfg[idx].ehm_pld_len_dflt = 256;

        const auto &phes = set.second;
        if (phes.size()) {
            // ehm_xb.mirr_cfg[idx].mirr_ehm_phes = 0;
            ehm_xb.mirr_cfg[idx].mirr_ehm_sel = 0;
            ehm_xb.mirr_cfg[idx].mirr_ehm_dflt = 1;
            // ehm_xb.mirr_cfg[idx].mirr_ehm_shft = 0;

            // ehm_xb.hdr_len_cfg[idx].ehm_hdr_len_phes = 0;
            ehm_xb.hdr_len_cfg[idx].ehm_hdr_len_pov0 = en_pov_bit;
            ehm_xb.hdr_len_cfg[idx].ehm_hdr_len_pov1 = en_pov_bit;
            ehm_xb.hdr_len_cfg[idx].ehm_hdr_len_sel = 0;
            ehm_xb.hdr_len_cfg[idx].ehm_hdr_len_dflt = phes.size();

            for (int i = 0; i < phes.size(); ++i)
                ehm_xb.data[idx][i / 4].phe[i % 4] = phes[i]->reg.deparser_id();
        } else {
            // ehm_xb.mirr_cfg[idx].mirr_ehm_phes = 0;
            ehm_xb.mirr_cfg[idx].mirr_ehm_sel = 0;
            ehm_xb.mirr_cfg[idx].mirr_ehm_dflt = 0;
            // ehm_xb.mirr_cfg[idx].mirr_ehm_shft = 0;
        }

        idx++;
    }
}

template<> unsigned Deparser::FDEntry::Checksum::encode<Target::Flatrock>() {
    error(-1, "%s:%d: Flatrock deparser not implemented yet!", SRCFILE, __LINE__);
    return 0;
}

template<> unsigned Deparser::FDEntry::Constant::encode<Target::Flatrock>() {
    error(lineno, "%s:%d: Flatrock deparser not implemented yet!", SRCFILE, __LINE__);
    return 0;
}

struct ftr_str_info_t {
    int                                 len;
    unsigned                            use;
    checked_array_base<ubits<1>>        &en;
    checked_array_base<ubits<2>>        &sel;
};

// Register to POV byte index mappings
typedef ordered_map<const Phv::Register *, unsigned> pov_map_t;

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

/// @brief Flatrock-specific additions to the process method.
///
/// Populates the @p pov_order vector with Phv::Ref objects that represent the 128b POV
template<> void Deparser::process(Target::Flatrock*) {
    // Intrinsics/digests that must be extracted from the POV vector
    static std::set<Deparser::Intrinsic::Type *> povIntrinsics = {
        Deparser::Intrinsic::Type::all[Target::Flatrock::tag][INGRESS]["valid_vec"],
    };

    static std::set<Deparser::Digest::Type *> povDigests = {
        Deparser::Digest::Type::all[Target::Flatrock::tag][EGRESS]["mirror"],
    };

    // Perform the actual intrinsic/digest extraction
    for (auto &intrin : intrinsics) {
        if (povIntrinsics.count(intrin.type)) {
            for (auto &val : intrin.vals) pov_order[intrin.type->gress].push_back(val.val);
        }
    }

    for (auto &digest : digests) {
        if (povDigests.count(digest.type)) {
            pov_order[digest.type->gress].push_back(digest.select.val);
        }
    }
}

template<> void Deparser::write_config(Target::Flatrock::deparser_regs &regs) {
    // NOTE: Some of the sections listed below may be programmed via intrinsics (see above)

    // Ingress "deparser" -- metadata packer
    // -------------------------------------
    //
    // See: https://wiki.ith.intel.com/pages/viewpage.action?pageId=1767709001

    // POV extraction
    //
    // Ensure the MSB of the POVs is all zero as we need a zero-byte for some things
    auto &mdp_pov_ext = regs.mdp.pov_ext;
    ubits<8>* mdp_pov_ext_bytes[Target::Flatrock::POV_WIDTH] = {
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
    int idx = 0;
    for (auto &kv : pov[INGRESS]) {
        auto *reg = kv.first;
        idx = kv.second / 8;
        for (unsigned j = 0; j < reg->size / 8; ++j) {
            *mdp_pov_ext_bytes[idx++] = reg->deparser_id() + j;
        }
    }
    // Verify that we haven't written the _last_ entry (keep for zero byte)
    BUG_CHECK(idx <= Target::Flatrock::POV_WIDTH / 8 - 1, "Too many POV bytes being extracted");

    // populate unused bytes with the zero byte
    // TODO: consider pushing the zero-byte into the pov_order list in the Flatrock process method
    for ( ; idx < Target::Flatrock::POV_WIDTH / 8; ++idx)
        *mdp_pov_ext_bytes[idx] = zero_container[INGRESS]->reg.deparser_id();

    // Valid vector -- handled in valid_vec intrinsic above

    // Default select vector
    // Take everything from PHV -- point to a zero-POV byte for all 3 entries
    regs.mdp.dflt_vec_ext.b0_sel = 15;
    regs.mdp.dflt_vec_ext.b1_sel = 15;
    regs.mdp.dflt_vec_ext.b2_sel = 15;

    // Bridge metadata
    // TODO: regs.mdp.brm_ext
    // TODO: regs.mdp.br_meta_cfg_tcam
    // TODO: regs.mdp_mem.rem_brm_ext_ram
    // Match on entry 0 always
    // Ensure that bridged metadata never overwrites header pointers:
    //   - Byte 0: 0 (start hdr offset)
    //   - Byte 1: 0xFF (not compressed)
    //   - Byte 2-17: header ids
    //   - Byte 18-33: compressed header lengths (if using -- not in use yet)
    //     See https://wiki.ith.intel.com/pages/viewpage.action?
    //         pageId=1581874739#FrameProcessingPipeline(FPP)-POVFormat
    //   - Byte 48-55: POV flags
    //   - Byte 56-63: POV state
    regs.mdp.br_meta_cfg_tcam.tcam[0].key_wh = 0xFFFFFFFFUL;
    regs.mdp.br_meta_cfg_tcam.tcam[0].key_wl = 0xFFFFFFFFUL;

    int rem_brm_start = 1 + 1 + Target::Flatrock::PAC_HEADER_POINTERS_MAX;
    regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[0].rem_brm_start = rem_brm_start;

    auto &rem_brm_ext = regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[0];
    ubits<8>* rem_brm_ext_bytes[Target::Flatrock::PARSER_REMAINING_BRIDGE_MD_MAX_WIDTH] = {
#define RBE(i) &rem_brm_ext.b##i##_phv_sel
        RBE(0), RBE(1), RBE(2), RBE(3), RBE(4), RBE(5), RBE(6), RBE(7),
        RBE(8), RBE(9), RBE(10), RBE(11), RBE(12), RBE(13), RBE(14), RBE(15),
        RBE(16), RBE(17), RBE(18), RBE(19), RBE(20), RBE(21), RBE(22), RBE(23),
        RBE(24), RBE(25), RBE(26), RBE(27), RBE(28), RBE(29), RBE(30), RBE(31),
        RBE(32), RBE(33), RBE(34), RBE(35), RBE(36), RBE(37), RBE(38), RBE(39),
        RBE(40), RBE(41), RBE(42), RBE(43), RBE(44), RBE(45), RBE(46), RBE(47),
        RBE(48), RBE(49), RBE(50), RBE(51), RBE(52), RBE(53), RBE(54), RBE(55),
        RBE(56), RBE(57), RBE(58), RBE(59), RBE(60), RBE(61)
#undef RBE
    };

    // TODO Optimize to not place unused zero bytes?
    const int rem_brm_width = Target::Flatrock::PARSER_BRIDGE_MD_WIDTH - rem_brm_start;
    // This value needs to be in sync with the value of the pseudo parser > pov_flags_pos
    // and pov_state_pos registers. See ReplaceFlatrockParserIR::postorder(IR::BFN::Pipe *).
    const int rem_brm_pov_start = rem_brm_width - Target::Flatrock::POV_WIDTH / 8;
    for (int i = 0; i < Target::Flatrock::POV_WIDTH / 8; i++) {
        BUG_CHECK(!remaining_bridge_md.configs[0].bytes[rem_brm_pov_start + i],
            "overwriting remaining bridge metadata (byte %d) with POV byte (byte %d)",
            rem_brm_pov_start + i, i);
        *rem_brm_ext_bytes[rem_brm_pov_start + i] = *mdp_pov_ext_bytes[i];
    }

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

    remaining_bridge_md.write_config(regs);

    // Egress deparser
    // ---------------
    //
    // See: https://wiki.ith.intel.com/display/ITS51T/Deparser

    // Crossbar config
    auto &phvxb = regs.dprsr.dprsr_phvxb_rspec;

    // POV extraction
    for (auto &kv : pov[EGRESS]) {
        auto *reg = kv.first;
        int idx = kv.second / 8;
        for (unsigned j = 0; j < reg->size/8; ++j) {
            phvxb.phe2pov[idx / 4].phe_byte[idx % 4] = reg->deparser_id() + j;
            ++idx; } }


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
        case 8: fill_string(i->use*4, seq, it, next, pov[EGRESS], strings.str8, bytes); break;
        case 16: fill_string(i->use*4, seq, it, next, pov[EGRESS], strings.str16, bytes); break;
        case 32: fill_string(i->use*4, seq, it, next, pov[EGRESS], strings.str32, bytes); break;
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
    for (auto &digest : digests)
        digest.type->setregs(regs, *this, digest);

    if (!intrinsics.empty())
        warning(intrinsics.front().lineno, "Flatrock intrinsics not fully implemented yet!");
    if (!digests.empty())
        warning(digests.front().lineno, "Flatrock digests not fully implemented yet!");

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

void PacketBodyOffset::input(value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    for (auto &kv : MapIterChecked(data.map, true)) {
        if (kv.key == "hdr") {
            if (CHECKTYPE2(kv.value, tINT, tSTR)) {
                if (kv.value.type == tINT) {
                    check_range(kv.value, 0, Target::Flatrock::PARSER_HDR_ID_MAX);
                    hdr = kv.value.i;
                } else {
                    hdr = Hdr::id(data.lineno, kv.value.s);
                }
            }
        } else if (kv.key == "offset") {
            if (CHECKTYPE(kv.value, tINT)) {
                check_range(kv.value,
                            -Target::Flatrock::PARSER_BASE_LEN_MAX,
                            Target::Flatrock::PARSER_BASE_LEN_MAX);
                offset = kv.value.i;
            }
        } else if (kv.key == "var_off_pos") {
            if (CHECKTYPE(kv.value, tINT)) {
                check_range(kv.value, 0, Target::Flatrock::POV_WIDTH - 1);
                var_start = kv.value.i;
            }
        } else if (kv.key == "var_off_len") {
            if (CHECKTYPE(kv.value, tINT)) {
                check_range(kv.value, 0, Target::Flatrock::DEPARSER_PBO_VAR_OFFSET_LEN_WIDTH_MAX);
                var_len = kv.value.i;
            }
        } else {
            error(kv.key.lineno, "unknown item %s in packet_body_offset",
                    value_desc(kv.key));
        }
    }
}

static int phv_ref_to_phe_byte_number(const Phv::Ref &phv_ref) {
    return phv_ref->reg.deparser_id() + phv_ref.lobit() / 8;
}

void RemainingBridgeMetadataConfig::input_item(
        VECTOR(value_t) args, value_t data, int &bytes_index) {
    if (!CHECKTYPE3(data, tINT, tSTR, tCMD)) return;
    if (data.type == tINT) {
        if (!check_range(data, 0, 255 /* W15(24..31) byte number */)) return;
        bytes[bytes_index++] = data.i;
    } else if (data.type == tSTR) {
        Phv::Ref ref(INGRESS, DEPARSER_STAGE, data);
        auto phe_byte_number = phv_ref_to_phe_byte_number(ref);
        auto size = ref->reg.size / 8;
        for (int i_slice = phe_byte_number; i_slice < phe_byte_number + size; i_slice++)
            bytes[bytes_index++] = i_slice;
    } else if (data.type == tCMD) {
        Phv::Ref ref(INGRESS, DEPARSER_STAGE, data);
        auto phe_byte_number = phv_ref_to_phe_byte_number(ref);
        auto size = (ref.hibit() - ref.lobit() + 1) / 8;
        for (int i_slice = phe_byte_number; i_slice < phe_byte_number + size; i_slice++)
            bytes[bytes_index++] = i_slice;
    }
}

void RemainingBridgeMetadataConfig::input_bytes(
        VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE2(value, tVEC, tMAP)) return;
    if (value.type == tVEC) {
        value_t size = {.type = tINT, .lineno = value.lineno};
        size.i = value.vec.size;
        if (!check_range(size, 0, Target::Flatrock::PARSER_REMAINING_BRIDGE_MD_MAX_WIDTH)) return;
        int i_bytes = 0;
        for (int i_vec = 0; i_vec < value.vec.size; i_vec++)
            input_item(args, value.vec[i_vec], i_bytes);
    } else {
        // value.type == tMAP
        for (auto &kv : MapIterChecked(value.map, true)) {
            if (!CHECKTYPE(kv.key, tINT)) return;
            if (!check_range(kv.key, 0, Target::Flatrock::PARSER_REMAINING_BRIDGE_MD_MAX_WIDTH))
                return;
            int i_bytes = kv.key.i;
            input_item(args, kv.value, i_bytes);
        }
    }
}

void RemainingBridgeMetadataConfig::write_config(Target::Flatrock::deparser_regs &regs) {
    auto &tcam = regs.mdp.br_meta_cfg_tcam.tcam[*id];
    tcam.key_wh = match.word0;
    tcam.key_wl = match.word1;
    auto &rem_brm_ext = regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[*id];
    rem_brm_ext.rem_brm_start = start;
    ubits<8>* rem_brm_ext_bytes[Target::Flatrock::PARSER_REMAINING_BRIDGE_MD_MAX_WIDTH] = {
#define RBE(i) &rem_brm_ext.b##i##_phv_sel
        RBE(0), RBE(1), RBE(2), RBE(3), RBE(4), RBE(5), RBE(6), RBE(7),
        RBE(8), RBE(9), RBE(10), RBE(11), RBE(12), RBE(13), RBE(14), RBE(15),
        RBE(16), RBE(17), RBE(18), RBE(19), RBE(20), RBE(21), RBE(22), RBE(23),
        RBE(24), RBE(25), RBE(26), RBE(27), RBE(28), RBE(29), RBE(30), RBE(31),
        RBE(32), RBE(33), RBE(34), RBE(35), RBE(36), RBE(37), RBE(38), RBE(39),
        RBE(40), RBE(41), RBE(42), RBE(43), RBE(44), RBE(45), RBE(46), RBE(47),
        RBE(48), RBE(49), RBE(50), RBE(51), RBE(52), RBE(53), RBE(54), RBE(55),
        RBE(56), RBE(57), RBE(58), RBE(59), RBE(60), RBE(61)
#undef RBE
    };
    for (int i = 0; i < Target::Flatrock::PARSER_BRIDGE_MD_WIDTH - start; i++)
        if (bytes[i])
            *rem_brm_ext_bytes[i] = *bytes[i];
}

void RemainingBridgeMetadataConfig::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    auto match_present = false;
    auto start_present = false;

    for (auto &kv : MapIterChecked(data.map, false)) {
        if (kv.key == "match") {
            match_present = true;
            input_int_match(kv.value, match, Target::Flatrock::PARSER_POV_SELECT_NUM * 8);
        } else if (kv.key == "start") {
            start_present = true;
            check_range(kv.value, 0, Target::Flatrock::PPARSER_BRIDGE_MD_POV_OFFSET_MAX);
            start = kv.value.i;
        } else if (kv.key == "bytes") {
            input_bytes(args, kv.key, kv.value);
        } else {
            report_invalid_directive("invalid key", kv.key);
        }
    }

    if (!match_present) {
        error(data.lineno,
            "mandatory attribute `match' of `remanining_bridge_metadata' is missing");
    }
    if (!start_present) {
        error(data.lineno,
            "mandatory attribute `start' of `remanining_bridge_metadata' is missing");
    }
}

void RemainingBridgeMetadata::input_config(
        VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(key, tCMD)) return;
    if (key.vec.size < 2) error(key.lineno, "config ID missing");
    if (key.vec.size > 2) error(key.lineno, "too many parameters");
    if (!check_range(key[1], 0, Target::Flatrock::PARSER_BRIDGE_MD_CONFIGS - 1)) return;
    int id = key[1].i;
    configs[id].id = id;
    configs[id].input(args, value);
}

void RemainingBridgeMetadata::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    for (auto &kv : MapIterChecked(data.map, true)) {
        if (kv.key == "pov_select") {
            pov_select.input(kv.value);
        } else if (kv.key == "config") {
            input_config(args, kv.key, kv.value);
        } else {
            report_invalid_directive("invalid key", kv.key);
        }
    }
}

void RemainingBridgeMetadata::write_config(Target::Flatrock::deparser_regs &regs) {
    auto &brm_ext = regs.mdp.brm_ext;
    // TODO there are also regs.mdp.brm_ext.start_[0123] registers
    for (int i = 0; i < Target::Flatrock::PARSER_POV_SELECT_NUM; i++)
        if (pov_select.key[i].used)
            // TODO is this correct?
            brm_ext.start[i] = (pov_select.key[i].src << 3) | (pov_select.key[i].start & 7);
    for (int i = 0; i < Target::Flatrock::PARSER_BRIDGE_MD_CONFIGS; i++)
        if (configs[i].id)
            configs[i].write_config(regs);
}
