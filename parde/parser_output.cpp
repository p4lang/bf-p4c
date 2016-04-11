#include "asm_output.h"
#include "lib/match.h"
#include "lib/log.h"
#include "lib/range.h"

class OutputExtracts : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    gress_t             gress;
    indent_t            indent;
    int                 offset = 0;
    bool preorder(const IR::Primitive *prim) {
        PhvInfo::Info::bitrange bits;
        auto dest = phv.field(prim->operands[0], &bits);
        if (dest && prim->name == "extract") {
            int size = (prim->operands[0]->type->width_bits() + 7) / 8U;
            out << indent << Range(offset, offset+size-1) << ": ";
            if (bits.size() != size * 8) {
                out << dest->for_bit(gress, bits.lo).container;
            } else {
                out << canon_name(dest->name);
                if (bits.lo != 0 || bits.hi + 1 != dest->size)
                    out << '.' << bits.lo << '-' << bits.hi; }
            offset += size;
        } else if (dest && prim->name == "set_metadata") {
            out << indent << canon_name(dest->name) << ": ";
            if (auto val = prim->operands[1]->to<IR::Constant>())
                out << val->value;
            else
                out << "/* " << *prim->operands[1] << " */";
        } else {
            out << indent << "/* " << *prim << " */"; }
        out << std::endl;
        return false; }

 public:
    OutputExtracts(std::ostream &o, const PhvInfo &phv, gress_t gress, indent_t i)
    : out(o), phv(phv), gress(gress), indent(i) {}
};

static void output_match(std::ostream &out, const PhvInfo &phv, gress_t gress, indent_t indent,
                         const IR::Tofino::ParserMatch *match) {
    if (match->value)
        out << indent << match->value << ':' << std::endl;
    else
        out << indent << "0x*:" << std::endl;
    ++indent;
    match->stmts.apply(OutputExtracts(out, phv, gress, indent));
    if (match->shift)
        out << indent << "shift: " << match->shift << std::endl;
    out << indent << "next: " << (match->next ? match->next->name : "end") << std::endl;
    --indent;
}

static void output_state(std::ostream &out, const PhvInfo &phv, gress_t gress, indent_t indent,
                         const IR::Tofino::ParserState *state) {
    out << indent++ << state->name << ':' << std::endl;
    if (!state->select.empty()) {
        out << indent << "match: ";
        const char *sep = "[ ";
        for (auto e : state->select) {
            if (auto field = phv.field(e))
                out << sep << canon_name(field->name);
            else if (e->is<IR::Constant>())
                out << sep << e->toString();
            else if (auto r = e->to<IR::Range>())
                out << sep << r->left->toString() << ".." << r->right->toString();
            else
                out << sep << "/* " << *e << " */";
            sep = ", "; }
        out << " ]" << std::endl; }
    for (auto m : state->match)
        output_match(out, phv, gress, indent, m);
    --indent;
}

std::ostream &operator<<(std::ostream &out, const ParserAsmOutput &parser) {
    indent_t    indent(1);
    out << "parser " << parser.gress << ":" << std::endl;
    if (parser.parser && parser.parser->start)
        out << indent << "start: " << parser.parser->start->name << std::endl;
    for (auto state : parser.states)
        output_state(out, parser.phv, parser.gress, indent, state);
    return out;
}
