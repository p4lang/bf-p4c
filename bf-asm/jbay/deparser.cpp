/* deparser template specializations for jbay -- #included directly in top-level deparser.cpp */

#define STUB_JBAY_DEPARSER_INTRINSIC(GR, NAME, MAX) \
template<> void INTRIN##GR##NAME::setregs(Target::JBay::deparser_regs &, \
                                          std::vector<Phv::Ref> &) { assert(0); }
#define STUB_JBAY_DEPARSER_DIGEST(GR, NAME, MAX) \
void GR##NAME##Digest::init(Target::JBay) {} \
template<> void GR##NAME##Digest::setregs(Target::JBay::deparser_regs &, \
                                          Deparser::Digest &) { assert(0); }

ALL_DEPARSER_INTRINSICS(STUB_JBAY_DEPARSER_INTRINSIC)
ALL_DEPARSER_DIGESTS(STUB_JBAY_DEPARSER_DIGEST)

template<> void Deparser::write_config(Target::JBay::deparser_regs &regs) {
    ERROR("JBay deparser support not yet implemented in master branch");
#if 0
    // FIXME -- this is the tofino code -- needs to be updated to jbay
    regs.input.icr.inp_cfg.disable();
    regs.input.icr.intr.disable();
    regs.header.hem.he_edf_cfg.disable();
    regs.header.him.hi_edf_cfg.disable();
    dump_checksum_units(regs.input.iim.ii_phv_csum.csum_cfg, regs.header.him.hi_tphv_csum.csum_cfg,
                        INGRESS, checksum[INGRESS]);
    dump_checksum_units(regs.input.iem.ie_phv_csum.csum_cfg, regs.header.hem.he_tphv_csum.csum_cfg,
                        EGRESS, checksum[EGRESS]);
    dump_field_dictionary(regs.input.iim.ii_fde_pov.fde_pov, regs.header.him.hi_fde_phv.fde_phv,
        regs.input.iir.main_i.pov.phvs, pov_order[INGRESS], dictionary[INGRESS]);
    dump_field_dictionary(regs.input.iem.ie_fde_pov.fde_pov, regs.header.hem.he_fde_phv.fde_phv,
        regs.input.ier.main_e.pov.phvs, pov_order[EGRESS], dictionary[EGRESS]);

    if (Phv::use(INGRESS).intersects(Phv::use(EGRESS))) {
        warning(lineno[INGRESS], "Registers used in both ingress and egress in pipeline: %s",
                Phv::db_regset(phv_use[INGRESS] & phv_use[EGRESS]).c_str());
        /* FIXME -- this only (sort-of) works because 'deparser' comes first in the alphabet,
         * FIXME -- so is the first section to have its 'output' method run.  Its a hack
         * FIXME -- anyways to attempt to correct broken asm that should be an error */
        Phv::unsetuse(INGRESS, phv_use[EGRESS]);
        Phv::unsetuse(EGRESS, phv_use[INGRESS]);
    }

    output_phv_ownership(phv_use, regs.input.iir.ingr.phv8_grp, regs.input.iir.ingr.phv8_split,
                         regs.input.ier.egr.phv8_grp, regs.input.ier.egr.phv8_split,
                         FIRST_8BIT_PHV, COUNT_8BIT_PHV);
    output_phv_ownership(phv_use, regs.input.iir.ingr.phv16_grp, regs.input.iir.ingr.phv16_split,
                         regs.input.ier.egr.phv16_grp, regs.input.ier.egr.phv16_split,
                         FIRST_16BIT_PHV, COUNT_16BIT_PHV);
    output_phv_ownership(phv_use, regs.input.iir.ingr.phv32_grp, regs.input.iir.ingr.phv32_split,
                         regs.input.ier.egr.phv32_grp, regs.input.ier.egr.phv32_split,
                         FIRST_32BIT_PHV, COUNT_32BIT_PHV);

    for (unsigned i = 0; i < 8; i++) {
        if (phv_use[EGRESS].intersects(Phv::tagalong_groups[i])) {
            regs.input.icr.tphv_cfg.i_e_assign |= 1 << i;
            if (phv_use[INGRESS].intersects(Phv::tagalong_groups[i])) {
                error(lineno[INGRESS], "tagalong group %d used in both ingress and "
                      "egress deparser", i); } } }

    for (auto &intrin : intrinsics)
        intrin.first->setregs(regs, intrin.second);
    if (!regs.header.hir.ingr.ingress_port.sel.modified())
        regs.header.hir.ingr.ingress_port.sel = 1;

    for (auto &digest : digests)
        digest.type->setregs(regs, digest);

    if (options.condense_json) {
        regs.input.disable_if_zero();
        regs.header.disable_if_zero(); }
    regs.input.emit_json(*open_output("regs.all.deparser.input_phase.cfg.json"));
    regs.header.emit_json(*open_output("regs.all.deparser.header_phase.cfg.json"));
    TopLevel::all.reg_pipe.deparser.hdr = "regs.all.deparser.header_phase";
    TopLevel::all.reg_pipe.deparser.inp = "regs.all.deparser.input_phase";
#endif
}
