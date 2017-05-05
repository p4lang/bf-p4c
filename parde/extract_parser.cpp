#include "extract_parser.h"
#include "lib/log.h"

namespace Tofino {

class GetTofinoParser : public Inspector {
 public:
    explicit GetTofinoParser(const IR::P4Parser *p) : container(p) {}
    IR::Tofino::Parser *parser(gress_t);
    cstring ingress_entry();

    struct Context {
        /* records the path through the parser state machine from the start state to the
         * current state.  Not to be confused with Visitor::Context */
        const Context               *parent;
        int                         depth;
        IR::Tofino::ParserState     *state;
        const Context *find(IR::Tofino::ParserState *s) const {
            for (auto *c = this; c; c = c->parent)
                if (c->state == s)
                    return c;
            return nullptr; }
    };
    void addMatch(IR::Tofino::ParserState *, match_t, const IR::Vector<IR::Expression> &,
                  const IR::ID &, const Context *);
    IR::Tofino::ParserState *state(cstring, const Context *);

private:
    bool preorder(const IR::ParserState *) override;

    const IR::P4Parser                         *container = 0;
    gress_t                                     gress = INGRESS;
    map<cstring, IR::Tofino::ParserState *>     states;
    IR::ID                                      ingress_control;
};

class RemoveSetMetadata : public Transform {
    IR::Primitive *preorder(IR::Primitive *prim) override {
        return prim->name == "set_metadata" ? nullptr : prim; }
};

ParserInfo extractParser(const IR::P4Parser* parser) {
  GetTofinoParser parserGetter(parser);
  return {
    parserGetter.parser(INGRESS),
    parserGetter.parser(EGRESS)->apply(RemoveSetMetadata()),
    parserGetter.ingress_entry()
  };
}

bool GetTofinoParser::preorder(const IR::ParserState *p) {
    if (p->name == "accept" || p->name == "reject")
        return false;
    auto *s = states[p->name] = new IR::Tofino::ParserState(p, gress);
    if (s->name != p->name)
        states[s->name] = s;
    return true;
}

class FindStackExtract : public Inspector {
    const IR::HeaderRef         *hdr;
    int                         &index;
    bool preorder(const IR::HeaderStackItemRef *hs) override {
        auto prim = findContext<IR::Primitive>();
        if (!prim || prim->name != "extract") return true;  // do we need this check?
        LOG3("   FindStackExtract(" << hs->toString() << ")  hdr=" << hdr->toString() <<
             "  hs->base=" << hs->base()->toString());
        if (hs->base()->toString() == hdr->toString()) {
            auto idx = dynamic_cast<const IR::Constant *>(hs->index());
            if (idx)
                index = std::max(index, idx->asInt()); }
        return true; }
 public:
    FindStackExtract(const IR::HeaderRef *h, int &out) : hdr(h), index(out) {}
    FindStackExtract(const IR::Expression *e, int &out)
    : hdr(dynamic_cast<const IR::HeaderRef *>(e)), index(out) {
        if (!hdr) BUG("not a valid header ref"); }
};

class FindLatestExtract : public Inspector {
    const IR::Expression *&latest;
    bool preorder(const IR::Primitive *prim) override {
        if (prim->name == "extract") latest = prim->operands[0];
        return true; }

 public:
    explicit FindLatestExtract(const IR::Expression *&l) : latest(l) {}
};

class RewriteExtractNext : public Transform {
    typedef GetTofinoParser::Context Context;     // not to be confused with Visitor::Context
    const Context                 *ctxt;
    const IR::Expression          *latest = nullptr;
    std::map<cstring, int>        adjust;
    const IR::Expression *preorder(IR::Member *name) override;
    const IR::Expression *postorder(IR::Primitive *prim) override {
        if (prim->name == "extract") latest = prim->operands[0];
        return prim; }
    const IR::Expression *postorder(IR::Member *mem) override {
        /* FIXME -- could do full typechecking after this pass, but this is the only fixup needed,
         * for 'latest' refs that now point to real headers */
        if (mem->type == IR::Type::Unknown::get()) {
            if (auto ht = mem->expr->type->to<IR::Type_StructLike>()) {
                auto f = ht->getField(mem->member);
                if (f != nullptr)
                    mem->type = f->type; } }
        return mem; }

