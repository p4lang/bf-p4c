#include "ternary_match.h"
#include "stage.h"
#include "top_level.h"

int Target::Flatrock::TernaryMatchTable::json_memunit(const MemUnit &u) const {
    int stage = gress == EGRESS ? EGRESS_STAGE0_INGRESS_STAGE - u.stage : u.stage;
    int row = u.row;
    if (TCAM_UNITS_PER_ROW == 1 && row < 10) {
        // when in 20x1 config, reverse the first column so 9 ends up next to 10
        // for wide match combining
        row = 9 - row; }
    return stage * TCAM_STRIDE_STAGE + row * TCAM_STRIDE_ROW + u.col * TCAM_STRIDE_COLUMN;
}

void Target::Flatrock::TernaryMatchTable::setup_indirect(const value_t &v) {
    if (v.type == tINT) {
        if (v.i < 0 || v.i >= LOCAL_TIND_UNITS)
            error(v.lineno, "invalid tind unit %" PRIi64, v.i);
        local_tind_units.push_back(v.i);
    } else if (v.type == tRANGE) {
        if (v.lo < 0 || v.lo >= LOCAL_TIND_UNITS)
            error(v.lineno, "invalid tind unit %d", v.lo);
        else if (v.hi < 0 || v.hi >= LOCAL_TIND_UNITS)
            error(v.lineno, "invalid tind unit %d", v.hi);
        int step = v.lo <= v.hi ? 1 : -1;
        for (int i = v.lo; i != v.hi; i += step)
            local_tind_units.push_back(i);
        local_tind_units.push_back(v.hi);
    } else if (v.type == tVEC) {
        for (auto &el : v.vec) {
            if (!CHECKTYPE2(el, tINT, tRANGE)) continue;
            if (el.type == tINT) {
                if (el.i < 0 || el.i >= LOCAL_TIND_UNITS)
                    error(el.lineno, "invalid tind unit %" PRIi64, el.i);
                local_tind_units.push_back(el.i);
            } else {
                if (el.lo < 0 || el.lo >= LOCAL_TIND_UNITS)
                    error(el.lineno, "invalid tind unit %d", el.lo);
                else if (el.hi < 0 || el.hi >= LOCAL_TIND_UNITS)
                    error(el.lineno, "invalid tind unit %d", el.hi);
                int step = el.lo <= el.hi ? 1 : -1;
                for (int i = el.lo; i != el.hi; i += step)
                    local_tind_units.push_back(i);
                local_tind_units.push_back(el.hi); } }
    } else if (v.type == tSTR) {
        indirect = v;
    } else {
        error(v.lineno, "Syntax Error, invalid indirect");
    }
}

void Target::Flatrock::TernaryMatchTable::pass1() {
    ::TernaryMatchTable::pass1();
    if (tcam_id < 0 && indirect) {
        // allocate for tables with indirect STM first
        alloc_id("tcam", tcam_id, stage->pass1_tcam_id,
             TCAM_TABLES_WITH_INDIRECT_STM, false, stage->tcam_id_use);
        physical_id = tcam_id; }
    for (auto tind : local_tind_units) {
        if (stage->local_tind_use[tind]) {
            if (stage->local_tind_use[tind] == this)
                error(lineno, "local tind %d used multiple times by %s", tind, name());
            else
                error(lineno, "table %s using local tind %d already in use by %s", name(),
                      tind, stage->local_tind_use[tind]->name());
        } else {
            stage->local_tind_use[tind] = this; } }
    int tbl_stage = stage->stageno;
    if (gress == EGRESS) tbl_stage = EGRESS_STAGE0_INGRESS_STAGE - tbl_stage;
    for (auto &row : layout) {
        auto [minstage, maxstage] = stage_range(row.memunits, gress == EGRESS);
        if (minstage < tbl_stage) {
            if (!row.bus.count(Layout::R2L_BUS)) {
                if (!row.bus.count(Layout::SEARCH_BUS)) continue;
                row.bus[Layout::R2L_BUS] = row.bus.at(Layout::SEARCH_BUS); }
            int hbus = row.bus.at(Layout::R2L_BUS) + TCAM_MATCH_BUSSES/2;
            for (int st = minstage; st <= tbl_stage; ++st) {
                auto &old = Stage::stage(INGRESS, st)->tcam_match_bus_use[row.row][hbus];
                if (old)
                    error(row.lineno, "%s wants to use r2l bus %d:%d:%d, already in use by %s",
                          name(), row.row, st, hbus - TCAM_MATCH_BUSSES/2, old->name());
                else
                    old = this; } }
        if (maxstage > tbl_stage) {
            if (!row.bus.count(Layout::L2R_BUS)) {
                if (!row.bus.count(Layout::SEARCH_BUS)) continue;
                row.bus[Layout::L2R_BUS] = row.bus.at(Layout::SEARCH_BUS); }
            int hbus = row.bus.at(Layout::L2R_BUS);
            for (int st = tbl_stage; st <= maxstage; ++st) {
                auto &old = Stage::stage(INGRESS, st)->tcam_match_bus_use[row.row][hbus];
                if (old)
                    error(row.lineno, "%s wants to use l2r bus %d:%d:%d, already in use by %s",
                          name(), row.row, st, hbus, old->name());
                else
                    old = this; } }
    }
    if (auto *fmt = indirect ? indirect->format.get() : format.get()) {
        if (fmt->immed && fmt->immed->bit(0) != 0) {
            error(fmt->lineno, "immediate operands in format for ternary%s must start at bit 0",
                  indirect ? " indirect" : ""); } }
}

