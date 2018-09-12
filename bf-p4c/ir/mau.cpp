#include <assert.h>
#include "ir/ir.h"

bool IR::MAU::Table::operator==(const IR::MAU::Table &a) const {
    return name == a.name &&
           gress == a.gress &&
           logical_id == a.logical_id &&
           gateway_cond == a.gateway_cond &&
           gateway_rows == a.gateway_rows &&
           gateway_payload == a.gateway_payload &&
           match_table == a.match_table &&
           match_key == a.match_key &&
           attached == a.attached &&
           actions == a.actions &&
           next == a.next &&
           layout == a.layout &&
           ways == a.ways &&
           resources == a.resources;
}

IR::MAU::Table::Layout &IR::MAU::Table::Layout::operator +=(const IR::MAU::Table::Layout &a) {
    total_actions += a.total_actions;
    entries += a.entries;
    gateway |= a.gateway;
    ternary |= a.ternary;
    hash_action |= a.hash_action;
    atcam |= a.atcam;
    has_range |= a.has_range;
    ixbar_bytes += a.ixbar_bytes;
    ixbar_width_bits += a.ixbar_width_bits;
    match_width_bits += a.match_width_bits;
    if (a.action_data_bytes > action_data_bytes)
        action_data_bytes = a.action_data_bytes;


    if (a.action_data_bytes_in_table > action_data_bytes_in_table)
        action_data_bytes_in_table = a.action_data_bytes_in_table;

    overhead_bits += a.overhead_bits;
    immediate_bits += a.immediate_bits;
    meter_addr += a.meter_addr;
    stats_addr += a.stats_addr;
    action_addr += a.action_addr;
    ghost_bytes += a.ghost_bytes;
    partition_bits += partition_bits;
    partition_count += partition_count;
    return *this;
}

IR::MAU::Table::IndirectAddress
    &IR::MAU::Table::IndirectAddress::operator +=(const IR::MAU::Table::IndirectAddress &a) {
    shifter_enabled |= a.shifter_enabled;
    address_bits += a.address_bits;
    per_flow_enable |= a.per_flow_enable;
    meter_type_bits += a.meter_type_bits;
    return *this;
}

/** This function can only be used before TablePlacement, or essentially when the IR::MAU::Table
 *  resources object is not yet saved.
 *
 *  This is currently created as a key during the try_place_table algorithm.  These keys,
 *  after the IR is updated in the TablePlacement preorders, should be identical to the keys
 *  after table placement 
 */
UniqueId IR::MAU::Table::pp_unique_id(const IR::MAU::AttachedMemory *at,
        bool is_gw, int stage_table, int logical_table,
        UniqueAttachedId::pre_placed_type_t ppt) const {
    BUG_CHECK(!is_placed(), "Illegal call of the pp_unique_id function");

    UniqueId rv;
    rv.name = name;
    if (for_dleft())
        rv.speciality = UniqueId::DLEFT;
    if (layout.atcam)
        rv.speciality = UniqueId::ATCAM;

    // Note that for ATCAM/DLEFT tables, if the logical table isn't provided, then the
    // logical table is initialized to 0.  This is because all indirect attached tables
    // for an ATCAM are attached to logical table 0 in the assembler.  It is a lot easier
    // to call particular functions with this known ahead of time
    if (rv.speciality != UniqueId::NONE && logical_table == -1)
        rv.logical_table = 0;
    else
        rv.logical_table = logical_table;

    rv.stage_table = stage_table;
    rv.is_gw = is_gw;
    if (ppt != UniqueAttachedId::NO_PP)
        rv.a_id = UniqueAttachedId(ppt);
    else if (at != nullptr)
        rv.a_id = at->unique_id();

    return rv;
}

/** Building a unique id for a table after table placement.  Stage Table and Logical Table
 *  information as well as speciality information come directly from the IR.
 *
 *  If creating a unique id for an AttachedMemory table underneath a table in the DAG,
 *  then an AttachedMemory can be passed to the function.  The same is true for gateway information
 *
 *  A unique_id was created every time this function is called.  The reason these stay
 *  consistent through all of the passes is that the name of the table, the stage split of
 *  the table and the logical split of the table do not change after table placement.
 *
 *  For the AttachedMemory ids, these stay consistent if the name and type of the IR class
 *  remain consistent throughout the entirety of the allocation, which is the current invariant
 */
UniqueId IR::MAU::Table::unique_id(const IR::MAU::AttachedMemory *at, bool is_gw) const {
    BUG_CHECK(is_placed(), "Illegal call of the unique_id function");

    UniqueId rv;
    rv.name = name;
    rv.stage_table = stage_split;
    rv.logical_table = logical_split;

    if (for_dleft())
        rv.speciality = UniqueId::DLEFT;
    if (layout.atcam)
        rv.speciality = UniqueId::ATCAM;

    rv.is_gw = is_gw;
    if (at != nullptr)
        rv.a_id = at->unique_id();

    return rv;
}

bool IR::MAU::Table::action_chain() const {
    for (auto &n : next) {
        if (n.first[0] != '$') {
            return true;
        }
    }
    return false;
}

bool IR::MAU::Table::has_default_path() const {
    for (auto &n : next) {
        if (n.first == "$default")
            return true;
    }
    return false;
}

int IR::MAU::Table::action_next_paths() const {
    int action_paths = 0;
    for (auto &n : next) {
        if (n.first == "$default" || n.first[0] != '$')
            action_paths++;
    }
    return action_paths;
}

int IR::MAU::Table::get_provided_stage() const {
    if (gateway_only())
        return -1;
    auto annot = match_table->annotations->getSingle("stage");
    if (annot == nullptr)
        return -1;
    BUG_CHECK(annot->expr.size() == 1, "%s: Stage pragma provided to table %s has multiple "
              "parameters, while Brig currently only supports one parameter",
              annot->srcInfo, name);
    auto constant = annot->expr.at(0)->to<IR::Constant>();
    ERROR_CHECK(constant, "%s: Stage pragma value provided to table %s is not a constant",
                annot->srcInfo, name);
    return constant->asInt();
}

int IR::MAU::Table::get_random_seed() const {
    if (match_table == nullptr)
        return -1;
    auto annot = match_table->annotations->getSingle("random_seed");
    if (annot == nullptr)
        return -1;
    ERROR_CHECK(annot->expr.size() == 1, "%s: random_seed pragma provided to table %s has multiple "
              "parameters, while Brig currently only supports one parameter",
              annot->srcInfo, name);
    auto constant = annot->expr.at(0)->to<IR::Constant>();
    ERROR_CHECK(constant, "%s: random_seed pragma provided to table %s is not a constant",
                annot->srcInfo, name);
    int val = constant->asInt();
    ERROR_CHECK(val >= 0, "%s: random_seem pragma provided to table %s must be >= 0",
                annot->srcInfo, name);
    return val;
}

int IR::MAU::Table::hit_actions() const {
    int _hit_actions = 0;
    for (auto act : Values(actions)) {
        if (!act->miss_only())
            _hit_actions++;
    }
    return _hit_actions;
}

bool IR::MAU::Table::for_dleft() const {
    if (gateway_only())
        return false;
    return match_table->getAnnotations()->getSingle("dleft_learn_cache") != nullptr;
}

cstring IR::MAU::Action::externalName() const {
    if (auto *name_annot = annotations->getSingle("name"))
        return IR::Annotation::getName(name_annot);
    return name.originalName;
}
