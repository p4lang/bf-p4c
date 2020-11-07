
#include "bf_gtest_helpers.h"

#include <climits>
#include <regex>
#include <exception>
#include <sstream>
#include <utility>
#include "boost/algorithm/string/replace.hpp"
#include "boost/algorithm/string/trim_all.hpp"

#include "ir/ir.h"
#include "p4headers.h"
#include "lib/exceptions.h"
#include "lib/sourceCodeBuilder.h"
#include "bf-p4c/arch/bridge.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/phv/create_thread_local_instances.h"
#include "frontends/parsers/parserDriver.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/toP4/toP4.h"
#include "frontends/p4/frontend.h"    // Used by run_p4c_frontend_passes

// Frontend Passes
#include "frontends/p4/actionsInlining.h"
#include "frontends/p4/createBuiltins.h"
#include "frontends/p4/defaultArguments.h"
#include "frontends/p4/deprecated.h"
#include "frontends/p4/directCalls.h"
#include "frontends/p4/dontcareArgs.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4/functionsInlining.h"
#include "frontends/p4/hierarchicalNames.h"
#include "frontends/p4/inlining.h"
#include "frontends/p4/localizeActions.h"
#include "frontends/p4/moveConstructors.h"
#include "frontends/p4/moveDeclarations.h"
#include "frontends/p4/parserControlFlow.h"
#include "frontends/p4/removeReturns.h"
#include "frontends/p4/resetHeaders.h"
#include "frontends/p4/setHeaders.h"
#include "frontends/p4/sideEffects.h"
#include "frontends/p4/simplify.h"
#include "frontends/p4/simplifyDefUse.h"
#include "frontends/p4/simplifyParsers.h"
#include "frontends/p4/specialize.h"
#include "frontends/p4/specializeGenericFunctions.h"
#include "frontends/p4/strengthReduction.h"
#include "frontends/p4/structInitializers.h"
#include "frontends/p4/switchAddDefault.h"
#include "frontends/p4/tableKeyNames.h"
#include "frontends/p4/typeChecking/bindVariables.h"
#include "frontends/p4/uniqueNames.h"
#include "frontends/p4/unusedDeclarations.h"
#include "frontends/p4/uselessCasts.h"

#include "bf-p4c/midend.h"

#include "bf-p4c/backend.h"

