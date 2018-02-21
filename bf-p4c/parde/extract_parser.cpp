#include "extract_parser.h"

#include <algorithm>
#include <map>
#include <utility>
#include <vector>

#include "ir/ir.h"
#include "lib/log.h"
#include "bf-p4c/device.h"
#include "bf-p4c/parde/add_parde_metadata.h"
#include "bf-p4c/parde/resolve_computed.h"
#include "bf-p4c/parde/gen_deparser.h"

namespace BFN {

namespace {

/// A helper type that represents a transition in the parse graph that led to
/// the current state.
struct AncestorTransition {
    AncestorTransition(const IR::BFN::ParserState* state,
                       const IR::BFN::Transition* transition)
        : state(state), transition(transition) { }

    /// An ancestor state.
    const IR::BFN::ParserState* state;

    /// The outgoing edge of the ancestor state that we traversed to reach the
    /// current state.
    const IR::BFN::Transition* transition;

    /// A map from extract destination names to the number of times the
    /// destination is extracted in this state.
    std::map<cstring, unsigned> extracts;

    /// True if this state contains at least some valid extracts.
    bool isValid = true;
};

/// The stack of transitions we traversed to reach the current state.
struct TransitionStack {
    /// Push a new transition onto the stack.
    /// @return true if this is a valid transition, or false if the transition
    /// is invalid and we should stop generating the parse graph at this point.
    bool push(const IR::BFN::ParserState* state,
              const IR::BFN::Transition* transition) {
        transitionStack.emplace_back(state, transition);
        auto& newTransition = transitionStack.back();

        // If a state extracts a header which isn't part of a header stack, we don't
        // allow it to be part of a loop. Such a loop would trigger an error at
        // runtime anyway since the parser can't overwrite a PHV container it has
        // already written to.
        unsigned badExtractCount = 0;
        unsigned goodExtractCount = 0;
        unsigned extractCount = 0;
        forAllMatching<IR::BFN::Extract>(&state->statements,
                      [&](const IR::BFN::Extract* extract) {
            extractCount++;
            cstring destName;
            unsigned allowedExtracts;
            std::tie(destName, allowedExtracts) = analyzeDest(extract->dest->field);
            if (extractTotals[destName] >= allowedExtracts) {
                LOG2(state->name << ": too many extracts for " << destName);
                badExtractCount++;
                return;
            }
            extractTotals[destName]++;
            newTransition.extracts[destName]++;
            goodExtractCount++;
        });

        BUG_CHECK(badExtractCount + goodExtractCount == extractCount,
                  "Lost track of an extract?");

        // If the new transition contains extracts but none of them are legal,
        // it's not valid. The parser will stop here at runtime.
        if (extractCount > 0 && goodExtractCount == 0)
            newTransition.isValid = false;

        // We'll also stop here if the stack has gotten too deep.
        if (transitionStack.size() > 255)
            newTransition.isValid = false;

        return newTransition.isValid;
    }

    void pop() {
        for (auto& extractItem : transitionStack.back().extracts) {
            cstring destName = extractItem.first;
            unsigned count = extractItem.second;
            BUG_CHECK(extractTotals[destName] >= count,
                      "Lost track of some extracts?");
            extractTotals[destName] -= count;
        }

        transitionStack.pop_back();
    }

    const AncestorTransition& back() const {
        BUG_CHECK(!transitionStack.empty(), "Peeking an empty TransitionStack?");
        return transitionStack.back();
    }

    size_t size() const { return transitionStack.size(); }

    bool alreadyVisited(const IR::BFN::ParserState* state) const {
        return std::any_of(transitionStack.begin(), transitionStack.end(),
                           [&](const AncestorTransition& t) { return t.state == state; });
    }

 private:
    /// @return a string representation of the provided extract destination and
    /// the number of times that the destination may be extracted to on a given
    /// path through the parse graph.
    std::pair<cstring, unsigned> analyzeDest(const IR::Expression* dest) {
        if (dest->is<IR::TempVar>())
            return std::make_pair(dest->toString(), 1);
        if (!dest->is<IR::Member>()) {
            ::warning("Unexpected extract destination: %1%", dest);
            return std::make_pair(dest->toString(), 1);
        }
        auto* member = dest->to<IR::Member>();
        if (!member->expr->is<IR::HeaderStackItemRef>())
            return std::make_pair(dest->toString(), 1);
        auto* itemRef = member->expr->to<IR::HeaderStackItemRef>();
        auto destName = itemRef->base()->toString() + "." + member->member;
        auto allowedExtracts = itemRef->base()->type->to<IR::Type_Stack>()
                                              ->size->to<IR::Constant>()->asInt();
        return std::make_pair(destName, std::max(allowedExtracts, 0));
    }

