#ifndef EXTENSIONS_BF_P4C_PARDE_PARSER_LOOPS_INFO_H_
#define EXTENSIONS_BF_P4C_PARDE_PARSER_LOOPS_INFO_H_

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "logging/pass_manager.h"
#include "bf-p4c/ir/gress.h"


namespace BFN {

struct ParserPragmas : public Inspector {
    static bool checkNumArgs(cstring pragma, const IR::Vector<IR::Expression>& exprs,
                             unsigned expected);

    static bool checkGress(cstring pragma, const IR::StringLiteral* gress);

    bool preorder(const IR::Annotation *annot) override;

    std::set<const IR::ParserState*> terminate_parsing;
    std::map<const IR::ParserState*, unsigned> force_shift;
    std::map<const IR::ParserState*, unsigned> max_loop_depth;

    std::set<cstring> dont_unroll;
};

/// Collect loop information in the frontend parser IR.
///   - Where are the loops?
///   - What is the depth (max iterations) of each loop?
struct ParserLoopsInfo {
    /// Infer loop depth by looking at the stack size of stack references in the
    /// state.
    struct GetMaxLoopDepth;

    ParserLoopsInfo(P4::ReferenceMap* refMap, const IR::BFN::TnaParser* parser,
            const ParserPragmas& pm);

    const ParserPragmas& parserPragmas;

    std::set<std::set<cstring>> loops;
    std::map<cstring, int> max_loop_depth;
    std::set<cstring> has_next;   // states that have stack "next" references

    const std::set<cstring>* find_loop(cstring state) const;

    /// Returns true if the state is on loop that has "next" reference.
    bool has_next_on_loop(cstring state) const;

    bool dont_unroll(cstring state) const;

    /// state is on loop that requires strided allocation
    bool need_strided_allocation(cstring state) const;
};

}  // namespace BFN

#endif  /* EXTENSIONS_BF_P4C_PARDE_PARSER_LOOPS_INFO_H_ */
