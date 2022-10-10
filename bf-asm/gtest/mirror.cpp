#include "gtest/gtest.h"

#include "deparser.h"
#include "sections.h"

namespace {

/* Tests for mirror
 *
 * Currently we cannot run tests for multiple targets (e.g., Tofino and JBay)
 * in a single run. As a result, all tests except Tofino are disabled.
 */

#define TOF_MIRR_CFG regs.header.hir.main_i.mirror_cfg
#define TOF_MIRR_TBL regs.header.hir.main_i.mirror_tbl

#define JBAY_MIRR_BASE regs.dprsrreg.ho_i
#define JBAY_MIRR_ENTRY him.mirr_hdr_tbl.entry
#define JBAY_MIRR_SEL regs.dprsrreg.inp.ipp.ingr.m_mirr_sel

#define FTR_MDP_MIRR_BASE regs.mdp_mem.tmm_ext_ram.tmm_ext[0]
#define FTR_DPRSR_MIRR_BASE regs.dprsr.dprsr_phvxb_rspec.ehm_xb

/// Mirror configuration for Tofino
struct TofinoMirrorCfg {
    std::string sel_phv_;
    int sel_phv_lo_;

    std::map<int, std::string> entry_id_phv;
    std::map<int, std::vector<std::string>> entry_phvs;

    TofinoMirrorCfg(std::string sel_phv, int sel_phv_lo)
        : sel_phv_(sel_phv), sel_phv_lo_(sel_phv_lo) {}
};

/// Mirror configuration for JBay
struct JBayMirrorCfg {
    std::string sel_phv_;
    int sel_phv_lo_;

    std::string sel_pov_;
    int sel_pov_lo_;

    std::map<int, std::string> entry_id_phv;
    std::map<int, std::vector<std::string>> entry_phvs;

    JBayMirrorCfg(std::string sel_phv, int sel_phv_lo, std::string sel_pov, int sel_pov_lo)
        : sel_phv_(sel_phv), sel_phv_lo_(sel_phv_lo), sel_pov_(sel_pov), sel_pov_lo_(sel_pov_lo) {}
};

#if HAVE_FLATROCK
/// Ingress mirror configuration for Flatrock
struct FlatrockIngMirrorCfg {
    std::string bmp_b0_phv_;
    std::string bmp_b1_phv_;
    int bmp_phv_lo_;

    std::string cos_phv_;
    int cos_phv_lo_;

    FlatrockIngMirrorCfg(std::string bmp_b0_phv, std::string bmp_b1_phv, int bmp_phv_lo,
                      std::string cos_phv, int cos_phv_lo)
        : bmp_b0_phv_(bmp_b0_phv),
          bmp_b1_phv_(bmp_b1_phv),
          bmp_phv_lo_(bmp_phv_lo),
          cos_phv_(cos_phv),
          cos_phv_lo_(cos_phv_lo) {}
};

struct FlatrockEgMirrorCfg {
    std::string sel_phv_;
    int sel_phv_lo_;

    std::string sel_pov_;
    int sel_pov_lo_;

    std::string io_sel_phv_;
    int io_sel_phv_lo_;

    std::map<int, std::vector<std::string>> entry_phvs;

