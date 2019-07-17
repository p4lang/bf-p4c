#include "bf-p4c/parde/resolve_parser_stack_index.h"

#include <boost/optional.hpp>

#include "bf-p4c/device.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/dump_parser.h"

namespace {

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
        LOG4(id << ":ResolveStackRefs for "<< parser->toString()
                << " start=" << parser->start->name);
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
            ::error("%s Inconsistent index for next of %s in state %s", ref->srcInfo,
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

class CheckResolvedHeaderStackExpressions : public ParserInspector {
    bool preorder(const IR::BFN::UnresolvedStackRef* stackRef) {
        ::error("Couldn't resolve header stack reference in state %1%: %2%",
                findContext<IR::BFN::ParserState>()->name, stackRef);
        return false;
    }
};

}  // namespace

ResolveHeaderStackValues::ResolveHeaderStackValues() :
    Logging::PassManager("parser", Logging::Mode::AUTO) {
    addPasses({
        new ResolveNextAndLast,
        new CheckResolvedHeaderStackExpressions
    });
}
