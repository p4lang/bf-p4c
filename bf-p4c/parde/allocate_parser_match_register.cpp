#include <boost/range/adaptors.hpp>

#include "bf-p4c/common/utils.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/parde/allocate_parser_match_register.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/parde_utils.h"
#include "bf-p4c/parde/parser_info.h"
#include "device.h"

// Insert a stall state on transition whose next state requires
// branch word that is out of the input buffer of the current state.
struct ResolveOutOfBufferSelects : public ParserTransform {
    std::map<cstring, IR::BFN::ParserState*> src_to_stall_state;

    CollectParserInfo parser_info;

    profile_t init_apply(const IR::Node* root) override {
        root->apply(parser_info);
        return ParserTransform::init_apply(root);
    }

    const IR::BFN::Parser* parser = nullptr;

    IR::BFN::Parser* preorder(IR::BFN::Parser* p) override {
        parser = getOriginal<IR::BFN::Parser>();
        return p;
    }

    void insert_stall_state_for_oob_select(IR::BFN::Transition* t) {
        auto orig = getOriginal<IR::BFN::Transition>();
        auto src = parser_info.graph(parser).get_src(orig);

        IR::BFN::ParserState* stall = nullptr;

        if (src_to_stall_state.count(src->name)) {
            stall = src_to_stall_state.at(src->name);
        } else {
            cstring name = src->name + ".$stall";
            stall = new IR::BFN::ParserState(src->p4State, name, src->gress);
            src_to_stall_state[src->name] = stall;
        }

        LOG2("created stall state for out of buffer select on "
              << src->name << " -> " << t->next->name);

        auto to_dst = new IR::BFN::Transition(match_t(), 0, t->next);
        stall->transitions.push_back(to_dst);
        t->next = stall;
    }

    bool has_oob_select(const IR::BFN::Transition* t) {
        if (!t->next)
            return false;

        if (t->next->selects.empty())
            return false;

        GetMaxBufferPos max_select;
        t->next->selects.apply(max_select);

        return (*t->shift + (max_select.rv + 7) / 8) > Device::pardeSpec().byteInputBufferSize();
    }

    IR::BFN::Transition* postorder(IR::BFN::Transition* t) override {
        if (has_oob_select(t))
            insert_stall_state_for_oob_select(t);

        return t;
    }
};

struct Def {
    const IR::BFN::ParserState* state = nullptr;
    const IR::BFN::InputBufferRVal* rval = nullptr;

    Def(const IR::BFN::ParserState* s,
        const IR::BFN::InputBufferRVal* r) : state(s), rval(r) { }

    bool equiv(const Def* other) const {
        if (this == other) return true;
        return (state->name == other->state->name) && (rval->equiv(*other->rval));
    }

    std::string print() const {
        std::stringstream ss;
        ss << " ( " << state->name << " : " << rval->range << " )";
        return ss.str();
    }
};

struct Use {
    const IR::BFN::ParserState* state = nullptr;
    const IR::BFN::Select* select = nullptr;

    Use(const IR::BFN::ParserState* s,
        const IR::BFN::Select* select) : state(s), select(select) { }

    bool equiv(const Use* other) const {
        if (this == other) return true;
        return (state->name == other->state->name) && (select->equiv(*other->select));
    }

    std::string print() const {
        std::stringstream ss;
        ss << " [ " << state->name << " : " << select->p4Source << " ]";
        return ss.str();
    }
};

struct UseDef {
    ordered_map<const Use*, std::vector<const Def*>> use_to_defs;

    void add_def(const Use* use, const Def* def) {
        for (auto d : use_to_defs[use])
            if (d->equiv(def)) return;
        use_to_defs[use].push_back(def);
    }

    const Use*
    get_use(const IR::BFN::ParserState* state, const IR::BFN::Select* select) const {
        auto temp = new Use(state, select);
        for (auto& kv : use_to_defs)
            if (kv.first->equiv(temp))
                return kv.first;
        return temp;
    }

    const Def*
    get_def(const Use* use, const IR::BFN::ParserState* def_state) const {
        for (auto def : use_to_defs.at(use)) {
            if (def_state == def->state)
                return def;
        }
        return nullptr;
    }

    std::string print(const Use* use) const {
        std::stringstream ss;
        ss << "use: " << use->print() << " -- defs: ";
        for (auto def : use_to_defs.at(use))
            ss << def->print() << " ";
        return ss.str();
    }

    std::string print() const {
        std::stringstream ss;
        ss << "parser def use: " << std::endl;
        for (auto& kv : use_to_defs)
            ss << print(kv.first) << std::endl;
        return ss.str();
    }
};

typedef std::map<const IR::BFN::Parser*, UseDef> ParserUseDef;

/// Collect Use-Def for all select fields
///   Def: In which states are the select fields extracted?
///   Use: In which state are the select fields matched on?
struct CollectUseDef : PassManager {
    struct CollectDefs : Inspector {
        CollectDefs() { visitDagOnce = false; }

