#include "bf-p4c/parde/resolve_computed.h"

#include <boost/optional.hpp>
#include <boost/range/adaptors.hpp>
#include <limits>

#include "frontends/p4/callGraph.h"
#include "bf-p4c/device.h"
#include "bf-p4c/parde/parde_visitor.h"

namespace {

class VerifyAssignedShifts : public ParserInspector {
    bool preorder(const IR::BFN::Transition* transition) override {
        BUG_CHECK(transition->shift,
                  "Parser transition in state %1% was not assigned a shift",
                  findContext<IR::BFN::ParserState>()->name);
        return true;
    }
};

// XXX(seth): This is the simplest approach I've been able to find which has
// correct results. It's subtle, because you need to visit UnresolvedStackRef's
// every time they appear (to uniquify them) but you cannot do the same for
// ParserStates, or you'll end up turning the parser DAG into a tree.
// Visitor::visitDagOnce thus doesn't do the job, and I haven't been able to get
// Visitor::visitAgain() to work as I expected, so this seemingly simple task
// seems doomed to have a fairly complex implementation for the time being.
// XXX(seth): You'd ideally do this when actually constructing the parser IR,
// but I hesitate to rely on that since code elsewhere may mutate it and
// establishing this invariant is critical for the correctness of
// ResolveStackRefs.
class MakeUnresolvedStackRefsUnique : public ParserTransform {
    const IR::BFN::UnresolvedStackRef*
    makeUniqueStackRef(const IR::BFN::UnresolvedStackRef* ref) {
        if (visitedRefIds.find(ref->id) == visitedRefIds.end()) {
            visitedRefIds.insert(ref->id);
            return ref;
        }
        auto* freshRef = ref->makeFresh();
        BUG_CHECK(*freshRef != *ref, "Fresh ref isn't fresh?");
        visitedRefIds.insert(freshRef->id);
        return freshRef;
    }

    const IR::BFN::ParserState*
    preorder(IR::BFN::ParserState* state) override {
        for (unsigned i = 0; i < state->statements.size(); i++) {
            state->statements[i] =
                transformAllMatching<IR::BFN::UnresolvedStackRef>(state->statements[i],
                                    [&](IR::BFN::UnresolvedStackRef* ref) {
                return makeUniqueStackRef(ref);
            })->to<IR::BFN::ParserPrimitive>();
        }
        for (unsigned i = 0; i < state->selects.size(); i++) {
            state->selects[i] =
                transformAllMatching<IR::BFN::UnresolvedStackRef>(state->selects[i],
                                    [&](IR::BFN::UnresolvedStackRef* ref) {
                return makeUniqueStackRef(ref);
            })->to<IR::BFN::Select>();
        }
        return state;
    }

    std::set<size_t> visitedRefIds;
};

using HeaderStackItemRefIndices =
  std::map<const IR::HeaderStackItemRef*, const IR::Expression*>;

struct ResolveStackRefs : public ParserInspector {
    HeaderStackItemRefIndices resolvedIndices;

 private:
    using ExtractedStackIndices = std::map<cstring, bitvec>;

    bool preorder(const IR::BFN::Parser* parser) override {
        ExtractedStackIndices initialMap;
        resolveForState(parser->start, initialMap);
        return false;
    }

    unsigned nextIndex(const IR::HeaderStackItemRef* ref,
                       const ExtractedStackIndices& map) const {
        const auto stackName = ref->base()->toString();

        // If we haven't yet extracted any item in the header stack, the first
        // index is the next one to track.
        if (map.find(stackName) == map.end()) return 0;

        // The `next` property evaluates to the first index in the stack with an
        // unset valid bit. (i.e., the first item that hasn't yet been extracted)
        const auto& extractedIndices = map.at(stackName);
        return extractedIndices.ffz();
    }

    boost::optional<unsigned> lastIndex(const IR::HeaderStackItemRef* ref,
                                        const ExtractedStackIndices& map) const {
        const auto stackName = ref->base()->toString();

        // The `last` property is a partial function; it's an error to evaluate
        // it before you've extracted any item in the header stack.
        if (map.find(stackName) == map.end()) return boost::none;

        // The `last` property evaluates to the last index in the stack with a
        // set valid bit.
        const auto& extractedIndices = map.at(stackName);
        return *extractedIndices.max();
    }

