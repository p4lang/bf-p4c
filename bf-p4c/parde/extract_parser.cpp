#include "extract_parser.h"

#include <algorithm>
#include <utility>
#include <vector>

#include "ir/ir.h"
#include "lib/log.h"
#include "tofino/common/machine_description.h"
#include "tofino/parde/add_parde_metadata.h"
#include "tofino/parde/resolve_computed.h"

namespace Tofino {

namespace {

/// A helper type that represents a transition in the parse graph that led to
/// the current state.
struct Transition {
    Transition(const IR::Tofino::ParserState* state,
               const IR::Tofino::ParserMatch* match)
        : state(state), match(match) { }

    /// An ancestor state.
    const IR::Tofino::ParserState* state;

    /// The outgoing edge of the ancestor state that we traversed to reach the
    /// current state.
    const IR::Tofino::ParserMatch* match;

    /// A map from extract destination names to the number of times the
    /// destination is extracted in this transition's ParserMatch.
    std::map<cstring, unsigned> extracts;

    /// True if this state contains at least some valid extracts.
    bool isValid = true;
};

/// The stack of transitions we traversed to reach the current state.
struct TransitionStack {
    /// Push a new transition onto the stack.
    /// @return true if this is a valid transition, or false if the transition
    /// is invalid and we should stop generating the parse graph at this point.
    bool push(const IR::Tofino::ParserState* state,
              const IR::Tofino::ParserMatch* match) {
        transitionStack.emplace_back(state, match);
        auto& transition = transitionStack.back();

        // If a state extracts a header which isn't part of a header stack, we don't
        // allow it to be part of a loop. Such a loop would trigger an error at
        // runtime anyway since the parser can't overwrite a PHV container it has
        // already written to.
        unsigned badExtractCount = 0;
        unsigned goodExtractCount = 0;
        unsigned extractCount = 0;
        forAllMatching<IR::Tofino::Extract>(&match->stmts,
                      [&](const IR::Tofino::Extract* extract) {
            extractCount++;
            cstring destName;
            unsigned allowedExtracts;
            std::tie(destName, allowedExtracts) = analyzeDest(extract->dest);
            if (extractTotals[destName] >= allowedExtracts) {
                LOG2(state->name << ": too many extracts for " << destName);
                badExtractCount++;
                return;
            }
            extractTotals[destName]++;
            transition.extracts[destName]++;
            goodExtractCount++;
        });

        BUG_CHECK(badExtractCount + goodExtractCount == extractCount,
                  "Lost track of an extract?");

        // If this transition contains extracts but none of them are legal, it's
        // not a valid transition. The parser will stop here at runtime.
        if (extractCount > 0 && goodExtractCount == 0)
            transition.isValid = false;

        // We'll also stop here if the stack has gotten too deep.
        if (transitionStack.size() > 255)
            transition.isValid = false;

        return transition.isValid;
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

    const Transition& back() const {
        BUG_CHECK(!transitionStack.empty(), "Peeking an empty TransitionStack?");
        return transitionStack.back();
    }

    size_t size() const { return transitionStack.size(); }

    bool alreadyVisited(const IR::Tofino::ParserState* state) const {
        return std::any_of(transitionStack.begin(), transitionStack.end(),
                           [&](const Transition& t) { return t.state == state; });
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

    std::vector<Transition> transitionStack;
    std::map<cstring, unsigned> extractTotals;
};

struct AutoPushTransition {
    AutoPushTransition(TransitionStack& transitionStack,
                       const IR::Tofino::ParserState* state,
                       const IR::Tofino::ParserMatch* match)
        : transitionStack(transitionStack)
        , isValid(transitionStack.push(state, match))
    { }

    ~AutoPushTransition() { transitionStack.pop(); }

    TransitionStack& transitionStack;
    bool isValid;
};

}  // namespace

class GetTofinoParser {
 public:
    static const IR::Tofino::Parser*
    extract(gress_t gress, const IR::P4Parser* parser,
            bool filterSetMetadata = false);
 private:
    GetTofinoParser(gress_t gress, bool filterSetMetadata)
        : gress(gress), filterSetMetadata(filterSetMetadata) { }

    IR::Tofino::ParserState* getState(cstring name);

