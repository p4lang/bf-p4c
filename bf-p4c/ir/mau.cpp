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
    entries += a.entries;
    gateway |= a.gateway;
    ternary |= a.ternary;
    ixbar_bytes += a.ixbar_bytes;
    match_width_bits += a.match_width_bits;
    if (a.action_data_bytes > action_data_bytes)
        action_data_bytes = a.action_data_bytes;
    overhead_bits += 8 * (a.action_data_bytes_in_overhead -
                          action_data_bytes_in_overhead);
    if (a.action_data_bytes_in_overhead >= action_data_bytes_in_overhead) {
        action_data_bytes_in_overhead = a.action_data_bytes_in_overhead;
        overhead_bits -= 8 * action_data_bytes_in_overhead;
    } else {
        overhead_bits -= 8 * a.action_data_bytes_in_overhead; }
    overhead_bits += a.overhead_bits;
    meter_addr_bits += a.meter_addr_bits;
    counter_addr_bits += a.counter_addr_bits;
    indirect_action_addr_bits += a.indirect_action_addr_bits;
    return *this;
}