        std::map<const IR::BFN::ParserState*,
                 std::set<const IR::BFN::InputBufferRVal*>> state_to_rvals;

        std::map<const IR::BFN::InputBufferRVal*,
                 const IR::Expression*> rval_to_lval;

        bool preorder(const IR::BFN::ParserState *) override {
            visitOnce();  // only visit once, regardless of how many predecessors
            return true; }

        // XXX(zma) what if extract gets dead code eliminated?
        // XXX(zma) this won't work if the extract is out of order
        bool preorder(const IR::BFN::Extract* extract) override {
            auto state = findContext<IR::BFN::ParserState>();

            if (auto rval = extract->source->to<IR::BFN::InputBufferRVal>()) {
                state_to_rvals[state].insert(rval);
                rval_to_lval[rval] = extract->dest->field;

                LOG4(state->name << " " << rval << " -> " << extract->dest->field);
            }

            return false;
        }
    };

    struct MapToUse : Inspector {
        const PhvInfo& phv;
        const CollectParserInfo& parser_info;
        const CollectDefs& defs;

        ParserUseDef& parser_use_def;

        MapToUse(const PhvInfo& phv,
                    const CollectParserInfo& pi,
                    const CollectDefs& d,
                    ParserUseDef& parser_use_def) :
            phv(phv), parser_info(pi), defs(d), parser_use_def(parser_use_def) {
                visitDagOnce = false;
            }

        // defs have absoluate offsets from current state
        ordered_set<Def*>
        find_defs(const IR::BFN::InputBufferRVal* rval,
                 const IR::BFN::ParserGraph& graph,
                 const IR::BFN::ParserState* state) {
            ordered_set<Def*> rv;

            if (rval->range.lo < 0) {  // def is in an earlier state
                if (graph.predecessors().count(state)) {
                    for (auto pred : graph.predecessors().at(state)) {
                        for (auto t : graph.transitions(pred, state)) {
                            auto shift = t->shift;

                            BUG_CHECK(shift, "transition has no shift?");

                            auto shifted_rval = rval->apply(ShiftPacketRVal(-(*shift * 8), true));
                            auto defs = find_defs(shifted_rval->to<IR::BFN::InputBufferRVal>(),
                                                  graph, pred);

                            for (auto def : defs)
                                rv.insert(def);
                        }
                    }
                }

                return rv;
            } else if (rval->range.lo >= 0) {  // def is in this state
                auto def = new Def(state, rval);
                rv.insert(def);
            }

            return rv;
        }

        // multiple defs in earlier states with no absolute offsets from current state
        ordered_set<Def*>
        find_defs(const IR::BFN::SavedRVal* saved,
                  const IR::BFN::ParserGraph& graph,
                  const IR::BFN::ParserState* state) {
            ordered_set<Def*> rv;

            for (auto& kv : defs.state_to_rvals) {
                auto def_state = kv.first;

                if (graph.is_ancestor(def_state, state)) {
                    for (auto rval : kv.second) {
                        auto lval = defs.rval_to_lval.at(rval);

                        le_bitrange bits;
                        auto f = phv.field(lval, &bits);
                        auto s = phv.field(saved->source);

                        if (f == s) {
                            if (bits.size() == f->size) {
                                auto def = new Def(def_state, rval);
                                rv.insert(def);
                            } else {
                                auto full_rval = rval->clone();
                                full_rval->range.lo = rval->range.lo - bits.lo;
                                full_rval->range.hi = rval->range.hi + f->size - bits.hi - 1;
                                auto def = new Def(def_state, full_rval);
                                rv.insert(def);
                            }
                        }
                    }
                }
            }

            return rv;
        }
        bool preorder(const IR::BFN::Parser *) override { revisit_visited(); return true; }
        bool preorder(const IR::BFN::ParserState *) override { visitOnce(); return true; }

        bool preorder(const IR::BFN::Select* select) override {
            auto parser = findContext<IR::BFN::Parser>();
            auto state = findContext<IR::BFN::ParserState>();

            auto& graph = parser_info.graph(parser);

            auto use = parser_use_def[parser].get_use(state, select);

            if (auto buf = select->source->to<IR::BFN::InputBufferRVal>()) {
                auto defs = find_defs(buf, graph, state);
                for (auto def : defs)
                    parser_use_def[parser].add_def(use, def);
            } else if (auto save = select->source->to<IR::BFN::SavedRVal>()) {
                auto defs = find_defs(save, graph, state);
                for (auto def : defs)
                    parser_use_def[parser].add_def(use, def);
            } else {
                BUG("Unknown select expression %1%", select->source);
            }

            BUG_CHECK(parser_use_def[parser].use_to_defs.count(use),
                      "No reaching def found for select %1%", use->print());

            LOG4(parser_use_def[parser].print(use));

            return false;
        }
    };

