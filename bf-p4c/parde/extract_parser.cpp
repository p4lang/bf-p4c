#include "extract_parser.h"

#include <algorithm>
#include <map>
#include <utility>
#include <vector>

#include "ir/ir.h"
#include "lib/log.h"
#include "bf-p4c/device.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/parde/add_parde_metadata.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/resolve_parser_stack_index.h"
#include "bf-p4c/parde/gen_deparser.h"

namespace BFN {

using BlockInfoMapping = std::multimap<const IR::Node*, BlockInfo>;

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
        auto p = findContext<IR::BFN::TnaParser>();
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
            if (!shift_amt || shift_amt->asInt() < 0) {
                ::warning("@pragma force_shift must have positive shift amount(bits)");
                return false;
            }

            if (gress->value == toString(p->thread)) {
                force_shift[ps] = shift_amt->asInt();
            }
        } else if (pragma_name == "max_loop_depth") {
            auto& exprs = annot->expr;
            if (!checkNumArgs(pragma_name, exprs, 1))
            return false;

            auto max_loop = exprs[0]->to<IR::Constant>();
            if (!max_loop || max_loop->asInt() < 1) {
                ::warning("@pragma max_loop_depth must >= 1, skipping: %1%", annot);
                return false;
            }

            ::warning("Parser state %1% will be unrolled up to %2% "
                      "times due to @pragma max_loop_depth.", ps->name, max_loop->asInt());

            max_loop_depth[ps] = max_loop->asInt();
        } else if (pragma_name == "dont_unroll") {
            ::warning("Parser state %1% will not be unrolled because of @pragma dont_unroll",
                       ps->name);

            dont_unroll.insert(ps->name);
        }

        return false;
    }

    std::set<const IR::ParserState*> terminate_parsing;
    std::map<const IR::ParserState*, unsigned> force_shift;
    std::map<const IR::ParserState*, unsigned> max_loop_depth;

    std::set<cstring> dont_unroll;
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
        if (dest->is<IR::Slice>()) {
            P4C_UNIMPLEMENTED("Cannot extract to a field slice in the parser: %1%", dest);
        } else if (!dest->is<IR::Member>() && !dest->is<IR::ConcreteHeaderRef>()) {
            ::warning("Unexpected extract destination: %1%", dest);
            return std::make_pair(dest->toString(), 1);
        }
        if (auto* hdrRef = dest->to<IR::ConcreteHeaderRef>()) {
            auto destName = hdrRef->baseRef()->name;
            int allowedExtracts = hdrRef->baseRef()->type->to<IR::Type_Header>()
                                          ->annotations->annotations.size();
            return std::make_pair(destName, std::max(allowedExtracts, 0));
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

// Rewrite p4-14's "current(a,b)" or p4-16's "pkt.lookahead<switch_pkt_src_t>()"
// as IR::BFN::PacketRVal (bit position in the input buffer)
static const IR::BFN::PacketRVal*
rewriteLookahead(P4::TypeMap* typeMap,
                 const IR::MethodCallExpression* call,
                 const IR::Slice* slice,
                 int bitShift) {
    BUG_CHECK(call->typeArguments->size() == 1,
              "Expected 1 type parameter for %1%", call);
    auto* typeArg = call->typeArguments->at(0);
    auto* typeArgType = typeMap->getTypeType(typeArg, true);
    int width = typeArgType->width_bits();
    BUG_CHECK(width > 0, "Non-positive width for lookahead type %1%", typeArg);

    nw_bitrange finalRange;
    if (slice) {
        le_bitrange sliceRange(slice->getL(), slice->getH());
        nw_bitinterval lookaheadInterval =
          sliceRange.toOrder<Endian::Network>(width)
                    .intersectWith(StartLen(0, width));
        if (lookaheadInterval.empty())
            ::error("Slice is empty: %1%", slice);

        auto lookaheadRange = *toClosedRange(lookaheadInterval);
        finalRange = lookaheadRange.shiftedByBits(bitShift);
    } else {
        finalRange = nw_bitrange(StartLen(bitShift, width));
    }
    auto rval = new IR::BFN::PacketRVal(finalRange);
    return rval;
}

static bool isExtern(const IR::Member* method, cstring externName) {
    if (auto pe = method->expr->to<IR::PathExpression>()) {
        if (auto type = pe->type->to<IR::Type_SpecializedCanonical>()) {
            if (auto baseType = type->baseType->to<IR::Type_Extern>())
                if (baseType->name == externName)
                    return true;
        } else if (auto type = pe->type->to<IR::Type_Extern>()) {
            if (type->name == externName)
                return true;
        }
    }
    return false;
}

class GetBackendParser {
 public:
    explicit GetBackendParser(P4::TypeMap *typeMap,
                              P4::ReferenceMap *refMap,
                              const ParserPragmas& pg) :
        typeMap(typeMap), refMap(refMap), parserPragmas(pg) { }

    const IR::BFN::Parser* extract(const IR::BFN::TnaParser* parser, ParseTna *arch);

    bool addTransition(IR::BFN::ParserState* state, match_t matchVal, int shift, cstring nextState,
                       const IR::P4ValueSet* valueSet = nullptr);

 private:
    IR::BFN::ParserState* getState(cstring name, bool& isLoopState);

    // For v1model, compiler may insert parser states, e.g. if @pragma packet_entry is specified.
    // Therefore, the program "start" state may not be the true start state.
    // For TNA, the program "start" state is the start state.
    cstring
    getStateName(const IR::ParserState* state) {
        if (BackendOptions().arch == "v1model") {
            auto stateName = state->controlPlaneName();
            p4StateNameToStateName.emplace(state->name, stateName);
            return stateName;
        } else {
            return state->name;
        }
    }

    cstring
    getStateName(cstring p4Name) {
        if (BackendOptions().arch == "v1model") {
            return p4StateNameToStateName.at(p4Name);
        } else {
            return p4Name;
        }
    }

    const IR::Node* rewriteLookaheadExpr(const IR::MethodCallExpression* call,
                                         const IR::Slice* slice,
                                         int bitShift, nw_bitrange& bitrange);

    const IR::Node* rewriteSelectExpr(const IR::Expression* selectExpr, int bitShift,
                                      nw_bitrange& bitrange);

    TransitionStack                             transitionStack;

    std::map<cstring, IR::BFN::ParserState *>   states;
    std::map<cstring, int>                      max_loop_depth;
    std::map<cstring, cstring>                  p4StateNameToStateName;

    P4::TypeMap*      typeMap;
    P4::ReferenceMap* refMap;
    const ParserPragmas& parserPragmas;
};

const IR::BFN::Parser*
GetBackendParser::extract(const IR::BFN::TnaParser* parser, ParseTna *arch) {
    forAllMatching<IR::ParserState>(parser, [&](const IR::ParserState* state) {
        auto stateName = getStateName(state);

        if (state->name == "accept" || state->name == "reject")
            return false;

        states[stateName] =
          new IR::BFN::ParserState(state,
                                   createThreadName(parser->thread, stateName),
                                   parser->thread);
        if (parserPragmas.max_loop_depth.count(state))
            max_loop_depth[stateName] = parserPragmas.max_loop_depth.at(state);
        return true;
    });

    bool isLoopState = false;
    IR::BFN::ParserState* startState = getState(getStateName("start"), isLoopState);

    BlockInfoMapping* binfo = &arch->toBlockInfo;
    cstring multiParserName = "";
    if (binfo) {
        auto bitr = binfo->begin();
        while (bitr != binfo->end()) {
            auto b = *bitr;
            auto bparser = b.first->to<IR::P4Parser>();
            if (bparser && (bparser->name.originalName == parser->name) &&
                (b.second.gress == parser->thread)) {
                if (!b.second.arch.isNullOrEmpty())
                    multiParserName = b.second.arch;
                binfo->erase(bitr);
                break;
            }
            bitr++;
        }
    }

    IR::BFN::Phase0 *phase0 = nullptr;
    if (parser->phase0) {
        phase0 = parser->phase0->clone();
        // V1Model adds an arch name 'ingressParserImpl' or 'egressParserImpl'
        // which is not used in phase0 table name in backend
        if ((BackendOptions().arch != "v1model") && (!arch->hasMultipleParsers))
            phase0->tableName = parser->name + "." + phase0->tableName;
        // For multi parsers arch, the fully qualified name prefix is determined
        // in the multi parser name generated through block info mapping
        else if (arch->hasMultipleParsers)
            phase0->tableName = multiParserName + "." + phase0->tableName;
    }
    return new IR::BFN::Parser(parser->thread, startState, parser->name, phase0, parser->portmap);
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
        match_value_ir = new IR::BFN::ParserPvsMatchValue(valueSet->name.originalName, sz);
    } else {
        match_value_ir = new IR::BFN::ParserConstMatchValue(matchVal);
    }
    auto* transition = new IR::BFN::Transition(match_value_ir, shift, nullptr);

    AutoPushTransition newTransition(transitionStack, state, transition);
    if (newTransition.isValid) {
        bool isLoopState = false;

        auto next = getState(getStateName(nextState), isLoopState);

        if (isLoopState)
            transition->loop = next->name;
        else
            transition->next = next;

        state->transitions.push_back(transition);

        return true;
    }

    return false;  // One bad transition means the whole state's bad.
}

