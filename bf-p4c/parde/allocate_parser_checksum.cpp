#include <map>

#include "allocate_parser_checksum.h"

#include "lib/cstring.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/parde/dump_parser.h"
#include "device.h"

// Eliminate adds that do not have a terminal verify()
// Eliminate subtracts that do not have a terminal get()
class ComputeDeadParserChecksums : public ParserInspector {
 public:
    std::set<const IR::BFN::ParserPrimitive*> to_elim;

    ComputeDeadParserChecksums(const CollectParserInfo& parser_info,
        const CollectParserChecksums& checksum_info) :
            parser_info(parser_info), checksum_info(checksum_info) { }

 private:
    bool preorder(const IR::BFN::ParserState* state) override {
        auto parser = findContext<IR::BFN::Parser>();

        auto descendants = parser_info.graph(parser).get_all_descendants(state);
        state_to_descendants[state] = descendants;

        return true;
    }

    // Does cp have its terminal primitive in this state?
    // For ChecksumAdd, the terminal type is ChecksumVerify.
    // For ChecksumSub, the terminal type is ChecksumGet.
    bool has_terminal(const IR::BFN::ParserState* state, cstring decl,
                      const IR::BFN::ParserChecksumPrimitive* cp,
                      bool aftercp = false) {
        bool skipped = !aftercp;

        if (!checksum_info.state_to_prims.count(state))
            return false;

        for (auto p : checksum_info.state_to_prims.at(state)) {
            if (p->declName != decl)
                continue;

            if (p == cp)
                skipped = true;

            if (!skipped)
                continue;

            if (cp->is<IR::BFN::ChecksumAdd>() && p->is<IR::BFN::ChecksumVerify>())
                return true;

            if (cp->is<IR::BFN::ChecksumSubtract>() && p->is<IR::BFN::ChecksumGet>())
                return true;
        }
        return false;
    }

    bool is_dead(cstring decl, const IR::BFN::ParserChecksumPrimitive* p) {
        if (p->is<IR::BFN::ChecksumGet>() || p->is<IR::BFN::ChecksumVerify>())
            return false;

        // Look for terminal primitive of p in its state and all descendant states.
        // p is dead if no terminal is found.

        auto state = checksum_info.prim_to_state.at(p);

        if (has_terminal(state, decl, p, true))
            return false;

        auto descendants = state_to_descendants.at(state);

        for (auto desc : descendants)
            if (has_terminal(desc, decl, p))
                return false;

        return true;
    }

    void end_apply() override {
        for (auto kv : checksum_info.decl_name_to_prims) {
            for (auto dp : kv.second) {
                for (auto csum : dp.second) {
                    if (is_dead(dp.first, csum)) {
                        to_elim.insert(csum);

                        LOG3("eliminate dead parser checksum primitive "
                             << csum << " in " << csum->declName);
                    }
                }
            }
        }
    }

    std::map<const IR::BFN::ParserState*,
        std::set<const IR::BFN::ParserState*>> state_to_descendants;

    const CollectParserInfo& parser_info;
    const CollectParserChecksums& checksum_info;
};

class ElimDeadParserChecksums : public ParserModifier {
    const std::set<const IR::BFN::ParserPrimitive*>& to_elim;

 public:
    ElimDeadParserChecksums(
        const std::set<const IR::BFN::ParserPrimitive*>& to_elim) :
           to_elim(to_elim) { }

    bool preorder(IR::BFN::ParserState* state) override {
        IR::Vector<IR::BFN::ParserPrimitive> newStatements;

        for (auto csum : state->statements)
            if (!to_elim.count(csum))
                newStatements.push_back(csum);

        state->statements = newStatements;
        return true;
    }
};

struct ParserChecksumAllocator : public Visitor {
    ParserChecksumAllocator(AllocateParserChecksums& s,
             const CollectParserInfo& pi,
             const CollectParserChecksums& ci) :
        self(s), parser_info(pi), checksum_info(ci) { }

    AllocateParserChecksums& self;
    const CollectParserInfo& parser_info;
    const CollectParserChecksums& checksum_info;

    const IR::Node *apply_visitor(const IR::Node *n, const char *) override {
        for (auto& kv : checksum_info.parser_to_decl_names)
            allocate(kv.first);

        return n;
    }