    void end_apply() override {
        for (auto& kv : parser_use_def)
            LOG3(parser_use_def[kv.first].print());
    }

    explicit CollectUseDef(const PhvInfo& phv, const CollectParserInfo& parser_info) {
        auto collect_defs = new CollectDefs;
        addPasses({
            collect_defs,
            new MapToUse(phv, parser_info, *collect_defs, parser_use_def),
        });
    }

    ParserUseDef parser_use_def;
};

static
bool equiv(const std::vector<std::pair<MatchRegister, nw_bitrange>>& a,
           const std::vector<std::pair<MatchRegister, nw_bitrange>>& b) {
    if (a.size() != b.size()) return false;
    for (unsigned i = 0; i < a.size(); i++)
        if (a[i] != b[i]) return false;
    return true;
}

/// This is the match register allocation. We implements a greedy
/// graph coloring algorthim where two select's interfere if their
/// live range overlap.
class MatcherAllocator : public Visitor {
    const CollectParserInfo& parser_info;
    const ParserUseDef& parser_use_def;

 public:
    MatcherAllocator(const CollectParserInfo& pi,
                         const ParserUseDef& parser_use_def) :
        parser_info(pi), parser_use_def(parser_use_def) { }

 public:
    // The saves need to be executed on this transition.
    std::map<const IR::BFN::Transition*,
             std::vector<const IR::BFN::SaveToRegister*>> transition_saves;

    // The register slices that this select should match against.
    std::map<const IR::BFN::Select*,
             std::vector<std::pair<MatchRegister, nw_bitrange>>> select_reg_slices;

 private:
    /// Represents a group of select fields that can be coalesced into
    /// single allocation unit (see comment below for coalescing).
    struct UseGroup {
        const UseDef& use_def;

        std::vector<const Use*> members;

        std::map<const IR::BFN::Transition*,
                 const IR::BFN::ParserState*> def_transition_to_state;

        unsigned bits_in_group = 0, bytes_in_group = 0;

        explicit UseGroup(const UseDef& s) : use_def(s) { }

        const IR::BFN::ParserState*
        get_use_state() const {
            auto leader = members.front();
            return leader->state;
        }

        std::vector<const IR::BFN::ParserState*>
        get_def_states() const {
            auto leader = members.front();

            std::vector<const IR::BFN::ParserState*> rv;

            for (auto def : use_def.use_to_defs.at(leader))
                rv.push_back(def->state);

            return rv;
        }

        const IR::BFN::ParserState*
        get_def_state(const IR::BFN::Transition* def_transition) const {
            return def_transition_to_state.at(def_transition);
        }

        std::vector<const IR::BFN::Transition*>
        get_def_transitions() const {
            std::vector<const IR::BFN::Transition*> rv;

            for (auto& kv : def_transition_to_state)
                rv.push_back(kv.first);

            return rv;
        }

        /// For each select, computes a set of transitions where
        /// the branch word(s) need to be save into the match registers.
        void compute_def_transitions(const IR::BFN::ParserGraph& graph) {
            auto use_state = get_use_state();

            auto def_states = get_def_states();

            // case 1: def state == use state
            if (def_states.size() == 1 && def_states[0] == use_state) {
                BUG_CHECK(graph.predecessors().count(use_state),
                          "select state has no predecessors");

                for (auto pred : graph.predecessors().at(use_state)) {
                    for (auto t : graph.transitions(pred, use_state))
                        def_transition_to_state[t] = use_state;
                }
            } else {  // case 2: def states are ancestor states
                for (auto def_state : def_states) {
                    for (auto succ : graph.successors().at(def_state)) {
                        if (succ == use_state || graph.is_ancestor(succ, use_state)) {
                            for (auto t : graph.transitions(def_state, succ))
                                def_transition_to_state[t] = def_state;
                        }
                    }
                }
            }

            auto def_transitions = get_def_transitions();

            if (LOGGING(5)) {
                std::clog << "group: " << print() << " has def on:" << std::endl;
                for (auto t : def_transitions) {
                    std::clog << graph.get_src(t)->name << " -> "
                              << t->next->name << std::endl;
                }
            }

            BUG_CHECK(!def_transitions.empty(), "no def transitions for select group?");
        }

        nw_bitrange get_range(const IR::BFN::ParserState* def_state) const {
            auto head = members.front();
            auto tail = members.back();

            int lo = use_def.get_def(head, def_state)->rval->range.lo;
            int hi = use_def.get_def(tail, def_state)->rval->range.hi;

            return nw_bitrange(lo, hi);
        }