    TransitionStack                             transitionStack;
    gress_t                                     gress = INGRESS;
    map<cstring, IR::Tofino::ParserState *>     states;
    bool                                        filterSetMetadata;
};

/* static */ const IR::Tofino::Parser*
GetTofinoParser::extract(gress_t gress, const IR::P4Parser* parser,
                         bool filterSetMetadata /* = false */) {
    GetTofinoParser getter(gress, filterSetMetadata);

    forAllMatching<IR::ParserState>(parser,
                  [&](const IR::ParserState* state) {
        if (state->name == "accept" || state->name == "reject")
            return false;
        getter.states[state->name] =
          new IR::Tofino::ParserState(state, state->name, gress);
        return true;
    });

    auto startState = getter.getState("start");
    return new IR::Tofino::Parser(gress, startState);
}

ParserInfo extractParser(const IR::Tofino::Pipe* pipe,
                         const IR::P4Parser* igParser,
                         const IR::P4Control* igDeparser,
                         const IR::P4Parser* egParser /* = nullptr */,
                         const IR::P4Control* egDeparser /* = nullptr */) {
    CHECK_NULL(igParser);
    CHECK_NULL(igDeparser);

    ParserInfo info;

    // XXX(seth): Most of the stuff in this function should actually be handled
    // during the conversion to Tofino Native Architecture.

    // Convert the parsers. If no egress parser was provided, we generate one
    // from the ingress parser by removing all 'set_metadata' primitives.
    info.parsers[INGRESS] = GetTofinoParser::extract(INGRESS, igParser);
    info.parsers[EGRESS] = egParser != nullptr
        ? GetTofinoParser::extract(EGRESS, egParser)
        : GetTofinoParser::extract(EGRESS, igParser,
                                   /* filterSetMetadata = */ true);

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
    ResolveComputedHeaderStackExpressions resolveComputed;
    for (auto gress : { INGRESS, EGRESS })
        info.parsers[gress] = info.parsers[gress]->apply(resolveComputed);

    // Convert the deparsers, generating the egress deparser if necessary.
    info.deparsers[INGRESS] = new IR::Tofino::Deparser(INGRESS, igDeparser);
    info.deparsers[EGRESS] = egDeparser != nullptr
        ? new IR::Tofino::Deparser(EGRESS, egDeparser)
        : new IR::Tofino::Deparser(EGRESS, info.parsers[EGRESS]);

    // Add shims for intrinsic metadata.
    AddMetadataShims addMetadataShims(pipe);
    for (auto gress : { INGRESS, EGRESS }) {
        info.parsers[gress] = info.parsers[gress]->apply(addMetadataShims);
        info.deparsers[gress] = info.deparsers[gress]->apply(addMetadataShims);
    }

    return info;
}

struct RewriteParserStatements : public Transform {
    RewriteParserStatements(cstring stateName, bool filterSetMetadata)
        : stateName(stateName), filterSetMetadata(filterSetMetadata) { }

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

 private:
    const IR::Vector<IR::Tofino::ParserPrimitive>*
    rewriteExtract(Util::SourceInfo srcInfo, const IR::Expression* dest) {
        auto* hdr = dest->to<IR::HeaderRef>();
        BUG_CHECK(hdr != nullptr,
                  "Extracting something other than a header: %1%", dest);
        auto* hdr_type = hdr->type->to<IR::Type_StructLike>();
        BUG_CHECK(hdr_type != nullptr,
                  "Header type isn't a structlike: %1%", hdr_type);

        // If a previous operation (e.g. an `advance()` call) left us in a
        // non-byte-aligned position, we need to move up to the next byte; on
        // Tofino, we can't support unaligned extracts.
        if (currentBit % 8 != 0) {
            ::warning("Can't extract header %1% from non-byte-aligned input "
                      "buffer position on %2%; adding padding.", hdr,
                      Tofino::Description::ModelName);
            currentBit += 8 - currentBit % 8;
        }

        // Generate an extract operation for each field.
        auto* rv = new IR::Vector<IR::Tofino::ParserPrimitive>;
        for (auto field : hdr_type->fields) {
            if (field->type->is<IR::Type::Varbits>())
                P4C_UNIMPLEMENTED("Parser writes to varbits values are not yet supported.");
            IR::Expression* fref = new IR::Member(field->type, hdr, field->name);
            auto width = field->type->width_bits();
            auto extract =
              new IR::Tofino::ExtractBuffer(srcInfo, fref, currentBit, width);
            currentBit += width;
            rv->push_back(extract);
        }

        // On Tofino we can only extract and deparse headers with byte
        // alignment, so if this header isn't aligned, we need to add padding.
        // XXX(seth): We really should catch this error at a higher layer.
        if (currentBit % 8 != 0) {
            ::warning("Can't extract non-byte-aligned header %1% on %2%; adding "
                      "padding.", hdr, Tofino::Description::ModelName);
            currentBit += 8 - currentBit % 8;
        }

        // Generate an extract operation for the POV bit.
        auto validBit = new IR::Member(IR::Type::Bits::get(1), hdr, "$valid");
        rv->push_back(new IR::Tofino::ExtractConstant(srcInfo, validBit,
                                                      new IR::Constant(1)));
        return rv;
    }

