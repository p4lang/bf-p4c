/* deparser template specializations for jbay -- #included directly in top-level deparser.cpp */

#define YES(X)  X
#define NO(X)

#define JBAY_UNSUPPORTED_INTRINSIC(GR, NAME)                                            \
template<> void INTRIN##GR##NAME::setregs(Target::JBay::deparser_regs &, Deparser &,    \
                                          Deparser::Intrinsic &intrin) {                \
    error(intrin.lineno, "%s unsupported in jbay deparser", #NAME); }

#define JBAY_DEPARSER_INTRINSIC(GR, NAME, MAX) \
template<> void INTRIN##GR##NAME::setregs(Target::JBay::deparser_regs &regs,            \
                                          Deparser &deparser, Deparser::Intrinsic &intrin)

#define JBAY_SIMPLE_INTRINSIC(GRESS, NAME, REG, IFSHIFT, IFPOV)                                 \
    JBAY_DEPARSER_INTRINSIC(GRESS, NAME, 1) {                                                   \
        auto &v = intrin.vals[0];                                                               \
        REG.phv = v.val->reg.deparser_id();                                                     \
        IFPOV(if (v.pov) REG.pov = deparser.pov[GRESS].at(&v.pov->reg) + v.pov->lo;)            \
        IFSHIFT(REG.shft = intrin.vals[0].val->lo;) }

#define JBAY_ARRAY_INTRINSIC(GRESS, NAME, ARRAY, REG, IFSHIFT, IFPOV)                           \
    JBAY_DEPARSER_INTRINSIC(GRESS, NAME, 1) {                                                   \
        auto &v = intrin.vals[0];                                                               \
        for (auto &r : ARRAY) {                                                                 \
            r.REG.phv = v.val->reg.deparser_id();                                               \
            IFPOV(if (v.pov) r.REG.pov = deparser.pov[GRESS].at(&v.pov->reg) + v.pov->lo;)      \
            IFSHIFT(r.REG.shft = intrin.vals[0].val->lo;) } }

#define EI_INTRINSIC(NAME, IFSHIFT) \
    JBAY_SIMPLE_INTRINSIC(EGRESS, NAME, regs.dprsrreg.inp.ipp.egr.m_##NAME, IFSHIFT, YES)
#define HO_E_INTRINSIC(NAME, IFSHIFT) \
    JBAY_ARRAY_INTRINSIC(EGRESS, NAME, regs.dprsrreg.ho_e, her.meta.m_##NAME, IFSHIFT, NO)
#define II_INTRINSIC(NAME, IFSHIFT) \
    JBAY_SIMPLE_INTRINSIC(INGRESS, NAME, regs.dprsrreg.inp.ipp.ingr.m_##NAME, IFSHIFT, YES)
#define HO_I_INTRINSIC(NAME, IFSHIFT) \
    JBAY_ARRAY_INTRINSIC(INGRESS, NAME, regs.dprsrreg.ho_i, hir.meta.m_##NAME, IFSHIFT, NO)

EI_INTRINSIC(drop_ctl, YES)
EI_INTRINSIC(egress_unicast_port, NO)
HO_E_INTRINSIC(capture_tx_ts, YES)
HO_E_INTRINSIC(force_tx_err, YES)
HO_E_INTRINSIC(tx_pkt_has_offsets, YES)

II_INTRINSIC(copy_to_cpu, YES)
II_INTRINSIC(drop_ctl, YES)
II_INTRINSIC(egress_unicast_port, NO)
HO_I_INTRINSIC(bypss_egr, YES)
HO_I_INTRINSIC(ct_disable, YES)
HO_I_INTRINSIC(ct_mcast, YES)
HO_I_INTRINSIC(copy_to_cpu_cos, YES)
HO_I_INTRINSIC(deflect_on_drop, YES)
HO_I_INTRINSIC(icos, YES)
HO_I_INTRINSIC(qid, YES)
HO_I_INTRINSIC(rid, YES)

// FIXME -- these are different
JBAY_UNSUPPORTED_INTRINSIC(INGRESS, egress_multicast_group)
JBAY_UNSUPPORTED_INTRINSIC(INGRESS, hash_lag_ecmp_mcast)
JBAY_UNSUPPORTED_INTRINSIC(INGRESS, ingress_port_source)
JBAY_UNSUPPORTED_INTRINSIC(INGRESS, meter_color)
JBAY_UNSUPPORTED_INTRINSIC(INGRESS, xid)
JBAY_UNSUPPORTED_INTRINSIC(INGRESS, yid)
JBAY_UNSUPPORTED_INTRINSIC(EGRESS, coal)
JBAY_UNSUPPORTED_INTRINSIC(EGRESS, ecos)

#define STUB_JBAY_DEPARSER_DIGEST(GR, NAME, MAX) \
void GR##NAME##Digest::init(Target::JBay) {} \
template<> void GR##NAME##Digest::setregs(Target::JBay::deparser_regs &, Deparser &, \
                                          Deparser::Digest &) { assert(0); }

ALL_DEPARSER_DIGESTS(STUB_JBAY_DEPARSER_DIGEST)

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
    unsigned ch = 0;
    byte = 0;
    Phv::Slice prev_pov;
    for (auto &ent : dict) {
        unsigned size = ent.first->reg.size/8U;
        if (byte + size > JBAY_DEPARSER_CHUNK_SIZE || (prev_pov && *ent.second != prev_pov)) {
            chunk[ch].chunk_vld = 1;
            chunk[ch].pov = pov.at(&prev_pov.reg) + prev_pov.lo;
            chunk[ch].seg_slice = byte & 7;
            chunk[ch].seg_sel = byte >> 3;
            ++ch;
            byte = 0; }
        byte += size;
        prev_pov = *ent.second; }
    if (byte > 0) {
        chunk[ch].chunk_vld = 1;
        chunk[ch].pov = pov.at(&prev_pov.reg) + prev_pov.lo;
        chunk[ch].seg_slice = byte & 7;
        chunk[ch].seg_sel = byte >> 3; }
}

template<class CHUNKS, class CLOTS, class POV, class DICT>
void output_jbay_field_dictionary_slice(CHUNKS &chunk, CLOTS &clots, POV &pov, DICT &dict) {
    unsigned ch = 0, byte = 0;
    Phv::Slice prev_pov;
    for (auto &ent : dict) {
        unsigned size = ent.first->reg.size/8U;
        if (byte + size > JBAY_DEPARSER_CHUNK_SIZE || (prev_pov && *ent.second != prev_pov)) {
            chunk[ch].cfg.seg_slice = byte & 7;
            chunk[ch].cfg.seg_sel = byte >> 3;
            ++ch;
            byte = 0; }
        while (size--) {
            chunk[ch].is_phv |= 1 << byte;
            chunk[ch].byte_off.phv_offset[byte++] = ent.first->reg.deparser_id(); } }
    if (byte > 0) {
        chunk[ch].cfg.seg_slice = byte & 7;
        chunk[ch].cfg.seg_sel = byte >> 3; }
}

template<> void Deparser::write_config(Target::JBay::deparser_regs &regs) {
    regs.dprsrreg.dprsr_csr_ring.disable();
    regs.dprsrreg.dprsr_pbus.disable();
#if 0
    // FIXME -- this is old tofino code -- needs to be updated to jbay?
    regs.input.icr.inp_cfg.disable();
    regs.input.icr.intr.disable();
    regs.header.hem.he_edf_cfg.disable();
    regs.header.him.hi_edf_cfg.disable();
    dump_checksum_units(regs.input.iim.ii_phv_csum.csum_cfg, regs.header.him.hi_tphv_csum.csum_cfg,
                        INGRESS, checksum[INGRESS]);
    dump_checksum_units(regs.input.iem.ie_phv_csum.csum_cfg, regs.header.hem.he_tphv_csum.csum_cfg,
                        EGRESS, checksum[EGRESS]);
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

#if 0
    // FIXME -- this is old tofino code -- needs to be updated to jbay?
    output_phv_ownership(phv_use, regs.input.iir.ingr.phv8_grp, regs.input.iir.ingr.phv8_split,
                         regs.input.ier.egr.phv8_grp, regs.input.ier.egr.phv8_split,
                         FIRST_8BIT_PHV, COUNT_8BIT_PHV);
    output_phv_ownership(phv_use, regs.input.iir.ingr.phv16_grp, regs.input.iir.ingr.phv16_split,
                         regs.input.ier.egr.phv16_grp, regs.input.ier.egr.phv16_split,
                         FIRST_16BIT_PHV, COUNT_16BIT_PHV);
    output_phv_ownership(phv_use, regs.input.iir.ingr.phv32_grp, regs.input.iir.ingr.phv32_split,
                         regs.input.ier.egr.phv32_grp, regs.input.ier.egr.phv32_split,
                         FIRST_32BIT_PHV, COUNT_32BIT_PHV);
#endif

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