struct RewriteParserStatements : public Transform {
    RewriteParserStatements(P4::TypeMap* typeMap, cstring stateName, gress_t gress)
        : typeMap(typeMap), stateName(stateName), gress(gress) { }

    /// @return the cumulative shift in bits from all statements rewritten up to
    /// this point.
    int bitTotalShift() const { return currentBit; }

 private:
    const IR::Vector<IR::BFN::ParserPrimitive>*
    rewriteExtract(IR::MethodCallStatement* statement) {
        auto* call = statement->methodCall;

        Util::SourceInfo srcInfo = statement->srcInfo;
        auto dest = (*call->arguments)[0]->expression;

        auto* hdr = dest->to<IR::HeaderRef>();
        auto* hdr_type = hdr->type->to<IR::Type_StructLike>();

        if (gress == EGRESS &&
            hdr_type->getAnnotation("not_extracted_in_egress") != nullptr) {
            ::warning("Ignoring egress extract of @not_extracted_in_egress "
                      "header: %1%", dest);
            return nullptr;
        }

        // Generate an extract operation for each field.
        auto* rv = new IR::Vector<IR::BFN::ParserPrimitive>;
        for (auto field : hdr_type->fields) {
            if (field->type->is<IR::Type::Varbits>())
                BUG("Extraction to varbit field should have been de-sugared in midend.");

            auto* fref = new IR::Member(field->type, hdr, field->name);
            auto width = field->type->width_bits();
            auto* rval = new IR::BFN::PacketRVal(StartLen(currentBit, width));
            auto* extract = new IR::BFN::Extract(srcInfo, fref, rval);

            LOG5("add extract: " << extract);

            currentBit += width;
            rv->push_back(extract);
            extractedFields[fref] = rval;
        }

        if (auto* cf = hdr->to<IR::ConcreteHeaderRef>()) {
            if (cf->ref->to<IR::Metadata>())
                return rv;
        }

        // On Tofino we can only extract and deparse headers with byte
        // alignment. Any non-byte-aligned headers should've been caught by
        // BFN::CheckHeaderAlignment in the midend.
        BUG_CHECK(currentBit % 8 == 0,
                 "A non-byte-aligned header type reached the backend");

        // Generate an extract operation for the POV bit.
        auto* type = IR::Type::Bits::get(1);
        auto* validBit = new IR::Member(type, hdr, "$valid");
        rv->push_back(new IR::BFN::Extract(srcInfo, validBit,
                        new IR::BFN::ConstantRVal(type, 1)));

        return rv;
    }