        /// preconditions:
        ///   - assumes caller has checked candidate has same use/def states as group
        ///   - assumes defs are sorted already
        bool join(const Use* cand) {
            if (members.empty()) {
                members.push_back(cand);

                auto& defs = use_def.use_to_defs.at(cand);

                bits_in_group = defs.at(0)->rval->range.size();
                bytes_in_group = (bits_in_group + 7) / 8;

                return true;
            }

            // check if candidate's rvals are in same byte as all defs in group

            auto cand_defs = use_def.use_to_defs.at(cand);
            auto last_defs = use_def.use_to_defs.at(members.back());

            if (cand_defs.size() != last_defs.size()) return false;

            for (unsigned i = 0; i < cand_defs.size(); i++) {
                auto cd = cand_defs.at(i);
                auto ld = last_defs.at(i);

                if (ld->rval->range.hi + 1 == cd->rval->range.lo)
                    continue;

                auto lo = cd->rval->range.lo / 8;
                auto hi = ld->rval->range.hi / 8;

                if (lo != hi)
                    return false;
            }

            members.push_back(cand);

            bits_in_group += cand_defs.at(0)->rval->range.size();

            auto head_defs = use_def.use_to_defs.at(members.front());

            auto lo = head_defs.at(0)->rval->range.lo;
            auto hi = cand_defs.at(0)->rval->range.hi;

            bytes_in_group = (hi - lo) / 8 + 1;

            return true;
        }

        bool have_same_defs(const Use* a, const Use* b) const {
            auto a_defs = use_def.use_to_defs.at(a);
            auto b_defs = use_def.use_to_defs.at(b);

            if (a_defs.size() != b_defs.size()) return false;

            for (unsigned i = 0; i < a_defs.size(); i++) {
                if (!a_defs.at(i)->equiv(b_defs.at(i)))
                    return false;
            }

            return true;
        }

        bool have_same_defs(const UseGroup* other) const {
            if (members.size() != other->members.size()) return false;

            for (unsigned i = 0; i < members.size(); i++) {
                if (!have_same_defs(members.at(i), other->members.at(i)))
                    return false;
            }

            return true;
        }

        /// Given the registers allocated to a group, compute the
        /// the fields' layout within each register (slices)
        std::vector<std::pair<MatchRegister, nw_bitrange>>
        calc_reg_slices_for_use(const Use* use,
                                const std::vector<MatchRegister>& group_regs) const {
            std::vector<std::pair<MatchRegister, nw_bitrange>> reg_slices;

            auto def_states = get_def_states();
            auto state = def_states.at(0);  // pick first state as representative

            nw_bitrange group_range = get_range(state);
            nw_bitrange select_range = use_def.get_def(use, state)->rval->range;

            int group_start_bit_in_regs = group_range.lo % 8;
            int select_start_bit_in_regs = group_start_bit_in_regs +
                                           (select_range.lo - group_range.lo);

            nw_bitrange select_range_in_reg(StartLen(select_start_bit_in_regs,
                                                     select_range.size()));

            int curr_reg_start = 0;
            for (auto& reg : group_regs) {
                int reg_size_in_bit = reg.size * 8;

                nw_bitrange curr_reg_range(StartLen(curr_reg_start, reg_size_in_bit));
                auto intersect = toClosedRange(select_range_in_reg.intersectWith(curr_reg_range));

                if (intersect) {
                    nw_bitrange range_in_reg = (*intersect).shiftedByBits(-curr_reg_start);
                    auto slice = std::make_pair(reg, range_in_reg);
                    reg_slices.push_back(slice);
                }

                curr_reg_start += reg_size_in_bit;
            }

            return reg_slices;
        }

        std::string print() const {
            std::stringstream ss;
            ss << "{ ";
            for (auto u : members) {
                ss << u->print() << " ";
            }
            ss << "}";
            return ss.str();
        }
    };

 private:
    const IR::Node *apply_visitor(const IR::Node *root, const char *) override {
        for (auto& kv : parser_use_def)
            allocate(kv.first, kv.second);

        return root;
    }

    bool have_same_use_def_states(const UseDef& parser_use_def,
                                  const Use* a, const Use* b) {
        if (a->state != b->state)
            return false;

        auto a_defs = parser_use_def.use_to_defs.at(a);
        auto b_defs = parser_use_def.use_to_defs.at(b);

        if (a_defs.size() != b_defs.size())
            return false;

        for (auto a_def : a_defs) {
            bool found = false;

            for (auto b_def : b_defs) {
                if (a_def->state->name == b_def->state->name) {
                    found = true;
                    break;
                }
            }

            if (!found) return false;
        }

        return true;
    }

    /// sort uses by their position in the input buffer
    void sort_use_group(std::vector<const Use*>& group,
                           const UseDef& use_def) {
        std::stable_sort(group.begin(), group.end(),
            [&use_def] (const Use* a, const Use* b) {
                int a_min, b_min;
                a_min = b_min = Device::pardeSpec().byteInputBufferSize() * 8;

                for (auto def : use_def.use_to_defs.at(a))
                    a_min = std::min(a_min, def->rval->range.lo);

                for (auto def : use_def.use_to_defs.at(b))
                    b_min = std::min(b_min, def->rval->range.lo);

                return a_min < b_min;
            });
    }