    const IR::Vector<IR::Expression> *preorder(IR::IndexedVector<IR::StatOrDecl> *vec) override {
        auto *rv = new IR::Vector<IR::Expression>;
        for (auto stmt : *vec) {
            auto *n = apply_visitor(stmt);
            if (!n) continue;
            else if (auto *e = n->to<IR::Expression>())
                rv->push_back(e);
            else if (auto *v = n->to<IR::Vector<IR::Expression>>())
                rv->insert(rv->end(), v->begin(), v->end()); }
        prune();  // don't visit children again
        return rv; }
    const IR::Node *preorder(IR::MethodCallStatement *s) override {
        return transform_child(s->methodCall); }
    const IR::Expression *preorder(IR::MethodCallExpression *e) override {
        if (auto meth = e->method->to<IR::Member>()) {
            if (meth->member == "extract")
                return new IR::Primitive(meth->srcInfo, "extract", e->arguments);
        } else {
            BUG("invalid method call %s", e); }
        return e; }
    const IR::Expression *preorder(IR::AssignmentStatement *s) override {
        if (!canEvaluateInParser(s->right))
            ::error("Assignment cannot be supported in the parser: %1%", s->right);
        return new IR::Primitive(s->srcInfo, "set_metadata", s->left, s->right); }
    const IR::Expression *preorder(IR::Statement *) override { BUG("Unhandled statement kind"); }

    bool canEvaluateInParser(const IR::Expression* expression) const {
        // Peel off any Cast expression. This accepts more programs than we can
        // actually implement; some casts can't be performed at parse time.
        if (expression->is<IR::Cast>()) {
            expression = expression->to<IR::Cast>()->expr;
        }

        // We can't evaluate complex expressions on current hardware.
        return expression->is<IR::Constant>() ||
               expression->is<IR::PathExpression>() ||
               expression->is<IR::Member>() ||
               expression->is<IR::HeaderStackItemRef>() ||
               expression->is<IR::ArrayIndex>();
    }

