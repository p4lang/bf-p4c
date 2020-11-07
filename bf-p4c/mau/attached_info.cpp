#include "bf-p4c/common/slice.h"
#include "bf-p4c/mau/attached_info.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "bf-p4c/mau/table_placement.h"
#include "bf-p4c/phv/phv_fields.h"


/** The purpose of the ValidateAttachedOfSingleTable pass is to determine whether or not the
 * tables using stateful tables are allowed within Tofino.  Essentially the constraints are
 * the following:
 *  - Multiple counters, meters, or registers can be found on a table if they use the
 *    same exact addressing scheme.
 *  - A table can only have a meter, a stateful alu, or a selector, as they use
 *    the same address in match central
 *  - Indirect addresses for twoport tables require a per flow enable bit as well
 */

/* check if two attachments of the same type use identical addressing schemes and are the same
 * kind of table */
bool ValidateAttachedOfSingleTable::compatible(const IR::MAU::BackendAttached *ba1,
                                               const IR::MAU::BackendAttached *ba2) {
    if (typeid(*ba1->attached) != typeid(*ba2->attached)) return false;
    if (ba1->attached->direct != ba2->attached->direct) return false;
    if (ba1->addr_location != ba2->addr_location) return false;
    if (ba1->pfe_location != ba2->pfe_location) return false;
    if (ba1->type_location != ba2->type_location) return false;
    if (ba1->attached->direct) return true;
    if (auto *a1 = ba1->attached->to<IR::MAU::Synth2Port>()) {
        auto *a2 = ba2->attached->to<IR::MAU::Synth2Port>();
        if (a1->width != a2->width) return false; }
    // for indirect need to check that address expressions and enables are identical in
    // each action.  We do this in SetupAttachedAddressing::ScanActions as we don't have
    // the necessary information here
    return true;
}

void ValidateAttachedOfSingleTable::free_address(const IR::MAU::AttachedMemory *am,
        addr_type_t type) {
    IR::MAU::Table::IndirectAddress ia;
    auto ba = findContext<IR::MAU::BackendAttached>();
    if (users[type] != nullptr) {
        if (!compatible(users[type], ba))
            ::error(ErrorType::ERR_INVALID,
                    "overlap. Both %1% and %2% require the %3% address hardware, and cannot be on "
                    "the same table %4%.",
                    am, users[type]->attached->name, addr_type_name(type), tbl->externalName());
        return;
    }
    users[type] = ba;

    if (!am->direct) {
        if (am->size <= 0) {
            ::error(ErrorType::ERR_NOT_FOUND,
                    "indirect attached table %1%. Does not have a size.", am);
            return;
        }
    }

    BUG_CHECK(am->direct == (IR::MAU::AddrLocation::DIRECT == ba->addr_location), "%s: "
        "Instruction Selection did not correctly set up the addressing scheme for %s",
        am->srcInfo, am->name);

    ia.shifter_enabled = true;
    bool from_hash = false;
    if (ba->addr_location == IR::MAU::AddrLocation::OVERHEAD) {
        ia.address_bits = std::max(ceil_log2(am->size), 10);
    } else if (ba->addr_location == IR::MAU::AddrLocation::HASH) {
        from_hash = true;
        ia.hash_bits = std::max(ceil_log2(am->size), 10);
    }

    if (ba->pfe_location == IR::MAU::PfeLocation::OVERHEAD) {
        if (from_hash) {
            if (!tbl->has_match_data()) {
                ::error(ErrorType::ERR_INVALID,
                        "When an attached memory %1% is addressed by hash and requires "
                        "per action enabling, then the table %2% must have match data",
                         am, tbl->externalName());
                return;
            }
        }
        ia.per_flow_enable = true;
    }

    if (type == METER && ba->type_location == IR::MAU::TypeLocation::OVERHEAD) {
        if (from_hash) {
            if (!tbl->has_match_data()) {
                ::error(ErrorType::ERR_INVALID,
                        "When an attached memory %1% is addressed by hash and requires "
                        "multiple meter_type, then the table %2% must have match data",
                        am, tbl->externalName());
                return;
            }
        }
        ia.meter_type_bits = 3;
    }
    ind_addrs[type] = ia;
}

