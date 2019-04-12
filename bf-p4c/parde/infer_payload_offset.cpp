#include "infer_payload_offset.h"

#include <boost/range/adaptor/reversed.hpp>

#include "bf-p4c/parde/parde_utils.h"
#include "bf-p4c/parde/parser_info.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"

static bool is_mutable_field(const FieldDefUse& defuse, const PHV::Field* f) {
    auto all_defs = defuse.getAllDefs(f->id);

    for (auto def : all_defs) {
        auto unit = def.first;
        if (unit->is<IR::MAU::Table>())
            return true;
    }

    return false;
}

using StateSet = std::set<const IR::BFN::ParserState*>;

class FindParsingFrontier : public ParserInspector {
 public:
    struct CutSet {
        std::map<const IR::BFN::ParserState*, StateSet> transitions;
        StateSet transitions_to_pipe;

        StateSet
        get_all_srcs() const {
            StateSet cutset_srcs;

            for (auto& kv : transitions)
                cutset_srcs.insert(kv.first);

            for (auto s : transitions_to_pipe)
                cutset_srcs.insert(s);

            return cutset_srcs;
        }

        StateSet
        get_all_dsts() const {
            StateSet cutset_dsts;

            for (auto& kv : transitions) {
                for (auto s : kv.second)
                    cutset_dsts.insert(s);
            }

            return cutset_dsts;
        }

        StateSet
        get_dsts_for(const IR::BFN::ParserState* state) const {
            return transitions.at(state);
        }

        StateSet
        get_srcs_for(const IR::BFN::ParserState* state) const {
            StateSet rv;

            for (auto& kv : transitions) {
                if (kv.second.count(state))
                    rv.insert(kv.first);
            }

            return rv;
        }

        void print() const {
            std::clog << "cutset:" << std::endl;

            for (auto& kv : transitions) {
                for (auto s : kv.second)
                    std::clog << "  " << kv.first->name << " -> " << s->name << std::endl;
            }

            for (auto s : transitions_to_pipe)
                std::clog << "  " << s->name << " -> (pipe)" << std::endl;
        }
    };

    struct Frontier {
        StateSet states;
        CutSet cutset;

        void print() {
            std::clog << "frontier:" << std::endl;

            for (auto s : states)
                std::clog << "  " << s->name << std::endl;

            cutset.print();
        }
    };

 private:
    const PhvInfo& phv;
    const FieldDefUse& defuse;
    const CollectParserInfo& parserInfo;

    std::map<const IR::BFN::Parser*, StateSet> mutable_field_states;

    bool preorder(const IR::BFN::Parser* parser) override {
        mutable_field_states[parser] = {};
        return true;
    }

    bool preorder(const IR::BFN::Extract* extract) override {
        auto parser = findContext<IR::BFN::Parser>();
        auto state = findContext<IR::BFN::ParserState>();
        auto f = phv.field(extract->dest->field);

        if (is_mutable_field(defuse, f))
            mutable_field_states[parser].insert(state);

        return false;
    }

    struct BiPartition {
        StateSet mutable_field_descendants;
        StateSet non_mutable_field_descendants;

        void print() {
            std::clog << "bipartition:" << std::endl;

            std::clog << "non_mutable_field_descendants:" << std::endl;
            for (auto s : non_mutable_field_descendants)
                std::clog << "  " << s->name << std::endl;

            std::clog << "mutable_field_descendants:" << std::endl;
            for (auto s : mutable_field_descendants)
                std::clog << "  " << s->name << std::endl;
        }
    };

    BiPartition
    compute_bipartition(const IR::BFN::ParserGraph& graph,
                        const StateSet& mutable_field_states) {
        BiPartition bipartition;

        for (auto s : graph.states()) {
            if (mutable_field_states.count(s))
                continue;

            bool is_mutable_field_descendant = true;
            for (auto m : mutable_field_states) {
                if (graph.is_ancestor(s, m)) {
                    is_mutable_field_descendant = false;
                    break;
                }
            }
            if (is_mutable_field_descendant)
                bipartition.mutable_field_descendants.insert(s);
        }

        for (auto s : graph.states()) {
            if (!bipartition.mutable_field_descendants.count(s))
                bipartition.non_mutable_field_descendants.insert(s);
        }

        if (LOGGING(5))
            bipartition.print();

        return bipartition;
    }

