#ifndef EXTENSIONS_BF_P4C_PARDE_RESOLVE_NEGATIVE_EXTRACT_H_
#define EXTENSIONS_BF_P4C_PARDE_RESOLVE_NEGATIVE_EXTRACT_H_

#include "bf-p4c/common/utils.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/parser_info.h"

/// For extracts with negative source, i.e. source is in an earlier state, adjust
/// the state's shift amount so that the source is within current state's input buffer.
struct ResolveNegativeExtract : public PassManager {
    struct CollectNegativeExtractStates : public ParserInspector {
        const CollectParserInfo& parserInfo;

        std::map<cstring, unsigned> state_to_shift;

        explicit CollectNegativeExtractStates(const CollectParserInfo& pi) : parserInfo(pi) { }

        bool preorder(const IR::BFN::PacketRVal* rval) override {
            auto extract = findContext<IR::BFN::Extract>();
            if (extract && rval->range.lo < 0) {
                auto state = findContext<IR::BFN::ParserState>();
                unsigned shift = (-rval->range.lo + 7) / 8;
                state_to_shift[state->name] = std::max(state_to_shift[state->name], shift);

                auto parser = findContext<IR::BFN::Parser>();
                auto preds = parserInfo.graph(parser).predecessors().at(state);

                // XXX(zma) parser splitting currently requires all transitions leaving
                // a state to have same shift amount, so below is maintain this invariant
                for (auto pred : preds) {
                    auto succs = parserInfo.graph(parser).successors().at(pred);
                    for (auto succ : succs)
                        state_to_shift[succ->name] = state_to_shift[state->name];
                }
            }

            return false;
        }

        void end_apply() override {
            for (auto kv : state_to_shift)
                LOG3(kv.first << " needs " << kv.second << " bytes of shift");
        }
    };

    struct AdjustShift : public ParserModifier {
        const CollectNegativeExtractStates& collectNegative;

        explicit AdjustShift(const CollectNegativeExtractStates& cg) : collectNegative(cg) { }

        bool preorder(IR::BFN::Transition* transition) override {
            auto state = findContext<IR::BFN::ParserState>();

            if (collectNegative.state_to_shift.count(state->name)) {
                transition->shift += collectNegative.state_to_shift.at(state->name);
            } else if (transition->next &&
                       collectNegative.state_to_shift.count(transition->next->name)) {
                unsigned shift = collectNegative.state_to_shift.at(transition->next->name);
                if (transition->shift < shift) {
                    ::fatal_error("Parser state %1% requires fields from an earlier state"
                                  " which have been lost in current state's input buffer",
                                  transition->next->name);
                }
                transition->shift -= shift;
            }

            return true;
        }

        bool preorder(IR::BFN::PacketRVal* rval) override {
            auto state = findContext<IR::BFN::ParserState>();

            if (collectNegative.state_to_shift.count(state->name)) {
                unsigned shift = collectNegative.state_to_shift.at(state->name) * 8;
                rval->range.lo += shift;
                rval->range.hi += shift;
            }

            return false;
        }
    };

    ResolveNegativeExtract() {
        auto* parserInfo = new CollectParserInfo;
        auto* collectNegative = new CollectNegativeExtractStates(*parserInfo);

        addPasses({
            LOGGING(4) ? new DumpParser("before_resolve_negative_extract") : nullptr,
            parserInfo,
            collectNegative,
            new AdjustShift(*collectNegative),
            LOGGING(4) ? new DumpParser("after_resolve_negative_extract") : nullptr
        });
    }
};

#endif /* EXTENSIONS_BF_P4C_PARDE_RESOLVE_NEGATIVE_EXTRACT_H_ */
