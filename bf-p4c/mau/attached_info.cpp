#include "bf-p4c/common/slice.h"
#include "bf-p4c/mau/attached_info.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "bf-p4c/phv/phv_fields.h"


/** The purpose of this function is to determine whether or not the tables using stateful
 *  tables are allowed within Tofino.  Essentially the constraints are the following:
 *  - Multiple counters, meters, or registers can be found on a table if they use the
 *    same exact addressing scheme.
 *  - A table can only have a meter, a stateful alu, or a selector, as they use
 *    the same address in match central
 *  - Indirect addresses for twoport tables require a per flow enable bit as well
 */
bool ValidateAttachedOfSingleTable::free_address(const IR::MAU::AttachedMemory *am,
        addr_type_t type) {
    IR::MAU::Table::IndirectAddress ia;
    auto ba = findContext<IR::MAU::BackendAttached>();
    if (users[type] != nullptr) {
        ::error(ErrorType::ERR_INVALID,
                "overlap. Both %2% and %3% require the %4% address hardware, and cannot be on "
                "the same table %5%.",
                am, am->name, users[type]->name, addr_type_name(type), tbl->externalName());
        return false;
    }
    users[type] = am;

    if (!am->direct) {
        if (am->size <= 0) {
            ::error(ErrorType::ERR_NOT_FOUND,
                    "indirect attached table %2%. Does not have a size.", am, am->name);
            return false;
        }
    }

    BUG_CHECK(am->direct == (IR::MAU::AddrLocation::DIRECT == ba->addr_location), "%s: "
        "Instruction Selection did not correctly set up the addressing scheme for %s",
        am->srcInfo, am->name);

    ia.shifter_enabled = true;
    bool from_hash = false;
    if (ba->addr_location == IR::MAU::AddrLocation::OVERHEAD) {
        ia.address_bits += std::max(ceil_log2(am->size), 10);
    } else if (ba->addr_location == IR::MAU::AddrLocation::HASH) {
        from_hash = true;
    }

    if (ba->pfe_location == IR::MAU::PfeLocation::OVERHEAD) {
        if (from_hash) {
            if (!tbl->has_match_data()) {
                ::error(ErrorType::ERR_INVALID,
                        "When an attached memory %2% is addressed by hash and requires "
                        "per action enabling, then the table %3% must have match data",
                         am, am->name, tbl->externalName());
                return false;
            }
        }
        ia.per_flow_enable = true;
    }

    if (type == METER && ba->type_location == IR::MAU::TypeLocation::OVERHEAD) {
        if (from_hash) {
            if (!tbl->has_match_data()) {
                ::error(ErrorType::ERR_INVALID,
                        "When an attached memory %2% is addressed by hash and requires "
                        "multiple meter_type, then the table %3% must have match data",
                        am, am->name, tbl->externalName());
                return false;
            }
        }
        ia.meter_type_bits = 3;
    }
    ind_addrs[type] = ia;
    return true;
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
        error(ErrorType::ERR_NOT_FOUND, "size count in %2% %3%", ad, ad->kind(), ad->name);
    int vpn_bits_needed = std::max(10, ceil_log2(ad->size)) + 1;

    IR::MAU::Table::IndirectAddress ia;
    ia.address_bits = vpn_bits_needed;
    ia.shifter_enabled = true;
    ind_addrs[ACTIONDATA] = ia;
    return false;
}

/**
 * Returns true if it is legal to split the attached memory from the match table.  A counter
 * entry can be split into multiple entries, as the control plane can just sum the two counter
 * entries.  Selectors and Action Data tables can also be split, as they are not written by
 * the data plane.
 *
 * Meters and stateful ALUs must be together, however, as the entry cannot be split safely.
 * For example, if X is the average of set A and Y is the average of set B, the average
 * of X and Y is not the average of set A + set B.
 */
bool SplitAttachedInfo::safe_to_split_entry(const IR::MAU::AttachedMemory *at) {
    if (at->direct)
        return true;
    if (!(at->is<IR::MAU::Meter>() || at->is<IR::MAU::StatefulAlu>()))
        return true;
    auto salu = at->to<IR::MAU::StatefulAlu>();
    if (salu && salu->synthetic_for_selector)
        return true;
    return false;
}

