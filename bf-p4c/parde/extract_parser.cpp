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
#include "bf-p4c/common/utils.h"

namespace BFN {

struct ParserPragmas : public Inspector {
    static bool checkNumArgs(cstring pragma, const IR::Vector<IR::Expression>& exprs,
                             unsigned expected) {
        if (exprs.size() != expected) {
            ::warning("@pragma %1% must have %2% argument, %3% are found, skipped",
                       pragma, expected, exprs.size());
            return false;
        }

        return true;
    }

    static bool checkGress(cstring pragma, const IR::StringLiteral* gress) {
        if (!gress || (gress->value != "ingress" && gress->value != "egress")) {
            ::warning("@pragma %1% must be applied to ingress/egress", pragma);
            return false;
        }
        return true;
    }

    bool preorder(const IR::Annotation *annot) {
        auto pragma_name = annot->name.name;
        auto p = findContext<IR::BFN::TranslatedP4Parser>();
        auto ps = findContext<IR::ParserState>();

        if (!p || !ps)
            return false;

        if (pragma_name == "terminate_parsing") {
            auto& exprs = annot->expr;
            if (!checkNumArgs(pragma_name, exprs, 1))
                return false;

            auto gress = exprs[0]->to<IR::StringLiteral>();
            if (!checkGress(pragma_name, gress))
                return false;

            if (gress->value == toString(p->thread)) {
                terminate_parsing.insert(ps);
            }
        } else if (pragma_name == "force_shift") {
            auto& exprs = annot->expr;
            if (!checkNumArgs(pragma_name, exprs, 2))
                return false;

            auto gress = exprs[0]->to<IR::StringLiteral>();
            if (!checkGress(pragma_name, gress))
                return false;

            auto shift_amt = exprs[1]->to<IR::Constant>();
            if (!shift_amt || shift_amt->asInt() <= 0) {
                ::warning("@pragma force_shift must have positive shift amount(bits)");
                return false;
            }

            if (gress->value == toString(p->thread)) {
                force_shift[ps] = shift_amt->asInt();
            }
        }

        return false;
    }

    std::set<const IR::ParserState*> terminate_parsing;
    std::map<const IR::ParserState*, unsigned> force_shift;
};

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
            auto lval = extract->dest->to<IR::BFN::FieldLVal>();
            if (!lval) return;
            std::tie(destName, allowedExtracts) = analyzeDest(lval->field);
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

class GetBackendParser {
 public:
    explicit GetBackendParser(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
                              const ParserPragmas& pg) :
        refMap(refMap), typeMap(typeMap), parserPragmas(pg) { }

    const IR::BFN::Parser* extract(const IR::BFN::TranslatedP4Parser* parser);

    bool addTransition(IR::BFN::ParserState* state, match_t matchVal, int shift, cstring nextState,
                       const IR::P4ValueSet* valueSet = nullptr);

 private:
    IR::BFN::ParserState* getState(cstring name);

    TransitionStack                             transitionStack;

