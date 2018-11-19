#ifndef EXTENSIONS_BF_P4C_PARDE_ALLOCATE_PARSER_CHECKSUM_H_
#define EXTENSIONS_BF_P4C_PARDE_ALLOCATE_PARSER_CHECKSUM_H_

#include <map>

#include "ir/ir.h"
#include "lib/cstring.h"
#include "bf-p4c/parde/parde_utils.h"
#include "bf-p4c/parde/parser_info.h"
#include "bf-p4c/logging/pass_manager.h"
#include "parde_visitor.h"

class AllocateParserChecksumUnits : public Logging::PassManager {
    struct CollectParserChecksums : public ParserInspector {
        explicit CollectParserChecksums(const CollectParserInfo& parserInfo) :
            parserInfo(parserInfo) { }

        const CollectParserInfo& parserInfo;

        std::map<const IR::BFN::Parser*,
            ordered_set<cstring>> parser_to_decl_names;

        std::map<const IR::BFN::Parser*,
            std::set<cstring>> parser_to_verifies;

        std::map<const IR::BFN::Parser*,
            std::set<cstring>> parser_to_residuals;

        std::map<const IR::BFN::Parser*,
            std::map<cstring,
                std::vector<const IR::BFN::ParserChecksumPrimitive*>>> decl_name_to_prims;

        std::map<const IR::BFN::Parser*,
            std::map<cstring,
                ordered_set<const IR::BFN::ParserState*>>> decl_name_to_states;

        std::map<const IR::BFN::ParserState*,
            std::vector<const IR::BFN::ParserChecksumPrimitive*>> state_to_prims;

        std::map<const IR::BFN::ParserChecksumPrimitive*,
                 const IR::BFN::ParserState*> prim_to_state;

        profile_t init_apply(const IR::Node* root) override {
            parser_to_decl_names.clear();
            parser_to_verifies.clear();
            parser_to_residuals.clear();
            decl_name_to_prims.clear();
            decl_name_to_states.clear();
            state_to_prims.clear();
            prim_to_state.clear();
            return Inspector::init_apply(root);
        }

        bool preorder(const IR::BFN::Parser* parser) override {
            auto sorted_states = parserInfo.graph(parser).topological_sort();

            for (auto state : sorted_states)
                for (auto stmt : state->statements)
                    if (auto csum = stmt->to<IR::BFN::ParserChecksumPrimitive>())
                        visit(parser, state, csum);

            return false;
        }

        void visit(const IR::BFN::Parser* parser,
                   const IR::BFN::ParserState* state,
                   const IR::BFN::ParserChecksumPrimitive* csum) {
            parser_to_decl_names[parser].insert(csum->declName);
            prim_to_state[csum] = state;
            state_to_prims[state].push_back(csum);
            decl_name_to_states[parser][csum->declName].insert(state);
            decl_name_to_prims[parser][csum->declName].push_back(csum);
        }

        bool is_verification(const IR::BFN::Parser* parser, cstring decl) {
            for (auto p : decl_name_to_prims.at(parser).at(decl)) {
                if (!p->is<IR::BFN::ChecksumAdd>() && !p->is<IR::BFN::ChecksumVerify>())
                    return false;
            }
            return true;
        }

        bool is_residual(const IR::BFN::Parser* parser, cstring decl) {
            for (auto p : decl_name_to_prims.at(parser).at(decl)) {
                if (!p->is<IR::BFN::ChecksumSubtract>() && !p->is<IR::BFN::ChecksumGet>())
                    return false;
            }
            return true;
        }

        void end_apply() override {
            for (auto& pd : parser_to_decl_names) {
                for (auto decl : pd.second) {
                    if (is_verification(pd.first, decl))
                        parser_to_verifies[pd.first].insert(decl);
                    else if (is_residual(pd.first, decl))
                        parser_to_residuals[pd.first].insert(decl);
                    else
                        ::error("Inconsistent use of checksum declaration %1%", decl);
                }
            }
        }
    };

    // Eliminate adds that do not have a terminal verify()
    // Eliminate subtracts that do not have a terminal get()
    class ComputeDeadParserChecksums : public ParserInspector {
     public:
        std::set<const IR::BFN::ParserPrimitive*> toElim;

        ComputeDeadParserChecksums(const CollectParserInfo& parserInfo,
            const CollectParserChecksums& checksumInfo) :
                parserInfo(parserInfo), checksumInfo(checksumInfo) { }

