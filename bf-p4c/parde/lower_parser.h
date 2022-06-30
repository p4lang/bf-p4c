#ifndef EXTENSIONS_BF_P4C_PARDE_LOWER_PARSER_H_
#define EXTENSIONS_BF_P4C_PARDE_LOWER_PARSER_H_

#include "ir/ir.h"
#include "logging/pass_manager.h"
#include "common/utils.h"
#include "bf-p4c/parde/parser_header_sequences.h"

class ClotInfo;
class PhvInfo;
class FieldDefUse;

/**
 * \defgroup LowerParser LowerParser
 * \ingroup parde
 *
 * \brief Replace field-based parser and deparser IR with container-based parser
 * and deparser IR.
 *
 * Replace the high-level parser and deparser IRs, which operate on fields and
 * field-like objects, into the low-level IRs which operate on PHV containers
 * and constants.
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
    explicit LowerParser(const PhvInfo& phv, ClotInfo& clot, const FieldDefUse &defuse,
        const ParserHeaderSequences &parserHeaderSeqs);
};

#endif /* EXTENSIONS_BF_P4C_PARDE_LOWER_PARSER_H_ */
