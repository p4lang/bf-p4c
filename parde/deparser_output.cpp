#include "asm_output.h"

static const IR::Expression *header_ref(const IR::Expression *e) {
    /* FIXME(cdodd) -- this is a nasty hack */
    if (auto *p = e->to<IR::HeaderSliceRef>()) return p->header_ref();
    if (auto *p = e->to<IR::FieldRef>()) return p->base;
    return 0;
}

class OutputDictionary : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    indent_t            indent;
    bool preorder(const IR::Primitive *prim) {
        if (prim->name != "emit") return true;
        auto field = prim->operands[0];
        out << indent << phv.field(field)->name << ": "
            << trim_asm_name(header_ref(field)->toString()) << ".$valid" << std::endl;
        return false; }

 public:
    OutputDictionary(std::ostream &out, const PhvInfo &phv, indent_t indent)
    : out(out), phv(phv), indent(indent) {}
};

std::ostream &operator<<(std::ostream &out, const DeparserAsmOutput &d) {
    indent_t    indent(1);
    out << "deparser " << d.gress << ":" << std::endl;
    out << indent << "dictionary:" << std::endl;
    d.deparser->emits.apply(OutputDictionary(out, d.phv, ++indent));
    --indent;
    if (d.deparser->egress_port)
        out << indent << "egress_unicast_port: "
            << d.phv.field(d.deparser->egress_port)->name << std::endl;
    return out;
}
