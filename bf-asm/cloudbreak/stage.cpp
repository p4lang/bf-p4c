
/* mau stage template specializations for cloudbreak -- #included directly in top-level stage.cpp */


template<>
void Stage::gen_configuration_cache(Target::Cloudbreak::mau_regs &regs, json::vector &cfg_cache) {
    Stage::gen_configuration_cache_common(regs, cfg_cache);

    static unsigned i_pdddelay;
    static unsigned e_pdddelay;
    unsigned reg_width = 8;  // this means number of hex characters
    std::string i_reg_value_str;
    std::string e_reg_value_str;
    std::string reg_fqname;
    std::string reg_name;
    unsigned reg_value;
    std::string reg_value_str;

    if (stageno != 0) {
        if (i_pdddelay > regs.cfg_regs.amod_pre_drain_delay[INGRESS])
            i_pdddelay = regs.cfg_regs.amod_pre_drain_delay[INGRESS];
        if (e_pdddelay > regs.cfg_regs.amod_pre_drain_delay[EGRESS])
            e_pdddelay = regs.cfg_regs.amod_pre_drain_delay[EGRESS];

        if (stageno == AsmStage::numstages()-1) {
            // 64 is due to number of CSR's
            i_pdddelay += (7 + 64);
            i_reg_value_str = int_to_hex_string(i_pdddelay, reg_width);
            e_pdddelay += (7 + 64);
            e_reg_value_str = int_to_hex_string(e_pdddelay, reg_width);

            add_cfg_reg(cfg_cache, "pardereg.pgstnreg.parbreg.left.i_wb_ctrl",
                "left_i_wb_ctrl", i_reg_value_str);
            add_cfg_reg(cfg_cache, "pardereg.pgstnreg.parbreg.right.e_wb_ctrl",
                "right_e_wb_ctrl", e_reg_value_str);
        }
    }

    // meter_ctl
    auto &meter_ctl = regs.rams.map_alu.meter_group;
    for (int i = 0; i < 4; i++) {
        reg_fqname = "mau[" + std::to_string(stageno)
            + "].rams.map_alu.meter_group["
            + std::to_string(i) + "]"
            + ".meter.meter_ctl";
        reg_name = "stage_" + std::to_string(stageno) + "_meter_ctl_" + std::to_string(i);
        reg_value = (meter_ctl[i].meter.meter_ctl.meter_bytecount_adjust       & 0x00003FFF)
                 | ((meter_ctl[i].meter.meter_ctl.meter_byte                   & 0x00000001) << 14)
                 | ((meter_ctl[i].meter.meter_ctl.meter_enable                 & 0x00000001) << 15)
                 | ((meter_ctl[i].meter.meter_ctl.lpf_enable                   & 0x00000001) << 16)
                 | ((meter_ctl[i].meter.meter_ctl.red_enable                   & 0x00000001) << 17)
                 | ((meter_ctl[i].meter.meter_ctl.meter_alu_egress             & 0x00000001) << 18)
                 | ((meter_ctl[i].meter.meter_ctl.meter_rng_enable             & 0x00000001) << 19)
                 | ((meter_ctl[i].meter.meter_ctl.meter_time_scale             & 0x0000000F) << 20)
                 | ((meter_ctl[i].meter.meter_ctl.meter_lpf_sat_ctl            & 0x0000000F) << 24)
                 | ((meter_ctl[i].meter.meter_ctl.meter_lpf_virtual_access_ctl & 0x0000000F) << 25);

        if ((reg_value != 0) || (options.match_compiler)) {
            reg_value_str = int_to_hex_string(reg_value, reg_width);
            add_cfg_reg(cfg_cache, reg_fqname, reg_name, reg_value_str); }
    }
}