namespace Test {

namespace Match {
std::string trimWhiteSpace(std::string str) {
    boost::algorithm::trim_fill(str, " ");
    return str;
}

std::string trimAnnotations(const std::string& str) {
    // Are nested parentheses legal? If they are count them.
    auto nestedParen = R"(@\w+\([^\)]*\()";
    if (std::regex_search(str, std::regex(nestedParen)))
        throw std::invalid_argument("Annotation with nested parentheses are not supported");
    auto annotation = R"(@\w+(\([^\)]*\))?)";
    return std::regex_replace(str, std::regex(annotation), "");
}

std::string convet_to_regex(const std::string& expr) {
    auto exprLen = expr.length();
    auto stepOverChar = [exprLen](size_t pos) {
        ++pos;
        BUG_CHECK(pos <= exprLen, "pos more than +1 past the end of a string");
        return pos;
    };

    constexpr auto specialChars = "`^$.|?*+(){[\\";  // Backquote or regex special.
    std::string regex;
    size_t pos = 0;
    for (;;) {
        auto p = expr.find_first_of(specialChars, pos);
        regex += expr.substr(pos, p - pos);  // Copy everything up to p.
        if (p == std::string::npos)
            return regex;
        if (expr[p] == '`') {
            pos = stepOverChar(p);
            p = expr.find_first_of('`', pos);
            // If range contains a "\x60", the regex parser will escape it.
            regex += expr.substr(pos, p - pos);  // Copy everything up to p.
            if (p == std::string::npos)
                throw std::invalid_argument("Mismatch back quote");
            pos = stepOverChar(p);
        } else if (expr.compare(p, 4, "\\x60") == 0) {
            // We don't want to add a second '\'. Leave it for the regex parser.
            regex += expr[p];   // The "x60" will be copied as normal.
            pos = stepOverChar(p);
        } else {
            // A regex special char that needs escaping.
            regex += '\\';
            regex += expr[p];
            pos = stepOverChar(p);
        }
    }
}

size_t match_basic(const std::string& expr,
                   const std::string& str, const size_t pos, const size_t n_pos) {
    auto strLen = str.length();
    // std::compare does not mind if n_pos > strLen.
    if (pos > strLen || pos > n_pos)
        return failed;  // Handle bad arguments.
    auto exprLen = expr.length();
    auto next_pos = pos + exprLen;
    if (next_pos > n_pos)
        return failed;  // Not enough characters to match against.
    if (str.compare(pos, exprLen, expr) != 0)
        return failed;  // Not an exact match.
    return next_pos;  // Maybe one beyond the end of 'str'.
}

Result match(const CheckList& exprs,
             const std::string& str, size_t pos, size_t n_pos, Flag flag) {
    auto strLen = str.length();
    if (n_pos > strLen)
        n_pos = strLen;
    if (pos > strLen || pos > n_pos)
        return Result{.success = false, .pos = failed, .count = 0};  // Handle bad 'pos'.

    auto from = str.cbegin() + pos;
    auto to = str.cbegin() + n_pos;

    std::string regex;
    CheckList regex_exprs;  // Keep a record of conversions.
    std::smatch sm;

    // First attempt the whole CheckList.
    for (const auto& expr : exprs) {
        // Trim single space if present & required.
        std::string e;
        if (flag & TrimWhiteSpace)
            e += "` ?`";
        e += expr;
        regex_exprs.emplace_back(convet_to_regex(e));
        regex += regex_exprs.back();
    }
    if (std::regex_search(from, to, sm, std::regex(regex))
        && !sm.prefix().length())
        return Result{.success = true, .pos = pos+sm[0].length(), .count = exprs.size()};

    // Re-run to find out where we failed. Linear search is good enough.
    Result res = {.success = false, .pos = pos, .count = 0};
    regex = "";
    for (const auto& r_e : regex_exprs) {
        regex += r_e;  // Reuse the saved 'convet_to_regex()' value.
        if (!std::regex_search(from, to, sm, std::regex(regex)) ||
            sm.prefix().length())  // Once we have a prefix, it wont go away.
            return res;     // Found the fail point.
        ++res.count;
        res.pos = pos + sm[0].length();
    }
    BUG_CHECK(0, "Unreachable code");
}

size_t find_next_end(const std::string& blk, size_t pos, const std::string& ends) {
    if (ends.length() != 2 || ends[0] == ends[1])
        throw std::invalid_argument("Bad ends string");
    int count = 1;
    pos = blk.find_first_of(ends, pos);
    while (pos != std::string::npos) {
        if (blk[pos] == ends[0])
            ++count;
        else if (blk[pos] == ends[1])
            if (--count == 0)
                return pos;
        pos = blk.find_first_of(ends, pos + 1);
    }
    return pos;
}

std::pair<size_t, size_t> find_next_block(const std::string& blk, size_t pos,
                                          const std::string& ends) {
    if (ends.length() != 2 || ends[0] == ends[1])
        throw std::invalid_argument("Bad ends string");
    pos = blk.find_first_of(ends[0], pos);
    if (pos == std::string::npos)
        return std::make_pair(pos, pos);
    return std::make_pair(pos, find_next_end(blk, pos + 1, ends));
}

std::string get_ends(char opening) {
    switch (opening) {
    case '{':
        return BraceEnds();
    case '(':
        return ParenEnds();
    case '[':
        return SquareEnds();
    case '<':
        return AngleEnds();
    default:
        return "";
    }
}


}  // namespace Match


namespace {
char marker_last_char(const std::string& blockMarker) {
    // Find the actual last character of marker e.g. the '{' of the any_to_open_brace.
    size_t len = blockMarker.length();
    while (len > 1 && blockMarker[len - 1] == '`') {
        --len;  // Remove closing `.
        // Check the contents of the back quoted regex.
        if (blockMarker[len - 1] == '`') {
            --len;  // Remove opening `.
        } else {
            // Remove sub-pattern markers etc.
            int count = 0;
            while (len > 1 &&
                   blockMarker[len - 2] != '\\' &&   // not escaped.
                   (blockMarker[len - 1] == '(' || blockMarker[len - 1] == ')')) {
                count += (blockMarker[len - 1] == ')')? 1 : -1;
                if (count < 0)
                    throw std::invalid_argument("Invalid blockMarker parentheses");
                --len;  // Remove sub-pattern.
            }
            if (!count && blockMarker[len - 1] != '`') {
                --len;  // Remove opening `. It was an empty regex.
            } else if (len > 1 &&
                       blockMarker[len - 2] != '\\' &&   // not escaped.
                       blockMarker.find_first_of("^$.|?*+{}[]\\", len-1) == len-1) {
                // Ends with a special regex char.
                throw std::invalid_argument("marker_last_char must be a literal");
            } else {
                break;  // Found!
            }
        }
    }
    if (len)
        return blockMarker[len - 1];
    return 0;
}

std::string TofinoMin() {
    return R"(
    typedef bit<9>  PortId_t;
    typedef bit<16> MulticastGroupId_t;
    typedef bit<5>  QueueId_t;
    typedef bit<3>  MirrorType_t;
    extern packet_in {
        void extract<T>(out T hdr);
        void extract<T>(out T variableSizeHeader, in bit<32> variableFieldSizeInBits);
        T lookahead<T>();
        void advance(in bit<32> sizeInBits);
        bit<32> length();
    }
    extern packet_out {
        void emit<T>(in T hdr);
    }
    header ingress_intrinsic_metadata_t {
        bit<1> resubmit_flag;
        bit<1> _pad1;
        bit<2> packet_version;
        bit<3> _pad2;
        PortId_t ingress_port;
        bit<48> ingress_mac_tstamp;
    }
    struct ingress_intrinsic_metadata_for_tm_t {
        PortId_t ucast_egress_port;
        bit<1> bypass_egress;
        bit<1> deflect_on_drop;
        bit<3> ingress_cos;
        QueueId_t qid;
        bit<3> icos_for_copy_to_cpu;
        bit<1> copy_to_cpu;
        bit<2> packet_color;
        bit<1> disable_ucast_cutthru;
        bit<1> enable_mcast_cutthru;
        MulticastGroupId_t mcast_grp_a;
        MulticastGroupId_t mcast_grp_b;
        bit<13> level1_mcast_hash;
        bit<13> level2_mcast_hash;
        bit<16> level1_exclusion_id;
        bit<9> level2_exclusion_id;
        bit<16> rid;
    }
    struct ingress_intrinsic_metadata_from_parser_t {
        bit<48> global_tstamp;
        bit<32> global_ver;
        bit<16> parser_err;
    }
    header egress_intrinsic_metadata_t {
        bit<7> _pad0;
        PortId_t egress_port;
        bit<5> _pad1;
        bit<19> enq_qdepth;
        bit<6> _pad2;
        bit<2> enq_congest_stat;
        bit<14> _pad3;
        bit<18> enq_tstamp;
        bit<5> _pad4;
        bit<19> deq_qdepth;
        bit<6> _pad5;
        bit<2> deq_congest_stat;
        bit<8> app_pool_congest_stat;
        bit<14> _pad6;
        bit<18> deq_timedelta;
        bit<16> egress_rid;
        bit<7> _pad7;
        bit<1> egress_rid_first;
        bit<3> _pad8;
        QueueId_t egress_qid;
        bit<5> _pad9;
        bit<3> egress_cos;
        bit<7> _pad10;
        bit<1> deflection_flag;
        bit<16> pkt_length;
    }
    struct egress_intrinsic_metadata_from_parser_t {
        bit<48> global_tstamp;
        bit<32> global_ver;
        bit<16> parser_err;
    }
    struct ingress_intrinsic_metadata_for_deparser_t {
        bit<3> drop_ctl;
        bit<3> digest_type;
        bit<3> resubmit_type;
        MirrorType_t mirror_type;
    }
    struct egress_intrinsic_metadata_for_deparser_t {
        bit<3> drop_ctl;
        MirrorType_t mirror_type;
        bit<1> coalesce_flush;
        bit<7> coalesce_length;
    }
    struct egress_intrinsic_metadata_for_output_port_t {
        bit<1> capture_tstamp_on_tx;
        bit<1> update_delay_on_tx;
        bit<1> force_tx_error;
    }
    parser IngressParserT<H, M>(
        packet_in pkt,
        out H hdr,
        out M ig_md,
        @optional out ingress_intrinsic_metadata_t ig_intr_md,
        @optional out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        @optional out ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr);
    parser EgressParserT<H, M>(
        packet_in pkt,
        out H hdr,
        out M eg_md,
        @optional out egress_intrinsic_metadata_t eg_intr_md,
        @optional out egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr);
    control IngressT<H, M>(
        inout H hdr,
        inout M ig_md,
        @optional in ingress_intrinsic_metadata_t ig_intr_md,
        @optional in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
        @optional inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        @optional inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm);
    control EgressT<H, M>(
        inout H hdr,
        inout M eg_md,
        @optional in egress_intrinsic_metadata_t eg_intr_md,
        @optional in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        @optional inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        @optional inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport);
    control IngressDeparserT<H, M>(
        packet_out pkt,
        inout H hdr,
        in M metadata,
        @optional in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        @optional in ingress_intrinsic_metadata_t ig_intr_md);
    control EgressDeparserT<H, M>(
        packet_out pkt,
        inout H hdr,
        in M metadata,
        @optional in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        @optional in egress_intrinsic_metadata_t eg_intr_md,
        @optional in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr);
    package Pipeline<IH, IM, EH, EM>(
        IngressParserT<IH, IM> ingress_parser,
        IngressT<IH, IM> ingress,
        IngressDeparserT<IH, IM> ingress_deparser,
        EgressParserT<EH, EM> egress_parser,
        EgressT<EH, EM> egress,
        EgressDeparserT<EH, EM> egress_deparser);
    package Switch<IH0, IM0, EH0, EM0>(
        Pipeline<IH0, IM0, EH0, EM0> pipe);
    )";
}

}  // namespace

