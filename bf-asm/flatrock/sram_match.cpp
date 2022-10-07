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
            for (auto &piece : match->by_group[i]->bits) {
                auto mw = --match_by_bit.upper_bound(bit);
                int lo = bit - mw->first;
                while (!err && mw != match_by_bit.end() && mw->first < bit + piece.size()) {
                    for (auto &ixb : input_xbar) {
                        int offset = ixb->find_match_offset(mw->second);
                        if (offset < 0) continue;  // error?  not found on ixbar
                        if (offset + i*stride != piece.lo + mw->first - bit) {
                            error(match->fmt->lineno, "match entries don't match "
                                  "input_xbar ordering");
                            err = true;
                            break; } }
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

// Configure STM for read of the given ram from the given read port/bus
// REGS here will be an STM 3-dim array, indexed by [row][stage][col]
template <class REGS> void stm_read_config(REGS &stm, int stage, int col, int vbus,
            const std::map<Table::Layout::bus_type_t, int> &busses,
            const MemUnit &ram, int vpn, int delay) {
    // enable the vertical bus down to the row
    for (auto r = 0; r < ram.row; ++r) {
        auto &cfg = stm[r][stage][col];
        cfg.ver_bot_cfg.rd_req_en |= 1U << vbus;
        cfg.ver_top_cfg.bot_en[vbus] = 1;
    }
    stm[ram.row][stage][col].ver_top_cfg.bot_en[vbus] = 1;

    // figure out if we need a horizontal bus and whether it goes left or right
    bool left = ram.stage < stage;
    auto &cfg = stm[ram.row][ram.stage][ram.col/2];
    if (ram.stage == stage) {
        if (ram.col/2 == col) {
            // ram in the STM column (no horizontal bus needed)
            if (ram.col&1)
                cfg.ver_top_cfg.ram1_en[vbus] = 1;
            else
                cfg.ver_top_cfg.ram0_en[vbus] = 1;
            cfg.ram_cfg.delay[ram.col&1] = delay;  // FIXME -- delay config
            cfg.ram_cfg.rd_sel[ram.col&1] = 1 + vbus;
            cfg.ram_cfg.vpn[ram.col&1] = vpn;
            cfg.ram_cfg.wr_sel[ram.col&1] = 0;  // no writes
            return; }
        if (ram.col/2 < col)
            left = true; }
    // ram needs a horiz bus -- left or right depending on `left`
    if (left) {
        int hbus = busses.at(Table::Layout::SEARCH_BUS);
        if (hbus == 0)
            stm[ram.row][stage][col].ver_top_cfg.r2l0_en[vbus] = 1;
        else
            stm[ram.row][stage][col].ver_top_cfg.r2l1_en[vbus] = 1;
        stm[ram.row][stage][col].hor_r2l_cfg.rd_req_sel[hbus] = 2 + vbus;
        if (!col--) {
            col = 4;
            if (--stage & 1) --delay; }
        while (stage > ram.stage || col > ram.col/2) {
            stm[ram.row][stage][col].hor_r2l_cfg.rd_req_sel[hbus] = 1;
            if (!col--) {
                col = 4;
                if (--stage & 1) --delay; } }
        BUG_CHECK(stage == ram.stage && col == ram.col/2, "failed to reach correct column");
        BUG_CHECK(delay >= 0, "negative delay -- initial delay not large enough");
        cfg.hor_r2l_cfg.rd_req_sel[hbus] = 1;
        if (ram.col&1)
            cfg.hor_r2l_cfg.rd_rsp_ram1[hbus] = 1;
        else
            cfg.hor_r2l_cfg.rd_rsp_ram0[hbus] = 1;
        cfg.ram_cfg.delay[ram.col&1] = delay;  // FIXME -- delay config
        cfg.ram_cfg.rd_sel[ram.col&1] = 7 + hbus;
        cfg.ram_cfg.vpn[ram.col&1] = vpn;
        cfg.ram_cfg.wr_sel[ram.col&1] = 0;  // no writes
    } else {
        int hbus = busses.at(Table::Layout::SEARCH_BUS);
        if (hbus == 0)
            stm[ram.row][stage][col].ver_top_cfg.l2r0_en[vbus] = 1;
        else
            stm[ram.row][stage][col].ver_top_cfg.l2r1_en[vbus] = 1;
        stm[ram.row][stage][col].hor_l2r_cfg.rd_req_sel[hbus] = 2 + vbus;
        if (++col > 4) {
            col = 0;
            if (stage++ & 1) --delay; }
        while (stage < ram.stage || col < ram.col/2) {
            stm[ram.row][stage][col].hor_l2r_cfg.rd_req_sel[hbus] = 1;
            if (++col > 4) {
                col = 0;
                if (stage++ & 1) --delay; } }
        BUG_CHECK(stage == ram.stage && col == ram.col/2, "failed to reach correct column");
        BUG_CHECK(delay >= 0, "negative delay -- initial delay not large enough");
        cfg.hor_l2r_cfg.rd_req_sel[hbus] = 1;
        if (ram.col&1)
            cfg.hor_l2r_cfg.rd_rsp_ram1[hbus] = 1;
        else
            cfg.hor_l2r_cfg.rd_rsp_ram0[hbus] = 1;
        cfg.ram_cfg.delay[ram.col&1] = delay;  // FIXME -- delay config
        cfg.ram_cfg.rd_sel[ram.col&1] = 9 + hbus;
        cfg.ram_cfg.vpn[ram.col&1] = vpn;
        cfg.ram_cfg.wr_sel[ram.col&1] = 0;  // no writes
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
            // FIXME -- should be getting vpn from row.vpn?
            int vpn = std::find(way->rams.begin(), way->rams.end(), ram) - way->rams.begin();
            int memcol = (way->group_xme % 4) / 2;
            int vbus = way->group_xme % 2;
            if (gress != EGRESS)
                stm_read_config(ppu.istm, stage->stageno, memcol, vbus, row.bus,
                                ram, vpn, maxdelay);
            else
                stm_read_config(ppu.estm, stage->stageno, memcol, vbus, row.bus,
                                ram, vpn, maxdelay);
        }
    }

    if (actions) actions->write_regs(regs, this);
    if (gateway) gateway->write_regs(regs);
    if (idletime) idletime->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
}