    #define COMPARE_SRC(a, b, T) { \
        auto at = a->to<T>();      \
        auto bt = b->to<T>();      \
        if (at && bt)              \
            return at->source->range == bt->source->range; }

    #define COMPARE_DST(a, b, T) { \
        auto at = a->to<T>();      \
        auto bt = b->to<T>();      \
        if (at && bt)              \
            return at->dest->field == bt->dest->field; }

    #define OF_TYPE(a, b, T) (a->is<T>() && b->is<T>())

    // XXX(zma) boilerplates due to IR's lack of support of "deep" comparision

    bool is_equiv_src(const IR::BFN::ParserChecksumPrimitive* a,
                      const IR::BFN::ParserChecksumPrimitive* b) {
        COMPARE_SRC(a, b, IR::BFN::ChecksumAdd);
        COMPARE_SRC(a, b, IR::BFN::ChecksumSubtract);
        return false;
    }

    bool is_equiv_dest(const IR::BFN::ParserChecksumPrimitive* a,
                       const IR::BFN::ParserChecksumPrimitive* b) {
        COMPARE_DST(a, b, IR::BFN::ChecksumGet);
        COMPARE_DST(a, b, IR::BFN::ChecksumVerify);
        return false;
    }

    bool is_equiv(const IR::BFN::ParserState* state, cstring declA, cstring declB) {
        std::vector<const IR::BFN::ParserChecksumPrimitive*> primsA, primsB;

        for (auto prim : checksum_info.state_to_prims.at(state)) {
            if (prim->declName == declA)
                primsA.push_back(prim);
            else if (prim->declName == declB)
                primsB.push_back(prim);
        }

        if (primsA.size() != primsB.size())
            return false;

        int size = primsA.size();

        for (int i = 0; i < size; i++) {
            auto a = primsA[i];
            auto b = primsB[i];

            if (OF_TYPE(a, b, IR::BFN::ChecksumGet) ||
                OF_TYPE(a, b, IR::BFN::ChecksumVerify)) {
                if (!is_equiv_dest(a, b))
                    return false;
            } else if (OF_TYPE(a, b, IR::BFN::ChecksumAdd) ||
                     OF_TYPE(a, b, IR::BFN::ChecksumSubtract)) {
                if (!is_equiv_src(a, b))
                    return false;
            } else {
                return false;
            }
        }

        return true;
    }

    #undef COMPARE_SRC
    #undef COMPARE_DST
    #undef OF_TYPE

    std::string
    print_calc_states(const IR::BFN::Parser* parser, cstring declName) {
        std::stringstream ss;

        auto& calc_states = checksum_info.decl_name_to_states.at(parser).at(declName);
        auto type = checksum_info.get_type(parser, declName);

        ss << declName << ": (" << type << ")" << std::endl;
        for (auto s : calc_states)
            ss << "  " << s->name << std::endl;

        return ss.str();
    }

    /// Is any state in "calc_states_" an ancestor of "dst"?
    bool has_ancestor(const IR::BFN::Parser* parser,
                      const ordered_set<const IR::BFN::ParserState*>& calc_states,
                      const IR::BFN::ParserState* dst) {
        for (auto s : calc_states)
            if (parser_info.graph(parser).is_ancestor(s, dst))
                return true;
        return false;
    }

    bool can_share_hw_unit(const IR::BFN::Parser* parser, cstring declA, cstring declB) {
        // Two residual checksum calculations can share HW unit if
        //   1) no start state is ancestor of the other's start state
        //   2) overlapping states must have identical calculation

        // Two verification/CLOT checksum calculations can share HW unit if
        // their calculation states don't overlap

        auto& calc_states_A = checksum_info.decl_name_to_states.at(parser).at(declA);
        auto& calc_states_B = checksum_info.decl_name_to_states.at(parser).at(declB);

        if (is_residual(parser, declA) || is_residual(parser, declB)) {
            auto startA = get_start_states(parser, declA);
            auto startB = get_start_states(parser, declB);

            for (auto a : calc_states_A) {
                for (auto b : calc_states_B) {
                    if (a == b) {
                        if (is_residual(parser, declA) && is_residual(parser, declB)) {
                            if (!is_equiv(a, declA, declB)) {
                                return false;
                            }
                        } else {
                            return false;
                        }
                    }
                }
            }

            if (is_residual(parser, declA)) {
                for (auto a : startA)
                    for (auto b : startB)
                        if (parser_info.graph(parser).is_ancestor(a, b))
                            return false;
            }

            if (is_residual(parser, declB)) {
                for (auto b : startB)
                    for (auto a : startA)
                        if (parser_info.graph(parser).is_ancestor(b, a))
                            return false;
            }
        } else {
            for (auto a : calc_states_A) {
                for (auto b : calc_states_B) {
                    if (a == b) {
                        return false;
                    }
                }
            }
        }

        return true;
    }

    std::vector<ordered_set<cstring>>
    compute_disjoint_sets(const IR::BFN::Parser* parser) {
        std::vector<ordered_set<cstring>> disjoint_sets;

        if (checksum_info.parser_to_residuals.count(parser)) {
            compute_disjoint_sets(parser,
                                  checksum_info.parser_to_residuals.at(parser),
                                  disjoint_sets);
        }

        if (checksum_info.parser_to_verifies.count(parser)) {
            compute_disjoint_sets(parser,
                                  checksum_info.parser_to_verifies.at(parser),
                                  disjoint_sets);
        }

        if (checksum_info.parser_to_clots.count(parser)) {
            compute_disjoint_sets(parser,
                                  checksum_info.parser_to_clots.at(parser),
                                  disjoint_sets);
        }

        return disjoint_sets;
    }

    void compute_disjoint_sets(const IR::BFN::Parser* parser,
                               const std::set<cstring>& decls,
                               std::vector<ordered_set<cstring>>& disjoint_sets) {
        for (auto decl : decls) {
            bool found_union = false;

            for (auto& ds : disjoint_sets) {
                BUG_CHECK(!ds.empty(), "empty disjoint set?");

                cstring other = *(ds.begin());

                if (can_share_hw_unit(parser, decl, other)) {
                    ds.insert(decl);
                    found_union = true;

                    LOG3(decl << " can share with " << other);

                    break;
                } else {
                    LOG3(decl << " cannot share with " << other);
                }
            }

            if (!found_union) {
                ordered_set<cstring> newset;
                newset.insert(decl);
                disjoint_sets.push_back(newset);
            }
        }
    }

    bool is_verification(const IR::BFN::Parser* parser, cstring decl) {
        if (checksum_info.parser_to_verifies.count(parser)) {
            return checksum_info.parser_to_verifies.at(parser).count(decl);
        }
        return false;
    }

    bool is_residual(const IR::BFN::Parser* parser, cstring decl) {
        if (checksum_info.parser_to_residuals.count(parser)) {
             return checksum_info.parser_to_residuals.at(parser).count(decl);
        }
        return false;
    }

    bool is_clot(const IR::BFN::Parser* parser, cstring decl) {
        if (checksum_info.parser_to_clots.count(parser)) {
            return checksum_info.parser_to_clots.at(parser).count(decl);
        }
        return false;
    }

    /// Returns the checksum calculation start state for declaration. A calculation
    /// may have mutiple start states, e.g. branches that extract same header. A state
    /// is a start state is no other state is its ancestor.
    std::set<const IR::BFN::ParserState*>
    get_start_states(const IR::BFN::Parser* parser, cstring decl) {
        std::set<const IR::BFN::ParserState*> start_states;

        auto& calc_states = checksum_info.decl_name_to_states.at(parser).at(decl);

        for (auto a : calc_states) {
            bool is_start = true;
            for (auto b : calc_states) {
                if (parser_info.graph(parser).is_ancestor(b, a)) {
                    is_start = false;
                    break;
                }
            }
            if (is_start)
                start_states.insert(a);
        }

        return start_states;
    }

    /// Returns the checksum calculation end states for declaration. A calculation
    /// may have multiple end states, e.g. IPv4 with variable length options where
    /// each option length is its own parser state. A state is an end state is no
    /// other state is its descendant.
    std::set<const IR::BFN::ParserState*>
    get_end_states(const IR::BFN::Parser* parser, cstring decl) {
        std::set<const IR::BFN::ParserState*> end_states;

        auto& calc_states = checksum_info.decl_name_to_states.at(parser).at(decl);

        for (auto a : calc_states) {
            bool is_end = true;
            for (auto b : calc_states) {
                if (parser_info.graph(parser).is_ancestor(a, b)) {
                    is_end = false;
                    break;
                }
            }
            if (is_end)
                end_states.insert(a);
        }

        return end_states;
    }

    bool contains_clot_checksum(const IR::BFN::Parser* parser,
                                const ordered_set<cstring>& decls) {
        for (auto decl : decls) {
            if (is_clot(parser, decl))
                return true;
        }

        return false;
    }

    void bind(const IR::BFN::Parser* parser, cstring csum, unsigned id) {
        self.decl_to_checksum_id[parser][csum] = id;
        self.decl_to_start_states[parser][csum] = get_start_states(parser, csum);
        self.decl_to_end_states[parser][csum] = get_end_states(parser, csum);

        LOG1("allocated parser checksum unit " << id << " to " << csum);
    }

    void fail(gress_t gress) {
        std::stringstream msg;

        unsigned avail = 0;

        if (Device::currentDevice() == Device::TOFINO) avail = 2;
        else if (Device::currentDevice() == Device::JBAY) avail = 5;

        msg << "Ran out of checksum units on " << ::toString(gress) << " parser ("
            << avail << " available).";

        if (Device::currentDevice() == Device::JBAY)
            msg << " CLOT checksums can only use unit 2-4.";

        ::fatal_error("%1%", msg.str());
    }

    void allocate(const IR::BFN::Parser* parser) {
        LOG1("need to allocate " << checksum_info.parser_to_decl_names.at(parser).size()
             << " logical checksum calculations to " << ::toString(parser->gress)
             << " parser");

        if (LOGGING(2)) {
            for (auto decl : checksum_info.parser_to_decl_names.at(parser))
                LOG2(print_calc_states(parser, decl));
        }

        // Tofino: 2 checksum units available per parser
        // Modes: Verification/Residual

        // JBay: 5 checksum units available per parser
        // Modes: Verification/Residual/CLOT
        // CLOT checksum can only use units 2-4

        // Residual checksum once used need to reserved to end of parsing
        // Verification/CLOT checksum can be reused when done

        // each disjoint set can be assigned to a HW unit
        auto disjoint_sets = compute_disjoint_sets(parser);

        LOG3("disjoint parser checksum sets: " << disjoint_sets.size());

        // now bind each set to a checksum unit

        if (Device::currentDevice() == Device::TOFINO) {
            unsigned id = 0;

            for (auto& ds : disjoint_sets) {
                if (id == 2) fail(parser->gress);
                for (auto s : ds) bind(parser, s, id);
                id++;
            }
        } else if (Device::currentDevice() == Device::JBAY) {
            std::set<unsigned> clots;

            unsigned id = 2;  // allocate clot checksums first
            for (auto& ds : disjoint_sets) {
                if (id == 5) fail(parser->gress);

                if (contains_clot_checksum(parser, ds)) {
                    for (auto s : ds) bind(parser, s, id);
                    clots.insert(id);
                    id++;
                }
            }

            id = 0;  // now allocate the rest
            for (auto& ds : disjoint_sets) {
                if (!contains_clot_checksum(parser, ds)) {
                    while (clots.count(id)) id++;
                    if (id == 5) fail(parser->gress);
                    for (auto s : ds) bind(parser, s, id);
                    id++;
                }
            }

        } else {
            BUG("Unknown device");
        }
    }
};

