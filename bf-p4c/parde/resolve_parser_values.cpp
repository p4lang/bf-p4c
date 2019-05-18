#include "bf-p4c/parde/resolve_parser_values.h"

#include <boost/optional.hpp>
#include <boost/range/adaptors.hpp>
#include <limits>

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

// Need to ensure that every distinct UnresolvedStackRef is in fact a distinct Node,
// but cannot clone any ParserState.
// XXX(seth): You'd ideally do this when actually constructing the parser IR,
// but I hesitate to rely on that since code elsewhere may mutate it and
// establishing this invariant is critical for the correctness of
// ResolveStackRefs.
class MakeUnresolvedStackRefsUnique : public ParserTransform {
    const IR::BFN::UnresolvedStackRef*
    preorder(IR::BFN::UnresolvedStackRef* ref) override {
        if (visitedRefIds.count(ref->id))
            ref->makeFresh();
        visitedRefIds.insert(ref->id);
        return ref; }

    const IR::BFN::ParserState*
    preorder(IR::BFN::ParserState* state) override {
        visitOnce();
        return state; }

    std::set<size_t> visitedRefIds;

 public:
    MakeUnresolvedStackRefsUnique() { visitDagOnce = false; }
};

using HeaderStackItemRefIndices =
  std::map<const IR::HeaderStackItemRef*, const IR::Expression*>;

struct ResolveStackRefs : public ParserInspector, ControlFlowVisitor {
    HeaderStackItemRefIndices &resolvedIndices;
    explicit ResolveStackRefs(HeaderStackItemRefIndices &ri) : resolvedIndices(ri) {
        joinFlows = true; }

 private:
    int id;
    static int id_ctr;
    struct IndexState {
        bitvec  valid;          // indices that are valid or indeterminate
        bitvec  unknown;        // indices that are indeterminate
                                // 'unknown' will always be a subset of 'valid'
    };
    std::map<cstring, IndexState>       stack_state;
    ResolveStackRefs *clone() const override {
        auto *rv = new ResolveStackRefs(*this);
        rv->id = ++id_ctr;
        LOG7("  clone " << id << " -> " << rv->id);
        return rv; }
    void flow_merge(Visitor &other_) override {
        auto &other = dynamic_cast<ResolveStackRefs &>(other_);
        LOG7("  flow_merge " << other.id << " -> " << id);
        for (auto &el : other.stack_state) {
            auto &state = stack_state[el.first];
            auto &other_state = el.second;
            state.unknown |= other_state.unknown;
            state.unknown |= other_state.valid ^ state.valid;
            state.valid |= state.unknown; }
        for (auto &el : stack_state)
            if (!other.stack_state.count(el.first))
                el.second.unknown |= el.second.valid; }

    profile_t init_apply(const IR::Node *root) override {
        resolvedIndices.clear();
        id = id_ctr = 0;
        return ParserInspector::init_apply(root); }
    bool filter_join_point(const IR::Node *n) override { return !n->is<IR::BFN::ParserState>(); }

    bool preorder(const IR::BFN::Parser *parser) override {
        stack_state.clear();  // each parser is independent and CANNOT share states
        LOG3(id << ":ResolveStackRefs for "<< parser->toString() << parser <<
             " start=" << parser->start->name);
        return true; }
    bool preorder(const IR::BFN::ParserState *state) override {
        LOG4(id << ":visit state " << state->name << IndentCtl::indent);
        return true; }
    void postorder(const IR::BFN::ParserState *) override {
        if (LOGGING(4))
            ::Log::Detail::fileLogOutput(__FILE__) << IndentCtl::unindent;
    }