    const IR::Vector<IR::BFN::ParserPrimitive>*
    rewriteAdvance(IR::MethodCallStatement* statement) {
        auto* call = statement->methodCall;

        auto bits = (*call->arguments)[0]->expression;

        BUG_CHECK(call->arguments->size() == 1,
                  "Wrong number of arguments for method call: %1%", statement);

        if (!bits->is<IR::Constant>()) {
            ::error("Advancing by a non-constant distance is not supported on "
                    "%1%: %2%", Device::name(), bits);
            return nullptr;
        }

        auto bitOffset = bits->to<IR::Constant>()->asInt();
        if (bitOffset < 0) {
            ::error("Advancing by a negative distance is not supported on "
                    "%1%: %2%", Device::name(), bits);
            return nullptr;
        }

        currentBit += bitOffset;
        return nullptr;
    }

    // check if member is header/payload checksum field itself
    // (annotated with @header_checksum/@payload_checksum)
    bool isChecksumField(const IR::Member* member, cstring which) {
        const IR::HeaderOrMetadata* header = nullptr;
        if (auto headerRef = member->expr->to<IR::ConcreteHeaderRef>()) {
            header = headerRef->baseRef();
        } else if (auto headerRef = member->expr->to<IR::HeaderStackItemRef>()) {
            header = headerRef->baseRef();
        } else {
            ::error("Unhandled checksum expression %1%", member);
        }
        for (auto field : header->type->fields) {
            if (field->name == member->member) {
                auto annot = field->annotations->getSingle(which);
                if (annot) return true;
            }
        }
        return false;
    }
    const IR::Vector<IR::BFN::ParserPrimitive>*
    rewriteChecksumAddOrSubtract(const IR::MethodCallExpression* call) {
        auto* method = call->method->to<IR::Member>();
        auto* path = method->expr->to<IR::PathExpression>()->path;
        cstring declName = path->name;
        if (!declNameToOffset.count(declName)) {
            declNameToOffset[declName] = 0;
        }
        auto src = (*call->arguments)[0]->expression;
        IR::Vector<IR::Expression> srcList;
        if (auto listExpr = src->to<IR::ListExpression>()) {
            srcList = listExpr->components;
        } else {
            srcList.push_back(src);
        }
        bool isAdd = method->member == "add";

        auto rv = new IR::Vector<IR::BFN::ParserPrimitive>;
        IR::Vector<IR::Expression> list;
        for (auto srcComp : srcList) {
            if (auto member = srcComp->to<IR::Member>()) {
                list.push_back(member);
            } else if (auto constant = srcComp->to<IR::Constant>()) {
                list.push_back(constant);
            } else if (auto headerRef = srcComp->to<IR::ConcreteHeaderRef>()) {
                auto header = headerRef->baseRef();
                for (auto field : header->type->fields) {
                    auto* member = new IR::Member(src->srcInfo, headerRef, field->name);
                    list.push_back(member);
                }
            }
        }

        for (auto expr : list) {
            bool swap = false;
            if (auto* constant = expr->to<IR::Constant>()) {
                if (constant->asInt() != 0) {
                   P4C_UNIMPLEMENTED(
                   "Non-zero constant entry is not supported in checksum calculation %1%", expr);
                }
                declNameToOffset[declName] += constant->type->width_bits();
                continue;
            }
            auto member = expr->to<IR::Member>();
            BUG_CHECK(member != nullptr,
                      "Invalid field in the checksum calculation : %1%",
                      expr->srcInfo);
            auto hdr = member->expr->to<IR::HeaderRef>();
            BUG_CHECK(hdr != nullptr,
                      "Invalid field in the checksum calculation."
                      " Expecting a header field : %1%", member->srcInfo);
            auto hdr_type = hdr->type->to<IR::Type_StructLike>();
            BUG_CHECK(hdr_type != nullptr,
                      "Header type isn't a structlike: %1%", hdr_type);

            const IR::BFN::PacketRVal* rval = nullptr;
            for (auto kv : extractedFields) {
                auto* extracted = kv.first;
                if (member->member == extracted->member &&
                    member->expr->equiv(*(extracted->expr))) {
                    rval = kv.second;
                    // If a field is on an even byte in the checksum operation field list
                    // but on an odd byte in the input buffer and vice-versa then swap is true.
                    if ((declNameToOffset[declName]/8) % 2 != rval->range.loByte() % 2) {
                        swap = true;
                    }
                    break;
                }
            }
            if (!rval) {
                std::stringstream msg;
                msg << "field in " << declName << " is not extracted in "
                    << stateName <<"."
                    << " Operations on the checksum fields must be in the same parser state "
                    << "where the fields are extracted.";
                ::fatal_error("%1% %2%", expr, msg.str());
            }
            declNameToOffset[declName] += rval->range.size();
            if (isAdd) {
                bool isChecksum = isChecksumField(member, "header_checksum");
                auto* add = new IR::BFN::ChecksumAdd(declName, rval, swap, isChecksum);
                rv->push_back(add);
            } else {
                bool isChecksum = isChecksumField(member, "payload_checksum");
                auto* subtract = new IR::BFN::ChecksumSubtract(declName, rval, member,
                                                               swap, isChecksum);
                rv->push_back(subtract);
            }

            // TODO(zma) checksum field can be metadata
        }
        return rv;
    }