     private:
        bool preorder(const IR::BFN::ParserState* state) override {
            auto parser = findContext<IR::BFN::Parser>();

            auto descendants = parserInfo.graph(parser).get_all_descendants(state);
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

            if (!checksumInfo.state_to_prims.count(state))
                return false;

            for (auto p : checksumInfo.state_to_prims.at(state)) {
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

            auto state = checksumInfo.prim_to_state.at(p);

            if (has_terminal(state, decl, p, true))
                return false;

            auto descendants = state_to_descendants.at(state);

            for (auto desc : descendants)
                if (has_terminal(desc, decl, p))
                    return false;

            return true;
        }

        void end_apply() override {
            for (auto kv : checksumInfo.decl_name_to_prims) {
                for (auto dp : kv.second) {
                    for (auto csum : dp.second) {
                        if (is_dead(dp.first, csum)) {
                            toElim.insert(csum);

                            LOG4("eliminate dead parser checksum primitive "
                                 << csum << " in " << csum->declName);
                        }
                    }
                }
            }
        }

        std::map<const IR::BFN::ParserState*,
            std::set<const IR::BFN::ParserState*>> state_to_descendants;

        const CollectParserInfo& parserInfo;
        const CollectParserChecksums& checksumInfo;
    };


    class ElimDeadParserChecksums : public ParserModifier {
        const std::set<const IR::BFN::ParserPrimitive*>& toElim;

     public:
        ElimDeadParserChecksums(
            const std::set<const IR::BFN::ParserPrimitive*>& toElim) :
               toElim(toElim) { }

        bool preorder(IR::BFN::ParserState* state) override {
            IR::Vector<IR::BFN::ParserPrimitive> newStatements;

            for (auto csum : state->statements)
                if (!toElim.count(csum))
                    newStatements.push_back(csum);

            state->statements = newStatements;
            return true;
        }
    };

    struct Allocate : public Visitor {
        Allocate(AllocateParserChecksumUnits& self,
                 const CollectParserInfo& parserInfo,
                 const CollectParserChecksums& checksumInfo) :
            self(self), parserInfo(parserInfo), checksumInfo(checksumInfo) { }

        unsigned current_unit_id = 0;

        const IR::Node *apply_visitor(const IR::Node *n, const char *) override {
            for (auto& kv : checksumInfo.parser_to_decl_names)
                allocate(kv.first);

            return n;
        }

        #define COMPARE_SRC(a, b, T) { \
            auto at = a->to<T>();      \
            auto bt = b->to<T>();      \
            if (at && bt)              \
                return at->source->range() == bt->source->range(); }

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

