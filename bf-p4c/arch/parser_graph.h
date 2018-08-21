#ifndef EXTENSIONS_BF_P4C_ARCH_PARSER_GRAPH_H_
#define EXTENSIONS_BF_P4C_ARCH_PARSER_GRAPH_H_

#include "backends/graphs/parsers.h"

/// Extends p4c's parser graph with various algorithms
class P4ParserGraphs: public graphs::ParserGraphs {
    void postorder(const IR::P4Parser* parser) override {
        if (dumpDot)
            graphs::ParserGraphs::postorder(parser);
    }

    void end_apply() override {
        for (auto& kv : transitions) {
            for (auto* t : kv.second) {
                auto* src = t->sourceState;
                auto* dst = t->destState;

                preds[dst].insert(src);
                succs[src].insert(dst);
            }
        }
    }

    bool is_descendant_impl(const IR::ParserState* a, const IR::ParserState* b,
                            std::set<const IR::ParserState*>& visited) const {
        if (!a || !b || a == b)
            return false;

        auto inserted = visited.insert(b);
        if (inserted.second == false)  // visited
            return false;

        if (!succs.count(b))
            return false;

        if (succs.at(b).count(a))
            return true;

        for (auto succ : succs.at(b))
            if (is_descendant_impl(a, succ, visited))
                return true;

        return false;
    }

 public:
    P4ParserGraphs(P4::ReferenceMap *refMap, P4::TypeMap *typeMap, bool dumpDot) :
        graphs::ParserGraphs(refMap, typeMap, cstring()), dumpDot(dumpDot) { }

    /// Is "a" a descendant of "b"?
    bool is_descendant(const IR::ParserState* a, const IR::ParserState* b) const {
        std::set<const IR::ParserState*> visited;
        return is_descendant_impl(a, b, visited);
    }

    /// Is "a" an ancestor of "b"?
    bool is_ancestor(const IR::ParserState* a, const IR::ParserState* b) const {
        return is_descendant(b, a);
    }

    std::map<const IR::ParserState*, std::set<const IR::ParserState*>> preds, succs;

    bool dumpDot;
};

#endif /* EXTENSIONS_BF_P4C_ARCH_PARSER_GRAPH_H_ */
