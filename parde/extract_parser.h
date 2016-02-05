#ifndef _TOFINO_PARDE_EXTRACT_PARSER_H_
#define _TOFINO_PARDE_EXTRACT_PARSER_H_

#include "ir/ir.h"

class GetTofinoParser : public Inspector {
  const IR::Global                            *program;
  map<cstring, IR::Tofino::ParserState *>     states;
  IR::ID                                      ingress_control;
  bool preorder(const IR::Parser *) override;

  struct Context {
    const Context               *parent;
    int                         depth;
    IR::Tofino::ParserState     *state;
    const Context *find(IR::Tofino::ParserState *s) const {
      for (auto *c = this; c; c = c->parent)
        if (c->state == s)
          return c;
      return nullptr; }
  };
  class FindExtract : public Inspector {
    const IR::HeaderRef         *hdr;
    int                         &index;
    bool preorder(const IR::HeaderStackItemRef *) override;
   public:
    FindExtract(const IR::HeaderRef *h, int &out) : hdr(h), index(out) {}
    FindExtract(const IR::Expression *e, int &out)
    : hdr(dynamic_cast<const IR::HeaderRef *>(e)), index(out) {
      if (!hdr) BUG("not a valid header ref"); }
  };
  class RewriteExtractNext : public Transform {
    typedef GetTofinoParser::Context Context;     // not to be confused with Visitor::Context
    const IR::Global            *program;
    const Context               *ctxt;
    IR::Expression *preorder(IR::NamedRef *name) override;
   public:
    bool                        failed = false;
    RewriteExtractNext(const IR::Global *p, const Context *c) : program(p), ctxt(c) {}
  };
  void addMatch(IR::Tofino::ParserState *, int, int, const IR::Vector<IR::Expression> &,
                const IR::ID &, const Context *);
  IR::Tofino::ParserState *state(cstring, const Context *);

 public:
  explicit GetTofinoParser(const IR::Global *g) : program(g) {}
  IR::Tofino::Parser *parser(gress_t);
  cstring ingress_entry();
};


#endif /* _TOFINO_PARDE_EXTRACT_PARSER_H_ */
