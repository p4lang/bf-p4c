#ifndef _PARSER_OVERLAY_H_
#define _PARSER_OVERLAY_H_

#include <iostream>
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/bitvec.h"
#include "lib/symbitmatrix.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/parde/parde_visitor.h"

namespace PHV {
class Field;
}  // namespace PHV

class PhvInfo;

/* Produces a SymBitMatrix where keys are PHV::Field ids and values
 * indicate whether two fields are mutually exclusive, based on analyzing the
 * structure of the parse graph to identify fields that can never appear in the
 * same packet.
 *
 * Takes as an argument a set of fields that can be added in the MAU pipeline.
 * These fields are never considered to be mutually exclusive with any other
 * field based on this analysis of the parser.
 *
 * For example, many P4 parsers accept packets that have either an IPv4 or IPv6
 * header, but not both.  These headers are considered mutually exclusive.
 * However, suppose an `add_header(ipv4)` instruction exists in the MAU
 * pipeline, and fields in the IPv4 header are supplied to this pass.  In that
 * case, IPv4 and IPv6 header fields are not considered mutually exclusive.
 */
class BuildParserOverlay : public BFN::ControlFlowVisitor,
                           public PardeInspector, TofinoWriteContext {
 private:
    const PhvInfo&   phv;
    const bitvec&    addedHeaderFields;

    // mutually_inclusive(f1, f2) == false implies that f1 and f2 cannot appear
    // in the same packet header.
    SymBitMatrix     mutually_inclusive;
    SymBitMatrix&    mutually_exclusive;

    bitvec           fields_encountered;

    void mark(const PHV::Field*);
    void mark(const IR::HeaderRef*);

    bool preorder(const IR::BFN::Extract*) override;
    bool preorder(const IR::BFN::Deparser*) override { return false; }
    void postorder(const IR::BFN::Pipe*) override;

    void flow_merge(Visitor &) override;
    void end_apply() override;

 public:
    BuildParserOverlay(
            PhvInfo& phv,
            const bitvec& addedHeaderFields,
            SymBitMatrix& rv)
            : phv(phv), addedHeaderFields(addedHeaderFields), mutually_exclusive(rv) {
        joinFlows = true;
        visitDagOnce = false; }

    BuildParserOverlay *clone() const override { return new BuildParserOverlay(*this); }
};


/** Find fields that appear in headers that may be added (with the `add_header`
 * or `.setValid` instructions) in the MAU pipeline.  These fields are
 * (conservatively) excluded from BuildParserOverlay.
 *
 * XXX(cole): This analysis could be improved to determine whether an
 * `add_header` instruction is unreachable for certain classes of packets,
 * potentially making BuildParserOverlay more precise.
 *
 * @pre Must run after CopyHeaderEliminator transforms instances of
 * `add_header` and `setValid` to `modify_field`, and after
 * InstructionSelection transforms `modify_field` to `set`.
 */
class FindAddedHeaderFields : public MauInspector {
 private:
    const PhvInfo& phv;
    bitvec& rv;

    bool preorder(const IR::Primitive* prim) override;

 public:
    FindAddedHeaderFields(const PhvInfo& phv, bitvec& rv) : phv(phv), rv(rv) { }
};

/** See documentation for BuildParserOverlay and FindAddedHeaderFields. */
class ParserOverlay : public PassManager {
 private:
    bitvec addedHeaderFields;

 public:
    ParserOverlay(PhvInfo& phv, SymBitMatrix& rv) {
        addPasses({
            new FindAddedHeaderFields(phv, addedHeaderFields),
            new BuildParserOverlay(phv, addedHeaderFields, rv) });
    }
};

#endif /*_PARSER_OVERLAY_H_ */
