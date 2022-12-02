#include <algorithm>
#include <boost/optional/optional_io.hpp>

#include "lib/match.h"
#include "lib/log.h"
#include "lib/range.h"

#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/common/autoindent.h"
#include "bf-p4c/common/debug_info.h"
#include "bf-p4c/common/flatrock.h"
#include "bf-p4c/parde/asm_output.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/phv/phv_fields.h"

namespace {

// Generates parser assembly by walking the IR and writes the result to an
// output stream. The parser IR must be in lowered form - i.e., the root must
// a LoweredParser rather than a Parser.
//
// PVS Handle Generation
// TNA instantiates different parsers for ingress and egress and therefore
// expects a unique pvs handle for each gress.
// However this is not the case with V1Model as it always instantiates the same parser
//
//                  P4-14                      P4-16
//
// TNA          Share PVS Handle           Share PVS Handle
//              across and                 only within ig/eg
//              within ig/eg               Don't share across ig/eg
//
static int pvs_handle = 512;
static std::map<cstring, int> pvs_handles;
struct ParserAsmSerializer : public ParserInspector {
    explicit ParserAsmSerializer(std::ostream& out, const PhvInfo& phv, const ClotInfo& clot_info)
       : out(out), phv(phv), clot_info(clot_info) {
        is_v1Model = (BackendOptions().arch == "v1model"); }

 private:
    bool is_v1Model = false;
    void init_apply() {
       // If not v1Model share pvs handles only when pvs is invoked multiple
       // times within the same parser.
       if (!is_v1Model) pvs_handles.clear();
    }

    int getPvsHandle(cstring pvsName) {
        // For P4_14 parser value set is shared across ingress and egress,
        // Assign the same pvs handle in these cases
        int handle = -1;
        if (pvs_handles.count(pvsName) > 0) {
            handle = pvs_handles[pvsName];
        } else {
            handle = --pvs_handle;
            pvs_handles[pvsName] = handle;
        }
        return handle;
    }

#ifdef HAVE_FLATROCK

    bool preorder(const IR::Flatrock::Parser* parser) override {
        AutoIndent indentParser(indent, 0);
        out << indent << "parser ingress:" << std::endl;
        if (!parser->states.empty()){
            indent++;
            out << indent << "states:" << std::endl;
            indent++;
            for (auto &state : parser->states)
                out << indent << state.first << ": " << state.second << std::endl;
            indent--;
            indent--;
        }
        return true;
    }

    bool preorder(const IR::Flatrock::PortMetadata* port_metadata) override {
        AutoIndent indentParser(indent, 1);
        if (port_metadata->items.size() > 0)
            out << indent << "port_metadata:" << std::endl;
        return true;
    }

    bool preorder(const IR::Flatrock::PortMetadataItem* port_metadata_item) override {
        AutoIndent indentParser(indent, 2);
        out << indent << port_metadata_item->port << ": [ ";
        cstring sep = "";
        for (auto &i : port_metadata_item->data) {
            out << sep << static_cast<unsigned int>(i);
            sep = ", ";
        }
        out << " ]" << std::endl;
        return true;
    }