    CutSet
    compute_bipartition_cutset(const IR::BFN::ParserGraph& graph,
                               const BiPartition& bipartition) {
        CutSet cutset;

        for (auto s : bipartition.mutable_field_descendants) {
            if (graph.predecessors().count(s)) {
                for (auto p : graph.predecessors().at(s)) {
                    if (bipartition.non_mutable_field_descendants.count(p))
                        cutset.transitions[p].insert(s);
                }
            }
        }

        for (auto s : bipartition.non_mutable_field_descendants) {
            if (graph.to_pipe().count(s))
                cutset.transitions_to_pipe.insert(s);
        }

        if (LOGGING(5))
            cutset.print();

        return cutset;
    }

    // See if we can absorb the transitions in cutset to their originating states.
    // s is a frontier state, if cutset originates from s == all outgoing transitions of s.
    // Otherwise, need to insert frontier state on all cutset originate from s.
    Frontier
    compute_frontier_by_push_up(const IR::BFN::ParserGraph& graph, const CutSet& cutset) {
        Frontier frontier;

        auto cutset_srcs = cutset.get_all_srcs();

        for (auto s : cutset_srcs) {
            bool is_frontier = true;

            if (graph.successors().count(s)) {
                if (cutset.get_dsts_for(s) != graph.successors().at(s))
                    is_frontier = false;
            }

            if (is_frontier) {
                frontier.states.insert(s);
            } else {
                if (cutset.transitions.count(s))
                    frontier.cutset.transitions[s] = cutset.transitions.at(s);

                if (cutset.transitions_to_pipe.count(s))
                    frontier.cutset.transitions_to_pipe.insert(s);
            }
        }

        return frontier;
    }

    // See if we can absorb the transitions in cutset to their destination states.
    // s is a frontier state, if cutset ends at s == all incoming transitions of s.
    // Otherwise, need to insert frontier state on all cutset ends at s.
    Frontier
    compute_frontier_by_push_down(const IR::BFN::ParserGraph& graph, const CutSet& cutset) {
        Frontier frontier;

        auto cutset_dsts = cutset.get_all_dsts();

        for (auto s : cutset_dsts) {
            bool is_frontier = false;

            if (cutset.get_srcs_for(s) == graph.predecessors().at(s))
                is_frontier = true;

            if (is_frontier) {
                frontier.states.insert(s);
            } else {
                if (cutset.transitions.count(s))
                    frontier.cutset.transitions[s] = cutset.transitions.at(s);

                if (cutset.transitions_to_pipe.count(s))
                    frontier.cutset.transitions_to_pipe.insert(s);
            }
        }

        return frontier;
    }

    // Given the the frontier solutions computed by "push-up" and "push-down" (see above).
    // We try to reconcile the two solutions such that if a transition is aborbed into
    // its originating/destination state, we can eliminate the transition from the final
    // solution.
    Frontier
    reconcile_push_up_and_push_down(const Frontier& push_up, const Frontier& push_down) {
        Frontier frontier;

        for (auto s : push_up.states)
            frontier.states.insert(s);

        for (auto s : push_down.states)
            frontier.states.insert(s);

        for (auto& kv : push_up.cutset.transitions) {
            for (auto s : kv.second) {
                if (!frontier.states.count(s))
                    frontier.cutset.transitions[kv.first].insert(s);
            }
        }

        for (auto s : push_up.cutset.transitions_to_pipe) {
            if (!frontier.states.count(s)) {
                frontier.cutset.transitions_to_pipe.insert(s);
            }
        }

        for (auto& kv : push_down.cutset.transitions) {
            if (!frontier.cutset.transitions.count(kv.first)) {
                for (auto s : kv.second)
                    frontier.cutset.transitions[kv.first].insert(s);
            }
        }

        return frontier;
    }

    Frontier
    compute_frontier(const IR::BFN::ParserGraph& graph, const CutSet& cutset) {
        auto push_up = compute_frontier_by_push_up(graph, cutset);
        auto push_down = compute_frontier_by_push_down(graph, cutset);

        auto frontier = reconcile_push_up_and_push_down(push_up, push_down);
        return frontier;
    }

