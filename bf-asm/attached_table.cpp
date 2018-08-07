#include <config.h>

#include "action_bus.h"
#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

#include <unordered_map>

void AttachedTable::pass1() {
    if (default_action.empty()) default_action = get_default_action();
    // Per Flow Enable - Validate and Set pfe and address bits
    if (per_flow_enable_param == "false")
        per_flow_enable = false;

#ifdef HAVE_JBAY
    if (options.target == JBAY && stage->overflow_bus_use[7])
        error(layout[0].lineno,
              "table %s, Tofino2 has no overflow bus between logical row 7 and 8", name());
#endif /* HAVE_JBAY */
}

unsigned AttachedTable::per_flow_enable_bit(MatchTable *m) const {
    if (!per_flow_enable || per_flow_enable_param.empty()) return 0;
    unsigned pfe_bit = 0;
    if (m) {
        auto addr = m->find_address_field(this);
        auto address_bits = addr ? addr->size : 0;
        if (auto f = m->lookup_field(per_flow_enable_param)) {
            // Get pfe bit position from format entry
            // This value is then adjusted based on address
            if (f->size == 1)
                pfe_bit = f->bit(0);
            else
                error(lineno, "pfe bit %s is not a 1 bit in table %s format",
                      per_flow_enable_param.c_str(), m->name());
            if (addr)
                pfe_bit -= addr->bit(0);
            else
                pfe_bit = 0; // we use the primary shift to get at the pfe bit
        } else if (per_flow_enable_param == "true" && addr) {
            pfe_bit = addr->bit(addr->size-1) - addr->bit(0) + default_pfe_adjust();
        } else {
            error(lineno, "can't find per_flow_enable param %s in format for %s",
                  per_flow_enable_param.c_str(), m->name()); }
    } else for (auto mt : match_tables) {
        auto bit = per_flow_enable_bit(mt);
        if (bit && pfe_bit && bit != pfe_bit) {
            // FIXME -- this should be ok, but we can't handle it currently
            warning(lineno, "pfe_bit %s at different locations in different match tables,"
                    " which will cause driver problems", per_flow_enable_param.c_str());
        } else {
            pfe_bit = bit; } }
    return pfe_bit;
}

// ---------------
// Meter ALU | Row
// Used      |
// ---------------
// 0         | 1
// 1         | 3
// 2         | 5
// 3         | 7
// ---------------
void AttachedTable::add_alu_index(json::map &stage_tbl, std::string alu_index) {
    if (layout.size() <= 0)
        error(lineno, "Invalid meter alu setup. A meter ALU should be allocated for table %s", name());
    stage_tbl[alu_index] = get_alu_index();
}

SelectionTable *AttachedTables::get_selector() const {
    if (selector)
        return dynamic_cast<SelectionTable *>((Table *)selector);
    return nullptr; }

StatefulTable *AttachedTables::get_stateful(std::string name) const {
    for (auto &s : statefuls) {
        if (name == s->name() || name.empty())
            return dynamic_cast<StatefulTable*>((Table *)s); }
    return nullptr; }

MeterTable* AttachedTables::get_meter(std::string name) const {
    for (auto &s : meters) {
        if (name == s->name() || name.empty())
            return dynamic_cast<MeterTable*>((Table *)s); }
    return nullptr; }

Table::Format::Field *AttachedTables::find_address_field(const AttachedTable *tbl) const {
    if (selector == tbl && selector.args.size() > 0)
        return selector.args.at(0).field();
    for (auto &s : stats)
        if (s == tbl && s.args.size() > 0)
            return s.args.at(0).field();
    for (auto &m : meters)
        if (m == tbl && m.args.size() > 0)
            return m.args.at(0).field();
    for (auto &s : statefuls)
        if (s == tbl) {
            if (s.args.size() > 1)
                return s.args.at(1).field();
            else if (s.args.size() > 0) {
                // FIXME -- this special case is a hack in case we're calling this before
                // pass1 has run on the match table with these attached tables
                auto *f = s.args.at(0).field();
                if (f && f->size > 3) return f; } }
    return nullptr; }

bool AttachedTables::run_at_eop() {
    if (meters.size() > 0) return true;
    for (auto &s : stats)
        if (s->run_at_eop()) return true;
    return false;
}

const Table::Call *AttachedTables::get_call(const Table *tbl) const {
    if (selector == tbl) return &selector;
    for (auto &s : stats)
        if (s == tbl) return &s;
    for (auto &m : meters)
        if (m == tbl) return &m;
    for (auto &s : statefuls)
        if (s == tbl) return &s;
    return nullptr;
}

