#include "extract_parser.h"

bool GetTofinoParser::preorder(const IR::Parser *p) {
  states[p->name] = new IR::Tofino::ParserState(p);
  return true;
}

void GetTofinoParser::addMatch(IR::Tofino::ParserState *s, int val, int mask,
                               const IR::ID &action) {
  auto match = new IR::Tofino::ParserMatch(val, mask, s->p4state->stmts);
  s->match.push_back(match);
  if ((match->next = state(action))) ;
  else if (program->get<IR::Control>(action)) {
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

IR::Tofino::ParserState *GetTofinoParser::state(cstring name) {
  if (states.count(name) == 0) return nullptr;
  auto rv = states[name];
  if (!rv->match.empty()) return rv;
  if (rv->p4state->cases)
    for (auto ce : *rv->p4state->cases)
      for (auto val : ce->values)
        addMatch(rv, val.first, val.second, ce->action);
  if (rv->p4state->default_return)
    addMatch(rv, 0, 0, rv->p4state->default_return);
  else if (rv->p4state->parse_error)
    addMatch(rv, 0, 0, rv->p4state->parse_error);
  return rv;
}

IR::Tofino::Parser *GetTofinoParser::parser(gress_t gress) {
  return new IR::Tofino::Parser(gress, state("start"));
}

cstring GetTofinoParser::ingress_entry() {
  if (!ingress_control)
    state("start");
  return ingress_control.name;
}