    void updateExtractedIndices(const IR::BFN::Extract* extract,
                                ExtractedStackIndices& map) const {
        // Is this a write to a header stack item POV bit?
        if (!extract->source->is<IR::BFN::ConstantRVal>()) return;
        if (!extract->dest->field->is<IR::Member>()) return;
        auto* member = extract->dest->field->to<IR::Member>();
        if (member->member != "$valid") return;
        if (!member->expr->is<IR::HeaderStackItemRef>()) return;

        // If so, we just finished extracting the corresponding header stack
        // item. Figure out the index and update the map.
        auto* ref = member->expr->to<IR::HeaderStackItemRef>();
        BUG_CHECK(resolvedIndices.find(ref) != resolvedIndices.end(),
                  "Didn't resolve header stack index for POV bit?");
        auto* index = resolvedIndices.at(ref);
        if (!index->is<IR::Constant>()) {
            return;
        }
        auto intIndex = std::max(index->to<IR::Constant>()->asInt(), 0);
        auto stackName = ref->base()->toString();
        map[stackName].setbit(intIndex);
    }

    void resolve(const IR::HeaderStackItemRef* ref, const ExtractedStackIndices& map) {
        // Explicit references to a specific header stack index are trivial; we
        // just resolve them to the specified index.
        if (!ref->index()->is<IR::BFN::UnresolvedStackRef>()) {
            resolvedIndices[ref] = ref->index();
            return;
        }

        const IR::Constant* resolvedIndex = nullptr;
        if (ref->index()->is<IR::BFN::UnresolvedStackNext>()) {
            resolvedIndex = new IR::Constant(nextIndex(ref, map));
        } else if (ref->index()->is<IR::BFN::UnresolvedStackLast>()) {
            auto last = lastIndex(ref, map);
            if (!last) {
                ::error("Calling .last method on unextracted header stack %1%", ref);
                // "Resolve" to the original UnresolvedStackLast, indicating failure.
                resolvedIndices[ref] = ref->index();
                return;
            }
            resolvedIndex = new IR::Constant(*last);
        } else {
            BUG("Unexpected UnresolvedStackRef type %1%", ref->index());
        }

        // If there was no previous resolution, we know we're OK.
        if (resolvedIndices.find(ref) == resolvedIndices.end()) {
            resolvedIndices[ref] = resolvedIndex;
            return;
        }

        // There was a previous resolution. Make sure it matches. For the
        // generated code to be correct, we need to ensure that we get the same
        // index no matter what path we take to reach this point.
        auto* previousResolution = resolvedIndices[ref];
        if (!previousResolution->is<IR::Constant>()) {
            BUG_CHECK(previousResolution->is<IR::BFN::UnresolvedStackRef>(),
                      "Not a constant, but also not a resolution failure?");
            return;  // We already failed; keep it that way.
        }
        if (previousResolution->to<IR::Constant>()->asInt() != resolvedIndex->asInt()) {
            ::error("Cannot resolve header stack item reference "
                    "unambiguously: %1%", ref);
            // "Resolve" to the original UnresolvedStackLast, indicating failure.
            resolvedIndices[ref] = ref->index();
        }
    }

    void resolveForState(const IR::BFN::ParserState* state,
                         const ExtractedStackIndices& context) {
        if (!state) return;

        ExtractedStackIndices map(context);

        forAllMatching<IR::BFN::Extract>(&state->statements,
                      [&](const IR::BFN::Extract* extract) {
            // Resolve any header stack item references lurking in either the
            // source or the destination of the extract.
            forAllMatching<IR::HeaderStackItemRef>(extract,
                          [&](const IR::HeaderStackItemRef* ref) {
                resolve(ref, map);
            });

            // Check if this extract sets a header stack item's POV bit and, if
            // so, record that the item has been extracted.
            updateExtractedIndices(extract, map);
        });

        forAllMatching<IR::HeaderStackItemRef>(&state->selects,
                      [&](const IR::HeaderStackItemRef* ref) {
            resolve(ref, map);
        });

        for (auto* transition : state->transitions)
            resolveForState(transition->next, map);
    }
};

struct AssignNextAndLast : public ParserModifier {
    explicit AssignNextAndLast(const HeaderStackItemRefIndices& resolvedIndices)
      : resolvedIndices(resolvedIndices) { }

 private:
    void postorder(IR::HeaderStackItemRef* ref) override {
        const auto* original = getOriginal<IR::HeaderStackItemRef>();
        BUG_CHECK(resolvedIndices.find(original) != resolvedIndices.end(),
                  "Missed %1% when resolving header stack indices?", original);
        ref->index_ = resolvedIndices.at(original);
    }

    const HeaderStackItemRefIndices& resolvedIndices;
};

struct ResolveNextAndLast : public PassManager {
    ResolveNextAndLast() {
        auto* resolveStackRefs = new ResolveStackRefs;
        addPasses({
            new MakeUnresolvedStackRefsUnique,
            resolveStackRefs,
            new AssignNextAndLast(resolveStackRefs->resolvedIndices)
        });
    }
};

/// Verify that every r-value referenced in the parser program only appears
/// once. This is a requirement for the correctness of
/// CopyPropagateParserValues.
class VerifyParserRValsAreUnique : public ParserInspector {
    bool preorder(const IR::BFN::ParserRVal* value) override {
        BUG_CHECK(visitedParserRVals.find(value) == visitedParserRVals.end(),
                  "Parser r-value appears in more than one place: %1%", value);
        visitedParserRVals.insert(value);
        return false;
    }

