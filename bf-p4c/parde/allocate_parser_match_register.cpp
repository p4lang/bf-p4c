#include <boost/range/adaptors.hpp>

#include "bf-p4c/common/utils.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/parde/allocate_parser_match_register.h"
#include "bf-p4c/parde/collect_parser_usedef.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/parser_info.h"
#include "device.h"

// Insert a stall state on transition whose next state requires
// branch word that is out of the input buffer of the current state.
struct ResolveOutOfBufferSaves : public ParserTransform {
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

    // keep track of number stall states from orig_state
    std::map<cstring, unsigned> orig_state_to_stall_cnt;

    void insert_stall_state_for_oob_save(IR::BFN::Transition* t) {
        auto orig = getOriginal<IR::BFN::Transition>();
        auto src = parser_info.graph(parser).get_src(orig);

        auto cnt = orig_state_to_stall_cnt[src->name]++;
        cstring name = src->name + ".$stall_" + cstring::to_cstring(cnt);
        auto stall = new IR::BFN::ParserState(src->p4State, name, src->gress);

        LOG2("created stall state for out of buffer select on "
              << src->name << " -> " << t->next->name);

        auto to_dst = new IR::BFN::Transition(match_t(), 0, t->next);
        stall->transitions.push_back(to_dst);
        t->next = stall;
    }

    struct GetMaxSavedRVal : Inspector {
        int rv = -1;

        bool preorder(const IR::BFN::SavedRVal* save) override {
            if (auto buf = save->source->to<IR::BFN::PacketRVal>())
                rv = std::max(buf->range.hi, rv);
            return false;
        }
    };

    bool has_oob_save(const IR::BFN::Transition* t) {
        if (!t->next)
            return false;

        GetMaxSavedRVal max_save;

        t->next->selects.apply(max_save);
        t->next->statements.apply(max_save);

        return (*t->shift + (max_save.rv + 7) / 8) > Device::pardeSpec().byteInputBufferSize();
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
    std::map<const IR::BFN::SavedRVal*,
             std::vector<std::pair<MatchRegister, nw_bitrange>>> save_reg_slices;

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

            if (save_reg_slices.count(use->save)) {
                bool eq = equiv(save_reg_slices.at(use->save), reg_slices);

                BUG_CHECK(eq, "select has different allocations based on the use context: %1%",
                          use->print());

                // XXX(zma) This check is really an aritificial constraint; We can
                // of course give different allocations based on the context (use state).
                // The thing is I'm not really sure how the subsequent Modifier can
                // perform a context based revisit on the IR::BFN::Select node.
            } else {
                save_reg_slices[use->save] = reg_slices;
            }
        }
    }

    void bind_alloc(const IR::BFN::Parser* parser, const UseGroup* group,
                    std::map<const UseGroup*, std::vector<MatchRegister>>& group_to_alloc_regs,
                    const std::vector<MatchRegister>& alloc_regs) {
        group_to_alloc_regs[group] = alloc_regs;
        save_result(parser, group, alloc_regs);

        if (LOGGING(1)) {
            std::clog << "allocated { ";
            for (auto& reg : alloc_regs) std::clog << "$" << reg.name << " ";
            std::clog << "} to " << group->print() << std::endl;
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

                bind_alloc(parser, group, group_to_alloc_regs, alloc_regs);  // success

                // propagate alloc to all groups that have shared def
                for (auto other : coalesced_groups) {
                    if (!group_to_alloc_regs.count(other)) {
                        if (group->have_subset_defs(other) || other->have_subset_defs(group)) {
                            LOG3("group " << other->print() << " can share registers with "
                                          << group->print());

                            bind_alloc(parser, other, group_to_alloc_regs, alloc_regs);
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

    void postorder(IR::BFN::SavedRVal* save) override {
        auto* orig = getOriginal<IR::BFN::SavedRVal>();
        if (rst.save_reg_slices.count(orig)) {
            save->reg_slices = rst.save_reg_slices.at(orig);
        } else {
            auto select = findContext<IR::BFN::Select>();
            BUG("Parser match register not allocated for %1%", select->p4Source);
        }
    }

    const MatcherAllocator& rst;
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
        } else if (auto cntr = select->source->to<IR::BFN::ParserCounterRVal>()) {
            BUG_CHECK(!values[cntr->declName], "value aleady exists for %1%", cntr->declName);
            values[cntr->declName] = val;
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
            } else if (auto cntr = select->source->to<IR::BFN::ParserCounterRVal>()) {
                sources.push_back(cntr->declName);
                values[cntr->declName] = match_t();
                sizes[cntr->declName] = 1;
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
            cstring field_name = stripThreadPrefix(select->p4Source->toString());
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

// After match register allocation, if the start state is empty and its
// transition to the next state contains no writes to the match register,
// we can safely remove this empty state.
struct RemoveEmptyStartState : public ParserTransform {
    const IR::BFN::ParserState*
    is_empty(const IR::BFN::ParserState* state) {
        if (!state->statements.empty())
            return nullptr;

        if (!state->selects.empty())
            return nullptr;

        if (state->transitions.size() != 1)
            return nullptr;

        auto t = state->transitions[0];

        if (!t->saves.empty())
            return nullptr;

        if (t->shift && *t->shift == 0)
            return t->next;

        return nullptr;
    }

    IR::BFN::Parser* preorder(IR::BFN::Parser* parser) {
        if (parser->start) {
            if (auto next = is_empty(parser->start)) {
                parser->start = next;
                LOG4("removed empty parser start state on " << parser->gress);
            }
        }

        return parser;
    }
};

AllocateParserMatchRegisters::AllocateParserMatchRegisters(const PhvInfo& phv) {
    auto* parserInfo = new CollectParserInfo;
    auto* collectUseDef = new CollectParserUseDef(phv, *parserInfo);
    auto* allocator = new MatcherAllocator(*parserInfo, collectUseDef->parser_use_def);

    addPasses({
        LOGGING(4) ? new DumpParser("before_parser_match_alloc") : nullptr,
        new ResolveOutOfBufferSaves,
        LOGGING(4) ? new DumpParser("after_resolve_oob_saves") : nullptr,
        parserInfo,
        collectUseDef,
        allocator,
        new InsertSaveAndSelect(*allocator),
        new AdjustMatchValue,
        new RemoveEmptyStartState,
        LOGGING(4) ? new DumpParser("after_parser_match_alloc") : nullptr
    });
}
