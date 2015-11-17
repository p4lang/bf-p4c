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
		throw Util::CompilerBug("unexpected reads expression %s", r);
	    layout.match_width_bits += 1;
	} else if (dynamic_cast<const IR::FieldRef *>(r)) {
	    layout.match_width_bits += r->type->width_bits();
	    if (!layout.ternary)
		layout.ixbar_bytes += (r->type->width_bits() + 7)/8;
	} else
	    throw Util::CompilerBug("unexpected reads expression %s", r);
    }
    layout.overhead_bits = ceil_log2(tbl->actions.size());
}

class GatewayLayout : public MauInspector {
    IR::MAU::Table::Layout &layout;
    set<cstring> added;
    bool preorder(const IR::FieldRef *f) {
	cstring name = f->toString();
	if (!added.count(name)) {
	    added.insert(name);
	    layout.ixbar_bytes += (f->type->width_bits() + 7)/8; }
	return false; }
public:
    GatewayLayout(IR::MAU::Table::Layout &l) : layout(l) {}
};

static const IR::Expression *setup_gateway_layout(IR::MAU::Table::Layout &layout, const IR::Expression *gw) {
    // gw = canonicalize_gateway_expr(gw);
    gw->apply(GatewayLayout(layout));
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

namespace {
class VisitAttached : public Inspector {
    IR::MAU::Table::Layout &layout;
    bool preorder(const IR::Stateful *st) override {
	if (!st->direct) {
	    if (st->instance_count <= 0)
		error("%s: No instance count in indirect %s %s", st->srcInfo, st->kind(), st->name);
	    layout.overhead_bits += ceil_log2(st->instance_count); }
	return false; }
    bool preorder(const IR::ActionProfile *ap) override {
	have_action_data = true;
	if (ap->size <= 0)
	    error("%s: No size count in %s %s", ap->srcInfo, ap->kind(), ap->name);
	layout.overhead_bits += ceil_log2(ap->size);
	return false; }
    bool preorder(const IR::ActionSelector *) override {
	// TODO -- what does this require from the layout?
	return false; }
    bool preorder(const IR::MAU::TernaryIndirect *) override {
	have_ternary_indirect = true;
	return false; }
    bool preorder(const IR::MAU::ActionData *) override {
	have_action_data = true;
	return false; }
    bool preorder(const IR::Attached *att) override {
	throw Util::CompilerBug("Unknown attached table type %s", typeid(*att).name()); }
public:
    VisitAttached(IR::MAU::Table::Layout *l) : layout(*l) {}
    bool have_ternary_indirect = false;
    bool have_action_data = false;;
};
}

bool TableLayout::preorder(IR::MAU::Table *tbl) {
    tbl->layout.ixbar_bytes = tbl->layout.match_width_bits = 
    tbl->layout.action_data_bytes = tbl->layout.overhead_bits = 0;
    if (tbl->match_table)
	setup_match_layout(tbl->layout, tbl->match_table);
    if ((tbl->layout.gateway = bool(tbl->gateway_expr)))
	tbl->gateway_expr = setup_gateway_layout(tbl->layout, tbl->gateway_expr);
    setup_action_layout(tbl);
    VisitAttached attached(&tbl->layout);
    for (auto at : tbl->attached)
	at->apply(attached);
    if (tbl->layout.action_data_bytes > 4 && !attached.have_action_data) {
	auto *act_data = new IR::MAU::ActionData(tbl->name);
	tbl->attached.push_back(act_data);
	act_data->apply(attached); }
    if (!attached.have_action_data) {
	tbl->layout.action_data_bytes_in_overhead = tbl->layout.action_data_bytes;
	tbl->layout.overhead_bits += 8 * tbl->layout.action_data_bytes_in_overhead; }
    if (tbl->layout.ternary) {
	if (tbl->layout.overhead_bits > 1 && !attached.have_ternary_indirect) {
	    auto *tern_indir = new IR::MAU::TernaryIndirect(tbl->name);
	    tbl->attached.push_back(tern_indir);
	    tern_indir->apply(attached);
        }
    } else {
	// determine ways and match groups?
    }
    return true;
}

bool TableLayout::backtrack(trigger &) {
    return false;
}