void AttachedTables::pass0(MatchTable *self) {
    if (selector.check() && selector->set_match_table(self, true) != Table::SELECTION)
            error(selector.lineno, "%s is not a selection table", selector->name());
    for (auto &s : stats)
        if (s.check() && s->set_match_table(self, s.args.size() > 0) != Table::COUNTER)
            error(s.lineno, "%s is not a counter table", s->name());
    for (auto &m : meters) if (m.check()) {
        auto type = m->set_match_table(self, m.args.size() > 0);
        if (type != Table::METER && type != Table::STATEFUL)
            error(m.lineno, "%s is not a meter table", m->name()); }
    for (auto &s : statefuls) {
        if (!s.check()) continue;
        bool default_action_arg = false;
        // If no args are present, stateful is direct running default action. We
        // assume action is at 0 and add an action arg
        if (s.args.size() == 0) default_action_arg = true;
        if (s.args.size() > 0) {
            // If no action name argument is present and action bits size > 3
            // (bit 2 - Meter Type, bit 1:0 - 1 of 4 instructions)
            if (s.args[0].type != Table::Call::Arg::Name) {
                if ((s.args.size() == 1) && (s.args[0].size() > 3))
                default_action_arg = true; } }
        // Add default action at 0
        if (default_action_arg) s.args.emplace(s.args.begin(), 0);
        if (s->set_match_table(self, s.args.size() > 1) != Table::STATEFUL)
            error(s.lineno, "%s is not a stateful table", s->name()); }
}

void AttachedTables::pass1(MatchTable *self) {
    if (selector) {
        if (selector.args.size() < 1 || selector.args.size() > 3)
            error(selector.lineno, "Selector requires 1-3 args");
        if (selector->stage != self->stage)
            error(selector.lineno, "Selector table %s not in same stage as %s",
                  selector->name(), self->name());
        else if (selector->gress != self->gress)
            error(selector.lineno, "Selector table %s not in same thread as %s",
                  selector->name(), self->name());
        for (auto &arg : selector.args)
            if (arg.type == Table::Call::Arg::Name)
                error(selector.lineno, "No field named %s in format", arg.name());
            else if (arg.type == Table::Call::Arg::Counter)
                error(selector.lineno, "Can't use counter index to selector"); }
    for (auto &s : stats) if (s) {
        if (s.args.size() > 1)
            error(s.lineno, "Stats table requires zero or one args");
        if (s.args.size() > 0) {
            if (s.args.at(0).type == Table::Call::Arg::Name)
                error(s.lineno, "No field named %s in format", s.args.at(0).name());
            else if (s.args.at(0).type == Table::Call::Arg::Counter)
                error(selector.lineno, "Can't use counter index to counter");
            else if (s.args[0].hash_dist())
                s.args[0].hash_dist()->xbar_use |= HashDistribution::STATISTICS_ADDRESS;
        } else if (s.args != stats[0].args)
            error(s.lineno, "Must pass same args to all stats tables in a single table");
        if (s->stage != self->stage)
            error(s.lineno, "Counter %s not in same stage as %s", s->name(), self->name());
        else if (s->gress != self->gress)
            error(s.lineno, "Counter %s not in same thread as %s", s->name(), self->name()); }
    for (auto &m : meters) if (m) {
        if (m.args.size() > 1)
            error(m.lineno, "Meter table requires zero or one args");
        if (m.args.size() > 0) {
            if (m.args.at(0).type == Table::Call::Arg::Name)
                error(m.lineno, "No field named %s in format", m.args.at(0).name());
            else if (m.args.at(0).type == Table::Call::Arg::Counter)
                error(selector.lineno, "Can't use counter index to meter");
            else if (m.args[0].hash_dist())
                m.args[0].hash_dist()->xbar_use |= HashDistribution::METER_ADDRESS;
        } else if (m.args != meters[0].args)
            error(m.lineno, "Must pass same args to all meter tables in a single table");
        if (m->stage != self->stage)
            error(m.lineno, "Meter %s not in same stage as %s", m->name(), self->name());
        else if (m->gress != self->gress)
            error(m.lineno, "Meter %s not in same thread as %s", m->name(), self->name()); }
    for (auto &s : statefuls) if (s) {
        if (s.args.size() > 2)
            error(s.lineno, "Stateful table requires no more than two args");
        auto *salu = s->to<StatefulTable>();
        if (!salu) continue;
        if (s.args.size() > 0) {
            if (s.args[0].type == Table::Call::Arg::Name) {
                if (!salu->actions || !salu->actions->exists(s.args[0].name()))
                    error(selector.lineno, "No action or field named %s", s.args[0].name()); } }
        if (s.args.size() > 1) {
            if (s.args.at(1).type == Table::Call::Arg::Name)
                error(s.lineno, "No field named %s in format", s.args.at(1).name());
            auto f1 = s.args.at(0).field();
            auto f2 = s.args.at(1).field();
            /* If format is a NULL, this is a ternary_table and we dont need to check for
             * match group consistency */
            if (self->format && f1 && f2) {
                int off = f1->bits[0].lo - f2->bits[0].lo;
                for (int i = self->format->groups()-1; i > 0; --i)
                    if (off != f1->by_group[i]->bits[0].lo - f2->by_group[i]->bits[0].lo) {
                        error(s.lineno, "fields %s and %s have inconsistent layout across groups",
                              self->find_field(f1).c_str(), self->find_field(f2).c_str());
                        break; } }
            if (s.args[1].hash_dist())
                s.args[1].hash_dist()->xbar_use |= HashDistribution::METER_ADDRESS;
            else if (s.args[1].type == Table::Call::Arg::Counter)
                salu->set_counter_mode(s.args[1].count_mode()); }
        if (s.args != statefuls[0].args)
            error(s.lineno, "Must pass same args to all stateful tables in a single table");
        if (s->stage != self->stage)
            error(s.lineno, "Stateful %s not in same stage as %s", s->name(), self->name());
        else if (timing_thread(s->gress) != timing_thread(self->gress))
            error(s.lineno, "Stateful %s not in same thread as %s", s->name(), self->name()); }
}

