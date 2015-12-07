#ifndef _TOFINO_PARDE_EXTRACT_PARSER_H_
#define _TOFINO_PARDE_EXTRACT_PARSER_H_

#include "ir/ir.h"
#include "ir/visitor.h"

class GetTofinoParser : public Inspector {
  const IR::Global                            *program;
  map<cstring, IR::Tofino::ParserState *>     states;
  IR::ID                                      ingress_control;
  bool preorder(const IR::Parser *) override;
  void addMatch(IR::Tofino::ParserState *, int, int, const IR::ID &);
  IR::Tofino::ParserState *state(cstring);

 public:
  GetTofinoParser(const IR::Global *g) : program(g) {}
  IR::Tofino::Parser *parser(gress_t);
  cstring ingress_entry();
};

#endif /* _TOFINO_PARDE_EXTRACT_PARSER_H_ */
