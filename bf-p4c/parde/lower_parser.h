#ifndef EXTENSIONS_BF_P4C_PARDE_LOWER_PARSER_H_
#define EXTENSIONS_BF_P4C_PARDE_LOWER_PARSER_H_

#include "ir/ir.h"
#include "logging/pass_manager.h"

class ClotInfo;
class PhvInfo;
class FieldDefUse;

/**
 * Replace the high-level parser and deparser IRs, which operate on fields and
 * field-like objects, into the low-level IRs which operate on PHV containers
 * and constants.
 *
 * XXX(seth): Right now there is no *separate* lowered deparser IR; the same
 * types of IR nodes are used for both. However, deparser primitives are still
 * simplified so that each primitive operates on a single container. This is a
 * temporary state of affairs; we'll introduce a lowered deparser IR as well.
 *
 * This is a lossy transformation; no information about fields remains in the
 * lowered parser IR in a form that's useable by the rest of the compiler. For
 * that reason, any analyses or transformations that need to take that
 * information into account need to run before this pass.
 *
 * @pre The parser and deparser IR have been simplified by
 * ResolveComputedParserExpressions and PHV allocation has completed
 * successfully.
 *
 * @post The parser and deparser IR are replaced by lowered versions.
 */
class LowerParser : public Logging::PassManager {
 public:
    explicit LowerParser(const PhvInfo& phv, ClotInfo& clot, const FieldDefUse &defuse);
};

#endif /* EXTENSIONS_BF_P4C_PARDE_LOWER_PARSER_H_ */