/// For CLOTs that contribute to checksum update at the deparser,
/// we need to compute the CLOT's portion of checksum in the parser
/// when we issue the CLOTs. So after CLOT allocation, we know which
/// fields are allocated to CLOTs, and of those fields, which contribute
/// to the checksum update. We then insert the checksum calculation
/// primitives for these fields into the parser state where they are
/// extracted.
struct InsertParserClotChecksums : public PassManager {
    struct CollectClotChecksumFields : DeparserInspector {
        CollectClotChecksumFields(const PhvInfo& phv, const ClotInfo& clotInfo) :
            phv(phv), clotInfo(clotInfo) {}

        bool preorder(const IR::BFN::Deparser* deparser) override {
            // look for clot fields in deparser checksums

            for (auto emit : deparser->emits) {
                if (auto csum = emit->to<IR::BFN::EmitChecksum>()) {
                   int idx = 0;
                    for (auto source : csum->sources) {
                        auto field = phv.field(source->field);
                        if (auto* clot = clotInfo.fully_allocated(field)) {
                            checksum_field_to_clot[field] = clot;
                            checksum_field_to_offset[field] =
                                      csum->source_index_to_offset.at(idx);
                        }
                       idx++;
                    }
                }
            }

            return false;
        }
        std::map<const PHV::Field*, const Clot*> checksum_field_to_clot;
        // Maps checksum field used in CLOT to their offset in deparser checksum fieldlist
        std::map<const PHV::Field*, int> checksum_field_to_offset;
        const PhvInfo& phv;
        const ClotInfo& clotInfo;
    };