    FlatrockEgMirrorCfg(std::string sel_phv, int sel_phv_lo, std::string sel_pov, int sel_pov_lo,
                        std::string io_sel_phv, int io_sel_phv_lo)
        : sel_phv_(sel_phv),
          sel_phv_lo_(sel_phv_lo),
          sel_pov_(sel_pov),
          sel_pov_lo_(sel_pov_lo),
          io_sel_phv_(io_sel_phv),
          io_sel_phv_lo_(io_sel_phv_lo) {}
};

#endif  /* HAVE_FLATROCK */

/// Map from register name to Phv::Register*
std::map<std::string, const Phv::Register*> phvRegs;

/// Populate register name -> register map
void populateRegIds() {
    if (!phvRegs.size()) {
        // Initialize the PHVs.
        // Triggered by requesting a slice for a field. The field does not need to exist.
        Phv::get(INGRESS, 0, "jbay_dummy$");

        // Walk through the registers and record them
        for (int i = 0; i < Phv::num_regs(); ++i) {
            if (const auto* reg = Phv::reg(i)) phvRegs[reg->name] = reg;
        }
    }
}

/// Get the MAU ID of a given register name
int mau_id(std::string name) {
    return phvRegs.count(name) ? phvRegs.at(name)->mau_id() : -1;
}

/// Get the deparser ID of a given register name
int deparser_id(std::string name) {
    return phvRegs.count(name) ? phvRegs.at(name)->deparser_id() : -1;
}

/// Find a Digest for a given target
Deparser::Digest* findDigest(Deparser* dprsr, target_t target) {
    for (auto& digest : dprsr->digests) {
        if (digest.type->target == target) return &digest;
    }

    BUG("Could not find the Digest for %s", toString(target).c_str());
    return nullptr;
}

/** Reset all target information
 *
 * This function should be called when switching from one target to another
 * (e.g., Tofino to JBay) in tests to reset state.
 */
void resetTarget() {
    options.target = NO_TARGET;
    Phv::test_clear();
    phvRegs.clear();
    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    dprsr->gtest_clear();
}

/// Verify that registers match a mirror configuration (Tofino)
void tofinoCheckMirrorRegs(Target::Tofino::deparser_regs& regs, TofinoMirrorCfg& cfg) {
    populateRegIds();

    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    auto* digest = findDigest(dprsr, TOFINO);

    // Tell the digest code to set the registers
    digest->type->setregs(regs, *dprsr, *digest);

    // Verify the registers:
    // 1. Verify common registers
    EXPECT_EQ(TOF_MIRR_CFG.phv, deparser_id(cfg.sel_phv_));
    EXPECT_EQ(TOF_MIRR_CFG.shft, cfg.sel_phv_lo_);
    EXPECT_EQ(TOF_MIRR_CFG.valid, 1);

    // 2. Verify the entries
    for (auto& kv : cfg.entry_id_phv) {
        int id = kv.first;
        EXPECT_EQ(TOF_MIRR_TBL[id].id_phv, deparser_id(cfg.entry_id_phv[id]));
        int idx = 0;
        for (auto& phv : cfg.entry_phvs[id]) {
            EXPECT_EQ(TOF_MIRR_TBL[id].phvs[idx], deparser_id(phv));
            idx++;
        }
        EXPECT_EQ(TOF_MIRR_TBL[id].len, cfg.entry_phvs[id].size());
    }
}

/// Verify that registers match a mirror configuration (JBay)
void jbayCheckMirrorRegs(Target::JBay::deparser_regs& regs, JBayMirrorCfg& cfg) {
    // Base index for POV PHV. Want this to be non-zero.
    const int povBase = 64;

    populateRegIds();

    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    auto* digest = findDigest(dprsr, JBAY);

    // Ensure the POV register in the config is actually recorded as a POV in
    // the deparser object
    int povReg = mau_id(cfg.sel_pov_);
    dprsr->pov[INGRESS][Phv::reg(povReg)] = povBase;

    // Tell the digest code to set the registers
    digest->type->setregs(regs, *dprsr, *digest);

    // Verify the registers:
    // 1. Verify common registers
    EXPECT_EQ(JBAY_MIRR_SEL.phv, deparser_id(cfg.sel_phv_));
    EXPECT_EQ(JBAY_MIRR_SEL.pov, povBase + cfg.sel_pov_lo_);
    EXPECT_EQ(JBAY_MIRR_SEL.shft, cfg.sel_phv_lo_);
    EXPECT_EQ(JBAY_MIRR_SEL.disable_, 0);

    // 2. Verify the entries
    for (auto& base : JBAY_MIRR_BASE) {
        for (auto& kv : cfg.entry_id_phv) {
            int id = kv.first;
            EXPECT_EQ(base.JBAY_MIRR_ENTRY[id].id_phv, deparser_id(cfg.entry_id_phv[id]));
            int idx = 0;
            for (auto& phv : cfg.entry_phvs[id]) {
                EXPECT_EQ(base.JBAY_MIRR_ENTRY[id].phvs[idx], deparser_id(phv));
                idx++;
            }
            EXPECT_EQ(base.JBAY_MIRR_ENTRY[id].len, cfg.entry_phvs[id].size());
        }
    }
}

#if HAVE_FLATROCK
/// Verify that registers match a mirror configuration (Flatrock)
void flatrockCheckIngMirrorRegs(Target::Flatrock::deparser_regs& regs, FlatrockIngMirrorCfg& cfg) {
    populateRegIds();

    // Verify the registers:
    EXPECT_EQ(FTR_MDP_MIRR_BASE.phv_n_b0_mrr_bmp, deparser_id(cfg.bmp_b0_phv_));
    EXPECT_EQ(FTR_MDP_MIRR_BASE.phv_n_b1_mrr_bmp,
              deparser_id(cfg.bmp_b1_phv_) + (cfg.bmp_b0_phv_ == cfg.bmp_b1_phv_));
    EXPECT_EQ(FTR_MDP_MIRR_BASE.mrr_bmp_shft, cfg.bmp_phv_lo_);

    EXPECT_EQ(FTR_MDP_MIRR_BASE.phv_n_mrr_cos, deparser_id(cfg.cos_phv_));
    EXPECT_EQ(FTR_MDP_MIRR_BASE.mrr_cos_shft, cfg.cos_phv_lo_);
}

void flatrockCheckEgMirrorRegs(Deparser* deparser, Target::Flatrock::deparser_regs& regs,
                               FlatrockEgMirrorCfg& cfg) {
    populateRegIds();

    // Verify the registers:
    // 1. Verify common registers
    EXPECT_TRUE(phvRegs.count(cfg.sel_phv_));
    const auto* sel_reg = phvRegs.at(cfg.sel_phv_);
    EXPECT_TRUE(deparser->pov[EGRESS].count(sel_reg));
    EXPECT_EQ(FTR_DPRSR_MIRR_BASE.pov_key_sel.pov_byte[0], deparser->pov[EGRESS].at(sel_reg) / 8);

    EXPECT_TRUE(phvRegs.count(cfg.sel_pov_));
    const auto* sel_pov_reg = phvRegs.at(cfg.sel_pov_);
    EXPECT_TRUE(deparser->pov[EGRESS].count(sel_pov_reg));
    int sel_pov_bit = deparser->pov[EGRESS].at(sel_pov_reg) + cfg.sel_pov_lo_;

    // 2. Verify the entries
    int idx = 0;
    for (auto& kv : cfg.entry_phvs) {
        int id = kv.first;
        const auto& phvs = kv.second;

        EXPECT_EQ((FTR_DPRSR_MIRR_BASE.key[idx].key_wl >> cfg.sel_phv_lo_) & 0xf, id);
        EXPECT_EQ(((~FTR_DPRSR_MIRR_BASE.key[idx].key_wh) >> cfg.sel_phv_lo_) & 0xf, id);

        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_en_phes, deparser_id(cfg.sel_pov_));
        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_en_sel, 1);
        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_en_dflt, 0);
        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_en_shft, cfg.sel_pov_lo_);

        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_src_phes, deparser_id(cfg.io_sel_phv_));
        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_src_sel, 1);
        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_src_dflt, 0);
        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_src_shft, cfg.io_sel_phv_lo_);

        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.pld_len_cfg[idx].ehm_pld_len_phes, 0);
        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.pld_len_cfg[idx].ehm_pld_len_pov0, sel_pov_bit);
        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.pld_len_cfg[idx].ehm_pld_len_pov1, sel_pov_bit);
        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.pld_len_cfg[idx].ehm_pld_len_sel, 0);
        EXPECT_EQ(FTR_DPRSR_MIRR_BASE.pld_len_cfg[idx].ehm_pld_len_dflt, 256);

        if (phvs.size()) {
            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_ehm_phes, 0);
            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_ehm_sel, 0);
            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_ehm_dflt, 1);
            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_ehm_shft, 0);

            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.hdr_len_cfg[idx].ehm_hdr_len_phes, 0);
            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.hdr_len_cfg[idx].ehm_hdr_len_pov0, sel_pov_bit);
            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.hdr_len_cfg[idx].ehm_hdr_len_pov1, sel_pov_bit);
            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.hdr_len_cfg[idx].ehm_hdr_len_sel, 0);
            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.hdr_len_cfg[idx].ehm_hdr_len_dflt, phvs.size());

            for (int i = 0; i < phvs.size(); ++i) {
                EXPECT_EQ(FTR_DPRSR_MIRR_BASE.data[idx][i / 4].phe[i % 4], deparser_id(phvs[i]));
            }
        } else {
            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_ehm_phes, 0);
            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_ehm_sel, 0);
            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_ehm_dflt, 0);
            EXPECT_EQ(FTR_DPRSR_MIRR_BASE.mirr_cfg[idx].mirr_ehm_shft, 0);
        }

        idx++;
    }

    // EXPECT_EQ(FTR_MDP_MIRR_BASE.phv_n_mrr_cos, deparser_id(cfg.cos_phv_));
    // EXPECT_EQ(FTR_MDP_MIRR_BASE.mrr_cos_shft, cfg.cos_phv_lo_);
}
#endif  /* HAVE_FLATROCK */