            for (auto prim : checksumInfo.state_to_prims.at(state)) {
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

        void print_calc_states(const IR::BFN::Parser* parser, cstring declName) {
            auto& calc_states = checksumInfo.decl_name_to_states.at(parser).at(declName);

            cstring type = is_verification(parser, declName) ? "verify" : "residual";
            std::cout << declName << ": (" << type << ")" << std::endl;
            for (auto s : calc_states)
                std::cout << "  " << s->name << std::endl;
        }

        /// Is any state in "calc_states_" an ancestor of "dst"?
        bool has_ancestor(const IR::BFN::Parser* parser,
                          const ordered_set<const IR::BFN::ParserState*>& calc_states,
                          const IR::BFN::ParserState* dst) {
            for (auto s : calc_states)
                if (parserInfo.graph(parser).is_ancestor(s, dst))
                    return true;
            return false;
        }

        bool can_share_hw_unit(const IR::BFN::Parser* parser, cstring declA, cstring declB) {
            // Two residual checksum calculations can share HW unit if
            // 1) no start state is ancestor of the other's start state
            // 2) overlapping states must have identical calculation

            // Two verification checksum calculations can share HW unit if
            // their calculation states don't overlap

            auto& calc_states_A = checksumInfo.decl_name_to_states.at(parser).at(declA);
            auto& calc_states_B = checksumInfo.decl_name_to_states.at(parser).at(declB);

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
                            if (parserInfo.graph(parser).is_ancestor(a, b))
                                return false;
                }

                if (is_residual(parser, declB)) {
                    for (auto b : startB)
                        for (auto a : startA)
                            if (parserInfo.graph(parser).is_ancestor(b, a))
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

            if (checksumInfo.parser_to_residuals.count(parser)) {
                compute_disjoint_sets(parser,
                                      checksumInfo.parser_to_residuals.at(parser),
                                      disjoint_sets);
            }

            if (checksumInfo.parser_to_verifies.count(parser)) {
                compute_disjoint_sets(parser,
                                      checksumInfo.parser_to_verifies.at(parser),
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

                        LOG4(decl << " can share with " << other);

                        break;
                    } else {
                        LOG4(decl << " cannot share with " << other);
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
            if (checksumInfo.parser_to_verifies.count(parser)) {
                return checksumInfo.parser_to_verifies.at(parser).count(decl);
            }
            return false;
        }

        bool is_residual(const IR::BFN::Parser* parser, cstring decl) {
            if (checksumInfo.parser_to_residuals.count(parser)) {
                 return checksumInfo.parser_to_residuals.at(parser).count(decl);
            }
            return false;
        }

        /// Returns the checksum calculation start state for declaration. A calculation
        /// may have mutiple start states, e.g. branches that extract same header. A state
        /// is a start state is no other state is its ancestor.
        std::set<const IR::BFN::ParserState*>
        get_start_states(const IR::BFN::Parser* parser, cstring decl) {
            std::set<const IR::BFN::ParserState*> start_states;

            auto& calc_states = checksumInfo.decl_name_to_states.at(parser).at(decl);

            for (auto a : calc_states) {
                bool is_start = true;
                for (auto b : calc_states) {
                    if (parserInfo.graph(parser).is_ancestor(b, a)) {
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

            auto& calc_states = checksumInfo.decl_name_to_states.at(parser).at(decl);

            for (auto a : calc_states) {
                bool is_end = true;
                for (auto b : calc_states) {
                    if (parserInfo.graph(parser).is_ancestor(a, b)) {
                        is_end = false;
                        break;
                    }
                }
                if (is_end)
                    end_states.insert(a);
            }

            return end_states;
        }

        void allocate(const IR::BFN::Parser* parser) {
            LOG4("need to allocate " << checksumInfo.parser_to_decl_names.at(parser).size()
                 << " logical checksum calculations to " << ::toString(parser->gress)
                 << " parser");

            if (LOGGING(4)) {
                for (auto decl : checksumInfo.parser_to_decl_names.at(parser))
                    print_calc_states(parser, decl);
            }

            // Tofino: 2 checksum units available per parser
            // Modes: Verification/Residual

            // JBay: 5 checksum units available per parser
            // Modes: Verification/Residual/CLOT
            // Units 0-1 can only used for Verification/Residual
            // Units 2-4 can be used for all modes

            // Residual checksum once used need to reserved to end of parsing
            // Verification/CLOT checksum can be reused when done

            // each disjoint set can be assigned to a HW unit
            auto disjointSets = compute_disjoint_sets(parser);

            LOG4("disjoint parser checksum sets: " << disjointSets.size());

            // now save allocation results
            save_allocation(parser, disjointSets);
        }

        void save_allocation(const IR::BFN::Parser* parser,
                             const std::vector<ordered_set<cstring>>& disjoint_sets) {
            unsigned curr_id = 0;

            for (auto& ds : disjoint_sets) {
                for (auto s : ds) {
                    self.declToChecksumId[parser][s] = curr_id;
                    self.declToStartStates[parser][s] = get_start_states(parser, s);
                    self.declToEndStates[parser][s] = get_end_states(parser, s);

                    LOG4("allocated parser checksum unit " << curr_id << " to " << s);
                }

                curr_id++;
            }
        }

        AllocateParserChecksumUnits&  self;
        const CollectParserInfo&      parserInfo;
        const CollectParserChecksums& checksumInfo;
    };

    CollectParserInfo                              parserInfo;
    CollectParserChecksums                         checksumInfo;
    ComputeDeadParserChecksums                     computeDeadParserChecksums;

 public:
    std::map<const IR::BFN::Parser*,
        std::map<cstring, unsigned>>                              declToChecksumId;

    std::map<const IR::BFN::Parser*,
        std::map<cstring, std::set<const IR::BFN::ParserState*>>> declToStartStates;

    std::map<const IR::BFN::Parser*,
        std::map<cstring, std::set<const IR::BFN::ParserState*>>> declToEndStates;

    AllocateParserChecksumUnits() :
        Logging::PassManager("parser", true),
        checksumInfo(parserInfo),
        computeDeadParserChecksums(parserInfo, checksumInfo) {
        addPasses({
            LOGGING(3) ? new DumpParser("before_parser_csum_alloc") : nullptr,
            &parserInfo,
            &checksumInfo,
            &computeDeadParserChecksums,
            new ElimDeadParserChecksums(computeDeadParserChecksums.toElim),
            &parserInfo,
            &checksumInfo,
            new Allocate(*this, parserInfo, checksumInfo)
        });
    }
};


#endif  /* EXTENSIONS_BF_P4C_PARDE_ALLOCATE_PARSER_CHECKSUM_H_ */
