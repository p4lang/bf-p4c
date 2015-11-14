#include <assert.h>
#include "ir/ir.h"

namespace IR {

MAU::Table::Layout &MAU::Table::Layout::operator += (const MAU::Table::Layout &a) {
    entries += a.entries;
    gateway |= a.gateway;
    ternary |= a.ternary;
    ixbar_bytes += a.ixbar_bytes;
    match_width_bits += a.match_width_bits;
    if (a.action_data_bytes > action_data_bytes)
	action_data_bytes = a.action_data_bytes;
    overhead_bits += 8*(a.action_data_bytes_in_overhead-action_data_bytes_in_overhead);
    if (a.action_data_bytes_in_overhead >= action_data_bytes_in_overhead) {
	action_data_bytes_in_overhead = a.action_data_bytes_in_overhead;
	overhead_bits -= 8 * action_data_bytes_in_overhead;
    } else
	overhead_bits -= 8 * a.action_data_bytes_in_overhead;
    overhead_bits += a.overhead_bits;
    return *this;
}

} // end namespace IR
