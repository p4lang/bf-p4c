#include <boost/range/adaptor/reversed.hpp>

#include "frontends/p4/callGraph.h"
#include "ir/ir.h"

namespace {

template <typename Func>
void generateEmits(const IR::Expression* expression, Func func) {
    auto* header = expression->to<IR::HeaderRef>();
    BUG_CHECK(header != nullptr,
              "Emitting something other than a header: %1%", expression);
    auto* headerType = header->type->to<IR::Type_StructLike>();
    BUG_CHECK(headerType != nullptr,
              "Emitting header with non-structlike type: %1%", headerType);

    auto* povBit = new IR::Member(IR::Type::Bits::get(1), header, "$valid");
    for (auto field : headerType->fields) {
        IR::Expression* fieldRef = new IR::Member(field->type, header, field->name);
        func(fieldRef, povBit);
    }
}

}  // namespace
IR::BFN::Deparser::Deparser(gress_t gr, const IR::P4Control* dp) : gress(gr) {
    CHECK_NULL(dp);
    forAllMatching<IR::MethodCallExpression>(dp,
                  [&](const IR::MethodCallExpression* mc) {
        auto method = mc->method->to<IR::Member>();
        if (!method || method->member != "emit") return true;
        generateEmits((*mc->arguments)[0], [&](const IR::Expression* field,
                                               const IR::Expression* povBit) {
            emits.push_back(new IR::BFN::Emit(mc->srcInfo, field, povBit));
        });
        return false;
    });
}

IR::BFN::Deparser::Deparser(gress_t gr, const IR::BFN::Parser* p) : gress(gr) {
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
    std::set<const IR::BFN::ParserState*> states;
    extractOrder.calls(p, p->start);  // The parser object is the entry point.
    states.insert(p->start);

    forAllMatching<IR::BFN::ParserState>(p, [&](const IR::BFN::ParserState* s) {
        for (auto match : s->match) {
            const IR::Node* lastExtract = s;
            for (auto stmt : match->stmts) {
                if (!stmt->is<IR::BFN::Extract>()) continue;
                auto extract = stmt->to<IR::BFN::Extract>();
                extractOrder.calls(lastExtract, extract->dest);
                lastExtract = extract->dest;
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
    std::set<cstring> visitedExtracts;
    for (auto extract : boost::adaptors::reverse(sortedExtracts)) {
        if (extract->is<IR::BFN::Parser>()) continue;
        if (visitedExtracts.find(extract->toString()) != visitedExtracts.end())
            continue;
        visitedExtracts.insert(extract->toString());
        if (!extract->is<IR::Member>()) continue;
        auto* field = extract->to<IR::Member>();
        if (field->member == "$valid") continue;
        auto* header = field->expr;
        auto* povBit = new IR::Member(IR::Type::Bits::get(1), header, "$valid");
        emits.push_back(new IR::BFN::Emit(field, povBit));
    }
}
