#ifndef _tofino_ir_mau_h_
#define _tofino_ir_mau_h_

#include "lib/ltbitmatrix.h"

namespace IR {

class MAU_TableSeq;
class MAU_Table : public Node {
    /* A Tofino logical table (group) -- a gateway and/or match table along with whatever
     * attached tables are run.  The basic scheduling unit for tofino; there are 16 such
     * 'logical' tables available in each stage, which will run simultaneously and have
     * their results predicated by the predicate mask calucluated from the next tables */
public:
    cstring				name;
    gress_t				gress;
    int					logical_id = -1;
    bool				gateway_cond = true;
    const Expression			*gateway_expr = nullptr;
    const ActionFunction		*gateway_payload = nullptr;
    const Table				*match_table = nullptr;
    vector<const ActionFunction *>	actions;
    vector<const Attached *>		attached;
    map<cstring, const MAU_TableSeq *>	next;
    struct Layout {
	/* POD type */
	int		entries = 0;
	bool		gateway = false, ternary = false;
	int		ixbar_bytes = 0;
	int		match_width_bits = 0;
	int		action_data_bytes = 0;
	int		action_data_bytes_in_overhead = 0;
	int		overhead_bits = 0;
	bool operator==(const Layout &a) const { return memcmp(this, &a, sizeof(Layout)) == 0; }
	Layout &operator+=(const Layout &a);
    } layout;

    MAU_Table(cstring n, gress_t gr, const Table *t) : name(n), gress(gr), match_table(t) {}
    MAU_Table(cstring n, gress_t gr, const Expression *gw) : name(n), gress(gr), gateway_expr(gw) {}
    IRNODE_SUBCLASS(MAU_Table)
    bool operator==(const MAU_Table &a) const {
	return name == a.name && gress == a.gress && logical_id == a.logical_id &&
	       gateway_cond == a.gateway_cond && gateway_expr == a.gateway_expr &&
	       gateway_payload == a.gateway_payload && match_table == a.match_table &&
	       actions == a.actions && attached == a.attached && next == a.next &&
	       layout == a.layout; }
    IRNODE_VISIT_CHILDREN({
	unsigned next_count = 0;
	v.visit(gateway_expr);
	auto &gateway_inhibit(v.flow_clone());
	gateway_inhibit.visit(gateway_payload);
	v.visit(match_table);
	auto &clone(v.flow_clone());
	if (match_table) {
	    for (auto &action : actions) {
		auto &clone2(clone.flow_clone());
		clone2.visit(action);
		if (next.count(action->name)) {
		    clone2.visit(next.at(action->name));
		    next_count++; }
		v.flow_merge(clone2); }
	    if (next.count("default")) {
		auto &clone2(clone.flow_clone());
		clone2.visit(next.at("default"));
		next_count++;
		v.flow_merge(clone2); }
	    if (next.count("$miss")) {
		auto &clone2(clone.flow_clone());
		clone2.visit(next.at("$miss"));
		next_count++;
		v.flow_merge(clone2); } }
	if (gateway_expr) {
	    if (next.count("true")) {
		if (gateway_cond && match_table)
		    v.visit(next.at("true"));
		else
		    gateway_inhibit.visit(next.at("true"));
		next_count++; }
	    if (next.count("false")) {
		if (gateway_cond || !match_table)
		    gateway_inhibit.visit(next.at("false"));
		else
		    v.visit(next.at("false"));
		next_count++; }
	    v.flow_merge(gateway_inhibit); }
	if (next_count != next.size())
	    throw Util::CompilerBug("unreachable results in table");
	for (auto &att : attached)
	    v.visit(att);
    })
    void dbprint(std::ostream &out) const override;
    int logical_order() const { return logical_id + gress * 4096; }
};

class MAU_TernaryIndirect : public Attached {
public:
    MAU_TernaryIndirect(cstring tbl_name) { name = tbl_name + "$tind"; }

    IRNODE_SUBCLASS(MAU_TernaryIndirect)
    const char *kind() const { return "ternary indirect"; }
};

class MAU_ActionData : public Attached {
public:
    MAU_ActionData(cstring tbl_name) { name = tbl_name + "$action"; }

    IRNODE_SUBCLASS(MAU_ActionData)
    const char *kind() const { return "action data"; }
};

class MAU_TableSeq : public Node {
    /* a sequence of tables -- may be reordered if deps allow.  deps(i,j) is true
     * iff tables[i] is dependent on tables[j] (so must have j < i) */
public:
    Vector<MAU_Table>		tables;
    LTBitMatrix			deps;

    MAU_TableSeq() = default;
    MAU_TableSeq(const MAU_Table *a) { if (a) tables.push_back(a); }
    MAU_TableSeq(const MAU_Table *a, const MAU_Table *b) {
	if (a) tables.push_back(a);
	if (b) tables.push_back(b); }
    MAU_TableSeq(const MAU_TableSeq *a, const MAU_Table *b) {
	if (a) tables.insert(tables.end(), a->tables.begin(), a->tables.end());
	if (b) tables.push_back(b); }
    IRNODE_SUBCLASS(MAU_TableSeq)
    IRNODE_DEFINE_APPLY_OVERLOAD(MAU_TableSeq)
    bool operator==(const MAU_TableSeq &a) const { return tables == a.tables && deps == a.deps; }
    IRNODE_VISIT_CHILDREN({ tables.visit_children(v); })
    void dbprint(std::ostream &out) const override;
};

namespace MAU {
using Table = MAU_Table;
using TableSeq = MAU_TableSeq;
using TernaryIndirect = MAU_TernaryIndirect;
using ActionData = MAU_ActionData;
} // end namespace MAU

} // end namespace IR

#endif /* _tofino_ir_mau_h_ */
