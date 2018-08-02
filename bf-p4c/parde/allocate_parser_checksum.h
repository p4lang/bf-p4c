#ifndef EXTENSIONS_BF_P4C_PARDE_ALLOCATE_PARSER_CHECKSUM_H_
#define EXTENSIONS_BF_P4C_PARDE_ALLOCATE_PARSER_CHECKSUM_H_

class AllocateParserChecksumUnits : public PassManager {
    struct CollectParserChecksums : public ParserInspector {
        explicit CollectParserChecksums(const CollectParserInfo& parserInfo) :
            parserInfo(parserInfo) { }

        const CollectParserInfo& parserInfo;

        std::map<const IR::BFN::Parser*, std::set<cstring>> parser_to_decl_names;

        std::map<cstring,
            std::vector<const IR::BFN::ParserChecksumPrimitive*>> decl_name_to_prims;

        std::map<cstring, ordered_set<const IR::BFN::ParserState*>> decl_name_to_states;

        std::map<const IR::BFN::ParserState*, std::set<cstring>> state_to_decl_names;

        std::map<const IR::BFN::ParserState*,
            std::vector<const IR::BFN::ParserChecksumPrimitive*>> state_to_prims;

        std::map<const IR::BFN::ParserChecksumPrimitive*,
                 const IR::BFN::ParserState*> prim_to_state;

        profile_t init_apply(const IR::Node* root) override {
            parser_to_decl_names.clear();
            decl_name_to_prims.clear();
            decl_name_to_states.clear();
            state_to_decl_names.clear();
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
            state_to_decl_names[state].insert(csum->declName);
            decl_name_to_states[csum->declName].insert(state);
            decl_name_to_prims[csum->declName].push_back(csum);
        }
    };

    // Eliminate ChecksumAdd's that do not have a following ChecksumVerify
    // Eliminate ChecksumSubtract's that do not have a following ChecksumGet
    class ComputeDeadParserChecksums : public ParserInspector {
     public:
        std::set<const IR::BFN::ParserPrimitive*> toElim;

        ComputeDeadParserChecksums(const CollectParserInfo& parserInfo,
            const CollectParserChecksums& checksumInfo) :
                parserInfo(parserInfo), checksumInfo(checksumInfo) { }

     private:
        void compute_dead_checksum_primitives(
            const std::vector<const IR::BFN::ParserChecksumPrimitive*>& sorted_csums) {
            for (auto rit = sorted_csums.rbegin(); rit != sorted_csums.rend(); rit++) {
                auto csum = *rit;
                if (csum->is<IR::BFN::ChecksumGet>() || csum->is<IR::BFN::ChecksumVerify>())
                    break;

                toElim.insert(csum);
            }
        }

        void compute_dead_checksum_primitives(cstring declName,
            const std::vector<const IR::BFN::ParserChecksumPrimitive*>& sorted_csums) {
            std::vector<const IR::BFN::ParserChecksumPrimitive*> verify, residual;

            for (auto csum : sorted_csums)
                if (csum->is<IR::BFN::ChecksumAdd>() || csum->is<IR::BFN::ChecksumVerify>())
                    verify.push_back(csum);
                else if (csum->is<IR::BFN::ChecksumSubtract>() || csum->is<IR::BFN::ChecksumGet>())
                    residual.push_back(csum);

            if (!verify.empty() && !residual.empty())
                BUG("%1% is used for both residual and verification?", declName);

            compute_dead_checksum_primitives(verify);

            compute_dead_checksum_primitives(residual);
        }

        bool preorder(const IR::BFN::Parser* parser) override {
            auto sorted_states = parserInfo.graph(parser).topological_sort();

            std::map<cstring, std::vector<const IR::BFN::ParserChecksumPrimitive*>> sorted_csums;

            for (auto state : sorted_states) {
                std::vector<const IR::BFN::ParserChecksumPrimitive*> checksums;

                for (auto stmt : state->statements)
                    if (auto csum = stmt->to<IR::BFN::ParserChecksumPrimitive>())
                        checksums.push_back(csum);

                for (auto csum : checksums)
                    sorted_csums[csum->declName].push_back(csum);
            }

            for (auto& kv : sorted_csums)
                compute_dead_checksum_primitives(kv.first, kv.second);

            return false;
        }

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
                allocate(kv.first, kv.second);

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

        static void print_state_path(cstring declName,
                                     const ordered_set<const IR::BFN::ParserState*>& path) {
            std::cout << "path " << declName << " : ";
            for (auto s : path)
                std::cout << s->name << " ";
            std::cout << std::endl;
        }

