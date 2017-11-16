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
    // Per Flow Enable - Validate and Set pfe and address bits
    bool pfe_set = false;
    if (per_flow_enable && !per_flow_enable_param.empty()) {
        for (auto m : match_tables) {
            if (auto f = m->lookup_field(per_flow_enable_param)) {
                // Get pfe bit position from format entry
                // This value is then adjusted based on address
                unsigned pfe_bit = 0;
                if (f->size == 1)
                    pfe_bit = f->bit(0);
                else
                    error(lineno, "pfe bit %s is not a 1 bit in table %s format",
                          per_flow_enable_param.c_str(), m->name());
                if (auto addr = m->find_address_field(this)) {
                    pfe_bit -= addr->bits[0].lo;
                    for (int i = m->format ? m->format->groups() - 1 : 0; i >= 1; --i) {
                        // For multiple entries check if each of the pfe bits are in the same
                        // position relative to address
                        if (f->by_group[i]->bit(0) - addr->by_group[i]->bit(0) != pfe_bit)
                            error(lineno, "PFE bit position not in the same relative location to "
                                  "address in other entries in table format - %s(%i)",
                                  per_flow_enable_param.c_str(), i); }
                } else
                    pfe_bit = 0; // we use the primary shift to get at the pfe bit
                if (pfe_set) {
                    if (pfe_bit != per_flow_enable_bit) {
                        // FIXME -- this should be ok, but we can't handle it currently
                        error(lineno, "pfe_bit %s at different locations in different match tables",
                              per_flow_enable_param.c_str()); }
                } else {
                    per_flow_enable_bit = pfe_bit;
                    pfe_set = true; }
            } else {
                error(lineno, "no format found for per_flow_enable param %s",
                      per_flow_enable_param.c_str()); } } }
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

Table::Format::Field *AttachedTables::find_address_field(AttachedTable *tbl) const {
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
                if (f->size > 3) return f; } }
    return nullptr; }

bool AttachedTables::run_at_eop() {
    if (meters.size() > 0) return true;
    for (auto &s : stats)
        if (s->run_at_eop()) return true;
    return false;
}