bool SplitAttachedInfo::BuildSplitMaps::preorder(const IR::MAU::Table *tbl) {
    const IR::MAU::AttachedMemory *at = nullptr;
    for (auto back_at : tbl->attached) {
        auto at_temp = back_at->attached;
        if (SplitAttachedInfo::safe_to_split_entry(at_temp))
            continue;
        BUG_CHECK(at == nullptr, "A single table %s% has multiple meters/stateful ALUs");
        at = at_temp;
    }

    if (at == nullptr)
        return true;

    self.attached_to_table_map[at].insert(tbl);
    self.table_to_attached_map[tbl] = at;
    return true;
}


bool SplitAttachedInfo::ValidateAttachedOfAllTables::preorder(const IR::MAU::Table *tbl) {
    ValidateAttachedOfSingleTable::TypeToAddressMap ia;
    ValidateAttachedOfSingleTable validate_attached(ia, tbl);
    tbl->attached.apply(validate_attached);

    if (self.table_to_attached_map.count(tbl) == 0)
        return true;

    auto &addr_info = self.address_info_per_table[tbl];
    addr_info.address_bits = ia[ValidateAttachedOfSingleTable::METER].address_bits;
    return true;
}

bool SplitAttachedInfo::EnableAndTypesOnActions::preorder(const IR::MAU::Action *act) {
    if (findContext<IR::MAU::StatefulAlu>())
        return false;

    auto tbl = findContext<IR::MAU::Table>();

    if (self.table_to_attached_map.count(tbl) == 0)
        return false;
    auto at = self.table_to_attached_map.at(tbl);
    auto uai = at->unique_id();
    auto &addr_info = self.address_info_per_table[tbl];

    auto pfe_p = act->per_flow_enables.find(uai);
    if (pfe_p == act->per_flow_enables.end()) {
        if (!act->hit_only())
            addr_info.always_run_on_miss = false;
        if (!act->miss_only())
            addr_info.always_run_on_hit = false;
    } else {
        auto type_p = act->meter_types.find(uai);
        BUG_CHECK(type_p != act->meter_types.end(), "Action %1% requires a meter type, as the %2% "
            "is running in this action", act->name, at->name);
        int meter_type = static_cast<int>(type_p->second);
        if (!act->hit_only())
            addr_info.types_on_miss.setbit(meter_type);
        if (!act->miss_only())
            addr_info.types_on_hit.setbit(meter_type);
        self.types_per_attached[at].setbit(meter_type);
    }
    return false;
}

int SplitAttachedInfo::addr_bits_to_phv_on_split(const IR::MAU::Table *tbl) const {
    if (address_info_per_table.count(tbl) == 0)
        return false;
    auto &addr_info = address_info_per_table.at(tbl);
    return addr_info.address_bits;
}

bool SplitAttachedInfo::enable_to_phv_on_split(const IR::MAU::Table *tbl) const {
    if (address_info_per_table.count(tbl) == 0)
        return false;
    auto &addr_info = address_info_per_table.at(tbl);
    return !(addr_info.always_run_on_hit && addr_info.always_run_on_miss);
}

int SplitAttachedInfo::type_bits_to_phv_on_split(const IR::MAU::Table *tbl) const {
    if (address_info_per_table.count(tbl))
        return false;
    auto &addr_info = address_info_per_table.at(tbl);
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
        const IR::MAU::Table *tbl, const PhvInfo *phv) const {
    auto *at = attached_from_table(tbl);
    if (at == nullptr)
        return nullptr;

    int addr_bits = addr_bits_to_phv_on_split(tbl);
    if (addr_bits == 0)
        return nullptr;

    cstring base_addr = "$" + at->unique_id().build_name();
    cstring addr_name = base_addr + "_address";
    IR::TempVar *tv = new IR::TempVar(IR::Type::Bits::get(addr_bits), false, addr_name);
    if (phv && phv->field(tv) == nullptr)
        return nullptr;

    const IR::Expression *expr_to_set = nullptr;
    for (auto sc : act->stateful_calls) {
        if (sc->attached_callee == at) {
            expr_to_set = sc->index;
            break;
        }
    }

    BUG_CHECK(expr_to_set && (expr_to_set->to<IR::MAU::ActionArg>() ||
        expr_to_set->to<IR::Constant>()), "Trying to split a stateful ALU %1% "
        "address across a stage that doesn't have a parameter based address");

    return new IR::MAU::Instruction(act->srcInfo, "set", tv,
                                    MakeSlice(expr_to_set, 0, addr_bits - 1));
}

