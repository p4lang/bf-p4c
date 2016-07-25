#include "asm_output.h"

class OutputDictionary : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    indent_t            indent;
    bool preorder(const IR::Primitive *prim) {
        if (prim->name != "emit") return true;
        PhvInfo::Field::bitrange bits;
        auto field = phv.field(prim->operands[0], &bits);
        if (!field->size) {
            /* varbits? not supported */
            return false; }
        auto &alloc = field->for_bit(bits.lo);
        if (size_t(alloc.container_bit + alloc.width) != alloc.container.size())
            return false;
        int size = alloc.container.size() / 8;
        if (bits.size() != size * 8) {
            out << indent << alloc.container;
        } else {
            out << indent << canon_name(field->name);
            if (bits.lo != 0 || bits.hi + 1 != field->size)
                out << '.' << bits.lo << '-' << bits.hi; }
        out << ": ";
        if (field->metadata)
            out << "$bridge-metadata";
        else
            out << canon_name(trim_asm_name(field->header())) << ".$valid";
        out << std::endl;
        return false; }

 public:
    OutputDictionary(std::ostream &out, const PhvInfo &phv, indent_t indent)
    : out(out), phv(phv), indent(indent) {}
};

std::ostream &operator<<(std::ostream &out, const DeparserAsmOutput &d) {
    indent_t    indent(1);
    out << "deparser " << d.gress << ":" << std::endl;
    out << indent << "dictionary:";
    if (!d.deparser || d.deparser->emits.empty())
        out << " {}";
    out << std::endl;
    if (d.deparser) {
        d.deparser->emits.apply(OutputDictionary(out, d.phv, ++indent));
        --indent;
        if (d.deparser->egress_port)
            out << indent << "egress_unicast_port: "
                << canon_name(d.phv.field(d.deparser->egress_port)->name) << std::endl; }
    return out;
}