    std::vector<AncestorTransition> transitionStack;
    std::map<cstring, unsigned> extractTotals;
};

struct AutoPushTransition {
    AutoPushTransition(TransitionStack& transitionStack,
                       const IR::BFN::ParserState* state,
                       const IR::BFN::Transition* transition)
        : transitionStack(transitionStack)
        , isValid(transitionStack.push(state, transition))
    { }

    ~AutoPushTransition() { transitionStack.pop(); }

    TransitionStack& transitionStack;
    bool isValid;
};

class GetTofinoParser {
 public:
    static const IR::BFN::Parser*
    extract(gress_t gress, const IR::P4Parser* parser);

    bool addTransition(IR::BFN::ParserState* state, match_t matchVal, int shift, cstring nextState);

 private:
    explicit GetTofinoParser(gress_t gress) : gress(gress) { }

    IR::BFN::ParserState* getState(cstring name);

    TransitionStack                             transitionStack;
    gress_t                                     gress = INGRESS;
    std::map<cstring, IR::BFN::ParserState *>   states;
    std::map<cstring, cstring>                  p4StateNameToStateName;
};

/* static */ const IR::BFN::Parser*
GetTofinoParser::extract(gress_t gress, const IR::P4Parser* parser) {
    GetTofinoParser getter(gress);

    forAllMatching<IR::ParserState>(parser,
                  [&](const IR::ParserState* state) {
        auto stateName = state->controlPlaneName();
        getter.p4StateNameToStateName.emplace(state->name, stateName);
        if (state->name == "accept" || state->name == "reject")
            return false;
        getter.states[stateName] =
          new IR::BFN::ParserState(state, stateName, gress);
        return true;
    });

    BUG_CHECK(getter.p4StateNameToStateName.count("start"),
              "No entry point in parser?");
    auto* startState = getter.getState(getter.p4StateNameToStateName.at("start"));
    return new IR::BFN::Parser(gress, startState);
}

bool GetTofinoParser::addTransition(IR::BFN::ParserState* state, match_t matchVal,
    int shift, cstring nextState) {
    auto* transition = new IR::BFN::Transition(matchVal, shift);
    state->transitions.push_back(transition);

    AutoPushTransition newTransition(transitionStack, state, transition);
    if (newTransition.isValid) {
        BUG_CHECK(p4StateNameToStateName.count(nextState),
                  "Transition to unknown P4 state: %1%", nextState);
        transition->next =
          getState(p4StateNameToStateName.at(nextState));
    } else {
        return false;  // One bad transition means the whole state's bad.
    }

    return true;
}


}  // namespace

struct RewriteParserStatements : public Transform {
    RewriteParserStatements(cstring stateName, gress_t gress)
        : stateName(stateName), gress(gress) { }

    /// @return the cumulative shift in bytes from all of the statements
    /// rewritten up to this point. This includes both extracts and `advance()`
    /// calls.
    int byteTotalShift() const {
        nw_bitinterval bitsAdvanced(0, currentBit);
        if (!bitsAdvanced.isHiAligned())
            ::warning("Parser state %1% does not end on a byte boundary; "
                      "adding padding.", stateName);
        return bitsAdvanced.nextByte();
    }

    /// @return the cumulative shift in bits from all statements rewritten up to
    /// this point.
    int bitTotalShift() const { return currentBit; }

