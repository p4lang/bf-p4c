#ifndef _PARSER_OVERLAY_H_
#define _PARSER_OVERLAY_H_

#include <iostream>
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/bitvec.h"
#include "lib/symbitmatrix.h"
#include "tofino/phv/phv_fields.h"
#include "tofino/parde/parde_visitor.h"

/* Produces a SymBitMatrix where keys are PhvInfo::Field ids and values
 * indicate whether two fields are mutually exclusive.
 */

class ParserOverlay : public ControlFlowVisitor,
                      public PardeInspector, P4WriteContext {
 private:
    const PhvInfo&   phv;

    // mutually_inclusive(f1, f2) == false implies that f1 and f2 cannot appear
    // in the same packet header.
    SymBitMatrix     mutually_inclusive;
    SymBitMatrix&    mutually_exclusive;

    bitvec           fields_encountered;

    void mark(const PhvInfo::Field*);
    void mark(const IR::HeaderRef*);

    bool preorder(const IR::Expression*) override;
    bool preorder(const IR::Tofino::Deparser*) override { return false; }

    bool filter_join_point(const IR::Node *n) override {
        return !n->is<IR::Tofino::ParserState>(); }
    void flow_merge(Visitor &) override;

    void end_apply() override;

 public:
    explicit ParserOverlay(PhvInfo& phv, SymBitMatrix& rv) :
        phv{phv}, mutually_exclusive{rv}
    {
        joinFlows = true;
        visitDagOnce = true;
    }
    ParserOverlay *clone() const override { return new ParserOverlay(*this); }
};

#endif /*_PARSER_OVERLAY_H_ */
