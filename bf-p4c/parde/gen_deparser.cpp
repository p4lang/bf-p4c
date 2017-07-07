#include <boost/range/adaptor/reversed.hpp>

#include "frontends/p4/callGraph.h"
#include "ir/ir.h"

IR::Tofino::Deparser::Deparser(gress_t gr, const IR::P4Control* dp) : gress(gr) {
    CHECK_NULL(dp);
    forAllMatching<IR::MethodCallExpression>(dp,
                  [&](const IR::MethodCallExpression* mc) {
        auto method = mc->method->to<IR::Member>();
        if (!method || method->member != "emit") return true;
        emits.push_back(new IR::Primitive(mc->srcInfo, "emit", mc->arguments));
        return false;
    });
}

IR::Tofino::Deparser::Deparser(gress_t gr, const IR::Tofino::Parser* p) : gress(gr) {
    CHECK_NULL(p);
    if (!p->start) return;

    // We need to convert the parser's extract calls into emit calls. The
    // extract calls occur in a directed graph of states, but emit calls are
    // executed sequentially, so we need to construct a topological sort. We'll
    // do this in two steps: first, we construct a graph containing edges
    // between sequential extract calls, and between the final extract in a
    // sequence and the next parser state. We then contract away the parser
    // state nodes, leaving only the extract calls.
    P4::CallGraph<const IR::Node*> extractOrder("extractOrder");
    std::set<const IR::Tofino::ParserState*> states;
    extractOrder.calls(p, p->start);  // The parser object is the entry point.
    states.insert(p->start);

    forAllMatching<IR::Tofino::ParserState>(p, [&](const IR::Tofino::ParserState* s) {
        for (auto match : s->match) {
            const IR::Node* lastExtract = s;
            for (auto stmt : match->stmts) {
                if (!stmt->is<IR::Primitive>()) continue;
                auto prim = stmt->to<IR::Primitive>();
                if (prim->name != "extract") continue;
                extractOrder.calls(lastExtract, prim->operands[0]);
                lastExtract = prim->operands[0];
            }
            if (match->next) {
                states.insert(match->next);
                extractOrder.calls(lastExtract, match->next);
            }
        }
    });

    // Contract away the parser state nodes. This will leave only the extracted
    // headers and the entry point.
    for (auto state : states) {
        auto* callees = extractOrder.getCallees(state);
        auto* callers = extractOrder.getCallers(state);
        extractOrder.remove(state);
        if (!callees || !callers) continue;
        for (auto caller : *callers)
            for (auto callee : *callees)
                extractOrder.calls(caller, callee);
    }

    // Construct a topological sort. This can only be done for DAGs; if there's
    // a loop, we'll just have to cope as best we can.
    std::vector<const IR::Node*> sortedExtracts;
    bool loop = extractOrder.sccSort(p, sortedExtracts);
    if (loop)
        ::warning("The order of headers in deparser is not uniquely determined by parser!");

    // Generate the emit calls.
    for (auto extract : boost::adaptors::reverse(sortedExtracts)) {
        if (extract->is<IR::Tofino::Parser>()) continue;
        auto expr = extract->to<IR::Expression>();
        BUG_CHECK(expr, "Extract is not expression?");
        emits.push_back(new IR::Primitive("emit", expr));
    }
}
