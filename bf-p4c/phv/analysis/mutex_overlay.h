#ifndef EXTENSIONS_BF_P4C_PHV_ANALYSIS_MUTEX_OVERLAY_H_
#define EXTENSIONS_BF_P4C_PHV_ANALYSIS_MUTEX_OVERLAY_H_

#include <iostream>
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/bitvec.h"
#include "lib/symbitmatrix.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/parser_info.h"
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

 protected:
    PhvInfo&      phv;
    const bitvec&       neverOverlay;

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
    bool preorder(const IR::MAU::Action *act) override;
    void flow_merge(Visitor &) override;
    void end_apply() override;

 protected:
    profile_t init_apply(const IR::Node* root) override;

 public:
    BuildMutex(PhvInfo& phv, const bitvec& neverOverlay, FieldFilter_t ignore_field)
        : phv(phv), neverOverlay(neverOverlay), mutually_exclusive(phv.field_mutex()),
          IgnoreField(ignore_field) {
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
    /// Ignore non-header fields.
    static bool ignore_field(const PHV::Field* f) {
        return !f || f->pov || f->metadata;
    }

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::TableSeq*) override { return false; }
    bool preorder(const IR::BFN::Deparser*) override { return false; }

 public:
    BuildParserOverlay(PhvInfo& phv,
                       const bitvec& neverOverlay)
        : BuildMutex(phv, neverOverlay, ignore_field) { }
};

class ExcludeParserLoopReachableFields : public Visitor {
    PhvInfo&      phv;
    const MapFieldToParserStates&  fieldToStates;
    const CollectParserInfo&       parserInfo;

 private:
    const IR::Node *apply_visitor(const IR::Node *root, const char *) override;

    bool is_loop_reachable(
        const ordered_set<const IR::BFN::ParserState*>& k,
        const ordered_set<const IR::BFN::ParserState*>& v);

 public:
    ExcludeParserLoopReachableFields(PhvInfo& phv,
                       const MapFieldToParserStates& fs,
                       const CollectParserInfo& pi)
        : phv(phv), fieldToStates(fs), parserInfo(pi) { }
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
    BuildMetadataOverlay(PhvInfo& phv, const bitvec& neverOverlay)
        : BuildMutex(phv, neverOverlay, ignore_field) { }
};

/** Mark aliased header fields as never overlaid. When header fields are aliased, they are always
 * aliased with metadata, and should therefore be excluded from BuildParserOverlay.
 */
class ExcludeAliasedHeaderFields : public Inspector {
    PhvInfo& phv;
    bitvec& neverOverlay;

    bool preorder(const IR::BFN::AliasMember* alias) override {
        excludeAliasedField(alias);
        return true;
    }

    bool preorder(const IR::BFN::AliasSlice* alias) override {
        excludeAliasedField(alias);
        return true;
    }

    void excludeAliasedField(const IR::Expression* alias);

 public:
    ExcludeAliasedHeaderFields(PhvInfo& phv, bitvec& neverOverlay)
        : phv(phv), neverOverlay(neverOverlay) { }
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
    ExcludePragmaNoOverlayFields(bitvec& neverOverlay, const PragmaNoOverlay& p)
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
    bitvec rv;

    profile_t init_apply(const IR::Node* root) override {
        rv.clear();
        return Inspector::init_apply(root);
    }
    bool preorder(const IR::MAU::Primitive* prim) override;
    void markFields(const IR::HeaderRef* hr);

 public:
    explicit FindAddedHeaderFields(PhvInfo& phv) : phv(phv) { }
    bool isAddedInMAU(const PHV::Field* field) const { return rv[field->id]; }
};

class ExcludeMAUOverlays : public MauInspector {
 public:
    using ActionToFieldsMap = ordered_map<const IR::MAU::Action*, ordered_set<const PHV::Field*>>;

 private:
    PhvInfo&                        phv;
    const FindAddedHeaderFields&    addedFields;

    ActionToFieldsMap actionToWrites;
    ActionToFieldsMap actionToReads;

    profile_t init_apply(const IR::Node* root) override {
        actionToWrites.clear();
        actionToReads.clear();
        return Inspector::init_apply(root);
    }