void Target::Flatrock::TernaryMatchTable::pass2() {
    ::TernaryMatchTable::pass2();
    if (tcam_id < 0) {
        alloc_id("tcam", tcam_id, stage->pass1_tcam_id,
             TCAM_TABLES_PER_STAGE, false, stage->tcam_id_use);
        physical_id = tcam_id; }
    int tbl_stage = stage->stageno;
    if (gress == EGRESS) tbl_stage = EGRESS_STAGE0_INGRESS_STAGE - tbl_stage;
    for (auto &row : layout) {
        auto [minstage, maxstage] = stage_range(row.memunits, gress == EGRESS);
        if (minstage < tbl_stage && !row.bus.count(Layout::R2L_BUS)) {
            for (int hbus = TCAM_MATCH_BUSSES/2; hbus < TCAM_MATCH_BUSSES; ++hbus) {
                bool ok = true;
                for (int st = minstage; st <= tbl_stage; ++st) {
                    if (Stage::stage(INGRESS, st)->tcam_match_bus_use[row.row][hbus]) {
                        ok = false;
                        break; } }
                if (ok) {
                    row.bus[Layout::R2L_BUS] = hbus - TCAM_MATCH_BUSSES/2;
                    for (int st = minstage; st <= tbl_stage; ++st)
                        Stage::stage(INGRESS, st)->tcam_match_bus_use[row.row][hbus] = this;
                    break; } } }
        if (maxstage > tbl_stage && !row.bus.count(Layout::L2R_BUS)) {
            for (int hbus = 0; hbus < TCAM_MATCH_BUSSES/2; ++hbus) {
                bool ok = true;
                for (int st = tbl_stage; st <= maxstage; ++st) {
                    if (Stage::stage(INGRESS, st)->tcam_match_bus_use[row.row][hbus]) {
                        ok = false;
                        break; } }
                if (ok) {
                    row.bus[Layout::R2L_BUS] = hbus;
                    for (int st = tbl_stage; st <= maxstage; ++st)
                        Stage::stage(INGRESS, st)->tcam_match_bus_use[row.row][hbus] = this;
                    break; } } } }
}

static auto &scm_regs(gress_t gress, int stageno) {
    auto &ppu = TopLevel::regs<Target::Flatrock>()->reg_pipe.ppu_pack;
    Stage *stage = Stage::stage(gress, stageno);
    BUG_CHECK(stage, "invalid stage %s:%d", to_string(gress).c_str(), stageno);
    if (stage->shared_tcam_stage) stage = stage->shared_tcam_stage;
    return ppu.scm[stage->stageno].stage_addrmap;
}

void Target::Flatrock::TernaryMatchTable::gen_match_fields_pvp(json::vector &match_field_list,
        unsigned word, bool uses_versioning, unsigned version_word_group, bitvec &tcam_bits) const {
    // Flatrock does not use payload, version, or parity bits it the tcam, so do nothing
}