    struct CreateParserPrimitives : ParserInspector {
        const PhvInfo& phv;
        const ClotInfo& clotInfo;
        const CollectClotChecksumFields& clot_checksum_fields;
        std::map<const IR::BFN::ParserState*,
                 std::map<const Clot*,
                          std::vector<const IR::BFN::ParserChecksumPrimitive*>>>
                                 state_to_clot_primitives;

        std::map<const Clot*, ordered_set<const IR::BFN::ParserState*>> clot_to_states;

        CreateParserPrimitives(const PhvInfo& phv, const ClotInfo& clotInfo,
                               const CollectClotChecksumFields& clot_checksum_fields) :
            phv(phv), clotInfo(clotInfo),
            clot_checksum_fields(clot_checksum_fields) { }

        IR::BFN::ChecksumAdd*
        create_checksum_add(const Clot* clot, const IR::BFN::PacketRVal* rval, bool swap) {
            cstring name = "$clot_" + cstring::to_cstring(clot->tag) + "_csum";
            auto add = new IR::BFN::ChecksumAdd(name, rval, swap, false);
            return add;
        }

        IR::BFN::ChecksumDepositToClot*
        create_checksum_deposit(const Clot* clot) {
            cstring name = "$clot_" + cstring::to_cstring(clot->tag) + "_csum";
            auto deposit = new IR::BFN::ChecksumDepositToClot(name);
            deposit->clot = clot;
            deposit->declName = name;
            return deposit;
        }