 public:
    bool                        failed = false;
    explicit RewriteExtractNext(const Context *c) : ctxt(c) {}
};

const IR::Expression *RewriteExtractNext::preorder(IR::Member *m) {
    if (m->member != "next" && m->member != "last") return m;
    int index = -1;
    for (const Context *c = ctxt; index < 0 && c; c = c->parent)
        for (auto match : c->state->match)
            match->stmts.apply(FindStackExtract(m->expr, index));
    cstring hdrname = m->expr->toString();
    index += adjust[hdrname];
    if (m->member == "next")
        ++index;
    LOG2("   rewrite " << m << " => [" << index << "]");
    if (index >= m->expr->type->to<IR::Type_Stack>()->size->to<IR::Constant>()->asInt()) {
        failed = true;
        return m; }
    if (auto prim = findContext<IR::Primitive>())
        if (prim->name == "extract")
            adjust[hdrname]++;
    return new IR::HeaderStackItemRef(m->srcInfo,
        m->expr->type->to<IR::Type_Stack>()->elementType->to<IR::Type_Header>(),
        m->expr, new IR::Constant(index));
}

void GetTofinoParser::addMatch(IR::Tofino::ParserState *s, match_t match_val,
                               const IR::Vector<IR::Expression> &stmts, const IR::ID &action,
                               const Context *ctxt) {
    Context local = { ctxt, ctxt ? ctxt->depth+1 : 0, s };
    LOG2("GetParser::addMatch(" << s->p4state->toString() << ", " << match_val <<
         ", " << local.depth << ")");
    auto match = new IR::Tofino::ParserMatch(match_val, stmts);
    s->match.push_back(match);
    if (!(match->next = state(action, &local))) {
        if (action == "accept" || action == "reject")
            return;
        else if (!states.count(action))
            error("%s: No definition for %s", action.srcInfo, action);
        // If there is a parser state with this name, but we couldn't generate it, its probably
        // because we've unrolled a loop filling a header stack completely.  Should set some
        // parser error code?
    }
}

static match_t buildListMatch(const IR::Vector<IR::Expression> *list) {
    match_t     rv;
    for (auto el : *list) {
        int width = el->type->width_bits();
        rv.word0 <<= width;
        rv.word1 <<= width;
        uintmax_t mask = -1, v;
        mask = ~(mask << width);
        if (auto k = el->to<IR::Constant>()) {
            v = k->asLong();
        } else if (auto mval = el->to<IR::Mask>()) {
            v = mval->right->to<IR::Constant>()->asLong();
            rv.word0 |= mask & ~v;
            rv.word1 |= mask & ~v;
            mask &= v;
            v = mval->left->to<IR::Constant>()->asLong();
        } else {
            BUG("Invalid select case expression %1%", el); }
        rv.word0 |= mask & ~v;
        rv.word1 |= mask & v; }
    return rv;
}

static match_t buildMatch(int match_size, const IR::Expression *key) {
    if (key->is<IR::DefaultExpression>())
        return match_t();
    else if (auto k = key->to<IR::Constant>())
        return match_t(match_size, k->asLong(), ~0ULL);
    else if (auto mask = key->to<IR::Mask>())
        return match_t(match_size, mask->left->to<IR::Constant>()->asLong(),
                                   mask->right->to<IR::Constant>()->asLong());
    else if (auto list = key->to<IR::ListExpression>())
        return buildListMatch(&list->components);
    else
        BUG("Invalid select case expression %1%", key);
    return match_t();
}

IR::Tofino::ParserState *GetTofinoParser::state(cstring name, const Context *ctxt) {
    if (states.count(name) == 0) return nullptr;
    if (ctxt && ctxt->depth >= 256) return nullptr;
    auto rv = states[name];
    if (ctxt && ctxt->find(rv)) {
        rv = new IR::Tofino::ParserState(rv->p4state, gress);
        rv->name = cstring::make_unique(states, name);
        states[rv->name] = rv; }
    if (!rv->match.empty()) return rv;
    RewriteExtractNext rewrite(ctxt);
    const IR::Vector<IR::Expression> *stmts;
    stmts = rv->p4state->components.Node::apply(rewrite)->to<IR::Vector<IR::Expression>>();
    if (rewrite.failed)
        // FIXME should be setting an appropriate parser exception?
        return nullptr;
    rv->select = *rv->select.apply(rewrite);
    int match_size = 0;
    for (auto s : rv->select)
        match_size += s->type->width_bits();

    LOG2("GetParser::state(" << name << ")");
    if (!rv->p4state->selectExpression) {
    } else if (auto *path = rv->p4state->selectExpression->to<IR::PathExpression>()) {
        addMatch(rv, match_t(), *stmts, path->path->name, ctxt);
    } else if (auto *sel = rv->p4state->selectExpression->to<IR::SelectExpression>()) {
        for (auto ce : sel->selectCases)
            addMatch(rv, buildMatch(match_size, ce->keyset), *stmts,
                     ce->state->path->name, ctxt);
    } else {
        BUG("Invalid select expression %1%", rv->p4state->selectExpression); }

    return rv;
}

IR::Tofino::Parser *GetTofinoParser::parser(gress_t gress) {
    if (this->gress != gress) {
        states.clear();
        this->gress = gress; }
    if (states.empty()) {
        LOG1("#GetTofinoParser");
        container->apply(*this); }
    return new IR::Tofino::Parser(gress, state("start", nullptr));
}

cstring GetTofinoParser::ingress_entry() {
    if (!ingress_control && states.empty()) {
        LOG1("#GetTofinoParser");
        container->apply(*this);
        state("start", nullptr); }
    return ingress_control.name;
}

}  // namespace Tofino