    std::set<const IR::BFN::ParserRVal*> visitedParserRVals;
};

/// A mapping from a computed r-value to the r-value we evaluated it to. Ideally
/// we evaluated it to a simple r-value which is implementable on the hardware.
using ParserValueResolution = std::map<const IR::BFN::ComputedRVal*,
                                       const IR::BFN::ParserRVal*>;

/**
 * Walk the parser programs (each thread is treated separately) and try to
 * simplify r-values by replacing any uses of l-values with their definition.
 *
 * XXX(seth): This is slated for demolition. I want to replace this with a copy
 * propagation pass that walks over the entire program, rather than just the
 * parser.
 *
 * @pre Every `ParserRVal` in each of the parser programs is a unique object.
 * @post Any `ComputedRVal` which can be evaluated unambiguously to a simple
 * r-value (i.e. a `PacketRVal` or `ConstantRVal`) is replaced. Any
 * `ComputedRVal` which remains is either too complex to evaluate, contains uses
 * of l-values that were reached by more than one definition, or contains uses
 * of l-values that were not reached by any definition at all.
 */
struct CopyPropagateParserValues : public ParserInspector {
    ParserValueResolution resolvedValues;

 private:
    /// A map from l-values (identified by strings) to the r-value most recently
    /// assigned to them.
    using ReachingDefs = std::map<cstring, const IR::BFN::ParserRVal*>;

    bool preorder(const IR::BFN::Parser* parser) override {
        ReachingDefs initialDefs;
        propagateToState(parser->start, std::move(initialDefs));
        return false;
    }

    ReachingDefs updateOffsets(const ReachingDefs& defs, int byteShift) {
        if (byteShift == 0) return defs;

        ReachingDefs updated;
        for (auto& def : defs) {
            auto lVal = def.first;
            auto* rVal = def.second;

            // Values that don't come from the input packet don't need to
            // change; they're invariant under shifting.
            if (!rVal->is<IR::BFN::PacketRVal>()) {
                updated[lVal] = rVal;
                continue;
            }

            // Values from the input packet need their offsets to be shifted
            // to the left to compensate for the fact that the transition is
            // shifting the input buffer to the right.
            auto* clone = rVal->to<IR::BFN::PacketRVal>()->clone();
            clone->range = clone->range.shiftedByBytes(-byteShift);
            updated[lVal] = clone;
        }

        return updated;
    }