bool ValidateAttachedOfSingleTable::preorder(const IR::MAU::Counter *cnt) {
    free_address(cnt, STATS);
    return false;
}

bool ValidateAttachedOfSingleTable::preorder(const IR::MAU::Meter *mtr) {
    free_address(mtr, METER);
    return false;
}

bool ValidateAttachedOfSingleTable::preorder(const IR::MAU::StatefulAlu *salu) {
    if (getParent<IR::MAU::BackendAttached>()->use != IR::MAU::StatefulUse::NO_USE)
        free_address(salu, METER);
    return false;
}

bool ValidateAttachedOfSingleTable::preorder(const IR::MAU::Selector *as) {
    free_address(as, METER);
    return false;
}

/**
 * Action data addresses currently do not require a check for PFE, as it is always defaulted
 * on at this point
 */
bool ValidateAttachedOfSingleTable::preorder(const IR::MAU::ActionData *ad) {
    BUG_CHECK(!ad->direct, "Cannot have a direct action data table before table placement");
    if (ad->size <= 0)
        error(ErrorType::ERR_NOT_FOUND, "size count in %2% %1%", ad, ad->kind());
    int vpn_bits_needed = std::max(10, ceil_log2(ad->size)) + 1;

    IR::MAU::Table::IndirectAddress ia;
    ia.address_bits = vpn_bits_needed;
    ia.shifter_enabled = true;
    ind_addrs[ACTIONDATA] = ia;
    return false;
}


bool SplitAttachedInfo::BuildSplitMaps::preorder(const IR::MAU::Table *tbl) {
    // At present table placement only supports the splitting one attached table.
    // Look for a splitable attached memory to map:
    //    either a splitable counter (duplicatable)
    const IR::MAU::AttachedMemory* splitable_counter = nullptr;
    //    or a splitable meter/stateful (nonduplicatable).
    const IR::MAU::AttachedMemory* splitable_meterStateful = nullptr;

    for (auto at : tbl->attached) {
        if (at->attached->direct)
            continue;   // Not splitable.
        if (TablePlacement::can_duplicate(at->attached)) {
            // We can only attach one, even if multiple are split in the same way.
            if (!splitable_counter)
                splitable_counter = at->attached;
        } else {
            if (!splitable_meterStateful)
                splitable_meterStateful = at->attached;
            else
                return true;  // More than one! Don't attach any to this table.
        }
    }
    // Prefer the splitable_meterStateful if found.
    if (auto at = splitable_meterStateful? splitable_meterStateful : splitable_counter) {
        self.attached_to_table_map[at->name].insert(tbl);
        self.table_to_attached_map[tbl->name] = at;
    }
    return true;
}


bool SplitAttachedInfo::ValidateAttachedOfAllTables::preorder(const IR::MAU::Table *tbl) {
    ValidateAttachedOfSingleTable::TypeToAddressMap ia;
    ValidateAttachedOfSingleTable validate_attached(ia, tbl);
    tbl->attached.apply(validate_attached);

    if (self.table_to_attached_map.count(tbl->name) == 0)
        return true;

    auto *at = self.table_to_attached_map.at(tbl->name);
    ValidateAttachedOfSingleTable::addr_type_t addr_type;
    if (at->is<IR::MAU::MeterBus2Port>()) {
        addr_type = ValidateAttachedOfSingleTable::METER;
    } else if (at->is<IR::MAU::Counter>()) {
        addr_type = ValidateAttachedOfSingleTable::STATS;
    } else if (at->is<IR::MAU::ActionData>()) {
        addr_type = ValidateAttachedOfSingleTable::ACTIONDATA;
    } else if (at->is<IR::MAU::Selector>()) {
        addr_type = ValidateAttachedOfSingleTable::METER;
    } else {
        BUG("Unhandled attached table type %s", at);
    }

    auto &addr_info = self.address_info_per_table[tbl->name];
    addr_info.address_bits = ia[addr_type].address_bits;
    addr_info.hash_bits = ia[addr_type].hash_bits;
    return true;
}