    unsigned nextIndex(const IR::HeaderStackItemRef* ref) const {
        const auto stackName = ref->base()->toString();

        // If we haven't yet extracted any item in the header stack, the first
        // index is the next one to track.
        if (!stack_state.count(stackName)) return 0;

        // The `next` property evaluates to the first index in the stack with an
        // unset valid bit. (i.e., the first item that hasn't yet been extracted)
        const auto& extractedIndices = stack_state.at(stackName);
        if (!extractedIndices.unknown.empty()) {
            auto *state = findContext<IR::BFN::ParserState>();
            error("%sInconsisten index for next of %s in state %s", ref->srcInfo,
                  stackName, state); }
        return extractedIndices.valid.ffz();
    }

    boost::optional<unsigned> lastIndex(const IR::HeaderStackItemRef* ref) {
        const auto stackName = ref->base()->toString();

        // The `last` property is a partial function; it's an error to evaluate
        // it before you've extracted any item in the header stack.
        if (stack_state[stackName].valid.empty()) return boost::none;

        // The `last` property evaluates to the last index in the stack with a
        // set valid bit.
        const auto& extractedIndices = stack_state.at(stackName);
        auto last = *extractedIndices.valid.max();
        if (extractedIndices.unknown[last]) {
            auto *state = findContext<IR::BFN::ParserState>();
            error("%sInconsisten index for last of %s in state %s", ref->srcInfo,
                  stackName, state); }
        return last;
    }

    void postorder(const IR::BFN::Extract *extract) override {
        // Is this a write to a header stack item POV bit?
        auto crval = extract->source->to<IR::BFN::ConstantRVal>();
        if (!crval) return;
        auto lval = extract->dest->to<IR::BFN::FieldLVal>();
        if (!lval) return;
        if (!lval->field->is<IR::Member>()) return;
        auto* member = lval->field->to<IR::Member>();
        if (member->member != "$valid") return;
        if (!member->expr->is<IR::HeaderStackItemRef>()) return;

        // If so, we just finished extracting the corresponding header stack
        // item, or just invalidated it. Figure out the index and update the stack_state.
        auto* ref = member->expr->to<IR::HeaderStackItemRef>();
        BUG_CHECK(resolvedIndices.find(ref) != resolvedIndices.end(),
                  "Didn't resolve header stack index for POV bit?");
        auto* index = resolvedIndices.at(ref);
        if (!index->is<IR::Constant>()) {
            return;
        }
        LOG4(id << ": " << DBPrint::Prec_Low << DBPrint::Brief << extract <<
             " -> [" << index << "]" << DBPrint::Reset);
        auto intIndex = std::max(index->to<IR::Constant>()->asInt(), 0);
        auto stackName = ref->base()->toString();
        stack_state[stackName].valid[intIndex] = crval->constant->value != 0;
        stack_state[stackName].unknown[intIndex] = 0;
    }

