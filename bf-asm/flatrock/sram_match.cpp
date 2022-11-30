#include "sram_match.h"
#include "stage.h"
#include "top_level.h"

void SRamMatchTable::verify_format(Target::Flatrock) {
    format->pass1(this);
    group_info.resize(format->groups());
    unsigned fmt_width = (format->size + 127)/128;
    std::vector<int> offsets = { 0 };
    for (unsigned i = 1; i < format->groups(); i++) {
        for (auto &field : format->group(i)) {
            auto &f0 = *field.second.by_group[0];
            if (field.second.bits.size() != f0.bits.size()) {
                error(format->lineno, "mismatch for %s between match groups 0 and %d",
                      field.first.c_str(), i);
                continue; }
            auto it = field.second.bits.begin();
            for (auto &bits : f0.bits) {
                if (offsets.size() <= i) offsets.push_back(it->lo - bits.lo);
                if (it->lo - bits.lo != offsets.at(i) || it->hi - bits.hi != offsets.at(i))
                    error(format->lineno, "mismatch for %s between match groups 0 and %d",
                          field.first.c_str(), i);
                ++it; } } }
    if (error_count > 0) return;
    for (unsigned i = 1; i < offsets.size(); i++) {
        if (offsets.at(i) < offsets.at(i-1)) {
            error(format->lineno, "match groups %d and %d out of order", i-1, i);
            // FIXME -- could sort them if they're out of order instead
            return; } }
    if ((offsets.size() & (offsets.size() - 1)) == 0) {  // power of 2 size
        int stride = (1 << format->log2size)/offsets.size();
        for (unsigned i = 1; i < offsets.size(); i++) {
            if (offsets.at(i) != i*stride) {
                error(format->lineno, "match group %d at wrong offset %d (should be %d)",
                      i, offsets.at(i), i*stride);
                return; } }
    } else {
        int sets = offsets.size()/3;
        if ((sets & (sets-1)) || sets*3U != offsets.size()) {
            error(format->lineno, "Invalid number of match groups");
            return; }
        int stride = (1 << format->log2size)/sets;
        for (unsigned i = 1; i < offsets.size(); i++) {
            if (offsets.at(i) != (i/3)*stride + (i%3)*(stride/3)) {
                error(format->lineno, "match group %d at wrong offset %d (should be %d)",
                      i, offsets.at(i), (i/3)*stride + (i%3)*(stride/3));
                return; } } }
    if (word_info.empty()) {
        word_info.resize(fmt_width);
        for (size_t i = 0; i < offsets.size(); ++i)
            word_info.at(offsets[i]/128).push_back(i);
    } else if (word_info.size() != fmt_width) {
        error(mgm_lineno, "Match group map doesn't match format size");
    } else {
        for (size_t i = 0; i < word_info.size(); ++i) {
            for (unsigned grp : word_info[i]) {
                if (grp >= offsets.size() || offsets[grp]/128 != i)
                    error(mgm_lineno, "match_group_map does not match format of atble %s", name());
            }
        }
    }
    verify_match(fmt_width);
    for (auto &way : ways) {
        if (way.subword_bits != ways.front().subword_bits) {
            error(way.lineno, "incompatible way indexes");
            break; }
        if (way.subword_bits + format->log2size < 7) {
            // make the format compatible with the way by padding it out.  Is there
            // a better way of doing this?  Or perhaps it should be an error
            format->log2size = 7 - way.subword_bits;
        }
    }
}