    void propagateToUse(const IR::BFN::ComputedRVal* value,
                        const ReachingDefs& defs) {
        // Drop any cast which may be applied to this computed value.
        // XXX(seth): This obviously isn't sound, but it's consistent with what
        // we're doing elsewhere in the parser code. This is just a hack until
        // we eliminate casts correctly in an earlier pass.
        // XXX(yumin): The size that is casted to is used to form the match range.
        // It would make match value incorrect if we don't respect it.
        boost::optional<int> size_cast_to = boost::make_optional(false, int());
        auto* sourceExpr = value->source;
        if (auto* cast = sourceExpr->to<IR::Cast>()) {
            if (auto* type_bits = cast->destType->to<IR::Type_Bits>()) {
                size_cast_to = type_bits->size; }
            sourceExpr = cast->expr;
        }

        // XXX(seth): Ugh. =( This is a terrible hack, but this stuff will get
        // replaced soon, so it's not worth using a non-hacky approach.
        auto* outerSlice = sourceExpr->to<IR::Slice>();
        if (outerSlice) sourceExpr = outerSlice->e0;

        // Create a string representation of this computed value. We consider
        // values to be equal if they have the same string representation.
        // XXX(seth): It'd be nice to move away from using strings.
        auto sourceName = sourceExpr->toString();

        // Does some definition for this computed value reach this point?
        if (defs.find(sourceName) == defs.end()) {
            // No reaching definition; just "propagate" the original value.
            resolvedValues[value] = value->clone();
            return;
        }

        // We found a definition; propagate it here.
        auto* resolvedValue = defs.at(sourceName)->clone();

        if (size_cast_to) {
            auto* buf = resolvedValue->to<IR::BFN::BufferlikeRVal>();
            auto casted_range = buf->range.resizedToBits(*size_cast_to);
            resolvedValue = new IR::BFN::PacketRVal(casted_range);
        }

        // If this use was wrapped in a slice, try to simplify it.
        // XXX(seth): Again, this will get replaced with something non-hacky
        // soon. For now, this gets us very basic slice support.
        if (outerSlice) {
            auto* bufferlikeValue =
                dynamic_cast<IR::BFN::BufferlikeRVal*>(resolvedValue);
            if (!bufferlikeValue) {
                // We can't simplify slices of other kinds of r-values for now.
                resolvedValues[value] = value->clone();
                return;
            }

            // Try to simplify away the slice by shrinking the input packet
            // range we're extracting. We need to transform the slice into the
            // same coordinate system that the input packet range is using and
            // then intersect the two ranges.
            const le_bitrange sliceRange = FromTo(outerSlice->getL(),
                                                  outerSlice->getH());
            const nw_bitinterval sliceOfValue =
              sliceRange.toOrder<Endian::Network>(bufferlikeValue->range.size())
                        .shiftedByBits(bufferlikeValue->range.lo)
                        .intersectWith(bufferlikeValue->range);
            if (sliceOfValue.empty()) {
                ::error("Computed value resolves to a zero-width slice: %1%",
                        value->source);
                resolvedValues[value] = value->clone();
                return;
            }

            // Success; we've eliminated the slice.
            bufferlikeValue->range = *toClosedRange(sliceOfValue);
            resolvedValue = bufferlikeValue;
        }

        // If there's no other reaching definition, we know we're OK.
        if (resolvedValues.find(value) == resolvedValues.end()) {
            resolvedValues[value] = resolvedValue;
            return;
        }

        // We've seen another definition already.
        auto* previousResolution = resolvedValues[value];

        // If the previous definition is a computed r-value, we've already
        // encountered some kind of failure; just keep it that way.
        if (previousResolution->is<IR::BFN::ComputedRVal>()) return;

        // We found a previous definition that was valid on its own; we just
        // need to make sure it matches the new one. For the generated code to
        // be correct, we need to ensure that every reaching definition is
        // equivalent.
        if (*previousResolution == *resolvedValue) return;

        // The two definitions don't match; that means that we can't resolve
        // this value to a simple r-value unambiguously. Forget the previously
        // encountered definition *and* this new one; just "propagate" the
        // original value.
        ::error("Cannot resolve computed value unambiguously: %1%", value);
        resolvedValues[value] = value->clone();
    }

    void propagateToState(const IR::BFN::ParserState* state,
                          ReachingDefs&& reachingDefs) {  // NOLINT
        if (!state) return;

        ReachingDefs defs(reachingDefs);

        forAllMatching<IR::BFN::Extract>(&state->statements,
                      [&](const IR::BFN::Extract* extract) {
            auto dest = extract->dest->field->toString();

            // If the source of this extract is a computed r-value, its
            // expression may use a definition we've seen. Try to simplify it.
            // (And regardless of our success, record the new definition for
            // `dest`.)
            if (auto* computed = extract->source->to<IR::BFN::ComputedRVal>()) {
                propagateToUse(computed, defs);
                defs[dest] = resolvedValues[computed];
                return;
            }

            // The source is a simple r-value; just record the new definition
            // for `dest` and move on.
            defs[dest] = extract->source;
        });

        forAllMatching<IR::BFN::Select>(&state->selects,
                      [&](const IR::BFN::Select* select) {
            // If the source of this select is a computed r-value, its
            // expression may use a definition we've seen. Try to simplify it.
            if (auto* computed = select->source->to<IR::BFN::ComputedRVal>())
                propagateToUse(computed, defs);
        });

        // Recursively propagate the definitions which have reached this point
        // to child states.
        for (auto* transition : state->transitions)
            propagateToState(transition->next,
                             updateOffsets(defs, *transition->shift));
    }
};

struct ApplyParserValueResolutions : public ParserTransform {
    explicit ApplyParserValueResolutions(const ParserValueResolution& resolvedValues)
      : resolvedValues(resolvedValues) { }

 private:
    IR::BFN::ParserRVal* preorder(IR::BFN::ComputedRVal* value) override {
        prune();
        auto* original = getOriginal<IR::BFN::ComputedRVal>();
        BUG_CHECK(resolvedValues.find(original) != resolvedValues.end(),
                  "No resolution for computed value: %1%", value);
        return resolvedValues.at(original)->clone();
    }