    bool preorder(const IR::Flatrock::Profile* profile) override {
        AutoIndent indentParser(indent, 1);
        out << indent << "profile " << profile->index << ":" << std::endl;
        indent++;
        out << indent << "match_port: " << profile->match_port << std::endl;
        out << indent << "match_inband_metadata: " << profile->match_inband_metadata << std::endl;
        out << indent << "initial_pktlen: " << profile->initial_pktlen << std::endl;
        out << indent << "initial_seglen: " << profile->initial_seglen << std::endl;
        if (profile->initial_state_name) {
            out << indent << "initial_state: " << *profile->initial_state_name << std::endl;
        } else if (profile->initial_state && profile->initial_state->size() > 0) {
            out << indent << "initial_state: 0x";
            auto original_flags = out.flags();
            auto original_fill = out.fill('0');
            for (auto &s : *profile->initial_state)
                out << std::hex << std::setw(2) << static_cast<unsigned int>(s);
            out << std::endl;
            out.fill(original_fill);
            out.flags(original_flags);
        }
        if (profile->initial_flags && profile->initial_flags->size() > 0) {
            out << indent << "initial_flags: 0x";
            auto original_flags = out.flags();
            auto original_fill = out.fill('0');
            for (auto &f : *profile->initial_flags)
                out << std::hex << std::setw(2) << static_cast<unsigned int>(f);
            out << std::endl;
            out.fill(original_fill);
            out.flags(original_flags);
        }
        if (profile->initial_ptr)
            out << indent << "initial_ptr: " << profile->initial_ptr << std::endl;
        if (profile->initial_w0_offset)
            out << indent << "initial_w0_offset: " << profile->initial_w0_offset << std::endl;
        if (profile->initial_w1_offset)
            out << indent << "initial_w1_offset: " << profile->initial_w1_offset << std::endl;
        if (profile->initial_w2_offset)
            out << indent << "initial_w2_offset: " << profile->initial_w2_offset << std::endl;
        if (profile->initial_alu0_instruction) {
            out << indent << "initial_alu0_instruction: ";
            print_params(out, *profile->initial_alu0_instruction);
            out << "  # ";
            print_pretty(out, *profile->initial_alu0_instruction);
            out << std::endl;
        }
        if (profile->initial_alu1_instruction) {
            out << indent << "initial_alu1_instruction: ";
            print_params(out, *profile->initial_alu1_instruction);
            out << "  # ";
            print_pretty(out, *profile->initial_alu1_instruction);
            out << std::endl;
        }
        if (profile->metadata_select.size() > 0) {
            out << indent << "metadata_select: [ ";
            std::string sep = "";
            for (auto &m : profile->metadata_select) {
                out << sep << m;
                sep = ", ";
            }
            out << " ]" << std::endl;
        }
        indent--;
        return true;
    }

    bool preorder(const IR::Flatrock::AnalyzerStage* analyzer_stage) override {
        AutoIndent indentParser(indent, 1);
        out << indent << "analyzer_stage " << analyzer_stage->stage;
        if (!analyzer_stage->name.isNullOrEmpty())
            out << " " << analyzer_stage->name;
        out << ":" << std::endl;
        return true;
    }