TestCode::TestCode(Hdr header, std::string code,
                   const std::initializer_list<std::string>& insertion,
                   const std::string& blockMarker,
                   const std::initializer_list<std::string>& options) :
                   context(new BFNContext()) {
    // Set up default options.
    auto& o = BackendOptions();
    o.langVersion = CompilerOptions::FrontendVersion::P4_16;
    switch (header) {
        default:
            o.target = "tofino";
            o.arch = "tna";
            break;
        case Hdr::Tofino2arch:
            o.target = "tofino2";
            o.arch = "t2na";
           break;
        case Hdr::Tofino3arch:
            o.target = "tofino3";
            o.arch = "t3na";
            break;
    }

    std::vector<char*> argv;
    // We must have at least one command-line option viz the name.
    static const char* testcode = "TestCode";
    argv.push_back(const_cast<char*>(testcode));
    // Add the input options.
    for (const auto& arg : options)
        argv.push_back(const_cast<char*>(arg.data()));
    argv.push_back(nullptr);
    o.process(argv.size() - 1, argv.data());
    Device::init(o.target);

    std::stringstream source;
    switch (header) {
        case Hdr::None:
            break;
        case Hdr::TofinoMin:
            source << TofinoMin();
            break;
        case Hdr::Tofino1arch:
            source << p4headers().tofino1arch_p4;
            break;
        case Hdr::Tofino2arch:
            source << p4headers().tofino2arch_p4;
            break;
        case Hdr::Tofino3arch:
            source << p4headers().tofino3arch_p4;
            break;
        case Hdr::V1model_2018:
            source << p4headers().v1model_2018_p4;
            break;
        case Hdr::V1model_2020:
            source << p4headers().v1model_2020_p4;
            break;
    }

    // Replace embedded tokens.
    int i = 0;
    for (auto insert : insertion) {
        std::ostringstream oss;
        oss << '%' << i++ << '%';
        boost::replace_all(code, oss.str(), insert);
    }
    source << code;

    program = P4::P4ParserDriver::parse(source, testcode);
    if (::errorCount() || !program)
        throw std::invalid_argument("TestCode built a bad program.");

    if (!blockMarker.empty()) {
        marker = std::regex(Match::convet_to_regex(blockMarker));
        ends = Match::get_ends(marker_last_char(blockMarker));
        if (ends.empty())
            throw std::invalid_argument("blockMarker's last char is not a Match::get_ends()");
    }
}