void SRamMatchTable::verify_format_pass2(Target::Flatrock) {
    for (auto &ixb : input_xbar)
        for (auto *ms : this->match)
            ixb->setup_match_key_cfg(ms);
    if (Format::Field *match = format->field("match")) {
        int stride = (1 << format->log2size)/format->groups();
        bool err = false;
        for (int i = 0; i < format->groups(); ++i) {
            // FIXME -- the below double-loop is cribbed from SRamMatchTable::verify_match;
            // there should be a better/cleaner interface for mapping between the match
            // key and things in the ixbar
            unsigned bit = 0;
            int prev_offset = -1;
            for (auto &piece : match->by_group[i]->bits) {
                auto mw = --match_by_bit.upper_bound(bit);
                int lo = bit - mw->first;
                while (!err && mw != match_by_bit.end() && mw->first < bit + piece.size()) {
                    for (auto &ixb : input_xbar) {
                        int offset = ixb->find_match_offset(mw->second);
                        if (offset < 0) continue;  // error?  not found on ixbar
                        if (offset + i*stride != piece.lo + mw->first - bit) {
                            if (prev_offset < offset)
                                error(match->fmt->lineno, "match entry %s not aligned between "
                                      "format and input_xbar", mw->second->toString().c_str());
                            else
                                error(match->fmt->lineno, "match entries don't match "
                                      "input_xbar ordering");
                            err = true;
                            break; }
                        prev_offset = offset; }
                    lo = 0;
                    ++mw;
                }
                bit += piece.size();
                if (err) break; }
            if (err) break; }
    }
}

void SRamMatchTable::setup_word_ixbar_group(Target::Flatrock) {
    // flatrock does not need this as words are assigned to specific XMEs
}

void SRamMatchTable::alloc_global_busses() {
    int tbl_stage = stage->stageno;
    for (auto &row : layout) {
        int minstage, mincol, maxstage, maxcol;
        Target::Flatrock::stage_col_range(row.memunits, minstage, mincol, maxstage, maxcol);
        const Way *left_way = nullptr, *right_way = nullptr;  // ways using left & right busses
        int left_col = -1, right_col = -1;  // xme cols of those ways
        for (auto &ram : row.memunits) {
            if (auto *way = way_for_ram(ram)) {
                int col = (way->group_xme % 4) / 2;
                if (ram.stage == tbl_stage ? ram.col/2 < col : ram.stage < tbl_stage) {
                    if (left_way && left_way != way)
                        error(row.lineno, "rams on row %d in different ways can't share lhbus",
                              row.row);
                    left_way = way;
                    left_col = col;
                } else if (ram.stage == tbl_stage ? ram.col/2 > col : ram.stage > tbl_stage) {
                    if (right_way && right_way != way)
                        error(row.lineno, "rams on row %d in different ways can't share rhbus",
                              row.row);
                    right_way = way;
                    right_col = col;
                }
            } else {
                error(row.lineno, "Can't find way for %s", ram.desc()); } }
        if (left_way) {
            alloc_global_bus(row, Layout::R2L_BUS, minstage, mincol/2, tbl_stage, left_col); }
        if (right_way) {
            alloc_global_bus(row, Layout::L2R_BUS, tbl_stage, right_col, maxstage, maxcol/2); }
    }
}

/**
 * @brief configure the stm busses to access a single RAM from a particuler table
 *
 * Configures STM memory registers (controlling how busses and rams are connected) to
 * allow a single RAM to be accessed by a single table on a particular port/column/vbus
 * in a particular stage.  This is used by ALL table types that use STM
 *
 * @param regs  The estm or istm register array to be programmed.  These are different
 *              types as ingress and egress have different sizes.  This is a 3D array,
 *              indexed by [row][stage][column]
 * @param stage Stage for the table accessing the RAM
 * @param col   Memory column the table is on (0-4)
 * @param vbus  Vertical bus in the column the table uses (0-5).  Note that if 'write' is
 *              true it will also use the write vbus and the spare busses
 * @param busses Which horizontal busses to use on the ram's row, if needed
 * @param ram   Which memory unit (ram) to program access for
 * @param write Program for read-only (false) or read-write (true) access
 * @param vpn   VPN to program the ram
 * @param delay Extra delay to program at the ram so access will time-match with more
 *              distant rams.
 */