    std::vector<UseGroup*>
    coalesce_group(const std::vector<const Use*>& group,
                   const IR::BFN::Parser* parser,
                   const UseDef& use_def) {
        std::vector<UseGroup*> coalesced;

        for (auto select : group) {
            bool joined = false;

            for (auto coal : coalesced) {
                if (coal->join(select)) {
                    joined = true;
                    break;
                }
            }

            if (!joined) {
                auto coal = new UseGroup(use_def);
                coal->join(select);
                coalesced.push_back(coal);
            }
        }

        auto& graph = parser_info.graph(parser);

        for (auto coal : coalesced)
            coal->compute_def_transitions(graph);

        return coalesced;
    }

    // Before the register allocation, perform coalescing of select fields
    // so that each coalesced group will be considered as a single allocation unit.
    //
    // We can coalesce selects if they
    //   1. have the same use state
    //   2. have the same set of def states
    //   3. rvals can be coalesced (from contiguous packet bytes)
    std::vector<const UseGroup*>
    coalesce_uses(const IR::BFN::Parser* parser, const UseDef& use_def) {
        std::vector<std::vector<const Use*>> use_groups;

        // let's first group by condition 1 & 2

        for (auto& kv : use_def.use_to_defs) {
            bool joined = false;

            for (auto& group : use_groups) {
                auto leader = *group.begin();

                if (have_same_use_def_states(use_def, kv.first, leader)) {
                    group.push_back(kv.first);
                    joined = true;
                    break;
                }
            }

            if (!joined)
                use_groups.push_back({kv.first});
        }

        // now coalesce by condition 3

        std::vector<const UseGroup*> coalesced;

        for (auto& group : use_groups) {
            sort_use_group(group, use_def);

            auto coals = coalesce_group(group, parser, use_def);

            for (auto& coal : coals)
                coalesced.push_back(coal);
        }

        // TODO finally, sort group based on size, live range

        if (LOGGING(2)) {
            std::clog << "created " << coalesced.size()
                      << " coalesced groups:" << std::endl;

            unsigned id = 0;

            for (auto coal : coalesced) {
                std::clog << "group " << id++ << ": ";
                std::clog << coal->print() << std::endl;
            }
        }

        return coalesced;
    }

    bool is_ancestor(const IR::BFN::ParserGraph& graph,
                     const IR::BFN::Transition* x_def,
                     const IR::BFN::ParserState* y_use) {
        return x_def->next == y_use || graph.is_ancestor(x_def->next, y_use);
    }

    /// returns true if x's defs intersects y's (def,use)
    bool overlap(const IR::BFN::ParserGraph& graph,
                 const UseGroup* x, const UseGroup* y) {
        auto x_defs = x->get_def_transitions();

        auto y_use = y->get_use_state();
        auto y_defs = y->get_def_transitions();

        auto same_defs = x->have_same_defs(y);

        for (auto x_def : x_defs) {
            if (is_ancestor(graph, x_def, y_use)) {
                for (auto y_def : y_defs) {
                    if (!same_defs) {
                        auto x_def_src = graph.get_src(x_def);
                        if (x_def == y_def || is_ancestor(graph, y_def, x_def_src))
                            return true;
                    }
                }
            }
        }

        return false;
    }

    /// returns true if a and b's live range intersection is not null
    bool interfere(const IR::BFN::ParserGraph& graph,
                   const UseGroup* a, const UseGroup* b) {
        if (overlap(graph, a, b))
            return true;

        if (overlap(graph, b, a))
            return true;

        return false;
    }

    std::vector<MatchRegister>
    get_available_regs(const ordered_set<MatchRegister>& used) {
        std::vector<MatchRegister> avail;

        for (auto reg : Device::pardeSpec().matchRegisters()) {
            if (!used.count(reg))
                avail.push_back(reg);
        }

        return avail;
    }

