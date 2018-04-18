#include "asm_output.h"

#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/common/autoindent.h"
#include "bf-p4c/common/debug_info.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/match.h"
#include "lib/log.h"
#include "lib/range.h"

namespace {

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

        if (!parser->initZeroContainers.empty()) {
            out << indent << "init_zero: ";
            const char *sep = "[ ";
            for (auto container : parser->initZeroContainers) {
                out << sep << container;
                sep = ", ";
            }
            out << " ]" << std::endl;
        }

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

        if (parser->epbConfig)
            out << indent << "meta_opt: " << parser->epbConfig->fieldsEnabled
                << std::endl;

        if (parser->parserError)
            out << indent << "parser_error: " << parser->parserError << std::endl;

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
            // XXX(yumin): The order of registers is sorted by MatchRegister::operator<.
            // We use this order to adjust the match value.
            std::set<MatchRegister> used_registers;
            for (auto *select : state->select) {
                for (auto& r : select->reg) {
                    used_registers.insert(r); } }

            out << indent << "match: ";
            const char *sep = "[ ";
            for (const auto& r : used_registers) {
                out << sep << r;
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

        if (match->value_set)
            out << indent << "value_set " << match->value_set->controlPlaneName()
                << " " << match->value_set->size << ':' << std::endl;
        else if (match->value)
            out << indent << match->value << ':' << std::endl;
        else
            out << indent << "0x*:" << std::endl;

        AutoIndent indentMatch(indent);

        for (auto* ck : match->checksums) {
            if (auto* csum = ck->to<IR::BFN::LoweredParserChecksum>())
                outputChecksum(csum);
        }

        for (auto* stmt : match->statements) {
            if (auto* extract = stmt->to<IR::BFN::LoweredExtractPhv>())
                outputExtractPhv(extract);
            else if (auto* extract = stmt->to<IR::BFN::LoweredExtractClot>())
                outputExtractClot(extract);
            else
                BUG("unknown lowered parser primitive type");
        }

        outputSave(match->saves);

        if (match->shift != 0)
            out << indent << "shift: " << match->shift << std::endl;

        if (match->bufferRequired)
            out << indent << "buf_req: " << *match->bufferRequired << std::endl;

        out << indent << "next: ";
        if (match->next)
            out << canon_name(match->next->name);
        else
            out << "end";

        out << std::endl;
    }

    void outputSave(const IR::Vector<IR::BFN::LoweredSave>& saves) {
        if (!saves.size()) {
            return; }
        const char* sep = "save: { ";
        out << indent;
        for (const auto* save : saves) {
            if (auto* source = save->source->to<IR::BFN::LoweredBufferlikeRVal>()) {
                auto bytes = source->extractedBytes();
                out << sep << save->dest << " : " << Range(bytes.lo, bytes.hi);
                sep = ", "; }
        }
        out << " }" << std::endl;
    }

    void outputExtractPhv(const IR::BFN::LoweredExtractPhv* extract) {
        if (!extract->dest)
            return;

        // Generate the assembly that actually implements the extract.
        if (auto* source = extract->source->to<IR::BFN::LoweredBufferlikeRVal>()) {
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

    void outputExtractClot(const IR::BFN::LoweredExtractClot* extract) {
        out << indent << "clot " << extract->dest.tag << " :" << std::endl;
        AutoIndent ai(indent, 1);

        if (auto* source = extract->source->to<IR::BFN::LoweredPacketRVal>()) {
            auto bytes = source->extractedBytes();
            out << indent << "start: " << bytes.lo << std::endl;
            out << indent << "length: " << bytes.hi - bytes.lo + 1 << std::endl;
            if (clot_tag_to_checksum_unit.count(extract->dest.tag))
                out << indent << "checksum: " << clot_tag_to_checksum_unit.at(extract->dest.tag)
                    << std::endl;
        } else {
            BUG("Can't generate assembly for: %1%", extract);
        }
    }

    void outputChecksum(const IR::BFN::LoweredParserChecksum* csum) {
        cstring type;
        switch (csum->type) {
            case 0: type = "verify";   break;
            case 1: type = "residual"; break;
            case 2: type = "clot";     break;
            default: BUG("Unknown parser checksum type");
        }
        out << indent << "checksum " << csum->unit_id << ":" << std::endl;
        AutoIndent indentCsum(indent, 1);
        out << indent << "type: " << type << std::endl;

        // TODO(zma) these low level bit encoding can be pushed down into the
        // assembler by using some syntax sugar in the assembly
        out << indent << "mask: " << csum->mask << std::endl;
        out << indent << "swap: " << csum->swap << std::endl;
        out << indent << "start: " << csum->start  << std::endl;
        out << indent << "end: " << csum->end  << std::endl;

        auto parser = findContext<IR::BFN::LoweredParser>();
        if (csum->type == 0) {
            // XXX(zma) checksum error can have its own container dest,
            // we use parser error to be consistent with glass
            if (parser->parserError) {
                out << indent << "dest: " << parser->parserError << std::endl;
            }
        } else if (csum->type == 1 && csum->phv_dest) {
            out << indent << "dest: " << csum->phv_dest << std::endl;
        } else if (csum->type == 2) {
            out << indent << "dest: " << csum->clot_dest << std::endl;

            clot_tag_to_checksum_unit[csum->clot_dest.tag] = csum->unit_id;
        }

        if (csum->type == 0 && parser->parserError) {
            // XXX(zma) again, hard-coded to be consistent with glass for now
            out << indent << "dst_bit: 12" << std::endl;
        }
    }

    // XXX(zma) really a work-around due to lack of reference support of clot
    // in assembler
    std::map<unsigned, unsigned> clot_tag_to_checksum_unit;

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
