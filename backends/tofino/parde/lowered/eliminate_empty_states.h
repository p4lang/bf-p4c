#ifndef EXTENSIONS_BF_P4C_PARDE_LOWERED_ELIMINATE_EMPTY_STATES_H_
#define EXTENSIONS_BF_P4C_PARDE_LOWERED_ELIMINATE_EMPTY_STATES_H_

#include "backends/tofino/parde/parde_visitor.h"
#include "backends/tofino/parde/parser_info.h"

namespace Parde::Lowered {

/**
 * @ingroup LowerParserIR
 * @brief Eliminates empty states.
 *
 * If before parser lowering, a state is empty and has unconditional transition
 * leaving the state, we can safely eliminate this state.
 */
struct EliminateEmptyStates : public ParserTransform {
    const CollectParserInfo& parser_info;

    explicit EliminateEmptyStates(const CollectParserInfo& pi) : parser_info(pi) {}

    bool is_empty(const IR::BFN::ParserState* state);

    const IR::BFN::Transition* get_unconditional_transition(const IR::BFN::ParserState* state);

    IR::Node* preorder(IR::BFN::Transition* transition) override;
};

}  // namespace Parde::Lowered

#endif /* EXTENSIONS_BF_P4C_PARDE_LOWERED_ELIMINATE_EMPTY_STATES_H_ */