    bool preorder(const IR::Flatrock::AnalyzerRule* analyzer_rule) override {
        AutoIndent indentParser(indent, 2);
        out << indent << "rule " << analyzer_rule->index << ":" << std::endl;
        indent++;
        if (auto *stage = findContext<IR::Flatrock::AnalyzerStage>()) {
            if (!stage->name)
                // Named analyzer stage must not contain any rule with the match_state attribute
                out << indent << "match_state: " << analyzer_rule->match_state << std::endl;
        }
        out << indent << "match_w0: " << analyzer_rule->match_w0 << std::endl;
        out << indent << "match_w1: " << analyzer_rule->match_w1 << std::endl;
        if (analyzer_rule->next_state_name) {
            out << indent << "next_state: " << *analyzer_rule->next_state_name << std::endl;
        } else if (analyzer_rule->next_state) {
            out << indent << "next_state: " << *analyzer_rule->next_state << std::endl;
        }
        if (analyzer_rule->next_w0_offset)
            out << indent << "next_w0_offset: " << *analyzer_rule->next_w0_offset << std::endl;
        if (analyzer_rule->next_w1_offset)
            out << indent << "next_w1_offset: " << *analyzer_rule->next_w1_offset << std::endl;
        if (analyzer_rule->next_w2_offset)
            out << indent << "next_w2_offset: " << *analyzer_rule->next_w2_offset << std::endl;
        if (analyzer_rule->next_alu0_instruction) {
            out << indent << "next_alu0_instruction: ";
            print_params(out, *analyzer_rule->next_alu0_instruction);
            out << "  # ";
            print_pretty(out, *analyzer_rule->next_alu0_instruction);
            out << std::endl;
        }
        if (analyzer_rule->next_alu1_instruction) {
            out << indent << "next_alu1_instruction: ";
            print_params(out, *analyzer_rule->next_alu1_instruction);
            out << "  # ";
            print_pretty(out, *analyzer_rule->next_alu1_instruction);
            out << std::endl;
        }
        if (const auto& cksum = analyzer_rule->modify_checksum)
            out << indent
                << "modify_checksum: "
                << "{ cksum_idx: " << cksum->cksum_idx
                << ", enabled: " << (cksum->enabled ? "true" : "false")
                << "}" << std::endl;
        if (const auto& instr = analyzer_rule->modify_flags16)
            out << indent
                << "modify_flags16: "
                << "{ imm: "   << instr->imm
                << ", mask: "  << instr->mask
                << ", shift: " << static_cast<unsigned>(instr->shift)
                << ", src: "   << static_cast<unsigned>(instr->src)
                << " }" << std::endl;
        if (const auto& instr = analyzer_rule->modify_flags4)
            out << indent
                << "modify_flags4: "
                << "{ imm: "   << instr->imm
                << ", mask: "  << instr->mask
                << ", shift: " << static_cast<unsigned>(instr->shift)
                << ", src: "   << static_cast<unsigned>(instr->src)
                << " }" << std::endl;
        int i = 0;
        for (const auto& instr : {analyzer_rule->modify_flag0, analyzer_rule->modify_flag1}) {
            if (instr)
                out << indent
                    << "modify_flag" << i++ << ": "
                    << "{ "   << (instr->imm ? "set" : "clear")
                    << ": " << static_cast<unsigned>(instr->shift)
                    << " }" << std::endl;
        }
        if (analyzer_rule->push_hdr_id) {
            // Adjust the offset: when the ALU0 opcode == 0, we need to subtract the constant being
            // added by ALU0.
            // (Possibly temporary : see TFC-1610)
            int offset_adj = analyzer_rule->push_hdr_id->offset;
            if (analyzer_rule->next_alu0_instruction &&
                analyzer_rule->next_alu0_instruction->opcode ==
                    Flatrock::alu0_instruction::OPCODE_0) {
                offset_adj -= analyzer_rule->next_alu0_instruction->opcode_0_1.add_imm8s;
                offset_adj &= Flatrock::PARSER_W_OFFSET_MAX;
            }
            out << indent
                << "push_hdr_id: "
                << "{ hdr: "    << static_cast<unsigned>(analyzer_rule->push_hdr_id->hdr_id)
                << ", offset: " << static_cast<unsigned>(offset_adj)
                << " }" << std::endl;
        }
        indent--;
        return true;
    }

    bool preorder(const IR::Flatrock::PhvBuilderGroup* phv_builder_group) override {
        AutoIndent indentParser(indent, 1);
        out << indent << "phv_builder_group " << phv_builder_group->index << ":" << std::endl;
        indent++;
        out << indent << "pov_select: [ ";
        std::string sep = "";
        for (auto &p : phv_builder_group->pov_select) {
            out << sep << p;
            sep = ", ";
        }
        out << "]" << std::endl;
        indent--;
        return true;
    }

    bool preorder(const IR::Flatrock::PhvBuilderExtract* phv_builder_extract) override {
        AutoIndent indentParser(indent, 2);
        out << indent << "extract " << phv_builder_extract->index << ":" << std::endl;
        indent++;
        out << indent << "match: " << phv_builder_extract->match << std::endl;

        std::string source;
        switch (phv_builder_extract->size) {
        case PHV::Size::b8: source = "packet8"; break;
        case PHV::Size::b16: source = "packet16"; break;
        case PHV::Size::b32: source = "packet32"; break;
        default:
            BUG("invalid container size in PHV builder extractor");
            break;
        }

        auto output_extract = [this, &source](
                const PHV::Size size, const Flatrock::PheSource &phe_source) {
            if (phe_source.type == Flatrock::ExtractType::Packet) {
                if (phe_source.hdr_name) {
                    out << indent << "- " << source << ' ' << *phe_source.hdr_name << ' ';
                    if (size != PHV::Size::b32)
                        out << "[ ";
                    std::string sep = "";
                    for (auto &offset : phe_source.offsets) {
                        out << sep << offset.container;
                        if (size != PHV::Size::b8)
                            out << " msb_offset ";
                        else
                            out << " offset ";
                        out << offset.value;
                        sep = ", ";
                    }
                    if (size != PHV::Size::b32)
                        out << " ]";
                } else {
                    out << indent << "- {}";
                }
            } else {
                out << indent << "- { ";
                std::string sep = "";
                for (auto &offset : phe_source.offsets) {
                    out << sep << offset.container;
                    out << ": " << get_subtype_label(offset.subtype) << " ";
                    out << offset.value;
                    sep = ", ";
                }
                out << " }";
            }
            out << std::endl;
            indent++;
            for (auto& info : phe_source.debug.info)
                out << indent << "# " << info << std::endl;
            indent--;
        };

        out << indent << "source:" << std::endl;
        indent++;
        for (int i = 0; i < Flatrock::PARSER_PHV_BUILDER_GROUP_PHE_SOURCES; ++i)
            output_extract(phv_builder_extract->size, phv_builder_extract->source[i]);
        indent--;

        indent--;
        return true;
    }