 private:
    const IR::Vector<IR::BFN::ParserPrimitive>*
    rewriteExtract(Util::SourceInfo srcInfo, const IR::Expression* dest) {
        auto* hdr = dest->to<IR::HeaderRef>();
        BUG_CHECK(hdr != nullptr,
                  "Extracting something other than a header: %1%", dest);
        auto* hdr_type = hdr->type->to<IR::Type_StructLike>();
        BUG_CHECK(hdr_type != nullptr,
                  "Header type isn't a structlike: %1%", hdr_type);

        // XXX(seth): We filter out extracts for types with this annotation.
        // This is a hack to support some v1model programs in the short term;
        // long term, the right solution is to use PSA or TNA, which allow the
        // programmer to define separate ingress and egress parsers.
        if (gress == EGRESS &&
            hdr_type->getAnnotation("not_extracted_in_egress") != nullptr) {
            ::warning("Ignoring egress extract of @not_extracted_in_egress "
                      "header: %1%", dest);
            return nullptr;
        }

        // If a previous operation (e.g. an `advance()` call) left us in a
        // non-byte-aligned position, we need to move up to the next byte; on
        // Tofino, we can't support unaligned extracts.
        if (currentBit % 8 != 0) {
            ::warning("Can't extract header %1% from non-byte-aligned input "
                      "buffer position on %2%; adding padding.", hdr,
                      Device::currentDevice());
            currentBit += 8 - currentBit % 8;
        }

        // Generate an extract operation for each field.
        auto* rv = new IR::Vector<IR::BFN::ParserPrimitive>;
        for (auto field : hdr_type->fields) {
            if (field->type->is<IR::Type::Varbits>())
                P4C_UNIMPLEMENTED("Parser writes to varbits values are not yet supported.");
            IR::Expression* fref = new IR::Member(field->type, hdr, field->name);
            auto width = field->type->width_bits();
            auto* extract = new IR::BFN::Extract(srcInfo, fref,
                              new IR::BFN::PacketRVal(StartLen(currentBit, width)));
            currentBit += width;
            rv->push_back(extract);
        }

        // On Tofino we can only extract and deparse headers with byte
        // alignment. Any non-byte-aligned headers should've been caught by
        // BFN::CheckHeaderAlignment in the midend.
        BUG_CHECK(currentBit % 8 == 0,
                  "A non-byte-aligned header type reached the backend");

        // Generate an extract operation for the POV bit.
        auto* validBit = new IR::Member(IR::Type::Bits::get(1), hdr, "$valid");
        rv->push_back(new IR::BFN::Extract(srcInfo, validBit,
                        new IR::BFN::ConstantRVal(1)));
        return rv;
    }

    const IR::Vector<IR::BFN::ParserPrimitive>*
    rewriteAdvance(const IR::Expression* bits) {
        if (!bits->is<IR::Constant>()) {
            ::error("Advancing by a non-constant distance is not supported on "
                    "%1%: %2%", Device::currentDevice(), bits);
            return nullptr;
        }

        auto bitOffset = bits->to<IR::Constant>()->asInt();
        if (bitOffset < 0) {
            ::error("Advancing by a negative distance is not supported on "
                    "%1%: %2%", Device::currentDevice(), bits);
            return nullptr;
        }

        currentBit += bitOffset;
        return nullptr;
    }

    const IR::Vector<IR::BFN::ParserPrimitive>*
    preorder(IR::MethodCallStatement* statement) override {
        auto* call = statement->methodCall;
        auto* method = call->method->to<IR::Member>();
        BUG_CHECK(method != nullptr, "Invalid method call: %1%", statement);

        if (method->member == "extract") {
            BUG_CHECK(call->arguments->size() == 1,
                      "Wrong number of arguments for method call: %1%", statement);
            return rewriteExtract(statement->srcInfo, (*call->arguments)[0]);
        }
        if (method->member == "advance") {
            BUG_CHECK(call->arguments->size() == 1,
                      "Wrong number of arguments for method call: %1%", statement);
            return rewriteAdvance((*call->arguments)[0]);
        }
        if (method->member == "set") {
            WARNING("packet priority set is not yet implemented");
            return nullptr;
        }

        ::error("Unexpected method call in parser: %1%", statement->toString());
        return nullptr;
    }

    bool canEvaluateInParser(const IR::Expression* expression) const {
        // We can't evaluate complex expressions on current hardware.
        return expression->is<IR::Constant>() ||
               expression->is<IR::PathExpression>() ||
               expression->is<IR::Member>() ||
               expression->is<IR::HeaderStackItemRef>() ||
               expression->is<IR::TempVar>();
    }

    const IR::BFN::ParserPrimitive*
    preorder(IR::AssignmentStatement* s) override {
        if (s->left->type->is<IR::Type::Varbits>())
            P4C_UNIMPLEMENTED("Parser writes to varbits values are not yet supported.");

        // Peel off any Cast expression. This accepts more programs than we can
        // actually implement; some casts can't be performed at parse time.
        auto rhs = s->right;
        if (rhs->is<IR::Cast>())
            rhs = rhs->to<IR::Cast>()->expr;

        if (rhs->is<IR::Constant>())
            return new IR::BFN::Extract(s->srcInfo, s->left,
                     new IR::BFN::ConstantRVal(rhs->to<IR::Constant>()->value));

        if (auto* lookahead = rhs->to<IR::BFN::LookaheadExpression>()) {
            auto bits = lookahead->bitRange().shiftedByBits(currentBit);
            return new IR::BFN::Extract(s->srcInfo, s->left,
                     new IR::BFN::PacketRVal(bits));
        }

        // Allow slices if we'd allow the expression being sliced.
        if (auto* slice = rhs->to<IR::Slice>())
            if (canEvaluateInParser(slice->e0))
                return new IR::BFN::Extract(s->srcInfo, s->left,
                                            new IR::BFN::ComputedRVal(rhs));

        if (!canEvaluateInParser(rhs)) {
            ::error("Assignment cannot be supported in the parser: %1%", rhs);
            return nullptr;
        }

        return new IR::BFN::Extract(s->srcInfo, s->left,
                                    new IR::BFN::ComputedRVal(rhs));
    }