    /// Given a set of available registers to the group, choose a
    /// set of registers that will cover all select fields.
    std::vector<MatchRegister>
    allocate(const UseGroup* group, std::vector<MatchRegister> avail_regs) {
        auto select_bytes = group->bytes_in_group;

        unsigned total_reg_bytes = 0;
        for (auto reg : avail_regs)
            total_reg_bytes += reg.size;

        if (select_bytes > total_reg_bytes)  // not enough registers, bail
            return {};

        // try allocating in ascending order of container size
        std::vector<MatchRegister> alloc_ascend;
        unsigned reg_bytes_ascend = 0;

        for (auto reg : avail_regs) {
            if (reg_bytes_ascend >= select_bytes)
                break;

            alloc_ascend.push_back(reg);
            reg_bytes_ascend += reg.size;
        }

        if (Device::currentDevice() == Device::JBAY)  // all register of equal size in jbay
            return alloc_ascend;

        // now try allocating in descending order of container size
        std::reverse(avail_regs.begin(), avail_regs.end());

        std::vector<MatchRegister> alloc_descend;
        unsigned reg_bytes_descend = 0;

        for (auto reg : avail_regs) {
            if (reg_bytes_descend >= select_bytes)
                break;

            alloc_descend.push_back(reg);
            reg_bytes_descend += reg.size;
        }

        // pick better alloc of the two (first fit ascending vs. descending)
        if (reg_bytes_ascend < reg_bytes_descend)
            return alloc_ascend;

        if (reg_bytes_descend < reg_bytes_ascend)
            return alloc_descend;

        if (alloc_ascend.size() < alloc_descend.size())
            return alloc_ascend;

        if (alloc_descend.size() < alloc_ascend.size())
            return alloc_descend;

        return alloc_ascend;
    }

    /// Success is not final, failure is fatal.
    void fail(const UseGroup* group) {
        std::stringstream avail;

        avail << "Total available parser match registers on the device are: ";

        if (Device::currentDevice() == Device::TOFINO)
            avail << "1x16b, 2x8b.";
        else if (Device::currentDevice() == Device::JBAY)
            avail << "4x8b.";
        else
            BUG("Unknown device");

        std::stringstream hint;

        hint << "Consider shrinking the live range of select fields or reducing the";
        hint << " number of select fields that are being matched in the same state.";

        ::fatal_error("Ran out of parser match registers for %1%.\n%2% %3%",
                       group->print(), avail.str(), hint.str());
    }

    /// Bind the allocation results to the group. Also create the
    /// match register read and write intructions which will be
    /// inserted into the IR by the subsequent InsertSaveAndSelect pass.
    void save_result(const IR::BFN::Parser* parser, const UseGroup* group,
                     const std::vector<MatchRegister>& alloc_regs) {
         auto& graph = parser_info.graph(parser);

        // def
        for (auto transition : group->get_def_transitions()) {
            auto src_state = graph.get_src(transition);
            auto def_state = group->get_def_state(transition);

            nw_byterange group_range = group->get_range(def_state).toUnit<RangeUnit::Byte>();

            if (src_state != def_state) {
                BUG_CHECK(transition->next == def_state, "whoa");
                auto shift = *(transition->shift);
                group_range = group_range.shiftedByBytes(shift);
            }

            unsigned bytes = 0;

            for (auto& reg : alloc_regs) {
                unsigned lo = group_range.lo + bytes;
                nw_byterange reg_range(lo, lo + reg.size - 1);

                BUG_CHECK(reg_range.size() <= reg.size,
                           "saved bits greater than register size?");

                // The state splitter should have split the states such that the branch
                // word is withtin current state. This is the pre-condition of this pass.
                BUG_CHECK(reg_range.lo >= 0 &&
                          reg_range.hi <= Device::pardeSpec().byteInputBufferSize(),
                          "branch word out of current input buffer!");

                auto save = new IR::BFN::SaveToRegister(reg, reg_range);

                bool saved = false;
                for (auto s : transition_saves[transition]) {
                    if (save->equiv(*s)) {
                        saved = true;
                        break;
                    }
                }

                if (!saved)
                    transition_saves[transition].push_back(save);

                bytes += reg.size;
            }
        }

        // use
        for (auto use : group->members) {
            auto reg_slices = group->calc_reg_slices_for_use(use, alloc_regs);

            if (select_reg_slices.count(use->select)) {
                bool eq = equiv(select_reg_slices.at(use->select), reg_slices);

                BUG_CHECK(eq, "select has different allocations based on the use context: %1%",
                          use->print());

                // XXX(zma) This check is really an aritificial constraint; We can
                // of course give different allocations based on the context (use state).
                // The thing is I'm not really sure how the subsequent Modifier can
                // perform a context based revisit on the IR::BFN::Select node.
            } else {
                select_reg_slices[use->select] = reg_slices;
            }
        }
    }

