#ifndef EXTENSIONS_BF_P4C_PARDE_ALLOCATE_PARSER_MATCH_REGISTER_H_
#define EXTENSIONS_BF_P4C_PARDE_ALLOCATE_PARSER_MATCH_REGISTER_H_

#include "bf-p4c/parde/resolve_parser_values.h"

/** Compute select/save to register on each state.
 *
 * @pre: ResolveComputedValues has resolved all Rvalue expression in select to a
 * specific buffer range. If referencing to data that is already shifted out from
 * input buffer, the range offset should remain negative. At this point, we assume
 * that each state has infinitely large input buffer, and the reason of shifting on
 * transition to the other state is because that it is how it is written in the p4 program.
 *
 * The algorithm used here is to generate save [*] to register, when [*] is inside the current
 * state. Registers are allocated greedily, in that we try smaller registers first.
 * Algorithm detail:
 * 1. On postorder of every state, add selects to unresolved select of this state.
 *    add itself to unprocessed state.
 * 2. Forall transitions from this state,
 *     a. Get all unresolved select of the next state, shift them by the `shift` value.
 *     b. Allocate match register to them, if they are extracted in this state, otherwise,
 *        add it to unresolved selets of this state. Note that there are several requirements
 *        on register allocation, e.g. if the select has already been allocated with a specific
 *        register, we must use that register on all the other branches.
 *     c. Mark corresponding select that it is using this register.
 * 3. In the end_apply, if there are unprocess state that has unresolved selets (TNA case),
 *    Insert a new state to add saves for that state.
 *
 * About Match Register Liverange:
 * If you select field.A in state.5, and field.A is extracted in state.2,
 * then field.A is saved to a match_register.i in state.2, during the second clock,
 * then [state.3, state.5) is the span of match_register.i.
 *
 * Now we eargerly resolve selects, which means: `who decides first, others must follow`.
 * It is for a two branch and merge case, all parent nodes need to coperate and make same
 * decision on which register to used for each select.
 *
 * TODO(yumin): Currently, we greedily allocate registers. so if there is a lot match on
 * fields extracted in an earlier state, it might not compile. However, the case is rare,
 * because it does not compile in previous implementation.
 *
*/

struct AllocateParserMatchRegisters : public PassManager {
    AllocateParserMatchRegisters(
        const std::map<const IR::BFN::ComputedRVal*, std::vector<ParserRValDef>>& multiDef);
};

#endif  /* EXTENSIONS_BF_P4C_PARDE_ALLOCATE_PARSER_MATCH_REGISTER_H_ */