    const char* get_subtype_label(const Flatrock::ExtractSubtype subtype) const {
        using namespace Flatrock;

        switch (subtype) {
            case ExtractSubtype::Constant:
                return "constant";
            case ExtractSubtype::PovFlags:
                return "pov_flags";
            case ExtractSubtype::PovState:
                return "pov_state";
            case ExtractSubtype::ChecksumError:
                return "checksum_and_error";
            case ExtractSubtype::Udf0:
                return "udf0";
            case ExtractSubtype::Udf1:
                return "udf1";
            case ExtractSubtype::Udf2:
                return "udf2";
            case ExtractSubtype::Udf3:
                return "udf3";
            case ExtractSubtype::Ghost:
                return "ghost";
            case ExtractSubtype::Tm:
                return "tm";
            case ExtractSubtype::Bridge:
                return "bridge";
            default:
                BUG("Unexpected ExtractSubtype");
        }
    }

    bool preorder(const IR::Flatrock::PseudoParser* /*pparser*/) override {
        out << "parser egress:" << std::endl;
        return true;
    }

#endif  // HAVE_FLATROCK

    bool preorder(const IR::BFN::LoweredParser* parser) override {
        AutoIndent indentParser(indent);

        out << "parser " << parser->gress;
        if (parser->portmap.size() != 0) {
            const char *sep = " [ ";
            for (auto port : parser->portmap) {
                out << sep << port;
                sep = ", ";
            }
            out << " ]";
        }
        out << ":" << std::endl;

        if (parser->name && parser->portmap.size() != 0)
            out << indent << "name: " << canon_name(parser->name)
                << std::endl;

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

        if (!parser->bitwiseOrContainers.empty()) {
            out << indent << "bitwise_or: ";
            const char *sep = "[ ";
            for (auto container : parser->bitwiseOrContainers) {
                out << sep << container;
                sep = ", ";
            }
            out << " ]" << std::endl;
        }

        if (!parser->clearOnWriteContainers.empty()) {
            out << indent << "clear_on_write: ";
            const char *sep = "[ ";
            for (auto container : parser->clearOnWriteContainers) {
                out << sep << container;
                sep = ", ";
            }
            out << " ]" << std::endl;
        }

        out << indent << "hdr_len_adj: " << parser->hdrLenAdj << std::endl;

        if (parser->metaOpt)
            out << indent << "meta_opt: " << *(parser->metaOpt) << std::endl;

        if (parser->parserError)
            out << indent << "parser_error: " << parser->parserError << std::endl;

        // Parse depth checks disabled (used by driver to disable multi-threading)
        if ((Device::pardeSpec().minParseDepth(parser->gress) > 0 &&
             BackendOptions().disable_parse_min_depth_limit) ||
            (Device::pardeSpec().maxParseDepth(parser->gress) < SIZE_MAX &&
             BackendOptions().disable_parse_max_depth_limit))
            out << indent << "parse_depth_checks_disabled: true" << std::endl;

        // Rate Limiter Setup :
        //
        // The rate limiter is configured in the parser arbiter which controls
        // the rate at which phv arrays are sent to MAU. Based on input pps load
        // we determine the configuration for rate limiter.
        //
        // Tofino - Sets max, inc. dec values on rate limiter
        //  - Decrement credits by dec after sending phv
        //  - Send only if available credits > dec value
        //  - If no phv sent increment credits by inc value
        //  - Saturate credits at max value
        //
        // JBay - Sets max, inc, interval values on rate limiter
        //  - Decrement credits by 1 after sending phv
        //  - Send only if available credit > 0
        //  - After every interval cycles increment credits by inc value
        //  - Saturate credits at max value
        //
        auto pps_load = BackendOptions().traffic_limit;
        if (pps_load > 0 && pps_load < 100) {
            int bubble_load = 100 - pps_load;
            int bubble_gcd = std::__gcd(100, bubble_load);
            int bubble_dec = bubble_load / bubble_gcd;
            int bubble_max = (100 / bubble_gcd) - bubble_dec;
            int bubble_inc = bubble_max;
            out << indent++ << "bubble: " << std::endl;
            out << indent << "max: " << bubble_max << std::endl;
            if (Device::currentDevice() == Device::TOFINO) {
                out << indent << "dec: " << bubble_dec << std::endl;
                LOG3("Bubble Rate Limiter ( load : " << pps_load << "%, bubble: "
                        << bubble_load << "%, max: " << bubble_max
                        << ", inc: " << bubble_inc <<", dec: " << bubble_dec << ")");
            } else {
                int bubble_intvl = 100 / bubble_gcd;
                bubble_inc = pps_load / bubble_gcd;
                out << indent << "interval: " << bubble_intvl << std::endl;
                LOG3("Bubble Rate Limiter ( load : " << pps_load << "%, bubble: "
                        << bubble_load << "%, max: " << bubble_max
                        << ", inc: " << bubble_inc <<", intvl: " << bubble_intvl << ")");
            }
            out << indent << "inc: " << bubble_inc << std::endl;
            indent--;
        }

        out << indent << "states:" << std::endl;

        return true;
    }

