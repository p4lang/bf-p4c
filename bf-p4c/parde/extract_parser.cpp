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
                 int bitShift,
                 const IR::Slice* slice = nullptr,
                 const IR::Member* member = nullptr) {
    BUG_CHECK(call->typeArguments->size() == 1,
              "Expected 1 type parameter for %1%", call);

    if (slice && member) BUG("Invalid use of function rewriteLookahead");

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
    } else if (member) {
        auto header = typeArgType->to<IR::Type_Header>();
        unsigned offset = 0;

        for (auto f : header->fields) {
            if (f->name == member->member)
                break;
            offset += f->type->width_bits();
        }

        finalRange = nw_bitrange(StartLen(bitShift + offset, member->type->width_bits()));
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
                const IR::BFN::TnaParser* parser, const ParserPragmas& pm) : parserPragmas(pm) {
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

    const ParserPragmas& parserPragmas;

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

    /// Returns true if the state is on loop that has "next" reference.
    bool has_next_on_loop(cstring state) const {
        auto loop = find_loop(state);
        if (!loop) return false;

        for (auto s : *loop) {
            if (has_next.count(s))
                return true;
        }

        return false;
    }

    bool dont_unroll(cstring state) const {
        auto loop = find_loop(state);
        if (!loop) return false;

        for (auto s : *loop) {
            if (parserPragmas.dont_unroll.count(s))
                return true;
        }

        return !has_next_on_loop(state);
    }

    /// state is on loop that requires strided allocation
    bool need_strided_allocation(cstring state) const {
        return dont_unroll(state) && has_next.count(state);
    }
};

/// Keeps track of visited states which are all ancestors
/// to the current state.
struct AncestorStates {
    /// We maintain the visited states in a stack as we visit
    /// in a DFS order.
    std::vector<IR::BFN::ParserState*> stack;

