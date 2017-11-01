#include "asm_output.h"

#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/common/debug_info.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/match.h"
#include "lib/log.h"
#include "lib/range.h"

namespace {

/// A RAII helper that indents when it's created and unindents by the same
/// amount when it's destroyed.
/// XXX(seth): This should live in indent.h.
struct AutoIndent {
    explicit AutoIndent(indent_t& indent, int indentBy = 1)
      : indent(indent), indentBy(indentBy) { indent += indentBy; }
    ~AutoIndent() { indent -= indentBy; }

 private:
    indent_t& indent;
    int indentBy;
};

/// Generates parser assembly by walking the IR and writes the result to an
/// output stream. The parser IR must be in lowered form - i.e., the root must
/// a LoweredParser rather than a Parser.
struct ParserAsmSerializer : public ParserInspector {
    explicit ParserAsmSerializer(std::ostream& out) : out(out) { }

 private:
    bool preorder(const IR::BFN::LoweredParser* parser) override {
        AutoIndent indentParser(indent);

        out << "parser " << parser->gress << ":" << std::endl;
        if (parser->start)
            out << indent << "start: " << canon_name(parser->start->name)
                << std::endl;

        if (!parser->multiwriteContainers.empty()) {
            out << indent << "multi_write: ";
            const char *sep = "[ ";
            for (auto container : parser->multiwriteContainers) {
                out << sep << container;
                sep = ", ";
            }
            out << " ]" << std::endl;
        }

        out << indent << "hdr_len_adj: " << parser->prePacketDataLengthBytes
            << std::endl;

        out << indent << "states:" << std::endl;

        return true;
    }

    bool preorder(const IR::BFN::LoweredParserState* state) override {
        AutoIndent indentState(indent, 2);

        out << indent << canon_name(state->name) << ':';

        // Print human-friendly debug information about this state - any unhandled
        // primitives it included, the higher-level states it may have been
        // constructed from, etc.
        for (auto& info : state->debug.info) {
            if (state->debug.info.size() == 1)
                out << "  # ";
            else
                out << std::endl << indent << "      # - ";
            out << info;
        }

        out << std::endl;

        if (!state->select.empty()) {
            AutoIndent indentSelect(indent);

            // Generate the assembly that actually implements the select.
            out << indent << "match: ";
            const char *sep = "[ ";
            for (auto* select : state->select) {
                out << sep << Range(select->range.lo, select->range.hi);
                sep = ", ";
            }
            out << " ]" << std::endl;

            // Print human-friendly debug info about what the select offsets
            // mean in terms of the original P4 program.
            for (auto* select : state->select)
                for (auto& info : select->debug.info)
                    out << "      # - " << info << std::endl;
        }

        for (auto* match : state->match)
            outputMatch(match);

        return true;
    }

    void outputMatch(const IR::BFN::LoweredParserMatch* match) {
        AutoIndent indentMatchPattern(indent);

        if (match->value)
            out << indent << match->value << ':' << std::endl;
        else
            out << indent << "0x*:" << std::endl;

        AutoIndent indentMatch(indent);

        for (auto* extract : match->statements)
            outputExtract(extract);

        if (match->shift != 0)
            out << indent << "shift: " << match->shift << std::endl;

        out << indent << "next: ";
        if (match->next)
            out << canon_name(match->next->name);
        else
            out << "end";

        out << std::endl;
    }

    void outputExtract(const IR::BFN::LoweredExtract* extract) {
        // Generate the assembly that actually implements the extract.
        if (auto* source = extract->source->to<IR::BFN::LoweredBufferRVal>()) {
            auto bytes = source->extractedBytes();
            out << indent << Range(bytes.lo, bytes.hi) << ": " << extract->dest;
        } else if (auto* source = extract->source->to<IR::BFN::LoweredConstantRVal>()) {
            out << indent << extract->dest << ": " << source->constant;
        } else {
            BUG("Can't generate assembly for: %1%", extract);
        }

        // Print human-friendly debug info about the extract - what it's writing
        // to, what higher-level extracts it may have been generated from, etc.
        for (auto& info : extract->debug.info) {
            if (extract->debug.info.size() == 1)
                out << "  # ";
            else
                out << std::endl << indent << "    # - ";
            out << info;
        }

        out << std::endl;
    }

    std::ostream& out;
    indent_t indent;
};

}  // namespace

ParserAsmOutput::ParserAsmOutput(const IR::BFN::Pipe* pipe,
                                 gress_t gress)
        : parser(nullptr) {
    auto* abstractParser = pipe->thread[gress].parser;
    BUG_CHECK(abstractParser != nullptr, "No parser?");
    parser = abstractParser->to<IR::BFN::LoweredParser>();
    BUG_CHECK(parser != nullptr, "Writing assembly for a non-lowered parser?");
}

std::ostream& operator<<(std::ostream& out, const ParserAsmOutput& parserOut) {
    ParserAsmSerializer serializer(out);
    parserOut.parser->apply(serializer);
    return out;
}
