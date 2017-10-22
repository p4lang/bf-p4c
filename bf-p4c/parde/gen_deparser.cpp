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

class GenerateDeparser : public Inspector {
    IR::BFN::Deparser                           *dprsr;
    const IR::Expression                        *pred = nullptr;
    ordered_map<cstring, IR::BFN::Digest *>     digests;

    void generateDigest(IR::BFN::Digest *&digest, cstring name, const IR::Expression *list);
    bool equiv(const IR::Expression *a, const IR::Expression *b) const;
    bool preorder(const IR::IfStatement *ifstmt) {
        const IR::Expression *old_pred = pred;
        pred = ifstmt->condition;
        if (old_pred) pred = new IR::LAnd(old_pred, pred);
        visit(ifstmt->ifTrue, "ifTrue");
        if (ifstmt->ifFalse) {
            pred = new IR::LNot(ifstmt->condition);
            if (old_pred) pred = new IR::LAnd(old_pred, pred);
            visit(ifstmt->ifFalse, "ifFalse"); }
        pred = old_pred;
        return false; }

    bool preorder(const IR::MethodCallExpression* mc) {
        auto method = mc->method->to<IR::Member>();
        if (!method) return true;
        if (method->member == "emit") {
            if (pred) error("Conditional emit %s not supported", mc);
            generateEmits((*mc->arguments)[0], [&](const IR::Expression* field,
                                                   const IR::Expression* povBit) {
                dprsr->emits.push_back(new IR::BFN::Emit(mc->srcInfo, field, povBit)); });
            return false;
        } else if (method->member == "update") {
            warning("FIXME method call %s in deparser not yet supported", mc);
            return false;
        } else if (method->member == "add_metadata") {
            if (auto dname = method->expr->to<IR::PathExpression>()) {
                generateDigest(digests[dname->path->name], dname->path->name, mc->arguments->at(0));
            } else {
                error("Unsupported method call %s in deparser", mc); }
            return false;
        } else {
            error("Unsupported method call %s in deparser", mc);
            return true; } }

 public:
    explicit GenerateDeparser(IR::BFN::Deparser *d) : dprsr(d) {}
};

// FIXME -- factor this with Digests::add_to_digest in digest.h?
void GenerateDeparser::generateDigest(IR::BFN::Digest *&digest, cstring name,
                                      const IR::Expression *expr) {
    const IR::Constant *k = nullptr;
    const IR::Expression *select;
    if (!pred) {
        error("%s:Unconditional %s.add_metadata not supported", expr->srcInfo, name);
        return;
    } else if (auto eq = pred->to<IR::Equ>()) {
        if ((k = eq->left->to<IR::Constant>()))
            select = eq->right;
        else if ((k = eq->right->to<IR::Constant>()))
            select = eq->left; }
    if (!k) {
        error("%s.add_metadata condition %s not supported", name, pred);
        return; }
    if (!digest) {
        digest = new IR::BFN::Digest(dprsr->gress, name, select);
        dprsr->digests.addUnique(name, digest);
    } else if (!equiv(select, digest->select)) {
        error("Inconsistent %s selectors, %s and %s", name, select, digest->select); }
    auto list = dynamic_cast<const IR::Vector<IR::Expression> *>(expr);
    if (!list) {
        if (auto l = dynamic_cast<const IR::ListExpression *>(expr))
            list = new IR::Vector<IR::Expression>(l->components);
        else if (expr)
            list = new IR::Vector<IR::Expression>({expr});
        else
            list = new IR::Vector<IR::Expression>; }
    if (static_cast<int>(digest->sets.size()) <= k->asInt())
        digest->sets.resize(k->asInt() + 1);
    digest->sets.at(k->asInt()) = list;
}

// FIXME -- yet another 'deep' comparison for expressions
bool GenerateDeparser::equiv(const IR::Expression *a, const IR::Expression *b) const {
    if (a == b) return true;
    if (typeid(*a) != typeid(*b)) return false;
    if (auto ma = a->to<IR::Member>()) {
        auto mb = b->to<IR::Member>();
        return ma->member == mb->member && equiv(ma->expr, mb->expr); }
    if (auto pa = a->to<IR::PathExpression>()) {
        auto pb = b->to<IR::PathExpression>();
        return pa->path->name == pb->path->name; }
    if (auto ka = a->to<IR::Constant>()) {
        auto kb = b->to<IR::Constant>();
        return ka->value == kb->value; }
    return false;
}

}  // namespace
IR::BFN::Deparser::Deparser(gress_t gr, const IR::P4Control* dp) : gress(gr) {
    CHECK_NULL(dp);
    dp->apply(GenerateDeparser(this));
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
        const IR::Node* lastExtract = s;
        for (auto* statement : s->statements) {
            if (!statement->is<IR::BFN::Extract>()) continue;
            auto* extract = statement->to<IR::BFN::Extract>();
            extractOrder.calls(lastExtract, extract->dest);
            lastExtract = extract->dest;
        }
        for (auto* transition : s->transitions) {
            if (!transition->next) continue;
            states.insert(transition->next);
            extractOrder.calls(lastExtract, transition->next);
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
