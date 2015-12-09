#include "extract_parser.h"
#include "lib/log.h"

bool GetTofinoParser::preorder(const IR::Parser *p) {
  states[p->name] = new IR::Tofino::ParserState(p);
  return true;
}

bool GetTofinoParser::FindExtract::preorder(const IR::HeaderStackItemRef *hs) {
  LOG3("   FindExtract(" << hs->toString() << ")  hdr=" << hdr->toString() <<
       "  hs->base=" << hs->base()->toString());
  if (hs->base()->toString() == hdr->toString()) {
    auto idx = dynamic_cast<const IR::Constant *>(hs->index());
    if (idx)
      index = idx->asInt(); }
  return true;
}

IR::Expression *GetTofinoParser::RewriteExtractNext::preorder(IR::NamedRef *name) {
  if (name->name != "next") return name;
  auto *hdr = findContext<IR::HeaderStackItemRef>();
  if (!hdr) /* error? */
    return name;
  int index = -1;
  for (const Context *c = ctxt; index < 0 && c; c = c->parent)
    for (auto m : c->state->match)
      m->stmts.apply(FindExtract(hdr->base(), index));
  ++index;
  LOG2("   rewrite " << hdr->base() << "[next] => [" << index << "]");
  auto *hdrstack = program->get<IR::HeaderStack>(hdr->base()->toString());
  if (!hdrstack) {
    error("%s: No header stack %s", hdr->base()->srcInfo, hdr->base()->toString());
    failed = true;
  } else if (index >= hdrstack->size) {
    failed = true;
    return name; }
  return new IR::Constant(index);
}

void GetTofinoParser::addMatch(IR::Tofino::ParserState *s, int val, int mask,
                               const IR::ID &action, const Context *ctxt) {
  Context local = { ctxt, ctxt ? ctxt->depth+1 : 0, s };
  LOG2("GetParser::addMatch(" << s->p4state->name << ", " << val << ", " <<
       mask << ", " << local.depth << ")");
  auto match = new IR::Tofino::ParserMatch(val, mask, s->p4state->stmts);
  RewriteExtractNext rewrite(program, ctxt);
  match->stmts = *match->stmts.apply(rewrite);
  s->match.push_back(match);
  if (rewrite.failed) {
    match->stmts.clear();
    match->except = new IR::ParserException; // header stack overflow, generally
  } else if ((match->next = state(action, &local))) {
  } else if (program->get<IR::Control>(action)) {
    if (ingress_control) {
      if (ingress_control != action)
        error("%s: Multiple ingress entry points %s and %s",
              action.srcInfo, ingress_control, action);
    } else
      ingress_control = action;
  } else if ((match->except = program->get<IR::ParserException>(action))) {
  } else
    error("%s: No definition for %s", action.srcInfo, action);
}

IR::Tofino::ParserState *GetTofinoParser::state(cstring name, const Context *ctxt) {
  if (states.count(name) == 0) return nullptr;
  auto rv = states[name];
  if (ctxt->find(rv)) rv = new IR::Tofino::ParserState(rv->p4state);
  if (!rv->match.empty()) return rv;
  LOG2("GetParser::state(" << name << ")");
  if (rv->p4state->cases)
    for (auto ce : *rv->p4state->cases)
      for (auto val : ce->values)
        addMatch(rv, val.first, val.second, ce->action, ctxt);
  if (rv->p4state->default_return)
    addMatch(rv, 0, 0, rv->p4state->default_return, ctxt);
  else if (rv->p4state->parse_error)
    addMatch(rv, 0, 0, rv->p4state->parse_error, ctxt);
  return rv;
}

IR::Tofino::Parser *GetTofinoParser::parser(gress_t gress) {
  auto timer = init_apply(program);
  LOG1("#GetTofinoParser");
  return new IR::Tofino::Parser(gress, state("start", nullptr));
}

cstring GetTofinoParser::ingress_entry() {
  auto timer = init_apply(program);
  if (!ingress_control){
    LOG1("#GetTofinoParser");
    state("start", nullptr); }
  return ingress_control.name;
}