    const ParserValueResolution& resolvedValues;
};

class ResolveComputedValues : public PassManager {
 public:
    ResolveComputedValues() {
        auto* copyPropagate = new CopyPropagateParserValues;
        addPasses({
            copyPropagate,
            new ApplyParserValueResolutions(copyPropagate->resolvedValues)
        });
    }
};

class CheckResolvedHeaderStackExpressions : public ParserInspector {
    bool preorder(const IR::BFN::UnresolvedStackRef* stackRef) {
        ::error("Couldn't resolve header stack reference in state %1%: %2%",
                findContext<IR::BFN::ParserState>()->name, stackRef);
        return false;
    }
};

class CheckResolvedParserExpressions : public ParserTransform {
    const IR::BFN::Extract*
    checkExtractDestination(const IR::BFN::Extract* extract) const {
        if (!extract->dest->field->is<IR::HeaderStackItemRef>()) return extract;

        auto* itemRef = extract->dest->field->to<IR::HeaderStackItemRef>();
        if (itemRef->index()->is<IR::BFN::UnresolvedStackRef>()) {
            ::error("Couldn't resolve header stack reference in state %1%: %2%",
                    findContext<IR::BFN::ParserState>()->name, extract);
            return nullptr;
        }

        if (!itemRef->index()->is<IR::Constant>()) {
            ::error("Extracting to non-constant header stack index in "
                    "state %1%: %2%",
                    findContext<IR::BFN::ParserState>()->name, extract);
            return nullptr;
        }

        auto* stack = extract->dest->field->to<IR::HeaderStackItemRef>()->base();
        auto stackSize = stack->type->to<IR::Type_Stack>()
                              ->size->to<IR::Constant>()->asInt();
        if (itemRef->index()->to<IR::Constant>()->asInt() >= stackSize) {
            // XXX(seth): This should actually be an error, but before making
            // that change we need to make loop unrolling handle header stacks
            // more precisely.
            ::warning("Extract overflows header stack in state %1%: %2%",
                      findContext<IR::BFN::ParserState>()->name, extract);
            // Just clamp it; the hardware will report an error at runtime.
            auto* itemRefClone = itemRef->clone();
            itemRefClone->index_ = new IR::Constant(std::max(stackSize - 1, 0));
            auto* clone = extract->clone();
            clone->dest = new IR::BFN::FieldLVal(itemRefClone);
            return clone;
        }

        return extract;
    }

    const IR::BFN::Extract*
    checkExtractIsNotComputed(const IR::BFN::Extract* extract) const {
        if (!extract->source->is<IR::BFN::ComputedRVal>()) return extract;
        ::error("Couldn't resolve computed value for extract in state %1%: %2%",
                findContext<IR::BFN::ParserState>()->name, extract);
        return nullptr;
    }

    const IR::BFN::ParserPrimitive*
    preorder(IR::BFN::Extract* extract) override {
        prune();
        auto* checkedExtract = checkExtractIsNotComputed(extract);
        if (!checkedExtract) return checkedExtract;
        return checkExtractDestination(checkedExtract);
    }

    const IR::BFN::Select*
    preorder(IR::BFN::Select* select) override {
        prune();
        if (!select->source->is<IR::BFN::ComputedRVal>()) return select;
        ::error("Couldn't resolve computed value for select in state %1%: %2%",
                findContext<IR::BFN::ParserState>()->name,
                select->source->to<IR::BFN::ComputedRVal>()->source);
        return nullptr;
    }
};

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
 * fields extracted in earlier stage, it might not compile. However, the case is rare,
 * because it does not compile in previous implementation.
 *
 * TODO(yumin): if select on something does not show up in the first 32 bytes of the header
 * currently implementation is not able to do, those it's possible by splitting this header.
 *
*/
class ComputeSaveAndSelect: public ParserInspector {
    using State = IR::BFN::ParserState;
    using StateTransition = IR::BFN::Transition;
    using StateSelect = IR::BFN::Select;

    struct UnresolvedSelect {
        UnresolvedSelect(const StateSelect* s, unsigned shifts,
                         const std::set<MatchRegister>& used)
            : select(s), byte_shifted(shifts), used_by_others(used) { }

        const StateSelect* select;
        unsigned byte_shifted;
        // MatchRegisters that has been used on the path by other selects.
        // Any save before that state need to update this.
        std::set<MatchRegister> used_by_others;

        // The absolute offset that this select match on for current state's
        // input buffer.
        nw_bitrange source() const {
            if (auto* buf = select->source->to<IR::BFN::BufferlikeRVal>()) {
                return buf->extractedBits().shiftedByBytes(byte_shifted);
            } else {
                ::error("select on a field that is impossible to implement");
                return nw_bitrange(); }
        }
    };

    std::map<const State*, std::vector<UnresolvedSelect>> state_unresolved_selects;
    ordered_set<const State*> unprocessed_states;

    void postorder(const State* state) override {
        // Mark state_unresolved_selects for this state
        for (const auto* select : state->selects) {
            state_unresolved_selects[state].push_back(
                    UnresolvedSelect(select, 0, { })); }
        unprocessed_states.insert(state);
        calcSaves(state);
    }

