#include "asm_output.h"
#include "lib/match.h"
#include "lib/log.h"
#include "lib/range.h"

class OutputExtracts : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    indent_t            indent;
    int                 offset = 0;
    bool preorder(const IR::Primitive *prim) {
        auto dest = phv.field(prim->operands[0]);
        if (prim->name == "extract") {
            int size = (prim->operands[0]->type->width_bits() + 7) / 8U;
            out << indent << Range(offset, offset+size-1) << ": " << dest->name;
            offset += size;
        } else if (prim->name == "set_metadata") {
            out << indent << dest->name << ": ";
            if (auto val = prim->operands[1]->to<IR::Constant>())
                out << val->value;
            else
                out << "/* " << *prim->operands[1] << " */";
        } else {
            out << indent << "/* " << *prim << " */"; }
        out << std::endl;
        return false; }
 public:
    OutputExtracts(std::ostream &o, const PhvInfo &phv, indent_t i) : out(o), phv(phv), indent(i) {}
};

static void output_match(std::ostream &out, const PhvInfo &phv, indent_t indent,
                         const IR::Tofino::ParserMatch *match) {
    if (match->value)
        out << indent << match->value << ':' << std::endl;
    else
        out << indent << "default:" << std::endl;
    ++indent;
    match->stmts.apply(OutputExtracts(out, phv, indent));
    if (match->shift)
        out << indent << "shift: " << match->shift << std::endl;
    out << indent << "next: " << (match->next ? match->next->name : "end") << std::endl;
    --indent;
}

static void output_state(std::ostream &out, const PhvInfo &phv, indent_t indent,
                         const IR::Tofino::ParserState *state) {
    out << indent++ << state->name << ':' << std::endl;
    if (!state->select.empty()) {
        out << indent << "match: ";
        const char *sep = "[ ";
        for (auto e : state->select) {
            out << sep << *e;
            sep = ", "; }
        out << " ]" << std::endl; }
    for (auto m : state->match)
        output_match(out, phv, indent, m);
    --indent;
}

std::ostream &operator<<(std::ostream &out, const ParserAsmOutput &parser) {
    indent_t    indent(1);
    out << "parser " << parser.gress << ":" << std::endl;
    if (parser.parser && parser.parser->start)
        out << indent << "start: " << parser.parser->start->name << std::endl;
    for (auto state : parser.states)
        output_state(out, parser.phv, indent, state);
    return out;
}
