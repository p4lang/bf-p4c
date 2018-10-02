#ifndef _data_switchbox_h_
#define _data_switchbox_h_

#include "stage.h"
#include "tables.h"

/*
 * Code to handle programming of the Ram Data Bus Horizontal/Vertical Switchbox
 * see section 6.2.4.4 of the MAU uArch docs
 */

template<class REGS>
class DataSwitchboxSetup {
    REGS        &regs;
    Table       *tbl;
    unsigned    home_row, home_row_logical, prev_row, top_ram_row;
public:
    unsigned get_home_row() { return home_row; }
    unsigned get_home_row_logical() { return home_row_logical; }
    DataSwitchboxSetup(REGS &regs, Table *t) : regs(regs), tbl(t) {
        top_ram_row = prev_row = home_row = tbl->layout[0].row/2U;
        // Counter ALU's are on even rows on right side of RAM array. Set
        // home_row to the correct ALU
        if (tbl->table_type() == Table::COUNTER)
            prev_row = home_row = prev_row % 2 ? prev_row + 1 : prev_row;
        // Stateful/Selection/Meter ALU's are on odd rows on right side of RAM
        // array. Set home_row to the correct ALU
        else if (tbl->table_type() == Table::STATEFUL ||
                tbl->table_type() == Table::SELECTION ||
                tbl->table_type() == Table::METER)
            prev_row = home_row = prev_row % 2 ? prev_row : prev_row + 1;
        home_row_logical = home_row * 2 + 1; }
    void setup_row(unsigned row) {
        auto &map_alu =  regs.rams.map_alu;
        auto &swbox = regs.rams.array.switchbox.row;
        auto &map_alu_row =  map_alu.row[row];
        int side = 1;  // always -- currently no maprams on left side
        auto &syn2port_ctl = map_alu_row.i2portctl.synth2port_fabric_ctl[0][side];
        map_alu_row.i2portctl.synth2port_ctl.synth2port_enable = 1;
        while (prev_row != row) {
            auto &prev_syn2port_ctl = map_alu.row[prev_row].i2portctl.synth2port_fabric_ctl[0];
            if (prev_row == home_row) {
                swbox[prev_row].ctl.r_stats_alu_o_mux_select.r_stats_alu_o_sel_oflo_rd_b_i = 1;
                swbox[prev_row].ctl.b_oflo_wr_o_mux_select.b_oflo_wr_o_sel_stats_wr_r_i = 1;
                prev_syn2port_ctl[side].stats_to_vbus_below = 1;
            } else {
                swbox[prev_row].ctl.t_oflo_rd_o_mux_select.t_oflo_rd_o_sel_oflo_rd_b_i = 1;
                swbox[prev_row].ctl.b_oflo_wr_o_mux_select.b_oflo_wr_o_sel_oflo_wr_t_i = 1;
                prev_syn2port_ctl[side].synth2port_connect_below2above = 1;
                /* need to also program left side below2above connections
                 * see ram_bus_path.py:254 -- 'Mike F.' comment */
                prev_syn2port_ctl[0].synth2port_connect_below2above = 1;
                prev_syn2port_ctl[side].oflo_to_vbus_below = 1; }
            prev_syn2port_ctl[side].synth2port_connect_below = 1;
            if (--prev_row == row) {
                swbox[row].ctl.t_oflo_rd_o_mux_select.t_oflo_rd_o_sel_oflo_rd_r_i = 1;
                swbox[row].ctl.r_oflo_wr_o_mux_select = 1;
                syn2port_ctl.oflo_to_vbus_above = 1;
                syn2port_ctl.synth2port_connect_above = 1; } }
        // FIXME: Should this be top_ram_row?
        if (row == home_row) {
            swbox[row].ctl.r_stats_alu_o_mux_select.r_stats_alu_o_sel_stats_rd_r_i = 1; }
    }
    void setup_row_col(unsigned row, unsigned col, int vpn) {
        int side = col >= 6;
        unsigned logical_col = col % 6U;
        auto &ram = regs.rams.array.row[row].ram[col];
        auto &map_alu =  regs.rams.map_alu;
        auto &map_alu_row =  map_alu.row[prev_row];
        auto &unitram_config = map_alu_row.adrmux.unitram_config[side][logical_col];
        unitram_config.unitram_type = tbl->unitram_type();
        unitram_config.unitram_logical_table = tbl->logical_id;
        if (!options.match_compiler) // FIXME -- compiler doesn't set this?
            unitram_config.unitram_vpn = vpn;
        if (tbl->gress == INGRESS)
            unitram_config.unitram_ingress = 1;
        else
            unitram_config.unitram_egress = 1;
        unitram_config.unitram_enable = 1;

        auto &ram_address_mux_ctl = map_alu_row.adrmux.ram_address_mux_ctl[side][logical_col];
        ram_address_mux_ctl.ram_unitram_adr_mux_select = UnitRam::AdrMux::STATS_METERS;
        if (row == home_row) {
            ram.unit_ram_ctl.match_ram_write_data_mux_select = UnitRam::DataMux::STATISTICS;
            ram.unit_ram_ctl.match_ram_read_data_mux_select = UnitRam::DataMux::STATISTICS;
            if (tbl->adr_mux_select_stats())
                ram_address_mux_ctl.ram_stats_meter_adr_mux_select_stats = 1;
            else
                ram_address_mux_ctl.ram_stats_meter_adr_mux_select_meter = 1;
            ram_address_mux_ctl.ram_ofo_stats_mux_select_statsmeter = 1;
            ram_address_mux_ctl.synth2port_radr_mux_select_home_row = 1;
        } else {
            ram.unit_ram_ctl.match_ram_write_data_mux_select = UnitRam::DataMux::OVERFLOW;
            ram.unit_ram_ctl.match_ram_read_data_mux_select = UnitRam::DataMux::OVERFLOW;
            ram_address_mux_ctl.ram_oflo_adr_mux_select_oflo = 1;
            ram_address_mux_ctl.ram_ofo_stats_mux_select_oflo = 1;
            ram_address_mux_ctl.synth2port_radr_mux_select_oflo = 1; }
        ram_address_mux_ctl.map_ram_wadr_mux_select = MapRam::Mux::SYNTHETIC_TWO_PORT;
        ram_address_mux_ctl.map_ram_wadr_mux_enable = 1;
        ram_address_mux_ctl.map_ram_radr_mux_select_smoflo = 1;
        int syn2port_bus = prev_row == top_ram_row ? 0 : 1;
        auto &syn2port_members = map_alu_row.i2portctl.synth2port_hbus_members[syn2port_bus][side];
        syn2port_members |= 1U << logical_col;
    }
};

#endif /* _data_switchbox_h_ */
