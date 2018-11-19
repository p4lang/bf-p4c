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
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

namespace PHV {
class Field;
}  // namespace PHV

class PhvInfo;

/* Produces a SymBitMatrix where keys are PHV::Field ids and values indicate
 * whether two fields are mutually exclusive, based on analyzing the structure
 * of the control flow graph to identify fields that are not live at the same
 * time.
 *
 * ALGORITHM: Build @mutually_inclusive, which denotes pairs of fields that are
 * live on the same control-flow path.  All fields in @fields_encountered that
 * are not mutually inclusive are mutually exclusive.
 *
 * For example, BuildParserOverlay inherits from BuildMutex, traversing the
 * parser control flow graph (and nothing else), and ignoring non-header
 * fields, to produce header fields that cannot be parsed from the same packet.
 *
 * @warning Take care when traversing a subset of the IR, because this might
 * produce fields that are mutually exclusive in that subgraph but not
 * throughout the entire IR.  For example, header fields that are mutually
 * exclusive in the parser may be added to the same packet in the MAU pipeline.
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
 *
 * This class is intended to be specialized in two ways: to tailor which parts
 * of the pipeline are visited, and to tailor which kinds of fields are
 * considered.  @see BuildParserOverlay, BuildMetadataOverlay.
 */
class BuildMutex : public BFN::ControlFlowVisitor, public Inspector {
 public:
    using FieldFilter_t = std::function<bool(const PHV::Field* f)>;

 private:
    PhvInfo&      phv;
    const bitvec&       neverOverlay;

    // Used to get information about mutually exclusive fields, specified by pragmas
    const PragmaMutuallyExclusive& pragmas;

    /// If mutually_inclusive(f1->id, f2->id), then fields f1 and f2 are used
    /// or defined on the same control flow path.
    SymBitMatrix     mutually_inclusive;

    /// If mutually_inclusive(f1, f2) == false, i.e. f1 and f2 never appear on
    /// the same control flow path, then f1 and f2 are mutually exclusive.
    SymBitMatrix&    mutually_exclusive;

    /// @returns true if @f should be ignored in this analysis.
    FieldFilter_t IgnoreField;

    /// Tracks the fields encountered (and not ignored) during this analysis.
    bitvec           fields_encountered;

    virtual void mark(const PHV::Field*);

    bool preorder(const IR::Expression*) override;
    void flow_merge(Visitor &) override;
    void end_apply() override;

 protected:
    profile_t init_apply(const IR::Node* root) override;

 public:
    BuildMutex(
            PhvInfo& phv,
            const bitvec& neverOverlay,
            const PragmaMutuallyExclusive& p,
            FieldFilter_t ignore_field)
            : phv(phv), neverOverlay(neverOverlay), pragmas(p),
              mutually_exclusive(phv.parser_mutex()), IgnoreField(ignore_field) {
        joinFlows = true;
        visitDagOnce = false; }

    BuildMutex *clone() const override { return new BuildMutex(*this); }
};

/* Produces a SymBitMatrix where keys are PHV::Field ids and values
 * indicate whether two fields are mutually exclusive, based on analyzing the
 * structure of the parse graph to identify fields that can never appear in the
 * same packet.  @see BuildMutex.
 */
class BuildParserOverlay : public BuildMutex {
 private:
    /// Ignore non-header fields.
    static bool ignore_field(const PHV::Field* f) {
        return !f || f->pov || f->metadata;
    }

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::TableSeq*) override { return false; }
    bool preorder(const IR::BFN::Deparser*) override { return false; }

 public:
    BuildParserOverlay(
            PhvInfo& phv,
            const bitvec& neverOverlay,
            const PragmaMutuallyExclusive& p)
        : BuildMutex(phv, neverOverlay, p, ignore_field) { }
};

/* Produces a SymBitMatrix where keys are PHV::Field ids and values indicate
 * whether two fields are mutually exclusive, based on analyzing the structure
 * of the MAU pipeline to identify metadata fields that are only used in
 * mutually exclusive tables/actions.  @see BuildMutex.
 */
class BuildMetadataOverlay : public BuildMutex {
 private:
    /// Ignore non-metadata fields.
    static bool ignore_field(const PHV::Field* f) {
        return !f || f->pov || !f->metadata;
    }

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::BFN::Deparser*) override { return false; }

 public:
    BuildMetadataOverlay(
            PhvInfo& phv,
            const bitvec& neverOverlay,
            const PragmaMutuallyExclusive& p)
        : BuildMutex(phv, neverOverlay, p, ignore_field) { }
};

/** Mark deparsed intrinsic metadata fields as never overlaid.  The deparser
 * reads the valid container bit for containers holding these fields, but
 * they're often never written.
 */
class ExcludeDeparsedIntrinsicMetadata : public Inspector {
    PhvInfo& phv;
    bitvec& neverOverlay;

    profile_t init_apply(const IR::Node* root) override {
        profile_t rv = Inspector::init_apply(root);
        neverOverlay.clear();
        return rv;
    }

    void end_apply() override;

 public:
    ExcludeDeparsedIntrinsicMetadata(PhvInfo& phv, bitvec& neverOverlay)
        : phv(phv), neverOverlay(neverOverlay) { }
};

/** Mark fields specified by pa_no_overlay as never overlaid. These fields are excluded from
  * BuildParserOverlay
  */
class ExcludePragmaNoOverlayFields : public Inspector {
    bitvec&                   neverOverlay;
    const PragmaNoOverlay&    pragma;

    void end_apply() override;

 public:
    ExcludePragmaNoOverlayFields(
        bitvec& neverOverlay,
        const PragmaNoOverlay& p)
    : neverOverlay(neverOverlay), pragma(p) { }
};

/** Find fields that appear in headers that may be added (with the `add_header`
 * or `.setValid` instructions) in the MAU pipeline.  These fields are
 * (conservatively) excluded from BuildParserOverlay.
 *
 * @param rv holds field IDs of fields that cannot be overlaid.
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
    PhvInfo& phv;
    bitvec& rv;

    bool preorder(const IR::Primitive* prim) override;

 public:
    FindAddedHeaderFields(PhvInfo& phv, bitvec& rv) : phv(phv), rv(rv) { }
};

/// @see BuildParserOverlay and FindAddedHeaderFields.
class ParserOverlay : public PassManager {
 private:
    /// Field IDs of fields that cannot be overlaid.
    bitvec              neverOverlay;

 public:
    ParserOverlay(
            PhvInfo& phv,
            const PHV::Pragmas& pragmas) {
        addPasses({
            new ExcludeDeparsedIntrinsicMetadata(phv, neverOverlay),
            new ExcludePragmaNoOverlayFields(neverOverlay, pragmas.pa_no_overlay()),
            // new FindAddedHeaderFields(phv, neverOverlay),
            new BuildParserOverlay(phv, neverOverlay, pragmas.pa_mutually_exclusive()),
            new BuildMetadataOverlay(phv, neverOverlay, pragmas.pa_mutually_exclusive())
        });
    }
};

#endif /*_PARSER_OVERLAY_H_ */