    std::map<cstring, IR::BFN::ParserState *>   states;
    std::map<cstring, cstring>                  p4StateNameToStateName;

    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
    const ParserPragmas& parserPragmas;
};

const IR::BFN::Parser*
GetBackendParser::extract(const IR::BFN::TranslatedP4Parser* parser) {
    forAllMatching<IR::ParserState>(parser, [&](const IR::ParserState* state) {
        auto stateName = state->controlPlaneName();
        p4StateNameToStateName.emplace(state->name, stateName);
        if (state->name == "accept" || state->name == "reject")
            return false;
        states[stateName] =
          new IR::BFN::ParserState(state,
                                   createThreadName(parser->thread, stateName),
                                   parser->thread);
        return true;
    });

    BUG_CHECK(p4StateNameToStateName.count("start"),
              "No entry point in parser?");
    auto* startState = getState(p4StateNameToStateName.at("start"));
    return new IR::BFN::Parser(parser->thread, startState);
}

bool GetBackendParser::addTransition(IR::BFN::ParserState* state, match_t matchVal,
                                     int shift, cstring nextState, const IR::P4ValueSet* valueSet) {
    IR::BFN::ParserMatchValue* match_value_ir = nullptr;
    if (valueSet) {
        // Convert IR::Constant to unsigned int.
        size_t sz = 0;
        auto sizeConstant = valueSet->size->to<IR::Constant>();
        if (sizeConstant == nullptr || !sizeConstant->fitsInt()) {
            ::error("valueset should have an integer as size %1%", valueSet); }
        if (sizeConstant->value < 0) {
            ::error("valueset size must be a positive integer %1%", valueSet); }
        sz = sizeConstant->value.get_ui();
        match_value_ir = new IR::BFN::ParserPvsMatchValue(valueSet->controlPlaneName(), sz);
    } else {
        match_value_ir = new IR::BFN::ParserConstMatchValue(matchVal);
    }
    auto* transition = new IR::BFN::Transition(match_value_ir, shift, nullptr);
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

struct RewriteParserStatements : public Transform {
    std::map<cstring, const IR::BFN::PacketRVal*> extractedFields;

    RewriteParserStatements(cstring stateName, gress_t gress)
        : stateName(stateName), gress(gress) { }

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
            auto* rval = new IR::BFN::PacketRVal(StartLen(currentBit, width));
            auto* extract = new IR::BFN::Extract(srcInfo, fref, rval);
            currentBit += width;
            rv->push_back(extract);
            extractedFields[field->name] = rval;
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
    rewriteChecksumAdd(const IR::Expression* src) {
        auto rv = new IR::Vector<IR::BFN::ParserPrimitive>;
        IR::Vector<IR::Expression> list;
        if (auto member = src->to<IR::Member>()) {
            list.push_back(member);
        } else if (auto listExpr = src->to<IR::ListExpression>()) {
            list = listExpr->components;
        } else if (auto headerRef = src->to<IR::ConcreteHeaderRef>()) {
            auto header = headerRef->baseRef();
            for (auto field : header->type->fields) {
                auto member = new IR::Member(
                    src->srcInfo, headerRef, field->name);
                list.push_back(member);
            }
        }

        for (auto expr : list) {
            auto member = expr->to<IR::Member>();
            BUG_CHECK(member != nullptr,
                      "Invalid field in the checksum verification field list : %1%",
                      member->srcInfo);
            auto hdr = member->expr->to<IR::HeaderRef>();
            BUG_CHECK(hdr != nullptr,
                      "Invalid field in the checksum verification field list."
                      " Expecting a header field : %1%", member->srcInfo);
            auto hdr_type = hdr->type->to<IR::Type_StructLike>();
            BUG_CHECK(hdr_type != nullptr,
                      "Header type isn't a structlike: %1%", hdr_type);

            auto rval = extractedFields.at(member->member);
            auto* add = new IR::BFN::AddToChecksum(rval);
            rv->push_back(add);
        }
        return rv;
    }

    const IR::Vector<IR::BFN::ParserPrimitive>*
    preorder(IR::MethodCallStatement* statement) override {
        auto* call = statement->methodCall;
        auto* method = call->method->to<IR::Member>();
        BUG_CHECK(method != nullptr, "Invalid method call: %1%", statement);

        if (method->member == "extract") {
            BUG_CHECK(call->arguments->size() == 1,
                      "Wrong number of arguments for method call: %1%", statement);
            return rewriteExtract(statement->srcInfo, (*call->arguments)[0]->expression);
        }

        if (method->member == "advance") {
            BUG_CHECK(call->arguments->size() == 1,
                      "Wrong number of arguments for method call: %1%", statement);
            return rewriteAdvance((*call->arguments)[0]->expression);
        }

        if (method->member == "set") {
            WARNING("packet priority set is not yet implemented");
            return nullptr;
        }

        if (method->member == "increment" || method->member == "decrement") {
            WARNING("parser counter is not yet implemented");
            return nullptr;
        }

        if (method->member == "add") {
            BUG_CHECK(call->arguments->size() == 1,
                      "Wrong number of arguments for method call: %1%", statement);
            return rewriteChecksumAdd((*call->arguments)[0]->expression);
        }

        if (method->member == "remove") {
            WARNING("checksum.remove is not yet implemented");
            return nullptr;
        }

        if (method->member == "verify") {
            auto* rv = new IR::Vector<IR::BFN::ParserPrimitive>;
            rv->push_back(new IR::BFN::VerifyChecksum());
            return rv;
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
               expression->is<IR::TempVar>() ||
               expression->is<IR::MethodCallExpression>();  // verify checksum
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

        if (auto mc = rhs->to<IR::MethodCallExpression>()) {
            auto* method = mc->method->to<IR::Member>();
            if (method && method->member == "verify") {
                auto verify = new IR::BFN::VerifyChecksum();
                if (auto mem = s->left->to<IR::Member>())
                    verify->dest = new IR::BFN::FieldLVal(mem);
                else if (auto sl = s->left->to<IR::Slice>())
                    verify->dest = new IR::BFN::FieldLVal(sl);
                return verify;
            }
        }

        if (auto mem = s->left->to<IR::Member>()) {
            if (mem->member == "ingress_parser_err"|| mem->member == "egress_parser_err")
                return nullptr;
        }

        if (rhs->is<IR::Constant>()) {
            return new IR::BFN::Extract(s->srcInfo, s->left,
                     new IR::BFN::ConstantRVal(rhs->to<IR::Constant>()->value));
        }

        if (auto* lookahead = rhs->to<IR::BFN::LookaheadExpression>()) {
            auto bits = lookahead->bitRange().shiftedByBits(currentBit);
            return new IR::BFN::Extract(s->srcInfo, s->left,
                     new IR::BFN::PacketRVal(bits));
        }

        // Allow slices if we'd allow the expression being sliced.
        if (auto* slice = rhs->to<IR::Slice>()) {
            if (canEvaluateInParser(slice->e0))
                return new IR::BFN::Extract(s->srcInfo, s->left,
                                            new IR::BFN::ComputedRVal(rhs));
        }

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
                          const IR::Vector<IR::Expression> &selectExprs) {
    if (key->is<IR::DefaultExpression>())
        return match_t();
    else if (auto k = key->to<IR::Constant>())
        return match_t(match_size, k->asLong(), ~((~uintmax_t(0)) << match_size));
    else if (auto mask = key->to<IR::Mask>())
        return match_t(match_size, mask->left->to<IR::Constant>()->asLong(),
                                   mask->right->to<IR::Constant>()->asLong());
    else if (auto list = key->to<IR::ListExpression>())
        return buildListMatch(&list->components, selectExprs);
    else
        BUG("Invalid select case expression %1%", key);
    return match_t();
}

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

IR::BFN::ParserState* GetBackendParser::getState(cstring name) {
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
        state = new IR::BFN::ParserState(state->p4State,
                                         createThreadName(state->gress, unrolledName),
                                         state->gress);
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
                                              state->gress);
    for (auto* statement : state->p4State->components)
        state->statements.pushBackOrAppend(statement->apply(rewriteStatements));

    // Compute the new state's shift.
    auto bitShift = rewriteStatements.bitTotalShift();

    if (parserPragmas.force_shift.count(state->p4State))
        bitShift += parserPragmas.force_shift.at(state->p4State);

    nw_bitinterval bitsAdvanced(0, bitShift);
    if (!bitsAdvanced.isHiAligned())
        ::warning("Parser state %1% does not end on a byte boundary; "
                  "adding padding.", state->p4State->controlPlaneName());
    auto shift = bitsAdvanced.nextByte();

#if HAVE_JBAY
    /* This is a hack - JBay's EPB buffer is tapped off at 4 byte intervals rather
     * than like every byte in Tofino. This means the buffer size to extract egress
     * metadata must be a muliple of 4 rounded up. The right way to do this is to
     * get a Jbay_instrinsic_metadata.p4 file with the right paddings so that the
     * compiler is agnosic about these restrictions. For now, this change along
     * with JBayPardeSpec::byteEgressMetadataSize are together working around this
     * issue. The other fix is to remove Tofino specific metadata size hardcoded
     * in parde_spec.cpp since that completely negates the aspect of including these
     * files
     */
    if ((Device::currentDevice() == "JBay") && (name == "$egress_metadata")) {
        shift = ((shift+3)/4)*4;
    }
#endif

    LOG2("GetParser::state(" << name << ")");

    // case 1: no select
    if (!state->p4State->selectExpression) return state;

    // case 2: @pragma terminate_parsing applied on this state
    if (parserPragmas.terminate_parsing.count(state->p4State)) {
        addTransition(state, match_t(), shift, "accept");
        return state;
    }

    // case 3: unconditional transition, e.g. accept/reject
    if (auto* path = state->p4State->selectExpression->to<IR::PathExpression>()) {
        bool ok = addTransition(state, match_t(), shift, path->path->name);
        return ok ? state : nullptr;
    }

    // case 4: we have a select expression. Lower it to Tofino IR.
    auto* p4Select = state->p4State->selectExpression->to<IR::SelectExpression>();

    BUG_CHECK(p4Select, "Invalid select expression %1%", state->p4State->selectExpression);

    auto& selectExprs = p4Select->select->components;
    auto& selectCases = p4Select->selectCases;

    // FIXME multiple exprs can share match if they reside in same byte
    // FIXME duplicated match exprs, is this legal in the language?

    int matchSize = 0;

    for (auto* selectExpr : selectExprs) {
        nw_bitrange bitrange;
        state->selects.pushBackOrAppend(rewriteSelectExpr(selectExpr, bitShift, bitrange));
        matchSize += selectExpr->type->width_bits();
    }

    // Generate the outgoing transitions.
    for (auto selectCase : selectCases) {
        // parser_value_set shows up as a path expression in the select case.
        if (auto path = selectCase->keyset->to<IR::PathExpression>()) {
            auto decl = refMap->getDeclaration(path->path, true);
            auto pvs = decl->to<IR::P4ValueSet>();
            CHECK_NULL(pvs);
            addTransition(state, match_t(), shift, selectCase->state->path->name, pvs);
        } else {
            auto matchVal = buildMatch(matchSize, selectCase->keyset, selectExprs);
            bool ok = addTransition(state, matchVal, shift, selectCase->state->path->name);
            if (!ok) return nullptr;
        }
    }

    return state;
}

void ExtractParser::postorder(const IR::BFN::TranslatedP4Parser* parser) {
    ParserPragmas pg;
    parser->apply(pg);

    GetBackendParser gp(refMap, typeMap, pg);
    rv->thread[parser->thread].parser = gp.extract(parser);
}

void ExtractParser::end_apply() {
    if (LOGGING(3)) {
        DumpParser dp("extract_parser.dot");
        rv->apply(dp);
    }
}

/// XXX(hanw): This pass must be applied to IR::BFN::Pipe. It modifies the
/// ingress and egress parser to insert parser state that deals with tofino
/// intrinsic metadata and resubmit/mirror metadata. It does not have to be
/// in the backend though. The compiler should be able to insert placeholder
/// parser state in the midend instead, and let the backend to insert the
/// intrinsic metadata extraction logic based on the target device (tofino/jbay).
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
