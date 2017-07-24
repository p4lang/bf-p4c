#include "asm_output.h"

class OutputDictionary : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    indent_t            indent;
    PHV::Container      last;
    bool preorder(const IR::Primitive *prim) {
        if (prim->name != "emit") return true;
        PhvInfo::Field::bitrange bits;
        auto field = phv.field(prim->operands[0], &bits);
        if (!field->size) {
            /* varbits? not supported */
            LOG3("skipping varbits? " << field->name);
            return false; }
        auto &alloc = field->for_bit(bits.lo);
        if (last == alloc.container) {
            LOG2("skipping repeat container " << alloc << " " << field->name);
            return false; }
        last = alloc.container;
        int size = alloc.container.size() / 8;
        if (bits.size() != size * 8) {
            out << indent << alloc.container;
        } else {
            out << indent << canon_name(field->name);
            if (bits.lo != 0 || bits.hi + 1 != field->size)
                out << '.' << bits.lo << '-' << bits.hi; }
        out << ": ";
        if (field->metadata)
            out << "$always_deparse";
        else
            out << canon_name(trim_asm_name(field->header())) << ".$valid";
        out << std::endl;
        return false; }

 public:
    OutputDictionary(std::ostream &out, const PhvInfo &phv, indent_t indent)
    : out(out), phv(phv), indent(indent) {}
};

void DeparserAsmOutput::emit_fieldlist(std::ostream &out, const IR::Vector<IR::Expression> *list,
                                       const char *sep) const {
    PHV::Container last;
    for (auto f : *list) {
        bitrange bits;
        if (auto field = phv.field(f, &bits)) {
            auto &alloc = field->for_bit(bits.lo);
            if (last && alloc.container == last)
                continue;
            last = alloc.container;
            if (alloc.container && size_t(bits.size()) != alloc.container.size()) {
                out << sep << alloc.container;
            } else {
                out << sep << canon_name(field->name);
                if (bits.lo != 0 || bits.hi + 1 != field->size)
                    out << '.' << bits.lo << '-' << bits.hi; }
            sep = ", "; } }
}

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
                << canon_name(d.phv.field(d.deparser->egress_port)->name) << std::endl;
        for (auto digest : Values(d.deparser->digests)) {
            int idx = 0;
            out << indent++ << digest->name << ":" << std::endl;
            for (auto l : digest->sets) {
                out << indent << idx++ << ": [ " << canon_name(digest->select->name);
                d.emit_fieldlist(out, l, ", ");
                out << " ]" << std::endl; }
            out << indent-- << "select: " << canon_name(digest->select->name) << std::endl; } }
    return out;
}
