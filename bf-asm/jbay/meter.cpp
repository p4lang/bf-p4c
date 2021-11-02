// common between jbay and cloudbreak
template<typename REGS> void MeterTable::setup_teop_regs_2(REGS &regs, int meter_group_index) {
    BUG_CHECK(teop >= 0 && teop < 4);
    BUG_CHECK(gress == EGRESS);

    auto &adrdist = regs.rams.match.adrdist;
    // assume this stage driving teop
    auto delay = stage->pipelength(gress) - stage->pred_cycle(gress) - 7;
    adrdist.teop_bus_ctl[teop].teop_bus_ctl_delay = delay;
    adrdist.teop_bus_ctl[teop].teop_bus_ctl_delay_en = 1;
    adrdist.teop_bus_ctl[teop].teop_bus_ctl_meter_en = 1;

    adrdist.meter_to_teop_adr_oxbar_ctl[teop].enabled_2bit_muxctl_select = meter_group_index;
    adrdist.meter_to_teop_adr_oxbar_ctl[teop].enabled_2bit_muxctl_enable = 1;

    adrdist.teop_to_meter_adr_oxbar_ctl[meter_group_index].enabled_2bit_muxctl_select = teop;
    adrdist.teop_to_meter_adr_oxbar_ctl[meter_group_index].enabled_2bit_muxctl_enable = 1;

    // count all tEOP events
    adrdist.dp_teop_meter_ctl[meter_group_index].dp_teop_meter_ctl_err = 0;
    // Refer to JBAY uArch Section 6.4.4.10.8
    //
    // The user of the incoming tEOP address needs to consider the original
    // driver. For instance, a meter address driver will be aliged with the LSB
    // of the 18b incoming address, whereas a single-entry stats driver will be
    // already padded with 2 zeros.
    //
    // For example, dp_teop_meter_ctl.dp_teop_meter_ctl_rx_shift must be
    // programmed to 2 to compensate for the single-entry stats address driver:
    //
    // Meter (23b) = {4b CMD+Color, ((dp_teop{6b VPN, 10b addr, 2b subword
    // zeros} >> 2) + 7b zero pad)}
    //
    // As per above, the dp_teop_meter_ctl_rx_shift is set based on the original
    // driver. For a meter address driving there is no need for any shift,
    // however if a stats address is driving then it needs to be shifted by 2.
    // Compiler currently does not use this mechanism where a stats address is
    // driving the meter, this is scope for optimization in future.
    adrdist.dp_teop_meter_ctl[meter_group_index].dp_teop_meter_ctl_rx_shift = 0;
    adrdist.dp_teop_meter_ctl[meter_group_index].dp_teop_meter_ctl_rx_en = 1;

    auto &meter = regs.rams.map_alu.meter_group[meter_group_index].meter;
    meter.meter_ctl_teop_en = 1;
}

template<> void MeterTable::setup_teop_regs(Target::JBay::mau_regs &regs, int meter_group_index) {
    setup_teop_regs_2(regs, meter_group_index);
}
