#include "extract_parser.h"

#include <algorithm>
#include <map>
#include <utility>
#include <vector>

#include "ir/ir.h"
#include "lib/log.h"
#include "bf-p4c/midend/parser_graph.h"
#include "bf-p4c/device.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/parde/add_parde_metadata.h"
#include "bf-p4c/parde/dump_parser.h"
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
            if (!max_loop || max_loop->asUnsigned() == 0) {
                ::warning("@pragma max_loop_depth must be greater than one, skipping: %1%", annot);
                return false;
            }

            ::warning("Parser state %1% will be unrolled up to %2% "
                      "times due to @pragma max_loop_depth.", ps->name, max_loop->asInt());

            max_loop_depth[ps] = max_loop->asUnsigned();
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
            ::fatal_error("Slice is empty: %1%", slice);

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

/// Collect loop information in the frontend parser IR.
///   - Where are the loops?
///   - What is the depth (max iterations) of each loop?
struct ParserLoopsInfo {
    /// Infer loop depth by looking at the stack size of stack references in the
    /// state.
    struct GetMaxLoopDepth : public Inspector {
        bool has_next = false;
        int max_loop_depth = -1;

        bool preorder(const IR::HeaderStackItemRef* ref) override {
            auto stack_size = ref->base()->type->to<IR::Type_Stack>()
                                         ->size->to<IR::Constant>()->asInt();

            if (max_loop_depth == -1)
                max_loop_depth = stack_size;
            else
                max_loop_depth = std::min(max_loop_depth, stack_size);

            return true;
        }

        bool preorder(const IR::BFN::UnresolvedHeaderStackIndex* unresolved) override {
            if (unresolved->index == "next")
                has_next = true;

            return false;
        }
    };

    ParserLoopsInfo(P4::TypeMap* typeMap, P4::ReferenceMap* refMap,
                    const IR::BFN::TnaParser* parser) {
        P4ParserGraphs pg(refMap, typeMap, false);
        parser->apply(pg);

        loops = pg.compute_loops(parser);

        LOG2("detected " << loops.size() << " loops in " << parser->thread << " parser");

        if (LOGGING(2)) {
            unsigned id = 0;
            for (auto& loop : loops) {
                std::clog << "loop " << id++ << " : [ ";
                for (auto s : loop)
                    std::clog << s << " ";
                std::clog << " ]" << std::endl;
            }
        }

        for (auto& loop : loops) {
            for (auto s : loop) {
                auto state = pg.get_state(parser, s);
                GetMaxLoopDepth mld;
                state->apply(mld);

                max_loop_depth[s] = mld.max_loop_depth;
                LOG3("inferred loop depth " << max_loop_depth[s] << " for " << s);

                if (mld.max_loop_depth > 1 && mld.has_next)
                    has_next.insert(s);
            }
        }
    }

    std::set<std::set<cstring>> loops;
    std::map<cstring, int> max_loop_depth;
    std::set<cstring> has_next;   // states that have stack "next" references

    const std::set<cstring>* find_loop(cstring state) const {
        for (auto& loop : loops) {
            if (loop.count(state))
                return &loop;
        }

        return nullptr;
    }

    /// Returns true if the state is on loop that does not have "next" reference.
    /// It's always safe to keep the simple loops (as opposed to unrolled) as these
    /// do not need to PHV allocation to be at strided offset.
    bool is_on_simple_loop(cstring state) const {
        auto loop = find_loop(state);
        if (!loop) return false;

        for (auto s : *loop) {
            if (has_next.count(s))
                return false;
        }

        return true;
    }
};

/// Keeps track of visited states which are all ancestors
/// to the current state.
struct AncestorStates {
    /// We maintain the visited states in a stack as we visit
    /// in a DFS order.
    std::vector<const IR::BFN::ParserState*> stack;

    /// Encounter this state, push to stack.
    void push(const IR::BFN::ParserState* state) {
        stack.push_back(state);
    }