std::string TestCode::min_control_shell() {return R"(
    %0%                                                 // Defines 'struct Headers'
    control TestIngress<H>(inout H hdr);
    package TestPackage<H>(TestIngress<H> ig);
    control testingress(inout Headers headers) {%1%}    // The control block
    TestPackage(testingress()) main;)";}


std::string TestCode::tofino_shell() {return R"(
    %0% // Define struct headers_t{}; struct local_metadata_t{}
    parser ingress_parser(packet_in packet, out headers_t hdr,
                          out local_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md)
        {%1%}
    control ingress_control(inout headers_t hdr, inout local_metadata_t ig_md,
                            in ingress_intrinsic_metadata_t ig_intr_md,
                            in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
        {%2%}
    control ingress_deparser(packet_out packet, inout headers_t hdr, in local_metadata_t ig_md,
                             in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        {%3%}
    parser egress_parser(packet_in packet, out headers_t hdr, out local_metadata_t eg_md,
                         out egress_intrinsic_metadata_t eg_intr_md)
        {state start {transition accept;}}
    control egress_control(inout headers_t hdr, inout local_metadata_t eg_md,
                           in egress_intrinsic_metadata_t eg_intr_md,
                           in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                           inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                           inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
        {apply{}}
    control egress_deparser(packet_out packet, inout headers_t hdr, in local_metadata_t eg_md,
                            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
        {apply{}}
    Pipeline(ingress_parser(),
             ingress_control(),
             ingress_deparser(),
             egress_parser(),
             egress_control(),
             egress_deparser()) pipeline;
    Switch(pipeline) main;)";}

namespace {
Visitor* minimum_frontend_passes(bool skip_side_effect_ordering) {
    // TODO Can the number of passes be reduced further  - to reduce the processing time?
    auto refMap = new P4::ReferenceMap();
    auto typeMap = new P4::TypeMap();
    auto evaluator = new P4::EvaluatorPass(refMap, typeMap);
    return new PassManager({
        // Synthesize some built-in constructs
        new P4::CreateBuiltins(),
        new P4::ResolveReferences(refMap, true),  // check shadowing
        // First pass of constant folding, before types are known --
        // may be needed to compute types.
        new P4::ConstantFolding(refMap, nullptr),
        // Desugars direct parser and control applications
        // into instantiations followed by application
        new P4::InstantiateDirectCalls(refMap),
        new P4::ResolveReferences(refMap),  // check shadowing
        // Type checking and type inference.  Also inserts
        // explicit casts where implicit casts exist.
        new P4::TypeInference(refMap, typeMap, false),  // insert casts
        new P4::BindTypeVariables(refMap, typeMap),
        new P4::DefaultArguments(refMap, typeMap),  // add default argument values to parameters
        new P4::ResolveReferences(refMap),
        new P4::TypeInference(refMap, typeMap, false),  // more casts may be needed
        new P4::RemoveParserControlFlow(refMap, typeMap),
        new P4::StructInitializers(refMap, typeMap),
        new P4::SpecializeGenericFunctions(refMap, typeMap),
        new P4::TableKeyNames(refMap, typeMap),
        new PassRepeated({
            new P4::ConstantFolding(refMap, typeMap),
            new P4::StrengthReduction(refMap, typeMap),
            new P4::UselessCasts(refMap, typeMap)
        }),
        new P4::SimplifyControlFlow(refMap, typeMap),
        new P4::SwitchAddDefault,
        new P4::RemoveAllUnusedDeclarations(refMap, true),
        new P4::SimplifyParsers(refMap),
        new P4::ResetHeaders(refMap, typeMap),
        new P4::UniqueNames(refMap),  // Give each local declaration a unique internal name
        new P4::MoveDeclarations(),  // Move all local declarations to the beginning
        new P4::MoveInitializers(refMap),
        new P4::SideEffectOrdering(refMap, typeMap, skip_side_effect_ordering),
        new P4::SimplifyControlFlow(refMap, typeMap),
        new P4::MoveDeclarations(),  // Move all local declarations to the beginning
        new P4::SimplifyDefUse(refMap, typeMap),
        new P4::UniqueParameters(refMap, typeMap),
        new P4::SimplifyControlFlow(refMap, typeMap),
        new P4::SpecializeAll(refMap, typeMap),
        new P4::RemoveParserControlFlow(refMap, typeMap),
        new P4::RemoveReturns(refMap),
        new P4::RemoveDontcareArgs(refMap, typeMap),
        new P4::MoveConstructors(refMap),
        new P4::RemoveAllUnusedDeclarations(refMap),
        new P4::ClearTypeMap(typeMap),
        evaluator,
        new P4::Inline(refMap, typeMap, evaluator),
        new P4::InlineActions(refMap, typeMap),
        new P4::InlineFunctions(refMap, typeMap),
        new P4::SetHeaders(refMap, typeMap),
        // Check for constants only after inlining
        new P4::SimplifyControlFlow(refMap, typeMap),
        new P4::RemoveParserControlFlow(refMap, typeMap),
        new P4::UniqueNames(refMap),
        new P4::LocalizeAllActions(refMap),
        new P4::UniqueNames(refMap),  // needed again after inlining
        new P4::UniqueParameters(refMap, typeMap),
        new P4::SimplifyControlFlow(refMap, typeMap),
        new P4::HierarchicalNames(),
    });
}

Visitor* minimum_backend_passes(const CompilerOptions& options) {
    (void) options;
    return new PassManager({
#if 0
    // TODO This is taken from bf-p4c/test/gtest/phv_core_alloc.cpp
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        new InstructionSelection(options, phv),
        &uses,
        &pragmas,
        new MutexOverlay(phv, pragmas),
        &field_to_parser_states,
        &parser_critical_path,
        new FindDependencyGraph(phv, deps, &options, "", "Before PHV allocation"),
        new MemoizeMinStage(phv, deps),
        &defuse,
        &table_mutex,
        &action_mutex,
        &pack_conflicts,
        &action_constraints,
        new TablePhvConstraints(phv, action_constraints, pack_conflicts),
        new PardePhvConstraints(phv, pragmas.pa_container_sizes()),
        &critical_path_clusters,
        &dom_tree,
        &table_actions_map,
        &meta_live_range,
        (Device::phvSpec().hasContainerKind(PHV::Kind::dark) &&
         !options.disable_dark_allocation)
            ? &dark_live_range : nullptr,
        &live_range_shrinking,
        &clustering,
        &table_ids,
        &strided_headers,
        &parser_info
#endif
    });
}

}  // namespace

bool TestCode::apply_pass(Visitor& pass, const Visitor_Context* context) {
    auto before = ::errorCount();
    if (pipe) {
        pipe = pipe->apply(pass, context);
        if (!pipe)
            std::cerr << "apply_pass to pipe failed\n";
    } else {
        program = program->apply(pass, context);
        if (!program)
            std::cerr << "apply_pass to program failed\n";
    }
    return ::errorCount() == before;
}


bool TestCode::apply_pass(Pass pass) {
    constexpr bool skip_side_effect_ordering = true;
    auto options = BackendOptions();
    switch (pass) {
        case Pass::FullFrontend: {
            pipe = nullptr;
            auto before = ::errorCount();
            // The 'frontendPasses' are encapsulated in a run method, so we have to call that.
            program = P4::FrontEnd().run(options, program, skip_side_effect_ordering);
            return ::errorCount() == before;
        }

        case Pass::FullMidend: {
            pipe = nullptr;
            BFN::MidEnd midend{options};
            return apply_pass(midend);
        }

        case Pass::ConverterToBackend: {
            pipe = nullptr;
            ordered_map<cstring, const IR::Type_StructLike*> empty{};
            BFN::SubstitutePackedHeaders extractPipes{options, empty};
            if (!apply_pass(extractPipes) || !extractPipes.pipe.size())
                return false;
            pipe = extractPipes.pipe[0];
            return pipe != nullptr;
        }

        case Pass::FullBackend: {
            if (!pipe) throw std::invalid_argument("ConverterToBackend must be run first");
            static int pipe_id = INT_MAX;  // TableSummary requires a unique pipe ID.
            BFN::Backend backend{options, pipe_id--};
            return apply_pass(backend);
        }

        case Pass::ThreadLocalInstances: {
            if (!pipe) throw std::invalid_argument("ConverterToBackend must be run first");
            CreateThreadLocalInstances ctli;
            return apply_pass(ctli);
        }

        case Pass::MinimumFrontend:
            if (pipe) pipe = nullptr;
            return apply_pass(minimum_frontend_passes(skip_side_effect_ordering));

        case Pass::MinimumBackend:
            if (!pipe) throw std::invalid_argument("ConverterToBackend must be run first");
            return apply_pass(minimum_backend_passes(options));
    }
    return false;
}

Match::Result TestCode::match(const Match::CheckList& exprs) const {
    return Match::match(exprs, get_block(), 0, std::string::npos, flag);
}

std::string TestCode::get_block(size_t pos) const {
    // Fetch the entire program.
    Util::SourceCodeBuilder builder;
    auto before = ::errorCount();
    auto pass = P4::ToP4(builder, false);
    program->apply(pass);
    if (::errorCount() != before)
        return "Invalid Program";
    auto blk = builder.toString();

    // Trim out the block - the block may move location.
    std::smatch sm;
    if (!ends.empty() && std::regex_search(blk, sm, marker)) {
        size_t start = sm.prefix().length() + sm[0].length();
        size_t end = Match::find_next_end(blk, start, ends);
        if (end != std::string::npos)
            --end;
        blk = blk.substr(start, end-start);
    }

    // Apply any requested options.
    if (flag & Match::TrimAnnotations)
        blk = Match::trimAnnotations(blk);
    if (flag & Match::TrimWhiteSpace)
        blk = Match::trimWhiteSpace(blk);

    return blk.substr(pos);
}

}  // namespace Test
