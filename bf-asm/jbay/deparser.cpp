/* deparser template specializations for jbay -- #included directly in top-level deparser.cpp */

#define YES(X)  X
#define NO(X)

#define JBAY_SIMPLE_INTRINSIC(GRESS, VAL, REG, IFSHIFT)                                         \
    REG.phv = VAL.val->reg.deparser_id();                                                       \
    if (VAL.pov) REG.pov = deparser.pov[GRESS].at(&VAL.pov->reg) + VAL.pov->lo;                 \
    else error(VAL.val.lineno, "POV bit required for jbay");                                    \
    IFSHIFT(REG.shft = intrin.vals[0].val->lo;)

#define JBAY_ARRAY_INTRINSIC(GRESS, VAL, ARRAY, REG, POV, IFSHIFT)                              \
    for (auto &r : ARRAY) {                                                                     \
        r.REG.phv = VAL.val->reg.deparser_id();                                                 \
        IFSHIFT(r.REG.shft = intrin.vals[0].val->lo;) }                                         \
    if (VAL.pov) POV.pov = deparser.pov[GRESS].at(&VAL.pov->reg) + VAL.pov->lo;                 \
    else error(VAL.val.lineno, "POV bit required for jbay");

#define EI_INTRINSIC(NAME, IFSHIFT)                                                             \
    DEPARSER_INTRINSIC(JBay, EGRESS, NAME, 1) {                                                 \
        JBAY_SIMPLE_INTRINSIC(EGRESS, intrin.vals[0], regs.dprsrreg.inp.ipp.egr.m_##NAME,       \
                              IFSHIFT) }
