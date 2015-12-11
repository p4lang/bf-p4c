#ifndef _tofino_ir_parde_h_
#define _tofino_ir_parde_h_

namespace IR {

class Tofino_ParserState;

class Tofino_ParserMatch : public Node {
 public:
  long                        match, mask;
  int                         shift = 0;
  Vector<Expression>          stmts;
  const Tofino_ParserState    *next = nullptr;
  const ParserException       *except = nullptr;
  Tofino_ParserMatch(long v, long m, const Vector<Expression> &e)
  : match(v), mask(m), shift(0), stmts(e), next(0), except(0) {}
  IRNODE_SUBCLASS(Tofino_ParserMatch)
  bool operator==(const Tofino_ParserMatch &a) const {
    return match == a.match && mask == a.mask && shift == a.shift &&
           stmts == a.stmts && next == a.next && except == a.except; }
  IRNODE_VISIT_CHILDREN({ 
    stmts.visit_children(v);
    v.visit(next);
    v.visit(except); })
};

class Tofino_ParserState : public Node {
 public:
  const IR::Parser            *p4state;
  Vector<Expression>          select;
  Vector<Tofino_ParserMatch>  match;
  Tofino_ParserState(const IR::Parser *);
  IRNODE_SUBCLASS(Tofino_ParserState)
  bool operator==(const Tofino_ParserState &a) const {
    /* we don't compare the p4state, as it's only present for info */
    return select == a.select && match == a.match; }
  IRNODE_VISIT_CHILDREN({ 
    /* we don't visit the p4state, as it's only present for info */
    select.visit_children(v);
    match.visit_children(v); })
};

class Tofino_Parser : public Node {
public:
  gress_t 		        gress;
  const Tofino_ParserState	*start;
  Tofino_Parser(gress_t gr, const Tofino_ParserState *s) : gress(gr), start(s) {}
  IRNODE_SUBCLASS(Tofino_Parser)
  bool operator==(const Tofino_Parser &a) const {
    return gress == a.gress && start == a.start; }
  IRNODE_VISIT_CHILDREN({ v.visit(start); })
  void dbprint(std::ostream &out) const override;
};

class Tofino_Deparser : public Node {
public:
  gress_t 		gress;
  const IR::Parser	*start;
  Tofino_Deparser(gress_t gr, const Tofino_Parser *s)
  : gress(gr), start(s && s->start ? s->start->p4state : 0) {}
  IRNODE_SUBCLASS(Tofino_Deparser)
  bool operator==(const Tofino_Deparser &a) const {
    return gress == a.gress && start == a.start; }
  IRNODE_VISIT_CHILDREN({ v.visit(start); })
  void dbprint(std::ostream &out) const override;
};

namespace Tofino {
using ParserMatch = Tofino_ParserMatch;
using ParserState = Tofino_ParserState;
using Parser = Tofino_Parser;
using Deparser = Tofino_Deparser;
} // end namespace Tofino

} // end namespace IR

#endif /* _tofino_ir_parde_h_ */
