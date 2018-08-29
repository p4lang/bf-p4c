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
void AttachedTable::add_alu_index(json::map &stage_tbl, std::string alu_index) const {
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

unsigned AttachedTable::determine_meter_shiftcount(Table::Call &call, int group, int word,
        int tcam_shift) const {
    if (call.args[0].name() && strcmp(call.args[0].name(), "$DIRECT") == 0) {
        return direct_shiftcount() + tcam_shift;
    } else if (auto f = call.args[0].field()) {
        assert(f->by_group[group]->bit(0)/128U == word);
        return f->by_group[group]->bit(0)%128U + indirect_shiftcount();
    } else if (auto f = call.args[1].field()) {
        return f->bit(0) + METER_ADDRESS_ZERO_PAD;
    } else if (auto f = call.args[2].field()) {
        return f->bit(0) + METER_ADDRESS_ZERO_PAD;
    } else {
        return 0;
    }
}

/**
 * In match merge, addresses are generated from result buses containing match overhead.
 * These buses (83 bits = 64 bits of RAM line + 19 bits of direct address) are sent through
 * format and merge to potentially generate addresses for meters, counters, action data,
 * etc.
 *
 * The addresses for meter/selector/stateful alu, counter, idletime, and action data
 * have very similar setups, and will described in the section below.  But generally
 * the address can be formulated in 3 steps.
 *
 *     1. The 83 bit bus is right shifted to get the bits corresponding to the address.
 *     2. This value is ANDed with a mask to pull only the relevant bits
 *     3. The value is ORed with a default register to enable certain bits
 *
 * This is commonly referred to as shift-mask-default, and will happen for all of
 * these addresses if necessary.
 *
 * The addresses are built up of 2 or 3 general pieces.
 *
 *     1. The RAM line location - which RAM/RAM line to look up the address.  This will
 *        potentially contain a RAM line, a VPN, and Huffman bits.
 *     2. A per flow enable bit - a bit to enable the associated table to run or not
 *     3. A meter type - Specifically only for the meter_adr users (selectors, stateful,
 *        meter).  Will indicate to the meter alu what particular instruction to run.
 *
 * The following portion will describe the registers required to build these addresses:
 *
 *    1. *_payload_shifter_en - will enable the address to be generated if set to true, i.e.
 *       if a match table does not have a counter, then the associated stats_payload_shifter_en
 *       will not be enabled.
 *
 *    2. *_exact/_tcam_shiftcount - the right shift per tind/exact match result bus.
 *       Addresses themselves can have a certain number of bits appended to the lsb, so
 *       the number of appended bits has to appear in the shiftcount
 *
 *    3. *_mask - the post shift AND mask of the relevant address bits from match overhead
 *
 *    4. *_default - the post mask OR value.  Potentially useful for per flow enable bits/
 *       meter types that are identical for every action
 *
 *    5. *_per_entry_mux_ctl - the post shift position of the per flow enable bit, if that
 *       bit is contained in overhead.  This is always ORed in, separate from default
 *
 *    6. _type_position - only relevant for meter address users.  This is the lsb of the
 *       meter type position if the meter position is in overhead.  Note that if this register
 *       is used, then the meter type must be included in the mask. 
 *
 * The purpose of the function of the determine_merge_regs is to look at the arguments of the
 * call for an attached table, and use those to determine the values of these registers.
 */
void AttachedTable::determine_meter_merge_regs(MatchTable *match, int type, int bus,
         const std::vector<Call::Arg> &args, METER_ACCESS_TYPE default_type,
         unsigned &adr_mask, unsigned &per_entry_en_mux_ctl, unsigned &adr_default,
         unsigned &meter_type_position) {
    adr_mask = 0;
    per_entry_en_mux_ctl = 0;
    adr_default = 0;
    meter_type_position = 0;

    int max_ptr_bits = EXACT_VPN_BITS + EXACT_WORD_BITS;
    if (match->to<TernaryMatchTable>())
        max_ptr_bits = TCAM_VPN_BITS + TCAM_WORD_BITS;

    unsigned max_address = (1U << METER_ADDRESS_BITS) - 1;
    assert(args.size() == 3);
    if (args[0].type == Table::Call::Arg::Name && strcmp(args[0].name(), "$DIRECT") == 0) {
        adr_mask |= (((1U << max_ptr_bits) - 1) << address_shift()) & max_address;
    } else if (auto addr = args[0].field()) {
        adr_mask |= (((1U << addr->size) - 1) << address_shift()) & max_address;
    }

    if (args[1].name() && strcmp(args[1].name(), "$DEFAULT") == 0) {
        adr_default |= (1 << METER_PER_FLOW_ENABLE_START_BIT);
    } else if (auto pfe_field = args[1].field()) {
        if (auto addr_field = args[0].field()) {
            per_entry_en_mux_ctl = pfe_field->bit(0) - addr_field->bit(0) + address_shift();
        } else if (args[0].hash_dist() || args[0].count_mode()) {
            per_entry_en_mux_ctl = 0;
        }
    }

    if (args[2].name() && strcmp(args[2].name(), "$DEFAULT") == 0) {
        adr_default |= default_type << METER_TYPE_START_BIT;
    } else if (auto type_field = args[2].field()) {
        if (auto addr_field = args[0].field()) {
            meter_type_position = type_field->bit(0) - addr_field->bit(0) + address_shift();
        } else if (args[0].hash_dist() || args[0].count_mode()) {
            if (auto pfe_field = args[1].field()) {
                meter_type_position = type_field->bit(0) - pfe_field->bit(0);
            }
        } else {
            meter_type_position = 0;
        }
        adr_mask |= ((1 << METER_TYPE_BITS) - 1) << METER_TYPE_START_BIT;
    }
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

/**
 * Currently a call for an attached table (currently for counters/meters/stateful alus/selectors)
 * is built up of a 2 part address/3 part address consisting of 3 parameters:
 *
 * 1.  The location of the address
 * 2.  The location of the per flow enable bit
 * 3.  The location of the meter type (if necessary)
 *
 * Currently these locations can be:
 *     - Names that appear in the format of the table
 *     - For address location, a hash distribution unit
 *     - For address a $DIRECT keyword for a directly addressed table
 *     - For pfe and meter type, a $DEFAULT keyword indicating that the value is ORed in through
 *       the default register
 *
 * This function is responsible for validating this.  Perhaps, in the future, we can have arguments
 * both contain potential SHIFTs and ORs that can be interpreted by the registers
 */
bool AttachedTables::validate_call(Table::Call &call, MatchTable *self, size_t required_args,
        int hash_dist_type, Table::Call &first_call) {
    if (call->stage != self->stage) {
        error(call.lineno, "%s not in same stage as %s", call->name(), self->name());
        return false;
    } else if (call->gress != self->gress) {
        if (!(call->to<StatefulTable>() && 
              timing_thread(call->gress) == timing_thread(self->gress))) {
            error(call.lineno, "%s not in same thread as %s", call->name(), self->name());
            return false;
        }
    } else if (call.args != first_call.args) {
        error(call.lineno, "All calls for the same address type must be identical, and "
              "are not for %s and %s", call->name(), first_call->name());
    }

    if (call.args.size() != required_args) {
        error(call.lineno, "%s requires exactly %zu arguments", call->name(), required_args);
        return false;
    }

    if (call.args.size() == 0)
        return true;
    if (call.args[0].name()) {
        if (strcmp(call.args[0].name(), "$DIRECT") != 0) {
            error(call.lineno, "Index %s for %s cannot be found", call.args[0].name(),
                  call->name());
            return false;
        }
    } else if (call.args[0].hash_dist()) {
        call.args[0].hash_dist()->xbar_use |= hash_dist_type;
    } else if (call.args[0].type == Table::Call::Arg::Counter) {
        auto *salu = call->to<StatefulTable>();
        if (salu == nullptr) {
            error(call.lineno, "Index for %s cannot be a stateful counter, as it is not a "
                               "stateful alu", call->name());
            return false;
        }
        salu->set_counter_mode(call.args[0].count_mode());

    } else if (!call.args[0].field()) {
        error(call.lineno, "Index for %s cannot be understood", call->name());
    }

    if (call.args.size() == 1)
        return true;

    if (call.args[1].name()) {
        if (strcmp(call.args[1].name(), "$DEFAULT") != 0) {
            error(call.lineno, "Per flow enable %s for %s cannot be found", call.args[1].name(),
                  call->name());
            return false;
        }
    } else if (!call.args[1].field()) {
        error(call.lineno, "Per flow enable for %s cannot be understood", call->name());   
        return false;
    }

    if (call.args.size() == 2)
        return true;

    if (call.args[2].name()) {
        if (strcmp(call.args[2].name(), "$DEFAULT") != 0) {
            error(call.lineno, "Meter type %s for %s cannot be found", call.args[2].name(),
                  call->name());
            return false;
        }
    } else if (!call.args[2].field()) {
        error(call.lineno, "Meter type for %s cannot be understood", call->name());
        return false;
    }
    return true;
}

void AttachedTables::pass0(MatchTable *self) {
    if (selector.check() && selector->set_match_table(self, true) != Table::SELECTION)
            error(selector.lineno, "%s is not a selection table", selector->name());
    for (auto &s : stats) {
        bool direct = false; 
        if (s.check() && s->set_match_table(self, !s.is_direct_call()) != Table::COUNTER)
            error(s.lineno, "%s is not a counter table", s->name());
    }
    for (auto &m : meters) if (m.check()) {
        auto type = m->set_match_table(self, !m.is_direct_call() > 0);
        if (type != Table::METER && type != Table::STATEFUL)
            error(m.lineno, "%s is not a meter table", m->name()); }
    for (auto &s : statefuls) {
        if (!s.check()) continue;
        if (s->set_match_table(self, !s.is_direct_call()) != Table::STATEFUL)
            error(s.lineno, "%s is not a stateful table", s->name()); }
}

void AttachedTables::pass1(MatchTable *self) {
    if (selector) {
        validate_call(selector, self, 3, HashDistribution::METER_ADDRESS, selector);
    }
    for (auto &s : stats) {
        if (s) {
            validate_call(s, self, 2, HashDistribution::STATISTICS_ADDRESS, stats[0]);
        }
    }
    for (auto &m : meters) {
        if (m) {
            validate_call(m, self, 3, HashDistribution::METER_ADDRESS, meters[0]);
        }
    }

    for (auto &s : statefuls) {
        if (s) {
            validate_call(s, self, 3, HashDistribution::METER_ADDRESS, statefuls[0]);
        } 
    }
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
        merge.mau_stats_adr_tcam_shiftcount[bus] =
           st->determine_shiftcount(st, 0, 0, tcam_shift);
        break;
    }
    for (auto &m : meters) {
        int shiftcount = m->determine_shiftcount(m, 0, 0, tcam_shift);
        merge.mau_meter_adr_tcam_shiftcount[bus] = shiftcount;
        if (m->uses_colormaprams()) {
            int huffman_bits_out = 0;
            if (m.args[0].field()
                || m.args[0].name() && strcmp(m.args[0].name(), "$DIRECT") == 0) {
                huffman_bits_out = METER_LOWER_HUFFMAN_BITS;
            }
            merge.mau_idletime_adr_tcam_shiftcount[bus]
                = std::max(shiftcount - METER_ADDRESS_ZERO_PAD + huffman_bits_out, 0);
            merge.mau_payload_shifter_enable[1][bus].idletime_adr_payload_shifter_en = 1;
        }
        break; /* all must be the same, only config once */
    }
    for (auto &s : statefuls) {
        merge.mau_meter_adr_tcam_shiftcount[bus]
            = s->determine_shiftcount(s, 0, 0, tcam_shift);
        break; /* all must be the same, only config once */
    }
}
FOR_ALL_TARGETS(INSTANTIATE_TARGET_TEMPLATE,
                void AttachedTables::write_tcam_merge_regs, mau_regs &, MatchTable *, int, int)