    void calcSaves(const State* state) {
        // For each transition branch, calculate the saves and corresponding select.
        for (const auto* transition : state->transitions) {
            BUG_CHECK(transition->shift, "State %1% has unset shift?", state->name);
            BUG_CHECK(*transition->shift >= 0, "State %1% has negative shift %2%?",
                      state->name, *transition->shift);

            // Mapping input buffer to a register that save it.
            std::map<nw_byterange, MatchRegister> saved_range;

            // XXX(yumin): shift is in byte, while all others are in bits.
            unsigned shift_bytes = *transition->shift;
            auto next_state = transition->next;

            // If this state is the last one, do not need to insert any save.
            if (!next_state)
                continue;

            unprocessed_states.erase(next_state);

            // Get unresolved selects by merge all child state's unresolved selects.
            auto unresolved_selects = calcUnresolvedSelects(next_state, shift_bytes);
            std::vector<UnresolvedSelect> early_stage_extracted;

            auto registers = Device::pardeSpec().matchRegisters();
            std::set<MatchRegister> used_registers;

            // Sorted by whether has decided register, the size of select.
            sort(unresolved_selects.begin(), unresolved_selects.end(),
                 [&] (const UnresolvedSelect& l, const UnresolvedSelect& r) {
                     if (select_registers.count(l.select) != select_registers.count(r.select))
                         return select_registers.count(l.select) > select_registers.count(r.select);
                     return l.source().size() < r.source().size();
                 });

            for (const auto& unresolved : unresolved_selects) {
                nw_byterange source = unresolved.source().toUnit<RangeUnit::Byte>();
                if (isExtractedEarlier(unresolved)) {
                    early_stage_extracted.push_back(unresolved);
                    continue; }

                boost::optional<std::vector<MatchRegister>> reg_choice;

                if (select_registers.count(unresolved.select)) {
                    // If the select has already be set by other branch,
                    // this branch need to follow it's decision.
                    // already saved in this state.
                    auto& regs = select_registers[unresolved.select];
                    if (!std::any_of(regs.begin(), regs.end(),
                                     [&] (const MatchRegister& r) -> bool {
                                         return unresolved.used_by_others.count(r); })) {
                        reg_choice = regs; }
                } else {
                    // TODO(yumin):
                    // We should have an algorithm that minimizes the use the
                    // register, e.g. use half to cover two small field,
                    // instead of this naive one.
                    // calculate which regs to use for each byte.
                    std::vector<MatchRegister> accumulated_regs;
                    size_t match_reg_itr = 0;
                    bool found_registers = true;
                    for (int i = source.loByte(); i <= source.hiByte();) {
                        bool found_saved_reg = false;
                        for (int reg_size : {1, 2}) {
                            nw_byterange reg_range = nw_byterange(StartLen(i, reg_size));
                            if (saved_range.count(reg_range)) {
                                accumulated_regs.push_back(saved_range.at(reg_range));
                                i += reg_size;
                                found_saved_reg = true;
                                break; } }

                        if (found_saved_reg) continue;

                        bool found_reg_for_this_byte = false;
                        while (match_reg_itr < registers.size()) {
                            auto& reg = registers[match_reg_itr++];
                            if (used_registers.count(reg) || unresolved.used_by_others.count(reg)) {
                                continue; }
                            accumulated_regs.push_back(reg);
                            i += reg.size;
                            found_reg_for_this_byte = true;
                            break;
                        }

                        if (!found_reg_for_this_byte) {
                            found_registers = false;
                            break;
                        }
                    }
                    if (found_registers) {
                        reg_choice = accumulated_regs; }
                }

                // Cannot find a register or the found one has been used
                // by downstream states because of brother's decision.
                if (!reg_choice) {
                    // throw error message saying that it's impossible.
                    ::error("Too much data for parse matcher, register not enough for %1%",
                            cstring::to_cstring(unresolved.select));
                    return;
                }

                // Assign registers and update match_saves
                // TODO(yumin): if it's the last byte, we can't use half register on it.
                // This case is rare because it only happens when you lookahead
                // to the last byte and all byte registers are used.
                nw_byterange save_range_itr = source;
                for (const auto& r : *reg_choice) {
                    nw_byterange range_of_this_register = save_range_itr.resizedToBytes(r.size);
                    if (!saved_range.count(range_of_this_register)) {
                        transition_saves[transition].push_back(
                                new IR::BFN::SaveToRegister(r, range_of_this_register));
                        saved_range[range_of_this_register] = r;
                    }
                    save_range_itr = save_range_itr.shiftedByBytes(r.size);
                }
                select_registers[unresolved.select] = *reg_choice;
                select_masks[unresolved.select]     = calcMask(unresolved.source(), source);
                used_registers.insert((*reg_choice).begin(), (*reg_choice).end());
            }

            // If there are remaining selects that needs to be extracted in earlier state,
            // update the used registers on this transition.
            // Note that, though registers used in this state will 'start to live' in the next
            // state, it should be added because those remaining_unresolved selects 'start to live'
            // in next state as well.
            for (const auto& remaining_unresolved : early_stage_extracted) {
                auto unresolved = remaining_unresolved;
                unresolved.used_by_others.insert(used_registers.begin(), used_registers.end());
                state_unresolved_selects[state].push_back(unresolved);
            }
        }  // for transition
    }

