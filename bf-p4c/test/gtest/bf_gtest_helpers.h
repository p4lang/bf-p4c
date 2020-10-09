#ifndef BF_GTEST_HELPERS_H_
#define BF_GTEST_HELPERS_H_

/** Helper functions and classes for making the creation of gtest easier and their running faster.
 *  See test-bf_getst_helper.cpp for example usage.
 */

#include <string>
#include <vector>
#include <iosfwd>
#include <initializer_list>
#include <regex>
#include "boost/operators.hpp"

#include "lib/compile_context.h"

// Forward declarations.
class Visitor;
struct Visitor_Context;
namespace IR {
class P4Program;
}  // namespace IR

namespace Test {

namespace Match {

/** The Match namespace brings together low level generic helper functionality.
 *  They play a supportive role to 'TestCode' and others to follow.
 *  End user tests should not need to call 'Match::function' directly - work in progress!
 */

std::string trimWhiteSpace(std::string str);

/// Annotations with nested parentheses are not supported e.g. "@anot(func())"
std::string trimAnnotations(const std::string& str);

/// Helper flags for use by other interfaces.
enum Flag {Raw = 0, TrimWhiteSpace = 1, TrimAnnotations = 2};
/// Flags may be ORed together.
inline Flag operator|(Flag a, Flag b) {
    return static_cast<Flag>(static_cast<int>(a) | static_cast<int>(b));
}

/** 'convet_to_regex()' allows user to write plain string embedded with chunks of regex.
 *  See std::ECMAScript for details on regex format.
 *  You do not have to escape your regex chunks, but it makes things much cleaner!
 *  Regex chucks placed within `` (back quotes) are not converted, everything else is.
 *  The result is a string suitable for std::regex().
 *  If you require a back quote "`", use its ASCII escape code "\x60".
 *  N.B. The usual escape characters are required for a string literal e.g. '\\' for '\'.
 *           "$slice`(\\d+)`[7:0] ++ $slice`\\1`[7:0]"
 *  or you can use Raw string literals
 *           R"($slice`(\d+)`[7:0] ++ $slice`\1`[7:0])"
 *  The returned string will be an escaped regex literal
 *           R"(\$slice(\d+)\[7:0\] \+\+ \$slice\1\[7:0\])"
 *  In the example above:
 *       `(\d+)` will match 1 or more digits.
 *       `\1` will match what was actually matched by the first regex match.
 *  Thus will match code such as:
 *           $slice42[7:0] ++ $slice42[7:0]
*/
std::string convet_to_regex(const std::string& expr);

/** 'match_basic()' compares 'expr' with 'str', staring at 'str[pos]'.
 *  The search will not include the 'str[n_pos]'character.
 *  Returns either the position in the searched string the match got to. N.B. this may
 *  be (one) beyond the end of 'str'!
 *  Or 'failed'.
 */
constexpr size_t failed = std::string::npos;
size_t match_basic(const std::string& expr,
                   const std::string& str, size_t pos = 0, size_t n_pos = std::string::npos);


/** A 'CheckList' is a series of expressions to match.
 *  The expressions may optionally contain regex expressions - see 'convet_to_regex()'.
 *  When 'TrimWhiteSpace' is used, entries may be separated by zero or more white-space.
 */
typedef std::vector<std::string> CheckList;

/// 'Result' is used to report how a match has proceeded.
struct Result : boost::equality_comparable<Result> {
    bool success;       ///< true if the 'CheckList' was completed.
    size_t pos;         ///< the position in 'str' the match was successful to.
                        ///< N.B. 'pos' may be (one) beyond the end of 'str'!
    size_t count;       ///< tHe number of 'CheckList' item successfully matched.
    Result(bool success, size_t pos, size_t count) :
            success(success), pos(pos), count(count) {}
    friend bool operator==(const Result& l, const Result& r) {
        return l.success == r.success && l.pos == r.pos && l.count == r.count;
    }
};

/** 'match()' is similar to 'match_basic()'.
 *  However it allows a match to be made up of a 'Checklist' of expressions.
 *  It calls 'convet_to_regex()' on the expressions, allowing regex expressions to be used.
 *  See comments regarding 'convet_to_regex()' for more details.
 */
Result match(const CheckList& exprs,
             const std::string& str, size_t pos = 0, size_t n_pos = std::string::npos,
             Flag flag = Raw);

// 'ends' can be any two differing characters e.g. "AZ".
inline const std::string  BraceEnds() {return "{}";}
inline const std::string  ParenEnds() {return "()";}
inline const std::string  SquareEnds() {return "[]";}
inline const std::string  AngleEnds() {return "<>";}

/// 'find_next_end' finds the closing end, where 'pos' beyond the opening character.
size_t find_next_end(const std::string& str, size_t pos, const std::string& ends);

// 'find_next_block' finds the opening & closing ends, where 'pos' is before the opening character.
std::pair<size_t, size_t> find_next_block(const std::string& str, size_t pos,
                                          const std::string& ends);
/// 'get_ends' returns the appropriate ends pair.
///  viz 'BraceEnds', 'ParenEnds', 'SquareEnds', 'AngleEnds' or an empty string.
std::string get_ends(char opening);

}  // namespace Match


class TestCode {
    // AutoCompileContext adds to the stack a new compilation context for the test to run in.
    AutoCompileContext context;
    const IR::P4Program* program = nullptr;     // N.B. The sharing of this object is not clear!
    Match::Flag flag = Match::TrimWhiteSpace;   // N.B. common to match() & get_block().
    std::regex marker;      // Optional search string for the block we are interested in.
    std::string ends;       // How our optional block starts and ends.