    /// Done visiting this state and all of its descendants, pop it
    /// off the stack.
    void pop() {
        stack.pop_back();
    }

    bool visited(const IR::BFN::ParserState* state) const {
        return std::find(stack.begin(), stack.end(), state) != stack.end();
    }

    /// Given the state with the original name, check on the visited
    /// stack that how many times this state has been unrolled.
    unsigned getCurrentIteration(cstring origName) const {
        unsigned it = 0;
        for (auto s : stack) {
            if (s->name == origName || s->name.startsWith(origName + ".$it"))
                it++;
        }
        return it;
    }

    struct GetHeaderStackIndex : public Inspector {
        cstring header;
        int rv = -1;

        explicit GetHeaderStackIndex(cstring hdr) : header(hdr) { }

        bool preorder(const IR::HeaderStackItemRef* ref) override {
            auto hdr = ref->baseRef()->name;

            if (hdr == header) {
                auto index = ref->index()->to<IR::Constant>();
                rv = index->asUnsigned();
            }

            return false;
        }

        void postorder(const IR::MethodCallStatement* statement) override {
            auto* call = statement->methodCall;
            if (auto* method = call->method->to<IR::Member>()) {
                if (method->member == "extract") {
                    auto dest = (*call->arguments)[0]->expression;
                    auto hdr = dest->to<IR::HeaderRef>();

                    if (!hdr->is<IR::HeaderStackItemRef>()) {
                        if (header == hdr->to<IR::ConcreteHeaderRef>()->ref->name) {
                            rv = 0;
                        }
                    }
                }
            }
        }
    };

    int getCurrentIndex(cstring header) {
        int rv = -1;

        for (auto state : stack) {
            GetHeaderStackIndex getHeaderStackIndex(header);
            state->p4State->apply(getHeaderStackIndex);

            // XXX(zma) taking a shortcut here of computing current index
            // by getting the max index of all references of the header
            // on current ancestor stack. This is incorrect if there are
            // multiple inconsistent previous indices that may lead to the
            // current state, in which case, it's an user error (cannot
            // consistently resolve the header stack index). The right thing
            // to do is look at the parse graph and check the indices of all
            // previous references are consistent.
            if (getHeaderStackIndex.rv > rv)
                rv = getHeaderStackIndex.rv;
        }

        return rv + 1;
    }
};

/// Converts frontend parser IR into backend IR
class GetBackendParser {
 public:
    explicit GetBackendParser(P4::TypeMap *typeMap,
                              P4::ReferenceMap *refMap,
                              ParseTna* arch,
                              const IR::BFN::TnaParser* parser) :
            typeMap(typeMap), refMap(refMap), arch(arch), parser(parser),
            parserLoopsInfo(typeMap, refMap, parser) {
        parser->apply(parserPragmas);
    }

    const IR::BFN::Parser* createBackendParser();

    void addTransition(IR::BFN::ParserState* state, match_t matchVal, int shift, cstring nextState,
                       const IR::P4ValueSet* valueSet = nullptr);

 private:
    IR::BFN::ParserState* convertBody(IR::BFN::ParserState* state);

    IR::BFN::ParserState* convertState(cstring name, bool& isLoopState);

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

    std::map<cstring, IR::BFN::ParserState*>    backendStates;
    std::map<IR::BFN::ParserState*, const IR::ParserState*> origP4States;

    std::map<cstring, unsigned>                 max_loop_depth;   // state name tp depth
    std::map<cstring, cstring>                  p4StateNameToStateName;

    P4::TypeMap*      typeMap;
    P4::ReferenceMap* refMap;
    ParseTna*         arch;
    const IR::BFN::TnaParser* parser;

    ParserPragmas parserPragmas;
    ParserLoopsInfo parserLoopsInfo;

    // used to keep track of visiter ancestor states at the current state
    AncestorStates ancestors;
};

