/* deparser template specializations for cloudbreak -- #included directly in top-level deparser.cpp */

#define YES(X)  X
#define NO(X)

#define CLOUDBREAK_POV(GRESS, VAL, REG)                                                         \
    if (VAL.pov) REG.pov = deparser.pov[GRESS].at(&VAL.pov->reg) + VAL.pov->lo;                 \
    else error(VAL.val.lineno, "POV bit required for Tofino2");

#define CLOUDBREAK_SIMPLE_INTRINSIC(GRESS, VAL, REG, IFSHIFT)                                   \
    REG.phv = VAL.val->reg.deparser_id();                                                       \
    CLOUDBREAK_POV(GRESS, VAL, REG)                                                             \
    IFSHIFT(REG.shft = intrin.vals[0].val->lo;)

#define CLOUDBREAK_ARRAY_INTRINSIC(GRESS, VAL, ARRAY, REG, POV, IFSHIFT)                        \
    for (auto &r : ARRAY) {                                                                     \
        r.REG.phv = VAL.val->reg.deparser_id();                                                 \
        IFSHIFT(r.REG.shft = intrin.vals[0].val->lo;) }                                         \
    CLOUDBREAK_POV(GRESS, VAL, POV)

#define EI_INTRINSIC(NAME, IFSHIFT)                                                             \
    DEPARSER_INTRINSIC(Cloudbreak, EGRESS, NAME, 1) {                                           \
        CLOUDBREAK_SIMPLE_INTRINSIC(EGRESS, intrin.vals[0], regs.dprsrreg.inp.ipp.egr.m_##NAME, \
                                    IFSHIFT) }
