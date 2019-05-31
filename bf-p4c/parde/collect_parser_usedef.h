#ifndef EXTENSIONS_BF_P4C_PARDE_COLLECT_PARSER_USEDEF_H_
#define EXTENSIONS_BF_P4C_PARDE_COLLECT_PARSER_USEDEF_H_

#include "bf-p4c/parde/parde_utils.h"
#include "bf-p4c/parde/parser_info.h"

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

struct ParserUseDef : std::map<const IR::BFN::Parser*, UseDef> { };

/// Collect Use-Def for all select fields
///   Def: In which states are the select fields extracted?
///   Use: In which state are the select fields matched on?
struct CollectParserUseDef : PassManager {
    struct CollectDefs : Inspector {
        CollectDefs() { visitDagOnce = false; }

        std::map<const IR::BFN::ParserState*,
                 std::set<const IR::BFN::InputBufferRVal*>> state_to_rvals;

        std::map<const IR::BFN::InputBufferRVal*,
                 const IR::Expression*> rval_to_lval;

        bool preorder(const IR::BFN::ParserState *) override {
            visitOnce();  // only visit once, regardless of how many predecessors
            return true;
        }

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

    explicit CollectParserUseDef(const PhvInfo& phv, const CollectParserInfo& parser_info) {
        auto collect_defs = new CollectDefs;
        addPasses({
            collect_defs,
            new MapToUse(phv, parser_info, *collect_defs, parser_use_def),
        });
    }

    ParserUseDef parser_use_def;
};

#endif  /* EXTENSIONS_BF_P4C_PARDE_COLLECT_PARSER_USEDEF_H_ */