    const IR::Vector<IR::Tofino::ParserPrimitive>*
    rewriteAdvance(const IR::Expression* bits) {
        if (!bits->is<IR::Constant>()) {
            ::error("Advancing by a non-constant distance is not supported on "
                    "%1%: %2%", Tofino::Description::ModelName, bits);
            return nullptr;
        }

        auto bitOffset = bits->to<IR::Constant>()->asInt();
        if (bitOffset < 0) {
            ::error("Advancing by a negative distance is not supported on "
                    "%1%: %2%", Tofino::Description::ModelName, bits);
            return nullptr;
        }

        currentBit += bitOffset;
        return nullptr;
    }

    const IR::Vector<IR::Tofino::ParserPrimitive>*
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

        ::error("Unexpected method call in parser: %1%", statement);
        return nullptr;
    }

    bool canEvaluateInParser(const IR::Expression* expression) const {
        // We can't evaluate complex expressions on current hardware.
        return expression->is<IR::Constant>() ||
               expression->is<IR::PathExpression>() ||
               expression->is<IR::Member>() ||
               expression->is<IR::HeaderStackItemRef>();
    }

    const IR::Tofino::ParserPrimitive*
    preorder(IR::AssignmentStatement* s) override {
        if (filterSetMetadata) return nullptr;

        if (s->left->type->is<IR::Type::Varbits>())
            P4C_UNIMPLEMENTED("Parser writes to varbits values are not yet supported.");

        // Peel off any Cast expression. This accepts more programs than we can
        // actually implement; some casts can't be performed at parse time.
        auto rhs = s->right;
        if (rhs->is<IR::Cast>())
            rhs = rhs->to<IR::Cast>()->expr;

        if (rhs->is<IR::Constant>())
            return new IR::Tofino::ExtractConstant(s->srcInfo, s->left,
                                                   rhs->to<IR::Constant>());

        if (auto* lookahead = rhs->to<IR::Tofino::LookaheadExpression>()) {
            auto bits = lookahead->bitRange().shiftedBy(currentBit);
            return new IR::Tofino::ExtractBuffer(s->srcInfo, s->left, bits);
        }

        if (!canEvaluateInParser(rhs)) {
            ::error("Assignment cannot be supported in the parser: %1%", rhs);
            return new IR::Tofino::UnhandledParserPrimitive(s->srcInfo, s);
        }

        return new IR::Tofino::ExtractComputed(s->srcInfo, s->left, rhs);
    }

    const IR::Expression* preorder(IR::Statement* s) override {
        BUG("Unhandled statement kind: %1%", s);
    }

