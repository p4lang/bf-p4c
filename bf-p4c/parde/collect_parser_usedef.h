#ifndef EXTENSIONS_BF_P4C_PARDE_COLLECT_PARSER_USEDEF_H_
#define EXTENSIONS_BF_P4C_PARDE_COLLECT_PARSER_USEDEF_H_

#include "bf-p4c/common/utils.h"
#include "bf-p4c/parde/dump_parser.h"
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
    const IR::BFN::SavedRVal* save = nullptr;

    Use(const IR::BFN::ParserState* s,
        const IR::BFN::SavedRVal* save) : state(s), save(save) { }

    bool equiv(const Use* other) const {
        if (this == other) return true;
        return (state->name == other->state->name) && (save->equiv(*other->save));
    }

    std::string print() const {
        std::stringstream ss;
        ss << " [ " << state->name << " : " << save->source << " ]";
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
    get_use(const IR::BFN::ParserState* state, const IR::BFN::SavedRVal* save) const {
        auto temp = new Use(state, save);
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

struct ResolveExtractSaves : Modifier {
    const PhvInfo& phv;

    explicit ResolveExtractSaves(const PhvInfo& phv) : phv(phv) { }

    struct FindRVal : Inspector {
        const PhvInfo& phv;
        const IR::Expression* expr;
        const IR::BFN::InputBufferRVal* rv = nullptr;

        FindRVal(const PhvInfo& phv, const IR::Expression* f) : phv(phv), expr(f) { }

        bool preorder(const IR::BFN::Extract* extract) override {
            le_bitrange f_bits, x_bits;

            auto f = phv.field(extract->dest->field, &f_bits);
            auto x = phv.field(expr, &x_bits);

            if (f == x) {
                if (auto rval = extract->source->to<IR::BFN::InputBufferRVal>()) {
                    auto clone = rval->clone();

                    // Lines up source and dest (both can be field slices)
                    // The destination field, f, is in little endian, whereas the extract source
                    // in the input buffer is in big endian.
                    clone->range.lo -= f_bits.lo;
                    clone->range.hi += f->size - f_bits.hi - 1;

                    clone->range.lo = clone->range.hi - x_bits.hi;
                    clone->range.hi -= x_bits.lo;

                    rv = clone;
                }
            }

            return false;
        }
    };

    bool preorder(IR::BFN::Extract* extract) override {
        if (auto save = extract->source->to<IR::BFN::SavedRVal>()) {
            LOG4("resolve extract save: " << save);

            if (auto rval = save->source->to<IR::BFN::InputBufferRVal>()) {
                extract->source = rval;
            } else {
                auto state = findOrigCtxt<IR::BFN::ParserState>();

                FindRVal find_rval(phv, save->source);
                state->apply(find_rval);

                if (find_rval.rv)
                    extract->source = find_rval.rv;
            }

            LOG4("as: " << extract->source);
        }

        return false;
    }
};

/// Collect Use-Def for all select fields
///   Def: In which states are the select fields extracted?
///   Use: In which state are the select fields matched on?
struct CollectParserUseDef : PassManager {
    struct CollectDefs : ParserInspector {
        CollectDefs() { visitDagOnce = false; }

        std::map<const IR::BFN::ParserState*,
                 std::set<const IR::BFN::InputBufferRVal*>> state_to_rvals;

        std::map<const IR::BFN::InputBufferRVal*,
                 std::set<const IR::Expression*>> rval_to_lvals;

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
                rval_to_lvals[rval].insert(extract->dest->field);

                LOG4(state->name << " " << rval << " -> " << extract->dest->field);
            }

            return false;
        }
    };

    struct MapToUse : ParserInspector {
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

        Visitor::profile_t init_apply(const IR::Node* root) override {
            parser_use_def.clear();
            return ParserInspector::init_apply(root);
        }

        // defs have absolute offsets from current state
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

                            auto shifted_rval = rval->apply(ShiftPacketRVal(-(shift * 8), true));
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
        find_defs(const IR::Expression* saved,
                  const IR::BFN::ParserGraph& graph,
                  const IR::BFN::ParserState* state) {
            ordered_set<Def*> rv;

            for (auto& kv : defs.state_to_rvals) {
                auto def_state = kv.first;

                if (def_state == state || graph.is_ancestor(def_state, state)) {
                    for (auto rval : kv.second) {
                        for (auto lval : defs.rval_to_lvals.at(rval)) {
                            le_bitrange bits;
                            auto f = phv.field(lval);
                            auto s = phv.field(saved, &bits);

                            if (f == s) {
                                if (bits.size() == f->size) {
                                    auto def = new Def(def_state, rval);
                                    rv.insert(def);
                                } else {
                                    nw_bitrange nw_bits = bits.toOrder<Endian::Network>(f->size);
                                    auto slice_rval = rval->clone();
                                    slice_rval->range.lo = rval->range.lo + nw_bits.lo;
                                    slice_rval->range.hi = rval->range.lo + nw_bits.hi;
                                    auto def = new Def(def_state, slice_rval);
                                    rv.insert(def);
                                }
                            }
                        }
                    }
                }
            }

            return rv;
        }

        bool preorder(const IR::BFN::Parser *) override { revisit_visited(); return true; }
        bool preorder(const IR::BFN::ParserState *) override { visitOnce(); return true; }

        bool preorder(const IR::BFN::SavedRVal* save) override {
            auto parser = findOrigCtxt<IR::BFN::Parser>();
            auto state = findOrigCtxt<IR::BFN::ParserState>();
            auto& graph = parser_info.graph(parser);

            auto use = parser_use_def[parser].get_use(state, save);

            ordered_set<Def*> defs;

            if (auto buf = save->source->to<IR::BFN::InputBufferRVal>())
                defs = find_defs(buf, graph, state);
            else
                defs = find_defs(save->source, graph, state);

            for (auto def : defs)
                parser_use_def[parser].add_def(use, def);

            if (!parser_use_def[parser].use_to_defs.count(use))
                ::fatal_error("Use of uninitialized parser value %1%", use->print());

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

struct CopyPropParserDef : public ParserModifier {
    const CollectParserInfo& parser_info;
    const ParserUseDef& parser_use_def;

    CopyPropParserDef(const CollectParserInfo& pi, const ParserUseDef& ud) :
        parser_info(pi), parser_use_def(ud) { }

    const IR::BFN::InputBufferRVal*
    get_absolute_def(const IR::BFN::SavedRVal* save) {
        auto parser = findOrigCtxt<IR::BFN::Parser>();
        auto state = findOrigCtxt<IR::BFN::ParserState>();

        auto use = parser_use_def.at(parser).get_use(state, save);
        auto defs = parser_use_def.at(parser).use_to_defs.at(use);

        if (defs.size() == 1) {
            auto def = *defs.begin();
            auto shifts = parser_info.get_all_shift_amounts(def->state, state);

            // if has single def of absolute offset, propagate to use
            if (shifts->size() == 1) {
                auto rval = def->rval->clone();

                if (rval->is<IR::BFN::PacketRVal>()) {
                    auto shift = *shifts->begin();
                    rval->range = rval->range.shiftedByBits(-shift);
                }

                return rval;
            }
        }

        return nullptr;
    }

    bool preorder(IR::BFN::SavedRVal* save) override {
        if (save->source->is<IR::BFN::InputBufferRVal>())
            return false;

        auto orig = getOriginal<IR::BFN::SavedRVal>();

        if (auto def = get_absolute_def(orig)) {
            LOG4("propagate " << def << " to " << save->source);
            save->source = def;
        }

        return false;
    }
};

struct ParserCopyProp : public PassManager {
    explicit ParserCopyProp(const PhvInfo& phv) {
        auto* parserInfo = new CollectParserInfo;
        auto* collectUseDef = new CollectParserUseDef(phv, *parserInfo);
        auto* copyPropDef = new CopyPropParserDef(*parserInfo, collectUseDef->parser_use_def);

        addPasses({
            LOGGING(4) ? new DumpParser("before_parser_copy_prop") : nullptr,
            new ResolveExtractSaves(phv),
            parserInfo,
            collectUseDef,
            copyPropDef,
            LOGGING(4) ? new DumpParser("after_parser_copy_prop") : nullptr
        });
    }
};

#endif  /* EXTENSIONS_BF_P4C_PARDE_COLLECT_PARSER_USEDEF_H_ */
