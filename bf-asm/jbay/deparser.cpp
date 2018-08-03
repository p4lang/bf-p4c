/* deparser template specializations for jbay -- #included directly in top-level deparser.cpp */

#define YES(X)  X
#define NO(X)

#define JBAY_POV(GRESS, VAL, REG)                                                               \
    if (VAL.pov) REG.pov = deparser.pov[GRESS].at(&VAL.pov->reg) + VAL.pov->lo;                 \
    else error(VAL.val.lineno, "POV bit required for jbay");

#define JBAY_SIMPLE_INTRINSIC(GRESS, VAL, REG, IFSHIFT)                                         \
    REG.phv = VAL.val->reg.deparser_id();                                                       \
    JBAY_POV(GRESS, VAL, REG)                                                                   \
    IFSHIFT(REG.shft = intrin.vals[0].val->lo;)

#define JBAY_ARRAY_INTRINSIC(GRESS, VAL, ARRAY, REG, POV, IFSHIFT)                              \
    for (auto &r : ARRAY) {                                                                     \
        r.REG.phv = VAL.val->reg.deparser_id();                                                 \
        IFSHIFT(r.REG.shft = intrin.vals[0].val->lo;) }                                         \
    JBAY_POV(GRESS, VAL, POV)

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
        SEL.phv = data.select.val->reg.deparser_id();                                   \
        JBAY_POV(GRESS, data.select, SEL)                                               \
        SEL.shft = data.shift + data.select->lo;                                        \
        SEL.disable_ = 0;                                                               \
        JBAY_DIGEST_TABLE(GRESS, TBL, IFID, YES, CNT) }

