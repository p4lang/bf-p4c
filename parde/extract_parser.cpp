#include "extract_parser.h"
#include "lib/log.h"

bool GetTofinoParser::preorder(const IR::Parser *p) {
  auto *s = states[p->name] = new IR::Tofino::ParserState(p);
  if (s->name != p->name)
    states[s->name] = s;
  return true;
}

bool GetTofinoParser::preorder(const IR::ParserState *p) {
  if (p->name == "accept" || p->name == "reject")
    return false;
  auto *s = states[p->name] = new IR::Tofino::ParserState(p);
  if (s->name != p->name)
    states[s->name] = s;
  return true;
}

bool GetTofinoParser::FindExtract::preorder(const IR::HeaderStackItemRef *hs) {
  LOG3("   FindExtract(" << hs->toString() << ")  hdr=" << hdr->toString() <<
       "  hs->base=" << hs->base()->toString());
  if (hs->base()->toString() == hdr->toString()) {
    auto idx = dynamic_cast<const IR::Constant *>(hs->index());
    if (idx)
      index = std::max(index, idx->asInt()); }
  return true;
}

class GetTofinoParser::RewriteExtractNext : public Transform {
  GetTofinoParser               &self;
  typedef GetTofinoParser::Context Context;     // not to be confused with Visitor::Context
  const Context                 *ctxt;
  std::map<cstring, int>        adjust;
  IR::Expression *preorder(IR::NamedRef *name) override;
  IR::Expression *preorder(IR::Member *name) override;

  IR::Vector<IR::Expression> *preorder(IR::Vector<IR::StatOrDecl> *vec) override {
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
    return new IR::Primitive(s->srcInfo, "set_metadata", s->left, s->right); }
  IR::Expression *preorder(IR::Statement *) override { BUG("Unhandled statement kind"); }

 public:
  bool                        failed = false;
  RewriteExtractNext(GetTofinoParser &s, const Context *c) : self(s), ctxt(c) {}
};

IR::Expression *GetTofinoParser::RewriteExtractNext::preorder(IR::NamedRef *name) {
  if (name->name != "next") return name;
  auto *hdr = findContext<IR::HeaderStackItemRef>();
  if (!hdr) /* error? */
    return name;
  cstring hdrname = hdr->toString();
  int index = -1;
  for (const Context *c = ctxt; index < 0 && c; c = c->parent)
    for (auto m : c->state->match)
      m->stmts.apply(FindExtract(hdr->base(), index));
  index += adjust[hdrname];
  ++index;
  LOG2("   rewrite " << hdr->base() << "[next] => [" << index << "]");
  auto *hdrstack = self.program->get<IR::HeaderStack>(hdr->base()->toString());
  if (!hdrstack) {
    error("%s: No header stack %s", hdr->base()->srcInfo, hdr->base()->toString());
    failed = true;
  } else if (index >= hdrstack->size) {
    failed = true;
    return name; }
  if (auto prim = findContext<IR::Primitive>())
    if (prim->name == "extract")
      adjust[hdrname]++;
  return new IR::Constant(index);
}

IR::Expression *GetTofinoParser::RewriteExtractNext::preorder(IR::Member *m) {
    if (m->member != "next" && m->member != "last") return m;
  int index = -1;
  for (const Context *c = ctxt; index < 0 && c; c = c->parent)
    for (auto match : c->state->match)
      match->stmts.apply(FindExtract(m->expr, index));
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
        m->expr->type->to<IR::Type_Stack>()->baseType->to<IR::Type_Header>(),
        m->expr, new IR::Constant(index));
}