bool SplitAttachedInfo::EnableAndTypesOnActions::preorder(const IR::MAU::Action *act) {
    if (findContext<IR::MAU::StatefulAlu>())
        return false;

    auto tbl = findContext<IR::MAU::Table>();

    if (self.table_to_attached_map.count(tbl->name) == 0)
        return false;
    auto at = self.table_to_attached_map.at(tbl->name);
    auto uai = at->unique_id();
    auto &addr_info = self.address_info_per_table[tbl->name];

    auto pfe_p = act->per_flow_enables.find(uai);
    auto type_p = act->meter_types.find(uai);
    if (pfe_p == act->per_flow_enables.end()) {
        if (!act->hit_only())
            addr_info.always_run_on_miss = false;
        if (!act->miss_only())
            addr_info.always_run_on_hit = false;
    }
    if (type_p != act->meter_types.end()) {
        int meter_type = static_cast<int>(type_p->second);
        if (!act->hit_only())
            addr_info.types_on_miss.setbit(meter_type);
        if (!act->miss_only())
            addr_info.types_on_hit.setbit(meter_type);
        // self.types_per_attached[at->name].setbit(meter_type);
    }
    return false;
}

int SplitAttachedInfo::addr_bits_to_phv_on_split(const IR::MAU::Table *tbl) const {
    if (address_info_per_table.count(tbl->name) == 0)
        return false;
    auto &addr_info = address_info_per_table.at(tbl->name);
    return std::max(addr_info.address_bits, addr_info.hash_bits);
}

bool SplitAttachedInfo::enable_to_phv_on_split(const IR::MAU::Table *tbl) const {
    if (address_info_per_table.count(tbl->name) == 0)
        return false;
    auto &addr_info = address_info_per_table.at(tbl->name);
    return !(addr_info.always_run_on_hit && addr_info.always_run_on_miss);
}

int SplitAttachedInfo::type_bits_to_phv_on_split(const IR::MAU::Table *tbl) const {
    if (address_info_per_table.count(tbl->name))
        return false;
    auto &addr_info = address_info_per_table.at(tbl->name);
    return (addr_info.types_on_hit | addr_info.types_on_miss).popcount() > 1 ? 3 : 0;
}

/**
 * Create an instruction set a new PHV field from the address provided by the control plane.
 * If the address is an ActionArg or a Constant, then the PHV field must be set to pass the
 * information to the next part of the program.
 *
 * PhvInfo is passed as an argument to potentially create an instruction only when the
 * field is in PHV.  This is necessary for some of the ActionFormat analysis when the parameter
 * does or does not yet exist.
 */
const IR::MAU::Instruction *SplitAttachedInfo::pre_split_addr_instr(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl, PhvInfo *phv) {
    auto *at = attached_from_table(tbl);
    if (at == nullptr)
        return nullptr;

    int addr_bits = addr_bits_to_phv_on_split(tbl);
    if (addr_bits == 0)
        return nullptr;

    auto &tv = index_tempvars[at->name];
    if (!tv.index) {
        cstring addr_name = at->name + "$index";
        tv.index = new IR::TempVar(IR::Type::Bits::get(addr_bits), false, addr_name); }
    if (phv)
        phv->addTempVar(tv.index, tbl->gress);

    if (auto *sc = act->stateful_call(at->name)) {
        const IR::Expression *index = sc->index;
        const IR::Expression *dest = tv.index;
        int index_width = index->type->width_bits();
        if (index_width > addr_bits)
            index = MakeSlice(index, 0, addr_bits - 1);
        else if (index_width > 0 && index_width < addr_bits)
            dest = MakeSlice(dest, 0, index_width - 1);
        return new IR::MAU::Instruction(act->srcInfo, "set", dest, index); }
    return nullptr;
}

/**
 * @seealso comments above pre_split_addr_instr
 */