#define JBAY_ARRAY_DIGEST(GRESS, NAME, ARRAY, TBL, SEL, IFID, CNT)                      \
    DEPARSER_DIGEST(JBay, GRESS, NAME, CNT, can_shift = true; ) {                       \
        SEL.phv = data.select.val->reg.deparser_id();                                   \
        JBAY_POV(GRESS, data.select, SEL)                                               \
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

template<class REGS, class POV_FMT, class POV, class DICT>
void output_jbay_field_dictionary(int lineno, REGS &regs, POV_FMT &pov_layout,
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
    const unsigned CHUNK_SIZE = Target::JBay::DEPARSER_CHUNK_SIZE;
    const unsigned CHUNK_GROUPS = Target::JBay::DEPARSER_CHUNK_GROUPS;
    const unsigned CHUNKS_PER_GROUP = Target::JBay::DEPARSER_CHUNKS_PER_GROUP;
    const unsigned CLOTS_PER_GROUP = Target::JBay::DEPARSER_CLOTS_PER_GROUP;
    const unsigned TOTAL_CHUNKS = Target::JBay::DEPARSER_TOTAL_CHUNKS;
    unsigned ch = 0, clots_in_group[CHUNK_GROUPS + 1] = { 0 };
    byte = 0;
    Phv::Slice prev_pov;
    for (auto &ent : dict) {
        if (ch >= TOTAL_CHUNKS) {
            error(lineno, "Ran out of chunks in field dictionary (%d)", TOTAL_CHUNKS);
            break; }
        auto *clot = dynamic_cast<Deparser::FDEntry::Clot *>(ent.what);
        // FIXME -- why does the following give an error from gcc?
        // auto *clot = ent.what->to<Deparser::FDEntry::Clot>();
        unsigned size = ent.what->size();
        if (byte && (clot || byte + size > CHUNK_SIZE ||
                     (prev_pov && *ent.pov != prev_pov))) {
            regs.chunk_info[ch].chunk_vld = 1;
            regs.chunk_info[ch].pov = pov.at(&prev_pov.reg) + prev_pov.lo;
            regs.chunk_info[ch].seg_vld = 0;
            regs.chunk_info[ch].seg_slice = byte & 7;
            regs.chunk_info[ch].seg_sel = byte >> 3;
            ++ch;
            byte = 0; }
        if (clot) {
            if (clots_in_group[ch/CHUNKS_PER_GROUP] >= CLOTS_PER_GROUP)
                ch = (ch | (CHUNKS_PER_GROUP - 1)) + 1;
            int clot_tag = Parser::clot_tag(clot->gress, clot->tag);
            int seg_tag = clots_in_group[ch/CHUNKS_PER_GROUP]++;
            regs.fd_tags[ch/CHUNKS_PER_GROUP].segment_tag[seg_tag] = clot_tag;
            for (int i = 0; i < clot->length; i += 8, ++ch) {
                if (ch >= TOTAL_CHUNKS)
                    break;
                if (clots_in_group[ch/CHUNKS_PER_GROUP] == 0) {
                    seg_tag = clots_in_group[ch/CHUNKS_PER_GROUP]++;
                    regs.fd_tags[ch/CHUNKS_PER_GROUP].segment_tag[seg_tag] = clot_tag; }
                regs.chunk_info[ch].chunk_vld = 1;
                regs.chunk_info[ch].pov = pov.at(&ent.pov->reg) + ent.pov->lo;
                regs.chunk_info[ch].seg_vld = 1;
                regs.chunk_info[ch].seg_sel = seg_tag;
                regs.chunk_info[ch].seg_slice = i/8U; }
            if (ch >= TOTAL_CHUNKS) {
                error(lineno, "Ran out of chunks in field dictionary (%d)", TOTAL_CHUNKS);
                break; }

        } else {
            byte += size; }
        prev_pov = *ent.pov; }
    if (byte > 0) {
        regs.chunk_info[ch].chunk_vld = 1;
        regs.chunk_info[ch].pov = pov.at(&prev_pov.reg) + prev_pov.lo;
        regs.chunk_info[ch].seg_vld = 0;  // no CLOTs yet
        regs.chunk_info[ch].seg_slice = byte & 7;
        regs.chunk_info[ch].seg_sel = byte >> 3; }
}

template<class CHUNKS, class CLOTS, class POV, class DICT>
void output_jbay_field_dictionary_slice(CHUNKS &chunk, CLOTS &clots, POV &pov, DICT &dict) {
    // DANGER -- this code and output_jbay_field_dictionary above must match exactly
    const unsigned CHUNK_SIZE = Target::JBay::DEPARSER_CHUNK_SIZE;
    const unsigned CHUNK_GROUPS = Target::JBay::DEPARSER_CHUNK_GROUPS;
    const unsigned CHUNKS_PER_GROUP = Target::JBay::DEPARSER_CHUNKS_PER_GROUP;
    const unsigned CLOTS_PER_GROUP = Target::JBay::DEPARSER_CLOTS_PER_GROUP;
    const unsigned TOTAL_CHUNKS = Target::JBay::DEPARSER_TOTAL_CHUNKS;
    unsigned ch = 0, byte = 0, clots_in_group[CHUNK_GROUPS + 1] = { 0 };
    Phv::Slice prev_pov;
    for (auto &ent : dict) {
        if (ch >= TOTAL_CHUNKS) break;
        auto *clot = dynamic_cast<Deparser::FDEntry::Clot *>(ent.what);
        unsigned size = ent.what->size();
        if (byte && (clot || byte + size > CHUNK_SIZE ||
                     (prev_pov && *ent.pov != prev_pov))) {
            chunk[ch].cfg.seg_vld = 0;
            chunk[ch].cfg.seg_slice = byte & 7;
            chunk[ch].cfg.seg_sel = byte >> 3;
            ++ch;
            byte = 0; }
        if (clot) {
            if (clots_in_group[ch/CHUNKS_PER_GROUP] >= CLOTS_PER_GROUP)
                ch = (ch | (CHUNKS_PER_GROUP - 1)) + 1;
            int clot_tag = Parser::clot_tag(clot->gress, clot->tag);
            int seg_tag = clots_in_group[ch/CHUNKS_PER_GROUP]++;
            clots[ch/CHUNKS_PER_GROUP].segment_tag[seg_tag] = clot_tag;
            auto phv_repl = clot->phv_replace.begin();
            auto csum_repl = clot->csum_replace.begin();
            for (int i = 0; i < clot->length; i += 8, ++ch) {
                if (ch >= TOTAL_CHUNKS) break;
                if (clots_in_group[ch/CHUNKS_PER_GROUP] == 0) {
                    seg_tag = clots_in_group[ch/CHUNKS_PER_GROUP]++;
                    clots[ch/CHUNKS_PER_GROUP].segment_tag[seg_tag] = clot_tag; }
                chunk[ch].cfg.seg_vld = 1;
                chunk[ch].cfg.seg_sel = seg_tag;
                chunk[ch].cfg.seg_slice = i/8U;
                for (int j = 0; j < 8 && i + j < clot->length; ++j) {
                    if (phv_repl != clot->phv_replace.end() && phv_repl->first <= i + j) {
                        chunk[ch].is_phv |= 1 << j;
                        chunk[ch].byte_off.phv_offset[j] = phv_repl->second->reg.deparser_id();
                        if (phv_repl->first + phv_repl->second->size()/8U <= i + j + 1)
                            ++phv_repl;
                    } else if (csum_repl != clot->csum_replace.end() && csum_repl->first <= i + j) {
                        chunk[ch].is_phv |= 1 << j;
                        chunk[ch].byte_off.phv_offset[j] = csum_repl->second.encode();
                        if (csum_repl->first + 2 <= i + j +1)
                            ++csum_repl;
                    } else {
                        chunk[ch].byte_off.phv_offset[j] = i + j; } } }
            if (ch >= TOTAL_CHUNKS) break;
        } else {
            while (size--) {
                chunk[ch].is_phv |= 1 << byte;
                chunk[ch].byte_off.phv_offset[byte++] = ent.what->encode(); } }
        prev_pov = *ent.pov; }
    if (byte > 0) {
        chunk[ch].cfg.seg_vld = 0;  // no CLOTs yet
        chunk[ch].cfg.seg_slice = byte & 7;
        chunk[ch].cfg.seg_sel = byte >> 3; }
}

static void check_jbay_ownership(bitvec phv_use[2]) {
    unsigned    mask = 0;
    int         group = -1;
    for (auto i : phv_use[INGRESS]) {
        if ((i|mask) == (group|mask)) continue;
        switch (Phv::reg(i)->size) {
        case 8: case 16: mask = 3; break;
        case 32:         mask = 1; break;
        default: assert(0); }
        group = i & ~mask;
        if (phv_use[EGRESS].getrange(group, mask+1)) {
            error(0, "%s..%s used by both ingress and egress deparser",
                  Phv::reg(group)->name, Phv::reg(group|mask)->name); } }
}

static void setup_jbay_ownership(bitvec phv_use, ubits_base &phv8, ubits_base &phv16,
                                 ubits_base &phv32) {
    std::set<unsigned> phv8_grps, phv16_grps, phv32_grps;

    for (auto i : phv_use) {
        auto *reg = Phv::reg(i);
        switch (reg->size) {
        case 8:
            phv8_grps.insert(1U << ((reg->deparser_id() - 64)/4U));
            break;
        case 16:
            phv16_grps.insert(1U << ((reg->deparser_id() - 128)/4U));
            break;
        case 32:
            phv32_grps.insert(1U << (reg->deparser_id()/2U));
            break;
        default:
            assert(0); } }

    for (auto v : phv8_grps)  phv8 |= v;
    for (auto v : phv16_grps) phv16 |= v;
    for (auto v : phv32_grps) phv32 |= v;
}

static short jbay_phv2cksum[224][2] = {
    {  0,  1}, {  2,  3}, {  4,  5}, {  6,  7}, {  8,  9}, { 10, 11}, { 12, 13}, { 14, 15},
    { 16, 17}, { 18, 19}, { 20, 21}, { 22, 23}, { 24, 25}, { 26, 27}, { 28, 29}, { 30, 31},
    { 32, 33}, { 34, 35}, { 36, 37}, { 38, 39}, { 40, 41}, { 42, 43}, { 44, 45}, { 46, 47},
    { 48, 49}, { 50, 51}, { 52, 53}, { 54, 55}, { 56, 57}, { 58, 59}, { 60, 61}, { 62, 63},
    { 64, 65}, { 66, 67}, { 68, 69}, { 70, 71}, { 72, 73}, { 74, 75}, { 76, 77}, { 78, 79},
    { 80, 81}, { 82, 83}, { 84, 85}, { 86, 87}, { 88, 89}, { 90, 91}, { 92, 93}, { 94, 95},
    { 96, 97}, { 98, 99}, {100,101}, {102,103}, {104,105}, {106,107}, {108,109}, {110,111},
    {112,113}, {114,115}, {116,117}, {118,119}, {120,121}, {122,123}, {124,125}, {126,127}, 
    {128, -1}, {129, -1}, {130, -1}, {131, -1}, {132, -1}, {133, -1}, {134, -1}, {135, -1},
    {136, -1}, {137, -1}, {138, -1}, {139, -1}, {140, -1}, {141, -1}, {142, -1}, {143, -1},
    {144, -1}, {145, -1}, {146, -1}, {147, -1}, {148, -1}, {149, -1}, {150, -1}, {151, -1},
    {152, -1}, {153, -1}, {154, -1}, {155, -1}, {156, -1}, {157, -1}, {158, -1}, {159, -1},
    {160, -1}, {161, -1}, {162, -1}, {163, -1}, {164, -1}, {165, -1}, {166, -1}, {167, -1},
    {168, -1}, {169, -1}, {170, -1}, {171, -1}, {172, -1}, {173, -1}, {174, -1}, {175, -1},
    {176, -1}, {177, -1}, {178, -1}, {179, -1}, {180, -1}, {181, -1}, {182, -1}, {183, -1},
    {184, -1}, {185, -1}, {186, -1}, {187, -1}, {188, -1}, {189, -1}, {190, -1}, {191, -1},
    {192, -1}, {193, -1}, {194, -1}, {195, -1}, {196, -1}, {197, -1}, {198, -1}, {199, -1},
    {200, -1}, {201, -1}, {202, -1}, {203, -1}, {204, -1}, {205, -1}, {206, -1}, {207, -1},
    {208, -1}, {209, -1}, {210, -1}, {211, -1}, {212, -1}, {213, -1}, {214, -1}, {215, -1},
    {216, -1}, {217, -1}, {218, -1}, {219, -1}, {220, -1}, {221, -1}, {222, -1}, {223, -1},
    {224, -1}, {225, -1}, {226, -1}, {227, -1}, {228, -1}, {229, -1}, {230, -1}, {231, -1},
    {232, -1}, {233, -1}, {234, -1}, {235, -1}, {236, -1}, {237, -1}, {238, -1}, {239, -1},
    {240, -1}, {241, -1}, {242, -1}, {243, -1}, {244, -1}, {245, -1}, {246, -1}, {247, -1},
    {248, -1}, {249, -1}, {250, -1}, {251, -1}, {252, -1}, {253, -1}, {254, -1}, {255, -1},
    {256, -1}, {257, -1}, {258, -1}, {259, -1}, {260, -1}, {261, -1}, {262, -1}, {263, -1},
    {264, -1}, {265, -1}, {266, -1}, {267, -1}, {268, -1}, {269, -1}, {270, -1}, {271, -1},
    {272, -1}, {273, -1}, {274, -1}, {275, -1}, {276, -1}, {277, -1}, {278, -1}, {279, -1},
    {280, -1}, {281, -1}, {282, -1}, {283, -1}, {284, -1}, {285, -1}, {286, -1}, {287, -1},
};

template<class ENTRIES> static
void write_jbay_checksum_entry(ENTRIES &entry, unsigned mask, int swap, int pov,
                               int id, const char* reg = nullptr) {
    write_checksum_entry(entry, mask, swap, id, reg);
    entry.pov = pov;
}

template<class CSUM, class POV, class ENTRIES>
void write_jbay_checksum_config(CSUM &csum, POV &pov_cfg, ENTRIES &phv_entries, int unit,
        std::vector<Deparser::ChecksumVal> &data, ordered_map<const Phv::Register *, unsigned> &pov) {
    std::map<unsigned, unsigned>        pov_map;
    unsigned byte = 0, mapped[4];
    for (auto &val : data) {
        if (!val.pov) {
            error(val.val.lineno, "POV bit required for jbay");
            continue; }
        unsigned bit = pov.at(&val.pov->reg) + val.pov->lo;
        if (pov_map.count(bit)) continue;
        for (unsigned i = 0; i < byte; ++i) {
            if (pov_cfg.byte_sel[i] == bit/8U) {
                pov_map[bit] = i*8U + bit%8U;
                break; } }
        if (pov_map.count(bit)) continue;
        if (byte == 4) {
            error(val.pov.lineno, "POV bits for checksum %d don't fit in 4 bytes", unit);
            return; }
        pov_map[bit] = byte*8U + bit%8U;
        pov_cfg.byte_sel[byte++] = bit/8U; }

    unsigned tag_idx = 0;
    for (auto &val : data) {
        if (!val.pov) continue;
        int povbit = pov_map.at(pov.at(&val.pov->reg) + val.pov->lo);
        if (val.is_clot()) {
            if (tag_idx == 16)
                error(-1, "Ran out of clot entries in deparser checksum unit %d", unit);
            csum.clot_entry[tag_idx].pov = povbit;
            csum.clot_entry[tag_idx].vld = 1; 
            csum.tags[tag_idx].tag = val.tag;
            tag_idx++;
        } else {
            int mask = val.mask;
            int swap = val.swap;
            auto &remap = jbay_phv2cksum[val->reg.deparser_id()];
            write_jbay_checksum_entry(phv_entries.entry[remap[0]], mask & 3, swap & 1, povbit,
                                              unit, val->reg.name);
            if (remap[1] >= 0)
                write_jbay_checksum_entry(phv_entries.entry[remap[1]], mask >> 2, swap >> 1, povbit,
                                                  unit, val->reg.name);
            else assert((mask >> 2 == 0) && (swap >> 1 == 0));
        }
    }

    // XXX(zma) -- each checksum output can combine any set of checksum units
    // This opens up optimization opportunities where we can selectively
    // combine a set of header checksums depending which ones are valid in
    // the packet.
    csum.phv_entry[unit].pov = pov_map.begin()->second;
    csum.phv_entry[unit].vld = 1;

    // FIXME -- use/set csum.csum_constant and csum.zeros_as_ones?
}

template<class CONS>
void write_jbay_constant_config(CONS &cons, const std::set<int> &vals) {
    unsigned idx = 0;
    for (auto v : vals) {
        cons[idx] = v;
        idx++; }
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

    for (auto &r : regs.dprsrreg.ho_i)
        write_jbay_constant_config(r.hir.h.hdr_xbar_const.value, constants[INGRESS]);
    for (auto &r : regs.dprsrreg.ho_e)
        write_jbay_constant_config(r.her.h.hdr_xbar_const.value, constants[EGRESS]);

    for (int i = 0; i < Target::JBay::DEPARSER_CHECKSUM_UNITS; i++) {
        if (!checksum[INGRESS][i].empty()) {
            regs.dprsrreg.inp.ipp.phv_csum_pov_cfg.thread.thread[i] = INGRESS;
            write_jbay_checksum_config(regs.dprsrreg.inp.icr.csum_engine[i],
                regs.dprsrreg.inp.ipp.phv_csum_pov_cfg.csum_pov_cfg[i],
                regs.dprsrreg.inp.ipp_m.i_csum.engine[i], i, checksum[INGRESS][i], pov[INGRESS]);
            if (!checksum[EGRESS][i].empty()) {
                error(checksum[INGRESS][i][0].lineno, "checksum %d used in both ingress", i);
                error(checksum[EGRESS][i][0].lineno, "...and egress"); }
        } else if (!checksum[EGRESS][i].empty()) {
            regs.dprsrreg.inp.ipp.phv_csum_pov_cfg.thread.thread[i] = EGRESS;
            write_jbay_checksum_config(regs.dprsrreg.inp.icr.csum_engine[i],
               regs.dprsrreg.inp.ipp.phv_csum_pov_cfg.csum_pov_cfg[i],
               regs.dprsrreg.inp.ipp_m.i_csum.engine[i], i, checksum[EGRESS][i], pov[EGRESS]); } }

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
        warning(lineno[INGRESS], "Registers used in both ingress and egress in pipeline: %s",
                Phv::db_regset(Phv::use(INGRESS) & Phv::use(EGRESS)).c_str());
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

#define DISBALE_IF_NOT_SET(ISARRAY, ARRAY, REGS, DISABLE) \
    ISARRAY(for (auto &r : ARRAY)) if (!ISARRAY(r.)REGS.modified()) ISARRAY(r.)REGS.DISABLE = 1;
    JBAY_DISABLE_REGBITS(DISBALE_IF_NOT_SET)

    if (options.condense_json)
        regs.disable_if_reset_value();
    if (error_count == 0 && options.gen_json)
        regs.emit_json(*open_output("regs.deparser.cfg.json"));
    TopLevel::regs<Target::JBay>()->reg_pipe.pardereg.dprsrreg.set("regs.deparser", &regs);
}

#if 0
namespace {
static struct JbayChecksumReg : public Phv::Register {
    JbayChecksumReg(int unit) : Phv::Register("", Phv::Register::CHECKSUM, unit, unit+232, 16) {
        sprintf(name, "csum%d", unit); }
    int deparser_id() const override { return uid; }
} jbay_checksum_units[8] = { {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7} };
}

template<> Phv::Slice Deparser::RefOrChksum::lookup<Target::JBay>() const {
    if (lo != hi || lo < 0 || lo >= Target::JBay::DEPARSER_CHECKSUM_UNITS) {
        error(lineno, "Invalid checksum unit number");
        return Phv::Slice(); }
    return Phv::Slice(tofino_checksum_units[lo], 0, 15);
}
#endif

template<> unsigned Deparser::FDEntry::Checksum::encode<Target::JBay>() {
    return 232 + unit;
}

template<> unsigned Deparser::FDEntry::Constant::encode<Target::JBay>() {
    return 224 + Deparser::constant_idx(gress, val);
}

template<> void Deparser::gen_learn_quanta(Target::JBay::parser_regs &regs, json::vector &learn_quanta) {
}