template <class REGS> void stm_bus_rw_config(REGS &stm, int stage, int col, int vbus,
            const std::map<Table::Layout::bus_type_t, int> &busses,
            const MemUnit &ram, bool write, int vpn, int delay) {
    // enable the vertical bus down to the row
    for (auto r = 0; r < ram.row; ++r) {
        auto &cfg = stm[r][stage][col];
        cfg.ver_bot_cfg.rd_req_en |= 1U << vbus;
        cfg.ver_top_cfg.bot_en[vbus] = 1;
        if (write) cfg.ver_bot_cfg.wr_req_en = 1;
    }
    stm[ram.row][stage][col].ver_top_cfg.bot_en[vbus] = 1;

    // figure out if we need a horizontal bus and whether it goes left or right
    bool left = ram.stage < stage;
    auto &cfg = stm[ram.row][ram.stage][ram.col/2];
    if (ram.stage == stage) {
        if (ram.col/2 == col) {
            // ram in the STM column (no horizontal bus needed)
            if (write && ram.row == 0) {
                // spare bank ram
                cfg.ver_top_cfg.spare_en = 1;
                cfg.ram_cfg.rd_sel[ram.col&1] = 11;
                cfg.ram_cfg.wr_sel[ram.col&1] = 6;
                return; }
            if (ram.col&1)
                cfg.ver_top_cfg.ram1_en[vbus] = 1;
            else
                cfg.ver_top_cfg.ram0_en[vbus] = 1;
            cfg.ram_cfg.delay[ram.col&1] = delay;
            cfg.ram_cfg.rd_sel[ram.col&1] = 1 + vbus;
            cfg.ram_cfg.vpn[ram.col&1] = vpn;
            if (write) cfg.ram_cfg.wr_sel[ram.col&1] = 1;
            return; }
        if (ram.col/2 < col)
            left = true; }
    // ram needs a horiz bus -- left or right depending on `left`
    if (left) {
        int hbus = busses.at(Table::Layout::R2L_BUS);
        // request goes down vbus and on to r2l req bus
        stm[ram.row][stage][col].hor_r2l_cfg.rd_req_sel[hbus] = 2 + vbus;
        // response comes back on corresponding l2r resp bus and up vbus
        if (hbus == 0)
            stm[ram.row][stage][col].ver_top_cfg.l2r0_en[vbus] = 1;
        else
            stm[ram.row][stage][col].ver_top_cfg.l2r1_en[vbus] = 1;
        if (write) stm[ram.row][stage][col].hor_r2l_cfg.wr_req_sel[hbus] = 2;
        if (!col--) {
            col = 4;
            if (--stage & 1) --delay; }
        while (stage > ram.stage || col > ram.col/2) {
            // request along r2l bus to the ram
            stm[ram.row][stage][col].hor_r2l_cfg.rd_req_sel[hbus] = 1;
            // response comes back on the corresponding l2r resp bus
            stm[ram.row][stage][col].hor_l2r_cfg.rd_rsp_hor[hbus] = 1;
            if (write) stm[ram.row][stage][col].hor_r2l_cfg.wr_req_sel[hbus] = 1;
            if (!col--) {
                col = 4;
                if (--stage & 1) --delay; } }
        BUG_CHECK(stage == ram.stage && col == ram.col/2, "failed to reach correct column");
        cfg.hor_r2l_cfg.rd_req_sel[hbus] = 1;
        if (write) cfg.hor_r2l_cfg.wr_req_sel[hbus] = 1;
        BUG_CHECK(delay >= 0, "negative delay -- initial delay not large enough");
        BUG_CHECK(!write || delay == 0, "inconsistent delay for dp memory");
        // response goes onto the corresponding l2r response bus
        if (ram.col&1)
            cfg.hor_l2r_cfg.rd_rsp_ram1[hbus] = 1;
        else
            cfg.hor_l2r_cfg.rd_rsp_ram0[hbus] = 1;
        cfg.ram_cfg.delay[ram.col&1] = delay;
        cfg.ram_cfg.rd_sel[ram.col&1] = 7 + hbus;
        cfg.ram_cfg.vpn[ram.col&1] = vpn;
        if (write) cfg.ram_cfg.wr_sel[ram.col&1] = 2 + hbus;
    } else {
        int hbus = busses.at(Table::Layout::L2R_BUS);
        // request goes down vbus and on to l2r req bus
        stm[ram.row][stage][col].hor_l2r_cfg.rd_req_sel[hbus] = 2 + vbus;
        // response comes back on corresponding r2l resp bus and up vbus
        if (hbus == 0)
            stm[ram.row][stage][col].ver_top_cfg.r2l0_en[vbus] = 1;
        else
            stm[ram.row][stage][col].ver_top_cfg.r2l1_en[vbus] = 1;
        if (write) stm[ram.row][stage][col].hor_l2r_cfg.wr_req_sel[hbus] = 2;
        if (++col > 4) {
            col = 0;
            if (stage++ & 1) --delay; }
        while (stage < ram.stage || col < ram.col/2) {
            // request along l2r bus to the ram
            stm[ram.row][stage][col].hor_l2r_cfg.rd_req_sel[hbus] = 1;
            // response comes back on the corresponding r2l resp bus
            stm[ram.row][stage][col].hor_r2l_cfg.rd_rsp_hor[hbus] = 1;
            if (write) stm[ram.row][stage][col].hor_l2r_cfg.wr_req_sel[hbus] = 1;
            if (++col > 4) {
                col = 0;
                if (stage++ & 1) --delay; } }
        BUG_CHECK(stage == ram.stage && col == ram.col/2, "failed to reach correct column");
        cfg.hor_l2r_cfg.rd_req_sel[hbus] = 1;
        if (write) cfg.hor_l2r_cfg.wr_req_sel[hbus] = 1;
        BUG_CHECK(delay >= 0, "negative delay -- initial delay not large enough");
        BUG_CHECK(!write || delay == 0, "inconsistent delay for dp memory");
        // response goes onto the corresponding r2l response bus
        if (ram.col&1)
            cfg.hor_r2l_cfg.rd_rsp_ram1[hbus] = 1;
        else
            cfg.hor_r2l_cfg.rd_rsp_ram0[hbus] = 1;
        cfg.ram_cfg.delay[ram.col&1] = delay;
        cfg.ram_cfg.rd_sel[ram.col&1] = 9 + hbus;
        cfg.ram_cfg.vpn[ram.col&1] = vpn;
        if (write) cfg.ram_cfg.wr_sel[ram.col&1] = 4 + hbus;
    }
}

