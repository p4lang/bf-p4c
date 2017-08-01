/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "tofino/parde/resolve_computed.h"

#include <boost/optional.hpp>

#include "frontends/p4/callGraph.h"
#include "tofino/common/machine_description.h"
#include "tofino/parde/parde_visitor.h"

namespace {

class VerifyAssignedShifts : public ParserInspector {
    bool preorder(const IR::Tofino::ParserMatch* match) override {
        BUG_CHECK(match->shift,
                  "Parser match in state %1% was not assigned a shift",
                  findContext<IR::Tofino::ParserState>()->name);
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
    const IR::Tofino::UnresolvedStackRef*
    makeUniqueStackRef(const IR::Tofino::UnresolvedStackRef* ref) {
        if (visitedRefIds.find(ref->id) == visitedRefIds.end()) {
            visitedRefIds.insert(ref->id);
            return ref;
        }
        auto* freshRef = ref->makeFresh();
        BUG_CHECK(*freshRef != *ref, "Fresh ref isn't fresh?");
        visitedRefIds.insert(freshRef->id);
        return freshRef;
    }

    const IR::Tofino::ParserState*
    preorder(IR::Tofino::ParserState* state) override {
        for (unsigned i = 0; i < state->select.size(); i++) {
            state->select[i] =
                transformAllMatching<IR::Tofino::UnresolvedStackRef>(state->select[i],
                                    [&](IR::Tofino::UnresolvedStackRef* ref) {
                return makeUniqueStackRef(ref);
            })->to<IR::Tofino::TransitionPrimitive>();
        }
        return state;
    }

    const IR::Tofino::ParserMatch*
    preorder(IR::Tofino::ParserMatch* match) override {
        for (unsigned i = 0; i < match->stmts.size(); i++) {
            match->stmts[i] =
                transformAllMatching<IR::Tofino::UnresolvedStackRef>(match->stmts[i],
                                    [&](IR::Tofino::UnresolvedStackRef* ref) {
                return makeUniqueStackRef(ref);
            })->to<IR::Tofino::ParserPrimitive>();
        }
        return match;
    }

    std::set<size_t> visitedRefIds;
};

using HeaderStackItemRefIndices =
  std::map<const IR::HeaderStackItemRef*, const IR::Expression*>;

struct ResolveStackRefs : public ParserInspector {
    HeaderStackItemRefIndices resolvedIndices;

 private:
    using ExtractedStackIndices = std::map<cstring, bitvec>;

