#ifndef EXTENSIONS_BF_P4C_PARDE_SPLIT_BIG_STATE_H_
#define EXTENSIONS_BF_P4C_PARDE_SPLIT_BIG_STATE_H_

/// Split states into smaller states which can be executed in a single cycle by
/// the hardware.
class SplitBigStates : public ParserModifier {
    profile_t init_apply(const IR::Node* root) override;

    /// return the buffer size of first state if all branch need to be splitted.
    /// Only in a rare case that only part of matches need to split, which is
    /// caused by that they have late-in-buffer save that has to be done in a new state.
    boost::optional<int> needSplitState(const IR::BFN::LoweredParserState* state);

    /// return the index in the input buffer that primitives are common, if null, then
    /// all are in common.
    unsigned
    calcEarliestConflict(const IR::BFN::LoweredParserState* state);

    void
    addTailStatePrimitives(IR::BFN::LoweredParserState* tailState, int until);

    /// Set primitives in @p common, as its the only match of the common state.
    void
    addCommonStatePrimitives(IR::BFN::LoweredParserMatch* common,
                             const IR::BFN::LoweredParserState* sampleState,
                             int until);

    /// Split out common primitives to a common state and return this state.
    /// Splitted primitives will be removed from original state and shift are adjusted.
    /// @return a state with common primitives and its next state is the truncated original
    /// state.
    IR::BFN::LoweredParserState*
    splitOutCommonState(IR::BFN::LoweredParserState* state,
                        const std::vector<const IR::BFN::LoweredSave*>& extra_saves,
                        int common_until);

    IR::BFN::LoweredParserState*
    createCommonPrimitiveState(const IR::BFN::LoweredParserState* state,
                               const std::vector<const IR::BFN::LoweredSave*>& extra_saves);

    /// Add common state when needed. Then preorder on match will be executed on new state.
    bool preorder(IR::BFN::LoweredParserState* state) override;

    bool preorder(IR::BFN::LoweredParserMatch* match) override;

    std::set<cstring> stateNames;
    std::set<IR::BFN::LoweredParserMatch*> added;
    std::map<cstring, std::vector<const IR::BFN::LoweredSave*>> leftover_saves;
};

#endif /* EXTENSIONS_BF_P4C_PARDE_SPLIT_BIG_STATE_H_ */
