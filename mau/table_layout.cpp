#include "table_layout.h"
#include "lib/bitops.h"

static void setup_match_layout(IR::MAU::Table::Layout &layout, const IR::Table *tbl) {
    for (auto t : tbl->reads_types)
	if (t == "ternary" || t == "lpm") {
	    layout.ternary = true;
	    break; }
    layout.match_width_bits = 0;
    if (tbl->reads) for (auto r : *tbl->reads) {
	if (auto mask = dynamic_cast<const IR::BAnd *>(r)) {
	    auto fval = dynamic_cast<const IR::FieldRef *>(mask->operands[0]);
	    auto mval = dynamic_cast<const IR::Constant *>(mask->operands[1]);
	    layout.match_width_bits += bitcount(mval->value);
	    if (!layout.ternary)
		layout.ixbar_bytes += (fval->type->width_bits() + 7)/8;
	} else if (auto prim = dynamic_cast<const IR::Primitive *>(r)) {
	    if (prim->name != "valid")
		throw std::logic_error("unexpected reads expression");
	    layout.match_width_bits += 1;
	} else if (dynamic_cast<const IR::FieldRef *>(r)) {
	    layout.match_width_bits += r->type->width_bits();
	    if (!layout.ternary)
		layout.ixbar_bytes += (r->type->width_bits() + 7)/8;
	} else
	    throw std::logic_error("unexpected reads expression");
    }
    layout.overhead_bits = ceil_log2(tbl->actions.size());
}

class GatewayLayout : public MauInspector {
    IR::MAU::Table::Layout &layout;
    set<cstring> added;
    bool preorder(const IR::FieldRef *f) {
	cstring name = f->asString();
	if (!added.count(name)) {
	    added.insert(name);
	    layout.ixbar_bytes += (f->type->width_bits() + 7)/8; }
	return false; }
public:
    GatewayLayout(IR::MAU::Table::Layout &l) : layout(l) {}
};

static const IR::Expression *setup_gateway_layout(IR::MAU::Table::Layout &layout, const IR::Expression *gw) {
    // gw = canonicalize_gateway_expr(gw);
    gw = gw->apply(GatewayLayout(layout));
    // should count gw tcam width and depth to support gw splitting when needed
    return gw;
}

static void setup_action_layout(IR::MAU::Table *tbl) {
    tbl->layout.action_data_bytes = 0;
    for (auto action : tbl->actions) {
	int action_data_bytes = 0;
	for (auto arg : action->args)
	    action_data_bytes += (arg->type->width_bits() + 7) / 8U;
	if (action_data_bytes > tbl->layout.action_data_bytes)
	    tbl->layout.action_data_bytes = action_data_bytes; }
}

bool TableLayout::preorder(IR::MAU::Table *tbl) {
    tbl->layout.gateway = bool(tbl->gateway_expr);
    if (tbl->match_table)
	setup_match_layout(tbl->layout, tbl->match_table);
    if (tbl->gateway_expr)
	tbl->gateway_expr = setup_gateway_layout(tbl->layout, tbl->gateway_expr);
    setup_action_layout(tbl);
    for (auto at : tbl->attached) {
	// FIXME -- overhead bits for indirect attached tables?
    }
    if (tbl->layout.ternary) {
	if (tbl->layout.overhead_bits > 1) {
	    // attach a ternary indirect table
        }
    } else {
	// determine ways and match groups?
    }
    return tbl;
}

bool TableLayout::backtrack(trigger &trig) {
    return false;
}