const IR::BFN::Parser*
GetBackendParser::createBackendParser() {
    for (auto state : parser->states) {
        auto stateName = getStateName(state);

        if (state->name == "accept" || state->name == "reject")
            continue;

        auto backendState = new IR::BFN::ParserState(state,
                                   createThreadName(parser->thread, stateName),
                                   parser->thread);

        backendStates[stateName] = backendState;
        origP4States[backendState] = state;

        if (parserPragmas.max_loop_depth.count(state))
            max_loop_depth[stateName] = parserPragmas.max_loop_depth.at(state);
        else if (parserLoopsInfo.max_loop_depth.count(state->name))
            max_loop_depth[stateName] = parserLoopsInfo.max_loop_depth.at(state->name);
    }

    bool isLoopState = false;
    IR::BFN::ParserState* startState = convertState(getStateName("start"), isLoopState);

    BlockInfoMapping* binfo = &arch->toBlockInfo;
    IR::ID multiParserName;
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

    IR::ID parserName = parser->name;
    if (arch->hasMultipleParsers) {
        BUG_CHECK(!multiParserName.toString().isNullOrEmpty(),
                "No multi parser block name generated for parser %1%", parser->name);
        parserName = multiParserName;
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

    return new IR::BFN::Parser(parser->thread, startState, parserName, phase0, parser->portmap);
}

void GetBackendParser::addTransition(IR::BFN::ParserState* state, match_t matchVal,
                                     int shift, cstring nextState, const IR::P4ValueSet* valueSet) {
    LOG4("addTransition: " << state->name << " -> " << nextState);

    IR::BFN::ParserMatchValue* match_value_ir = nullptr;
    if (valueSet) {
        // Convert IR::Constant to unsigned int.
        size_t sz = 0;
        auto sizeConstant = valueSet->size->to<IR::Constant>();
        if (sizeConstant == nullptr || !sizeConstant->fitsUint())
            ::fatal_error("parser value set should have an unsigned integer as size %1%", valueSet);
        sz = sizeConstant->asUnsigned();
        match_value_ir = new IR::BFN::ParserPvsMatchValue(valueSet->controlPlaneName(), sz);
    } else {
        match_value_ir = new IR::BFN::ParserConstMatchValue(matchVal);
    }
    auto* transition = new IR::BFN::Transition(match_value_ir, shift, nullptr);

    ancestors.push(state);

    bool isLoopState = false;
    auto next = convertState(getStateName(nextState), isLoopState);

    if (isLoopState)
        transition->loop = next->name;
    else
        transition->next = next;

    state->transitions.push_back(transition);
    ancestors.pop();
}

/// Resolves the "next" and "last" stack references according to the spec.
/// Call this on the frontend IR::ParserState node; will resolve all
/// IR::BFN::UnresolvedHeaderStackIndex into concrete indices.
struct ResolveHeaderStackIndex : public Transform {
    const IR::BFN::ParserState* state;
    AncestorStates& ancestors;

    /// Local map of header to stack index.
    /// The stack index can be advanced multiple times in the current state.
    std::map<cstring, int> headerToCurrentIndex;

    bool stackOutOfBound = false;

    ResolveHeaderStackIndex(const IR::BFN::ParserState* s, AncestorStates& ans) :
        state(s), ancestors(ans) { }

    bool isStackOutOfBound(const IR::HeaderStackItemRef* ref, int index) {
        auto stackSize = ref->base()->type->to<IR::Type_Stack>()
                                     ->size->to<IR::Constant>()->asInt();

        return index < 0 || index >= stackSize;
    }

    /// Returns the current stack index of the header.
    /// Looks into the visited ancestor states and see what's the current index.
    /// If not found in ancestor states, we are visiting this header for the first
    /// time.
    int getCurrentIndex(cstring header) {
        int currentIndex = -1;

        if (headerToCurrentIndex.count(header)) {
            currentIndex = headerToCurrentIndex.at(header);
        } else {
            currentIndex = ancestors.getCurrentIndex(header);
            headerToCurrentIndex[header] = currentIndex;
        }

        return currentIndex;
    }

    IR::Node* postorder(IR::MethodCallStatement* statement) override {
        auto* call = statement->methodCall;
        if (auto* method = call->method->to<IR::Member>()) {
            if (method->member == "extract") {
                auto dest = (*call->arguments)[0]->expression;
                auto hdr = dest->to<IR::HeaderRef>();

                if (!hdr->is<IR::HeaderStackItemRef>()) {
                    auto header = hdr->to<IR::ConcreteHeaderRef>()->ref->name;

                    int currentIndex = getCurrentIndex(header);

                    // For normal header, we allow single extract.
                    if (currentIndex > 0) {
                        stackOutOfBound = true;
                    }
                }
            }
        }

        return statement;
    }

    IR::Node* preorder(IR::BFN::UnresolvedHeaderStackIndex* unresolved) override {
        auto ref = findContext<IR::HeaderStackItemRef>();
        auto header = ref->baseRef()->name;

        int currentIndex = getCurrentIndex(header);

        // "last" refers to the previous index from the current index
        if (unresolved->index == "last")
            currentIndex--;

        if (isStackOutOfBound(ref, currentIndex))
            stackOutOfBound = true;

        LOG4("resolved " << header << " stack index " << unresolved->index
                         << " to " << currentIndex);

        auto resolved = new IR::Constant(currentIndex);

        auto statement = findContext<IR::MethodCallStatement>();
        if (statement) {
            auto call = statement->methodCall;
            if (auto method = call->method->to<IR::Member>()) {
                // "next" is "automatically advanced on each successful call to extract"
                if (method->member == "extract" && unresolved->index == "next") {
                    headerToCurrentIndex[header]++;
                }
            }
        }

        return resolved;
    }
};

/// Rewrites frontend parser IR statements to the backend ones.
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
            ::fatal_error("Advancing by a non-constant distance is not supported on "
                    "%1%: %2%", Device::name(), bits);
            return nullptr;
        }

        auto bitOffset = bits->to<IR::Constant>()->asInt();
        if (bitOffset < 0) {
            ::fatal_error("Advancing by a negative distance is not supported on "
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
                auto* subtract = new IR::BFN::ChecksumSubtract(declName, rval,
                                                               swap, isChecksum);
                lastChecksumSubtract = subtract;
                lastSubtractField = member;

                rv->push_back(subtract);
            }
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

    int getHeaderEndPos(const IR::BFN::ChecksumSubtract* lastSubtract,
                        const IR::Member* lastSubtractField) {
        auto v = lastSubtract->source->to<IR::BFN::PacketRVal>();
        int lastBitSubtract = v->range.toUnit<RangeUnit::Bit>().hi;
        if (lastBitSubtract % 8 != 7) {
            ::fatal_error("Checksum subtract ends at non-byte-aligned field %1%",
                          lastSubtractField);
        }

        auto* headerRef = lastSubtractField->expr->to<IR::ConcreteHeaderRef>();
        auto header = headerRef->baseRef();
        int endPos = 0;
        for (auto field :  header->type->fields) {
            if (field->name == lastSubtractField->member) {
                endPos = lastBitSubtract;
            } else if (endPos > 0) {
                endPos += field->type->width_bits();
            }
        }
        return endPos;
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
                        if (!lastChecksumSubtract || !lastSubtractField) {
                            ::fatal_error("Checksum \"get\" must have preceding \"subtract\""
                                          " call in the same parser state");
                        }
                        auto endPos = getHeaderEndPos(lastChecksumSubtract, lastSubtractField);
                        auto endByte = new IR::BFN::PacketRVal(StartLen(endPos, 8));
                        auto get = new IR::BFN::ChecksumGet(declName,
                                              new IR::BFN::FieldLVal(mem), endByte);
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
            ::fatal_error("Assignment source cannot be evaluated in the parser: %1%", rhs);
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

    const IR::Member* lastSubtractField = nullptr;
    const IR::BFN::ChecksumSubtract* lastChecksumSubtract = nullptr;
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
                        ::fatal_error("Illegal parser counter expression: %1%", selectExpr);
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

IR::BFN::ParserState* GetBackendParser::convertState(cstring name, bool& isLoopState) {
    LOG4("convert state: " << name);

    if (name == "accept" || name == "reject")
        return nullptr;

    BUG_CHECK(backendStates.count(name), "No definition for parser state %1%", name);

    auto* state = backendStates[name];

    if (ancestors.visited(state)) {
        LOG3("parser state " << name << " is in a loop");

        if (parserPragmas.dont_unroll.count(name) ||
            parserLoopsInfo.is_on_simple_loop(name)) {
            isLoopState = true;
            return state;
        }

        BUG_CHECK(max_loop_depth.count(name), "unable to infer loop bound for %1%?", name);

        auto origName = getStateName(name);
        auto iteration = ancestors.getCurrentIteration(createThreadName(state->gress, origName));

        if (max_loop_depth.at(name) == iteration) {
            // reached max loop depth, no more unrolling is allowed
            // TODO handle stack out of bound (transition to reject and setup parser error)
            return nullptr;
        }

        auto iterationSuffix = ".$it" + cstring::to_cstring(iteration);
        auto unrolledName = origName + iterationSuffix;

        if (backendStates.count(unrolledName)) {
            // current iteration already unrolled, reuse this state
            return backendStates.at(unrolledName);
        } else {
            // unroll current iteration by creating a new empty instance of this
            // state, which we'll convert again.
            auto newName = cstring::make_unique(backendStates, unrolledName);

            state = new IR::BFN::ParserState(origP4States.at(state),
                                             createThreadName(state->gress, newName),
                                             state->gress);
            backendStates[newName] = state;
            return convertBody(state);
        }
    } else if (!state->transitions.empty()) {
        // We've already generated the matches for this state, so we know we've
        // already converted it; just return.
        return state;
    }

    return convertBody(state);
}

IR::BFN::ParserState*
GetBackendParser::convertBody(IR::BFN::ParserState* state) {
    ResolveHeaderStackIndex resolveHeaderStackIndex(state, ancestors);
    auto resolved = state->p4State->apply(resolveHeaderStackIndex)->to<IR::ParserState>();

    if (resolveHeaderStackIndex.stackOutOfBound) {
        LOG4("stack out of bound at " << state->name);
        return nullptr;
    }

    state->p4State = resolved;

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

    // case 1: no select
    if (!state->p4State->selectExpression) return state;

    // case 2: @pragma terminate_parsing applied on this state
    if (parserPragmas.terminate_parsing.count(state->p4State)) {
        addTransition(state, match_t(), shift, "accept");
        return state;
    }

    // case 3: unconditional transition, e.g. accept/reject
    if (auto* path = state->p4State->selectExpression->to<IR::PathExpression>()) {
        addTransition(state, match_t(), shift, path->path->name);
        return state;
    }

    // case 4: we have a select expression. Lower it to Tofino IR.
    auto* p4Select = state->p4State->selectExpression->to<IR::SelectExpression>();

    BUG_CHECK(p4Select, "Invalid select expression %1%", state->p4State->selectExpression);

    auto& selectExprs = p4Select->select->components;
    auto& selectCases = p4Select->selectCases;

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
            addTransition(state, matchVal, shift, selectCase->state->path->name);
        }
    }

    return state;
}

void ExtractParser::postorder(const IR::BFN::TnaParser* parser) {
    GetBackendParser gp(typeMap, refMap, arch, parser);
    auto backendParser = gp.createBackendParser();
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
        new AddParserMetadata(rv, useV1model),
        new AddDeparserMetadata(rv),
    });
}

}  // namespace BFN