    void postorder(const IR::HeaderStackItemRef* ref) override {
        // Explicit references to a specific header stack index are trivial; we
        // just resolve them to the specified index.
        if (!ref->index()->is<IR::BFN::UnresolvedStackRef>()) {
            resolvedIndices[ref] = ref->index();
            return;
        }

        const IR::Constant* resolvedIndex = nullptr;
        if (ref->index()->is<IR::BFN::UnresolvedStackNext>()) {
            resolvedIndex = new IR::Constant(nextIndex(ref));
        } else if (ref->index()->is<IR::BFN::UnresolvedStackLast>()) {
            auto last = lastIndex(ref);
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
};

int ResolveStackRefs::id_ctr;

struct AssignNextAndLast : public ParserModifier {
    explicit AssignNextAndLast(const HeaderStackItemRefIndices &resolvedIndices)
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
    HeaderStackItemRefIndices resolvedIndices;
    ResolveNextAndLast() {
        addPasses({
            new MakeUnresolvedStackRefsUnique,
            new ResolveStackRefs(resolvedIndices),
            new AssignNextAndLast(resolvedIndices)
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
    bool preorder(const IR::BFN::Parser *parser) override {
        visitedNames.clear();  // each parser is independent and CANNOT share states
        LOG3("VerifyStateNamessAreUnique for "<< parser->toString() << parser <<
                " start=" << parser->start->name);
        return true; }

    bool preorder(const IR::BFN::ParserState* state) override {
        cstring name = cstring::to_cstring(state->gress) + state->name;
        BUG_CHECK(visitedNames.count(name) == 0,
                  "Duplicated parser state name appears: %1%", name);
        visitedNames.insert(name);
        return false;
    }

    std::set<cstring> visitedNames;
};

/// Represent a ParserRval and the state where it is defined.
/// null element represents uninitialized
struct ParserRValDef {
    const IR::BFN::ParserState* state = nullptr;
    const IR::BFN::ParserRVal* rval = nullptr;
    ParserRValDef() {}
    ParserRValDef(const IR::BFN::ParserState* state,
                  const IR::BFN::ParserRVal* rval)
        : state(state), rval(rval) { }
    bool operator==(const ParserRValDef &a) const {
        return state == a.state &&
               rval ? a.rval ? rval->equiv(*a.rval) : false : a.rval == nullptr; }
    bool operator!=(const ParserRValDef &a) const { return !operator==(a); }
};

/// A mapping from a saved r-value to the r-values we evaluated it to.
/// For one savedRVal, it can have multiple definition parserRVal.
using ParserValueResolution =
    std::map<const IR::BFN::SavedRVal*, std::vector<ParserRValDef>>;

/**
 * Walk the parser programs (each thread is treated separately) and try to
 * simplify r-values by replacing any uses of l-values with their definition.
 *
 * @pre Every `ParserRVal` in each of the parser programs is a unique object.
 * @post Any `SavedRVal` which can either be evaluated unambiguously to a simple
 * r-value (i.e. a `PacketRVal` or `ConstantRVal`), or remain the same but have a mapping
 * that maps it to multiple place that it were defined, only if it is for select. Any
 * `SavedRVal` which remains (without having a mapping) is either too complex to
 *  evaluate, or contains uses of l-values that were not reached by any definition at all.
 */
struct CopyPropagateParserValues : public ParserInspector, ControlFlowVisitor {
    ParserValueResolution &resolvedValues;

 private:
    int id;
    static int id_ctr;
    /// A map from l-values (identified by strings) to the r-value(s) most recently
    /// assigned to them.  Can't use a set because we don't have IR::Node::operator< (yet?)
    std::map<cstring, std::vector<ParserRValDef>> reachingDefs;
    void addReachingDef(std::vector<ParserRValDef> &set, const ParserRValDef &rvd) {
        if (std::find(set.begin(), set.end(), rvd) == set.end())
            set.push_back(rvd); }
    void setReachingDefs(std::vector<ParserRValDef> &set, const ParserRValDef &rvd) {
        set.clear();
        set.push_back(rvd); }
    CopyPropagateParserValues *clone() const override {
        auto rv = new CopyPropagateParserValues(*this);
        rv->id = ++id_ctr;
        LOG7("  clone " << id << " -> " << rv->id);
        return rv; }
    void flow_merge(Visitor &other_) override {
        auto &other = dynamic_cast<CopyPropagateParserValues &>(other_);
        // FIXME -- use erase_if (currently in table_placement.cpp)
        LOG7("  flow_merge " << other.id << " -> " << id);
        for (auto &el : reachingDefs) {
            if (!other.reachingDefs.count(el.first)) {
                addReachingDef(el.second, ParserRValDef());
            } else {
                // FIXME O(n^2) in the set size to squeeze out duplicates, but not doing
                // so would give us O(2^n) vector size in the depth of the parser graph
                // really need IR::Node::operator< so we can use set merge.
                for (auto &rvd : other.reachingDefs.at(el.first))
                    addReachingDef(el.second, rvd); } }
        for (auto &el : other.reachingDefs) {
            if (!reachingDefs.count(el.first)) {
                auto &add = reachingDefs[el.first] = el.second;
                addReachingDef(add, ParserRValDef()); } } }
    bool filter_join_point(const IR::Node *n) override { return !n->is<IR::BFN::ParserState>(); }


    profile_t init_apply(const IR::Node *root) override {
        resolvedValues.clear();
        id = id_ctr = 0;
        return Inspector::init_apply(root);
    }

    bool preorder(const IR::BFN::Parser *parser) override {
        reachingDefs.clear();
        LOG3(id << ":CopyPropagateParserValues for "<< parser->toString() << parser <<
             " start=" << parser->start->name);
        return true;
    }

    bool preorder(const IR::BFN::Transition *trans) override {
        LOG5(id << ": " << IndentCtl::indent << trans << IndentCtl::unindent);
        BUG_CHECK(!!trans->shift, "shift not comuted yet?");
        if (*trans->shift == 0) return true;

        for (auto& def : reachingDefs) {
            for (auto &rvd : def.second) {
                // Values that don't come from the input packet don't need to
                // change; they're invariant under shifting.
                if (!rvd.rval->is<IR::BFN::PacketRVal>()) {
                    continue; }

                // Values from the input packet need their offsets to be shifted
                // to the left to compensate for the fact that the transition is
                // shifting the input buffer to the right.
                auto* clone = rvd.rval->to<IR::BFN::PacketRVal>()->clone();
                clone->range = clone->range.shiftedByBytes(-*trans->shift);
                rvd.rval = clone;
            }
        }
        return true;
    }

    bool preorder(const IR::BFN::ParserState *state) override {
        LOG4(id << ":visit state " << state->name << IndentCtl::indent);
        return true; }
    void postorder(const IR::BFN::ParserState *) override {
        if (LOGGING(4))
            ::Log::Detail::fileLogOutput(__FILE__) << IndentCtl::unindent;
    }

    void propagateToUse(const IR::BFN::ParserState* state,
                        const IR::BFN::SavedRVal* value) {
        LOG4(id << ":propagateToUse(" << state->name << ", " << value << ")");
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

        // Create a string representation of this saved value. We consider
        // values to be equal if they have the same string representation.
        auto sourceName = sourceExpr->toString();

        // Does some definition for this saved value reach this point?
        if (reachingDefs.find(sourceName) == reachingDefs.end()) {
            // No reaching definition; just "propagate" the original value.
            BUG_CHECK(!resolvedValues.count(value), "multiref to SavedRVal");
            ::error("Select on uninitialized value: %1%", value->source);
            return; }

        // We found some definitions; propagate them here.
        for (auto &rvalRef : reachingDefs.at(sourceName)) {
            if (rvalRef.state == nullptr) {
                resolvedValues[value].push_back(ParserRValDef(state, value->clone()));
                LOG1("Select on field that might be uninitialized "
                     "in some parser path: " << value->source);
                continue; }

            auto* resolvedValue = rvalRef.rval->clone();

            if (size_cast_to) {
                auto* buf = resolvedValue->to<IR::BFN::InputBufferRVal>();
                auto casted_range = buf->range.resizedToBits(*size_cast_to);
                resolvedValue = new IR::BFN::PacketRVal(casted_range);
            }

            // If this use was wrapped in a slice, try to simplify it.
            // XXX(seth): Again, this will get replaced with something non-hacky
            // soon. For now, this gets us very basic slice support.
            if (outerSlice) {
                auto* bufferlikeValue =
                    dynamic_cast<IR::BFN::InputBufferRVal*>(resolvedValue);
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
                  sliceRange.toOrder<Endian::Network>(bufferlikeValue->range.size())
                            .shiftedByBits(bufferlikeValue->range.lo)
                            .intersectWith(bufferlikeValue->range);
                if (sliceOfValue.empty()) {
                    ::error("Saved value resolves to a zero-width slice: %1%",
                            value->source);
                    resolvedValues[value] = { ParserRValDef(state, value->clone()) };
                    return;
                }

                // Success; we've eliminated the slice.
                bufferlikeValue->range = *toClosedRange(sliceOfValue);
                resolvedValue = bufferlikeValue;
            }

            // If there's no other reaching definition, we know we're OK.
            if (resolvedValues.find(value) == resolvedValues.end()) {
                resolvedValues[value] = { ParserRValDef(rvalRef.state, resolvedValue) };
                continue;
            }

            // We've seen another definition already.
            auto& previousResolution = resolvedValues[value];

            // If the previous definition is a saved r-value, we've already
            // encountered some kind of failure; just keep it that way.
            if (previousResolution.size() == 1
                && previousResolution.front().rval->is<IR::BFN::SavedRVal>()) {
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
        return;
    }

    bool preorder(const IR::BFN::Extract *extract) override {
        if (auto lval = extract->dest->to<IR::BFN::FieldLVal>()) {
            auto dest = lval->field->toString();
            auto *state = findContext<IR::BFN::ParserState>();
            if (auto* saved = extract->source->to<IR::BFN::SavedRVal>()) {
                // If the source of this extract is a saved r-value, its
                // expression may use a definition we've seen. Try to simplify it.
                // (And regardless of our success, record the new definition for
                // `dest`.)
                propagateToUse(state, saved);
                setReachingDefs(reachingDefs[dest], resolvedValues[saved].back());
            } else {
                // The source is a simple r-value; just record the new definition
                // for `dest` and move on.
                setReachingDefs(reachingDefs[dest], ParserRValDef(state, extract->source)); }
            LOG4(id << ":reachingDefs[" << dest << "] = " << &reachingDefs[dest]); }
        return true; }

    bool preorder(const IR::BFN::Select *select) override {
        // If the source of this select is a saved r-value, its
        // expression may use a definition we've seen. Try to simplify it.
        if (auto* saved = select->source->to<IR::BFN::SavedRVal>())
            propagateToUse(findContext<IR::BFN::ParserState>(), saved);
        return true; }

 public:
    CopyPropagateParserValues() : resolvedValues(*new ParserValueResolution) { joinFlows = true; }
};

int CopyPropagateParserValues::id_ctr;

/// Replace saved value with rval if it has only one definition.
struct ApplyParserValueResolutions : public ParserTransform {
    explicit ApplyParserValueResolutions(const ParserValueResolution& resolvedValues)
        : resolvedValues(resolvedValues) { }

 private:
    profile_t init_apply(const IR::Node* root) override {
        return Transform::init_apply(root);
    }

    IR::BFN::ParserRVal* preorder(IR::BFN::SavedRVal* value) override {
        prune();
        auto* original = getOriginal<IR::BFN::SavedRVal>();
        BUG_CHECK(resolvedValues.find(original) != resolvedValues.end(),
                  "No resolution for saved value: %1%", value);
        auto &rval = resolvedValues.at(original);
        if (rval.size() == 1 && !rval.front().rval->is<IR::BFN::SavedRVal>()) {
            return rval.front().rval->clone();
        }
        return value;
    }

    const ParserValueResolution& resolvedValues;
};

class ResolveSavedValues : public PassManager {
 public:
    ResolveSavedValues() {
        auto* copyPropagate   = new CopyPropagateParserValues();
        auto* applyResolution = new ApplyParserValueResolutions(copyPropagate->resolvedValues);

        addPasses({
            copyPropagate,
            applyResolution,
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

}  // namespace

ResolveParserValues::ResolveParserValues() :
    Logging::PassManager("parser", Logging::Mode::AUTO) {
    auto* resolveSavedValues = new ResolveSavedValues();
    addPasses({
        new VerifyAssignedShifts,
        new ResolveNextAndLast,
        new VerifyParserRValsAreUnique,
        new VerifyStateNamessAreUnique,
        resolveSavedValues
    });
}

ResolveHeaderStackValues::ResolveHeaderStackValues() :
    Logging::PassManager("parser", Logging::Mode::AUTO) {
    addPasses({
        new VerifyAssignedShifts,
        new ResolveNextAndLast,
        new CheckResolvedHeaderStackExpressions
    });
}
