// common between jbay and cloudbreak
template<typename REGS> void MeterTable::setup_teop_regs_2(REGS &regs, int meter_group_index) {
    BUG_CHECK(teop >= 0 && teop < 4);
    BUG_CHECK(gress == EGRESS);

    auto &adrdist = regs.rams.match.adrdist;
    auto delay = stage->pipelength(gress) - stage->pred_cycle(gress) - 7;  // assume this stage driving teop
    adrdist.teop_bus_ctl[teop].teop_bus_ctl_delay = delay;
    adrdist.teop_bus_ctl[teop].teop_bus_ctl_delay_en = 1;
    adrdist.teop_bus_ctl[teop].teop_bus_ctl_meter_en = 1;

    adrdist.meter_to_teop_adr_oxbar_ctl[teop].enabled_2bit_muxctl_select = meter_group_index;
    adrdist.meter_to_teop_adr_oxbar_ctl[teop].enabled_2bit_muxctl_enable = 1;

    adrdist.teop_to_meter_adr_oxbar_ctl[meter_group_index].enabled_2bit_muxctl_select = teop;
    adrdist.teop_to_meter_adr_oxbar_ctl[meter_group_index].enabled_2bit_muxctl_enable = 1;

    adrdist.dp_teop_meter_ctl[meter_group_index].dp_teop_meter_ctl_err = 0;  // count all tEOP events
    adrdist.dp_teop_meter_ctl[meter_group_index].dp_teop_meter_ctl_rx_shift = 2; // XXX is this always 2?
    adrdist.dp_teop_meter_ctl[meter_group_index].dp_teop_meter_ctl_rx_en = 1;

    auto &meter = regs.rams.map_alu.meter_group[meter_group_index].meter;
    meter.meter_ctl_teop_en = 1;
}

template<> void MeterTable::setup_teop_regs(Target::JBay::mau_regs &regs, int meter_group_index) {
    setup_teop_regs_2(regs, meter_group_index);
}