    void end_apply() override {
        // Add all unresolved select to a dummy state.
        auto unprocessed_copy = unprocessed_states;
        for (const auto* state : unprocessed_copy) {
            auto gress = state->thread();
            BUG_CHECK(additional_states.count(gress) == 0,
                      "More than one starting state for %1%", gress);
            auto* transition = new IR::BFN::Transition(match_t(), 0, state);
            auto* init_state = new IR::BFN::ParserState(
                    "$_save_init_state", gress, { }, { }, { transition });
            calcSaves(init_state);
            if (transition_saves.count(transition)
                && transition_saves[transition].size() > 0) {
                additional_states[gress] = init_state; }
        }
        BUG_CHECK(unprocessed_states.size() == 0,
                  "Unprocessed states remaining");
    }

    nw_bitrange calcMask(nw_bitrange match_range, nw_byterange saved_range) {
        int loByte = saved_range.loByte();
        return match_range.shiftedByBytes(-loByte);
    }

    bool
    isExtractedEarlier(const UnresolvedSelect& select) {
        if (select.source().lo < 0) return true;
        return false;
    }

    std::vector<UnresolvedSelect>
    calcUnresolvedSelects(const State* next_state, unsigned shift_bytes) {
        // For the state_unresolved_selects from children state,
        // The range in this state used to save should be range + shift.
        std::vector<UnresolvedSelect> rst;
        for (const auto& s : state_unresolved_selects[next_state]) {
            UnresolvedSelect for_this_state(s);
            for_this_state.byte_shifted += shift_bytes;
            rst.push_back(for_this_state); }

        return rst;
    }

 public:
    // The saves need to be executed on this transition.
    std::map<const StateTransition*, std::vector<const IR::BFN::SaveToRegister*>> transition_saves;

    // The register that this select should match against.
    std::map<const StateSelect*, std::vector<MatchRegister>> select_registers;
    std::map<const StateSelect*, nw_bitrange> select_masks;

    // The additional state that should be prepended to the start state
    // to generate save for the select on the first state.
    std::map<gress_t, IR::BFN::ParserState*> additional_states;
};

struct WriteBackSaveAndSelect : public ParserModifier {
    explicit WriteBackSaveAndSelect(const ComputeSaveAndSelect& saves)
        : rst(saves) { }

    bool preorder(IR::BFN::Parser* parser) override {
        auto gress = parser->gress;
        if (rst.additional_states.count(gress) > 0) {
            parser->start = rst.additional_states.at(gress); }
        return true;
    }

    void postorder(IR::BFN::Transition* transition) override {
        auto* original_transition = getOriginal<IR::BFN::Transition>();
        if (rst.transition_saves.count(original_transition)) {
            for (const auto* save : rst.transition_saves.at(original_transition)) {
                transition->saves.push_back(save); }
        }
    }

    void postorder(IR::BFN::Select* select) override {
        auto* original_select = getOriginal<IR::BFN::Select>();
        if (rst.select_registers.count(original_select)) {
            select->reg = rst.select_registers.at(original_select);
            select->mask = rst.select_masks.at(original_select); }
    }

    const ComputeSaveAndSelect& rst;
};

/** A helper class for adjusting match value.
 */
class MatchRegisterLayout {
 private:
    std::vector<MatchRegister> all_regs;
    std::map<MatchRegister, match_t> values;
    size_t total_size;

    match_t shiftRight(match_t val, int n) {
        auto word0 = val.word0;
        auto word1 = val.word1;
        word0 >>= n;
        word1 >>= n;
        return match_t(word0, word1);
    }

    match_t shiftLeft(match_t val, int n) {
        auto word0 = val.word0;
        auto word1 = val.word1;
        word0 <<= n;
        word1 <<= n;
        return match_t(word0, word1);
    }

    match_t orTwo(match_t a, match_t b) {
        auto word0 = (a.word0 | b.word0);
        auto word1 = (a.word1 | b.word1);
        return match_t(word0, word1);
    }