#define HO_E_INTRINSIC(NAME, IFSHIFT)                                                           \
    DEPARSER_INTRINSIC(JBay, EGRESS, NAME, 1) {                                                 \
        JBAY_ARRAY_INTRINSIC(EGRESS, intrin.vals[0], regs.dprsrreg.ho_e, her.meta.m_##NAME,     \
                             regs.dprsrreg.inp.icr.egr_meta_pov.m_##NAME, IFSHIFT) }
#define II_INTRINSIC(NAME, IFSHIFT)                                                             \
    DEPARSER_INTRINSIC(JBay, INGRESS, NAME, 1) {                                                \
        JBAY_SIMPLE_INTRINSIC(INGRESS, intrin.vals[0], regs.dprsrreg.inp.ipp.ingr.m_##NAME,     \
                              IFSHIFT) }
#define HO_I_INTRINSIC(NAME, IFSHIFT)                                                           \
    DEPARSER_INTRINSIC(JBay, INGRESS, NAME, 1) {                                                \
        JBAY_ARRAY_INTRINSIC(INGRESS, intrin.vals[0], regs.dprsrreg.ho_i, hir.meta.m_##NAME,    \
                             regs.dprsrreg.inp.icr.ingr_meta_pov.m_##NAME, IFSHIFT) }

EI_INTRINSIC(drop_ctl, YES)
EI_INTRINSIC(egress_unicast_port, NO)
HO_E_INTRINSIC(afc, YES)
HO_E_INTRINSIC(capture_tx_ts, YES)
HO_E_INTRINSIC(force_tx_err, YES)
HO_E_INTRINSIC(tx_pkt_has_offsets, YES)
HO_E_INTRINSIC(mirr_c2c_ctrl, YES)
HO_E_INTRINSIC(mirr_coal_smpl_len, YES)
HO_E_INTRINSIC(mirr_dond_ctrl, YES)
HO_E_INTRINSIC(mirr_epipe_port, YES)
HO_E_INTRINSIC(mirr_hash, YES)
HO_E_INTRINSIC(mirr_icos, YES)
HO_E_INTRINSIC(mirr_io_sel, YES)
HO_E_INTRINSIC(mirr_mc_ctrl, YES)
HO_E_INTRINSIC(mirr_qid, YES)
HO_E_INTRINSIC(mtu_trunc_err_f, YES)
HO_E_INTRINSIC(mtu_trunc_len, YES)

II_INTRINSIC(copy_to_cpu, YES)
II_INTRINSIC(drop_ctl, YES)
II_INTRINSIC(egress_unicast_port, NO)
HO_I_INTRINSIC(afc, YES)
HO_I_INTRINSIC(bypss_egr, YES)
HO_I_INTRINSIC(copy_to_cpu_cos, YES)
HO_I_INTRINSIC(ct_disable, YES)
HO_I_INTRINSIC(ct_mcast, YES)
HO_I_INTRINSIC(deflect_on_drop, YES)
HO_I_INTRINSIC(icos, YES)
HO_I_INTRINSIC(mirr_c2c_ctrl, YES)
HO_I_INTRINSIC(mirr_coal_smpl_len, YES)
HO_I_INTRINSIC(mirr_dond_ctrl, YES)
HO_I_INTRINSIC(mirr_epipe_port, YES)
HO_I_INTRINSIC(mirr_hash, YES)
HO_I_INTRINSIC(mirr_icos, YES)
HO_I_INTRINSIC(mirr_io_sel, YES)
HO_I_INTRINSIC(mirr_mc_ctrl, YES)
HO_I_INTRINSIC(mirr_qid, YES)
HO_I_INTRINSIC(mtu_trunc_err_f, YES)
HO_I_INTRINSIC(mtu_trunc_len, YES)
HO_I_INTRINSIC(pkt_color, YES)
HO_I_INTRINSIC(qid, YES)
HO_I_INTRINSIC(rid, YES)

DEPARSER_INTRINSIC(JBay, INGRESS, egress_multicast_group, 2) {
    int idx = 0;
    for (auto &v : intrin.vals) {
        switch (++idx) {
        case 1: JBAY_SIMPLE_INTRINSIC(INGRESS, v, regs.dprsrreg.inp.ipp.ingr.m_mgid1, NO) break;
        case 2: JBAY_SIMPLE_INTRINSIC(INGRESS, v, regs.dprsrreg.inp.ipp.ingr.m_mgid2, NO) break;
        default: assert(0); } } }

DEPARSER_INTRINSIC(JBay, INGRESS, hash_lag_ecmp_mcast, 2) {
    int idx = 0;
    for (auto &v : intrin.vals) {
        switch (++idx) {
        case 1:
            JBAY_ARRAY_INTRINSIC(INGRESS, v, regs.dprsrreg.ho_i, hir.meta.m_hash1,
                                 regs.dprsrreg.inp.icr.ingr_meta_pov.m_hash1, YES)
            break;
        case 2:
            JBAY_ARRAY_INTRINSIC(INGRESS, v, regs.dprsrreg.ho_i, hir.meta.m_hash2,
                                 regs.dprsrreg.inp.icr.ingr_meta_pov.m_hash2, YES)
            break;
        default:
            assert(0); } } }
DEPARSER_INTRINSIC(JBay, INGRESS, xid, 2) {
    int idx = 0;
    for (auto &v : intrin.vals) {
        switch (++idx) {
        case 1:
            JBAY_ARRAY_INTRINSIC(INGRESS, v, regs.dprsrreg.ho_i, hir.meta.m_xid_l1,
                                 regs.dprsrreg.inp.icr.ingr_meta_pov.m_xid_l1, YES)
            break;
        case 2:
            JBAY_ARRAY_INTRINSIC(INGRESS, v, regs.dprsrreg.ho_i, hir.meta.m_xid_l2,
                                 regs.dprsrreg.inp.icr.ingr_meta_pov.m_xid_l2, YES)
            break;
        default:
            assert(0); } } }

#define JBAY_SIMPLE_DIGEST(GRESS, NAME, TBL, SEL, IFID, CNT)                            \
    DEPARSER_DIGEST(JBay, GRESS, NAME, CNT, can_shift = true; ) {                       \
        SEL.phv = data.select->reg.deparser_id();                                       \
        SEL.shft = data.shift + data.select->lo;                                        \
        SEL.disable_ = 0;                                                               \
        JBAY_DIGEST_TABLE(GRESS, TBL, IFID, YES, CNT) }

#define JBAY_ARRAY_DIGEST(GRESS, NAME, ARRAY, TBL, SEL, IFID, CNT)                      \
    DEPARSER_DIGEST(JBay, GRESS, NAME, CNT, can_shift = true; ) {                       \
        SEL.phv = data.select->reg.deparser_id();                                       \
        SEL.shft = data.shift + data.select->lo;                                        \
        SEL.disable_ = 0;                                                               \
        for (auto &r : ARRAY) {                                                         \
            JBAY_DIGEST_TABLE(GRESS, r.TBL, IFID, NO, CNT) } }

#define JBAY_DIGEST_TABLE(GRESS, REG, IFID, IFVALID, CNT)                               \
        for (auto &set : data.layout) {                                                 \
            int id = set.first >> data.shift;                                           \
            int idx = 0;                                                                \
            bool first = true;                                                          \
            for (auto &reg : set.second) {                                              \
                if (first) {                                                            \
                    first = false;                                                      \
                    IFID( REG[id].id_phv = reg->reg.deparser_id(); continue; ) }        \
                for (int i = reg->reg.size/8; i > 0; i--)                               \
                    REG[id].phvs[idx++] = reg->reg.deparser_id(); }                     \
            IFVALID( REG[id].valid = 1; )                                               \
            REG[id].len = idx; }

JBAY_SIMPLE_DIGEST(INGRESS, learning, regs.dprsrreg.inp.ipp.ingr.learn_tbl,
                   regs.dprsrreg.inp.ipp.ingr.m_learn_sel, NO, 8)
JBAY_ARRAY_DIGEST(INGRESS, mirror, regs.dprsrreg.ho_i, him.mirr_hdr_tbl.entry,
                  regs.dprsrreg.inp.ipp.ingr.m_mirr_sel, YES, 16)
JBAY_ARRAY_DIGEST(EGRESS, mirror, regs.dprsrreg.ho_e, hem.mirr_hdr_tbl.entry,
                  regs.dprsrreg.inp.ipp.egr.m_mirr_sel, YES, 16)
JBAY_SIMPLE_DIGEST(INGRESS, resubmit, regs.dprsrreg.inp.ipp.ingr.resub_tbl,
                   regs.dprsrreg.inp.ipp.ingr.m_resub_sel, NO, 8)


// all the jbay deparser subtrees with a dis or disable_ bit
// FIXME -- should be a way of doing this with a smart template or other metaprogramming.
#define JBAY_DISABLE_REGBITS(M) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_afc, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_capture_tx_ts, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_force_tx_err, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_mirr_c2c_ctrl, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_mirr_coal_smpl_len, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_mirr_dond_ctrl, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_mirr_epipe_port, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_mirr_hash, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_mirr_icos, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_mirr_io_sel, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_mirr_mc_ctrl, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_mirr_qid, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_mtu_trunc_err_f, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_mtu_trunc_len, dis) \
    M(YES, regs.dprsrreg.ho_e, her.meta.m_tx_pkt_has_offsets, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_afc, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_bypss_egr, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_copy_to_cpu_cos, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_ct_disable, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_ct_mcast, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_deflect_on_drop, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_hash1, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_hash2, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_icos, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_mirr_c2c_ctrl, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_mirr_coal_smpl_len, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_mirr_dond_ctrl, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_mirr_epipe_port, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_mirr_hash, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_mirr_icos, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_mirr_io_sel, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_mirr_mc_ctrl, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_mirr_qid, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_mtu_trunc_err_f, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_mtu_trunc_len, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_pkt_color, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_qid, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_rid, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_xid_l1, dis) \
    M(YES, regs.dprsrreg.ho_i, hir.meta.m_xid_l2, dis) \
    M(NO, , regs.dprsrreg.inp.ipp.egr.m_drop_ctl, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.egr.m_egress_unicast_port, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.egr.m_mirr_sel, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.ingr.m_copy_to_cpu, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.ingr.m_drop_ctl, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.ingr.m_egress_unicast_port, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.ingr.m_learn_sel, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.ingr.m_mgid1, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.ingr.m_mgid2, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.ingr.m_mirr_sel, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.ingr.m_pgen, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.ingr.m_pgen_addr, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.ingr.m_pgen_len, disable_) \
    M(NO, , regs.dprsrreg.inp.ipp.ingr.m_resub_sel, disable_)

enum { JBAY_DEPARSER_CHUNK_SIZE = 8 };

template<class CHUNKS, class POV_FMT, class POV, class DICT>
void output_jbay_field_dictionary(int lineno, CHUNKS &chunk, POV_FMT &pov_layout,
                                  POV &pov, DICT &dict) {
    unsigned byte = 0;
    for (auto &r : pov) {
        for (int bits = 0; bits < r.first->size; bits += 8) {
            if (byte > pov_layout.size())
                error(lineno, "Ran out of space in POV in deparser");
            pov_layout[byte++] = r.first->deparser_id(); } }
    while (byte < pov_layout.size())
        pov_layout[byte++] = 0xff;
    // DANGER -- this code and output_jbay_field_dictionary_slice below must match exactly
    unsigned ch = 0;
    byte = 0;
    Phv::Slice prev_pov;
    for (auto &ent : dict) {
        unsigned size = ent.first->reg.size/8U;
        if (byte + size > JBAY_DEPARSER_CHUNK_SIZE || (prev_pov && *ent.second != prev_pov)) {
            chunk[ch].chunk_vld = 1;
            chunk[ch].pov = pov.at(&prev_pov.reg) + prev_pov.lo;
            chunk[ch].seg_vld = 0;  // no CLOTs yet
            chunk[ch].seg_slice = byte & 7;
            chunk[ch].seg_sel = byte >> 3;
            ++ch;
            byte = 0; }
        byte += size;
        prev_pov = *ent.second; }
    if (byte > 0) {
        chunk[ch].chunk_vld = 1;
        chunk[ch].pov = pov.at(&prev_pov.reg) + prev_pov.lo;
        chunk[ch].seg_vld = 0;  // no CLOTs yet
        chunk[ch].seg_slice = byte & 7;
        chunk[ch].seg_sel = byte >> 3; }
}

template<class CHUNKS, class CLOTS, class POV, class DICT>
void output_jbay_field_dictionary_slice(CHUNKS &chunk, CLOTS &clots, POV &pov, DICT &dict) {
    // DANGER -- this code and output_jbay_field_dictionary above must match exactly
    unsigned ch = 0, byte = 0;
    Phv::Slice prev_pov;
    for (auto &ent : dict) {
        unsigned size = ent.first->reg.size/8U;
        if (byte + size > JBAY_DEPARSER_CHUNK_SIZE || (prev_pov && *ent.second != prev_pov)) {
            chunk[ch].cfg.seg_vld = 0;  // no CLOTs yet
            chunk[ch].cfg.seg_slice = byte & 7;
            chunk[ch].cfg.seg_sel = byte >> 3;
            ++ch;
            byte = 0; }
        while (size--) {
            chunk[ch].is_phv |= 1 << byte;
            chunk[ch].byte_off.phv_offset[byte++] = ent.first->reg.deparser_id(); }
        prev_pov = *ent.second; }
    if (byte > 0) {
        chunk[ch].cfg.seg_vld = 0;  // no CLOTs yet
        chunk[ch].cfg.seg_slice = byte & 7;
        chunk[ch].cfg.seg_sel = byte >> 3; }
}

static void setup_jbay_ownership(bitvec phv_use, ubits_base &phv8, ubits_base &phv16,
                                 ubits_base &phv32) {
    for (auto i : phv_use) {
        auto *reg = Phv::reg(i);
        switch (reg->size) {
        case 8:
            phv8 |= 1U << ((reg->deparser_id() - 64)/4U);
            break;
        case 16:
            phv16 |= 1U << ((reg->deparser_id() - 128)/4U);
            break;
        case 32:
            phv32 |= 1U << (reg->deparser_id()/2U);
            break;
        default:
            assert(0); } }
}

template<> void Deparser::write_config(Target::JBay::deparser_regs &regs) {
    regs.dprsrreg.dprsr_csr_ring.disable();
    regs.dprsrreg.dprsr_pbus.disable();
    regs.dprsrreg.inp.icr.disable();            // disable this whole tree
    regs.dprsrreg.inp.icr.disabled_ = false;    // then enable just certain subtrees
    regs.dprsrreg.inp.icr.csum_engine.enable();
    regs.dprsrreg.inp.icr.egr.enable(); 
    regs.dprsrreg.inp.icr.egr_meta_pov.enable(); 
    regs.dprsrreg.inp.icr.ingr.enable(); 
    regs.dprsrreg.inp.icr.ingr_meta_pov.enable(); 
    regs.dprsrreg.inp.iim.disable();
    regs.dprsrreg.inpslice.disable();
    for (auto &r : regs.dprsrreg.ho_i)
        r.out_ingr.disable();
    for (auto &r : regs.dprsrreg.ho_e)
        r.out_egr.disable();

#if 0
    // FIXME -- this is old tofino code -- needs to be updated to jbay?
    dump_checksum_units(regs.input.iim.ii_phv_csum.csum_cfg, regs.header.him.hi_tphv_csum.csum_cfg,
                        INGRESS, checksum[INGRESS]);
    dump_checksum_units(regs.input.iem.ie_phv_csum.csum_cfg, regs.header.hem.he_tphv_csum.csum_cfg,
                        EGRESS, checksum[EGRESS]);

    // jbay register trees associated with checksums:
    // regs.dprsrreg.inp.icr.csum_engine
    // regs.dprsrreg.inp.ipp.phv_csum_phv_cfg
    // regs.dprsrreg.inp.ipp_m.i_csum.engine
#endif

    output_jbay_field_dictionary(lineno[INGRESS], regs.dprsrreg.inp.icr.ingr.chunk_info,
        regs.dprsrreg.inp.ipp.main_i.pov.phvs, pov[INGRESS], dictionary[INGRESS]);
    for (auto &rslice : regs.dprsrreg.ho_i)
        output_jbay_field_dictionary_slice(rslice.him.fd_compress.chunk,
            rslice.hir.h.compress_clot_sel, pov[INGRESS], dictionary[INGRESS]);

    output_jbay_field_dictionary(lineno[EGRESS], regs.dprsrreg.inp.icr.egr.chunk_info,
        regs.dprsrreg.inp.ipp.main_e.pov.phvs, pov[EGRESS], dictionary[EGRESS]);
    for (auto &rslice : regs.dprsrreg.ho_e)
        output_jbay_field_dictionary_slice(rslice.hem.fd_compress.chunk,
            rslice.her.h.compress_clot_sel, pov[EGRESS], dictionary[EGRESS]);

    if (Phv::use(INGRESS).intersects(Phv::use(EGRESS))) {
        warning(lineno[INGRESS], "Registers used in both ingress and egress in pipeline: %s",
                Phv::db_regset(phv_use[INGRESS] & phv_use[EGRESS]).c_str());
        /* FIXME -- this only (sort-of) works because 'deparser' comes first in the alphabet,
         * FIXME -- so is the first section to have its 'output' method run.  Its a hack
         * FIXME -- anyways to attempt to correct broken asm that should be an error */
        Phv::unsetuse(INGRESS, phv_use[EGRESS]);
        Phv::unsetuse(EGRESS, phv_use[INGRESS]);
    }

    regs.dprsrreg.inp.icr.i_phv8_grp.enable();
    regs.dprsrreg.inp.icr.i_phv16_grp.enable();
    regs.dprsrreg.inp.icr.i_phv32_grp.enable();
    regs.dprsrreg.inp.icr.i_phv8_grp.val = 0;
    regs.dprsrreg.inp.icr.i_phv16_grp.val = 0;
    regs.dprsrreg.inp.icr.i_phv32_grp.val = 0;
    setup_jbay_ownership(phv_use[INGRESS], regs.dprsrreg.inp.icr.i_phv8_grp.val,
        regs.dprsrreg.inp.icr.i_phv16_grp.val, regs.dprsrreg.inp.icr.i_phv32_grp.val);
    setup_jbay_ownership(phv_use[EGRESS], regs.dprsrreg.inp.icr.e_phv8_grp.val,
        regs.dprsrreg.inp.icr.e_phv16_grp.val, regs.dprsrreg.inp.icr.e_phv32_grp.val);

    for (auto &intrin : intrinsics)
        intrin.type->setregs(regs, *this, intrin);

    for (auto &digest : digests)
        digest.type->setregs(regs, *this, digest);

#define DISBALE_IF_NOT_SET(ISARRAY, ARRAY, REGS, DISABLE) \
    ISARRAY(for (auto &r : ARRAY)) if (!ISARRAY(r.)REGS.modified()) ISARRAY(r.)REGS.DISABLE = 1;
    JBAY_DISABLE_REGBITS(DISBALE_IF_NOT_SET)

    if (options.condense_json)
        regs.disable_if_zero();
    regs.emit_json(*open_output("regs.deparser.cfg.json"));
    TopLevel::regs<Target::JBay>()->reg_pipe.pardereg.dprsrreg = "regs.deparser";
}

template<> Phv::Slice Deparser::RefOrChksum::lookup<Target::JBay>() const {
    return Phv::Slice();
}