void Target::Flatrock::TernaryMatchTable::gen_match_fields(json::vector &match_field_list,
                                                           std::vector<bitvec> &tcam_bits) const {
    unsigned match_index = match.size() - 1;
    for (auto &ixb : input_xbar) {
        for (auto field : *ixb) {
            switch (field.first.type) {
            case InputXbar::Group::TERNARY: {
                int word = match_index - match_word(field.first.index);
                if (word < 0) continue;
                std::string source = "spec";
                std::string field_name = field.second.what.name();
                unsigned lsb_mem_word_offset = 0;
                lsb_mem_word_offset = field.second.lo;
                gen_entry_cfg(match_field_list, field_name,
                              lsb_mem_word_offset, word, word, source,
                              field.second.what.lobit(), field.second.hi -
                              field.second.lo + 1, field.first.index,
                              tcam_bits[word], field.second.what->lo % 4); }
                break;
            default:
                break; } } }
}

void Target::Flatrock::TernaryMatchTable::gen_tbl_cfg(json::vector &out) const {
    ::TernaryMatchTable::gen_tbl_cfg(out);
    if (!local_tind_units.empty()) {
        json::map &tbl = get_tbl_top(out);
        json::vector &stage_tables = tbl["match_attributes"]["stage_tables"];
        BUG_CHECK(stage_tables.size() == 1, "Not exact 1 stage table");
        json::map &stage_tbl = stage_tables[0]->to<json::map>();
        /* build/modify ternary_indirection_stage_table json for these local tinds */
        json::map &tind = stage_tbl["ternary_indirection_stage_table"];
        json::map &mra = tind["memory_resource_allocation"] = json::map();
        mra["memory_type"] = "scm-tind";
        json::vector &mem_units_and_vpns = mra["memory_units_and_vpns"];
        int vpn = 0;
        for (auto tunit : local_tind_units) {
            json::vector units, vpns;
            units.push_back(tunit);
            vpns.push_back(vpn++);
            mem_units_and_vpns.push_back(json::map { { "memory_units", std::move(units) },
                                                     { "vpns", std::move(vpns) } }); }
        tind["pack_format"] = json::vector();  // erase the dummy pack format
        add_pack_format(tind, format.get());
        tind["size"] = local_tind_units.size() * LOCAL_TIND_DEPTH *
                       (LOCAL_TIND_WIDTH >> format->log2size);
    }
}