TEST(mirror, digest_tofino) {
    const char* mirror_str = R"MIRR_CFG(
version:
  target: Tofino
deparser ingress:
  mirror:
    select: B9(0..3)  # bit[3..0]: ingress::ig_intr_md_for_dprsr.mirror_type
    1:
      - H19(0..7)  # bit[7..0]: ingress::Thurmond.Circle.LaUnion[7:0].0-7
      - B9  # ingress::Thurmond.Longwood.Matheson
      - B9  # ingress::Thurmond.Longwood.Matheson
      - H56(0..8)  # bit[8..0]: ingress::Thurmond.Armagh.Moorcroft
)MIRR_CFG";

    resetTarget();

    auto* digest = ::get(Deparser::Digest::Type::all[TOFINO][INGRESS], "mirror");
    ASSERT_NE(digest, nullptr) << "Unable to find the mirror digest";

    Target::Tofino::deparser_regs regs;
    asm_parse_string(mirror_str);

    TofinoMirrorCfg mirrorCfg("B9", 0);
    mirrorCfg.entry_id_phv[1] = "H19";
    mirrorCfg.entry_phvs[1] = {"B9", "B9", "H56", "H56"};
    tofinoCheckMirrorRegs(regs, mirrorCfg);
}

TEST(mirror, digest_jbay) {
    const char* mirror_str = R"MIRR_CFG(
version:
  target: Tofino2
deparser ingress:
  mirror:
    select: { B9(0..3): B8(1) }  # bit[3..0]: ingress::ig_intr_md_for_dprsr.mirror_type
    1:
      - H19(0..7)  # bit[7..0]: ingress::Thurmond.Circle.LaUnion[7:0].0-7
      - B9  # ingress::Thurmond.Longwood.Matheson
      - B9  # ingress::Thurmond.Longwood.Matheson
      - H56(0..8)  # bit[8..0]: ingress::Thurmond.Armagh.Moorcroft
)MIRR_CFG";

    resetTarget();

    auto* digest = ::get(Deparser::Digest::Type::all[JBAY][INGRESS], "mirror");
    ASSERT_NE(digest, nullptr) << "Unable to find the mirror digest";

    Target::JBay::deparser_regs regs;
    asm_parse_string(mirror_str);

    JBayMirrorCfg mirrorCfg("B9", 0, "B8", 1);
    mirrorCfg.entry_id_phv[1] = "H19";
    mirrorCfg.entry_phvs[1] = {"B9", "B9", "H56", "H56"};
    jbayCheckMirrorRegs(regs, mirrorCfg);
}