    Frontier
    find_frontier_by_bipartition(const IR::BFN::Parser* parser,
                       const StateSet& mutable_field_states) {
        if (LOGGING(4)) {
            std::clog << parser->gress << " mutable_field_states:" << std::endl;
            for (auto s : mutable_field_states)
                std::clog << "  " << s->name << std::endl;
        }

        auto& graph = parserInfo.graph(parser);

        auto bipartition = compute_bipartition(graph, mutable_field_states);

        auto cutset = compute_bipartition_cutset(graph, bipartition);

        auto frontier = compute_frontier(graph, cutset);

        return frontier;
    }

    void find_frontier(const IR::BFN::Parser* parser,
                       const StateSet& mutable_field_states) {
        if (mutable_field_states.empty()) {
            LOG4(parser->gress << " mutable_field_states: <none>");
            Frontier frontier;
            frontier.states.insert(parser->start);  // trivial case, start state is frontier
            parser_to_frontier[parser->gress] = frontier;
        } else {
            parser_to_frontier[parser->gress] =
                find_frontier_by_bipartition(parser, mutable_field_states);
        }

        if (LOGGING(4)) {
            std::clog << parser->gress << " ";
            parser_to_frontier[parser->gress].print();
        }

        create_color_groups_for_visualization(parser);
    }

    void create_color_groups_for_visualization(const IR::BFN::Parser* parser) {
        auto& graph = parserInfo.graph(parser);
        auto& front = parser_to_frontier[parser->gress];

        std::set<void*> cg;
        for (auto s : front.states)
            cg.insert((void*)s);  // NOLINT

        for (auto& st : front.cutset.transitions) {
            for (auto d : st.second) {
                auto t = graph.transition(st.first, d);
                cg.insert((void*)t);  // NOLINT
            }
        }

        for (auto s : front.cutset.transitions_to_pipe) {
            auto t = graph.to_pipe(s);
            cg.insert((void*)t);  // NOLINT
        }

        color_groups.push_back(cg);
    }

    void end_apply() override {
        for (auto& kv : mutable_field_states)
            find_frontier(kv.first, kv.second);
    }

 public:
    std::map<gress_t, Frontier> parser_to_frontier;
    std::vector<std::set<void*>> color_groups;  // for DumpParser

    FindParsingFrontier(const PhvInfo& phv,
                       const FieldDefUse& defuse,
                       const CollectParserInfo& parserInfo) :
        phv(phv), defuse(defuse), parserInfo(parserInfo) { }
};

class InsertFrontierStates : public ParserTransform {
    bool need_to_insert_dummy(const IR::BFN::ParserState* state,
                              IR::BFN::Transition* transition,
                              const FindParsingFrontier::Frontier& front) {
        if (transition->next) {
            for (auto& kv : front.cutset.transitions) {
                if (kv.first->name == state->name) {
                    for (auto s : kv.second) {
                        if (s->name == transition->next->name) {
                            return true;
                        }
                    }
                }
            }
        } else {
            for (auto s : front.cutset.transitions_to_pipe) {
                if (s->name == state->name) {
                    return true;
                }
            }
        }

        return false;
    }

    const IR::Node* preorder(IR::BFN::ParserState* state) override {
        auto parser = findContext<IR::BFN::Parser>();
        auto& front = frontier.parser_to_frontier.at(parser->gress);

        for (auto s : front.states) {
            if (s->name == state->name) {
                parser_to_frontier_state_names[parser->gress].insert(state->name);
                break;
            }
        }

        return state;
    }

    const IR::Node* preorder(IR::BFN::Transition* transition) override {
        auto parser = findContext<IR::BFN::Parser>();
        auto& front = frontier.parser_to_frontier.at(parser->gress);

        auto state = findContext<IR::BFN::ParserState>();
        bool need_to_insert = need_to_insert_dummy(state, transition, front);

        if (!need_to_insert)
            return transition;

        static int id = 0;

        auto to_state = new IR::BFN::Transition(match_t(), 0, transition->next);
        cstring stopper_name = "$hdr_len_inc_stop_" + cstring::to_cstring(id++);
        auto stopper = new IR::BFN::ParserState(stopper_name, parser->gress, {}, {}, {to_state});

        LOG3("insert parser state " << stopper->name << " on "
             << state->name << " -> "
             << (transition->next ? transition->next->name : cstring("(pipe)")));

        transition->next = stopper;

        parser_to_frontier_state_names[parser->gress].insert(stopper->name);

        return transition;
    }

