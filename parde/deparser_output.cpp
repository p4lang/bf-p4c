#include "asm_output.h"

class OutputDictionary : public Inspector {
    std::ostream        &out;
    indent_t            indent;
    bool preorder(const IR::Primitive *prim) {
        if (prim->name != "emit") return true;
        auto field = prim->operands[0]->to<IR::FieldRef>();
        out << indent << trim_asm_name(field->toString()) << ": "
            << trim_asm_name(field->base->toString()) << ".$valid" << std::endl;
        return false; }

 public:
    OutputDictionary(std::ostream &out, indent_t indent) : out(out), indent(indent) {}
};

std::ostream &operator<<(std::ostream &out, const DeparserAsmOutput &d) {
    indent_t    indent(1);
    out << "deparser " << d.gress << ":" << std::endl;
    out << indent << "dictionary:" << std::endl;
    d.deparser->emits.apply(OutputDictionary(out, ++indent));
    --indent;
    if (d.deparser->egress_port)
        out << indent << "egress_unicast_port: "
            << trim_asm_name(d.deparser->egress_port->toString()) << std::endl;
    return out;
}
