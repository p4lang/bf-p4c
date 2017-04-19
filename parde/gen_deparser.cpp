#include "ir/ir.h"

class GenDeparser : public Inspector {
    IR::Vector<IR::Expression>  &emits;
    bool preorder(const IR::Primitive *prim) {
        if (prim->name != "extract") return true;
        emits.push_back(new IR::Primitive(prim->srcInfo, "emit", prim->operands[0]));
        return false; }
    bool preorder(const IR::MethodCallExpression *mc) {
        auto method = mc->method->to<IR::Member>();
        if (!method || method->member != "emit") return true;
        emits.push_back(new IR::Primitive(mc->srcInfo, "emit", mc->arguments));
        return false; }

 public:
    explicit GenDeparser(IR::Vector<IR::Expression> &e) : emits(e) {}
};

IR::Tofino::Deparser::Deparser(gress_t gr, const IR::Tofino::Parser *p) : gress(gr) {
    p->apply(GenDeparser(emits));
}


IR::Tofino::Deparser::Deparser(gress_t gr, const IR::P4Control *dp) : gress(gr) {
    if (dp)
        dp->apply(GenDeparser(emits));
}