    const FindParsingFrontier& frontier;

 public:
    std::map<gress_t, std::set<cstring>> parser_to_frontier_state_names;

    explicit InsertFrontierStates(const FindParsingFrontier& frontier) : frontier(frontier) {}
};

class RewriteParde : public PardeTransform {
    void sort_primitives_by_packet_rval(IR::BFN::ParserState* state) {
        std::sort(state->statements.begin(), state->statements.end(),
            [&] (const IR::BFN::ParserPrimitive* a,
                 const IR::BFN::ParserPrimitive* b) {
                auto ea = a->to<IR::BFN::Extract>();
                auto eb = b->to<IR::BFN::Extract>();

                if (ea && eb) {
                    auto va = ea->source->to<IR::BFN::PacketRVal>();
                    auto vb = eb->source->to<IR::BFN::PacketRVal>();

                    return (va && vb) ? (va->range() < vb->range()) : !!va;
                }

                return !!ea;
            });

        if (LOGGING(5)) {
            std::clog << "sorted primitives in " << state->name << std::endl;
            for (auto p : state->statements)
                std::clog << p << std::endl;
        }
    }

    void insert_hdr_len_inc_stop(IR::BFN::ParserState* state) {
        IR::Vector<IR::BFN::ParserPrimitive> rv;

        bool inserted = false;

        // assumes primitives have been sorted by packet rval
        for (auto stmt : boost::adaptors::reverse(state->statements)) {
            if (auto extract = stmt->to<IR::BFN::Extract>()) {
                auto f = phv.field(extract->dest->field);

                if (extract->source->is<IR::BFN::PacketRVal>()) {
                    if (!inserted && is_mutable_field(defuse, f)) {
                        auto clone = extract->clone();
                        clone->hdr_len_inc_stop = true;

                        rv.insert(rv.begin(), clone);
                        inserted = true;

                        LOG4("insert hdr_len_inc_stop in " << extract << " in " << state->name);
                        continue;
                    }
                }
            }

            rv.insert(rv.begin(), stmt);
        }

        // state has no write-able fields, insert stopper at the beginning
        if (!inserted) {
            auto stopper = new IR::BFN::Extract(
                new IR::TempVar(IR::Type::Bits::get(1), false,
                                "$dummy_" + ::toString(state->gress)),
                    new IR::BFN::PacketRVal(nw_bitrange(StartLen(0, 1))));

            stopper->hdr_len_inc_stop = true;
            rv.insert(rv.begin(), stopper);

            LOG4("insert hdr_len_inc_stop (null-extract) in " << state->name);
        }

        state->statements = rv;
    }

    void elim_extracts_of_unused_field(IR::BFN::ParserState* state) {
        IR::Vector<IR::BFN::ParserPrimitive> rv;

        bool seen_hdr_len_inc_stop = false;

        // assumes primitives have been sorted by packet rval
        for (auto stmt : boost::adaptors::reverse(state->statements)) {
            auto extract = stmt->to<IR::BFN::Extract>();

            if (extract && extract->hdr_len_inc_stop)
                seen_hdr_len_inc_stop = true;

            if (!extract || seen_hdr_len_inc_stop) {
                rv.push_back(stmt);
                continue;
            }

            auto field = phv.field(extract->dest->field);

            if (!field->deparsed() ||
                uses.is_used_mau(field)) {
                rv.insert(rv.begin(), stmt);
            } else {
                LOG4("elim " << stmt << " in " << state->name);
            }

            fields_below_frontier.insert(field);
        }

        state->statements = rv;
    }

    bool is_above_frontier(const IR::BFN::Parser* p, const IR::BFN::ParserState* s) {
        auto& front = parser_to_frontier_states.at(p->gress);
        auto& graph = parserInfo.graph(p);

        for (auto f : front) {
            if (!graph.is_ancestor(s, f))
                return false;
        }

        return true;
    }

    bool is_below_frontier(const IR::BFN::Parser* p, const IR::BFN::ParserState* s) {
        auto& front = parser_to_frontier_states.at(p->gress);
        auto& graph = parserInfo.graph(p);

        for (auto f : front) {
            if (!graph.is_descendant(s, f))
                return false;
        }

        return true;
    }

