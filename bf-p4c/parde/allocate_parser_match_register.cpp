#include <boost/range/adaptors.hpp>

#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/parde/allocate_parser_match_register.h"
#include "bf-p4c/parde/collect_parser_usedef.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/parser_info.h"
#include "device.h"

using namespace Parser;

// If the start state has selects, we need to insert a dummy state
// before it where we can insert the save instructions.
struct InsertInitSaveState : public ParserTransform {
    IR::BFN::Parser* preorder(IR::BFN::Parser* parser) override {
        auto init = new IR::BFN::ParserState(nullptr, "$init_match", parser->start->gress);
        auto next = new IR::BFN::Transition(match_t(), 0, parser->start);
        init->transitions = { next };
        parser->start = init;

        return parser;
    }
};

// Insert a stall state on transition whose next state requires
// branch word that is out of the input buffer of the current state.
struct ResolveOutOfBufferSaves : public ParserTransform {
    const ParserUseDef& parser_use_def;
    CollectParserInfo parser_info;

    explicit ResolveOutOfBufferSaves(const ParserUseDef& pud) : parser_use_def(pud) { }

    profile_t init_apply(const IR::Node* root) override {
        root->apply(parser_info);
        return ParserTransform::init_apply(root);
    }

    // keep track of number stall states from orig_state
    std::map<cstring, unsigned> orig_state_to_stall_cnt;

    void insert_stall_state_for_oob_save(IR::BFN::Transition* t) {
        auto orig = getOriginal<IR::BFN::Transition>();
        auto parser = findOrigCtxt<IR::BFN::Parser>();
        auto src = parser_info.graph(parser).get_src(orig);

        auto cnt = orig_state_to_stall_cnt[src->name]++;
        cstring name = src->name + ".$oob_stall_" + cstring::to_cstring(cnt);
        auto stall = new IR::BFN::ParserState(src->p4State, name, src->gress);

        LOG2("created stall state for out of buffer select on "
              << src->name << " -> " << t->next->name);

        auto to_dst = new IR::BFN::Transition(match_t(), 0, t->next);
        stall->transitions.push_back(to_dst);
        t->next = stall;

        // move loop back to stall state
        if (t->loop) {
            to_dst->loop = t->loop;
            t->loop = cstring();
        }
    }

    struct GetMaxSavedRVal : Inspector {
        int rv = -1;

        bool preorder(const IR::BFN::SavedRVal* save) override {
            if (auto buf = save->source->to<IR::BFN::PacketRVal>())
                rv = std::max(buf->range.hi, rv);
            return false;
        }
    };

    const IR::BFN::ParserState* get_next_state(const IR::BFN::Transition* t) {
        if (t->next) {
            return t->next;
        } else if (t->loop) {
            auto parser = findOrigCtxt<IR::BFN::Parser>();
            return parser_info.graph(parser).get_state(t->loop);
        } else {
            return nullptr;
        }
    }

    bool has_oob_save(const IR::BFN::Transition* t) {
        if (auto next = get_next_state(t)) {
            GetMaxSavedRVal max_save;

            next->selects.apply(max_save);
            next->statements.apply(max_save);

            if (max_save.rv >= 0) {
                return int(t->shift + max_save.rv / 8 + 1) >
                   Device::pardeSpec().byteInputBufferSize();
            }

            // If scratch regs are available, we may need the additional choice of
            // scratching at the predecessors. Therefore if the branch words are
            // more than 32 bytes away at the incoming transitions to the def states
            // we need to insert stall states.

            if (!Device::pardeSpec().scratchRegisters().empty()) {
                auto parser = findOrigCtxt<IR::BFN::Parser>();
                auto use_def = parser_use_def.at(parser);

                for (auto& ud : use_def.use_to_defs) {
                    for (auto d : ud.second) {
                        if (d->state->name == next->name) {
                            if (auto buf = d->rval->to<IR::BFN::PacketRVal>()) {
                                if (int(t->shift + buf->range.hi / 8 + 1) >
                                        Device::pardeSpec().byteInputBufferSize()) {
                                    return true;
                                }
                            }
                        }
                    }
                }
            }
        }

        return false;
    }

