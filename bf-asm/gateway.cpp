#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"
#include "hashexpr.h"
#include "hex.h"

DEFINE_TABLE_TYPE(GatewayTable)

static struct {
    unsigned         units, bits, half_shift, mask, half_mask;
} range_match_info[] = { { 0, 0, 0, 0, 0 }, { 6, 4, 2, 0xf, 0x3 }, { 3, 8, 8, 0xffff, 0xff } };

GatewayTable::Match::Match(value_t *v, value_t &data, range_match_t range_match) {
    if (range_match) {
        for (unsigned i = 0; i < range_match_info[range_match].units; i++)
            range[i] = range_match_info[range_match].mask;
    }
    if (v) {
        lineno = v->lineno;
        if (v->type == tVEC) {
            int last = v->vec.size - 1;
            if (last > static_cast<int>(range_match_info[range_match].units))
                error(lineno, "Too many set values for range match");
            for (int i = 0; i < last; i++)
                if (CHECKTYPE((*v)[last-i-1], tINT)) {
                    if ((unsigned)(*v)[last-i-1].i > range_match_info[range_match].mask)
                        error(lineno, "range match set too large");
                    range[i] = (*v)[last-i-1].i; }
            v = &(*v)[last]; }
        if (v->type == tINT || v->type == tBIGINT) {
            val.word0 = ~(val.word1 = get_int64(*v, 64, "Gateway key too large"));
        } else if (v->type == tMATCH) {
            val = v->m; } }
    if (data == "run_table") {
        run_table = true;
    } else if (data.type == tSTR || data.type == tVEC) {
        next = data;
    } else if (data.type == tMAP) {
        for (auto &kv : MapIterChecked(data.map)) {
            if (kv.key == "next") {
                next = kv.value;
            } else if (kv.key == "run_table") {
                if (kv.value == "true")
                    run_table = true;
                else if (kv.value == "false")
                    run_table = false;
                else
                    error(kv.value.lineno, "Syntax error, expecting boolean");
            } else {
                error(kv.key.lineno, "Syntax error, expecting gateway action description"); }
            }
        if (run_table && next.set())
            error(data.lineno, "Can't run table and override next in the same gateway row");
    } else {
        error(data.lineno, "Syntax error, expecting gateway action description");
    }
}

void GatewayTable::setup(VECTOR(pair_t) &data) {
    setup_logical_id();
    if (auto *v = get(data, "range")) {
        if (CHECKTYPE(*v, tINT)) {
            if (v->i == 2) range_match = DC_2BIT;
            if (v->i == 4)
                range_match = DC_4BIT;
            else
                error(v->lineno, "Unknown range match size %" PRId64 " bits", v->i); } }
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "name") {
            if (CHECKTYPE(kv.value, tSTR))
                gateway_name = kv.value.s;
        } else if (kv.key == "row") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 7)
                error(kv.value.lineno, "row %" PRId64 " out of range", kv.value.i);
            if (layout.empty()) layout.resize(1);
            layout[0].row = kv.value.i;
            layout[0].lineno = kv.value.lineno;
        } else if (kv.key == "bus") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 1)
                error(kv.value.lineno, "bus %" PRId64 " out of range", kv.value.i);
            if (layout.empty()) layout.resize(1);
            layout[0].bus = kv.value.i;
            if (layout[0].lineno < 0)
                layout[0].lineno = kv.value.lineno;
        } else if (kv.key == "payload_row") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 7)
                error(kv.value.lineno, "row %" PRId64 " out of range", kv.value.i);
            if (layout.size() < 2) layout.resize(2);
            layout[1].row = kv.value.i;
            layout[1].lineno = kv.value.lineno;
        } else if (kv.key == "payload_bus") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 3)
                error(kv.value.lineno, "bus %" PRId64 " out of range", kv.value.i);
            if (layout.size() < 2) layout.resize(2);
            layout[1].result_bus = kv.value.i;
            if (layout[1].lineno < 0)
                layout[1].lineno = kv.value.lineno;
        } else if (kv.key == "payload_unit") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 1)
                error(kv.value.lineno, "payload unit %" PRId64 " out of range", kv.value.i);
            payload_unit = kv.value.i;
        } else if (kv.key == "gateway_unit" || kv.key == "unit") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 1)
                error(kv.value.lineno, "gateway unit %" PRId64 " out of range", kv.value.i);
            gw_unit = kv.value.i;
        } else if (kv.key == "input_xbar") {
            if (CHECKTYPE(kv.value, tMAP))
                input_xbar = new InputXbar(this, false, kv.value.map);
        } else if (kv.key == "format") {
            if (CHECKTYPEPM(kv.value, tMAP, kv.value.map.size > 0, "non-empty map"))
                format = new Format(this, kv.value.map);
        } else if (kv.key == "always_run") {
            if ((always_run = get_bool(kv.value)) && !Target::SUPPORT_ALWAYS_RUN())
                error(kv.key.lineno, "always_run not supported on %s", Target::name());
        } else if (kv.key == "miss") {
            miss = Match(0, kv.value, range_match);
        } else if (kv.key == "condition") {
            if (CHECKTYPE(kv.value, tMAP)) {
                for (auto &v : kv.value.map) {
                    if (v.key == "expression" && CHECKTYPE(v.value, tSTR))
                        gateway_cond = v.value.s;
                    else if (v.key == "true")
                        cond_true = Match(0, v.value, range_match);
                    else if (v.key == "false")
                        cond_false = Match(0, v.value, range_match); } }
        } else if (kv.key == "payload") {
            if (CHECKTYPE2(kv.value, tINT, tBIGINT))
                payload = get_int64(kv.value);
            /* FIXME -- should also be able to specify payload as <action name>(<args>) */
            have_payload = kv.key.lineno;
        } else if (kv.key == "payload_map") {
            if (kv.value.type == tVEC) {
                if (kv.value.vec.size > Target::GATEWAY_PAYLOAD_GROUPS())
                    error(kv.value.lineno, "payload_map too large (limit %d)",
                          Target::GATEWAY_PAYLOAD_GROUPS());
                for (auto &v : kv.value.vec) {
                    if (v == "_")
                        payload_map.push_back(-1);
                    else if (CHECKTYPE(v, tINT))
                        payload_map.push_back(v.i); } }
        } else if (kv.key == "match_address") {
            if (CHECKTYPE(kv.value, tINT))
                match_address = kv.value.i;
        } else if (kv.key == "match") {
            if (kv.value.type == tVEC) {
                for (auto &v : kv.value.vec)
                    match.emplace_back(gress, stage->stageno, v);
            } else if (kv.value.type == tMAP) {
                for (auto &v : kv.value.map)
                    if (CHECKTYPE(v.key, tINT))
                        match.emplace_back(v.key.i, gress, stage->stageno, v.value);
            } else {
                match.emplace_back(gress, stage->stageno, kv.value);
            }
        } else if (kv.key == "range") {
            /* done above, to be before match parsing */
        } else if (kv.key == "xor") {
            if (kv.value.type == tVEC) {
                for (auto &v : kv.value.vec)
                    xor_match.emplace_back(gress, stage->stageno, v);
            } else if (kv.value.type == tMAP) {
                for (auto &v : kv.value.map)
                    if (CHECKTYPE(v.key, tINT))
                        xor_match.emplace_back(v.key.i, gress, stage->stageno, v.value);
            } else {
                xor_match.emplace_back(gress, stage->stageno, kv.value);
            }
        } else if (kv.key == "long_branch" && Target::LONG_BRANCH_TAGS() > 0) {
            if (options.disable_long_branch)
                error(kv.key.lineno, "long branches disabled");
            if (CHECKTYPE(kv.value, tMAP)) {
                for (auto &lb : kv.value.map) {
                    if (lb.key.type != tINT || lb.key.i < 0 ||
                        lb.key.i >= Target::LONG_BRANCH_TAGS())
                        error(lb.key.lineno, "Invalid long branch tag %s", value_desc(lb.key));
                    else if (long_branch.count(lb.key.i))
                        error(lb.key.lineno, "Duplicate long branch tag %" PRIi64, lb.key.i);
                    else
                        long_branch.emplace(lb.key.i, lb.value); } }
        } else if (kv.key == "context_json") {
            setup_context_json(kv.value);
        } else if (kv.key.type == tINT || kv.key.type == tBIGINT || kv.key.type == tMATCH ||
                   (kv.key.type == tVEC && range_match != NONE)) {
            table.emplace_back(&kv.key, kv.value, range_match);
        } else {
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name());
        }
    }
}

