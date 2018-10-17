#include "bf-p4c/parde/resolve_computed.h"

#include <boost/optional.hpp>
#include <boost/range/adaptors.hpp>
#include <limits>

#include "bf-p4c/device.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/allocate_parser_match_register.h"

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
        auto lval = extract->dest->to<IR::BFN::FieldLVal>();
        if (!lval) return;
        if (!lval->field->is<IR::Member>()) return;
        auto* member = lval->field->to<IR::Member>();
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
    profile_t init_apply(const IR::Node* root) override {
        visitedParserRVals.clear();
        return Inspector::init_apply(root);
    }
    bool preorder(const IR::BFN::ParserRVal* value) override {
        BUG_CHECK(visitedParserRVals.find(value) == visitedParserRVals.end(),
                  "Parser r-value appears in more than one place: %1%", value);
        visitedParserRVals.insert(value);
        return false;
    }

    std::set<const IR::BFN::ParserRVal*> visitedParserRVals;
};

/// Verify that every parser state have unique name.
/// This is a requirement for the correctness from CopyPropagateParserValues to
/// AllocateParserMatchRegisters, as state name is used to check equalilty between state*.
class VerifyStateNamessAreUnique : public ParserInspector {
    profile_t init_apply(const IR::Node* root) override {
        visitedNames.clear();
        return Inspector::init_apply(root);
    }
    bool preorder(const IR::BFN::ParserState* state) override {
        cstring name = cstring::to_cstring(state->gress) + state->name;
        BUG_CHECK(visitedNames.count(name) == 0,
                  "Duplicated parser state name appears: %1%", name);
        visitedNames.insert(name);
        return false;
    }

    std::set<cstring> visitedNames;
};

/// A mapping from a computed r-value to the r-values we evaluated it to.
/// For one computedRVal, it can have multiple definition parserRVal.
using ParserValueResolution =
    std::map<const IR::BFN::ComputedRVal*, std::vector<ParserRValDef>>;

#ifndef NDEBUG
std::ostream& operator<<(std::ostream& s, const ParserValueResolution& mapping) {
    for (const auto& kv : mapping) {
        s << "For " << kv.first << " multiple defs found: " << "\n";
        for (const auto& def : kv.second) {
            s << def.state->name << ", " << def.rval << "\n"; } }
    return s;
}

static void print_match(match_t m) {
    std::cout << m << std::endl;
}
#endif  // NDEBUG

/**
 * Walk the parser programs (each thread is treated separately) and try to
 * simplify r-values by replacing any uses of l-values with their definition.
 *
 * @pre Every `ParserRVal` in each of the parser programs is a unique object.
 * @post Any `ComputedRVal` which can either be evaluated unambiguously to a simple
 * r-value (i.e. a `PacketRVal` or `ConstantRVal`), or remain the same but have a mapping
 * that maps it to multiple place that it were defined, only if it is for select. Any
 * `ComputedRVal` which remains (without having a mapping) is either too complex to
 *  evaluate, or contains uses of l-values that were not reached by any definition at all.
 */
struct CopyPropagateParserValues : public ParserInspector {
    ParserValueResolution resolvedValues;

 private:
    /// A map from l-values (identified by strings) to the r-value most recently
    /// assigned to them.
    using ReachingDefs = std::map<cstring, ParserRValDef>;

    profile_t init_apply(const IR::Node* root) override {
        resolvedValues.clear();
        return Inspector::init_apply(root);
    }

    bool preorder(const IR::BFN::Parser* parser) override {
        ReachingDefs initialDefs;
        propagateToState(parser->start, std::move(initialDefs));
        return false;
    }

    ReachingDefs updateOffsets(const ReachingDefs& defs, int byteShift) {
        if (byteShift == 0) return defs;

        ReachingDefs updated;
        for (auto& def : defs) {
            cstring lVal = def.first;
            auto* rVal = def.second.rval;

            // Values that don't come from the input packet don't need to
            // change; they're invariant under shifting.
            if (!rVal->is<IR::BFN::PacketRVal>()) {
                updated.emplace(lVal, def.second);
                continue; }

            // Values from the input packet need their offsets to be shifted
            // to the left to compensate for the fact that the transition is
            // shifting the input buffer to the right.
            auto* clone = rVal->to<IR::BFN::PacketRVal>()->clone();
            clone->range_ = clone->range_.shiftedByBytes(-byteShift);
            updated.emplace(lVal, ParserRValDef(def.second.state, clone));
        }

        return updated;
    }