    bool preorder(const IR::MAU::Table* tbl) override;
    bool preorder(const IR::MAU::Instruction* inst) override;
    void end_apply() override;

    // Given map of action to fields @arg, mark all fields corresponding to the same action as
    // mutually non-exclusive.
    void markNonMutex(const ActionToFieldsMap& arg);

 public:
    explicit ExcludeMAUOverlays(PhvInfo& p, const FindAddedHeaderFields& a)
        : phv(p), addedFields(a) { }
};

/** Prevent overlaying of all fields that are emitted depending on the same POV bit.
  */
class ExcludeDeparserOverlays : public Inspector {
 private:
    PhvInfo&                        phv;
    ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>> povToFieldsMap;

    profile_t init_apply(const IR::Node* root) override {
        povToFieldsMap.clear();
        return Inspector::init_apply(root);
    }

    bool preorder(const IR::BFN::EmitField* emit) override;
    void end_apply() override;

 public:
    explicit ExcludeDeparserOverlays(PhvInfo& p) : phv(p) { }
};

/** Checksum is calculated only when the checksum destination field is valid.
 *  We need to make sure that the fields included in checksum don't overlap any
 *  other live fields when checksum destination is live. We do this by giving
 *  all the checksum fields same mutex constraint as that of checksum
 *  destination. Note: This contraint is added only for tofino because tofino's
 *  checksum engine cannot dynamically predicate entries based on header
 *  validity.
 *  P4C-3064 - Avoid overlay of checksum fields with other fields that may be
 *  present. The pass was updated to detect if checksum source field might come
 *  from a new header being added in MAU. In that case, all of the checksum
 *  source fields are set to be non mutually exclusive with every field being
 *  extracted but not referenced in MAU.
 */
class ExcludeCsumOverlays : public Inspector {
 private:
    PhvInfo& phv;
    const FindAddedHeaderFields& addedFields;
    const PhvUse& use;
    bool preorder(const IR::BFN::EmitChecksum* emitChecksum) override;
 public:
    explicit ExcludeCsumOverlays(PhvInfo& p, const FindAddedHeaderFields& a, const PhvUse& u)
        : phv(p), addedFields(a), use(u) { }
};

class MarkMutexPragmaFields : public Inspector {
 private:
    PhvInfo& phv;
    const PragmaMutuallyExclusive& pragma;

    profile_t init_apply(const IR::Node* root) override;

 public:
    explicit MarkMutexPragmaFields(PhvInfo& p, const PragmaMutuallyExclusive& pr)
        : phv(p), pragma(pr) { }
};

/// @see BuildParserOverlay and FindAddedHeaderFields.
class MutexOverlay : public PassManager {
 private:
    /// Field IDs of fields that cannot be overlaid.
    bitvec                  neverOverlay;
    FindAddedHeaderFields   addedFields;
    CollectParserInfo       parserInfo;
    MapFieldToParserStates  fieldToParserStates;

 public:
    MutexOverlay(
            PhvInfo& phv,
            const PHV::Pragmas& pragmas,
            const PhvUse& use)
    : addedFields(phv), fieldToParserStates(phv) {
        addPasses({
            new ExcludeDeparsedIntrinsicMetadata(phv, neverOverlay),
            new ExcludePragmaNoOverlayFields(neverOverlay, pragmas.pa_no_overlay()),
            &addedFields,
            new ExcludeAliasedHeaderFields(phv, neverOverlay),
            new BuildParserOverlay(phv, neverOverlay),
            new BuildMetadataOverlay(phv, neverOverlay),
            &parserInfo,
            &fieldToParserStates,
            new ExcludeParserLoopReachableFields(phv, fieldToParserStates, parserInfo),
            Device::currentDevice() == Device::TOFINO ?
                new ExcludeCsumOverlays(phv, addedFields, use) : nullptr,
            new ExcludeMAUOverlays(phv, addedFields),
            new ExcludeDeparserOverlays(phv),
            new MarkMutexPragmaFields(phv, pragmas.pa_mutually_exclusive())
        });
    }
};

#endif  /* EXTENSIONS_BF_P4C_PHV_ANALYSIS_MUTEX_OVERLAY_H_  */