void GetTofinoParser::addMatch(IR::Tofino::ParserState *s, int val, int mask,
                               const IR::Vector<IR::Expression> &stmts, const IR::ID &action,
                               const Context *ctxt) {
  Context local = { ctxt, ctxt ? ctxt->depth+1 : 0, s };
  LOG2("GetParser::addMatch(" << s->p4state->toString() << ", " << val << ", " <<
       mask << ", " << local.depth << ")");
  auto match = new IR::Tofino::ParserMatch(val, mask, stmts);
  s->match.push_back(match);
  if ((match->next = state(action, &local))) {
  } else if (!program) {
    if (action == "accept" || action == "reject")
      return;
    else if (!states.count(action))
      error("%s: No definition for %s", action.srcInfo, action);
    // If there is a parser state with this name, but we couldn't generate it, its probably
    // because we've unrolled a loop filling a header stack completely.  Should set some
    // parser error code?
  } else if (program->get<IR::Control>(action)) {
    if (ingress_control) {
      if (ingress_control != action)
        error("%s: Multiple ingress entry points %s and %s",
              action.srcInfo, ingress_control, action);
    } else {
      ingress_control = action; }
  } else if ((match->except = program->get<IR::ParserException>(action))) {
  } else if (program->get<IR::Parser>(action)) {
    // there is a parser state with this name, but we couldn't generate it, probably
    // because we've unrolled a loop filling a header stack completely.  Should set some
    // parser error code?
  } else {
    error("%s: No definition for %s", action.srcInfo, action); }
}

IR::Tofino::ParserState *GetTofinoParser::state(cstring name, const Context *ctxt) {
  if (states.count(name) == 0) return nullptr;
  if (ctxt && ctxt->depth >= 256) return nullptr;
  auto rv = states[name];
  if (ctxt->find(rv)) {
    rv = new IR::Tofino::ParserState(rv->p4state);
    rv->name = cstring::make_unique(states, name);
    states[rv->name] = rv; }
  if (!rv->match.empty()) return rv;
  RewriteExtractNext rewrite(*this, ctxt);
  const IR::Vector<IR::Expression> *stmts;
  auto *v1_0 = rv->p4state->to<IR::Parser>();
  auto *v1_2 = rv->p4state->to<IR::ParserState>();
  if (v1_0)
    stmts = v1_0->stmts.apply(rewrite);
  else if (v1_2)
    stmts = dynamic_cast<const IR::Vector<IR::Expression>*>(v1_2->components->Node::apply(rewrite));
  else
    BUG("invalid p4state in GetTofinoParser");
  if (rewrite.failed)
    // FIXME should be setting an appropriate parser exception?
    return nullptr;
  rv->select = *rv->select.apply(rewrite);

  LOG2("GetParser::state(" << name << ")");
  if (v1_0) {
    if (v1_0->cases)
      for (auto ce : *v1_0->cases)
        for (auto val : ce->values)
          addMatch(rv, val.first->asLong(), val.second->asLong(), *stmts, ce->action, ctxt);
    if (v1_0->default_return)
      addMatch(rv, 0, 0, *stmts, v1_0->default_return, ctxt);
    else if (v1_0->parse_error)
      addMatch(rv, 0, 0, *stmts, v1_0->parse_error, ctxt);
  } else {
    if (auto *path = dynamic_cast<const IR::PathExpression *>(v1_2->selectExpression)) {
      addMatch(rv, 0, 0, *stmts, path->path->name, ctxt);
    } else if (auto *sel = dynamic_cast<const IR::SelectExpression *>(v1_2->selectExpression)) {
      for (auto ce : *sel->selectCases) {
        if (ce->keyset->is<IR::DefaultExpression>())
          addMatch(rv, 0, 0, *stmts, ce->state->path->name, ctxt);
        else if (auto k = ce->keyset->to<IR::Constant>())
          addMatch(rv, k->asInt(), ~0, *stmts, ce->state->path->name, ctxt);
        else if (auto mask = ce->keyset->to<IR::Mask>())
          addMatch(rv, mask->left->to<IR::Constant>()->asInt(),
                   mask->right->to<IR::Constant>()->asInt(), *stmts, ce->state->path->name, ctxt);
        else
          BUG("Invalid select case expression %1%", ce); }
    } else if (v1_2->selectExpression) {
        BUG("Invalid select expression %1%", v1_2->selectExpression); } }
  return rv;
}

IR::Tofino::Parser *GetTofinoParser::parser(gress_t gress) {
  auto timer = program ? init_apply(program) : init_apply(container);
  LOG1("#GetTofinoParser");
  return new IR::Tofino::Parser(gress, state("start", nullptr));
}

cstring GetTofinoParser::ingress_entry() {
  auto timer = program ? init_apply(program) : init_apply(container);
  if (!ingress_control) {
    LOG1("#GetTofinoParser");
    state("start", nullptr); }
  return ingress_control.name;
}