static void check_match_key(Table *tbl, std::vector<GatewayTable::MatchKey> &vec,
                            const char *name, unsigned max) {
    for (unsigned i = 0; i < vec.size(); i++) {
        if (!vec[i].val.check())
            break;
        if (vec[i].val->reg.mau_id() < 0)
            error(vec[i].val.lineno, "%s not accessable in mau", vec[i].val->reg.name);
        if (vec[i].offset >= 0) {
            for (unsigned j = 0; j < i; ++j) {
                if (vec[i].offset < vec[j].offset + static_cast<int>(vec[j].val->size()) &&
                    vec[j].offset < vec[i].offset + static_cast<int>(vec[i].val->size()))
                    error(vec[i].val.lineno, "Gateway %s key at offset %d overlaps previous "
                          "value at offset %d", name, vec[i].offset, vec[j].offset); }
        } else {
            vec[i].offset = i ? vec[i-1].offset + vec[i-1].val->size() : 0;
        }
        if (vec[i].offset < 32 && (vec[i].offset & 7) != (vec[i].val->lo & 7))
            error(vec[i].val.lineno, "Gateway %s key %s misaligned within byte", name,
                  vec[i].val.name());

        if (vec[i].offset + vec[i].val->size() > max) {
            error(vec[i].val.lineno, "Gateway %s key too big", name);
            break; }
        if (vec[i].offset >= 32 && tbl->input_xbar) {
            auto hash = tbl->input_xbar->hash_column(vec[i].offset + 8);
            if (hash.size() != 1 || hash[0]->bit || !hash[0]->fn ||
                !hash[0]->fn->match_phvref(vec[i].val))
                error(vec[i].val.lineno, "Gateway %s key %s not in matching hash column", name,
                      vec[i].val.name()); } }
}

void GatewayTable::verify_format() {
    if (format->log2size > 6)
        error(format->lineno, "Gateway payload format too large (max 64 bits)");
    format->log2size = 6;
    format->pass1(this);
    if (format->groups() > Target::GATEWAY_PAYLOAD_GROUPS())
        error(format->lineno, "Too many groups for gateway payload");
    if (payload_map.empty()) {
        if (format->groups() == 1) {
            payload_map.push_back(0);
        } else {
            payload_map = std::vector<int>(Target::GATEWAY_PAYLOAD_GROUPS(), -1);
            int i = Target::GATEWAY_PAYLOAD_GROUPS() - 2;
            int grp = 0;
            for (auto &row : table) {
                if (!row.run_table && i >= 0) {
                    if (grp >= format->groups() && format->groups() > 1) {
                        error(format->lineno, "Not enough groups in format for payload");
                        grp = 0; }
                    payload_map[i--] = grp++; } }
            if (!miss.run_table)
                payload_map.back() = format->groups() - 1; } }
    for (auto pme : payload_map) {
        if (pme < -1 || pme >= int(format->groups()))
            error(format->lineno, "Invalid format group %d in payload_map", pme); }
    if (match_table) {
        if (match_table->table_type() == TERNARY) {
            if (format->groups() > 1)
                error(format->lineno, "Can't have mulitple payload format groups when attached "
                      "to a ternary table");
        } else if (!match_table->format) {
            // ok
        } else if (auto *srm = match_table->to<SRamMatchTable>()) {
            int groups = std::min(format->groups(), match_table->format->groups());
            bool err = false;
            for (auto &field : *format) {
                if (auto match_field = match_table->format->field(field.first)) {
                    int match_group = -1;
                    for (auto gw_group : payload_map) {
                        ++match_group;
                        if (gw_group < 0) continue;
                        int em_group = match_group;
                        if (!srm->word_info.empty()) {
                            if (match_group < srm->word_info[0].size())
                                em_group = srm->word_info[0][match_group];
                            else
                                em_group = -1; }
                        if (em_group < 0) continue;
                        if (field.second.by_group[gw_group]->bits !=
                            match_field->by_group[em_group]->bits) {
                            if (!err) {
                                error(format->lineno, "Gateway format inconsistent with table "
                                      "%s it is attached to", match_table->name());
                                error(match_table->format->lineno, "field %s inconsistent",
                                      field.first.c_str());
                                err = true;
                                break; } } }
                } else {
                    if (!err)
                        error(format->lineno, "Gateway format inconsistent with table %s it is "
                              "attached to", match_table->name());
                    error(match_table->format->lineno, "No field %s in match table format",
                          field.first.c_str());
                    err = true; } } }
    } else if (layout.size() > 1) {
        if (layout[1].result_bus < 0 || layout[1].result_bus > 3)
            error(layout[1].lineno, "Invalid bus %d for gateway payload",  layout[1].result_bus);
        if ((layout[1].result_bus & 2) && format->groups() > 1)
            error(format->lineno, "Can't have mulitple payload format groups when using "
                  "ternary indirect bus"); }
}

