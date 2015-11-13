#ifndef _tofino_ir_parde_h_
#define _tofino_ir_parde_h_

namespace IR {

class Tofino_Parser : public Node {
public:
    gress_t 		gress;
    const IR::Parser	*start;
    Tofino_Parser(gress_t gr, const IR::Parser *s) : gress(gr), start(s) {}
    IRNODE_SUBCLASS(Tofino_Parser)
    bool operator==(const Tofino_Parser &a) const {
	return gress == a.gress && start == a.start; }
    IRNODE_VISIT_CHILDREN({ v.visit(start); })
    void dbprint(std::ostream &out) const override;
};

class Tofino_Deparser : public Node {
public:
    gress_t 		gress;
    const IR::Parser	*start;
    Tofino_Deparser(gress_t gr, const IR::Parser *s) : gress(gr), start(s) {}
    IRNODE_SUBCLASS(Tofino_Deparser)
    bool operator==(const Tofino_Deparser &a) const {
	return gress == a.gress && start == a.start; }
    IRNODE_VISIT_CHILDREN({ v.visit(start); })
    void dbprint(std::ostream &out) const override;
};

namespace Tofino {
using Parser = Tofino_Parser;
using Deparser = Tofino_Deparser;
} // end namespace Tofino

} // end namespace IR

#endif /* _tofino_ir_parde_h_ */