    /// This is the core allocation routine. The basic idea to use two select
    /// groups' interference relationship to determine whether they can be
    /// allocated to the same set of registers.
    void allocate(const IR::BFN::Parser* parser, const UseDef& use_def) {
        auto coalesced_groups = coalesce_uses(parser, use_def);

        auto& graph = parser_info.graph(parser);

        std::map<const UseGroup*, std::vector<MatchRegister>> group_to_alloc_regs;

        for (auto group : coalesced_groups) {
            try {
                if (group_to_alloc_regs.count(group))
                    continue;

                std::vector<MatchRegister> alloc_regs;

                ordered_set<MatchRegister> cannot_alloc_regs;

                for (auto& gr : group_to_alloc_regs) {
                    if (interfere(graph, group, gr.first)) {
                        for (auto& r : gr.second)
                            cannot_alloc_regs.insert(r);

                        LOG3("group " << group->print() << " interferes with "
                                      << gr.first->print());
                    }
                }

                auto avail_regs = get_available_regs(cannot_alloc_regs);

                if (avail_regs.empty()) fail(group);

                alloc_regs = allocate(group, avail_regs);

                if (alloc_regs.empty()) fail(group);

                group_to_alloc_regs[group] = alloc_regs;  // success

                save_result(parser, group, alloc_regs);

                // propagate alloc to all groups that have same def
                for (auto other : coalesced_groups) {
                    if (group->have_same_defs(other) && !group_to_alloc_regs.count(other)) {
                        group_to_alloc_regs[other] = alloc_regs;
                        save_result(parser, other, alloc_regs);
                    }
                }

                if (LOGGING(1)) {
                    std::clog << "allocated { ";
                    for (auto& reg : alloc_regs) std::clog << "$" << reg.name << " ";
                    std::clog << "} to " << group->print() << std::endl;
                }
            } catch (const Util::CompilerBug &e) {
                std::stringstream ss;
                ss << "An error occured while the compiler was allocating parser match";
                ss << " registers for " << group->print() << ".";  // sorry
                BUG("%1%", ss.str());
            }
        }
    }
};

/// Insert match register read/write instruction in the IR
struct InsertSaveAndSelect : public ParserModifier {
    explicit InsertSaveAndSelect(const MatcherAllocator& saves)
        : rst(saves) { }

    void postorder(IR::BFN::Transition* transition) override {
        auto* original_transition = getOriginal<IR::BFN::Transition>();
        if (rst.transition_saves.count(original_transition)) {
            for (const auto* save : rst.transition_saves.at(original_transition)) {
                transition->saves.push_back(save);
                auto state = findContext<IR::BFN::ParserState>();

                BUG_CHECK(transition->next, "insert save on transition to <end>?");

                LOG4("insert " << save << " on " << state->name << " -> "
                               << transition->next->name);
            }
        }
    }

    void postorder(IR::BFN::Select* select) override {
        auto* original_select = getOriginal<IR::BFN::Select>();
        if (rst.select_reg_slices.count(original_select)) {
            select->reg_slices = rst.select_reg_slices.at(original_select);
        }
    }

    const MatcherAllocator& rst;
};

/// Adjust the match constant according to the select field's
/// alignment in the match register(s)
class MatchRegisterLayout {
 private:
    std::vector<MatchRegister> all_regs;
    std::map<MatchRegister, match_t> values;
    size_t total_size;

    match_t shiftRight(match_t val, int n) {
        auto word0 = val.word0;
        auto word1 = val.word1;
        word0 >>= n;
        word1 >>= n;
        return match_t(word0, word1);
    }

    match_t shiftLeft(match_t val, int n) {
        auto word0 = val.word0;
        auto word1 = val.word1;
        word0 <<= n;
        word1 <<= n;
        return match_t(word0, word1);
    }

    match_t orTwo(match_t a, match_t b) {
        auto word0 = (a.word0 | b.word0);
        auto word1 = (a.word1 | b.word1);
        return match_t(word0, word1);
    }

    match_t setWild(match_t a) {
        auto word0 = a.word0;
        auto word1 = a.word1;
        auto wilds = (~(word0 ^ word1)) & (~((~uintmax_t(0)) << total_size));
        return match_t(word0 | wilds, word1 | wilds);
    }

    // start is the from the left
    match_t getSubValue(match_t val, int sz, int start, int len) {
        auto word0 = val.word0;
        auto word1 = val.word1;
        uintmax_t mask = (~((~uintmax_t(0)) << (sz - start)));
        auto trim_left_word0 = (word0 & mask);
        auto trim_left_word1 = (word1 & mask);
        return shiftRight(match_t(trim_left_word0, trim_left_word1), sz - start - len);
    }

 public:
    explicit MatchRegisterLayout(ordered_set<MatchRegister> used_regs)
        : total_size(0) {
        for (const auto& r : used_regs) {
            total_size += r.size * 8;
            all_regs.push_back(r);
            values[r] = match_t(0, 0); }
    }

    void writeValue(const IR::BFN::Select* select, match_t val) {
        auto& reg_slices = select->reg_slices;

        int val_size = 0;
        int val_shifted = 0;

        for (auto rs : reg_slices)
            val_size += rs.second.size();

        for (auto& slice : reg_slices) {
            auto& reg = slice.first;
            auto& reg_sub_range = slice.second;

            nw_bitrange reg_range(0, reg.size * 8 - 1);
            BUG_CHECK(reg_range.contains(reg_sub_range),
                      "range not part of parser match register?");

            match_t slice_val = getSubValue(val, val_size, val_shifted, reg_sub_range.size());
            match_t val_to_or = shiftLeft(slice_val, reg.size * 8 - reg_sub_range.hi - 1);

            values[reg] = orTwo(values[reg], val_to_or);
            val_shifted += reg_sub_range.size();
        }

        BUG_CHECK(val_shifted == val_size, "value not entirely shifted?");
    }