    const IR::Vector<IR::BFN::ParserPrimitive>*
    rewriteChecksumVerify(const IR::MethodCallExpression* call) {
        auto* method = call->method->to<IR::Member>();
        auto* path = method->expr->to<IR::PathExpression>()->path;
        cstring declName = path->name;

        auto* rv = new IR::Vector<IR::BFN::ParserPrimitive>;
        rv->push_back(new IR::BFN::ChecksumVerify(declName));
        return rv;
    }

    const IR::Vector<IR::BFN::ParserPrimitive>*
    rewriteChecksumCall(IR::MethodCallStatement* statement) {
        auto* call = statement->methodCall;
        auto* method = call->method->to<IR::Member>();

        if (method->member == "add" || method->member == "subtract") {
            return rewriteChecksumAddOrSubtract(call);
        } else if (method->member == "verify") {
            return rewriteChecksumVerify(call);
        }

        return nullptr;
    }

    const IR::Vector<IR::BFN::ParserPrimitive>*
    rewriteParserCounterCall(IR::MethodCallStatement* statement) {
        auto* call = statement->methodCall;
        auto* method = call->method->to<IR::Member>();

        auto* path = method->expr->to<IR::PathExpression>()->path;
        cstring declName = path->name;

        auto* rv = new IR::Vector<IR::BFN::ParserPrimitive>;

        if (method->member == "set") {
            if ((*call->arguments).size() == 1) {
                if (auto* imm = (*call->arguments)[0]->expression->to<IR::Constant>()) {
                    // load immediate
                    auto* init = new IR::BFN::ParserCounterLoadImm(declName);
                    init->imm = imm->asInt();

                    rv->push_back(init);
                } else if (auto* field = (*call->arguments)[0]->expression->to<IR::Member>()) {
                    // load field (from match register)
                    auto* load = new IR::BFN::ParserCounterLoadPkt(declName,
                                                                   new IR::BFN::SavedRVal(field));
                    rv->push_back(load);
                } else if (auto* concat = (*call->arguments)[0]->expression->to<IR::Concat>()) {
                    auto* ext = concat->left->to<IR::Constant>();
                    if (ext && ext->asInt() == 0) {
                        if (auto* field = concat->right->to<IR::Member>()) {
                            // load field (from match register)
                            auto* load = new IR::BFN::ParserCounterLoadPkt(declName,
                                                                new IR::BFN::SavedRVal(field));
                            rv->push_back(load);
                        }
                    }
                } else {
                    ::fatal_error("Unsupported syntax of parser counter: %1%", statement);
                }
            } else if ((*call->arguments).size() == 5) {  // load field (from match register)
                auto* field = (*call->arguments)[0]->expression->to<IR::Member>();
                auto* max = (*call->arguments)[1]->expression->to<IR::Constant>();
                auto* rotate = (*call->arguments)[2]->expression->to<IR::Constant>();
                auto* mask = (*call->arguments)[3]->expression->to<IR::Constant>();
                auto* add = (*call->arguments)[4]->expression->to<IR::Constant>();

                if (field && max && rotate && mask && add) {
                    auto* load = new IR::BFN::ParserCounterLoadPkt(declName,
                                                                   new IR::BFN::SavedRVal(field));

                    load->max = max->asInt();
                    load->rotate = rotate->asInt();
                    load->mask = mask->asInt();
                    load->add = add->asInt();

                    rv->push_back(load);
                } else {
                    ::fatal_error("Unsupported syntax of parser counter: %1%", statement);
                }
            }
        } else if (method->member == "increment") {
            auto* value = (*call->arguments)[0]->expression->to<IR::Constant>();
            auto* inc = new IR::BFN::ParserCounterIncrement(declName);
            inc->value = value->asInt();
            rv->push_back(inc);
        } else if (method->member == "decrement") {
            auto value = (*call->arguments)[0]->expression->to<IR::Constant>();
            auto* dec = new IR::BFN::ParserCounterDecrement(declName);
            dec->value = value->asInt();
            rv->push_back(dec);
        }

        return rv;
    }