    match_t setWild(match_t a) {
        auto word0 = a.word0;
        auto word1 = a.word1;
        auto wilds = (~(word0 ^ word1)) & (~((~uintmax_t(0)) << total_size));
        return match_t(word0 | wilds, word1 | wilds);
    }

    // start is the from the left
    match_t getSubValue(match_t val, int sz, int start, int len) {
        auto word0 = val.word0;
        auto word1 = val.word1;
        uintmax_t mask = (~((~uintmax_t(0)) << (sz - start)));
        auto trim_left_word0 = (word0 & mask);
        auto trim_left_word1 = (word1 & mask);
        return shiftRight(match_t(trim_left_word0, trim_left_word1), sz - start - len);
    }

 public:
    explicit MatchRegisterLayout(std::set<MatchRegister> used_regs)
        : total_size(0) {
        for (const auto& r : used_regs) {
            total_size += r.size * 8;
            all_regs.push_back(r);
            values[r] = match_t(0, 0); }
    }

    void writeValue(const std::vector<MatchRegister> regs,
                    nw_bitrange mask, match_t val) {
        int total_reg_size = 0;
        for (const auto& r : regs) {
            total_reg_size += r.size * 8; }

        int val_shifted = 0;
        int reg_shifted = 0;
        for (const auto& r : regs) {
            nw_bitrange range_of_r(StartLen(reg_shifted, r.size * 8));
            BUG_CHECK(toClosedRange(mask.intersectWith(range_of_r)),
                      "Use Match register on empty range");
            nw_bitrange value_range_of_r = *toClosedRange(mask.intersectWith(range_of_r));
            // For the stored match value, shift right to remove all bits that is
            // matched in the next match register. Shift right 0 when it's the last
            // chunk.
            match_t value_of_r = getSubValue(val, mask.size(),
                                             val_shifted, value_range_of_r.size());
            // Then shift left by the empty (the 'bb..b' part) to or in.
            // LOG1("sft2: " << range_of_r.hi - value_range_of_r.hi);
            match_t value_to_or = shiftLeft(value_of_r, range_of_r.hi - value_range_of_r.hi);
            values[r] = orTwo(values[r], value_to_or);
            val_shifted += value_range_of_r.size();
            reg_shifted += r.size * 8;
        }
    }

    match_t getMatchValue() {
        int shift = 0;
        match_t rtn(0, 0);
        for (const auto& r : boost::adaptors::reverse(all_regs)) {
            rtn = orTwo(rtn, shiftLeft(values[r], shift));
            shift += r.size * 8;
        }
        return setWild(rtn);
    }
};

struct AdjustMatchValue : public ParserModifier {
    void postorder(IR::BFN::Transition* transition) override {
        auto* state = findContext<IR::BFN::ParserState>();
        std::set<MatchRegister> used_registers;
        for (const auto* select : state->selects) {
            for (const auto& r : select->reg) {
                used_registers.insert(r); } }

        // Pop out value for each select.
        auto& value = transition->value;
        uintmax_t word0 = value.word0;
        uintmax_t word1 = value.word1;
        auto shiftOut = [&word0, &word1] (int sz) {
            uintmax_t mask = ~(~uintmax_t(0) << sz);
            uintmax_t sub0 = (word0 & mask);
            uintmax_t sub1 = (word1 & mask);
            word0 >>= sz;
            word1 >>= sz;
            return match_t(sub0, sub1); };

        std::map<const IR::BFN::Select*, match_t> select_values;
        for (const auto* select : boost::adaptors::reverse(state->selects)) {
            int value_size = select->mask.size();
            select_values[select] = shiftOut(value_size); }

        MatchRegisterLayout layout(used_registers);
        for (const auto* select : state->selects) {
            layout.writeValue(select->reg, select->mask, select_values[select]);
        }
        transition->value = layout.getMatchValue();
    }
};

struct InsertSaveAndSelect : public PassManager {
    InsertSaveAndSelect() {
        auto* computeSaveAndSelect = new ComputeSaveAndSelect();
        addPasses({
            computeSaveAndSelect,
            new WriteBackSaveAndSelect(*computeSaveAndSelect),
            new AdjustMatchValue(),
        });
    }
};

}  // namespace

ResolveComputedParserExpressions::ResolveComputedParserExpressions() {
    addPasses({
        new VerifyAssignedShifts,
        new ResolveNextAndLast,
        new VerifyParserRValsAreUnique,
        new ResolveComputedValues,
        new CheckResolvedParserExpressions,
        new InsertSaveAndSelect,
    });
}

ResolveComputedHeaderStackExpressions::ResolveComputedHeaderStackExpressions() {
    addPasses({
        new VerifyAssignedShifts,
        new ResolveNextAndLast,
        new CheckResolvedHeaderStackExpressions
    });
}