template<class REGS>
void AttachedTables::write_merge_regs(REGS &regs, MatchTable *self, int type, int bus) {
    for (auto &s : stats) s->write_merge_regs(regs, self, type, bus, s.args);
    for (auto &m : meters) m->write_merge_regs(regs, self, type, bus, m.args);
    for (auto &s : statefuls) s->write_merge_regs(regs, self, type, bus, s.args);
    if (selector)
        get_selector()->write_merge_regs(regs, self, type, bus, selector.args);
}
FOR_ALL_TARGETS(INSTANTIATE_TARGET_TEMPLATE,
                void AttachedTables::write_merge_regs, mau_regs &, MatchTable *, int, int)

template<class REGS>
void AttachedTables::write_tcam_merge_regs(REGS &regs, MatchTable *self, int bus, int tcam_shift) {
    auto &merge = regs.rams.match.merge;
    for (auto &st : stats) {
        if (st.args.empty()) {
            merge.mau_stats_adr_tcam_shiftcount[bus] = st->direct_shiftcount() + tcam_shift;
        } else if (st.args[0].type == Table::Call::Arg::Field) {
            merge.mau_stats_adr_tcam_shiftcount[bus] =
                st.args[0].field()->bit(0) + st->indirect_shiftcount();
        } else if (auto f = st->get_per_flow_enable_param(self)) {
            merge.mau_stats_adr_tcam_shiftcount[bus] = f->bit(0) + STAT_ADDRESS_ZERO_PAD; }
        break; /* all must be the same, only config once */ }
    for (auto &m : meters) {
        if (m.args.empty()) {
            merge.mau_meter_adr_tcam_shiftcount[bus] = m->direct_shiftcount() + tcam_shift;
            if (m->uses_colormaprams()) {
                merge.mau_idletime_adr_tcam_shiftcount[bus] = 64 + tcam_shift;
                merge.mau_payload_shifter_enable[1][bus].idletime_adr_payload_shifter_en = 1; }
        } else if (m.args[0].type == Table::Call::Arg::Field) {
            merge.mau_meter_adr_tcam_shiftcount[bus] =
                m.args[0].field()->bits[0].lo + m->indirect_shiftcount();
            if (m->uses_colormaprams()) {
                merge.mau_idletime_adr_tcam_shiftcount[bus] = m.args[0].field()->bits[0].lo;
                merge.mau_payload_shifter_enable[1][bus].idletime_adr_payload_shifter_en = 1; }
        } else if (auto f = m->get_per_flow_enable_param(self)) {
            merge.mau_meter_adr_tcam_shiftcount[bus] = f->bit(0) + METER_ADDRESS_ZERO_PAD; }
        break; /* all must be the same, only config once */ }
    for (auto &s : statefuls) {
        if (s.args.size() <= 1) {
            merge.mau_meter_adr_tcam_shiftcount[bus] = s->direct_shiftcount() + tcam_shift;
        } else if (s.args[1].type == Table::Call::Arg::Field) {
            merge.mau_meter_adr_tcam_shiftcount[bus] =
                s.args[1].field()->bits[0].lo + s->indirect_shiftcount();
        } else if (auto f = s->get_per_flow_enable_param(self)) {
            merge.mau_meter_adr_tcam_shiftcount[bus] = f->bit(0) + METER_ADDRESS_ZERO_PAD; }
        break; /* all must be the same, only config once */ }
}
FOR_ALL_TARGETS(INSTANTIATE_TARGET_TEMPLATE,
                void AttachedTables::write_tcam_merge_regs, mau_regs &, MatchTable *, int, int)
