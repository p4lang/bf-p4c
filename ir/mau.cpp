#include <assert.h>
#include "ir/ir.h"

bool IR::MAU::Table::operator==(const IR::MAU::Table &a) const
{
    return name == a.name &&
	   gress == a.gress &&
	   logical_id == a.logical_id && 
	   gateway_cond == a.gateway_cond &&
	   gateway_expr == a.gateway_expr &&
	   gateway_payload == a.gateway_payload &&
	   match_table == a.match_table &&
	   actions == a.actions &&
	   attached == a.attached &&
	   next == a.next &&
	   layout == a.layout;
}

IR::MAU::Table::Layout &IR::MAU::Table::Layout::operator += (
    const IR::MAU::Table::Layout &a)
{
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
    } else
	overhead_bits -= 8 * a.action_data_bytes_in_overhead;
    overhead_bits += a.overhead_bits;
    return *this;
}