 public:
    /// Useful strings.
    static std::string any_to_brace() {return "`([^\\{]*\\{)`";}  // viz ".*{"
    static std::string empty_state() {return "state start {transition accept;}";}
    static std::string empty_appy() {return "apply {}";}

    /** 'tofino_shell' is a tofino program, requiring insertions for:
     *   %0%     Defines for 'struct headers_t' and 'struct local_metadata_t'.
     *   %1%     A parser ingress_parser block e.g. 'empty_state()'.
     *   %2%     A control ingress_control block e.g. 'empty_appy()'.
     *   %3%     A control ingress_deparser block e.g. 'empty_appy()'.
     *  The 'tofino_shell_*_marker's identify those blocks within the 'tofino_shell' string.
     */
    static std::string tofino_shell();  // See cpp file for the code.
    static std::string tofino_shell_parser_marker() {
        return "parser ingress_parser" + any_to_brace();
    }
    static std::string tofino_shell_control_marker() {
        return"control ingress_control" + any_to_brace();
    }
    static std::string tofino_shell_deparser_marker() {
        return"control ingress_deparser" + any_to_brace();
    }
    // TODO would a smaller test program (as used in test_bf_gtest_helpers.cpp) be of general value?


    /// The header file to be used when building the 'code'.
    enum class Hdr {None, Tofino1arch, Tofino2arch, Tofino3arch, V1model_2018, V1model_2020};

    /** See test_bf_gtest_helpers.cpp for example usage of 'TestCode'
     *  We state the 'header' we want and our 'code', with optional %N% insertion points.
     *  The %N% entires are repalced by the 'insertion' elements e.g.
     *     TestCode(Hdr::None,                                      // No header required.
     *              R"      control TestIngress<H, M>(inout H hdr, inout M meta);
     *                      package TestPackage<H, M>(TestIngress<H, M> ig);
     *                      %0%     // Definitions.
     *                      control ti(inout Hd headers, inout Md meta){
     *                          %1% // Apply block.
     *                      }
     *                      TestPackage(ti()) main;)",              // Our program.
     *              {"struct Hd{}; struct Md{};", "apply{}"},       // replaces %0% & %1%.
     *              "control ti"+any_to_brace(),                    // The start of the block.
     *              {"-S"});                                        // Commandline options.
     */
    TestCode(Hdr header,
             std::string code,
             const std::initializer_list<std::string>& insertion = {},  ///< Default: none.
             const std::string& blockMarker = "",                       ///< Default: all code.
             const std::initializer_list<std::string>& options = {});   ///< Default: tna & P4_16.

    /// Sets the flags to be used by other member functions.
    void flags(Match::Flag f) { flag = f; }

    /// Runs the pass over the control block.
    bool apply_pass(Visitor* pass, const Visitor_Context* context = nullptr);

    /// Runs a preconstructed pass over the control block.
    enum class Pass {FullFrontend, MinimumFrontend, MinimumBackend};
    bool apply_pass(Pass pass);  // Copy the implemenation & edit if not what you want!

    /// Calls Match::match() on the code identified by 'blockMarker'.
    Match::Result match(const Match::CheckList& exprs) const;

    /// Read the curret code identified by 'blockMarker'.
    std::string get_block(size_t pos = 0) const;

    friend std::ostream &operator<<(std::ostream &out, const TestCode &cb) {
        return out << cb.get_block();
    }
};

}  // namespace Test

#endif  /* BF_GTEST_HELPERS_H_ */