const IR::MAU::Instruction *SplitAttachedInfo::pre_split_enable_instr(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl, PhvInfo *phv) {
    auto *at = attached_from_table(tbl);
    if (at == nullptr)
        return nullptr;
    if (!enable_to_phv_on_split(tbl))
        return nullptr;

    auto &tv = index_tempvars[at->name];
    if (!tv.enable) {
        cstring enable_name = at->name + "$ena";
        tv.enable = new IR::TempVar(IR::Type::Bits::get(1), 0, enable_name); }
    if (phv)
        phv->addTempVar(tv.enable, tbl->gress);

    bool enabled = act->per_flow_enables.count(at->unique_id()) > 0;
    // FIXME -- It's not necessary to set the ena to 0 (metadata init will do that always?), but
    // doing so causes problems with imem allocation (it incorrectly tries to pack instructions
    // in the same imem word.)
    if (!enabled) return nullptr;
    return new IR::MAU::Instruction(act->srcInfo, "set", tv.enable,
                                    new IR::Constant(IR::Type::Bits::get(1), enabled ? 1 : 0));
}

/**
 * @seealso comments above pre_split_addr_instr
 */
const IR::MAU::Instruction *SplitAttachedInfo::pre_split_type_instr(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl, PhvInfo *phv) {
    auto *at = attached_from_table(tbl);
    if (at == nullptr)
        return nullptr;

    int type_bits = type_bits_to_phv_on_split(tbl);
    if (type_bits == 0)
        return nullptr;

    auto &tv = index_tempvars[at->name];
    if (!tv.type) {
        cstring type_name = at->name + "$type";
        tv.type = new IR::TempVar(IR::Type::Bits::get(type_bits), false, type_name); }
    if (phv)
        phv->addTempVar(tv.type, tbl->gress);

    bool enabled = act->per_flow_enables.count(at->unique_id()) > 0;
    if (enabled) {
        BUG_CHECK(act->meter_types.count(at->unique_id()) > 0, "An enable stateful op %1% "
            "in action %2% has no meter type?", at->name, act->name);
        int meter_type = static_cast<int>(act->meter_types.at(at->unique_id()));
        return new IR::MAU::Instruction(act->srcInfo, "set", tv.type,
                new IR::Constant(IR::Type::Bits::get(type_bits), meter_type));
    }
    return nullptr;
}

const IR::Expression *SplitAttachedInfo::split_enable(const IR::MAU::AttachedMemory *at) {
    return index_tempvars[at->name].enable;
}

const IR::Expression *SplitAttachedInfo::split_index(const IR::MAU::AttachedMemory *at) {
    return index_tempvars[at->name].index;
}

/**
 * When a match table is in a separate stage than it's stateful ALU, the IR::MAU::Table object
 * must be split into 2 separate IR::MAU::Table objects after table placement.  The first table
 * cannot generate a meter_adr, (as this will not be read by any ALU), but instead potentially pass
 * the address/pfe/type through PHV to a later table.
 *
 * @seealso The address/pfe/type pass requirements are detailed in attached_info.h file, but
 * will be generated if necessary
 */
const IR::MAU::Action *SplitAttachedInfo::create_pre_split_action(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl, PhvInfo *phv) {
    // FIXME -- should only do this once per table/action -- memoize?
    IR::MAU::Action *rv = act->clone();
    auto *at = attached_from_table(tbl);
    if (at == nullptr)
        return rv;

    HasAttachedMemory has_attached(at);
    // Remove instructions that set operations based on this instruction
    for (auto it = rv->action.begin(); it != rv->action.end();) {
        auto instr = *it;
        instr->apply(has_attached);
        if (has_attached.found())
            it = rv->action.erase(it);
        else
            it++;
    }

    // Remove all stateful informations associated with this action
    for (auto it = rv->stateful_calls.begin(); it != rv->stateful_calls.end();) {
        auto instr = *it;
        instr->apply(has_attached);
        if (has_attached.found())
            it = rv->stateful_calls.erase(it);
        else
            it++;
    }

    for (auto it = rv->per_flow_enables.begin(); it != rv->per_flow_enables.end();) {
        if (*it == at->unique_id())
            it = rv->per_flow_enables.erase(it);
        else
            it++;
    }

    for (auto it = rv->meter_types.begin(); it != rv->meter_types.end();) {
        if (it->first == at->unique_id())
            it = rv->meter_types.erase(it);
        else
            it++;
    }

    // Add instructions if necessary
    auto instr1 = pre_split_addr_instr(act, tbl, phv);
    if (instr1 != nullptr)
        rv->action.push_back(instr1);

    auto instr2 = pre_split_enable_instr(act, tbl, phv);
    if (instr2 != nullptr)
        rv->action.push_back(instr2);

    auto instr3 = pre_split_type_instr(act, tbl, phv);
    if (instr3 != nullptr)
        rv->action.push_back(instr3);

    // Will not be exiting from this point, still have to run one final table
    rv->exitAction = false;
    return rv;
}