    void propagateToUse(const IR::BFN::ParserState* state,
                        const IR::BFN::ComputedRVal* value,
                        const ReachingDefs& defs) {
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
        auto sourceName = sourceExpr->toString();

        // Does some definition for this computed value reach this point?
        if (defs.find(sourceName) == defs.end()) {
            // No reaching definition; just "propagate" the original value.
            if (!resolvedValues.count(value)) {
                resolvedValues[value] = { ParserRValDef(state, value->clone()) };
            } else {
                resolvedValues[value].push_back(ParserRValDef(state, value->clone()));
                LOG1("Select on field that might be uninitialized "
                     "in some parser path: " << value->source);
            }
            return;
        }

        // We found a definition; propagate it here.
        auto& rvalRef = defs.at(sourceName);
        auto* resolvedValue = rvalRef.rval->clone();

        if (size_cast_to) {
            auto* buf = resolvedValue->to<IR::BFN::BufferlikeRVal>();
            auto casted_range = buf->range().resizedToBits(*size_cast_to);
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
                if (!resolvedValues.count(value))
                    resolvedValues[value] = { ParserRValDef(state, value->clone()) };
                return;
            }

            // Try to simplify away the slice by shrinking the input packet
            // range we're extracting. We need to transform the slice into the
            // same coordinate system that the input packet range is using and
            // then intersect the two ranges.
            const le_bitrange sliceRange = FromTo(outerSlice->getL(),
                                                  outerSlice->getH());
            const nw_bitinterval sliceOfValue =
              sliceRange.toOrder<Endian::Network>(bufferlikeValue->range().size())
                        .shiftedByBits(bufferlikeValue->range().lo)
                        .intersectWith(bufferlikeValue->range());
            if (sliceOfValue.empty()) {
                ::error("Computed value resolves to a zero-width slice: %1%",
                        value->source);
                resolvedValues[value] = { ParserRValDef(state, value->clone()) };
                return;
            }

            // Success; we've eliminated the slice.
            bufferlikeValue->range_ = *toClosedRange(sliceOfValue);
            resolvedValue = bufferlikeValue;
        }

        // If there's no other reaching definition, we know we're OK.
        if (resolvedValues.find(value) == resolvedValues.end()) {
            resolvedValues[value] = { ParserRValDef(rvalRef.state, resolvedValue) };
            return;
        }

        // We've seen another definition already.
        auto& previousResolution = resolvedValues[value];

        // If the previous definition is a computed r-value, we've already
        // encountered some kind of failure; just keep it that way.
        if (previousResolution.size() == 1
            && previousResolution.front().rval->is<IR::BFN::ComputedRVal>()) {
            ::warning("Select on field that might be uninitialized "
                      "in some parser path: %1%", value->source); }

        // We found a previous definition that was valid on its own; we just
        // need to make sure we are not adding duplicated defs.
        bool duplicated = false;
        for (const auto& def : previousResolution) {
            if (def.state == rvalRef.state && *def.rval == *resolvedValue) {
                duplicated = true;
                break; } }

        if (!duplicated) {
            resolvedValues[value].push_back(ParserRValDef(rvalRef.state, resolvedValue)); }
    }

    void propagateToState(const IR::BFN::ParserState* state,
                          ReachingDefs&& reachingDefs) {  // NOLINT
        if (!state) return;

        ReachingDefs defs(reachingDefs);

        // The source is a simple r-value; just record the new definition
        // for `dest` and move on.
        forAllMatching<IR::BFN::Extract>(
            &state->statements, [&] (const IR::BFN::Extract* extract) {
                auto lval = extract->dest->to<IR::BFN::FieldLVal>();
                if (!lval) return;
                auto dest = lval->field->toString();
                if (!extract->source->is<IR::BFN::ComputedRVal>()) {
                    defs[dest] = ParserRValDef(state, extract->source); }
            });

        // If the source of this extract is a computed r-value, its
        // expression may use a definition we've seen. Try to simplify it.
        // (And regardless of our success, record the new definition for
        // `dest`.)
        forAllMatching<IR::BFN::Extract>(
            &state->statements, [&](const IR::BFN::Extract* extract) {
                auto lval = extract->dest->to<IR::BFN::FieldLVal>();
                if (!lval) return;
                auto dest = lval->field->toString();
                if (auto* computed = extract->source->to<IR::BFN::ComputedRVal>()) {
                    propagateToUse(state, computed, defs);
                    defs[dest] = resolvedValues[computed].back(); }
            });

        // If the source of this select is a computed r-value, its
        // expression may use a definition we've seen. Try to simplify it.
        forAllMatching<IR::BFN::Select>(&state->selects,
                      [&](const IR::BFN::Select* select) {
            if (auto* computed = select->source->to<IR::BFN::ComputedRVal>())
                propagateToUse(state, computed, defs);
        });

        // Recursively propagate the definitions which have reached this point
        // to child states.
        for (auto* transition : state->transitions)
            propagateToState(transition->next,
                             updateOffsets(defs, *transition->shift));
    }
};

/// Replace computed value with rval if it has only one definition. Others will be saved
/// in the multiDefValues. After this pass, a computedRVal is either replaced, or it has an
/// entry in the multiDefValues.
struct ApplyParserValueResolutions : public ParserTransform {
    explicit ApplyParserValueResolutions(const ParserValueResolution& resolvedValues)
        : resolvedValues(resolvedValues) { }