template<> void SRamMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### SRam match table " << name() << " write_regs " << loc());
    MatchTable::write_regs(regs, 0, this);
    for (auto &ixb : input_xbar)
        ixb->write_xmu_regs(regs);

    auto &ppu = TopLevel::regs<Target::Flatrock>()->reg_pipe.ppu_pack;
    int maxdelay = 0;
    for (auto &row : layout)
        for (auto &ram : row.memunits)
            maxdelay = std::max(maxdelay, std::abs(ram.stage/2 - stage->stageno/2));
    for (auto &row : layout) {
        for (auto &ram : row.memunits) {
            BUG_CHECK(row.row == ram.row, "ram row mismatch");
            auto *way = way_for_ram(ram);
            LOG3("# bus setup for " << ram << " in way " << (way - &ways[0]) << " xme " <<
                 way->group_xme);
            // FIXME -- should be getting vpn from row.vpn?
            int vpn = std::find(way->rams.begin(), way->rams.end(), ram) - way->rams.begin();
            int memcol = (way->group_xme % 8) / 2;
            int vbus = way->group_xme % 2;
            if (gress != EGRESS)
                stm_bus_rw_config(ppu.istm, stage->stageno, memcol, vbus, row.bus,
                                  ram, false, vpn, maxdelay);
            else
                stm_bus_rw_config(ppu.estm, stage->stageno, memcol, vbus, row.bus,
                                  ram, false, vpn, maxdelay);
        }
    }

    if (actions) actions->write_regs(regs, this);
    if (gateway) gateway->write_regs(regs);
    if (idletime) idletime->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
}

