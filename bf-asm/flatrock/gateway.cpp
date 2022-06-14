#include "gateway.h"
#include "input_xbar.h"  // FIXME needed only in unified build to ensure proper specialization

template<> void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Gateway table " << name() << " write_regs " << loc());
    for (auto &ixb : input_xbar)
        ixb->write_regs(regs);
    auto &minput = regs.ppu_minput.rf;
    auto &first_row = layout.at(0);
    int row = first_row.row;
    for (auto &line : table) {
        // FIXME -- there 104 bits of match to (maybe) specify here, but we
        // FIXME -- only store 64 bits in line.  The vector/byte match is also
        // FIXME -- weirdly shared between rows (single match for each byte,
        // FIXME -- then each row gets to match on those 8 bits
        // for now, just map as 40+8 bits
        for (int i = 0; i < 20; ++i)
            minput.minput_gw_btst_key[row].dir[i] = line.val.dirtcam(2, i*2);
        for (int i = 0; i < 4; ++i)
            minput.minput_gw_vtst_key[row].dir[i] = line.val.dirtcam(2, 40 + i*2);
        if (!line.run_table)
            minput.minput_gw_comp.inhibit |= 1 << row;
        ++row; }
    --row;  // last row of the table (inclusive)
    minput.minput_gw_comp.grp_start |= 1 << row;
    if (!miss.run_table)
        minput.minput_gw_comp.grp_inhibit |= 1 << first_row.row;
    minput.minput_gw_comp_vect[match_table->physical_id].comp_idx = first_row.row;

    // FIXME -- write payload?
    // error(lineno, "%s:%d: Flatrock gateway not implemented yet!", __FILE__, __LINE__);
}
template void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
