#include "stage.h"
#include "tables.h"

/*
 * Code to handle programming of the Ram Data Bus Horizontal/Vertical Switchbox
 * see section 6.2.4.4 of the MAU uArch docs
 */

class DataSwitchboxSetup {
    Stage *stage;
    unsigned    home_row, prev_row;
public:
    DataSwitchboxSetup(Stage *s, unsigned h) : stage(s), home_row(h), prev_row(h) {}
    void setup_row(unsigned row) {
        auto &map_alu =  stage->regs.rams.map_alu;
        auto &swbox = stage->regs.rams.array.switchbox.row;
        auto &map_alu_row =  map_alu.row[row];
        int side = 1;  // always -- currently no maprams on left side
        auto &syn2port_ctl = map_alu_row.i2portctl.synth2port_fabric_ctl[0][side];
        while (prev_row != row) {
            auto &prev_syn2port_ctl=map_alu.row[prev_row].i2portctl.synth2port_fabric_ctl[0];
            if (prev_row == home_row) {
                swbox[prev_row].ctl.r_stats_alu_o_mux_select.r_stats_alu_o_sel_oflo_rd_b_i = 1;
                swbox[prev_row].ctl.b_oflo_wr_o_mux_select.b_oflo_wr_o_sel_stats_wr_r_i = 1;
                //map_alu.row[prev_row].wadr_swbox.ctl.b_oflo_wadr_o_mux_select
                //    .b_oflo_wadr_o_sel_r_stats_wadr_i = 1;
                prev_syn2port_ctl[side].stats_to_vbus_below = 1;
            } else {
                swbox[prev_row].ctl.t_oflo_rd_o_mux_select.t_oflo_rd_o_sel_oflo_rd_b_i = 1;
                swbox[prev_row].ctl.b_oflo_wr_o_mux_select.b_oflo_wr_o_sel_oflo_wr_t_i = 1;
                //map_alu.row[prev_row].wadr_swbox.ctl.b_oflo_wadr_o_mux_select
                //    .b_oflo_wadr_o_sel_t_oflo_wadr_i = 1;
                prev_syn2port_ctl[side].synth2port_connect_below2above = 1;
                /* need to also program left side overflow connections?
                 * see ram_bus_path.py:560 */
                prev_syn2port_ctl[0].synth2port_connect_below2above = 1;
                if (options.match_compiler) {
                    /* FIXME -- always flow down over left side even if the next row not in use? */
                    map_alu.row[prev_row-1].i2portctl.synth2port_fabric_ctl[0][0]
                        .synth2port_connect_below2above = 1; } }
            prev_syn2port_ctl[side].synth2port_connect_below = 1;
            if (--prev_row == row) {
                swbox[row].ctl.t_oflo_rd_o_mux_select.t_oflo_rd_o_sel_oflo_rd_r_i = 1;
                swbox[row].ctl.r_oflo_wr_o_mux_select = 1;
                //map_alu.row[prev_row].wadr_swbox.ctl.r_oflo_wadr_o_mux_select = 1;
                syn2port_ctl.oflo_to_vbus_above = 1;
                syn2port_ctl.synth2port_connect_above = 1; } }
        if (row == home_row)
            swbox[row].ctl.r_stats_alu_o_mux_select.r_stats_alu_o_sel_stats_rd_r_i = 1;
    }
    void setup_col(unsigned col) {
        auto &map_alu =  stage->regs.rams.map_alu;
        auto &map_alu_row =  map_alu.row[prev_row];
        int syn2port_bus = prev_row == home_row ? 0 : 1;
        int side = 1;  // always -- currently no maprams on left side
        auto &syn2port_members = map_alu_row.i2portctl.synth2port_hbus_members[syn2port_bus][side];
        syn2port_members |= 1U << col;
    }
};