#if HAVE_FLATROCK
TEST(mirror, ingress_flatrock) {
    const char* mirror_str = R"MIRR_CFG(
version:
  target: Tofino5
deparser ingress:
  mirror_bitmap: W1(0..15)  # bit[15..0]: ig_intr_md_for_tm.mirror_bitmap
  mirr_icos: H1(1..3)
  valid_vec: [B0(0..6), B1]
      # B0(0..6):
      # - bit[6]: ig_intr_md_for_tm.icrc_enable
      # - bit[5]: ig_intr_md_for_tm.drop
      # - bit[4]: ig_intr_md_for_tm.pgen_trig_vld
      # - bit[3]: ig_intr_md_for_tm.iafc_vld
      # - bit[2]: ig_intr_md_for_tm.lq_vld
      # - bit[1]: ig_intr_md_for_tm.pkt_expan_idx_vld
      # - bit[0]: ig_intr_md_for_tm.ucast_egress_port.$valid
      # B1:
      # - bit[7]: ig_intr_md_for_tm.mcast_grp_b.$valid
      # - bit[6]: ig_intr_md_for_tm.mcast_grp_a.$valid
      # - bit[5]: ig_intr_md_for_tm.mirror_bitmap.$valid
      # - bit[4]: ig_intr_md_for_tm.copy_to_cpu
      # - bit[3]: ig_intr_md_for_tm.perfect_hash_table_id
      # - bit[2]: ig_intr_md_for_tm.enable_mcast_cutthru
      # - bit[1]: ig_intr_md_for_tm.disable_ucast_cutthru
      # - bit[0]: ig_intr_md_for_tm.deflect_on_drop
)MIRR_CFG";

    resetTarget();

    asm_parse_string(mirror_str);

    Target::Flatrock::deparser_regs regs;
    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    dprsr->process();
    dprsr->write_config(regs);

    FlatrockIngMirrorCfg mirrorCfg("W1", "W1", 0, "H1", 1);
    flatrockCheckIngMirrorRegs(regs, mirrorCfg);
}