#define HO_E_INTRINSIC(NAME, IFSHIFT)                                                           \
    DEPARSER_INTRINSIC(Cloudbreak, EGRESS, NAME, 1) {                                           \
        CLOUDBREAK_ARRAY_INTRINSIC(EGRESS, intrin.vals[0], regs.dprsrreg.ho_e,                  \
                                   her.meta.m_##NAME,                                           \
                                   regs.dprsrreg.inp.icr.egr_meta_pov.m_##NAME, IFSHIFT) }
#define II_INTRINSIC(NAME, IFSHIFT)                                                             \
    DEPARSER_INTRINSIC(Cloudbreak, INGRESS, NAME, 1) {                                          \
        CLOUDBREAK_SIMPLE_INTRINSIC(INGRESS, intrin.vals[0],                                    \
                                    regs.dprsrreg.inp.ipp.ingr.m_##NAME,IFSHIFT) }
#define II_INTRINSIC_RENAME(NAME, REGNAME, IFSHIFT)                                             \
    DEPARSER_INTRINSIC(Cloudbreak, INGRESS, NAME, 1) {                                          \
        CLOUDBREAK_SIMPLE_INTRINSIC(INGRESS, intrin.vals[0],                                    \
                                    regs.dprsrreg.inp.ipp.ingr.m_##REGNAME, IFSHIFT) }
#define HO_I_INTRINSIC(NAME, IFSHIFT)                                                           \
    DEPARSER_INTRINSIC(Cloudbreak, INGRESS, NAME, 1) {                                          \
        CLOUDBREAK_ARRAY_INTRINSIC(INGRESS, intrin.vals[0], regs.dprsrreg.ho_i,                 \
                                   hir.meta.m_##NAME,                                           \
                                   regs.dprsrreg.inp.icr.ingr_meta_pov.m_##NAME, IFSHIFT) }
#define HO_I_INTRINSIC_RENAME(NAME, REGNAME, IFSHIFT)                                           \
    DEPARSER_INTRINSIC(Cloudbreak, INGRESS, NAME, 1) {                                          \
        CLOUDBREAK_ARRAY_INTRINSIC(INGRESS, intrin.vals[0], regs.dprsrreg.ho_i,                 \
                                   hir.meta.m_##REGNAME,                                        \
                                   regs.dprsrreg.inp.icr.ingr_meta_pov.m_##REGNAME, IFSHIFT) }

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
II_INTRINSIC_RENAME(egress_multicast_group_0, mgid1, NO)
II_INTRINSIC_RENAME(egress_multicast_group_1, mgid2, NO)
II_INTRINSIC(learn_sel, YES)
II_INTRINSIC(pgen, YES)
II_INTRINSIC(pgen_len, YES)
II_INTRINSIC(pgen_addr, YES)
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
HO_I_INTRINSIC(qid, YES)
HO_I_INTRINSIC(rid, YES)
HO_I_INTRINSIC_RENAME(meter_color, pkt_color, YES)
HO_I_INTRINSIC_RENAME(xid, xid_l1, YES)
HO_I_INTRINSIC_RENAME(yid, xid_l2, YES)
HO_I_INTRINSIC_RENAME(hash_lag_ecmp_mcast_0, hash1, YES)
HO_I_INTRINSIC_RENAME(hash_lag_ecmp_mcast_1, hash2, YES)

#undef EI_INTRINSIC
#undef HO_E_INTRINSIC
#undef II_INTRINSIC
#undef II_INTRINSIC_RENAME
#undef HO_I_INTRINSIC
#undef HO_I_INTRINSIC_RENAME

/** Macros to build Digest::Type objects for Cloudbreak --
 * CLOUDBREAK_SIMPLE_DIGEST: basic digest that appears one place in the config
 * CLOUDBREAK_ARRAY_DIGEST: config is replicated across Header+Output slices
 * GRESS: INGRESS or EGRESS
 * NAME: keyword use for this digest in the assembler
 * ARRAY: Header+Ouput slice array (ho_i or ho_e, matching ingress or egress)
 * TBL: config register containing the table config
 * SEL: config register with the selection config
 * IFID: YES or NO -- if this config needs to pregram id_phv
 * CNT: how many patterns can be specified in the array
 * REVERSE: YES or NO -- if the entries in the table are reverse (0 is last byte of header)
 * IFIDX: YES or NO -- if CNT > 1 (if we index by id)
 */

#define CLOUDBREAK_SIMPLE_DIGEST(GRESS, NAME, TBL, SEL, IFID, CNT, REVERSE, IFIDX)              \
    CLOUDBREAK_COMMON_DIGEST(GRESS, NAME, TBL, SEL, IFID, CNT, REVERSE, IFIDX)                  \
    CLOUDBREAK_DIGEST_TABLE(GRESS, TBL, IFID, YES, CNT, REVERSE, IFIDX) }
#define CLOUDBREAK_ARRAY_DIGEST(GRESS, NAME, ARRAY, TBL, SEL, IFID, CNT, REVERSE, IFIDX)        \
    CLOUDBREAK_COMMON_DIGEST(GRESS, NAME, TBL, SEL, IFID, CNT, REVERSE, IFIDX)                  \
    for (auto &r : ARRAY) {                                                                     \
        CLOUDBREAK_DIGEST_TABLE(GRESS, r.TBL, IFID, NO, CNT, REVERSE, IFIDX) } }

#define CLOUDBREAK_COMMON_DIGEST(GRESS, NAME, TBL, SEL, IFID, CNT, REVERSE, IFIDX)              \
    DEPARSER_DIGEST(Cloudbreak, GRESS, NAME, CNT, can_shift = true; ) {                         \
        SEL.phv = data.select.val->reg.deparser_id();                                           \
        CLOUDBREAK_POV(GRESS, data.select, SEL)                                                 \
        SEL.shft = data.shift + data.select->lo;                                                \
        SEL.disable_ = 0;

#define CLOUDBREAK_DIGEST_TABLE(GRESS, REG, IFID, IFVALID, CNT, REVERSE, IFIDX)                 \
        for (auto &set : data.layout) {                                                         \
            int id = set.first >> data.shift;                                                   \
            int idx = 0;                                                                        \
            REVERSE( int maxidx = REG IFIDX([id]).phvs.size() - 1; )                            \
            bool first = true;                                                                  \
            int last = -1;                                                                      \
            for (auto &reg : set.second) {                                                      \
                if (first) {                                                                    \
                    first = false;                                                              \
                    IFID( REG IFIDX([id]).id_phv = reg->reg.deparser_id(); continue; ) }        \
                if (last == reg->reg.deparser_id()) continue;                                   \
                for (int i = reg->reg.size/8; i > 0; i--)                                       \
                    REG IFIDX([id]).phvs[REVERSE(maxidx -) idx++] = reg->reg.deparser_id();     \
                last = reg->reg.deparser_id(); }                                                \
            IFVALID( REG IFIDX([id]).valid = 1; )                                               \
            REG IFIDX([id]).len = idx; }

CLOUDBREAK_SIMPLE_DIGEST(INGRESS, learning, regs.dprsrreg.inp.ipp.ingr.learn_tbl,
                   regs.dprsrreg.inp.ipp.ingr.m_learn_sel, NO, 8, YES, YES)
CLOUDBREAK_ARRAY_DIGEST(INGRESS, mirror, regs.dprsrreg.ho_i, him.mirr_hdr_tbl.entry,
                  regs.dprsrreg.inp.ipp.ingr.m_mirr_sel, YES, 16, NO, YES)
CLOUDBREAK_ARRAY_DIGEST(EGRESS, mirror, regs.dprsrreg.ho_e, hem.mirr_hdr_tbl.entry,
                  regs.dprsrreg.inp.ipp.egr.m_mirr_sel, YES, 16, NO, YES)
CLOUDBREAK_SIMPLE_DIGEST(INGRESS, resubmit, regs.dprsrreg.inp.ipp.ingr.resub_tbl,
                   regs.dprsrreg.inp.ipp.ingr.m_resub_sel, NO, 8, NO, YES)
CLOUDBREAK_SIMPLE_DIGEST(INGRESS, pktgen, regs.dprsrreg.inp.ipp.ingr.pgen_tbl,
                   regs.dprsrreg.inp.ipp.ingr.m_pgen, NO, 1, NO, NO)

// all the jbay deparser subtrees with a dis or disable_ bit
// FIXME -- should be a way of doing this with a smart template or other metaprogramming.
#define CLOUDBREAK_DISABLE_REGBITS(M) \
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

template<> void Deparser::write_config(Target::Cloudbreak::deparser_regs &regs) {
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

    for (auto &r : regs.dprsrreg.ho_i)
        write_jbay_constant_config(r.hir.h.hdr_xbar_const.value, constants[INGRESS]);
    for (auto &r : regs.dprsrreg.ho_e)
        write_jbay_constant_config(r.her.h.hdr_xbar_const.value, constants[EGRESS]);

    for (int i = 0; i < Target::Cloudbreak::DEPARSER_CHECKSUM_UNITS; i++) {
        if (!checksum_unit[INGRESS][i].entries.empty()) {
            regs.dprsrreg.inp.ipp.phv_csum_pov_cfg.thread.thread[i] = INGRESS;
            write_jbay_checksum_config(regs.dprsrreg.inp.icr.csum_engine[i],
                regs.dprsrreg.inp.ipp.phv_csum_pov_cfg.csum_pov_cfg[i],
                regs.dprsrreg.inp.ipp_m.i_csum.engine[i], i, checksum_unit[INGRESS][i], pov[INGRESS]);
            if (!checksum_unit[EGRESS][i].entries.empty()) {
                error(checksum_unit[INGRESS][i].entries[0].lineno, "checksum %d used in both ingress", i);
                error(checksum_unit[EGRESS][i].entries[0].lineno, "...and egress"); }
        } else if (!checksum_unit[EGRESS][i].entries.empty()) {
            regs.dprsrreg.inp.ipp.phv_csum_pov_cfg.thread.thread[i] = EGRESS;
            write_jbay_checksum_config(regs.dprsrreg.inp.icr.csum_engine[i],
               regs.dprsrreg.inp.ipp.phv_csum_pov_cfg.csum_pov_cfg[i],
               regs.dprsrreg.inp.ipp_m.i_csum.engine[i], i, checksum_unit[EGRESS][i], pov[EGRESS]); } }

    output_jbay_field_dictionary(lineno[INGRESS], regs.dprsrreg.inp.icr.ingr,
        regs.dprsrreg.inp.ipp.main_i.pov.phvs, pov[INGRESS], dictionary[INGRESS]);
    for (auto &rslice : regs.dprsrreg.ho_i)
        output_jbay_field_dictionary_slice(rslice.him.fd_compress.chunk,
            rslice.hir.h.compress_clot_sel, pov[INGRESS], dictionary[INGRESS]);

    output_jbay_field_dictionary(lineno[EGRESS], regs.dprsrreg.inp.icr.egr,
        regs.dprsrreg.inp.ipp.main_e.pov.phvs, pov[EGRESS], dictionary[EGRESS]);
    for (auto &rslice : regs.dprsrreg.ho_e)
        output_jbay_field_dictionary_slice(rslice.hem.fd_compress.chunk,
            rslice.her.h.compress_clot_sel, pov[EGRESS], dictionary[EGRESS]);

    if (Phv::use(INGRESS).intersects(Phv::use(EGRESS))) {
        if (!options.match_compiler) {
            error(lineno[INGRESS], "Registers used in both ingress and egress in pipeline: %s",
                    Phv::db_regset(Phv::use(INGRESS) & Phv::use(EGRESS)).c_str());
        } else {
            warning(lineno[INGRESS], "Registers used in both ingress and egress in pipeline: %s",
                    Phv::db_regset(Phv::use(INGRESS) & Phv::use(EGRESS)).c_str()); }
        /* FIXME -- this only (sort-of) works because 'deparser' comes first in the alphabet,
         * FIXME -- so is the first section to have its 'output' method run.  Its a hack
         * FIXME -- anyways to attempt to correct broken asm that should be an error */
        Phv::unsetuse(INGRESS, phv_use[EGRESS]);
        Phv::unsetuse(EGRESS, phv_use[INGRESS]);
    }

    check_jbay_ownership(phv_use);
    regs.dprsrreg.inp.icr.i_phv8_grp.enable();
    regs.dprsrreg.inp.icr.i_phv16_grp.enable();
    regs.dprsrreg.inp.icr.i_phv32_grp.enable();
    regs.dprsrreg.inp.icr.i_phv8_grp.val = 0;
    regs.dprsrreg.inp.icr.i_phv16_grp.val = 0;
    regs.dprsrreg.inp.icr.i_phv32_grp.val = 0;
    setup_jbay_ownership(phv_use[INGRESS], regs.dprsrreg.inp.icr.i_phv8_grp.val,
        regs.dprsrreg.inp.icr.i_phv16_grp.val, regs.dprsrreg.inp.icr.i_phv32_grp.val);
    regs.dprsrreg.inp.icr.e_phv8_grp.enable();
    regs.dprsrreg.inp.icr.e_phv16_grp.enable();
    regs.dprsrreg.inp.icr.e_phv32_grp.enable();
    setup_jbay_ownership(phv_use[EGRESS], regs.dprsrreg.inp.icr.e_phv8_grp.val,
        regs.dprsrreg.inp.icr.e_phv16_grp.val, regs.dprsrreg.inp.icr.e_phv32_grp.val);

    for (auto &intrin : intrinsics)
        intrin.type->setregs(regs, *this, intrin);

    /* resubmit_mode specifies whether this pipe can perform a resubmit operation on
       a packet. i.e. tell the IPB to resubmit a packet to the MAU pipeline for a second
       time. If the compiler determines that no resubmit is possible, then it can set this
       bit, which should lower latency in some circumstances.
       0 = Resubmit is allowed.  1 = Resubmit is not allowed */
    bool resubmit=false;
    for (auto &digest : digests) {
        if (digest.type->name == "resubmit") {
            resubmit = true;
            break;
        }
    }
    if (resubmit) regs.dprsrreg.inp.ipp.ingr.resubmit_mode.mode = 0;
    else regs.dprsrreg.inp.ipp.ingr.resubmit_mode.mode = 1;

    for (auto &digest : digests)
        digest.type->setregs(regs, *this, digest);

    /* Set learning digest mask for Cloudbreak */
    for (auto &digest : digests) {
        if (digest.type->name == "learning") {
            regs.dprsrreg.inp.icr.lrnmask.enable();
            for(auto &set : digest.layout) {
                int id = set.first;
                int len = regs.dprsrreg.inp.ipp.ingr.learn_tbl[id].len;
                if (len == 0) continue; // Allow empty param list

                // Fix for TF2LAB-37s:
                // This fixes a hardware limitation where the container following 
                // the last PHV used cannot be the same non 8 bit container as the last entry.
                // E.g. For len = 5, (active entries start at index 47)
                // Used   - PHV[47] ... PHV[43] = 0; 
                // Unused - PHV[42] ... PHV[0] = 0; // Defaults to 0
                // This causes issues in hardware as container 0 is used. 
                // We fix by setting the default as 64 an 8 - bit container. It can be any
                // other 8 bit container value.
                // The hardware does not cause any issues for 8 bit conatiners.
                for (int i = 47 - len; i >= 0; i--)
                    regs.dprsrreg.inp.ipp.ingr.learn_tbl[id].phvs[i] = 64;
                // Fix for TF2LAB-37 end

                // Create a bitvec of all phv masks stacked up next to each
                // other in big-endian. 'setregs' above stacks the digest fields
                // in a similar manner to setup the phvs per byte on learn_tbl
                // regs. To illustrate with an example - tna_digest.p4 (since
                // this is not clear based on reg descriptions);
                //
                // BFA Output:
                //
                //   learning:
                //      select: { B1(0..2): B0(1) }  # L[0..2]b: ingress::ig_intr_md_for_dprsr.digest_type
                //      0:
                //        - B1(0..2)  # L[0..2]b: ingress::ig_intr_md_for_dprsr.digest_type
                //        - MW0  # ingress::hdr.ethernet.dst_addr.16-47
                //        - MH1  # ingress::hdr.ethernet.dst_addr.0-15
                //        - MH0(0..8)  # L[0..8]b: ingress::ig_md.port
                //        - MW1  # ingress::hdr.ethernet.src_addr.16-47
                //        - MH2  # ingress::hdr.ethernet.src_addr.0-15
                //
                // PHV packing for digest,
                //
                //    B1(7..0) | MW0 (31..24) | MW0(23..16) | MW0(15..8)  |
                //   MW0(7..0) | MH1 (15..8)  | MH1(7..0)   | MH0(16..8)  |
                //   MH0(7..0) | MW1 (31..24) | MW1(23..16) | MW1(15..8)  |
                //   MW1(7..0) | MH2 (15..8)  | MH2(7..0)   | ----------  |
                //
                // Learn Mask Regs for above digest
                //   deparser.regs.dprsrreg.inp.icr.lrnmask[0].mask[11] = 4294967047 (0x07ffffff)
                //   deparser.regs.dprsrreg.inp.icr.lrnmask[0].mask[10] = 4294967295 (0xffffff01)
                //   deparser.regs.dprsrreg.inp.icr.lrnmask[0].mask[9]  = 4278321151 (0xffffffff)
                //   deparser.regs.dprsrreg.inp.icr.lrnmask[0].mask[8]  = 4294967040 (0xffffff00)
                //
                bitvec lrnmask;
                int startBit = 0;
                int size = 0;
                for (auto p : set.second) {
                    if (size > 0)
                        lrnmask <<= p->reg.size;
                    auto psliceSize = p.size();
                    startBit = p.lobit(); 
                    lrnmask.setrange(startBit, psliceSize);
                    size += p->reg.size;
                }
                // Pad to a 32 bit word
                auto shift = (size % 32) ? (32 - (size % 32)) : 0;
                lrnmask <<= shift; 
                int num_words = (size + 31)/32;
                int quanta_index = 11;
                for (int index = num_words - 1; index >= 0; index--) {
                    BUG_CHECK(quanta_index >= 0);
                    unsigned word = lrnmask.getrange(index * 32, 32); 
                    regs.dprsrreg.inp.icr.lrnmask[id].mask[quanta_index--] = word;
                }
            }
        }
    }

#define DISBALE_IF_NOT_SET(ISARRAY, ARRAY, REGS, DISABLE) \
    ISARRAY(for (auto &r : ARRAY)) if (!ISARRAY(r.)REGS.modified()) ISARRAY(r.)REGS.DISABLE = 1;
    CLOUDBREAK_DISABLE_REGBITS(DISBALE_IF_NOT_SET)

    if (options.condense_json)
        regs.disable_if_reset_value();
    if (error_count == 0 && options.gen_json)
        regs.emit_json(*open_output("regs.deparser.cfg.json"));
    TopLevel::regs<Target::Cloudbreak>()->reg_pipe.pardereg.dprsrreg.set("regs.deparser", &regs);
}

template<> unsigned Deparser::FDEntry::Checksum::encode<Target::Cloudbreak>() {
    return 232 + unit;
}

template<> unsigned Deparser::FDEntry::Constant::encode<Target::Cloudbreak>() {
    return 224 + Deparser::constant_idx(gress, val);
}

template<> void Deparser::gen_learn_quanta(Target::Cloudbreak::parser_regs &regs, json::vector &learn_quanta) {
}
