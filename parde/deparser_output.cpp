#include "asm_output.h"

static const IR::Expression *header_ref(const IR::Expression *e) {
    /* FIXME(cdodd) -- this is a nasty hack */
    if (auto *p = e->to<IR::HeaderSliceRef>()) return p->header_ref();
    if (auto *p = e->to<IR::Member>()) return p->expr;
    return 0;
}

class OutputDictionary : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    gress_t             gress;
    indent_t            indent;
    bool preorder(const IR::Primitive *prim) {
        if (prim->name != "emit") return true;
        std::pair<int, int>     bits;
        auto hsr = prim->operands[0]->to<IR::HeaderSliceRef>();
        if (!hsr) {
            /* not allocated to header -- happens with Varbits currently */
            return false; }
        auto field = phv.field(prim->operands[0], &bits);
        out << indent << canon_name(field->name);
        if (bits.second != 0 || bits.first + 1 != field->size)
            out << '.' << bits.second << '-' << bits.first;
        out << ": " << canon_name(trim_asm_name(hsr->header_ref()->toString())) << ".$valid"
            << std::endl;
        return false; }

 public:
    OutputDictionary(std::ostream &out, const PhvInfo &phv, gress_t gress, indent_t indent)
    : out(out), phv(phv), gress(gress), indent(indent) {}
};

std::ostream &operator<<(std::ostream &out, const DeparserAsmOutput &d) {
    indent_t    indent(1);
    out << "deparser " << d.gress << ":" << std::endl;
    out << indent << "dictionary:" << std::endl;
    if (d.deparser) {
        d.deparser->emits.apply(OutputDictionary(out, d.phv, d.gress, ++indent));
        --indent;
        if (d.deparser->egress_port)
            out << indent << "egress_unicast_port: "
                << canon_name(d.phv.field(d.deparser->egress_port)->name) << std::endl; }
    return out;
}