    const IR::Vector<IR::BFN::ParserPrimitive>*
    rewriteParserPriorityCall(IR::MethodCallStatement* statement) {
        auto* call = statement->methodCall;
        auto* method = call->method->to<IR::Member>();

        auto* rv = new IR::Vector<IR::BFN::ParserPrimitive>;

        if (method->member == "set") {
            auto priority = (*call->arguments)[0]->expression->to<IR::Constant>();
            rv->push_back(new IR::BFN::ParserPrioritySet(priority->asInt()));
        }

        return rv;
    }

    const IR::Vector<IR::BFN::ParserPrimitive>*
    preorder(IR::MethodCallStatement* statement) override {
        auto* call = statement->methodCall;
        if (auto* method = call->method->to<IR::Member>()) {
            if (isExtern(method, "Checksum")) {
                return rewriteChecksumCall(statement);
            } else if (isExtern(method, "ParserCounter")) {
                return rewriteParserCounterCall(statement);
            } else if (isExtern(method, "ParserPriority")) {
                return rewriteParserPriorityCall(statement);
            } else if (method->member == "extract") {
                return rewriteExtract(statement);
            } else if (method->member == "advance") {
                return rewriteAdvance(statement);
            }
        } else if (auto* method = call->method->to<IR::PathExpression>()) {
            if (method->path->name == "verify") {
                // XXX(zma) allow this to go through to enable more testing
                ::warning("Parser \"verify\" is currently unsupported %s", statement->srcInfo);
                return nullptr;
            }
        }

        ::fatal_error("Unexpected method call in parser %s", statement);
        return nullptr;
    }