 private:
    profile_t init_apply(const IR::Node* root) override {
        multiDefValues.clear();
        return Transform::init_apply(root);
    }

    IR::BFN::ParserRVal* preorder(IR::BFN::ComputedRVal* value) override {
        prune();
        auto* original = getOriginal<IR::BFN::ComputedRVal>();
        BUG_CHECK(resolvedValues.find(original) != resolvedValues.end(),
                  "No resolution for computed value: %1%", value);
        if (resolvedValues.at(original).size() == 1) {
            return resolvedValues.at(original).front().rval->clone();
        } else {
            // XXX(yumin): no change is made and returns same pointer,
            // save the original instead of the parameter.
            multiDefValues[original] = resolvedValues.at(original);
            return value; }
    }

    const ParserValueResolution& resolvedValues;

 public:
    ParserValueResolution multiDefValues;
};

class CheckResolvedParserExpressions : public ParserTransform {
    const IR::BFN::Extract*
    checkExtractDestination(const IR::BFN::Extract* extract) const {
        auto lval = extract->dest->to<IR::BFN::FieldLVal>();
        if (!lval) return extract;
        if (!lval->field->is<IR::HeaderStackItemRef>()) return extract;

        auto* itemRef = lval->field->to<IR::HeaderStackItemRef>();
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

        auto* stack = lval->field->to<IR::HeaderStackItemRef>()->base();
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

    profile_t init_apply(const IR::Node* root) override {
        updatedDefValues.clear();
        return Transform::init_apply(root);
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
        if (!select->source->is<IR::BFN::ComputedRVal>())
            return select;

        auto* original = getOriginal<IR::BFN::Select>()->source->to<IR::BFN::ComputedRVal>();
        if (!multiDefValues.count(original)) {
            ::error("Couldn't resolve computed value for select in state %1%: %2%",
                    findContext<IR::BFN::ParserState>()->name,
                    original->source);
            return nullptr;
        }

        // Update mapping.
        auto* newComputed = select->source->to<IR::BFN::ComputedRVal>();
        updatedDefValues[newComputed] = {};
        for (const auto& def : multiDefValues.at(original)) {
                // Ignore computedRval as definition of a use,
                // because it means resolution failed to find a defintion
                // for this select on some path.
                if (def.rval->is<IR::BFN::BufferlikeRVal>()) {
                    updatedDefValues[newComputed].push_back(def); } }

        if (LOGGING(4)) {
            LOG4("Found computed value with multiple possible data source: ");
            for (const auto& def : multiDefValues.at(original)) {
                LOG4("State: " << def.state->name << ", Rval: " << def.rval); } }

        return select;
    }

 public:
    explicit CheckResolvedParserExpressions(const ParserValueResolution& multiDefValues)
        : multiDefValues(multiDefValues) { }

    const ParserValueResolution& multiDefValues;
    ParserValueResolution updatedDefValues;
};

class ResolveComputedValues : public PassManager {
 public:
    ResolveComputedValues() {
        // XXX(yumin): both applyResolution and checkResolved may change IR, so multiDefValues
        // are updated in visitFunctor by the new values produced by each pass.
        auto* copyPropagate   = new CopyPropagateParserValues();
        auto* applyResolution = new ApplyParserValueResolutions(copyPropagate->resolvedValues);
        auto* checkResolved   = new CheckResolvedParserExpressions(multiDefValues);
        addPasses({
            copyPropagate,
            applyResolution,
            new VisitFunctor([this, applyResolution] () {
                multiDefValues = applyResolution->multiDefValues; }),
            checkResolved,
            new VisitFunctor([this, checkResolved] () {
                multiDefValues = checkResolved->updatedDefValues; }),
        });
    }

    ParserValueResolution multiDefValues;
};

class CheckResolvedHeaderStackExpressions : public ParserInspector {
    bool preorder(const IR::BFN::UnresolvedStackRef* stackRef) {
        ::error("Couldn't resolve header stack reference in state %1%: %2%",
                findContext<IR::BFN::ParserState>()->name, stackRef);
        return false;
    }
};

}  // namespace

ResolveComputedParserExpressions::ResolveComputedParserExpressions() :
    Logging::PassManager("parser", true /* append */) {
    auto* resolveComputedValues = new ResolveComputedValues();
    addPasses({
        new VerifyAssignedShifts,
        new ResolveNextAndLast,
        new VerifyParserRValsAreUnique,
        new VerifyStateNamessAreUnique,
        resolveComputedValues,
        new AllocateParserMatchRegisters(resolveComputedValues->multiDefValues),
    });
}

ResolveComputedHeaderStackExpressions::ResolveComputedHeaderStackExpressions() :
    Logging::PassManager("parser", true /* append */) {
    addPasses({
        new VerifyAssignedShifts,
        new ResolveNextAndLast,
        new CheckResolvedHeaderStackExpressions
    });
}