template<> void Stage::write_regs(Target::Cloudbreak::mau_regs &regs) {
    write_common_regs<Target::Cloudbreak>(regs);
    auto &merge = regs.rams.match.merge;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (stageno == 0) {
            merge.predication_ctl[gress].start_table_fifo_delay0 = pred_cycle(gress) - 2;
            merge.predication_ctl[gress].start_table_fifo_enable = 1;
        } else if (stage_dep[gress] == MATCH_DEP) {
            merge.predication_ctl[gress].start_table_fifo_delay0 =
                this[-1].pipelength(gress) - this[-1].pred_cycle(gress) + pred_cycle(gress) - 3;
            merge.predication_ctl[gress].start_table_fifo_enable = 1;
        } else {
            BUG_CHECK(stage_dep[gress] == ACTION_DEP);
            merge.predication_ctl[gress].start_table_fifo_delay0 = 0;
            merge.predication_ctl[gress].start_table_fifo_enable = 0; }

        if (stageno != 0)
            regs.dp.cur_stage_dependency_on_prev[gress] = stage_dep[gress] != MATCH_DEP;

        /* set stage0 dependency if explicitly set by the commandline option */
        if (stageno == 0 && !options.stage_dependency_pattern.empty())
            regs.dp.cur_stage_dependency_on_prev[gress] = stage_dep[gress] != MATCH_DEP;

        if (stageno != AsmStage::numstages()-1)
            regs.dp.next_stage_dependency_on_cur[gress] = this[1].stage_dep[gress] != MATCH_DEP;
        else if (AsmStage::numstages() < Target::NUM_MAU_STAGES())
            regs.dp.next_stage_dependency_on_cur[gress] = 1;
        auto &deferred_eop_bus_delay = regs.rams.match.adrdist.deferred_eop_bus_delay[gress];
        deferred_eop_bus_delay.eop_internal_delay_fifo = pred_cycle(gress) + 2;
        /* FIXME -- making this depend on the dependency of the next stage seems wrong */
        if (stageno == AsmStage::numstages()-1) {
            if (AsmStage::numstages() < Target::NUM_MAU_STAGES())
                deferred_eop_bus_delay.eop_output_delay_fifo = 1;
            else
                deferred_eop_bus_delay.eop_output_delay_fifo = pipelength(gress) - 2;
        } else if (this[1].stage_dep[gress] == MATCH_DEP)
            deferred_eop_bus_delay.eop_output_delay_fifo = pipelength(gress) - 2;
        else
            deferred_eop_bus_delay.eop_output_delay_fifo = 1;
        deferred_eop_bus_delay.eop_delay_fifo_en = 1;
        if (stageno != AsmStage::numstages()-1 && this[1].stage_dep[gress] == MATCH_DEP)
            merge.mpr_thread_delay[gress] = pipelength(gress) - pred_cycle(gress) - 4;
        else {
            /* last stage in Cloudbreak must be always set as match-dependent on deparser */
            if (stageno == AsmStage::numstages()-1) {
                merge.mpr_thread_delay[gress] = pipelength(gress) - pred_cycle(gress) - 4;
            } else {
                merge.mpr_thread_delay[gress] = 0;
            }
        }
    }

    for (gress_t gress : Range(INGRESS, EGRESS)) {
        regs.cfg_regs.amod_pre_drain_delay[gress] = pipelength(gress) - 9;
        if (this[1].stage_dep[gress] == MATCH_DEP)
            regs.cfg_regs.amod_wide_bubble_rsp_delay[gress] = pipelength(gress) - 3;
        else
            regs.cfg_regs.amod_wide_bubble_rsp_delay[gress] = 0;
    }
    /* Max re-request limit with a long interval.  Parb is going to have a large
     * gap configured to minimize traffic hits during configuration this means
     * that individual stages may not get their bubbles and will need to retry. */
    regs.cfg_regs.amod_req_interval = 6732;
    regs.cfg_regs.amod_req_limit = 15;



    if (stageno == 0) {
        /* MFerrera: "After some debug on the emulator, we've found a programming issue due to
        * incorrect documentation and CSR description of match_ie_input_mux_sel in JBAY"
        * MAU Stage 0 must always be configured to source iPHV from Parser-Arbiter
        * Otherwise, MAU stage 0 is configured as match-dependent on Parser-Arbiter */
        regs.dp.match_ie_input_mux_sel |= 3;
    }

    merge.pred_stage_id = stageno;
    if (long_branch_terminate)
        merge.pred_long_brch_terminate = long_branch_terminate;
    for (gress_t gress : Range(INGRESS, GHOST)) {
        merge.mpr_stage_id[gress] = stageno;
        if (long_branch_thread[gress])
            merge.pred_long_brch_thread[gress] = long_branch_thread[gress];
    }

    merge.mpr_long_brch_thread = long_branch_thread[EGRESS];
    if (auto conflict = (long_branch_thread[INGRESS] | long_branch_thread[GHOST])
                        & long_branch_thread[EGRESS]) {
        // Should probably check this earlier, but there's not a good place to do it.
        for (auto tag : bitvec(conflict)) {
            error(long_branch_use[tag]->lineno, "Need one-stage turnaround before reusing "
                  "long_branch tag %d in a different thread", tag); } }

    if (stageno != AsmStage::numstages()-1) {
        merge.mpr_bus_dep.mpr_bus_dep_egress = this[1].stage_dep[EGRESS] != MATCH_DEP;
        merge.mpr_bus_dep.mpr_bus_dep_ingress = this[1].stage_dep[INGRESS] != MATCH_DEP;
        for (auto *tbl : this[1].tables)
            if (this[1].stage_dep[timing_thread(tbl->gress)] != MATCH_DEP)
                merge.mpr_bus_dep.mpr_bus_dep_glob_exec |= 1 << tbl->logical_id;
        for (gress_t gress : Range(INGRESS, GHOST)) {
            if (this[1].stage_dep[timing_thread(gress)] != MATCH_DEP)
                merge.mpr_bus_dep.mpr_bus_dep_long_brch |= this[1].long_branch_thread[gress]; } }

    bitvec in_use = match_use[INGRESS] | action_use[INGRESS] | action_set[INGRESS];
    bitvec eg_use = match_use[EGRESS] | action_use[EGRESS] | action_set[EGRESS];
    /* FIXME -- if the regs are live across a stage (even if not used in that stage) they
     * need to be set in the thread registers.  For now we just assume if they are used
     * anywhere, they need to be marked as live */
    in_use |= Phv::use(INGRESS);
    eg_use |= Phv::use(EGRESS);
    static const int phv_use_transpose[2][14] = {
        {  0,  1,  2,  3,  8,  9, 10, 11, 16, 17, 18, 19, 20, 21 },
        {  4,  5,  6,  7, 12, 13, 14, 15, 22, 23, 24, 25, 26, 27 } };
    // FIXME -- this code depends on the Phv::Register uids matching the
    // FIXME -- mau encoding of phv containers. (FIXME-PHV)
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 14; j++) {
            regs.dp.phv_ingress_thread[i][j] = regs.dp.phv_ingress_thread_imem[i][j] =
                in_use.getrange(10*phv_use_transpose[i][j], 10);
            regs.dp.phv_egress_thread[i][j] = regs.dp.phv_egress_thread_imem[i][j] =
                eg_use.getrange(10*phv_use_transpose[i][j], 10); } }

    /* Things following are for debug/bringup only : not for normal flows  */

    if (options.disable_power_gating) {
        disable_jbay_power_gating(regs);
    }
}

void AlwaysRunTable::write_regs(Target::Cloudbreak::mau_regs &regs) {
    if (gress == EGRESS)
        regs.dp.imem_word_read_override.imem_word_read_override_egress = 1;
    else
        regs.dp.imem_word_read_override.imem_word_read_override_ingress = 1;
    actions->write_regs(regs, this);
}
