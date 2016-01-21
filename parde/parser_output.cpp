#include "asm_output.h"
#include "lib/match.h"
#include "lib/log.h"
#include "lib/range.h"

class OutputExtracts : public Inspector {
    std::ostream        &out;
    indent_t            indent;
    int                 offset = 0;
    bool preorder(const IR::Primitive *prim) {
        cstring dest = trim_asm_name(prim->operands[0]->toString());
        if (prim->name == "extract") {
            int size = prim->operands[0]->type->width_bits() / 8U;
            out << indent << Range(offset, offset+size-1) << ": " << dest << std::endl;
            offset += size;
        } else if (prim->name == "set_metadata") {
            out << indent << dest << ": " << *prim->operands[1] << std::endl;
        } else {
            out << indent << "/* " << *prim << " */"  << std::endl; }
        return false; }
 public:
    OutputExtracts(std::ostream &o, indent_t i) : out(o), indent(i) {}
};

static void output_match(std::ostream &out, indent_t indent, const IR::Tofino::ParserMatch *match) {
    if (match->value)
        out << indent << match->value << ':' << std::endl;
    else
        out << indent << "default:" << std::endl;
    ++indent;
    match->stmts.apply(OutputExtracts(out, indent));
    if (match->shift)
        out << indent << "shift: " << match->shift << std::endl;
    out << indent << "next: " << (match->next ? match->next->name : "end") << std::endl;
    --indent;
}

static void output_state(std::ostream &out, indent_t indent, const IR::Tofino::ParserState *state) {
    out << indent++ << state->name << ':' << std::endl;
    if (!state->select.empty()) {
        out << indent << "match: ";
        const char *sep = "[ ";
        for (auto e : state->select) {
            out << sep << *e;
            sep = ", "; }
        out << " ]" << std::endl; }
    for (auto m : state->match)
        output_match(out, indent, m);
    --indent;
}

std::ostream &operator<<(std::ostream &out, const ParserAsmOutput &parser) {
    indent_t    indent(1);
    out << "parser " << parser.gress << ":" << std::endl;
    if (parser.parser->start)
        out << indent << "start: " << parser.parser->start->name << std::endl;
    for (auto state : parser.states)
        output_state(out, indent, state);
    return out;
}