/**
 * @seealso comments above pre_split_addr_instr
 */
const IR::MAU::Instruction *SplitAttachedInfo::pre_split_enable_instr(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl, const PhvInfo *phv) const {
    auto *at = attached_from_table(tbl);
    if (at == nullptr)
        return nullptr;
    if (!enable_to_phv_on_split(tbl))
        return nullptr;

    cstring base_addr = "$" + at->unique_id().build_name();
    cstring enable_name = base_addr + "_enable";
    IR::TempVar *tv = new IR::TempVar(IR::Type::Bits::get(1), 0, enable_name);
    if (phv && phv->field(tv) == nullptr)
        return nullptr;

    bool enabled = act->per_flow_enables.count(at->unique_id()) > 0;
    return new IR::MAU::Instruction(act->srcInfo, "set", tv,
                                    new IR::Constant(IR::Type::Bits::get(1), enabled ? 1 : 0));
}

/**
 * @seealso comments above pre_split_addr_instr
 */
const IR::MAU::Instruction *SplitAttachedInfo::pre_split_type_instr(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl, const PhvInfo *phv) const {
    auto *at = attached_from_table(tbl);
    if (at == nullptr)
        return nullptr;

    int type_bits = type_bits_to_phv_on_split(tbl);
    if (type_bits == 0)
        return nullptr;

    cstring base_addr = "$" + at->unique_id().build_name();
    cstring type_name = base_addr + "_type";
    IR::TempVar *tv = new IR::TempVar(IR::Type::Bits::get(type_bits), false, type_name);
    if (phv && phv->field(tv) == nullptr)
        return nullptr;

    bool enabled = act->per_flow_enables.count(at->unique_id()) > 0;
    if (enabled) {
        BUG_CHECK(act->meter_types.count(at->unique_id()) > 0, "An enable stateful op %1% "
            "in action %2% has no meter type?", at->name, act->name);
        int meter_type = static_cast<int>(act->meter_types.at(at->unique_id()));
        return new IR::MAU::Instruction(act->srcInfo, "set", tv,
                new IR::Constant(IR::Type::Bits::get(type_bits), meter_type));
    }
    return nullptr;
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
        const IR::MAU::Table *tbl, const PhvInfo *phv) const {
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
    if (instr1 == nullptr)
        rv->action.push_back(instr1);

    auto instr2 = pre_split_enable_instr(act, tbl, phv);
    if (instr2 == nullptr)
        rv->action.push_back(instr2);

    auto instr3 = pre_split_type_instr(act, tbl, phv);
    if (instr3 == nullptr)
        rv->action.push_back(instr3);

    // Will not be exiting from this point, still have to run one final table
    rv->exitAction = false;
    return rv;
}

const IR::MAU::Action *SplitAttachedInfo::create_post_split_action(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl) const {
    IR::MAU::Action *rv = act->clone();
    auto *at = attached_from_table(tbl);
    if (at == nullptr)
        return rv;

    HasAttachedMemory has_attached(at);
    for (auto it = rv->action.begin(); it != rv->action.end();) {
        auto instr = *it;
        instr->apply(has_attached);
        if (!has_attached.found())
            it = rv->action.erase(it);
        else
            it++;
    }

    for (auto it = rv->stateful_calls.begin(); it != rv->stateful_calls.end();) {
        auto instr = *it;
        instr->apply(has_attached);
        if (!has_attached.found())
            it = rv->stateful_calls.erase(it);
        else
            it++;
    }

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