    cstring stateName;
    unsigned currentBit = 0;
    bool filterSetMetadata;
};

static match_t buildListMatch(const IR::Vector<IR::Expression> *list) {
    match_t     rv;
    for (auto el : *list) {
        int width = el->type->width_bits();
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
        } else {
            BUG("Invalid select case expression %1%", el); }
        rv.word0 |= mask & ~v;
        rv.word1 |= mask & v; }
    return rv;
}

static match_t buildMatch(int match_size, const IR::Expression *key) {
    if (key->is<IR::DefaultExpression>())
        return match_t();
    else if (auto k = key->to<IR::Constant>())
        return match_t(match_size, k->asLong(), ~0ULL);
    else if (auto mask = key->to<IR::Mask>())
        return match_t(match_size, mask->left->to<IR::Constant>()->asLong(),
                                   mask->right->to<IR::Constant>()->asLong());
    else if (auto list = key->to<IR::ListExpression>())
        return buildListMatch(&list->components);
    else
        BUG("Invalid select case expression %1%", key);
    return match_t();
}

namespace {

const IR::Node* rewriteSelect(const IR::Expression* component) {
    // We can transform a LookaheadExpression immediately to a concrete select
    // on bits in the input buffer.
    if (auto* lookahead = component->to<IR::Tofino::LookaheadExpression>())
        return new IR::Tofino::SelectBuffer(component->srcInfo,
                                            lookahead->bitRange(),
                                            lookahead);

    // We can split a Concat into multiple selects. Note that this is quite
    // unlike a Slice; the Concat operands may not even be adjacent in the input
    // buffer, so this is really two primitive select operations.
    if (auto* concat = component->to<IR::Concat>()) {
        auto* rv = new IR::Vector<IR::Tofino::TransitionPrimitive>;
        rv->pushBackOrAppend(rewriteSelect(concat->left));
        rv->pushBackOrAppend(rewriteSelect(concat->right));
        return rv;
    }

    // For anything else, we'll have to resolve it later.
    return new IR::Tofino::SelectComputed(component->srcInfo, component);
}

}  // namespace

IR::Tofino::ParserState* GetTofinoParser::getState(cstring name) {
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
        auto originalName = state->p4State->name;
        auto unrolledName = cstring::make_unique(states, originalName);
        state = new IR::Tofino::ParserState(state->p4State, unrolledName, gress);
        states[unrolledName] = state;
    } else if (!state->match.empty()) {
        // We've already generated the matches for this state, so we know we've
        // already converted it; just return.
        return state;
    }

    BUG_CHECK(state->p4State != nullptr,
              "Converting a parser state that didn't come from the frontend?");

    // Lower the parser statements from the frontend IR to the Tofino IR.
    RewriteParserStatements rewriteStatements(state->p4State->name, filterSetMetadata);
    IR::Vector<IR::Tofino::ParserPrimitive> statements;
    for (auto* statement : state->p4State->components)
        statements.pushBackOrAppend(statement->apply(rewriteStatements));

    // Compute the new state's shift.
    auto shift = rewriteStatements.byteTotalShift();

    // Handle the simple cases: this state has no successor, or it transitions
    // to a single successor state unconditionally.
    LOG2("GetParser::state(" << name << ")");
    if (!state->p4State->selectExpression) return state;
    if (auto* path = state->p4State->selectExpression->to<IR::PathExpression>()) {
        auto match = new IR::Tofino::ParserMatch(match_t(), shift, statements);
        state->match.push_back(match);

        AutoPushTransition transition(transitionStack, state, match);
        if (transition.isValid)
            match->next = getState(path->path->name);
        else
            return nullptr;  // One bad transition means the whole state's bad.

        return state;
    }
    if (!state->p4State->selectExpression->is<IR::SelectExpression>())
        BUG("Invalid select expression %1%", state->p4State->selectExpression);

    // We have a select expression. Lower it to Tofino IR.
    int matchSize = 0;
    auto selectExpr = state->p4State->selectExpression->to<IR::SelectExpression>();
    for (auto* component : selectExpr->select->components) {
        matchSize += component->type->width_bits();
        state->select.pushBackOrAppend(rewriteSelect(component));
    }

    // Generate a ParserMatch for each outgoing transition.
    for (auto selectCase : selectExpr->selectCases) {
        auto matchVal = buildMatch(matchSize, selectCase->keyset);
        auto match = new IR::Tofino::ParserMatch(matchVal, shift, statements);
        state->match.push_back(match);

        AutoPushTransition transition(transitionStack, state, match);
        if (transition.isValid)
            match->next = getState(selectCase->state->path->name);
        else
            return nullptr;  // One bad transition means the whole state's bad.
    }

    return state;
}

}  // namespace Tofino
