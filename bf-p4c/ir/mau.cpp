#include <assert.h>
#include "ir/ir.h"

bool IR::MAU::Table::operator==(const IR::MAU::Table &a) const {
    return name == a.name &&
           gress == a.gress &&
           logical_id == a.logical_id &&
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
    meter_addr_bits += a.meter_addr_bits;
    counter_addr_bits += a.counter_addr_bits;
    action_addr_bits += a.action_addr_bits;
    ghost_bytes += a.ghost_bytes;
    partition_bits += partition_bits;
    partition_count += partition_count;
    return *this;
}

/** The name provided back is a unique assembly name to output to the bfa file.  Furthermore,
 *  the key is a unique name in the Memories::Use map within the TableResourceAlloc object.
 *  Unfortunately, because an individual table can have multiple of the same kind of attached
 *  table, one cannot uniquely key that map with the type of the table.  Rather it has to
 *  be done some other way.
 *
 *  There has to be a better way to manage this map while still being able to print out a
 *  unique key within the table.  The managment of these names has given me significant
 *  headaches in debugging when trying to add a new table.  If anyone has a better solution
 *  to this, then I'm all ears.
 */
cstring IR::MAU::Table::get_use_name(const IR::MAU::AttachedMemory *at, bool is_gw, int type,
                                     int logical_table) const {
    cstring rv = name;
    // After table placement, the atcam partition is actually part of the table name
    // while before table placement, the name is the original backend table name
    if (layout.atcam && !is_placed()) {
         rv += "$atcam" + (logical_table == -1 ? std::to_string(0)
                                              : std::to_string(logical_table));
    } else if (layout.atcam && is_placed() && logical_table >= 0) {
        BUG("Atcam becomes part of the table name after table placement, so atcam won't be "
            "append to the table name");
    }

    if (is_gw) {
        return rv +"$gw";
    } else if (at == nullptr) {
        if (type == IR::MAU::Table::TIND_NAME)
            return rv + "$tind";
        else if (type == IR::MAU::Table::AD_NAME)
            return rv + "$action";
        else
            return rv;
    } else if (at->is<IR::MAU::Counter>()) {
        rv += "$counter." + at->name;
    } else if (at->is<IR::MAU::Meter>()) {
        rv += "$meter." + at->name;
    } else if (at->is<IR::MAU::StatefulAlu>()) {
        rv += "$salu." + at->name;
    } else if (at->is<IR::MAU::Selector>()) {
        rv += "$act_sel." + at->name;
    } else if (at->is<IR::MAU::ActionData>()) {
        rv += "$action";
    } else if (at->is<IR::MAU::TernaryIndirect>()) {
        rv += "$tind";
    } else if (at->is<IR::MAU::IdleTime>()) {
        rv += "$idletime";
    } else {
        BUG("Unrecgonized attached table %s", at->name);
        return "";
    }
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

int IR::MAU::Table::hit_actions() const {
    int _hit_actions = 0;
    for (auto act : Values(actions)) {
        if (!act->miss_only())
            _hit_actions++;
    }
    return _hit_actions;
}
