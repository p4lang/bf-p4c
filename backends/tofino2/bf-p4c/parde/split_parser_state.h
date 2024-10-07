#ifndef EXTENSIONS_BF_P4C_PARDE_SPLIT_PARSER_STATE_H_
#define EXTENSIONS_BF_P4C_PARDE_SPLIT_PARSER_STATE_H_

#include "parde_visitor.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/ir/bitrange.h"

/**
 * @ingroup LowerParserIR
 * @brief Splits parser states into multiple states to account for HW resource constraints
 *        of a single parser state.
 *
 * After PHV allocation, we have the concrete view of what size of
 * PHV container each field is allocated in. We can then finalize
 * the parser IR. Specifically, parser states may need to split into
 * multiple states to account for various resource contraints of
 * a single parser state, these are
 * 
 *    - Input buffer (can only see 32 bytes of packet data in a state)
 *    - Extractors for PHV container
 *    - Constant extracts
 *    - Parser counter 
 *    - Checksum calculation
 *    - CLOT issurance (JBAY)
 *    - Stage rules (FTR)
 */
struct SplitParserState : public PassManager {
    SplitParserState(const PhvInfo &phv, ClotInfo &clot, const CollectParserInfo &parser_info);
};

#endif /* EXTENSIONS_BF_P4C_PARDE_SPLIT_PARSER_STATE_H_ */