TEST(mirror, digest_egress_flatrock) {
    const char* mirror_str = R"MIRR_CFG(
version:
  target: Tofino5
deparser egress:
  mirr_io_sel: B3(1..1)  # bit[1]: eg_intr_md_for_dprsr.mirror_io_select
  mirror:
    select: { B4(0..3): B3(0) }  # bit[3..0]: eg_intr_md_for_dprs.mirror_type
    1:
      - B6  # meta.mirr_sess_id

  ## == Currently unhandled fields ==
  # mirr_hash: H1(1..14)
  # mirr_epipe_port: H2(9..15)
  # mirr_qid: H3(3..9)
  # mirr_dond_ctrl: B5(3..3)
  # mirr_icos: B5(4..6)
  # mirr_mc_ctrl: B5(7)
)MIRR_CFG";

    resetTarget();

    auto* digest = ::get(Deparser::Digest::Type::all[FLATROCK][EGRESS], "mirror");
    ASSERT_NE(digest, nullptr) << "Unable to find the mirror digest";

    asm_parse_string(mirror_str);

    Target::Flatrock::deparser_regs regs;
    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    dprsr->process();
    dprsr->write_config(regs);

    FlatrockEgMirrorCfg mirrorCfg("B4", 0, "B3", 0, "B3", 1);
    mirrorCfg.entry_phvs[1] = {"B6"};
    flatrockCheckEgMirrorRegs(dprsr, regs, mirrorCfg);
}

#endif  /* HAVE_FLATROCK */

}  // namespace