    IR::BFN::Transition* postorder(IR::BFN::Transition* t) override {
        if (has_oob_save(t))
            insert_stall_state_for_oob_save(t);

        return t;
    }
};

static
bool equiv(const std::vector<std::pair<MatchRegister, nw_bitrange>>& a,
           const std::vector<std::pair<MatchRegister, nw_bitrange>>& b) {
    if (a.size() != b.size()) return false;
    for (unsigned i = 0; i < a.size(); i++)
        if (a[i] != b[i]) return false;
    return true;
}

typedef std::map<const IR::BFN::Transition*, const IR::BFN::ParserState*> DefSet;

struct AllocationResult {
    // The saves need to be executed on this transition.
    std::map<const IR::BFN::Transition*,
             std::vector<const IR::BFN::SaveToRegister*>> transition_saves;

    // Registers to scratches on this transition.
    std::map<const IR::BFN::Transition*,
             std::set<MatchRegister>> transition_scratches;

    // The register slices that this select should match against.
    std::map<const Use*,
             std::vector<std::pair<MatchRegister, nw_bitrange>>> save_reg_slices;
};

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
    AllocationResult result;

 private:
    /// Represents a group of select fields that can be coalesced into
    /// single allocation unit (see comment below for coalescing).
    struct UseGroup {
        const UseDef& use_def;

        std::vector<const Use*> members;

        std::vector<DefSet> def_transition_sets;

        unsigned bits_in_group = 0;

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

        const Def*
        get_def(const IR::BFN::ParserState* def_state) const {
            auto leader = members.front();
            return use_def.get_def(leader, def_state);
        }

        const IR::BFN::ParserState*
        get_def_state(const IR::BFN::Transition* def_transition) const {
            for (auto& def_set : def_transition_sets) {
                if (def_set.count(def_transition))
                    return def_set.at(def_transition);
            }

            return nullptr;
        }

        DefSet get_pred_def_set(const IR::BFN::ParserGraph& graph,
                                const std::vector<const IR::BFN::ParserState*> def_states) {
            DefSet def_set;

            for (auto def_state : def_states) {
                for (auto pred : graph.predecessors().at(def_state)) {
                    for (auto t : graph.transitions(pred, def_state))
                        def_set[t] = def_state;
                }

                for (auto& kv : graph.loopbacks()) {
                    if (kv.first.second == def_state->name) {
                        for (auto t : kv.second)
                            def_set[t] = def_state;
                    }
                }
            }

            return def_set;
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

                DefSet def_set = get_pred_def_set(graph, def_states);

                def_transition_sets.push_back(def_set);
            } else {  // case 2: def states are ancestor states
                DefSet succ_def_set;

                for (auto def_state : def_states) {
                    for (auto succ : graph.successors().at(def_state)) {
                        if (succ == use_state || graph.is_ancestor(succ, use_state)) {
                            for (auto t : graph.transitions(def_state, succ))
                                succ_def_set[t] = def_state;
                        }
                    }
                }

                def_transition_sets.push_back(succ_def_set);

                // If scratch regs are available, we may need the additional choice of
                // scratching at the predecessors
                if (!Device::pardeSpec().scratchRegisters().empty()) {
                    DefSet pred_def_set = get_pred_def_set(graph, def_states);

                    def_transition_sets.push_back(pred_def_set);
                }
            }

            if (LOGGING(5)) {
                std::clog << "group: " << print() << " has " << def_transition_sets.size()
                          << " def sets:" << std::endl;

                unsigned id = 0;
                for (auto& def_set : def_transition_sets) {
                    std::clog << "def set " << id++ << ":" << std::endl;

                    for (auto& kv : def_set) {
                        std::clog << graph.get_src(kv.first)->name << " -> "
                                  << (kv.first->next ? kv.first->next->name : kv.first->loop)
                                  << std::endl;
                    }
                }
            }

            BUG_CHECK(!def_transition_sets.empty(), "no def transition sets for select group?");
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

            return true;
        }

        unsigned bytes_in_group() const {
            auto head_defs = use_def.use_to_defs.at(members.front());
            auto tail_defs = use_def.use_to_defs.at(members.back());

            auto lo = head_defs.at(0)->rval->range.lo / 8;
            auto hi = tail_defs.at(0)->rval->range.hi / 8;

            auto bytes = hi - lo + 1;
            return bytes;
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

        // a's defs are subset of b's defs
        bool have_subset_defs(const Use* a, const Use* b) const {
            auto a_defs = use_def.use_to_defs.at(a);
            auto b_defs = use_def.use_to_defs.at(b);

            for (unsigned i = 0; i < a_defs.size(); i++) {
                bool exists = false;

                for (unsigned j = 0; j < b_defs.size(); j++) {
                    if (a_defs.at(i)->equiv(b_defs.at(j))) {
                        exists = true;
                        break;
                    }
                }

                if (!exists)
                    return false;
            }

            return true;
        }

        bool have_same_defs(const UseGroup* other) const {
            if (members.size() != other->members.size()) return false;
            return have_same_defs(members.at(0), other->members.at(0));
        }

        bool have_subset_defs(const UseGroup* other) const {
            if (members.size() != other->members.size()) return false;
            return have_subset_defs(members.at(0), other->members.at(0));
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
            allocate_all(kv.first, kv.second);

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
                 const UseGroup* x, const DefSet& x_defs,
                 const UseGroup* y, const DefSet& y_defs) {
        auto y_use = y->get_use_state();

        for (auto& kv : x_defs) {
            auto x_def = kv.first;
            auto x_def_state = kv.second;

            if (is_ancestor(graph, x_def, y_use)) {
                for (auto& xy : y_defs) {
                    auto y_def = xy.first;
                    auto y_def_state = xy.second;
                    auto x_def_src = graph.get_src(x_def);

                    auto xd = x->get_def(x_def_state);
                    auto yd = y->get_def(y_def_state);

                    if (xd->equiv(yd))
                        continue;

                    if (x_def == y_def || is_ancestor(graph, y_def, x_def_src))
                        return true;
                }
            }
        }

        return false;
    }

    /// returns true if a and b's live range intersection is not null
    bool interfere(const IR::BFN::ParserGraph& graph,
                   const UseGroup* a, const DefSet& a_defs,
                   const UseGroup* b, const DefSet& b_defs) {
        if (overlap(graph, a, a_defs, b, b_defs))
            return true;

        if (overlap(graph, b, b_defs, a, a_defs))
            return true;

        return false;
    }

    struct Allocation {
        std::map<const UseGroup*, std::vector<MatchRegister>> group_to_alloc_regs;
        std::map<const UseGroup*, DefSet> group_to_def_set;
    };

    bool can_scratch(const UseGroup* group,
                     MatchRegister scratch,
                     const Allocation& allocation,
                     const DefSet& def_set) {
        for (auto& kv : def_set) {
            auto transition = kv.first;

            for (auto& gr : allocation.group_to_def_set) {
                if (gr.second.count(transition)) {
                    for (auto reg : allocation.group_to_alloc_regs.at(gr.first)) {
                        if (group->have_subset_defs(gr.first) || gr.first->have_subset_defs(group))
                            continue;

                        if (reg.name == scratch.name.substr(5))
                            return false;
                    }
                }
            }
        }

        return true;
    }

    std::vector<MatchRegister>
    get_available_regs(const IR::BFN::Parser* parser,
                       const UseGroup* group,
                       const Allocation& allocation,
                       const DefSet& def_set) {
        auto& graph = parser_info.graph(parser);

        ordered_set<MatchRegister> used_regs;

        for (auto& their : allocation.group_to_alloc_regs) {
            auto they = their.first;
            auto& their_regs = their.second;
            auto& their_defs = allocation.group_to_def_set.at(they);

            if (interfere(graph, group, def_set, they, their_defs)) {
                for (auto& r : their_regs)
                    used_regs.insert(r);

                LOG3("group " << group->print() << " interferes with "
                              << they->print());
            }
        }

        std::vector<MatchRegister> avail;

        for (auto reg : Device::pardeSpec().matchRegisters()) {
            if (!used_regs.count(reg))
                avail.push_back(reg);
        }

        for (auto reg : Device::pardeSpec().scratchRegisters()) {
            if (!used_regs.count(reg)) {
                if (can_scratch(group, reg, allocation, def_set)) {
                    avail.push_back(reg);
                }
            }
        }

        LOG3("available regs are:");
        for (auto reg : avail)
            LOG3(reg.name);

        return avail;
    }

    /// Given a set of available registers to the group, choose a
    /// set of registers that will cover all select fields.
    std::vector<MatchRegister>
    allocate(const UseGroup* group, std::vector<MatchRegister> avail_regs) {
        auto select_bytes = group->bytes_in_group();

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

    MatchRegister get_match_register(MatchRegister scratch) {
        for (auto reg : Device::pardeSpec().matchRegisters()) {
            if (reg.name == scratch.name.substr(5))
                return reg;
        }

        BUG("Match register does not exist for %1%", scratch);
    }

    /// Success is not final, failure is fatal.
    void fail(const UseGroup* group) {
        std::stringstream avail;

        avail << "Total available parser match registers on the device are: ";

        if (Device::currentDevice() == Device::TOFINO)
            avail << "1x16b, 2x8b.";
        else if (Device::currentDevice() == Device::JBAY)
            avail << "4x8b.";
#if HAVE_CLOUDBREAK
        else if (Device::currentDevice() == Device::CLOUDBREAK)
            avail << "4x8b.";
#endif /* HAVE_CLOUDBREAK */
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
    void bind_def(const IR::BFN::Parser* parser, const UseGroup* group,
                  const std::vector<MatchRegister>& alloc_regs,
                  const DefSet& def_set) {
        auto& graph = parser_info.graph(parser);

        // def
        for (auto& kv : def_set) {
            auto transition = kv.first;

            auto src_state = graph.get_src(transition);
            auto def_state = group->get_def_state(transition);

            nw_byterange group_range = group->get_range(def_state).toUnit<RangeUnit::Byte>();

            if (src_state != def_state) {
                auto shift = transition->shift;
                group_range = group_range.shiftedByBytes(shift);
            }

            unsigned bytes = 0;

            for (auto reg : alloc_regs) {
                unsigned lo = group_range.lo + bytes;
                nw_byterange reg_range(lo, lo + reg.size - 1);

                BUG_CHECK(size_t(reg_range.size()) <= reg.size,
                           "saved bits greater than register size?");

                // The state splitter should have split the states such that the branch
                // word is withtin current state. This is the pre-condition of this pass.
                BUG_CHECK(reg_range.lo >= 0 &&
                          reg_range.hi <= Device::pardeSpec().byteInputBufferSize(),
                          "branch word out of current input buffer!");

                bool scratch = false;

                if (reg.name.startsWith("save_")) {
                    reg = get_match_register(reg);
                    scratch = true;
                }

                auto save = new IR::BFN::SaveToRegister(reg, reg_range);

                bool saved = false;
                for (auto s : result.transition_saves[transition]) {
                    if (save->equiv(*s)) {
                        saved = true;
                        break;
                    }
                }

                if (!saved)
                    result.transition_saves[transition].push_back(save);

                if (scratch)
                    result.transition_scratches[transition].insert(reg);

                bytes += reg.size;
            }
        }
    }

    void bind_use(const UseGroup* group,
                  const std::vector<MatchRegister>& alloc_regs) {
        // use
        for (auto use : group->members) {
            auto reg_slices = group->calc_reg_slices_for_use(use, alloc_regs);

            if (result.save_reg_slices.count(use)) {
                bool eq = equiv(result.save_reg_slices.at(use), reg_slices);

                BUG_CHECK(eq, "select has different allocations based on the use context: %1%",
                          use->print());
            } else {
                result.save_reg_slices[use] = reg_slices;
            }
        }
    }

    void bind_alloc(const IR::BFN::Parser* parser, const UseGroup* group,
                    Allocation& allocation,
                    const std::vector<MatchRegister>& alloc_regs,
                    const DefSet& def_set) {
        allocation.group_to_alloc_regs[group] = alloc_regs;

        allocation.group_to_def_set[group] = def_set;

        bind_def(parser, group, alloc_regs, def_set);

        bind_use(group, alloc_regs);

        if (LOGGING(1)) {
            std::clog << "allocated { ";
            for (auto& reg : alloc_regs) std::clog << "$" << reg.name << " ";
            std::clog << "} to " << group->print() << std::endl;
        }
    }

    bool allocate_group(const IR::BFN::Parser* parser, const UseGroup* group,
                        Allocation& allocation) {
        bool success = false;

        LOG3(">>>>>>>>>>>>>>>>");
        LOG3("allocating " << group->print());

        // try all def transition sets of group
        unsigned id = 0;

        for (auto& def_set : group->def_transition_sets) {
            LOG3("try def set " << id++);

            auto avail_regs = get_available_regs(parser, group, allocation, def_set);

            auto alloc_regs = allocate(group, avail_regs);

            if (!alloc_regs.empty()) {
                success = true;
                bind_alloc(parser, group, allocation, alloc_regs, def_set);
                LOG3("success");
                break;
            } else {
                LOG3("not ok");
            }
        }

        LOG3("<<<<<<<<<<<<<<<<");

        return success;
    }

    /// This is the core allocation routine. The basic idea to use two select
    /// groups' interference relationship to determine whether they can be
    /// allocated to the same set of registers.
    void allocate_all(const IR::BFN::Parser* parser, const UseDef& use_def) {
        auto coalesced_groups = coalesce_uses(parser, use_def);

        auto saved_result = result;  // save result

        LOG3("try allocating top down:");
        auto top_down_unalloc = try_allocate_all(parser, coalesced_groups);

        if (!top_down_unalloc) {
            LOG3("top down allocation successful!");
            return;
        }

        result = saved_result;  // rollback

        LOG3("try allocating bottom up:");
        std::reverse(coalesced_groups.begin(), coalesced_groups.end());
        auto bottom_up_unalloc = try_allocate_all(parser, coalesced_groups);

        if (!bottom_up_unalloc) {
            LOG3("bottom up allocation successful!");
            return;
        }

        fail(top_down_unalloc);
    }

    const UseGroup* try_allocate_all(const IR::BFN::Parser* parser,
                                     const std::vector<const UseGroup*>& coalesced_groups) {
        Allocation allocation;

        for (auto group : coalesced_groups) {
            try {
                if (allocation.group_to_alloc_regs.count(group))
                    continue;

                if (!allocate_group(parser, group, allocation))
                    return group;

                if (Device::pardeSpec().scratchRegisters().empty()) {
                    for (auto other : coalesced_groups) {
                        if (!allocation.group_to_alloc_regs.count(other)) {
                            if (group->have_subset_defs(other) ||
                                other->have_subset_defs(group)) {
                                if (!allocate_group(parser, other, allocation))
                                    return other;
                            }
                        }
                    }
                }
            } catch (const Util::CompilerBug &e) {
                std::stringstream ss;
                ss << "An error occured while the compiler was allocating parser match";
                ss << " registers for " << group->print() << ".";  // sorry
                BUG("%1%", ss.str());
            }
        }

        return nullptr;
    }
};

/// Insert match register read/write instruction in the IR
struct InsertSaveAndSelect : public ParserModifier {
    explicit InsertSaveAndSelect(const AllocationResult& result) : rst(result) { }

    void postorder(IR::BFN::Transition* transition) override {
        auto original_transition = getOriginal<IR::BFN::Transition>();

        if (rst.transition_saves.count(original_transition)) {
            for (auto save : rst.transition_saves.at(original_transition)) {
                transition->saves.push_back(save);
            }
        }

        if (rst.transition_scratches.count(original_transition)) {
            for (auto reg : rst.transition_scratches.at(original_transition)) {
                transition->scratches.insert(reg);
            }
        }
    }

    void postorder(IR::BFN::SavedRVal* save) override {
        auto state = findContext<IR::BFN::ParserState>();
        auto use = new Use(state, save);

        for (auto& kv : rst.save_reg_slices) {
            if (kv.first->equiv(use)) {
                save->reg_slices = kv.second;
                return;
            }
        }

        auto select = findContext<IR::BFN::Select>();
        BUG("Parser match register not allocated for %1%", select->p4Source);
    }

    const AllocationResult& rst;
};

/// Adjust the match constant according to the select field's
/// alignment in the match register(s) and/or counter reads
class MatchLayout {
 private:
    std::vector<cstring> sources;
    std::map<cstring, match_t> values;
    std::map<cstring, size_t> sizes;
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

    match_t setDontCare(match_t a) {
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

    void writeValue(const IR::BFN::Select* select, match_t val) {
        if (auto saved = select->source->to<IR::BFN::SavedRVal>()) {
            auto& reg_slices = saved->reg_slices;
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

                values[reg.name] = orTwo(values[reg.name], val_to_or);
                val_shifted += reg_sub_range.size();
            }

            BUG_CHECK(val_shifted == val_size, "value not entirely shifted?");
        } else if (auto cntr = select->source->to<IR::BFN::ParserCounterIsZero>()) {
            values[cntr->declName + ".ctr_zero"] = val;
        } else if (auto cntr = select->source->to<IR::BFN::ParserCounterIsNegative>()) {
            values[cntr->declName + ".ctr_neg"] = val;
        } else {
            BUG("Unknown parser select source");
        }
    }

 public:
    explicit MatchLayout(const IR::BFN::ParserState* state,
                         const IR::BFN::Transition* transition) : total_size(0) {
        for (const auto* select : state->selects) {
            if (auto saved = select->source->to<IR::BFN::SavedRVal>()) {
                for (const auto& rs : saved->reg_slices) {
                    auto reg = rs.first;
                    if (!values.count(reg.name)) {
                        sources.push_back(reg.name);
                        values[reg.name] = match_t();
                        sizes[reg.name] = reg.size * 8;
                        total_size += reg.size * 8;
                    }
                }
            } else if (auto cntr = select->source->to<IR::BFN::ParserCounterIsZero>()) {
                sources.push_back(cntr->declName + ".ctr_zero");
                values[cntr->declName + ".ctr_zero"] = match_t();
                sizes[cntr->declName + ".ctr_zero"] = 1;
                total_size += 1;
            } else if (auto cntr = select->source->to<IR::BFN::ParserCounterIsNegative>()) {
                sources.push_back(cntr->declName + ".ctr_neg");
                values[cntr->declName + ".ctr_neg"] = match_t();
                sizes[cntr->declName + ".ctr_neg"] = 1;
                total_size += 1;
            }
        }

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
            if (auto saved = select->source->to<IR::BFN::SavedRVal>()) {
                for (auto rs : saved->reg_slices) {
                    auto mask = rs.second;
                    value_size += mask.size();
                }
                select_values[select] = shiftOut(value_size);
            } else if (select->source->is<IR::BFN::ParserCounterRVal>()) {
                select_values[select] = shiftOut(1);
            }
        }

        for (const auto* select : state->selects) {
            if (select->source->is<IR::BFN::SavedRVal>() ||
                select->source->is<IR::BFN::ParserCounterRVal>())
                writeValue(select, select_values[select]);
        }
    }

    match_t getMatchValue() {
        int shift = 0;
        match_t rv;
        for (const auto& src : boost::adaptors::reverse(sources)) {
            rv = orTwo(rv, shiftLeft(values[src], shift));
            shift += sizes.at(src);
        }

        rv = setDontCare(rv);
        return rv;
    }
};

struct AdjustMatchValue : public ParserModifier {
    void postorder(IR::BFN::Transition* transition) override {
        if (transition->value->is<IR::BFN::ParserConstMatchValue>())
            adjustConstValue(transition);
        else if (transition->value->is<IR::BFN::ParserPvsMatchValue>())
            adjustPvsValue(transition);
        else
            BUG("Unknown match value: %1%", transition->value);
    }

    /// Adjust the transition value to a match_t that:
    ///   1. match_t value's size = sum of size of all used registers.
    ///   2. values are placed into their `slot` in match_t value.
    void adjustConstValue(IR::BFN::Transition* transition) {
        auto* state = findContext<IR::BFN::ParserState>();
        MatchLayout layout(state, transition);
        auto value = layout.getMatchValue();
        transition->value = new IR::BFN::ParserConstMatchValue(value);
    }

    /// Build a mapping from fieldslice to matcher slice by checking the field
    /// where the select originally matched on and the masking of the registers.
    void adjustPvsValue(IR::BFN::Transition* transition) {
        auto* state = findContext<IR::BFN::ParserState>();
        auto* old_value = transition->value->to<IR::BFN::ParserPvsMatchValue>();
        auto* adjusted = new IR::BFN::ParserPvsMatchValue(old_value->name, old_value->size);

        for (const auto* select : state->selects) {
            const IR::Expression* source = select->p4Source;
            if (auto sl = select->p4Source->to<IR::Slice>())
                source = sl->e0;

            cstring field_name = stripThreadPrefix(source->toString());
            field_name = canon_name(field_name);
            int field_start = 0;

            if (auto saved = select->source->to<IR::BFN::SavedRVal>()) {
                for (const auto& rs : boost::adaptors::reverse(saved->reg_slices)) {
                    auto reg = rs.first;
                    auto reg_slice = rs.second.toOrder<Endian::Little>(reg.size * 8);

                    nw_bitrange field_slice(StartLen(field_start, reg_slice.size()));
                    adjusted->mapping[{field_name, field_slice}] =  {reg, reg_slice};

                    LOG2("add PVS mapping: " << field_name << field_slice << " -> "
                         << reg << " : " << reg_slice);

                    field_start += field_slice.size();
                }
            }
        }

        transition->value = adjusted;
    }
};

const IR::BFN::ParserState*
can_remove(const IR::BFN::ParserState* state) {
    if (!state->statements.empty())
        return nullptr;

    if (!state->selects.empty())
        return nullptr;

    if (state->transitions.size() != 1)
        return nullptr;

    auto t = state->transitions[0];

    if (!t->saves.empty())
        return nullptr;

    if (t->shift == 0)
        return t->next;

    return nullptr;
}

// After match register allocation, if the start state is empty and its
// transition to the next state contains no writes to the match register,
// we can safely remove this empty state.
// Also, since extracts with MatchLVal type destination only exists to
// provide information for allocating parser match registers, they are no
// longer needed and can be deleted.
struct RemoveEmptyStartStateAndMatchExtract : public ParserTransform {
    IR::BFN::Parser* preorder(IR::BFN::Parser* parser) {
        if (parser->start) {
            if (auto next = can_remove(parser->start)) {
                parser->start = next;
                LOG4("removed empty parser start state on " << parser->gress);
            }
        }

        return parser;
    }

    IR::BFN::Extract* preorder(IR::BFN::Extract* extract) {
        if (extract->dest->is<IR::BFN::MatchLVal>()) {
            LOG5("Removed match value extract " << extract);
            return nullptr;
        }
        return extract;
    }
};

// If the stall state did not receive reg allocation, we can also
// safely remove this stall state.
struct RemoveEmptyStallState : public ParserModifier {
    void postorder(IR::BFN::Transition* t) override {
        if (t->next && t->next->name.find("$oob_stall")) {
            if (auto next = can_remove(t->next)) {
                t->next = next;
                LOG4("removed empty parser stall state  " << t->next->name);
            }
        }
    }
};

AllocateParserMatchRegisters::AllocateParserMatchRegisters(const PhvInfo& phv) {
    auto* parserInfo = new CollectParserInfo;
    auto* collectUseDef = new CollectParserUseDef(phv, *parserInfo);
    auto* resolveOobDefs = new ResolveOutOfBufferSaves(collectUseDef->parser_use_def);
    auto* allocator = new MatcherAllocator(*parserInfo, collectUseDef->parser_use_def);

    addPasses({
        LOGGING(4) ? new DumpParser("before_parser_match_alloc") : nullptr,
        new InsertInitSaveState,
        parserInfo,
        collectUseDef,
        resolveOobDefs,
        LOGGING(4) ? new DumpParser("after_resolve_oob_saves") : nullptr,
        parserInfo,
        collectUseDef,
        allocator,
        new InsertSaveAndSelect(allocator->result),
        new AdjustMatchValue,
        new RemoveEmptyStartStateAndMatchExtract,
        new RemoveEmptyStallState,
        LOGGING(4) ? new DumpParser("after_parser_match_alloc") : nullptr
    });
}
