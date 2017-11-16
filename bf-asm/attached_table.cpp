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
    unsigned addr_bits = 0;
    if (per_flow_enable && !per_flow_enable_param.empty()) {
        for (auto m : match_tables) {
            auto fmt = m->format;
            if (auto t = m->to<TernaryMatchTable>())
                if (t->indirect) fmt = t->indirect->format;
            if (fmt) {
                unsigned g = 0;
                while (g < fmt->groups()) {
                    if (auto f = fmt->field(per_flow_enable_param, g)) {
                        // Get pfe bit position from format entry
                        // This value is then adjusted based on address
                        unsigned pfe_bit = 0;
                        if (f->bits[0].lo == f->bits[0].hi)
                            pfe_bit = f->bits[0].lo;
                        else
                            error(lineno, "pfe bit %s is not a 1 bit value for entry in table format %s(%d)",
                                    per_flow_enable_param.c_str(), per_flow_enable_param.c_str(), g);
                        // Generate address field name based on pfe name
                        std::string addr = per_flow_enable_param.substr(0, per_flow_enable_param.find("_pfe"));
                        addr = addr + "_addr";
                        // Find addr field in format and adjust pfe_bit
                        if (auto a = fmt->field(addr, g)) {
                            pfe_bit = pfe_bit - a->bits[0].lo;
                            addr_bits = a->bits[0].hi - a->bits[0].lo + 1;
                        } else
                            error(lineno, "addr field not found in entry format for pfe %s(%i)",
                                per_flow_enable_param.c_str(), g);
                        if (pfe_set) {
                            // For multiple entries check if each of the pfe bits are in the same position relative to address
                            if (pfe_bit != per_flow_enable_bit)
                                error(lineno, "PFE bit position not in the same relative location to address in other entries in table format - %s(%i)",
                                        per_flow_enable_param.c_str(), g);
                            // Also check for address bits having similar widths
                            if (addr_bits != address_bits)
                                error(lineno, "Address with different widths in other entries in table format - %s(%i)",
                                        addr.c_str(), g);
                        } else {
                            per_flow_enable_bit = pfe_bit;
                            address_bits = addr_bits;
                            pfe_set = true; } }
                    ++g; }
            } else {
                error(lineno, "no format found for per_flow_enable param %s", per_flow_enable_param.c_str()); } } }
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
                        break; } } }
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
        if (st.args.empty())
            merge.mau_stats_adr_tcam_shiftcount[bus] = st->direct_shiftcount() + tcam_shift;
        else
            merge.mau_stats_adr_tcam_shiftcount[bus] = st.args[0].field()->bits[0].lo + 7;
        break; /* all must be the same, only config once */ }
    for (auto &m : meters) {
        if (m.args.empty()) {
            merge.mau_meter_adr_tcam_shiftcount[bus] = m->direct_shiftcount() + tcam_shift + 16;
            merge.mau_idletime_adr_tcam_shiftcount[bus] = m->direct_shiftcount() + tcam_shift;
        } else if (m.args[0].type == Table::Call::Arg::Field) {
            merge.mau_meter_adr_tcam_shiftcount[bus] = m.args[0].field()->bits[0].lo + 16;
            merge.mau_idletime_adr_tcam_shiftcount[bus] = m.args[0].field()->bits[0].lo;
        } else {
            assert(m.args[0].type == Table::Call::Arg::HashDist);
            merge.mau_meter_adr_tcam_shiftcount[bus] = 0; }
        break; /* all must be the same, only config once */ }
    for (auto &s : statefuls) {
        if (s.args.size() <= 1) {
            merge.mau_meter_adr_tcam_shiftcount[bus] = s->direct_shiftcount() + tcam_shift + 16;
            merge.mau_idletime_adr_tcam_shiftcount[bus] = s->direct_shiftcount() + tcam_shift;
        } else if (s.args[1].type == Table::Call::Arg::Field) {
            merge.mau_meter_adr_tcam_shiftcount[bus] = s.args[1].field()->bits[0].lo + 16;
            merge.mau_idletime_adr_tcam_shiftcount[bus] = s.args[1].field()->bits[0].lo;
        } else {
            assert(s.args[1].type == Table::Call::Arg::HashDist);
            merge.mau_meter_adr_tcam_shiftcount[bus] = 0; }
        break; /* all must be the same, only config once */ }
}
FOR_ALL_TARGETS(INSTANTIATE_TARGET_TEMPLATE,
                void AttachedTables::write_tcam_merge_regs, mau_regs &, MatchTable *, int, int)