        /// Is any state in "path" an ancestor of "dst"?
        bool has_ancestor(const IR::BFN::Parser* parser,
                          const ordered_set<const IR::BFN::ParserState*>& path,
                          const IR::BFN::ParserState* dst) {
            for (auto s : path)
                if (parserInfo.graph(parser).is_ancestor(s, dst))
                    return true;
            return false;
        }

        bool can_share_hw_unit(const IR::BFN::Parser* parser, cstring declA, cstring declB) {
            // Two residual checksum decls can share HW unit if
            // 1) no start state is ancestor of the other's start state
            // 2) overlapping states must have identical calculation

            // Two verification checksum decls can share HW unit if
            // their paths don't overlap

            auto& pathA = checksumInfo.decl_name_to_states.at(declA);
            auto& pathB = checksumInfo.decl_name_to_states.at(declB);

            if (LOGGING(4)) {
                print_state_path(declA, pathA);
                print_state_path(declB, pathB);
            }

            if (is_residual(declA) && is_residual(declB)) {
                auto startA = *pathA.begin();
                auto startB = *pathB.begin();

                for (auto a : pathA)
                    for (auto b : pathB)
                        if (a == b && !is_equiv(a, declA, declB))
                            return false;

                if (parserInfo.graph(parser).is_ancestor(startA, startB) ||
                    parserInfo.graph(parser).is_ancestor(startB, startA)) {
                    return false;
                }
            } else {
                for (auto a : pathA)
                    for (auto b : pathB)
                        if (a == b)
                            return false;
            }

            return true;
        }

        std::set<std::set<cstring>>
        compute_disjoint_sets(const IR::BFN::Parser* parser, const std::set<cstring>& decls) {
            std::set<std::set<cstring>> disjoint_sets;

            for (auto decl : decls) {
                bool found_union = false;

                for (auto& const_ds : disjoint_sets) {
                    // std::set iterator only return const reference? since when?!
                    auto& ds = const_cast<std::set<cstring>&>(const_ds);

                    BUG_CHECK(!ds.empty(), "empty disjoint set?");

                    if (can_share_hw_unit(parser, decl, *ds.begin())) {
                        ds.insert(decl);
                        found_union = true;
                        break;
                    }
                }

                if (!found_union) {
                    std::set<cstring> newset;
                    newset.insert(decl);
                    disjoint_sets.insert(newset);
                }
            }

            return disjoint_sets;
        }

        bool is_verification(cstring decl) {
            auto last = checksumInfo.decl_name_to_prims.at(decl).back();
            return last->is<IR::BFN::ChecksumVerify>();
        }

        bool is_residual(cstring decl) {
            auto last = checksumInfo.decl_name_to_prims.at(decl).back();
            return last->is<IR::BFN::ChecksumGet>();
        }

        void allocate(const IR::BFN::Parser* parser, const std::set<cstring>& decls) {
            LOG4("need to allocate " << decls.size() << " logical checksums to "
                      << ::toString(parser->gress));

            // Tofino: 2 checksum units available per parser
            // Modes: Verification/Residual

            // JBay: 5 checksum units available per parser
            // Modes: Verification/Residual/CLOT
            // Units 0-1 can only used for Verification/Residual
            // Units 2-4 can be used for all modes

            // Residual checksum once used need to reserved to end of parsing
            // Verification/CLOT checksum can be reused when done

            // each disjoint set can be assigned to a HW unit
            auto disjointSets = compute_disjoint_sets(parser, decls);

            LOG4("disjoint parser checksum sets: " << disjointSets.size());

            // now save allocation results
            save_allocation(disjointSets);
        }

        void save_allocation(const std::set<std::set<cstring>>& disjoint_sets) {
            unsigned curr_id = 0;

            for (auto ds : disjoint_sets) {
                for (auto s : ds) {
                    LOG4("allocated parser checksum unit " << curr_id
                         << " to " << s);

                    self.declToChecksumId[s] = curr_id;

                    auto& path = checksumInfo.decl_name_to_states.at(s);
                    self.declToStartState[s] = *path.begin();
                    self.declToEndState[s]   = *path.rbegin();
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
    std::map<cstring, unsigned>                    declToChecksumId;
    std::map<cstring, const IR::BFN::ParserState*> declToStartState;
    std::map<cstring, const IR::BFN::ParserState*> declToEndState;

    AllocateParserChecksumUnits() :
        checksumInfo(parserInfo),
        computeDeadParserChecksums(parserInfo, checksumInfo) {
        addPasses({
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
