#ifndef _PARSER_OVERLAY_H_
#define _PARSER_OVERLAY_H_

#include <iostream>
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/bitvec.h"
#include "lib/symbitmatrix.h"
#include "tofino/phv/phv_fields.h"
#include "tofino/parde/parde_visitor.h"
#include "tofino/ir/tofino_write_context.h"

/* Produces a SymBitMatrix where keys are PhvInfo::Field ids and values
 * indicate whether two fields are mutually exclusive.
 */

class ParserOverlay : public ControlFlowVisitor,
                      public PardeInspector, TofinoWriteContext {
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
    bool preorder(const IR::BFN::Deparser*) override { return false; }

    void flow_merge(Visitor &) override;

    void end_apply() override;

 public:
    explicit ParserOverlay(PhvInfo& phv, SymBitMatrix& rv) : phv(phv), mutually_exclusive(rv) {
        joinFlows = true;
        visitDagOnce = true; }
    ParserOverlay *clone() const override { return new ParserOverlay(*this); }
};

#endif /*_PARSER_OVERLAY_H_ */
