#ifndef BF_P4C_PARDE_RESOLVE_COMPUTED_H_
#define BF_P4C_PARDE_RESOLVE_COMPUTED_H_

#include "ir/ir.h"
#include "bf-p4c/logging/pass_manager.h"

/**
 * Resolve all computed parser expressions if possible. These are expressions in
 * extracts or selects that reference outputs of the parser program or track
 * state in some way. Then all select on input buffer are replaced by selecting
 * on match registers, and corresponding saves are inserted.
 *
 * If you made any change to parsers after the initial run of this pass, you
 * should rerun it. Removing parts of the parser program (e.g. via dead code
 * elimination) is safe as long as the removal is otherwise correct.
 *
 * @pre The parser program contains all extracts that may be referenced by
 * computed parser expressions. This means that the bridged metadata states must
 * already have been generated, for example.
 *
 * @post If it's possible, all UnresolvedStackRef and ComputedRVal IR nodes are
 * removed from the program, and select will have match registers allocated.
 * If program errors (e.g. ambiguous references, references to
 * unextracted headers, or input buffer requirements in excess of what is
 * available on the hardware) prevent us from doing so, or if we're simply
 * incapable of handling what the program is doing, errors are reported.
 */
class ResolveComputedParserExpressions : public Logging::PassManager {
 public:
    ResolveComputedParserExpressions();
};

/**
 * Resolve header stack '.next' and '.last' expressions if possible.
 *
 * XXX(seth): This pass just constitutes a partial run of
 * ResolveComputedParserExpressions.  We shouldn't need it, but right now it
 * allows us to present essentially the same information to FieldDefUse and
 * TofinoWriteContext that they received in the past, and we need to run them to
 * determine which metadata fields are bridged, which is required for a full
 * run. That dependency will eventually be handled in a cleaner way.
 *
 * @pre The parser program may be incomplete, but contains header stack
 * extraction operations which are expected to be consistent.
 *
 * @post If it's possible, all UnresolvedStackRef IR nodes are removed from the
 * program. If program errors (e.g. ambiguous references or references to
 * unextracted headers) prevent us from doing so, or if we're simply incapable
 * of handling what the program is doing, errors are reported.
 */
class ResolveComputedHeaderStackExpressions : public Logging::PassManager {
 public:
    ResolveComputedHeaderStackExpressions();
};

#endif /* BF_P4C_PARDE_RESOLVE_COMPUTED_H_ */