    bool canEvaluateInParser(const IR::Expression* expression) const {
        // We can't evaluate complex expressions on current hardware.
        return expression->is<IR::Constant>() ||
               expression->is<IR::BoolLiteral>() ||
               expression->is<IR::PathExpression>() ||
               expression->is<IR::Member>() ||
               expression->is<IR::HeaderStackItemRef>() ||
               expression->is<IR::TempVar>() ||
               expression->is<IR::MethodCallExpression>();  // verify checksum
    }

    const IR::BFN::Extract*
    createBitwiseOrExtract(const IR::Expression* dest,
                           const IR::Expression* src,
                           Util::SourceInfo srcInfo) {
        IR::BFN::Extract* e = nullptr;

        if (auto c = src->to<IR::Constant>()) {
            e = new IR::BFN::Extract(srcInfo, dest, new IR::BFN::ConstantRVal(c));
        } else {
            e = new IR::BFN::Extract(srcInfo, dest, new IR::BFN::SavedRVal(src));
        }

        e->write_mode = IR::BFN::ParserWriteMode::BITWISE_OR;

        return e;
    }

    const IR::BFN::ParserPrimitive*
    preorder(IR::AssignmentStatement* s) override {
        if (s->left->type->is<IR::Type::Varbits>())
            BUG("Extraction to varbit field should have been de-sugared in midend.");

        auto lhs = s->left;
        auto rhs = s->right;

        // no bits are lost by throwing away IR::BFN::ReinterpretCast.
        if (rhs->is<IR::BFN::ReinterpretCast>())
            rhs = rhs->to<IR::BFN::ReinterpretCast>()->expr;

        if (auto mc = rhs->to<IR::MethodCallExpression>()) {
            if (auto* method = mc->method->to<IR::Member>()) {
                if (isExtern(method, "Checksum")) {
                    auto* path = method->expr->to<IR::PathExpression>()->path;
                    cstring declName = path->name;

                    if (method->member == "verify") {
                        auto verify = new IR::BFN::ChecksumVerify(declName);
                        if (auto mem = lhs->to<IR::Member>())
                            verify->dest = new IR::BFN::FieldLVal(mem);
                        else if (auto sl = lhs->to<IR::Slice>())
                            verify->dest = new IR::BFN::FieldLVal(sl);
                        return verify;
                    } else if (method->member == "get") {
                        auto mem = lhs->to<IR::Member>();
                        auto get = new IR::BFN::ChecksumGet(declName, new IR::BFN::FieldLVal(mem));
                        return get;
                    }
                }
            }
        }

        if (auto* slice = rhs->to<IR::Slice>()) {
            if (auto* call = slice->e0->to<IR::MethodCallExpression>()) {
                if (auto* mem = call->method->to<IR::Member>()) {
                    if (mem->member == "lookahead") {
                        auto rval = rewriteLookahead(typeMap, call, slice, currentBit);
                        return new IR::BFN::Extract(s->srcInfo, lhs, rval);
                    }
                }
            }
        } else if (auto* call = rhs->to<IR::MethodCallExpression>()) {
            if (auto* mem = call->method->to<IR::Member>()) {
                if (mem->member == "lookahead") {
                    auto rval = rewriteLookahead(typeMap, call, slice, currentBit);
                    return new IR::BFN::Extract(s->srcInfo, lhs, rval);
                }
            }
        }

        if (auto mem = lhs->to<IR::Member>()) {
            if (mem->member == "ingress_parser_err" || mem->member == "egress_parser_err")
                return nullptr;
        }

        if (rhs->is<IR::Constant>() || rhs->is<IR::BoolLiteral>()) {
            auto* rhsConst = rhs->to<IR::Constant>();
            if (!rhsConst)  // boolean
                rhsConst = new IR::Constant(rhs->to<IR::BoolLiteral>()->value ? 1 : 0);
            return new IR::BFN::Extract(s->srcInfo, s->left,
                     new IR::BFN::ConstantRVal(rhsConst->type,
                             rhsConst->value));
        }

        // Allow slices if we'd allow the expression being sliced.
        if (auto* slice = rhs->to<IR::Slice>()) {
            if (canEvaluateInParser(slice->e0))
                return new IR::BFN::Extract(s->srcInfo, lhs,
                                            new IR::BFN::SavedRVal(rhs));
        }

        // a = a | b
        if (auto bor = rhs->to<IR::BOr>()) {
            if (bor->left->equiv(*lhs)) {
                return createBitwiseOrExtract(lhs, bor->right, s->srcInfo);
            } else if (bor->right->equiv(*lhs)) {
                return createBitwiseOrExtract(lhs, bor->left, s->srcInfo);
            }
        }

        if (!canEvaluateInParser(rhs)) {
            ::error("Assignment source cannot be evaluated in the parser: %1%", rhs);
            return nullptr;
        }

        return new IR::BFN::Extract(s->srcInfo, s->left,
                                    new IR::BFN::SavedRVal(rhs));
    }