    match_t getMatchValue() {
        int shift = 0;
        match_t rtn(0, 0);
        for (const auto& r : boost::adaptors::reverse(all_regs)) {
            rtn = orTwo(rtn, shiftLeft(values[r], shift));
            shift += r.size * 8;
        }
        return setWild(rtn);
    }
};

struct AdjustMatchValue : public ParserModifier {
    void postorder(IR::BFN::Transition* transition) override {
        if (transition->value->is<IR::BFN::ParserConstMatchValue>()) {
            adjustConstValue(transition);
        } else if (transition->value->is<IR::BFN::ParserPvsMatchValue>()) {
            adjustPvsValue(transition);
        } else {
            BUG("Unknown match value: %1%", transition->value);
        }
    }

    /// Adjust the transition value to a match_t that:
    ///   1. match_t value's size = sum of size of all used registers.
    ///   2. values are placed into their `slot` in match_t value.
    void adjustConstValue(IR::BFN::Transition* transition) {
        auto* state = findContext<IR::BFN::ParserState>();
        ordered_set<MatchRegister> used_registers;
        for (const auto* select : state->selects) {
            for (const auto& rs : select->reg_slices) {
                used_registers.insert(rs.first); } }

        // Pop out value for each select.
        auto const_val = transition->value->to<IR::BFN::ParserConstMatchValue>()->value;
        uintmax_t word0 = const_val.word0;
        uintmax_t word1 = const_val.word1;
        auto shiftOut = [&word0, &word1] (int sz) {
            uintmax_t mask = ~(~uintmax_t(0) << sz);
            uintmax_t sub0 = (word0 & mask);
            uintmax_t sub1 = (word1 & mask);
            word0 >>= sz;
            word1 >>= sz;
            return match_t(sub0, sub1); };

        std::map<const IR::BFN::Select*, match_t> select_values;
        for (const auto* select : boost::adaptors::reverse(state->selects)) {
            int value_size = 0;
            for (auto rs : select->reg_slices) {
                auto mask = rs.second;
                value_size += mask.size();
            }
            select_values[select] = shiftOut(value_size);
        }

        MatchRegisterLayout layout(used_registers);
        for (const auto* select : state->selects) {
            layout.writeValue(select, select_values[select]);
        }
        transition->value = new IR::BFN::ParserConstMatchValue(layout.getMatchValue());
    }

    /// Build a mapping from fieldslice to matcher slice by checking the field
    /// where the select originally matched on and the masking of the registers.
    void adjustPvsValue(IR::BFN::Transition* transition) {
        auto* state = findContext<IR::BFN::ParserState>();
        auto* old_value = transition->value->to<IR::BFN::ParserPvsMatchValue>();
        auto* adjusted = new IR::BFN::ParserPvsMatchValue(old_value->name, old_value->size);

        for (const auto* select : state->selects) {
            cstring field_name = select->p4Source->toString();

            int field_start = 0;
            for (const auto& rs : boost::adaptors::reverse(select->reg_slices)) {
                auto reg = rs.first;
                auto reg_slice = rs.second.toOrder<Endian::Little>(reg.size * 8);

                nw_bitrange field_slice(StartLen(field_start, reg_slice.size()));
                adjusted->mapping[{field_name, field_slice}] =  {reg, reg_slice};

                LOG2("add PVS mapping: " << field_name << field_slice << " -> "
                     << reg << " : " << reg_slice);

                field_start += field_slice.size();
            }
        }

        transition->value = adjusted;
    }
};

struct CheckAllocation : public Inspector {
    bool preorder(const IR::BFN::Select* select) override {
        BUG_CHECK(select->reg_slices.size() > 0,
            "Parser match register not allocated for %1%", select->p4Source);
        return false;
    }
};

AllocateParserMatchRegisters::AllocateParserMatchRegisters(const PhvInfo& phv) {
    auto* parserInfo = new CollectParserInfo;
    auto* collectUseDef = new CollectUseDef(phv, *parserInfo);
    auto* allocator = new MatcherAllocator(*parserInfo, collectUseDef->parser_use_def);

    addPasses({
        LOGGING(4) ? new DumpParser("before_parser_match_alloc") : nullptr,
        new ResolveOutOfBufferSelects,
        LOGGING(4) ? new DumpParser("after_resolve_oob_selects") : nullptr,
        parserInfo,
        collectUseDef,
        allocator,
        new InsertSaveAndSelect(*allocator),
        new AdjustMatchValue,
        new CheckAllocation,
        LOGGING(4) ? new DumpParser("after_parser_match_alloc") : nullptr
    });
}