void GatewayTable::pass1() {
    LOG1("### Gateway table " << name() << " pass1 " << loc());
    Table::pass1();
    alloc_id("logical", logical_id, stage->pass1_logical_id,
             LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    /* in a gateway, the layout has one or two rows -- layout[0] specifies the gateway, and
     * layout[1] specifies the payload. There will be no columns in either row */
    if (layout.empty() || layout[0].row < 0)
        error(lineno, "No row specified in gateway");
    else if (layout[0].bus < 0 && (!match.empty() || !xor_match.empty()))
        error(lineno, "No bus specified in gateway to read from");
    if (payload_unit >= 0 && have_payload < 0 && match_address < 0)
        error(lineno, "payload_unit with no payload or match address in gateway");
    if (layout.size() > 1) {
        if (layout[1].result_bus >= 0 && (have_payload >= 0 || match_address >= 0)) {
            if (payload_unit < 0) {
                payload_unit = layout[1].result_bus & 1;
            } else if (payload_unit != layout[1].result_bus & 1) {
                error(layout[1].lineno, "payload unit %d cannot write to result bus %d",
                      payload_unit, layout[1].result_bus); } }
        if (layout[1].row < 0) {
            error(layout[1].lineno, "payload_bus with no payload_row in gateway");
        } else if (Table *tbl = match_table) {
            if (auto *tmatch = dynamic_cast<TernaryMatchTable *>(tbl))
                tbl = tmatch->indirect;
            if (tbl && !tbl->layout.empty()) {
                for (auto &r : tbl->layout) {
                    if (r.row != layout[1].row) continue;
                    auto match_rbus = r.result_bus >= 0 ? r.result_bus : r.bus;
                    if (match_rbus >= 0 && payload_unit >= 0 && payload_unit != (match_rbus & 1))
                        continue;
                    auto &gw_rbus = layout[1].result_bus;
                    if (match_rbus == gw_rbus || gw_rbus < 0) {
                        if (gw_rbus < 0 && match_rbus >= 0)
                            gw_rbus = match_rbus;
                        if (tbl->to<TernaryIndirectTable>())
                            layout[1].result_bus |= 2;
                        break; } } }
        } else if (have_payload >= 0 || match_address >= 0) {
            if (payload_unit) {
                if (auto *old = stage->gw_payload_use[layout[1].row][payload_unit])
                    error(layout[1].lineno, "payload %d.%d already in use by table %s",
                          layout[1].row, payload_unit, old->name());
                else
                    stage->gw_payload_use[layout[1].row][payload_unit] = this; }
        } else if (payload_unit >= 0) {
            error(lineno, "payload_unit with no payload or match address in gateway"); }
    } else if ((have_payload >= 0 || match_address >= 0) && !match_table) {
        error(have_payload, "payload on standalone gateway requires explicit payload_row");
    } else if (payload_unit >= 0 && match_table) {
        bool ternary = false;
        Table *tbl = match_table;
        if (auto *tmatch = dynamic_cast<TernaryMatchTable *>(tbl)) {
            ternary = true;
            tbl = tmatch->indirect; }
        if (!tbl || tbl->layout.empty()) {
            error(lineno, "No result busses in table %s for gateway payload", match_table->name());
        } else {
            for (auto &r : tbl->layout) {
                auto match_rbus = r.result_bus >= 0 ? r.result_bus : r.bus;
                if (match_rbus >= 0 && payload_unit != (match_rbus & 1)) continue;
                if (!stage->gw_payload_use[r.row][payload_unit]) {
                    layout.resize(2);
                    layout[1].row = r.row;
                    if (r.result_bus >= 0)
                        layout[1].result_bus = r.result_bus;
                    else
                        layout[1].result_bus = r.bus | (ternary ? 2 : 0);
                    stage->gw_payload_use[r.row][payload_unit] = this;
                    break; } }
            if (layout.size() < 2)
                error(lineno, "No row in table %s has payload unit %d free", tbl->name(),
                      payload_unit); } }
    if (layout.size() > 1 && layout[1].result_bus >= 0) {
        Table *tbl = match_table;
        if (auto *tmatch = dynamic_cast<TernaryMatchTable *>(tbl))
            tbl = tmatch->indirect;
        if (!tbl) tbl = this;
        auto &result_bus = (layout[1].result_bus & 2) ? stage->tcam_indirect_bus_use
                                                      : stage->match_result_bus_use;
        auto *old = result_bus[layout[1].row][layout[1].result_bus & 1];
        if (old && old != tbl)
            error(layout[1].lineno, "Gateway payload result bus %d conflict on row %d between "
                  "%s and %s", layout[1].result_bus, layout[1].row, name(), old->name());
        result_bus[layout[1].row][layout[1].result_bus & 1] = tbl;
    }
    if (always_run && match_table)
        error(lineno, "always_run set on non-standalone gateway for %s", match_table->name());
    if (gw_unit >= 0) {
        if (auto *old = stage->gw_unit_use[layout[0].row][gw_unit])
            error(layout[0].lineno, "gateway %d.%d already in use by table %s", layout[0].row,
                  gw_unit, old->name());
        else
            stage->gw_unit_use[layout[0].row][gw_unit] = this; }
    if (input_xbar) {
        input_xbar->pass1();
        if (input_xbar->match_group() < 0)
            error(input_xbar->lineno, "Gateway match keys must be in a single ixbar group"); }
    check_match_key(this, match, "match", 44);
    check_match_key(this, xor_match, "xor", 32);
    std::sort(match.begin(), match.end());
    std::sort(xor_match.begin(), xor_match.end());
    if (table.size() > 4)
        error(lineno, "Gateway can only have 4 match entries max");
    for (auto &line : table)
        check_next(line.next);
    check_next(miss.next);
    check_next(cond_false.next);
    check_next(cond_true.next);
    if (error_count > 0) return;
    /* FIXME -- the rest of this function is a hack -- sometimes the compiler wants to
     * generate matches just covering the bits it names in the match and other times it wants
     * to create the whole tcam value.  Need to fix the asm syntax to be sensible and fix the
     * compiler's output */
    uint64_t ignore = UINT64_MAX;
    int shift = -1;
    for (auto &r : match) {
        if (range_match && r.offset >= 32) {
            continue; }
        ignore ^= bitMask(r.val->size()) << r.offset;
        if (shift < 0 || shift > r.offset) shift = r.offset; }
    if (shift < 0) shift = 0;
    LOG3("shift=" << shift << " ignore=0x" << hex(ignore));
    for (auto &line : table) {
        auto ign = ~(line.val.word0 ^ line.val.word1);
        if (ign == 0) ign = line.val.word0;
        if ((ign & ~(~ignore >> shift)) != ~(~ignore >> shift))
            warning(line.lineno, "Trying to match on bits not in match of gateway");
        line.val.word0 = (line.val.word0 << shift) | ignore;
        line.val.word1 = (line.val.word1 << shift) | ignore; }
    if (format)
        verify_format();
}

static int find_next_lut_entry(Table *tbl, const Table::NextTables &next) {
    int rv = 0;
    for (auto &e : tbl->hit_next) {
        if (e == next) return rv;
        ++rv; }
    for (auto &e : tbl->extra_next_lut) {
        if (e == next) return rv;
        ++rv; }
    tbl->extra_next_lut.push_back(next);
    if (rv == NEXT_TABLE_SUCCESSOR_TABLE_DEPTH)
        error(tbl->lineno, "Too many next table map entries in table %s", tbl->name());
    return rv;
}

void GatewayTable::pass2() {
    LOG1("### Gateway table " << name() << " pass2 " << loc());
    if (logical_id < 0)  {
        if (match_table)
            logical_id = match_table->logical_id;
        else
            choose_logical_id(); }
    if (gw_unit < 0) {
        if (layout[0].bus >= 0 && !stage->gw_unit_use[layout[0].row][layout[0].bus]) {
            gw_unit = layout[0].bus;
        } else {
            for (int i = 0; i < 2; ++i) {
                if (!stage->gw_unit_use[layout[0].row][i] &&
                    !stage->sram_search_bus_use[layout[0].row][i]) {
                    gw_unit = i;
                    break; } } }
        if (gw_unit < 0)
            error(layout[0].lineno, "No gateway units available on row %d", layout[0].row);
        else
            stage->gw_unit_use[layout[0].row][gw_unit] = this; }
    if (layout[0].bus < 0 && gw_unit >= 0)
        layout[0].bus = gw_unit;
    if (payload_unit < 0 && (have_payload >= 0 || match_address >= 0)) {
        if (layout.size() > 1) {
            if (layout[1].result_bus < 0) {
                if (!stage->gw_payload_use[layout[1].row][0])
                    payload_unit = 0;
                else if (!stage->gw_payload_use[layout[1].row][1])
                    payload_unit = 1;
            } else if (!stage->gw_payload_use[layout[1].row][layout[1].result_bus & 1]) {
                payload_unit = layout[1].bus & 1; }
            if (payload_unit >= 0)
                stage->gw_payload_use[layout[1].row][payload_unit] = this;
            else
                error(lineno, "No payload available on row %d", layout[1].row);
        } else if (Table *tbl = match_table) {
            bool ternary = false;
            if (auto *tmatch = dynamic_cast<TernaryMatchTable *>(tbl)) {
                tbl = tmatch->indirect;
                ternary = true; }
            if (tbl && !tbl->layout.empty()) {
                for (auto &row : tbl->layout) {
                    auto match_rbus = row.result_bus >= 0 ? row.result_bus : row.bus;
                    BUG_CHECK(match_rbus >= 0);  // alloc_busses on the match table must run first
                    if (stage->gw_payload_use[row.row][match_rbus & 1]) {
                        continue;
                    } else {
                        payload_unit = match_rbus & 1; }
                    stage->gw_payload_use[row.row][payload_unit] = this;
                    layout.resize(2);
                    layout[1].row = row.row;
                    layout[1].result_bus = match_rbus | (ternary ? 2 : 0);
                    break; }
                if (payload_unit < 0)
                    error(lineno, "No row in table %s has a free payload unit", tbl->name());
            } else {
                error(lineno, "No result busses in table %s for gateway payload",
                      match_table->name()); } } }
    if (payload_unit >= 0 && layout[1].result_bus < 0) {
        BUG_CHECK(layout.size() > 1);
        int row = layout[1].row;
        Table *tbl = match_table;
        int ternary = tbl ? 0 : -1;
        if (auto *tmatch = dynamic_cast<TernaryMatchTable *>(tbl)) {
            ternary = 1;
            tbl = tmatch->indirect ? tmatch->indirect : tmatch; }
        if (!tbl) tbl = this;
        for (int i = payload_unit; i < 4; i += 2) {
            if (ternary >= 0 && (i >> 1) != ternary) continue;
            auto &result_bus = (i & 2) ? stage->tcam_indirect_bus_use : stage->match_result_bus_use;
            if (!result_bus[row][i & 1] || result_bus[row][i & 1] == tbl) {
                layout[1].result_bus = i;
                result_bus[row][i & 1] = tbl;
                break; } }
        if (layout[1].result_bus < 0) {
            error(lineno, "No result bus available for gateway payload of table %s on row %d",
                  name(), layout[1].row); } }
    if (input_xbar) input_xbar->pass2();
    need_next_map_lut = miss.next.need_next_map_lut();
    for (auto &e : table)
        need_next_map_lut |= e.next.need_next_map_lut();
    if (need_next_map_lut) {
        Table *tbl = match_table;
        if (!tbl) tbl = this;
        for (auto &e : table)
            if (!e.run_table)
                e.next_map_lut = find_next_lut_entry(tbl, e.next);
        if (!miss.run_table)
            miss.next_map_lut = find_next_lut_entry(tbl, miss.next); }
}

void GatewayTable::pass3() {
    LOG1("### Gateway table " << name() << " pass3 " << loc());
    if (layout[0].bus >= 0) {
        auto *tbl = stage->sram_search_bus_use[layout[0].row][layout[0].bus];
        // Sharing with an exact match -- make sure it is ok
        if (tbl && input_xbar) {
            auto *sram_tbl = tbl->to<SRamMatchTable>();
            BUG_CHECK(sram_tbl, "%s is not an SRamMatch table even though it is using a "
                      "search bus?", tbl->name());
            SRamMatchTable::WayRam *way = nullptr;
            for (auto &row : sram_tbl->layout) {
                if (row.row == layout[0].row && row.bus == layout[0].bus) {
                    if (row.cols.empty()) {
                        // FIXME -- not really used, so we don't need to check the
                        // match/hash group.  Should this be an asm error?
                        return; }
                    way = &sram_tbl->way_map.at(std::make_pair(row.row, row.cols[0]));
                    break; } }
            BUG_CHECK(way, "%s claims to use search bus %d.%d, but we can't find it in the layout",
                      sram_tbl->name(), layout[0].row, layout[0].bus);
            if (input_xbar->hash_group() >= 0 && sram_tbl->ways[way->way].group >= 0 &&
                input_xbar->hash_group() != sram_tbl->ways[way->way].group) {
                error(layout[0].lineno, "%s sharing search bus %d.%d with %s, but wants a "
                      "different hash group", name(), layout[0].row, layout[0].bus, tbl->name());
            }
            if (input_xbar->match_group() >= 0 && sram_tbl->word_ixbar_group[way->word] >= 0 &&
                input_xbar->match_group() != sram_tbl->word_ixbar_group[way->word]) {
                error(layout[0].lineno, "%s sharing search bus %d.%d with %s, but wants a "
                      "different match group", name(), layout[0].row, layout[0].bus, tbl->name());
            }
        }
    }
}

static unsigned match_input_use(const std::vector<GatewayTable::MatchKey> &match) {
    unsigned rv = 0;
    for (auto &r : match) {
        unsigned lo = r.offset;
        unsigned hi = lo + r.val->size() - 1;
        if (lo < 32) {
            rv |= (((UINT32_C(1) << (hi/8 - lo/8 + 1)) - 1) << lo/8) & 0xf;
            lo = 32; }
        if (lo <= hi)
            rv |= ((UINT32_C(1) << (hi - lo + 1)) - 1) << (lo-24); }
    return rv;
}

/* caluclate match_bus byte use (8 bytes/bits) + hash output use (12 bits) */
unsigned GatewayTable::input_use() const {
    unsigned rv = match_input_use(match) | match_input_use(xor_match);
    if (!xor_match.empty())
        rv |= (rv & 0xf) >> 4;
    return rv;
}

bool GatewayTable::is_branch() const {
    for (auto &line : table)
        if (line.next.next_table() != nullptr)
            return true;
    if (!miss.run_table && miss.next.next_table() != nullptr)
        return true;
    return false;
}

/* FIXME -- how to deal with (or even specify) matches in the upper 24 bits coming from
 * the hash bus?   Currently we assume that the input_xbar is declared to set up the
 * hash signals correctly so that we can just match them.  Should at least check it
 * somewhere, somehow. We do some checking in check_match_key above, but is that enough?
 * See P4C-2171
 */
template<class REGS>
static bool setup_vh_xbar(REGS &regs, Table *table, Table::Layout &row, int base,
                          std::vector<GatewayTable::MatchKey> &match, int group) {
    auto &rams_row = regs.rams.array.row[row.row];
    auto &byteswizzle_ctl = rams_row.exactmatch_row_vh_xbar_byteswizzle_ctl[row.bus];
    for (auto &r : match) {
        if (r.offset >= 32) break; /* skip hash matches */
        for (int bit = 0; bit < r.val->size(); ++bit) {
            int ibyte = table->find_on_ixbar(*Phv::Ref(r.val, bit, bit), group);
            if (ibyte < 0) {
                error(r.val.lineno, "Can't find %s(%d) on ixbar", r.val.desc().c_str(), bit);
                return false; }
            unsigned byte = base + (r.offset + bit)/ 8;
            byteswizzle_ctl[byte][(r.val->lo + bit) & 7] = 0x10 + ibyte; } }
    return true;
}

template<class REGS> void enable_gateway_payload_exact_shift_ovr(REGS &regs, int bus) {
    regs.rams.match.merge.gateway_payload_exact_shift_ovr[bus/8] |= 1U << bus % 8;
}

#include "tofino/gateway.cpp"
#if HAVE_JBAY
#include "jbay/gateway.cpp"
#endif  // HAVE_JBAY
#if HAVE_CLOUDBREAK
#include "cloudbreak/gateway.cpp"
#endif  // HAVE_CLOUDBREAK

template<class REGS>
void GatewayTable::payload_write_regs(REGS &regs, int row, int type, int bus) {
    auto &merge = regs.rams.match.merge;
    auto &xbar_ctl = merge.gateway_to_pbus_xbar_ctl[row*2 + bus];
    if (type) {
        xbar_ctl.tind_logical_select = logical_id;
        xbar_ctl.tind_inhibit_enable = 1;
    } else {
        xbar_ctl.exact_logical_select = logical_id;
        xbar_ctl.exact_inhibit_enable = 1; }
    if (have_payload >= 0 || match_address >= 0) {
        BUG_CHECK(payload_unit == bus);
        if (type)
            merge.gateway_payload_tind_pbus[row] |= 1 << bus;
        else
            merge.gateway_payload_exact_pbus[row] |= 1 << bus; }
    if (have_payload >= 0) {
        merge.gateway_payload_data[row][bus][0][type] = payload & 0xffffffff;
        merge.gateway_payload_data[row][bus][1][type] = payload >> 32;
        merge.gateway_payload_data[row][bus][0][type^1] = payload & 0xffffffff;
        merge.gateway_payload_data[row][bus][1][type^1] = payload >> 32; }
    if (match_address >= 0) {
        merge.gateway_payload_match_adr[row][bus][type] = match_address;
        merge.gateway_payload_match_adr[row][bus][type^1] = match_address;
    } else if (options.target == TOFINO) {
        // For Tofino A0, there is a bug in snapshot that cannot distinguish if a
        // gateway is inhibiting a table To work around this, configure the
        // gateway_payload_match_adr to an invalid value. Add a command line flag
        // if this is only a tofino A0 issue?.
        merge.gateway_payload_match_adr[row][bus][type] = 0x7ffff;
        merge.gateway_payload_match_adr[row][bus][type^1] = 0x7ffff; }

    int groups = format ? format->groups() : 1;
    if (groups > 1 || payload_map.size() > 1) {
        BUG_CHECK(type == 0);  // only supported on exact result busses
        enable_gateway_payload_exact_shift_ovr(regs, row*2 + bus); }

    int tcam_shift = 0;
    if (type != 0 && format) {
        auto match_table = get_match_table();
        if (match_table) {
            auto ternary_table = match_table->to<TernaryMatchTable>();
            if (ternary_table && ternary_table->has_indirect()) {
                tcam_shift = format->log2size-2;
            }
        }
    }

    if (format) {
        if (auto *attached = get_attached()) {
            for (auto &st : attached->stats) {
                if (type == 0) {
                    for (unsigned i = 0; i < payload_map.size(); ++i) {
                        auto grp = payload_map.at(i);
                        if (grp < 0) continue;
                        merge.mau_stats_adr_exact_shiftcount[row*2 + bus][i]
                            = st->determine_shiftcount(st, grp, 0, 0); }
                } else {
                    merge.mau_stats_adr_tcam_shiftcount[row*2 + bus]
                        = st->determine_shiftcount(st, 0, 0, tcam_shift);
                }
                break;
            }

            for (auto &m : attached->meters) {
                if (type == 0) {
                    for (unsigned i = 0; i < payload_map.size(); ++i) {
                        auto grp = payload_map.at(i);
                        if (grp < 0) continue;
                        merge.mau_meter_adr_exact_shiftcount[row*2 + bus][i]
                            = m->determine_shiftcount(m, grp, 0, 0);
                        if (m->uses_colormaprams()) {
                            int color_shift = m->color_shiftcount(attached->meter_color, i, 0);
                            if (m->color_addr_type() == MeterTable::IDLE_MAP_ADDR) {
                                merge.mau_idletime_adr_exact_shiftcount[row*2 + bus][i]
                                    = color_shift;
                                merge.mau_payload_shifter_enable[0][row*2 + bus]
                                    .idletime_adr_payload_shifter_en = 1;
                            } else if (m->color_addr_type() == MeterTable::STATS_MAP_ADDR) {
                                merge.mau_stats_adr_exact_shiftcount[row*2 + bus][i] = color_shift;
                                merge.mau_payload_shifter_enable[0][row*2 + bus]
                                    .stats_adr_payload_shifter_en = 1;
                            }
                        }
                    }
                } else {
                    merge.mau_meter_adr_tcam_shiftcount[row*2 + bus]
                        = m->determine_shiftcount(m, 0, 0, tcam_shift);
                    if (m->uses_colormaprams()) {
                        int color_shift = m->color_shiftcount(attached->meter_color, 0, 0);
                        if (m->color_addr_type() == MeterTable::IDLE_MAP_ADDR) {
                            merge.mau_idletime_adr_tcam_shiftcount[row*2 + bus] = color_shift;
                            merge.mau_payload_shifter_enable[1][row*2 + bus]
                                .idletime_adr_payload_shifter_en = 1;
                        } else if (m->color_addr_type() == MeterTable::STATS_MAP_ADDR) {
                            merge.mau_stats_adr_tcam_shiftcount[row*2 + bus] = color_shift;
                            merge.mau_payload_shifter_enable[1][row*2 + bus]
                                .stats_adr_payload_shifter_en = 1;
                        }
                    }
                }
                break;
            }
            for (auto &s : attached->statefuls) {
                if (type == 0) {
                    for (unsigned i = 0; i < payload_map.size(); ++i) {
                        auto grp = payload_map.at(i);
                        if (grp < 0) continue;
                        merge.mau_meter_adr_exact_shiftcount[row*2 + bus][i]
                            = s->determine_shiftcount(s, grp, 0, 0); }
                } else {
                    merge.mau_meter_adr_tcam_shiftcount[row*2 + bus]
                        = s->determine_shiftcount(s, 0, 0, tcam_shift);
                }
                break;
            }
        }
    }

    if (match_table && match_table->instruction) {
        if (auto field = match_table->instruction.args[0].field()) {
            if (type == 0) {
                for (unsigned i = 0; i < payload_map.size(); ++i) {
                    auto grp = payload_map.at(i);
                    if (grp < 0) continue;
                    merge.mau_action_instruction_adr_exact_shiftcount[row*2 + bus][i]
                        = field->by_group[grp]->bit(0); }
            } else {
                merge.mau_action_instruction_adr_tcam_shiftcount[row*2 + bus] = field->bit(0)
                                                                                + tcam_shift;
            }
        }
    } else if (auto *action = format ? format->field("action") : nullptr) {
        if (type == 0) {
            for (unsigned i = 0; i < payload_map.size(); ++i) {
                auto grp = payload_map.at(i);
                if (grp < 0) continue;
                merge.mau_action_instruction_adr_exact_shiftcount[row*2 + bus][i]
                    = action->by_group[grp]->bit(0); }
        } else {
            merge.mau_action_instruction_adr_tcam_shiftcount[row*2 + bus] = action->bit(0)
                                                                             + tcam_shift;
        }
    }

    if (format && format->immed) {
        if (type == 0) {
            for (unsigned i = 0; i < payload_map.size(); ++i) {
                auto grp = payload_map.at(i);
                if (grp < 0) continue;
                merge.mau_immediate_data_exact_shiftcount[row*2 + bus][i]
                    = format->immed->by_group[grp]->bit(0); }
        } else {
            merge.mau_immediate_data_tcam_shiftcount[row*2 + bus] = format->immed->bit(0)
                                                                    + tcam_shift;
        }
        // FIXME -- may be redundant witehr writing this for the match table,
        // but should always be consistent
        merge.mau_immediate_data_mask[type][row*2 + bus] = bitMask(format->immed_size);
        merge.mau_payload_shifter_enable[type][row*2 + bus].immediate_data_payload_shifter_en = 1;
    }

    if (type) {
        merge.tind_bus_prop[row*2 + bus].tcam_piped = 1;
        merge.tind_bus_prop[row*2 + bus].thread = gress;
        merge.tind_bus_prop[row*2 + bus].enabled = 1;
    } else {
        merge.exact_match_phys_result_en[row/4U] |= 1U << (row%4U * 2 + bus);
        merge.exact_match_phys_result_thread[row/4U] |= gress << (row%4U * 2 + bus);
        if (stage->tcam_delay(gress))
            merge.exact_match_phys_result_delay[row/4U] |= 1U << (row%4U * 2 + bus); }
}


template<class REGS> void GatewayTable::standalone_write_regs(REGS &regs) { }

template<class REGS>
void GatewayTable::write_regs(REGS &regs) {
    LOG1("### Gateway table " << name() << " write_regs " << loc());
    auto &row = layout[0];
    if (input_xbar) {
        // FIXME -- if there's no ixbar in the gateway, we should look for a group with
        // all the match/xor values across all the exact match groups in the stage and use
        // that.  See P4C-2171
        input_xbar->write_regs(regs);
        if (!setup_vh_xbar(regs, this, row, 0, match, input_xbar->match_group()) ||
            !setup_vh_xbar(regs, this, row, 4, xor_match, input_xbar->match_group()))
            return; }
    auto &row_reg = regs.rams.array.row[row.row];
    auto &gw_reg = row_reg.gateway_table[gw_unit];
    auto &merge = regs.rams.match.merge;
    if (row.bus == 0) {
        gw_reg.gateway_table_ctl.gateway_table_input_data0_select = 1;
        gw_reg.gateway_table_ctl.gateway_table_input_hash0_select = 1;
    } else {
        BUG_CHECK(row.bus == 1);
        gw_reg.gateway_table_ctl.gateway_table_input_data1_select = 1;
        gw_reg.gateway_table_ctl.gateway_table_input_hash1_select = 1; }
    if (input_xbar && input_xbar->hash_group() >= 0)
        setup_muxctl(row_reg.vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[row.bus],
                     input_xbar->hash_group());
    if (input_xbar && input_xbar->match_group() >= 0) {
        auto &vh_xbar_ctl = row_reg.vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl;
        setup_muxctl(vh_xbar_ctl, input_xbar->match_group());
        /* vh_xbar_ctl.exactmatch_row_vh_xbar_thread = gress; */ }
    gw_reg.gateway_table_ctl.gateway_table_logical_table = logical_id;
    gw_reg.gateway_table_ctl.gateway_table_thread = timing_thread(gress);
    for (auto &r : xor_match)
        gw_reg.gateway_table_matchdata_xor_en |= bitMask(r.val->size()) << r.offset;
    int idx = 3;
    gw_reg.gateway_table_ctl.gateway_table_mode = range_match;
    for (auto &line : table) {
        BUG_CHECK(idx >= 0);
        /* FIXME -- hardcoding version/valid to always */
        gw_reg.gateway_table_vv_entry[idx].gateway_table_entry_versionvalid0 = 0x3;
        gw_reg.gateway_table_vv_entry[idx].gateway_table_entry_versionvalid1 = 0x3;
        gw_reg.gateway_table_entry_matchdata[idx][0] = line.val.word0 & 0xffffffff;
        gw_reg.gateway_table_entry_matchdata[idx][1] = line.val.word1 & 0xffffffff;
        if (range_match) {
            auto &info = range_match_info[range_match];
            for (unsigned i = 0; i < range_match_info[range_match].units; i++) {
                gw_reg.gateway_table_data_entry[idx][0] |=
                    (line.range[i] & info.half_mask) << (i * info.bits);
                gw_reg.gateway_table_data_entry[idx][1] |=
                    ((line.range[i] >> info.half_shift) & info.half_mask) << (i * info.bits); }
        } else {
            gw_reg.gateway_table_data_entry[idx][0] = (line.val.word0 >> 32) & 0xffffff;
            gw_reg.gateway_table_data_entry[idx][1] = (line.val.word1 >> 32) & 0xffffff; }
        if (!line.run_table) {
            merge.gateway_inhibit_lut[logical_id] |= 1 << idx; }
        idx--; }
    if (!miss.run_table) {
        merge.gateway_inhibit_lut[logical_id] |= 1 << 4; }
    write_next_table_regs(regs);
    merge.gateway_en |= 1 << logical_id;
    setup_muxctl(merge.gateway_to_logicaltable_xbar_ctl[logical_id], row.row*2 + gw_unit);
    if (layout.size() > 1) {
        BUG_CHECK(layout[1].result_bus >= 0);
        payload_write_regs(regs, layout[1].row, layout[1].result_bus >> 1,
                           layout[1].result_bus & 1);
    }
    if (Table *tbl = match_table) {
        bool tind_bus = false;
        auto *tmatch = dynamic_cast<TernaryMatchTable *>(tbl);
        if (tmatch) {
            tind_bus = true;
            tbl = tmatch->indirect;
        } else if (auto *hashaction = dynamic_cast<HashActionTable *>(tbl)) {
            tind_bus = hashaction->layout[0].bus >= 2;
        }
        if (tbl) {
            for (auto &row : tbl->layout) {
                BUG_CHECK(row.result_bus_initialized());
                if (row.result_bus >= 0) {
                    auto &xbar_ctl = merge.gateway_to_pbus_xbar_ctl[row.row * 2 + row.result_bus];
                    if (tind_bus) {
                        xbar_ctl.tind_logical_select = logical_id;
                        xbar_ctl.tind_inhibit_enable = 1;
                    } else {
                        xbar_ctl.exact_logical_select = logical_id;
                        xbar_ctl.exact_inhibit_enable = 1;
                    }
                }
            }
        } else {
            BUG_CHECK(tmatch);
            auto &xbar_ctl = merge.gateway_to_pbus_xbar_ctl[tmatch->indirect_bus];
            xbar_ctl.tind_logical_select = logical_id;
            xbar_ctl.tind_inhibit_enable = 1; }
    } else {
        if (gress != GHOST)
            merge.predication_ctl[gress].table_thread |= 1 << logical_id;
        if (gress == INGRESS || gress == GHOST) {
            merge.logical_table_thread[0].logical_table_thread_ingress |= 1 << logical_id;
            merge.logical_table_thread[1].logical_table_thread_ingress |= 1 << logical_id;
            merge.logical_table_thread[2].logical_table_thread_ingress |= 1 << logical_id;
        } else if (gress == EGRESS) {
            regs.dp.imem_table_addr_egress |= 1 << logical_id;
            merge.logical_table_thread[0].logical_table_thread_egress |= 1 << logical_id;
            merge.logical_table_thread[1].logical_table_thread_egress |= 1 << logical_id;
            merge.logical_table_thread[2].logical_table_thread_egress |= 1 << logical_id; }
        auto &adrdist = regs.rams.match.adrdist;
        adrdist.adr_dist_table_thread[timing_thread(gress)][0] |= 1 << logical_id;
        adrdist.adr_dist_table_thread[timing_thread(gress)][1] |= 1 << logical_id;
        // FIXME -- allow table_counter on standalone gateay?  What can it count?
        if (options.match_compiler)
            merge.mau_table_counter_ctl[logical_id/8U].set_subfield(4, 3 * (logical_id%8U), 3);
        standalone_write_regs(regs); }
    if (stage->tcam_delay(gress) > 0)
        merge.exact_match_logical_result_delay |= 1 << logical_id;
}

std::set<std::string> gateways_in_json;
void GatewayTable::gen_tbl_cfg(json::vector &out) const {
    // Avoid adding gateway table multiple times to the json. The gateway table
    // gets called multiple times in some cases based on how it is attached or
    // associated with a match table, we should only output it to json once.
    auto gwName = gateway_name.empty() ? name() : gateway_name;
    if (gateways_in_json.count(gwName)) return;
    LOG3("### Gateway table " << gwName << " gen_tbl_cfg " << loc());
    json::map gTable;
    gTable["direction"] = P4Table::direction_name(gress);
    gTable["attached_to"] = match_table ? match_table->p4_name() : "-";
    gTable["handle"] = gateway_handle++;
    gTable["name"] = gwName;
    gTable["table_type"] = "condition";

    json::vector gStageTables;
    json::map gStageTable;
    json::map next_tables;
    next_tables["false"] = cond_false.next.next_table_id();
    next_tables["true"] = cond_true.next.next_table_id();
    gStageTable["next_tables"] = std::move(next_tables);
    json::map mra;
    mra["memory_unit"] = layout[0].row * 2 + gw_unit;
    mra["memory_type"] = "gateway";
    mra["payload_buses"] = json::vector();
    gStageTable["memory_resource_allocation"] = std::move(mra);
    json::vector pack_format;  // For future use
    gStageTable["pack_format"] = std::move(pack_format);
    json::map next_table_names;
    next_table_names["false"] = cond_false.next.next_table_name();
    next_table_names["true"] = cond_true.next.next_table_name();
    gStageTable["next_table_names"] = std::move(next_table_names);
    gStageTable["logical_table_id"] = logical_id;
    gStageTable["stage_number"] = stage->stageno;
    gStageTable["stage_table_type"] = "gateway";
    gStageTable["size"] = 0;
    gStageTables.push_back(std::move(gStageTable));

    json::vector condition_fields;
    for (auto m : match) {
        json::map condition_field;
        condition_field["name"] = m.val.name();
        condition_field["start_bit"] = m.offset;
        condition_field["bit_width"] = m.val.size();
        condition_fields.push_back(std::move(condition_field));
    }

    gTable["stage_tables"] = std::move(gStageTables);
    gTable["condition_fields"] = std::move(condition_fields);
    gTable["condition"] = gateway_cond;
    gTable["size"] = 0;
    out.push_back(std::move(gTable));
    gateways_in_json.insert(gwName);
}