void AttachedTables::pass1(MatchTable *self) {
    if (selector.check()) {
        if (selector->set_match_table(self, true) != Table::SELECTION)
            error(selector.lineno, "%s is not a selection table", selector->name());
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
                error(selector.lineno, "No field named %s in format", arg.name()); }
    for (auto &s : stats) if (s.check()) {
        if (s->set_match_table(self, s.args.size() > 0) != Table::COUNTER)
            error(s.lineno, "%s is not a counter table", s->name());
        if (s.args.size() > 1)
            error(s.lineno, "Stats table requires zero or one args");
        if (s.args.size() > 0) {
            if (s.args.at(0).type == Table::Call::Arg::Name)
                error(s.lineno, "No field named %s in format", s.args.at(0).name());
            else if (s.args[0].hash_dist())
                s.args[0].hash_dist()->xbar_use |= HashDistribution::STATISTICS_ADDRESS;
        } else if (s.args != stats[0].args)
            error(s.lineno, "Must pass same args to all stats tables in a single table");
        if (s->stage != self->stage)
            error(s.lineno, "Counter %s not in same stage as %s", s->name(), self->name());
        else if (s->gress != self->gress)
            error(s.lineno, "Counter %s not in same thread as %s", s->name(), self->name()); }
    for (auto &m : meters) if (m.check()) {
        auto type = m->set_match_table(self, m.args.size() > 0);
        if (type != Table::METER && type != Table::STATEFUL)
            error(m.lineno, "%s is not a meter table", m->name());
        if (m.args.size() > 1)
            error(m.lineno, "Meter table requires zero or one args");
        if (m.args.size() > 0) {
            if (m.args.at(0).type == Table::Call::Arg::Name)
                error(m.lineno, "No field named %s in format", m.args.at(0).name());
            else if (m.args[0].hash_dist())
                m.args[0].hash_dist()->xbar_use |= HashDistribution::METER_ADDRESS;
        } else if (m.args != meters[0].args)
            error(m.lineno, "Must pass same args to all meter tables in a single table");
        if (m->stage != self->stage)
            error(m.lineno, "Meter %s not in same stage as %s", m->name(), self->name());
        else if (m->gress != self->gress)
            error(m.lineno, "Meter %s not in same thread as %s", m->name(), self->name()); }
    for (auto &s : statefuls) if (s.check()) {
        if (s.args.size() > 2)
            error(s.lineno, "Stateful table requires no more than two args");
        auto *salu = s->to<StatefulTable>();
        if (!salu) {
            error(s.lineno, "%s is not a stateful table", s->name());
            continue; }
        if (s.args.size() > 0) {
            if (s.args[0].type == Table::Call::Arg::Name) {
                if (!salu->actions || !salu->actions->exists(s.args[0].name()))
                    error(selector.lineno, "No action or field named %s", s.args[0].name());
            } else if (s.args.size() == 1 && (s.args[0].size() > 3 || s.args.size() == 0)) {
                s.args.emplace(s.args.begin(), 0); } }
        s->set_match_table(self, s.args.size() > 1);
        if (s.args.size() > 1) {
            if (s.args.at(1).type == Table::Call::Arg::Name)
                error(s.lineno, "No field named %s in format", s.args.at(1).name());
            auto f1 = s.args.at(0).field();
            auto f2 = s.args.at(1).field();
            if (f1 && f2) {
                int off = f1->bits[0].lo - f2->bits[0].lo;
                for (int i = self->format->groups()-1; i > 0; --i)
                    if (off != f1->by_group[i]->bits[0].lo - f2->by_group[i]->bits[0].lo) {
                        error(s.lineno, "fields %s and %s have inconsistent layout across groups",
                              self->find_field(f1).c_str(), self->find_field(f2).c_str());
                        break; } }
            if (s.args[1].hash_dist())
                s.args[1].hash_dist()->xbar_use |= HashDistribution::METER_ADDRESS; }
        if (s.args != statefuls[0].args)
            error(s.lineno, "Must pass same args to all stateful tables in a single table");
        if (s->stage != self->stage)
            error(s.lineno, "Stateful %s not in same stage as %s", s->name(), self->name());
        else if (s->gress != self->gress)
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
            if (self->idletime)
                merge.mau_idletime_adr_tcam_shiftcount[bus] =
                    self->idletime->direct_shiftcount() + tcam_shift;
        } else if (m.args[0].type == Table::Call::Arg::Field) {
            merge.mau_meter_adr_tcam_shiftcount[bus] =
                m.args[0].field()->bits[0].lo + m->indirect_shiftcount();
            merge.mau_idletime_adr_tcam_shiftcount[bus] = m.args[0].field()->bits[0].lo;
        } else if (auto f = m->get_per_flow_enable_param(self)) {
            merge.mau_meter_adr_tcam_shiftcount[bus] = f->bit(0) + METER_ADDRESS_ZERO_PAD; }
        break; /* all must be the same, only config once */ }
    for (auto &s : statefuls) {
        if (s.args.size() <= 1) {
            merge.mau_meter_adr_tcam_shiftcount[bus] = s->direct_shiftcount() + tcam_shift;
            if (self->idletime)
                merge.mau_idletime_adr_tcam_shiftcount[bus] =
                    self->idletime->direct_shiftcount() + tcam_shift;
        } else if (s.args[1].type == Table::Call::Arg::Field) {
            merge.mau_meter_adr_tcam_shiftcount[bus] =
                s.args[1].field()->bits[0].lo + s->indirect_shiftcount();
            merge.mau_idletime_adr_tcam_shiftcount[bus] = s.args[1].field()->bits[0].lo;
        } else if (auto f = s->get_per_flow_enable_param(self)) {
            merge.mau_meter_adr_tcam_shiftcount[bus] = f->bit(0) + METER_ADDRESS_ZERO_PAD; }
        break; /* all must be the same, only config once */ }
}
FOR_ALL_TARGETS(INSTANTIATE_TARGET_TEMPLATE,
                void AttachedTables::write_tcam_merge_regs, mau_regs &, MatchTable *, int, int)