    bool preorder(const IR::Tofino::Parser* parser) override {
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

    void updateExtractedIndices(const IR::Tofino::Extract* extract,
                                ExtractedStackIndices& map) const {
        // Is this a write to a header stack item POV bit?
        if (!extract->is<IR::Tofino::ExtractConstant>()) return;
        if (!extract->dest->is<IR::Member>()) return;
        auto* member = extract->dest->to<IR::Member>();
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
        if (!ref->index()->is<IR::Tofino::UnresolvedStackRef>()) {
            resolvedIndices[ref] = ref->index();
            return;
        }

        const IR::Constant* resolvedIndex = nullptr;
        if (ref->index()->is<IR::Tofino::UnresolvedStackNext>()) {
            resolvedIndex = new IR::Constant(nextIndex(ref, map));
        } else if (ref->index()->is<IR::Tofino::UnresolvedStackLast>()) {
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
            BUG_CHECK(previousResolution->is<IR::Tofino::UnresolvedStackRef>(),
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

    void resolveForState(const IR::Tofino::ParserState* state,
                         const ExtractedStackIndices& map) {
        if (!state) return;

        // XXX(seth): It seems obvious to me that the contents of the matches
        // should not logically be in scope for the select, but that's how the
        // IR is currently designed. Saving `newMap` for use when resolving the
        // selects below is just a hack until we've had a chance to rethink
        // this.
        ExtractedStackIndices* newMap = nullptr;
        for (auto* match : state->match) {
            newMap = new ExtractedStackIndices(map);
            resolveForMatch(match, *newMap);
        }

        forAllMatching<IR::HeaderStackItemRef>(&state->select,
                      [&](const IR::HeaderStackItemRef* ref) {
            resolve(ref, newMap ? *newMap : map);
        });
    }

    void resolveForMatch(const IR::Tofino::ParserMatch* match,
                         ExtractedStackIndices& map) {
        forAllMatching<IR::Tofino::Extract>(&match->stmts,
                      [&](const IR::Tofino::Extract* extract) {
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

        resolveForState(match->next, map);
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

class VerifyParserPrimitivesAreUnique : public ParserInspector {
    bool preorder(const IR::Tofino::ParserState* state) override {
        forAllMatching<IR::Tofino::TransitionPrimitive>(&state->select,
                      [&](const IR::Tofino::TransitionPrimitive* prim) {
            BUG_CHECK(visitedTransitionPrims.find(prim) == visitedTransitionPrims.end(),
                      "Transition primitive appears in more than one place: %1%",
                      prim);
            visitedTransitionPrims.insert(prim);
        });

        // We can't require that parser primitives are unique within a state,
        // because every ParserMatch in a state contains the same sequence of
        // primitives. (Before optimizations are applied, at least.) We *can*,
        // however, require that no parser primitive appears in more than one
        // state.
        // XXX(seth): We should probably rethink this design, or at least clone
        // the primitives for each ParserMatch.
        std::set<const IR::Tofino::ParserPrimitive*> parserPrimsInState;
        for (auto* match : state->match) {
            forAllMatching<IR::Tofino::ParserPrimitive>(&match->stmts,
                          [&](const IR::Tofino::ParserPrimitive* prim) {
                parserPrimsInState.insert(prim);
            });
        }
        for (auto* prim : parserPrimsInState) {
            BUG_CHECK(visitedParserPrims.find(prim) == visitedParserPrims.end(),
                      "Parser primitive appears in more than one place: %1%",
                      prim);
            visitedParserPrims.insert(prim);
        }

        return true;
    }

    std::set<const IR::Tofino::TransitionPrimitive*> visitedTransitionPrims;
    std::set<const IR::Tofino::ParserPrimitive*> visitedParserPrims;
};

using ComputedExtractResolution = std::map<const IR::Tofino::ExtractComputed*,
                                           const IR::Tofino::Extract*>;
using ComputedSelectResolution = std::map<const IR::Tofino::SelectComputed*,
                                          const IR::Tofino::Select*>;

struct ResolveComputedParserPrimitives : public ParserInspector {
    ComputedExtractResolution resolvedExtracts;
    ComputedSelectResolution resolvedSelects;

 private:
    using ExtractMap = std::map<cstring, const IR::Tofino::Extract*>;

    bool preorder(const IR::Tofino::Parser* parser) override {
        ExtractMap initialMap;
        resolveForState(parser->start, initialMap);
        return false;
    }

    ExtractMap updateOffsets(const ExtractMap& map, int byteShift) {
        if (byteShift == 0) return map;

        ExtractMap updated;
        for (auto& item : map) {
            auto dest = item.first;
            auto* extract = item.second;

            // Extracts that don't come from the buffer don't need to change.
            if (!extract->is<IR::Tofino::ExtractBuffer>()) {
                updated[dest] = extract;
                continue;
            }

            // Extracts from the input buffer need their offsets to be shifted
            // to the left to compensate for the fact that the transition is
            // shifting the input buffer to the right.
            auto* extractBuffer = extract->to<IR::Tofino::ExtractBuffer>();
            auto* clone = extractBuffer->clone();
            clone->bitOffset -= byteShift * 8;
            updated[dest] = clone;
        }
        return updated;
    }

    void resolveExtract(const IR::Tofino::ExtractComputed* extract,
                        ExtractMap& map) {
        auto sourceName = extract->source->toString();
        if (map.find(sourceName) == map.end()) {
            // "Resolve" to the original ExtractComputed, indicating failure.
            resolvedExtracts[extract] = extract->clone();
            return;
        }

        // There's an existing extract for this source. Forward it here. (We're
        // essentially doing copy propagation.)
        auto* sourceExtract = map[sourceName];
        auto* resolvedExtract = sourceExtract->clone();
        resolvedExtract->dest = extract->dest;

        // If there was no previous resolution, we know we're OK.
        if (resolvedExtracts.find(extract) == resolvedExtracts.end()) {
            resolvedExtracts[extract] = resolvedExtract;
            map[extract->dest->toString()] = resolvedExtract;
            return;
        }

        // There was a previous resolution. Make sure it matches. For the
        // generated code to be correct, we need to ensure that we get the same
        // resolution no matter what path we take to reach this point.
        auto* previousResolution = resolvedExtracts[extract];
        if (previousResolution->is<IR::Tofino::ExtractComputed>()) {
            return;  // We already failed; keep it that way.
        }

        if (*previousResolution != *resolvedExtract) {
            ::error("Cannot resolve computed extract unambiguously: %1%", extract);
            // "Resolve" to the original ExtractComputed, indicating failure.
            resolvedExtracts[extract] = extract;
            map[extract->dest->toString()] = extract->clone();
            return;
        }
    }

    void resolveSelect(const IR::Tofino::SelectComputed* select,
                       const ExtractMap& map) {
        auto* resolvedSelect = [&]() -> const IR::Tofino::Select* {
            auto sourceName = select->source->toString();
            if (map.find(sourceName) == map.end()) {
                ::error("Cannot resolve computed select: %1%", select);
                // "Resolve" to the original SelectComputed, indicating failure.
                return select;
            }

            // There's an existing extract for this source. Forward it here.
            auto* resolvedExtract = map.at(sourceName)->to<IR::Tofino::ExtractBuffer>();
            if (!resolvedExtract) {
                ::warning("Couldn't resolve select %1% to unsupported source: %2%",
                          select, resolvedExtract);
                // "Resolve" to the original SelectComputed, indicating failure.
                return select;
            }
            return new IR::Tofino::SelectBuffer(resolvedExtract->extractedBits(),
                                                resolvedExtract->dest);
        }();

        // If there was no previous resolution, we know we're OK.
        if (resolvedSelects.find(select) == resolvedSelects.end()) {
            resolvedSelects[select] = resolvedSelect;
            return;
        }

        // There was a previous resolution. Make sure it matches. For the
        // generated code to be correct, we need to ensure that we get the same
        // resolution no matter what path we take to reach this point.
        auto* previousResolution = resolvedSelects[select];
        if (*previousResolution != *resolvedSelect) {
            ::error("Cannot resolve computed select unambiguously: %1%", select);
            // "Resolve" to the original SelectComputed, indicating failure.
            resolvedSelects[select] = select;
            return;
        }
    }

    void resolveForState(const IR::Tofino::ParserState* state,
                         const ExtractMap& map) {
        if (!state) return;

        // XXX(seth): It seems obvious to me that the contents of the matches
        // should not logically be in scope for the select, but that's how the
        // IR is currently designed. Saving `newMap` for use when resolving the
        // selects below is just a hack until we've had a chance to rethink
        // this.
        ExtractMap* newMap = nullptr;
        for (auto* match : state->match) {
            newMap = new ExtractMap(map);
            resolveForMatch(match, *newMap);
        }

        forAllMatching<IR::Tofino::SelectComputed>(&state->select,
                      [&](const IR::Tofino::SelectComputed* select) {
            resolveSelect(select, newMap ? *newMap : map);
        });
    }

    void resolveForMatch(const IR::Tofino::ParserMatch* match,
                         ExtractMap& map) {
        forAllMatching<IR::Tofino::Extract>(&match->stmts,
                      [&](const IR::Tofino::Extract* extract) {
            if (extract->is<IR::Tofino::ExtractComputed>()) {
                resolveExtract(extract->to<IR::Tofino::ExtractComputed>(), map);
                return;
            }
            map[extract->dest->toString()] = extract;
        });

        resolveForState(match->next, updateOffsets(map, *match->shift));
    }
};

struct ApplyPrimitiveResolutions : public ParserTransform {
    ApplyPrimitiveResolutions(const ComputedExtractResolution& resolvedExtracts,
                              const ComputedSelectResolution& resolvedSelects)
      : resolvedExtracts(resolvedExtracts), resolvedSelects(resolvedSelects) { }

 private:
    IR::Tofino::Extract* preorder(IR::Tofino::ExtractComputed* extract) override {
        prune();
        auto* original = getOriginal<IR::Tofino::ExtractComputed>();
        BUG_CHECK(resolvedExtracts.find(original) != resolvedExtracts.end(),
                  "No resolution for computed extract: %1%", extract);
        return resolvedExtracts.at(original)->clone();
    }

    IR::Tofino::Select* preorder(IR::Tofino::SelectComputed* select) override {
        prune();
        auto* original = getOriginal<IR::Tofino::SelectComputed>();
        BUG_CHECK(resolvedSelects.find(original) != resolvedSelects.end(),
                  "No resolution for computed select: %1%", select);
        return resolvedSelects.at(original)->clone();
    }

    const ComputedExtractResolution& resolvedExtracts;
    const ComputedSelectResolution& resolvedSelects;
};

class ResolveComputedExtracts : public PassManager {
 public:
    ResolveComputedExtracts() {
        auto* computeResolution = new ResolveComputedParserPrimitives;
        addPasses({
            computeResolution,
            new ApplyPrimitiveResolutions(computeResolution->resolvedExtracts,
                                          computeResolution->resolvedSelects)
        });
    }
};

using OffsetCorrections = std::map<const IR::Node*, int>;
using ShiftCorrections = std::map<const IR::Tofino::ParserMatch*, int>;

class ComputeOffsetCorrections : public ParserInspector {
 public:
    ComputeOffsetCorrections() : transitions("transitions") { }

    OffsetCorrections bitOffsetCorrections;
    ShiftCorrections byteShiftCorrections;

 private:
    Visitor::profile_t init_apply(const IR::Node* node) override {
        forAllMatching<IR::Tofino::ParserMatch>(node,
                      [&](const IR::Tofino::ParserMatch* match) {
            if (match->next) transitions.calls(match, match->next);
        });
        return ParserInspector::init_apply(node);
    }

    void postorder(const IR::Tofino::ParserState* state) override {
        // Find the minimum negative offset used in this state. This tells us
        // how far back in the input buffer we need to move this state so that
        // all offsets are positive. Note that we take any shift corrections
        // that were already computed by our successor states into account.
        int bitMinOffset = 0;
        forAllMatching<IR::Tofino::SelectBuffer>(&state->select,
                      [&](const IR::Tofino::SelectBuffer* select) {
            bitMinOffset = std::min(bitMinOffset, select->bitOffset);
        });
        for (auto* match : state->match) {
            forAllMatching<IR::Tofino::ExtractBuffer>(&match->stmts,
                          [&](const IR::Tofino::ExtractBuffer* extract) {
                bitMinOffset = std::min(bitMinOffset, extract->bitOffset);
            });
            BUG_CHECK(byteShiftCorrections[match] <= 0,
                      "Computed a positive shift correction?");
            auto byteCorrectedShift = *match->shift + byteShiftCorrections[match];
            bitMinOffset = std::min(bitMinOffset, byteCorrectedShift * 8);
        }

        // We can only shift by whole bytes, so convert to bytes to determine
        // the final correction. This correction can be interpreted two ways:
        //  (1) It tells us how much to *increase* all of the offsets and shifts
        //      in this state so that they'll refer to the correct range of bits
        //      in the input buffer after the correction is applied.
        //  (2) It tells us how much to *reduce* the shifts that are applied on
        //      the transitions (i.e., ParserMatches) that lead into this state.
        //      That reduction may actually make those shifts negative, requiring
        //      us to fix the offsets in that state as well. That's why this is
        //      a bottom-up analysis.
        // All of these changes will be applied in ApplyOffsetCorrections.
        const int byteShiftCorrection = (-bitMinOffset + 7) / 8;
        const int bitOffsetCorrection = byteShiftCorrection * 8;

        // Increase offsets and shifts.
        bitOffsetCorrections[state] = bitOffsetCorrection;
        for (auto* match : state->match)
            byteShiftCorrections[match] += byteShiftCorrection;

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
            BUG_CHECK(caller->is<IR::Tofino::ParserMatch>(),
                      "A non-ParserMatch calls a ParserState?");
            auto* match = caller->to<IR::Tofino::ParserMatch>();
            BUG_CHECK(byteShiftCorrections[match] == 0,
                      "Already corrected this ParserMatch's shift?");
            byteShiftCorrections[match] = -byteShiftCorrection;
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
    void postorder(IR::Tofino::SelectBuffer* select) override {
        auto* state = findOrigCtxt<IR::Tofino::ParserState>();
        BUG_CHECK(bitOffsetCorrections.find(state) != bitOffsetCorrections.end(),
                  "No offset correction entries for state %1%", state->name);
        select->bitOffset += bitOffsetCorrections.at(state);
        BUG_CHECK(select->bitOffset >= 0, "Failed to correct offset?");
    }

    void postorder(IR::Tofino::ExtractBuffer* extract) override {
        auto* state = findOrigCtxt<IR::Tofino::ParserState>();
        BUG_CHECK(bitOffsetCorrections.find(state) != bitOffsetCorrections.end(),
                  "No offset correction entries for state %1%", state->name);
        extract->bitOffset += bitOffsetCorrections.at(state);
        BUG_CHECK(extract->bitOffset >= 0, "Failed to correct offset?");
    }

    void postorder(IR::Tofino::ParserMatch* match) override {
        auto* original = getOriginal<IR::Tofino::ParserMatch>();
        BUG_CHECK(byteShiftCorrections.find(original) != byteShiftCorrections.end(),
                  "No shift correction entries for match in state %1%",
                  findContext<IR::Tofino::ParserState>()->name);
        *match->shift += byteShiftCorrections.at(original);
        BUG_CHECK(*match->shift >= 0, "Failed to correct shift?");
    }

    const std::map<const IR::Node*, int>& bitOffsetCorrections;
    const std::map<const IR::Tofino::ParserMatch*, int>& byteShiftCorrections;
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
    bool preorder(const IR::Tofino::UnresolvedStackRef* stackRef) {
        ::error("Couldn't resolve header stack reference in state %1%: %2%",
                findContext<IR::Tofino::ParserState>()->name, stackRef);
        return false;
    }
};

class CheckResolvedParserExpressions : public ParserTransform {
    const IR::Tofino::ParserPrimitive*
    checkExtractDestination(IR::Tofino::Extract* extract) const {
        if (!extract->dest->is<IR::HeaderStackItemRef>()) return extract;
        auto* itemRef = extract->dest->to<IR::HeaderStackItemRef>();
        if (itemRef->index()->is<IR::Tofino::UnresolvedStackRef>()) {
            ::error("Couldn't resolve header stack reference in state %1%: %2%",
                    findContext<IR::Tofino::ParserState>()->name, extract);
            return new IR::Tofino::UnhandledParserPrimitive(extract);
        }
        if (!itemRef->index()->is<IR::Constant>()) {
            ::error("Extracting to non-constant header stack index in "
                    "state %1%: %2%",
                    findContext<IR::Tofino::ParserState>()->name, extract);
            return new IR::Tofino::UnhandledParserPrimitive(extract);
        }
        auto* stack = extract->dest->to<IR::HeaderStackItemRef>()->base();
        auto stackSize = stack->type->to<IR::Type_Stack>()
                              ->size->to<IR::Constant>()->asInt();
        if (itemRef->index()->to<IR::Constant>()->asInt() >= stackSize) {
            // XXX(seth): This should actually be an error, but before making
            // that change we need to make loop unrolling handle header stacks
            // more precisely.
            ::warning("Extract overflows header stack in state %1%: %2%",
                      findContext<IR::Tofino::ParserState>()->name, extract);
            // Just clamp it; the hardware will report an error at runtime.
            auto* itemRefClone = itemRef->clone();
            itemRefClone->index_ = new IR::Constant(std::max(stackSize - 1, 0));
            auto* clone = extract->clone();
            clone->dest = itemRefClone;
            return clone;
        }
        return extract;
    }

    const IR::Tofino::ParserPrimitive*
    preorder(IR::Tofino::ExtractComputed* extract) override {
        ::error("Couldn't resolve computed extract in state %1%: %2%",
                findContext<IR::Tofino::ParserState>()->name, extract);
        return new IR::Tofino::UnhandledParserPrimitive(extract);
    }

    const IR::Tofino::ParserPrimitive*
    preorder(IR::Tofino::ExtractBuffer* extract) override {
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
        auto* match = findContext<IR::Tofino::ParserMatch>();
        const int byteOverflow = extract->bitInterval().hiByte() - *match->shift;
        if (byteOverflow < Tofino::Description::ByteInputBufferSize)
            return checkExtractDestination(extract);

        ::error("Extract in state %1% requires reading %2% bytes ahead, which "
                "is beyond %3%'s limit of %4% bytes: %5%",
                findContext<IR::Tofino::ParserState>()->name, byteOverflow,
                Tofino::Description::ModelName,
                Tofino::Description::ByteInputBufferSize, extract);

        // The most likely cause is that RemoveNegativeOffsets had to put off
        // shifting so long that we ran out of runway in the input buffer.
        ::error("(Does your parser read or select on a value which originated "
                "in a much earlier state?)");

        return new IR::Tofino::UnhandledParserPrimitive(extract);
    }

    const IR::Tofino::ParserPrimitive*
    preorder(IR::Tofino::Extract* extract) override {
        return checkExtractDestination(extract);
    }

    const IR::Tofino::TransitionPrimitive*
    preorder(IR::Tofino::SelectComputed* select) override {
        ::error("Couldn't resolve computed select in state %1%: %2%",
                findContext<IR::Tofino::ParserState>()->name, select);
        return new IR::Tofino::UnhandledTransitionPrimitive(select);
    }
};

}  // namespace

ResolveComputedParserExpressions::ResolveComputedParserExpressions() {
    addPasses({
        new VerifyAssignedShifts,
        new ResolveNextAndLast,
        new VerifyParserPrimitivesAreUnique,
        new ResolveComputedExtracts,
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
