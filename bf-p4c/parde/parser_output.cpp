#include "asm_output.h"
#include "lib/match.h"
#include "lib/log.h"
#include "lib/range.h"

struct ExtractDestFormatter {
    const PhvInfo::Field* dest;
    bitrange bits;
};


std::ostream& operator<<(std::ostream& out, const ExtractDestFormatter& format) {
    out << canon_name(format.dest->name);
    if (format.bits.lo != 0 || format.bits.hi + 1 != format.dest->size)
        out << '.' << format.bits.lo << '-' << format.bits.hi;
    return out;
}

class OutputExtracts : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    indent_t            indent;
    PHV::Container      last;

    bool preorder(const IR::Tofino::ExtractBuffer* extract) {
        bitrange bits;
        auto dest = phv.field(extract->dest, &bits);
        if (!dest) {
            out << indent << "# no phv: " << *extract << std::endl;
            return false;
        }

        auto &alloc = dest->for_bit(bits.lo);
        if (alloc.container == last) {
            out << indent << "    # - " << alloc.container_bits() << " "
                << ExtractDestFormatter{dest, bits} << std::endl;
            return false;
        }
        last = alloc.container;

        const int byteOffset = extract->bitInterval().loByte();
        const int byteSize = alloc.container.size() / 8U;
        out << indent << Range(byteOffset, byteOffset + byteSize - 1) << ": ";
        if (unsigned(bits.size()) != alloc.container.size()) {
            out << alloc.container << std::endl;
            out << indent << "    # - " << alloc.container_bits() << " ";
        }
        out << ExtractDestFormatter{dest, bits} << std::endl;
        return false;
    }

    bool preorder(const IR::Tofino::ExtractConstant* extract) {
        bitrange bits;
        auto dest = phv.field(extract->dest, &bits);
        if (!dest) {
            out << indent << "# no phv: " << *extract << std::endl;
            return false;
        }
        out << indent << canon_name(dest->name) << ": "
            << extract->constant->value << std::endl;
        return false;
    }

    bool preorder(const IR::Tofino::ParserPrimitive* primitive) {
        out << indent << "# unsupported: " << *primitive << std::endl;
        return false;
    }

 public:
    OutputExtracts(std::ostream &o, const PhvInfo &phv, indent_t i) : out(o), phv(phv), indent(i) {}
};

static void output_match(std::ostream &out, const PhvInfo &phv, indent_t indent,
                         const IR::Tofino::ParserMatch *match) {
    if (match->value)
        out << indent << match->value << ':' << std::endl;
    else
        out << indent << "0x*:" << std::endl;
    ++indent;
    match->stmts.apply(OutputExtracts(out, phv, indent));
    if (match->shift)
        out << indent << (match->shift < 0 ? "# " : "") << "shift: " << match->shift << std::endl;
    out << indent << "next: ";
    if (match->next)
        out << canon_name(match->next->name);
    else
        out << "end";
    out << std::endl;
    --indent;
}

static void output_state(std::ostream &out, const PhvInfo &phv, indent_t indent,
                         const IR::Tofino::ParserState *state) {
    out << indent++ << canon_name(state->name) << ':' << std::endl;
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
        output_match(out, phv, indent, m);
    --indent;
}

std::ostream &operator<<(std::ostream &out, const ParserAsmOutput &parser) {
    indent_t    indent(1);
    out << "parser " << parser.gress << ":" << std::endl;
    if (parser.parser && parser.parser->start)
        out << indent << "start: " << canon_name(parser.parser->start->name) << std::endl;
    for (auto state : parser.states)
        output_state(out, parser.phv, indent, state);
    return out;
}