    const IR::Expression* preorder(IR::Statement* s) override {
        BUG("Unhandled statement kind: %1%", s);
    }

    const cstring stateName;
    const gress_t gress;
    unsigned currentBit = 0;
};

static match_t buildListMatch(const IR::Vector<IR::Expression> *list,
                              const IR::Vector<IR::Expression> select) {
    match_t     rv;
    auto sel_el = select.begin();
    for (auto el : *list) {
        if (!el->is<IR::DefaultExpression>()) {
            BUG_CHECK(el->type == (*sel_el)->type ||
                      (el->type->is<IR::Type_Set>() &&
                       el->type->to<IR::Type_Set>()->elementType == (*sel_el)->type),
                      "select type mismatch"); }
        int width = (*sel_el)->type->width_bits();
        rv.word0 <<= width;
        rv.word1 <<= width;
        uintmax_t mask = -1, v;
        mask = ~(mask << width);
        if (auto k = el->to<IR::Constant>()) {
            v = k->asLong();
        } else if (auto mval = el->to<IR::Mask>()) {
            v = mval->right->to<IR::Constant>()->asLong();
            rv.word0 |= mask & ~v;
            rv.word1 |= mask & ~v;
            mask &= v;
            v = mval->left->to<IR::Constant>()->asLong();
        } else if (el->is<IR::DefaultExpression>()) {
            mask = v = 0;
        } else {
            BUG("Invalid select case expression %1%", el); }
        rv.word0 |= mask & ~v;
        rv.word1 |= mask & v;
        ++sel_el; }
    BUG_CHECK(sel_el == select.end(), "select/match mismatch");
    return rv;
}

static match_t buildMatch(int match_size, const IR::Expression *key,
                          const IR::Vector<IR::Expression> &selectExprs,
                          int pad) {
    if (key->is<IR::DefaultExpression>())
        return match_t();
    else if (auto k = key->to<IR::Constant>())
        return match_t(match_size + pad, k->asLong() << pad, ~0ULL << pad);
    else if (auto mask = key->to<IR::Mask>())
        return match_t(match_size, mask->left->to<IR::Constant>()->asLong(),
                                   mask->right->to<IR::Constant>()->asLong());
    else if (auto list = key->to<IR::ListExpression>())
        return buildListMatch(&list->components, selectExprs);
    else
        BUG("Invalid select case expression %1%", key);
    return match_t();
}

namespace {

const IR::Node* rewriteSelectExpr(const IR::Expression* selectExpr, int bitShift,
                                  nw_bitrange& bitrange) {
    // We can transform a LookaheadExpression immediately to a concrete select
    // on bits in the input buffer.
    if (auto* lookahead = selectExpr->to<IR::BFN::LookaheadExpression>()) {
        auto finalRange = lookahead->bitRange().shiftedByBits(bitShift);
        bitrange = finalRange;
        return new IR::BFN::Select(new IR::BFN::PacketRVal(finalRange), lookahead);
    }

    // We can split a Concat into multiple selects. Note that this is quite
    // unlike a Slice; the Concat operands may not even be adjacent in the input
    // buffer, so this is really two primitive select operations.
    if (auto* concat = selectExpr->to<IR::Concat>()) {
        auto* rv = new IR::Vector<IR::BFN::Select>;
        rv->pushBackOrAppend(rewriteSelectExpr(concat->left, bitShift, bitrange));
        rv->pushBackOrAppend(rewriteSelectExpr(concat->right, bitShift, bitrange));
        return rv;
    }

    // For anything else, we'll have to resolve it later.
    // FIXME(zma) alright, I believe you have a good reason for that ...
    return new IR::BFN::Select(new IR::BFN::ComputedRVal(selectExpr), selectExpr);
}

}  // namespace

IR::BFN::ParserState* GetTofinoParser::getState(cstring name) {
    // If the state isn't found, immediately return null; at runtime, parsing
    // will terminate here. That's normal if we're transitioning to a terminal
    // state; otherwise, we'll report an error.
    if (states.count(name) == 0) {
        if (name != "accept" && name != "reject")
            ::error("No definition for parser state %1%", name);
        return nullptr;
    }

    // Check if we've already reached this state on this path, and if so, make
    // sure that the resulting loop is legal.
    auto* state = states[name];
    if (transitionStack.alreadyVisited(state)) {
        // We're inside a loop. We don't want loops in the actual IR graph, so
        // we'll unroll the loop by creating a new, empty instance of this
        // state, which we'll convert again.
        auto originalName = state->p4State->controlPlaneName();
        auto unrolledName = cstring::make_unique(states, originalName);
        state = new IR::BFN::ParserState(state->p4State, unrolledName, gress);
        states[unrolledName] = state;
    } else if (!state->transitions.empty()) {
        // We've already generated the matches for this state, so we know we've
        // already converted it; just return.
        return state;
    }

    BUG_CHECK(state->p4State != nullptr,
              "Converting a parser state that didn't come from the frontend?");

    // Lower the parser statements from the frontend IR to the Tofino IR.
    RewriteParserStatements rewriteStatements(state->p4State->controlPlaneName(),
                                              gress);
    for (auto* statement : state->p4State->components)
        state->statements.pushBackOrAppend(statement->apply(rewriteStatements));

    // Compute the new state's shift.
    auto bitShift = rewriteStatements.bitTotalShift();
    auto shift = rewriteStatements.byteTotalShift();

    LOG2("GetParser::state(" << name << ")");

    // case 1: no select
    if (!state->p4State->selectExpression) return state;

    // case 2: unconditional transition, e.g. accept/reject
    if (auto* path = state->p4State->selectExpression->to<IR::PathExpression>()) {
        bool ok = addTransition(state, match_t(), shift, path->path->name);
        return ok ? state : nullptr;
    }

    // case 3: we have a select expression. Lower it to Tofino IR.
    auto* p4Select = state->p4State->selectExpression->to<IR::SelectExpression>();

    BUG_CHECK(p4Select, "Invalid select expression %1%", state->p4State->selectExpression);

    auto& selectExprs = p4Select->select->components;
    auto& selectCases = p4Select->selectCases;

    // FIXME multiple exprs can share match if they reside in same byte
    // FIXME duplicated match exprs, is this legal in the language?
    // FIXME non byte aligned select expression

    int matchSize = 0;
    int pad = 0;

    for (auto* selectExpr : selectExprs) {
        nw_bitrange bitrange;

        state->selects.pushBackOrAppend(rewriteSelectExpr(selectExpr, bitShift, bitrange));

        // XXX(zma) tmp fix for non byte-aligned select expr
        // this won't work if there are mulitple non byte-aligned select exprs
        // proper fix is to transform all select exprs into byte-aligned
        // ones before building matches
        if (bitrange != nw_bitrange())
            pad = 7 - bitrange.hi % 8;

        matchSize += selectExpr->type->width_bits();
    }

    // Generate the outgoing transitions.
    for (auto selectCase : selectCases) {
        auto matchVal = buildMatch(matchSize, selectCase->keyset, selectExprs, pad);
        bool ok = addTransition(state, matchVal, shift, selectCase->state->path->name);
        if (!ok) return nullptr;
    }

    return state;
}

void BFN::ExtractParser::postorder(const IR::BFN::TranslatedP4Parser* parser) {
    gress_t thread = parser->thread;
    rv->thread[thread].parser = BFN::GetTofinoParser::extract(thread, parser);
}

ProcessParde::ProcessParde(IR::BFN::Pipe* rv, bool useTna) {
    setName("ProcessParde");
    addPasses({
        // Attempt to resolve header stack ".next" and ".last" members.
        // XXX(seth): In the long term we should run
        // ResolveComputedParserExpressions here instead, but right now we can't
        // because we haven't yet added bridged metadata, and without it the egress
        // parser may fail because it tries to read ingress intrinsic metadata that
        // isn't present natively in egress.
        // XXX(seth): Also, generating the egress deparser from the egress parser
        // correctly requires that we've resolved header stack indices, but that's
        // an artifact of the IR conversion and it's not something that should not
        // be happening at this layer anyway.
        // XXX(seth): We could and should deal with this in the midend.
        new ResolveComputedHeaderStackExpressions(),
        // Add shims for intrinsic metadata.
        (useTna) ? nullptr : new AddParserMetadataShims(rv),
        new AddDeparserMetadataShims(rv),
    });
}

}  // namespace BFN