/** Modify an action to run after the match, driving just the attached table(s) and values
 * dependent on it.  If `reduction_or` is true, it also needs to combine with previous actions
 * for this attached table in earlier stages (so 'set' needs to turn into 'or' -- in stages
 * where the attached table is not running, the table output will be 0.
 */
const IR::MAU::Action *SplitAttachedInfo::create_post_split_action(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl, bool reduction_or) {
    // FIXME -- should only do this once per table/action -- memoize?
    if (act->stateful_calls.empty()) return nullptr;
    IR::MAU::Action *rv = act->clone();
    auto *at = attached_from_table(tbl);
    if (at == nullptr)
        return rv;
    rv->hit_allowed = true;
    rv->default_allowed = true;
    rv->init_default = true;
    rv->hit_path_imp_only = true;
    rv->disallowed_reason = "hit_path_only";

    HasAttachedMemory has_attached(at);
    for (auto it = rv->action.begin(); it != rv->action.end();) {
        auto instr = *it;
        instr->apply(has_attached);
        if (auto ops = has_attached.found()) {
            if (reduction_or) {
                if (instr->name == "set") {
                    BUG_CHECK(instr->operands.size() == 2, "wrong number of operands to set");
                    *it = new IR::MAU::Instruction(instr->srcInfo, "or",
                    instr->operands.at(0),
                    instr->operands.at(0),
                    instr->operands.at(1));
                } else if (instr->name == "or" || instr->name == "xor" ||
                           instr->name == "add" || instr->name == "sub" ||
                           instr->name == "sadds" || instr->name == "saddu" ||
                           instr->name == "ssubs" || instr->name == "ssubu" ||
                           (instr->name == "orca" && ops == 4) ||
                           (instr->name == "orcb" && ops == 2) ||
                           (instr->name == "andca" && ops == 2) ||
                           (instr->name == "andcb" && ops == 4)) {
                    // these are all ok
                } else {
                    error("Can't split %s across stages (so can't split %s)", act, tbl); } }
            it++;
        } else {
            it = rv->action.erase(it);
        }
    }

    for (auto it = rv->stateful_calls.begin(); it != rv->stateful_calls.end();) {
        auto instr = *it;
        instr->apply(has_attached);
        if (!has_attached.found()) {
            it = rv->stateful_calls.erase(it);
        } else {
            if (auto *tv = index_tempvars[at->name].index) {
                // FIXME -- should only create this modified cloned call once?
                auto *call = (*it)->clone();
                call->index = new IR::MAU::HashDist(new IR::MAU::HashGenExpression(tv));
                *it = call;
            }
            it++;
        }
    }
    if (rv->stateful_calls.empty()) return nullptr;

    for (auto it = rv->per_flow_enables.begin(); it != rv->per_flow_enables.end();) {
        if (*it != at->unique_id())
            it = rv->per_flow_enables.erase(it);
        else
            it++;
    }

    for (auto it = rv->meter_types.begin(); it != rv->meter_types.end();) {
        if (it->first != at->unique_id())
            it = rv->meter_types.erase(it);
        else
            it++;
    }
    rv->args.clear();
    return rv;
}