    const IR::Expression* preorder(IR::Statement* s) override {
        BUG("Unhandled statement kind: %1%", s);
    }

    P4::TypeMap* typeMap;
    const cstring stateName;
    const gress_t gress;
    unsigned currentBit = 0;
    // A bit offset counter for each checksum operation
    std::map<cstring, int> declNameToOffset;
    std::map<const IR::Member*, const IR::BFN::PacketRVal*> extractedFields;
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
        LOG3("el: " << el);
        if (auto k = el->to<IR::Constant>()) {
            v = k->asUnsigned();
        } else if (auto mval = el->to<IR::Mask>()) {
            v = mval->right->to<IR::Constant>()->asUnsigned();
            rv.word0 |= mask & ~v;
            rv.word1 |= mask & ~v;
            mask &= v;
            v = mval->left->to<IR::Constant>()->asUnsigned();
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
    LOG3("key: " << key);
    if (key->is<IR::DefaultExpression>())
        return match_t::dont_care(match_size);
    else if (auto k = key->to<IR::Constant>())
        return match_t(match_size, k->asUnsigned(), ~((~uintmax_t(0)) << match_size));
    else if (auto mask = key->to<IR::Mask>())
        return match_t(match_size, mask->left->to<IR::Constant>()->asUnsigned(),
                                   mask->right->to<IR::Constant>()->asUnsigned());
    else if (auto list = key->to<IR::ListExpression>())
        return buildListMatch(&list->components, selectExprs);
    else
        BUG("Invalid select case expression %1%", key);
    return match_t();
}

const IR::Node*
GetBackendParser::rewriteLookaheadExpr(const IR::MethodCallExpression* call,
                                       const IR::Slice* slice,
                                       int bitShift, nw_bitrange& bitrange) {
    auto rval = rewriteLookahead(typeMap, call, slice, bitShift);
    auto select = new IR::BFN::Select(new IR::BFN::SavedRVal(rval), call);
    bitrange = rval->range;
    return select;
}

const IR::Node*
GetBackendParser::rewriteSelectExpr(const IR::Expression* selectExpr, int bitShift,
                                    nw_bitrange& bitrange) {
    if (auto* cast = selectExpr->to<IR::Cast>()) {
        if (auto* call = cast->expr->to<IR::MethodCallExpression>()) {
            if (auto* method = call->method->to<IR::Member>()) {
                if (isExtern(method, "ParserCounter")) {
                    auto* path = method->expr->to<IR::PathExpression>()->path;
                    cstring declName = path->name;

                    if (method->member == "is_zero") {
                        return new IR::BFN::Select(
                            new IR::BFN::ParserCounterIsZero(declName), call);
                    } else if (method->member == "is_negative") {
                        return new IR::BFN::Select(
                            new IR::BFN::ParserCounterIsNegative(declName), call);
                    } else {
                        ::error("illegal parser counter expr in select");
                    }
                }
            }
        }
    }

    // We can transform a lookahead expression immediately to a concrete select
    // on bits in the input buffer.
    if (auto* slice = selectExpr->to<IR::Slice>()) {
        if (auto* call = slice->e0->to<IR::MethodCallExpression>()) {
            if (auto* mem = call->method->to<IR::Member>()) {
                if (mem->member == "lookahead") {
                    auto rval = rewriteLookahead(typeMap, call, slice, bitShift);
                    auto select = new IR::BFN::Select(new IR::BFN::SavedRVal(rval), call);
                    bitrange = rval->range;
                    return select;
                }
            }
        }
    } else if (auto* call = selectExpr->to<IR::MethodCallExpression>()) {
        if (auto* mem = call->method->to<IR::Member>()) {
            if (mem->member == "lookahead") {
                auto rval = rewriteLookahead(typeMap, call, nullptr, bitShift);
                auto select = new IR::BFN::Select(new IR::BFN::SavedRVal(rval), call);
                bitrange = rval->range;
                return select;
            }
        }
    }

    BUG_CHECK(!selectExpr->is<IR::Constant>(), "%1% constant selection expression %2% "
                                               "should have been eliminated by now.",
                                               selectExpr->srcInfo, selectExpr);

    // We can split a Concat into multiple selects. Note that this is quite
    // unlike a Slice; the Concat operands may not even be adjacent in the input
    // buffer, so this is really two primitive select operations.
    if (auto* concat = selectExpr->to<IR::Concat>()) {
        auto* rv = new IR::Vector<IR::BFN::Select>;
        rv->pushBackOrAppend(rewriteSelectExpr(concat->left, bitShift, bitrange));
        rv->pushBackOrAppend(rewriteSelectExpr(concat->right, bitShift, bitrange));
        return rv;
    }

    // SavedRVal will need to receive a register allocation
    return new IR::BFN::Select(new IR::BFN::SavedRVal(selectExpr), selectExpr);
}

IR::BFN::ParserState* GetBackendParser::getState(cstring name, bool& isLoopState) {
    if (states.count(name) == 0) {
        if (name != "accept" && name != "reject")
            ::error("No definition for parser state %1%", name);
        return nullptr;
    }

    // Check if we've already reached this state on this path, and if so, make
    // sure that the resulting loop is legal.
    auto* state = states[name];
    if (transitionStack.alreadyVisited(state)) {
        LOG2("parser state " << name << " is in a loop");

        if (parserPragmas.dont_unroll.count(name)) {
            isLoopState = true;
            return state;
        }

        if (max_loop_depth.count(name)) {
            max_loop_depth[name]--;
            // no more loop is allowed
            if (max_loop_depth.at(name) == 0)
                return nullptr;
        }
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

    // Lower the parser statements from frontend IR to backend IR.
    RewriteParserStatements rewriteStatements(typeMap,
                                              state->p4State->controlPlaneName(),
                                              state->gress);
    for (auto* statement : state->p4State->components)
        state->statements.pushBackOrAppend(statement->apply(rewriteStatements));
    // Compute the new state's shift.
    auto bitShift = rewriteStatements.bitTotalShift();

    if (parserPragmas.force_shift.count(state->p4State)) {
        bitShift = parserPragmas.force_shift.at(state->p4State);
        ::warning("state %1% will shift %2% bits because of @pragma force_shift",
                  state->name, bitShift);
    }

    nw_bitinterval bitsAdvanced(0, bitShift);

    if (!bitsAdvanced.isHiAligned()) {
        ::fatal_error("Parser state %1% is not byte-aligned (%2% bit shifted)",
                      state->p4State->controlPlaneName(), bitShift);
    }

    auto shift = bitsAdvanced.nextByte();

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
            addTransition(state, match_t::dont_care(matchSize),
                          shift, selectCase->state->path->name, pvs);
        } else {
            auto matchVal = buildMatch(matchSize, selectCase->keyset, selectExprs);
            bool ok = addTransition(state, matchVal, shift, selectCase->state->path->name);
            if (!ok) return nullptr;
        }
    }

