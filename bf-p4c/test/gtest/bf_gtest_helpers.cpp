
#include "bf_gtest_helpers.h"

#include <regex>
#include <exception>
#include <sstream>
#include <utility>
#include "boost/algorithm/string/replace.hpp"
#include "boost/algorithm/string/trim_all.hpp"

#include "frontends/p4/toP4/toP4.h"
#include "lib/exceptions.h"
#include "lib/sourceCodeBuilder.h"
#include "frontends/parsers/parserDriver.h"
#include "p4headers.h"

namespace Test {

namespace Match {
std::string trimWhiteSpace(std::string str) {
    boost::algorithm::trim_fill(str, " ");
    return str;
}

std::string trimAnnotations(const std::string& str) {
    const char* annotation = R"(@\w+(\([^\)]*?\))?)";
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
    BUG_CHECK(ends.length() >= 2, "Bad ends string");
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
    BUG_CHECK(ends.length() >= 2, "Bad ends string");
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

TestCode::TestCode(Match::P4Include header, std::string code,
                   const std::initializer_list<std::string>& replacement,
                   const std::string& blockMarker) :
                   autoGTestContext(new P4CContextWithOptions<CompilerOptions>(
                        P4CContextWithOptions<CompilerOptions>::get())) {
    std::stringstream source;
    switch (header) {
        case Match::P4Include::None:
            break;
        case Match::P4Include::Tofino1arch:
            source << p4headers().tofino1_p4;
            break;
        case Match::P4Include::Tofino2arch:
            source << p4headers().tofino2_p4;
            break;
        case Match::P4Include::Tofino3arch:
            source << p4headers().tofino3_p4;
            break;
    }

    // Replace embedded tokens.
    int i = 0;
    for (auto rep : replacement) {
        std::ostringstream oss;
        oss << '%' << i++ << '%';
        boost::replace_all(code, oss.str(), rep);
    }
    source << code;

    program = P4::P4ParserDriver::parse(source, "test program");
    if (::errorCount() || !program)
        throw std::invalid_argument("TestCode built a bad program.");

    if (!blockMarker.empty()) {
        marker = std::regex(Match::convet_to_regex(blockMarker));
        ends = Match::get_ends(marker_end_char(blockMarker));
        if (ends.empty())
            throw std::invalid_argument("blockMarker's last char is not a Match::get_ends()");
    }
}

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

char TestCode::marker_end_char(const std::string& blockMarker) {
    // Find the actual last character of marker viz the '{' in any_to_open_brace.
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
                throw std::invalid_argument("marker_end_char must be a literal");
            } else {
                break;  // Found!
            }
        }
    }
    if (len)
        return blockMarker[len - 1];
    return 0;
}

bool TestCode::apply_pass(Visitor* pass, const Visitor_Context* context) {
    auto before = ::errorCount();
    program = program->apply(*pass, context);
    return ::errorCount() == before;
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