        bool preorder(const IR::BFN::ParserState* state) override {
            auto& checksum_field_to_clot = clot_checksum_fields.checksum_field_to_clot;
            auto& checksum_field_to_offset = clot_checksum_fields.checksum_field_to_offset;
            for (auto stmt : state->statements) {
                if (auto extract = stmt->to<IR::BFN::ExtractClot>()) {
                    auto dest = phv.field(extract->dest->field);

                    if (checksum_field_to_clot.count(dest)) {
                        auto clot = checksum_field_to_clot.at(dest);
                        bool swap = false;
                        auto rval = extract->source->to<IR::BFN::PacketRVal>();
                        // If a field is on an even byte in the checksum operation field list
                        // but on an odd byte in the input buffer and vice-versa then swap is true.
                        if ((checksum_field_to_offset.at(dest)/8) % 2 != rval->range.loByte() % 2) {
                            swap = true;
                        }
                        auto add = create_checksum_add(clot, rval, swap);

                        state_to_clot_primitives[state][clot].push_back(add);
                        clot_to_states[clot].insert(state);
                    }
                }
            }

            return true;
        }

        void end_apply() override {
            // insert terminal call at last state
            for (auto& cs : clot_to_states) {
                auto clot = cs.first;
                auto last = *(cs.second.rbegin());

                auto deposit = create_checksum_deposit(clot);
                state_to_clot_primitives[last][clot].push_back(deposit);
            }
        }
    };

    struct InsertParserPrimitives : ParserModifier {
        const CreateParserPrimitives& create_parser_prims;

        explicit InsertParserPrimitives(const CreateParserPrimitives& create_parser_prims)
            : create_parser_prims(create_parser_prims) { }

        bool preorder(IR::BFN::ParserState* state) override {
            auto orig = getOriginal<IR::BFN::ParserState>();

            if (create_parser_prims.state_to_clot_primitives.count(orig)) {
                for (auto& kv : create_parser_prims.state_to_clot_primitives.at(orig)) {
                    for (auto prim : kv.second) {
                        state->statements.push_back(prim);
                        LOG3("added " << prim << " to " << state->name);
                    }
                }
            }

            return true;
        }
    };

    InsertParserClotChecksums(const PhvInfo& phv, const ClotInfo& clot) {
        auto clot_checksum_fields = new CollectClotChecksumFields(phv, clot);
        auto create_checksum_prims = new CreateParserPrimitives(phv, clot, *clot_checksum_fields);
        auto insert_checksum_prims = new InsertParserPrimitives(*create_checksum_prims);

        addPasses({
            clot_checksum_fields,
            create_checksum_prims,
            insert_checksum_prims
        });
    }
};

AllocateParserChecksums::AllocateParserChecksums(const PhvInfo& phv, const ClotInfo& clot)
        : Logging::PassManager("parser", Logging::Mode::AUTO),
          checksum_info(parser_info) {
    auto collect_dead_checksums = new ComputeDeadParserChecksums(parser_info, checksum_info);
    auto elim_dead_checksums = new ElimDeadParserChecksums(collect_dead_checksums->to_elim);
    auto insert_clot_checksums = new InsertParserClotChecksums(phv, clot);
    auto allocator = new ParserChecksumAllocator(*this, parser_info, checksum_info);

    addPasses({
        LOGGING(4) ? new DumpParser("before_parser_csum_alloc") : nullptr,
        &parser_info,
        &checksum_info,
        collect_dead_checksums,
        elim_dead_checksums,
        Device::currentDevice() == Device::JBAY ? insert_clot_checksums : nullptr,
        LOGGING(5) ? new DumpParser("after_insert_clot_csum") : nullptr,
        &parser_info,
        &checksum_info,
        allocator,
        LOGGING(4) ? new DumpParser("after_parser_csum_alloc") : nullptr
    });
}
