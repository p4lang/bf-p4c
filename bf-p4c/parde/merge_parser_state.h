#ifndef EXTENSIONS_BF_P4C_PARDE_MERGE_PARSER_STATE_H_
#define EXTENSIONS_BF_P4C_PARDE_MERGE_PARSER_STATE_H_

#include "ir/ir.h"
#include "ir/pass_manager.h"

/** Merge a chain of states into a large state.
 * Find the longest chain that:
 * Forall states expect for the last tail state:
 *   1. Only has one default branch.
 * Forall states incluing the last:
 *   2. Is not a merge point of multiple states.
 *   3. Does not have match resiger def/use dependency.
 */
struct MergeParserStates : public PassManager {
    MergeParserStates();
};

#endif /* EXTENSIONS_BF_P4C_PARDE_MERGE_PARSER_STATE_H_ */
