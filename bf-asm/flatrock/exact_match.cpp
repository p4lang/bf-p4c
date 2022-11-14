#include "exact_match.h"
#include "input_xbar.h"
#include "stage.h"

void Target::Flatrock::ExactMatchTable::pass1() {
    ::ExactMatchTable::pass1();
    unsigned stm_xmus = 0;
    for (auto &ixb : input_xbar)
        stm_xmus |= dynamic_cast<::Flatrock::InputXbar &>(*ixb).xmu_units() & 0xf0;
    physical_ids |= stm_xmus << 8;
}

void Target::Flatrock::ExactMatchTable::setup_ways() {
    ::ExactMatchTable::setup_ways();
    for (auto &row : layout) {
        int first_way[2] = { -1, -1 };
        for (auto &ram : row.memunits) {
            int way = way_map.at(ram).way;
            if (ram.stage == stage->stageno && ram.col/2 == (ways[way].group_xme-8)/2) {
                // if the ram is directly under the xme. no horizontal bus is needed
                continue; }
            bool left = ram.stage < stage->stageno ||
                        ram.stage == stage->stageno && ram.col < ways[way].group_xme - 8;
            if (first_way[left] < 0) {
                first_way[left] = way;
            } else if (first_way[left] != way) {
                error(row.lineno, "Ways %d and %d of table %s share address bus on row %d, "
                      "but use different addresses", first_way[left], way, name(), row.row);
                break; } } }
}


template<> void ExactMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Exact match table " << name() << " write_regs " << loc());
    SRamMatchTable::write_regs(regs);
    // error(lineno, "%s:%d: Flatrock exact_match not implemented yet!", SRCFILE, __LINE__);
}