    bool preorder(const IR::BFN::LoweredParserState* state) override {
        AutoIndent indentState(indent, 2);

        out << indent << canon_name(state->name) << ':' << std::endl;

        if (!state->select->regs.empty() || !state->select->counters.empty()) {
            AutoIndent indentSelect(indent);

            out << indent << "match: ";
            const char *sep = "[ ";
            for (const auto& c : state->select->counters) {
                if (c->is<IR::BFN::ParserCounterIsZero>())
                    out << sep << "ctr_zero";
                else if (c->is<IR::BFN::ParserCounterIsNegative>())
                    out << sep << "ctr_neg";
                sep = ", ";
            }
            for (const auto& r : state->select->regs) {
                out << sep << r;
                sep = ", ";
            }
            out << " ]" << std::endl;

            // Print human-friendly debug info about what the select offsets
            // mean in terms of the original P4 program.
            for (auto& info : state->select->debug.info)
                out << "      # - " << info << std::endl;
        }

        for (auto* match : state->transitions)
            outputMatch(match, state->thread());

        return true;
    }

    void outputMatch(const IR::BFN::LoweredParserMatch* match, gress_t gress) {
        AutoIndent indentMatchPattern(indent);

        if (auto* const_val = match->value->to<IR::BFN::ParserConstMatchValue>()) {
            out << indent << const_val->value << ':' << std::endl;
        } else if (auto* pvs = match->value->to<IR::BFN::ParserPvsMatchValue>()) {
            out << indent << "value_set " << pvs->name << " " << pvs->size << ":" << std::endl;
            AutoIndent indentMatch(indent);
            out << indent << "handle: " << getPvsHandle(pvs->name) << std::endl;
            out << indent << "field_mapping:" << std::endl;
            AutoIndent indentFieldMap(indent);
            for (const auto& m : pvs->mapping) {
                cstring fieldname = m.first.first;
                cstring reg_name = m.second.first.name;
                out << indent
                    << fieldname << "(" << m.first.second.lo << ".." << m.first.second.hi << ")"
                    << " : "
                    << reg_name  << "(" << m.second.second.lo << ".." << m.second.second.hi << ")"
                    << std::endl;
            }
        } else {
            BUG("unknown parser match value %1%", match->value);
        }

        AutoIndent indentMatch(indent);

        if (match->priority)
            out << indent << "priority: " << match->priority->val << std::endl;

        for (auto* csum : match->checksums)
            outputChecksum(csum);

        for (auto* cntr : match->counters)
            outputCounter(cntr);

        int intrinsic_width = 0;
        for (auto* stmt : match->extracts) {
            if (auto* extract = stmt->to<IR::BFN::LoweredExtractPhv>())
                outputExtractPhv(extract, intrinsic_width);
            else if (auto* extract = stmt->to<IR::BFN::LoweredExtractClot>())
                outputExtractClot(extract);
            else
                BUG("unknown lowered parser primitive type");
        }

        if (intrinsic_width > 0 && gress == EGRESS)
            out << indent << "intr_md: " << intrinsic_width << std::endl;

        if (!match->saves.empty())
            outputSave(match->saves);

        if (!match->scratches.empty())
            outputScratch(match->scratches);

        if (match->shift != 0)
            out << indent << "shift: " << match->shift << std::endl;

        if (match->hdrLenIncFinalAmt)
            out << indent << "hdr_len_inc_stop: " << *match->hdrLenIncFinalAmt << std::endl;

        if (match->bufferRequired)
            out << indent << "buf_req: " << *match->bufferRequired << std::endl;

        if (match->offsetInc)
            out << indent << "offset_inc: " << *match->offsetInc << std::endl;

        if (match->partialHdrErrProc)
            out << indent << "partial_hdr_err_proc: 1" << std::endl;

        out << indent << "next: ";
        if (match->next)
            out << canon_name(match->next->name);
        else if (match->loop)
            out << canon_name(match->loop);
        else
            out << "end";

        out << std::endl;
    }