    IR::Node* preorder(IR::BFN::Parser* parser) override {
        orig_parser = getOriginal<IR::BFN::Parser>();
        return parser;
    }

    IR::Node* preorder(IR::BFN::ParserState* state) override {
        auto orig_state = getOriginal<IR::BFN::ParserState>();

        IR::BFN::ParserState* rv = nullptr;

        if (is_above_frontier(orig_parser, orig_state)) {
            rv = state;
        } else if (is_below_frontier(orig_parser, orig_state)) {
            rv = state->clone();
            sort_primitives_by_packet_rval(rv);
            elim_extracts_of_unused_field(rv);
        } else {
            auto& front = parser_to_frontier_states.at(orig_parser->gress);
            BUG_CHECK(front.count(orig_state),
                      "Incorrect parsing frontier computation at %1%", state->name);

            rv = state->clone();
            sort_primitives_by_packet_rval(rv);
            insert_hdr_len_inc_stop(rv);
            elim_extracts_of_unused_field(rv);
        }

        return rv;
    }

    IR::Node* preorder(IR::BFN::EmitField* emit) override {
        prune();

        IR::BFN::Emit* rv = nullptr;

        auto f = phv.field(emit->source->field);
        if (!fields_below_frontier.count(f))
            rv = emit;

        if (!rv)
            LOG4("elim " << emit << " (below parsing frontier)");

        return rv;
    }

    struct MapNameToState : Inspector {
        std::map<cstring, const IR::BFN::ParserState*>& name_to_state;

        explicit MapNameToState(std::map<cstring, const IR::BFN::ParserState*>& n2s) :
            name_to_state(n2s) {}

        bool preorder(const IR::BFN::ParserState* state) override {
            name_to_state[state->name] = state;
            return true;
        }
    };

    profile_t init_apply(const IR::Node* root) override {
        root->apply(MapNameToState(name_to_state));

        for (auto& kv : frontier.parser_to_frontier_state_names) {
            for (auto s : kv.second)
                parser_to_frontier_states[kv.first].insert(name_to_state.at(s));
        }

        if (LOGGING(3)) {
            std::vector<std::set<void*>> color_groups;

            for (auto& kv : parser_to_frontier_states) {
                std::set<void*> cg;

                std::clog << kv.first << " frontier states:" << std::endl;
                for (auto s : kv.second) {
                    std::clog << "  " << s->name << std::endl;
                    cg.insert((void*)s);  // NOLINT
                }
                color_groups.push_back(cg);
            }

            root->apply(DumpParser("after_insert_frontier_states", color_groups));
        }

        return PardeTransform::init_apply(root);
    }

    std::map<gress_t, StateSet> parser_to_frontier_states;
    std::map<cstring, const IR::BFN::ParserState*> name_to_state;


    const IR::BFN::Parser* orig_parser = nullptr;

    std::set<const PHV::Field*> fields_below_frontier;

    const PhvInfo& phv;
    const PhvUse& uses;
    const FieldDefUse& defuse;
    const CollectParserInfo& parserInfo;
    const InsertFrontierStates& frontier;

 public:
    RewriteParde(const PhvInfo& phv, const PhvUse& uses,
                 const FieldDefUse& defuse,
                 const CollectParserInfo& parserInfo,
                 const InsertFrontierStates& frontier) :
        phv(phv), uses(uses), defuse(defuse),
        parserInfo(parserInfo), frontier(frontier) { }
};

InferPayloadOffset::InferPayloadOffset(const PhvInfo& phv,
                                       const FieldDefUse& defuse)
        : phv(phv), defuse(defuse) {
    auto uses = new PhvUse(phv);
    auto parserInfo = new CollectParserInfo;
    auto findFrontier = new FindParsingFrontier(phv, defuse, *parserInfo);
    auto insertFrontier = new InsertFrontierStates(*findFrontier);

    addPasses({
        LOGGING(3) ? new DumpParser("before_infer_payload_offset") : nullptr,
        uses,
        parserInfo,
        findFrontier,
        LOGGING(4) ? new DumpParser("after_find_parsing_frontier",
                                    findFrontier->color_groups) : nullptr,
        insertFrontier,
        parserInfo,
        new RewriteParde(phv, *uses, defuse, *parserInfo, *insertFrontier)
    });
}