    /// Encounter this state, push to stack.
    void push(IR::BFN::ParserState* state) {
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
            auto stmt = findContext<IR::AssignmentStatement>();
            if (stmt) {
                auto lhs = stmt->left->to<IR::Member>();
                // Ignore any prior change to $valid
                if (lhs && lhs->member == "$valid") {
                    return false;
                }
            }
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
            parserLoopsInfo(typeMap, refMap, parser, parserPragmas) {
        parser->apply(parserPragmas);
    }

    const IR::BFN::Parser* createBackendParser();

    void addTransition(IR::BFN::ParserState* state, match_t matchVal, int shift, cstring nextState,
                       const IR::P4ValueSet* valueSet = nullptr);

 private:
    IR::BFN::ParserState* convertBody(IR::BFN::ParserState* state);

    IR::BFN::ParserState* convertState(cstring name, bool& isLoopState);

    cstring
    getName(const IR::ParserState* state) {
        auto anno = state->getAnnotation(IR::Annotation::nameAnnotation);
        cstring name = (anno != nullptr) ? anno->getName() : state->name.name;
        return name.startsWith(".") ? name.substr(1) : name;
    }

    // For v1model, compiler may insert parser states, e.g. if @pragma packet_entry is specified.
    // Therefore, the program "start" state may not be the true start state.
    // For TNA, the program "start" state is the start state.
    cstring
    getStateName(const IR::ParserState* state) {
        if (BackendOptions().arch == "v1model") {
            auto stateName = getName(state);
            p4StateNameToStateName.emplace(state->name, stateName);
            return stateName;
        } else {
            return state->name;
        }
    }

    cstring
    getStateName(cstring p4Name) {
        if (BackendOptions().arch == "v1model" && p4StateNameToStateName.count(p4Name)) {
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

    std::map<cstring, unsigned>                 max_loop_depth;   // state name to depth
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

/// Resolves the "next" and "last" stack references according to the spec.
/// Call this on the frontend IR::ParserState node; will resolve all
/// IR::BFN::UnresolvedHeaderStackIndex into concrete indices.
struct ResolveHeaderStackIndex : public Transform {
    IR::BFN::ParserState* state;
    const std::map<cstring, IR::BFN::ParserState*> backendStates;
    const ordered_map<cstring, const IR::ParserState*>* topoAncestors = nullptr;
    std::set<cstring> stridedStates;
    P4ParserGraphs* pg;
    AncestorStates* ancestors = nullptr;

    /// Local map of header to stack index.
    /// The stack index can be advanced multiple times in the current state.
    std::map<cstring, int> headerToCurrentIndex;
    std::set<cstring> resolvedHeaders;

    bool stackOutOfBound = false;

    ResolveHeaderStackIndex(IR::BFN::ParserState* s, AncestorStates* ans) :
        state(s), ancestors(ans) { }

    ResolveHeaderStackIndex(IR::BFN::ParserState* s,
            const std::map<cstring, IR::BFN::ParserState*>& bs,
            const ordered_map<cstring, const IR::ParserState*>* ans,
            P4ParserGraphs* pg) :
        state(s), backendStates(bs), topoAncestors(ans), pg(pg) { }

    bool isStackOutOfBound(const IR::HeaderStackItemRef* ref, int index) {
        auto stackSize = ref->base()->type->to<IR::Type_Stack>()
                                     ->size->to<IR::Constant>()->asInt();

        return index < 0 || index >= stackSize;
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

    // In order to decide the index of headerstack reference, we need to look into its preceding
    // state and then decide its index. Of all preceding states we need to look into closest
    // state that extracts the same header stack in every path. The function recursively
    // looks through each path and determines if the given state is the closest state that extracts
    // the same header stack.
    bool addPrecedingExtractIdx(const IR::ParserState* state,
                    std::map<int, std::set<const IR::ParserState*>>& indexToState,
                    cstring header) {
        GetHeaderStackIndex getHeaderStackIndex(header);
        state->apply(getHeaderStackIndex);
        if (getHeaderStackIndex.rv == -1) return false;
        bool addInResolve = true;
        for (auto succ : pg->succs[state->name]) {
            if (topoAncestors->count(succ)) {
                if (addPrecedingExtractIdx(topoAncestors->at(succ), indexToState, header)) {
                    addInResolve = false;
                } else {
                    addInResolve = true;
                    break;
                }
            }
        }
        if (addInResolve) {
            indexToState[getHeaderStackIndex.rv].insert(state);
        }
        return true;
    }

    int getCurrentIndexFromTopoAncestors(cstring header) {
        std::map<int, std::set<const IR::ParserState*>> indexToState;
        for (auto &anc : *topoAncestors) {
            addPrecedingExtractIdx(anc.second, indexToState, header);
        }
        // multiple reaching indices, we need to mark all ancestors as strided
        if (indexToState.size() > 1) {
            LOG3("unable to consistently resolve header index for " << header);

            for (auto& kv : indexToState) {
                for (auto s : kv.second) {
                    auto* backendState = backendStates.at(s->name);
                    stridedStates.insert(s->name);
                    backendState->stride = true;
                    LOG3("mark " << s->name << " as strided");
                }
            }
            stridedStates.insert(state->p4State->name);
            state->stride = true;
            LOG3("mark " << state->p4State->name << " as strided");
            return 0;
        } else if (indexToState.size() == 1) {
            return indexToState.begin()->first + 1;
        } else {
            return 0;
        }
    }

    /// Returns the current stack index of the header.
    /// Looks into the visited ancestor states and see what's the current index.
    /// If not found in ancestor states, we are visiting this header for the first
    /// time.
    int getCurrentIndex(cstring header) {
        int currentIndex = -1;

        if (headerToCurrentIndex.count(header)) {
            currentIndex = headerToCurrentIndex.at(header);
        } else if (state->stride) {
            // The strided header will be allocated in a loop
            // and whose index increment will be managed by the
            // destination adjustment counter at runtime.
            headerToCurrentIndex[header] = currentIndex = 0;
        } else if (topoAncestors) {
            currentIndex = getCurrentIndexFromTopoAncestors(header);
            headerToCurrentIndex[header] = currentIndex;
        } else {
            currentIndex = ancestors->getCurrentIndex(header);
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
        auto state = findContext<IR::ParserState>();
        auto header = ref->baseRef()->name;

        int currentIndex = getCurrentIndex(header);

        // "last" refers to the previous index from the current index
        if (unresolved->index == "last")
            currentIndex--;

        if (isStackOutOfBound(ref, currentIndex))
            stackOutOfBound = true;

        LOG4("resolved " << header << " stack index " << unresolved->index
                         << " to " << currentIndex << " in state " << state->name);

        resolvedHeaders.insert(header);

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


// This will reset the unresolved header stack references of the state.
// The first hdr.stack.next of the state will be resolve to zero and the other references
// in that state will be resolved only with respect to the first next reference.
// This should be done for state that is marked as strided.
struct ResetHeaderStackIndex : public Transform {
    int currentIndex = 0;
    IR::Node* preorder(IR::BFN::UnresolvedHeaderStackIndex* unresolved) override {
        auto ref = findContext<IR::HeaderStackItemRef>();
        auto state = findContext<IR::ParserState>();
        auto header = ref->baseRef()->name;
        IR::Constant* resolved = nullptr;
        if (unresolved->index == "last") {
            resolved = new IR::Constant(currentIndex - 1);
        } else if (unresolved->index == "next") {
            resolved = new IR::Constant(currentIndex++);
        } else {
            ::error("Unhandled header stack reference");
        }
        LOG4("resolved " << header << " stack index " << unresolved->index
                         << " to " << resolved << " in state " << state->name);
        return resolved;
    }
};

const IR::BFN::Parser*
GetBackendParser::createBackendParser() {
    // 1. create backend states

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

        if (parserLoopsInfo.need_strided_allocation(state->name)) {
            backendState->stride = true;
            LOG3("mark " << state->name << " as strided");
        }
        if (auto dontmerge = state->getAnnotation("dontmerge")) {
            if (dontmerge->expr.size()) {
                auto gress = dontmerge->expr[0]->to<IR::StringLiteral>();
                if (gress->value == toString(parser->thread)) {
                    backendState->dontMerge = true;
                }
            }
        }
    }

    // 2. resolve header stack indices if graph has no loops

    P4ParserGraphs pg(refMap, typeMap, false);
    parser->apply(pg);

    if (!pg.has_loops(parser)) {
        auto topo = pg.topological_sort(parser);

        std::map<cstring, const IR::ParserState*> resolved_map;

        for (auto name : topo) {
            if (name == "accept" || name == "reject")
                continue;

            if (backendStates.count(name)) {
                auto* state = backendStates[name];

                ordered_map<cstring, const IR::ParserState*> ancestors;

                for (auto anc : pg.get_all_ancestors(state->p4State)) {
                    if (resolved_map.count(anc->name))
                        ancestors[anc->name] = resolved_map.at(anc->name);
                }

                ResolveHeaderStackIndex resolveHeaderStackIndex(state, backendStates,
                                                                       &ancestors, &pg);
                auto resolved = state->p4State->apply(resolveHeaderStackIndex)
                                     ->to<IR::ParserState>();
                if (resolveHeaderStackIndex.stackOutOfBound) {
                    LOG4("stack out of bound at " << state->name);
                    resolved = nullptr;
                } else {
                    resolved_map[resolved->name] = resolved;
                }
                for (auto stridedState : resolveHeaderStackIndex.stridedStates) {
                    if (stridedState == name) continue;
                    auto resolved_stride = backendStates.at(stridedState)->p4State
                                          ->apply(ResetHeaderStackIndex())->to<IR::ParserState>();
                    resolved_map[resolved_stride->name] = resolved_stride;
                }
            }
        }
        for (auto &backendState : backendStates) {
             auto* state = backendState.second;
             if (resolved_map.count(state->p4State->name)) {
                 state->p4State = resolved_map.at(state->p4State->name);
             }
        }
    }

    // 3. now convert states and stitch them together

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

    if (parser->phase0 && !parser->phase0->namedByAnnotation) {
        auto phase0 = parser->phase0->clone();
        // V1Model adds an arch name 'ingressParserImpl' or 'egressParserImpl'
        // which is not used in phase0 table name in backend
        if ((BackendOptions().arch != "v1model") && (!arch->hasMultipleParsers))
            phase0->tableName = parser->name + "." + phase0->tableName;
        // For multi parsers arch, the fully qualified name prefix is determined
        // in the multi parser name generated through block info mapping
        else if (arch->hasMultipleParsers)
            phase0->tableName = multiParserName + "." + phase0->tableName;
        return new IR::BFN::Parser(parser->thread, startState, parserName, phase0, parser->portmap);
    }

    return new IR::BFN::Parser(parser->thread, startState, parserName,
                               parser->phase0, parser->portmap);
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
        // P4-14 allows pvs in ingress and egress to share the same name.  We
        // supports this feature in TNA with the 'pd_pvs_name' annotation by
        // overriding the pvs name with the name in the annotation.
        cstring valueSetName;
        if (auto anno = valueSet->annotations->getSingle("pd_pvs_name")) {
            auto name = anno->expr.at(0)->to<IR::StringLiteral>();
            valueSetName = name->value;
        } else {
            valueSetName = valueSet->controlPlaneName();
        }
        match_value_ir = new IR::BFN::ParserPvsMatchValue(valueSetName, sz);
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

const IR::BFN::PacketRVal*
resolveLookahead(P4::TypeMap* typeMap, const IR::Expression* expr, int currentBit) {
    if (auto* slice = expr->to<IR::Slice>()) {
        if (auto* call = slice->e0->to<IR::MethodCallExpression>()) {
            if (auto* mem = call->method->to<IR::Member>()) {
                if (mem->member == "lookahead") {
                    auto rval = rewriteLookahead(typeMap, call, currentBit, slice);
                    return rval;
                }
            }
        }
    } else if (auto* call = expr->to<IR::MethodCallExpression>()) {
        if (auto* mem = call->method->to<IR::Member>()) {
            if (mem->member == "lookahead") {
                auto rval = rewriteLookahead(typeMap, call, currentBit);
                return rval;
            }
        }
    } else if (auto* member = expr->to<IR::Member>()) {
        if (auto* call = member->expr->to<IR::MethodCallExpression>()) {
            if (auto* mem = call->method->to<IR::Member>()) {
                if (mem->member == "lookahead") {
                    auto rval = rewriteLookahead(typeMap, call, currentBit, nullptr, member);
                    return rval;
                }
            }
        }
    }

    return nullptr;
}

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

        auto header = hdr->baseRef()->name;

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

        auto* extractValidBit = new IR::BFN::Extract(srcInfo, validBit,
                        new IR::BFN::ConstantRVal(type, 1));
        LOG5("add extract: " << extractValidBit);
        rv->push_back(extractValidBit);
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
    rewriteSubtractAllAndDeposit(const IR::MethodCallExpression* call) {
        auto* method = call->method->to<IR::Member>();
        auto* path = method->expr->to<IR::PathExpression>()->path;
        cstring declName = path->name;
        auto* rv = new IR::Vector<IR::BFN::ParserPrimitive>;
        auto deposit = (*call->arguments)[0]->expression;
        auto mem = deposit->to<IR::Member>();
        auto endByte = new IR::BFN::PacketRVal(StartLen(currentBit - 8, 8));
        auto get = new IR::BFN::ChecksumResidualDeposit(declName,
                                              new IR::BFN::FieldLVal(mem), endByte);
        rv->push_back(get);
        return rv;
    }

    const IR::Vector<IR::BFN::ParserPrimitive>*
    rewriteChecksumCall(IR::MethodCallStatement* statement) {
        auto* call = statement->methodCall;
        auto* method = call->method->to<IR::Member>();

        if (method->member == "add" || method->member == "subtract") {
            return rewriteChecksumAddOrSubtract(call);
        } else if (method->member == "subtract_all_and_deposit") {
            return rewriteSubtractAllAndDeposit(call);
        } else if (method->member == "verify") {
            return rewriteChecksumVerify(call);
        } else {
            BUG("Unhandled parser checksum call: %1%", statement);
        }

        return nullptr;
    }

    IR::BFN::ParserPrimitive*
    rewriteParserCounterSet(IR::MethodCallStatement* statement, bool push_stack = false) {
        auto* call = statement->methodCall;
        auto* method = call->method->to<IR::Member>();

        auto* path = method->expr->to<IR::PathExpression>()->path;
        cstring declName = path->name;

        if ((*call->arguments).size() == 1 || (push_stack && (*call->arguments).size() == 2)) {
            if (auto* imm = (*call->arguments)[0]->expression->to<IR::Constant>()) {
                // load immediate
                auto* load = new IR::BFN::ParserCounterLoadImm(declName);
                load->imm = imm->asInt();
                load->push = push_stack;
                if ((*call->arguments).size() == 2) {
                    load->update_with_top = (*call->arguments)[1]->expression
                                              ->to<IR::BoolLiteral>()->value;
                }
                return load;
            } else if (auto* rval = resolveLookahead(typeMap,
                                 (*call->arguments)[0]->expression, currentBit)) {
                // load field (from match register)
                auto* load = new IR::BFN::ParserCounterLoadPkt(declName,
                                                           new IR::BFN::SavedRVal(rval));
                load->push = push_stack;
                if ((*call->arguments).size() == 2) {
                    load->update_with_top = (*call->arguments)[1]->expression
                                              ->to<IR::BoolLiteral>()->value;
                }
                return load;
            } else if (auto* member = (*call->arguments)[0]->expression->to<IR::Member>()) {
                // load field (from match register)
                auto* load = new IR::BFN::ParserCounterLoadPkt(declName,
                                                           new IR::BFN::SavedRVal(member));
                load->push = push_stack;
                if ((*call->arguments).size() == 2) {
                    load->update_with_top = (*call->arguments)[1]->expression
                                              ->to<IR::BoolLiteral>()->value;
                }
                return load;
            } else if (auto* concat = (*call->arguments)[0]->expression->to<IR::Concat>()) {
                auto* ext = concat->left->to<IR::Constant>();
                if (ext && ext->asInt() == 0) {
                    if (auto* field = concat->right->to<IR::Member>()) {
                        // load field (from match register)
                        auto* load = new IR::BFN::ParserCounterLoadPkt(declName,
                                                            new IR::BFN::SavedRVal(field));
                        load->push = push_stack;
                        if ((*call->arguments).size() == 2) {
                            load->update_with_top = (*call->arguments)[1]->expression
                                                      ->to<IR::BoolLiteral>()->value;
                        }
                        return load;
                    }
                }
            }
        } else if ((*call->arguments).size() == 5 ||
                   (push_stack && (*call->arguments).size() == 6)) {
            // load field (from match register)
            const IR::Expression* field =
                resolveLookahead(typeMap, (*call->arguments)[0]->expression, currentBit);

            if (!field)
                field = (*call->arguments)[0]->expression->to<IR::Member>();

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
                load->push = push_stack;

                if ((*call->arguments).size() == 6) {
                    load->update_with_top = (*call->arguments)[5]->expression
                                              ->to<IR::BoolLiteral>()->value;
                }

                return load;
            }
        }

        ::fatal_error("Unsupported syntax of parser counter: %1%", statement);
        return nullptr;
    }

    const IR::Vector<IR::BFN::ParserPrimitive>*
    rewriteParserCounterCall(IR::MethodCallStatement* statement) {
        auto* call = statement->methodCall;
        auto* method = call->method->to<IR::Member>();

        auto* path = method->expr->to<IR::PathExpression>()->path;
        cstring declName = path->name;

        auto* rv = new IR::Vector<IR::BFN::ParserPrimitive>;

        if (Device::currentDevice() == Device::TOFINO &&
            (method->member == "push" || method->member == "pop")) {
            ::fatal_error("Tofino's parser does not have counter stack: %1%", statement);
        }

        if (method->member == "set" || method->member == "push") {
            auto set = rewriteParserCounterSet(statement, method->member == "push");
            rv->push_back(set);
        } else if (method->member == "increment") {
            auto* value = (*call->arguments)[0]->expression->to<IR::Constant>();
            auto* inc = new IR::BFN::ParserCounterIncrement(declName);
            if (!value) {
                ::fatal_error("Parser counter increment argument is not a constant integer: %1%",
                              statement);
            }
            inc->value = value->asInt();
            rv->push_back(inc);
        } else if (method->member == "decrement") {
            auto value = (*call->arguments)[0]->expression->to<IR::Constant>();
            if (!value) {
                ::fatal_error("Parser counter decrement argument is not a constant integer: %1%",
                              statement);
            }
            auto* dec = new IR::BFN::ParserCounterDecrement(declName);
            dec->value = value->asInt();
            rv->push_back(dec);
        } else if (method->member == "pop") {
            auto* pop = new IR::BFN::ParserCounterPop(declName);
            rv->push_back(pop);
        } else {
            BUG("Unhandled parser counter call: %1%", statement);
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
                        verify->dest = new IR::BFN::FieldLVal(lhs);
                        return verify;
                    } else if (method->member == "get") {
                        ::warning("checksum.get() will deprecate in future versions. Please use"
                                  " void subtract_all_and_deposit(bit<16>) instead");
                        if (!lastChecksumSubtract || !lastSubtractField) {
                            ::fatal_error("Checksum \"get\" must have preceding \"subtract\""
                                          " call in the same parser state");
                        }
                        auto endPos = getHeaderEndPos(lastChecksumSubtract, lastSubtractField);
                        auto endByte = new IR::BFN::PacketRVal(StartLen(endPos, 8));
                        auto get = new IR::BFN::ChecksumResidualDeposit(declName,
                                              new IR::BFN::FieldLVal(lhs), endByte);
                        return get;
                    }
                }
            }
        }

        if (auto rval = resolveLookahead(typeMap, rhs, currentBit)) {
            auto e = new IR::BFN::Extract(s->srcInfo, lhs, rval);
            LOG5("add extract: " << e);
            return e;
        }

        if (auto mem = lhs->to<IR::Member>()) {
            if (mem->member == "ingress_parser_err" || mem->member == "egress_parser_err")
                return nullptr;
        }

        if (rhs->is<IR::Constant>() || rhs->is<IR::BoolLiteral>()) {
            auto* rhsConst = rhs->to<IR::Constant>();
            if (!rhsConst)  // boolean
                rhsConst = new IR::Constant(rhs->to<IR::BoolLiteral>()->value ? 1 : 0);
            auto extract = new IR::BFN::Extract(s->srcInfo, s->left,
                     new IR::BFN::ConstantRVal(rhsConst->type,
                             rhsConst->value));
            LOG5("add extract: " << extract);
            return extract;
        }

        // Allow slices if we'd allow the expression being sliced.
        if (auto* slice = rhs->to<IR::Slice>()) {
            if (canEvaluateInParser(slice->e0)) {
                auto e = new IR::BFN::Extract(s->srcInfo, lhs,
                                            new IR::BFN::SavedRVal(rhs));
                LOG5("add extract: " << e);
                return e;
            }
        }

        // a = a | b
        if (auto bor = rhs->to<IR::BOr>()) {
            if (bor->left->equiv(*lhs)) {
                auto e = createBitwiseOrExtract(lhs, bor->right, s->srcInfo);
                LOG5("add extract: " << e);
                return e;
            } else if (bor->right->equiv(*lhs)) {
                auto e = createBitwiseOrExtract(lhs, bor->left, s->srcInfo);
                LOG5("add extract: " << e);
                return e;
            }
        }

        if (!canEvaluateInParser(rhs)) {
            ::fatal_error("Assignment source cannot be evaluated in the parser: %1%", rhs);
            return nullptr;
        }

        auto a = new IR::BFN::Extract(s->srcInfo, s->left,
                                    new IR::BFN::SavedRVal(rhs));
        LOG5("add extract: " << a);
        return a;
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
    ordered_map<const IR::Member*, const IR::BFN::PacketRVal*> extractedFields;
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
    auto rval = rewriteLookahead(typeMap, call, bitShift, slice);
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

    if (auto rval = resolveLookahead(typeMap, selectExpr, bitShift)) {
        auto select = new IR::BFN::Select(new IR::BFN::SavedRVal(rval), selectExpr);
        bitrange = rval->range;
        return select;
    }

    BUG_CHECK(!selectExpr->is<IR::Constant>(), "%1% constant selection expression %2% "
                                               "should have been eliminated by now. "
                                               "please make sure there's a key in the "
                                               "Keyset expressions matches %3%. Or add a "
                                               "default or _ label in the select expression",
                                               selectExpr->srcInfo, selectExpr, selectExpr);

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

        if (parserLoopsInfo.dont_unroll(name)) {
            LOG3("keeping " << name << " as a loop");
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
            LOG3("unrolling " << name << " as " << unrolledName);

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
    ResolveHeaderStackIndex resolveHeaderStackIndex(state, &ancestors);
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

    for (auto* statement : state->p4State->components) {
        // Checksum add might have added a BlockStatement
        if (auto* bs = statement->to<IR::BlockStatement>()) {
            for (auto* s : bs->components) {
                state->statements.pushBackOrAppend(s->apply(rewriteStatements));
            }
        } else {
            state->statements.pushBackOrAppend(statement->apply(rewriteStatements));
        }
    }

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