void Target::Flatrock::TernaryMatchTable::write_regs(Target::Flatrock::mau_regs &regs) {
    LOG1("### Ternary match table " << name() << " write_regs " << loc());
    MatchTable::write_regs(regs, 1, indirect ? indirect : this);

    auto &ppu = TopLevel::regs<Target::Flatrock>()->reg_pipe.ppu_pack;
    bitvec dconfig(0xf);    // FIXME -- could select different bits based on dconfig, but
                            // for now set all 4 variants
    unsigned word = 0;
    int logical_tcam = tcam_id + (gress == EGRESS ? 8 : 0);
    for (auto &row : layout) {
        int minstage = stage->stageno, maxstage = stage->stageno;
        // track which stages' rams are in use for each column in the row, using
        // ingress stage numbers (so reversed when this is an egress table
        if (gress == EGRESS) {
            minstage = EGRESS_STAGE0_INGRESS_STAGE - minstage;
            maxstage = EGRESS_STAGE0_INGRESS_STAGE - maxstage; }
        bitvec ramuse[TCAM_UNITS_PER_ROW];
        for (auto &ram : row.memunits) {
            int stage = ram.stage;
            if (gress == EGRESS)
                stage = EGRESS_STAGE0_INGRESS_STAGE - stage;
            ramuse[ram.col][stage] = 1;
            if (stage < minstage) minstage = stage;
            if (stage > maxstage) maxstage = stage; }
        auto vpn = row.vpns.begin();
        int phys_row = row.row;
        if (TCAM_UNITS_PER_ROW == 1 && phys_row < 10) {
            // when in 20x1 config, reverse the first column so 9 ends up next to 10
            // for wide match combining
            phys_row = 9 - phys_row; }
        int this_stage = stage->stageno;
        if (gress == EGRESS)
            this_stage = EGRESS_STAGE0_INGRESS_STAGE - this_stage;
        auto &scm = ppu.scm[this_stage].stage_addrmap;

        for (auto col = 0; col < TCAM_UNITS_PER_ROW; ++col) {
            int unit = phys_row + TCAM_ROWS * col;
            auto &iss_sel = scm.int_stage_sbus_sel[unit];
            if (minstage < this_stage) {
                int hbus = row.bus.at(Layout::R2L_BUS);
                iss_sel.ig_sel_r2l[hbus] = match.at(word).word_group;
                iss_sel.issb_sel_r2l[hbus] = 2;
                if (minstage > 0)
                    ppu.scm[minstage-1].stage_addrmap.result_bus[unit].isrb_l2r_dis[hbus] |= 2;
                scm.result_bus[unit].isrb_l2r_dis[hbus] = 3;
                for (int st = minstage; st < this_stage; ++st) {
                    if (!ramuse[col][st])
                        ppu.scm[st].stage_addrmap.result_bus[unit].isrb_l2r_dis[hbus] |= 1; } }
            if (maxstage > this_stage) {
                int hbus = row.bus.at(Layout::L2R_BUS);
                iss_sel.ig_sel_l2r[hbus] = match.at(word).word_group;
                iss_sel.issb_sel_l2r[hbus] = 2;
                if (maxstage < LAST_INGRESS_STAGE)
                    ppu.scm[maxstage+1].stage_addrmap.result_bus[unit].isrb_r2l_dis[hbus] |= 2;
                scm.result_bus[unit].isrb_r2l_dis[hbus] = 3;
                for (int st = maxstage; st > this_stage; --st) {
                    if (!ramuse[col][st])
                        ppu.scm[st].stage_addrmap.result_bus[unit].isrb_r2l_dis[hbus] |= 1; } }
            // need to merge to the middle (row 4 or 5) of 10x2 layout
            int direction = (phys_row % 10) < 5 ? +1 : -1;
            for (int row = phys_row; true; row += direction) {
                // The '4' here hardcodes the unsplit priority result.  When we support
                // split or bitmap tcams, this will need to change
                scm.match_merge[row + TCAM_ROWS * col][logical_tcam].enable_ |= 4;
                if (row == 4 || row == 5 || row == 14 || row == 15) break; } }

        for (auto &ram : row.memunits) {
            BUG_CHECK(row.row == ram.row, "ram row mismatch");
            auto &scm = scm_regs(gress, ram.stage);
            int unit = phys_row + TCAM_ROWS * ram.col;
            for (auto d : dconfig)
                scm.chunk_mask[unit].chunk_mask[d] = 0xff;  // FIXME -- for now use whole tcam
            // scm.dconfig_idx[unit] = ??   -- use dconfig
            if (gress == EGRESS)
                scm.search_bus[unit].eg_sel = match.at(word).word_group;
            else
                scm.search_bus[unit].ig_sel = match.at(word).word_group;
            for (auto d : dconfig)
                scm.tcam_mode[unit].chain_out_en[d] = word != match.size() - 1;
            for (unsigned i = 0; i < 5; ++i)
                scm.tcam_mode[unit].dirtcam_mode[i] = (match.at(word).dirtcam >> i*2) & 0b11;
            if (ram.stage == stage->stageno) {
                scm.tcam_mode[unit].key_sel = gress == EGRESS ? 5 : 0;
            } else if ((ram.stage < stage->stageno) ^ (gress == EGRESS)) {
                scm.tcam_mode[unit].key_sel = row.bus.at(Layout::R2L_BUS) + 3;  // R2L bus
            } else {
                scm.tcam_mode[unit].key_sel = row.bus.at(Layout::L2R_BUS) + 1;  // L2R bus
            }
            // scm.tcam_result_ctl[unit] = 0;  leaving this as 0 in all fields is
            // entire tcam as priority (no splitting or bitmap)
            for (auto d : dconfig)
                scm.vpn[unit].vpn[d] = *vpn;
            ++vpn; }

        int idx = 0;
        for (auto tind : local_tind_units) {
            scm.tind_table_cfg[tind].subw_addr_bits = 6 - format->log2size;
            scm.tind_table_cfg[tind].tind_id = idx;
            scm.tind_table_use[logical_tcam].tind_bmp |= 1U << tind;
            ++idx; }
        if (++word == match.size()) word = 0; }

    if (actions) actions->write_regs(regs, this);
    if (gateway) gateway->write_regs(regs);
    if (idletime) idletime->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
}

template<> void TernaryMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs) { BUG(); }
template<> void TernaryIndirectTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Ternary indirect table " << name() << " write_regs");
    error(lineno, "%s:%d: Flatrock ternary indirect not implemented yet!", SRCFILE, __LINE__);
    if (actions) actions->write_regs(regs, this);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
}