    return state;
}

void ExtractParser::postorder(const IR::BFN::TnaParser* parser) {
    ParserPragmas pg;
    parser->apply(pg);

    GetBackendParser gp(typeMap, refMap, pg);
    auto backendParser = gp.extract(parser, arch);
    rv->thread[parser->thread].parsers.push_back(backendParser);
}

void ExtractParser::end_apply() {
    if (LOGGING(3)) {
        DumpParser dp("extract_parser");
        rv->apply(dp);
    }
    Logging::FileLog::close(parserLog);
}

/// XXX(hanw): This pass must be applied to IR::BFN::Pipe. It modifies the
/// ingress and egress parser to insert parser state that deals with tofino
/// intrinsic metadata and resubmit/mirror metadata. It does not have to be
/// in the backend though. The compiler should be able to insert placeholder
/// parser state in the midend instead, and let the backend to insert the
/// intrinsic metadata extraction logic based on the target device (tofino/jbay).
ProcessParde::ProcessParde(const IR::BFN::Pipe* rv, bool useV1model) :
    Logging::PassManager("parser", Logging::Mode::AUTO) {
    setName("ProcessParde");
    addPasses({
        // Attempt to resolve header stack ".next" and ".last" members.
        // XXX(seth): Also, generating the egress deparser from the egress parser
        // correctly requires that we've resolved header stack indices, but that's
        // an artifact of the IR conversion and it's not something that should not
        // be happening at this layer anyway.
        new ResolveHeaderStackValues,
        // Add shims for intrinsic metadata.
        new AddParserMetadataShims(rv, useV1model),
        new AddDeparserMetadataShims(rv),
    });
}

}  // namespace BFN
