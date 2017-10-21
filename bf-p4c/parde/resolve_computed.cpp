#include "bf-p4c/parde/resolve_computed.h"

#include <boost/optional.hpp>
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
 * r-value (i.e. a `BufferRVal` or `ConstantRVal`) is replaced. Any
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

            // Values that don't come from the buffer don't need to change.
            if (!rVal->is<IR::BFN::BufferRVal>()) {
                updated[lVal] = rVal;
                continue;
            }

            // Values from the input buffer need their offsets to be shifted
            // to the left to compensate for the fact that the transition is
            // shifting the input buffer to the right.
            auto* clone = rVal->to<IR::BFN::BufferRVal>()->clone();
            clone->range = clone->range.shiftedByBytes(-byteShift);
            updated[lVal] = clone;
        }

        return updated;
    }

    void propagateToUse(const IR::BFN::ComputedRVal* value,
                        const ReachingDefs& defs) {
        // Create a string representation of this computed value. We consider
        // values to be equal if they have the same string representation.
        // XXX(seth): It'd be nice to move away from using strings.
        auto sourceName = value->source->toString();

        // Does some definition for this computed value reach this point?
        if (defs.find(sourceName) == defs.end()) {
            // No reaching definition; just "propagate" the original value.
            resolvedValues[value] = value->clone();
            return;
        }

        // We found a definition; propagate it here.
        auto* resolvedValue = defs.at(sourceName)->clone();

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
                          ReachingDefs&& reachingDefs) {
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

using OffsetCorrections = std::map<const IR::Node*, int>;
using ShiftCorrections = std::map<const IR::BFN::Transition*, int>;

class ComputeOffsetCorrections : public ParserInspector {
 public:
    ComputeOffsetCorrections() : transitions("transitions") { }

    OffsetCorrections bitOffsetCorrections;
    ShiftCorrections byteShiftCorrections;

 private:
    Visitor::profile_t init_apply(const IR::Node* node) override {
        forAllMatching<IR::BFN::Transition>(node,
                      [&](const IR::BFN::Transition* transition) {
            if (transition->next) transitions.calls(transition, transition->next);
        });
        return ParserInspector::init_apply(node);
    }

    void postorder(const IR::BFN::ParserState* state) override {
        // Find the minimum negative offset used in this state. This tells us
        // how far back in the input buffer we need to move this state so that
        // all offsets are positive. Note that we take any shift corrections
        // that were already computed by our successor states into account.
        int bitMinOffset = 0;
        forAllMatching<IR::BFN::BufferRVal>(&state->statements,
                      [&](const IR::BFN::BufferRVal* value) {
            bitMinOffset = std::min(bitMinOffset, value->range.lo);
        });
        forAllMatching<IR::BFN::BufferRVal>(&state->selects,
                      [&](const IR::BFN::BufferRVal* value) {
            bitMinOffset = std::min(bitMinOffset, value->range.lo);
        });
        for (auto* transition : state->transitions) {
            BUG_CHECK(byteShiftCorrections[transition] <= 0,
                      "Computed a positive shift correction?");
            auto byteCorrectedShift = *transition->shift +
                                      byteShiftCorrections[transition];
            bitMinOffset = std::min(bitMinOffset, byteCorrectedShift * 8);
        }

        // We can only shift by whole bytes, so convert to bytes to determine
        // the final correction. This correction can be interpreted two ways:
        //  (1) It tells us how much to *increase* all of the offsets and shifts
        //      in this state so that they'll refer to the correct range of bits
        //      in the input buffer after the correction is applied.
        //  (2) It tells us how much to *reduce* the shifts that are applied on
        //      the transitions that lead into this state. That reduction may
        //      actually make those shifts negative, requiring us to fix the
        //      offsets in that state as well. That's why this is a bottom-up
        //      analysis.
        // All of these changes will be applied in ApplyOffsetCorrections.
        const int byteShiftCorrection = (-bitMinOffset + 7) / 8;
        const int bitOffsetCorrection = byteShiftCorrection * 8;

        // Increase offsets and shifts.
        bitOffsetCorrections[state] = bitOffsetCorrection;
        for (auto* transition : state->transitions)
            byteShiftCorrections[transition] += byteShiftCorrection;

        // Reduce the shifts of callers.
        auto* callers = transitions.getCallers(state);
        if (!callers || callers->empty()) {
            if (byteShiftCorrection != 0)
                ::error("Parser program attempts to read %1% bytes before the "
                        "beginning of the %2% input buffer", byteShiftCorrection,
                        state->gress);
            return;
        }
        for (auto* caller : *callers) {
            BUG_CHECK(caller->is<IR::BFN::Transition>(),
                      "A non-Transition calls a ParserState?");
            auto* transition = caller->to<IR::BFN::Transition>();
            BUG_CHECK(byteShiftCorrections[transition] == 0,
                      "Already corrected this Transition's shift?");
            byteShiftCorrections[transition] = -byteShiftCorrection;
        }
    }

    P4::CallGraph<const IR::Node*> transitions;
};

struct ApplyOffsetCorrections : public ParserModifier {
    ApplyOffsetCorrections(const OffsetCorrections& bitOffsetCorrections,
                           const ShiftCorrections& byteShiftCorrections)
      : bitOffsetCorrections(bitOffsetCorrections),
        byteShiftCorrections(byteShiftCorrections)
    { }

 private:
    void postorder(IR::BFN::BufferRVal* value) override {
        auto* state = findOrigCtxt<IR::BFN::ParserState>();
        BUG_CHECK(bitOffsetCorrections.find(state) != bitOffsetCorrections.end(),
                  "No offset correction entries for state %1%", state->name);
        value->range = value->range.shiftedByBits(bitOffsetCorrections.at(state));
        BUG_CHECK(value->range.lo >= 0, "Failed to correct offset?");
    }

    void postorder(IR::BFN::Transition* transition) override {
        auto* original = getOriginal<IR::BFN::Transition>();
        BUG_CHECK(byteShiftCorrections.find(original) != byteShiftCorrections.end(),
                  "No shift correction entries for transition in state %1%",
                  findContext<IR::BFN::ParserState>()->name);
        *transition->shift += byteShiftCorrections.at(original);
        BUG_CHECK(*transition->shift >= 0, "Failed to correct shift?");
    }

    const OffsetCorrections& bitOffsetCorrections;
    const ShiftCorrections& byteShiftCorrections;
};

struct RemoveNegativeOffsets : public PassManager {
    RemoveNegativeOffsets() {
        auto* computeCorrections = new ComputeOffsetCorrections;
        addPasses({
            computeCorrections,
            new ApplyOffsetCorrections(computeCorrections->bitOffsetCorrections,
                                       computeCorrections->byteShiftCorrections)
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
    checkExtractFitsInBuffer(const IR::BFN::Extract* extract) const {
        auto* bufferSource = extract->source->to<IR::BFN::BufferRVal>();
        if (!bufferSource) return extract;

        auto* state = findContext<IR::BFN::ParserState>();
        if (state->transitions.empty()) return extract;

        // Check if this extract could possibly fit within the input buffer on
        // the hardware. We can split large states into smaller ones, but we're
        // limited by the fact that the total number of bytes we shift out of
        // the input buffer in those smaller states has to equal the shift of
        // the original state. If, after shifting that much, this extract still
        // doesn't fit in the input buffer, then it's unimplementable on the
        // hardware.
        // XXX(seth): That doesn't mean that we couldn't produce a parser
        // program with the same behavior that *is* implementable; we could
        // support a lot more with some additional program transformations.
        int worstCaseShift = std::numeric_limits<int>::max();
        for (auto* transition : state->transitions)
            worstCaseShift = std::min(worstCaseShift, *transition->shift);

        const int byteOverflow = bufferSource->bitInterval().hiByte() - worstCaseShift;
        if (byteOverflow < Device::pardeSpec().byteInputBufferSize())
            return extract;

        ::error("Extract in state %1% requires reading %2% bytes ahead, which "
                "is beyond %3%'s limit of %4% bytes: %5%",
                findContext<IR::BFN::ParserState>()->name, byteOverflow,
                Device::currentDevice(),
                Device::pardeSpec().byteInputBufferSize(), extract);

        // The most likely cause is that RemoveNegativeOffsets had to put off
        // shifting so long that we ran out of runway in the input buffer.
        ::error("(Does your parser read or select on a value which originated "
                "in a much earlier state?)");

        return nullptr;
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
        checkedExtract = checkExtractFitsInBuffer(checkedExtract);
        if (!checkedExtract) return checkedExtract;
        return checkExtractDestination(checkedExtract);
    }

    const IR::BFN::Select*
    preorder(IR::BFN::Select* select) override {
        prune();
        if (!select->source->is<IR::BFN::ComputedRVal>()) return select;
        ::error("Couldn't resolve computed value for select in state %1%: %2%",
                findContext<IR::BFN::ParserState>()->name, select);
        return nullptr;
    }
};

}  // namespace

ResolveComputedParserExpressions::ResolveComputedParserExpressions() {
    addPasses({
        new VerifyAssignedShifts,
        new ResolveNextAndLast,
        new VerifyParserRValsAreUnique,
        new ResolveComputedValues,
        new RemoveNegativeOffsets,
        new CheckResolvedParserExpressions
    });
}

ResolveComputedHeaderStackExpressions::ResolveComputedHeaderStackExpressions() {
    addPasses({
        new VerifyAssignedShifts,
        new ResolveNextAndLast,
        new CheckResolvedHeaderStackExpressions
    });
}
