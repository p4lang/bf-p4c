#include <target.h>
#include <tables.h>

int Target::Flatrock::NUM_BUS_OF_TYPE_v(int bus_type) const {
    switch (static_cast<Table::Layout::bus_type_t>(bus_type)) {
    case Table::Layout::SEARCH_BUS:
    case Table::Layout::L2R_BUS:
    case Table::Layout::R2L_BUS:
        return 2;
    default:
        return 0;
    }
}


std::pair<int, int> Target::Flatrock::stage_range(const std::vector<MemUnit> &mem,
                                                  bool egress2ingress) {
    int minstage = mem.at(0).stage, maxstage = minstage;
    for (auto &el : mem) {
        if (el.stage < minstage) minstage = el.stage;
        if (el.stage > maxstage) maxstage = el.stage; }
    if (egress2ingress) {
        int tmp = EGRESS_STAGE0_INGRESS_STAGE - minstage;
        minstage = EGRESS_STAGE0_INGRESS_STAGE - maxstage;
        maxstage = tmp; }
    return std::make_pair(minstage, maxstage);
}

void Target::Flatrock::stage_col_range(const std::vector<MemUnit> &mem, int &minstage, int &mincol,
                                       int &maxstage, int &maxcol) {
    minstage = maxstage = mem.at(0).stage;
    mincol = maxcol = mem.at(0).col;
    for (auto &el : mem) {
        if (el.stage < minstage) {
            minstage = el.stage;
            mincol = el.col;
        } else if (el.stage == minstage && el.col < mincol) {
            mincol = el.col; }
        if (el.stage > maxstage) {
            maxstage = el.stage;
            maxcol = el.col;
        } else if (el.stage == maxstage && el.col > maxcol) {
            maxcol = el.col; } }
}