    void outputSave(const IR::Vector<IR::BFN::LoweredSave>& saves) {
        const char* sep = "load: { ";
        out << indent;
        for (const auto* save : saves) {
            if (auto* source = save->source->to<IR::BFN::LoweredInputBufferRVal>()) {
                auto bytes = source->range;
                out << sep << save->dest << " : " << Range(bytes.lo, bytes.hi);
                sep = ", ";
            }
        }
        out << " }" << std::endl;
    }

    void outputScratch(const std::set<MatchRegister>& scratches) {
        const char* sep = "save: [ ";
        out << indent;
        for (auto reg : scratches) {
            out << sep << reg.name;
            sep = ", ";
        }
        out << " ]" << std::endl;
    }

    void outputExtractPhv(const IR::BFN::LoweredExtractPhv* extract, int &intrinsic_width) {
        // Generate the assembly that actually implements the extract.
        if (auto* source = extract->source->to<IR::BFN::LoweredInputBufferRVal>()) {
            auto bytes = source->range;
            out << indent << Range(bytes.lo, bytes.hi) << ": " << extract->dest;
            for (auto sl : phv.get_slices_in_container(extract->dest->container)) {
                if (sl.field()->is_intrinsic()) intrinsic_width += sl.width();
            }
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
        if (extract->is_start) {
            out << indent << "clot " << extract->dest->tag << " :" << std::endl;
            AutoIndent ai(indent, 1);

            auto* source = extract->source->to<IR::BFN::LoweredPacketRVal>();
            cstring name = clot_info.sanitize_state_name(extract->higher_parser_state->name,
                                                         extract->higher_parser_state->gress);

            out << indent << "start: " << source->range.lo << std::endl;
            out << indent << "length: " << extract->dest->length_in_bytes(name) << std::endl;

            if (extract->dest->csum_unit) {
                out << indent << "checksum: " << extract->dest->csum_unit << std::endl;
            }
        } else {
            out << indent << "# clot " << extract->dest->tag << " (spilled)" << std::endl;
        }
    }

    void outputChecksum(const IR::BFN::LoweredParserChecksum* csum) {
        out << indent << "checksum " << csum->unit_id << ":" << std::endl;
        AutoIndent indentCsum(indent, 1);
        out << indent << "type: " << csum->type << std::endl;

        out << indent << "mask: ";
        out << "[ ";

        unsigned i = 0;
        for (auto r : csum->masked_ranges) {
            out << Range(r.lo, r.hi);

            if (i != csum->masked_ranges.size() - 1)
                out << ", ";
            i++;
        }

        out << " ]" << std::endl;
        out << indent << "swap: " << csum->swap << std::endl;
        out << indent << "start: " << csum->start  << std::endl;
        out << indent << "end: " << csum->end  << std::endl;
        if (csum->multiply_2 > 0) {
            out << indent << "mul_2: " << csum->multiply_2 << std::endl;
        }

        if (csum->end) {
            if (csum->type == IR::BFN::ChecksumMode::VERIFY && csum->csum_err)
                out << indent << "dest: " << csum->csum_err << std::endl;
            else if (csum->type == IR::BFN::ChecksumMode::RESIDUAL && csum->phv_dest)
                out << indent << "dest: " << csum->phv_dest << std::endl;
            else if (csum->type == IR::BFN::ChecksumMode::CLOT)
                out << indent << "dest: clot " << csum->clot_dest.tag << std::endl;

            if (csum->type == IR::BFN::ChecksumMode::RESIDUAL)
                out << indent << "end_pos: " << csum->end_pos  << std::endl;
        }
    }

    void outputCounter(const IR::BFN::ParserCounterPrimitive* cntr) {
        if (auto* init = cntr->to<IR::BFN::ParserCounterLoadImm>()) {
            out << indent << "counter:" << std::endl;

            indent++;

            out << indent << "imm: " << init->imm << std::endl;

            if (init->push)
                out << indent << "push: 1" << std::endl;

            if (init->update_with_top)
                out << indent << "update_with_top: 1"  << std::endl;

            indent--;
        } else if (auto* load = cntr->to<IR::BFN::ParserCounterLoadPkt>()) {
            out << indent << "counter:" << std::endl;

            BUG_CHECK(load->source->reg_slices.size() == 1,
                      "counter load allocated to more than 1 registers");

            auto reg = load->source->reg_slices[0].first;
            auto slice = load->source->reg_slices[0].second.toOrder<Endian::Little>(reg.size * 8);

            BUG_CHECK(slice.size() <= 8, "parser counter load more than 8 bits");

            indent++;
            out << indent << "src: " << reg.name;

            if (reg.size == 2)
                out << (slice.lo ? "_hi" : "_lo");

            out << std::endl;

            if (load->max)
                out << indent << "max: " << *(load->max) << std::endl;

            if (load->rotate)
                out << indent << "rotate: " << *(load->rotate) << std::endl;

            if (load->mask)
                out << indent << "mask: " << *(load->mask) << std::endl;

            if (load->add)
                out << indent << "add: " << *(load->add) << std::endl;

            if (load->push)
                out << indent << "push: 1" << std::endl;

            if (load->update_with_top)
                out << indent << "update_with_top: 1"  << std::endl;

            indent--;
        } else if (auto* inc = cntr->to<IR::BFN::ParserCounterIncrement>()) {
            out << indent << "counter: inc " << inc->value << std::endl;
        } else if (auto* inc = cntr->to<IR::BFN::ParserCounterDecrement>()) {
            out << indent << "counter: dec " << inc->value << std::endl;
        } else if (cntr->is<IR::BFN::ParserCounterPop>()) {
            out << indent << "counter: pop" << std::endl;
        }
    }

    std::ostream& out;
    const PhvInfo& phv;
    const ClotInfo& clot_info;
    indent_t indent;
};

}  // namespace

ParserAsmOutput::ParserAsmOutput(const IR::BFN::Pipe* pipe, const PhvInfo& phv,
                                 const ClotInfo& clot_info, gress_t gress)
        : phv(phv), clot_info(clot_info) {
    BUG_CHECK(pipe->thread[gress].parsers.size() != 0, "No parser?");
    for (auto parser : pipe->thread[gress].parsers) {
        auto lowered_parser = parser->to<IR::BFN::BaseLoweredParser>();
        BUG_CHECK(lowered_parser != nullptr, "Writing assembly for a non-lowered parser?");
        parsers.push_back(lowered_parser);
    }
}

std::ostream& operator<<(std::ostream& out, const ParserAsmOutput& parserOut) {
    ParserAsmSerializer serializer(out, parserOut.phv, parserOut.clot_info);
    for (auto p : parserOut.parsers) {
        LOG1("write asm for " << p);
        p->apply(serializer);
    }
    return out;
}

