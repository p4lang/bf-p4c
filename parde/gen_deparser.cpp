#include "tofino/ir/tofino.h"

class GenDeparser : public Inspector {
    IR::Vector<IR::Expression>  &emits;
    bool preorder(const IR::Primitive *prim) {
        if (prim->name != "extract") return true;
        emits.push_back(new IR::Primitive(prim->srcInfo, "emit", prim->operands[0]));
        return false; }

 public:
    GenDeparser(IR::Vector<IR::Expression> &e) : emits(e) {}
};

IR::Tofino_Deparser::Tofino_Deparser(gress_t gr, const IR::Tofino::Parser *p) : gress(gr) {
    if (p && p->start)
        start = p->start->p4state;
    p->apply(GenDeparser(stmts));
}
