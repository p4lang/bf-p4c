#ifndef EXTENSIONS_BF_P4C_COMMON_BRIDGED_PACKING_H_
#define EXTENSIONS_BF_P4C_COMMON_BRIDGED_PACKING_H_

#include "z3++.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/constraints/constraints.h"
#include "bf-p4c/phv/phv_fields.h"

using RepackedHeaderTypes = ordered_map<cstring, const IR::Type_StructLike*>;

/**
 * Todo list for future improvements
 *
 * IMPL_NOTE(0) no_split and no_split_container_size constraints
 *
 * The alignment constraint analysis may collect multiple alignment constraints
 * on a single bridged field. In this case, the bridge packing algorithm must
 * pick one of the alignment constraint as the final alignment for packing. If
 * the selected alignment constraint is derived from a source field that span
 * across byte boundary, then we generate additional no_split and
 * no_split_container_size constraint on the bridged field. E.g.,
 * if the alignment requirement is bit 6 with a field size of 6, then the
 * no_split constraint is 1 and no_split_container_size is round_up(6 + 6).
 */

/**
 * Gather ingress bridge to original field map
 *
 * XXX(hanw): This pass depends on Alias pass, We could figure out the mapping
 * from def-use analysis instead.
 */
class CollectIngressBridgedFields : public Inspector {
 private:
    const PhvInfo& phv;

    bool preorder(const IR::BFN::Unit* unit) override {
        if (unit->thread() == EGRESS)
            return false;
        return true;
    }

    profile_t init_apply(const IR::Node* root) override;
    void postorder(const IR::BFN::AliasMember* mem) override;
    void end_apply() override;

 public:
    explicit CollectIngressBridgedFields(const PhvInfo& phv) : phv(phv) { }

    /// Key: Bridged Field name, Value: Original field name.
    ordered_map<cstring, cstring> bridged_to_orig;
};

/**
 * Gather egress bridge/original field map
 *
 * XXX(hanw): This pass must be run before eliminating assignment statement in
 * parser states (ParserCopyProp).
 */
class CollectEgressBridgedFields : public Inspector {
    const PhvInfo& phv;
    ordered_map<const PHV::Field*,
        ordered_map<const PHV::Field*,
        ordered_set<const IR::BFN::ParserState*>>> candidateSourcesInParser;

 public:
    explicit CollectEgressBridgedFields(const PhvInfo& p) : phv(p) {}

    /// Key: Bridged field name, Value: Original field name.
    ordered_map<cstring, cstring> bridged_to_orig;

    Visitor::profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::BFN::Extract* extract) override;
    void end_apply() override;
};

// This class identifies all metadata fields that have alignment constraints
// due to initialization by SavedRVals in the parser.
class GatherParserExtracts : public Inspector {
 public:
    using FieldToFieldSet = ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>>;

 private:
    const PhvInfo& phv;
    // Map of all fields with alignment constraints due to initialization in
    // the parser with values being the field they are initialized to.
    FieldToFieldSet parserAlignedFields;
    FieldToFieldSet reverseParserAlignMap;

    profile_t init_apply(const IR::Node* root) override {
        parserAlignedFields.clear();
        reverseParserAlignMap.clear();
        return Inspector::init_apply(root);
    }

    bool preorder(const IR::BFN::Extract* e) override;

 public:
    explicit GatherParserExtracts(const PhvInfo& p) : phv(p) { }

    bool count(const PHV::Field* f) const {
        return parserAlignedFields.count(f);
    }

    const ordered_set<const PHV::Field*>& at(const PHV::Field* f) const {
        static ordered_set<const PHV::Field*> emptySet;
        if (!parserAlignedFields.count(f)) return emptySet;
        return parserAlignedFields.at(f);
    }

    bool revCount(const PHV::Field* f) const {
        return reverseParserAlignMap.count(f);
    }

    const ordered_set<const PHV::Field*>& revAt(const PHV::Field* f) const {
        static ordered_set<const PHV::Field*> emptySet;
        if (!reverseParserAlignMap.count(f)) return emptySet;
        return reverseParserAlignMap.at(f);
    }

    const FieldToFieldSet& getAlignedMap() const { return parserAlignedFields; }
    const FieldToFieldSet& getReverseMap() const { return reverseParserAlignMap; }
};

template <typename NodeType, typename Func, typename Func2>
void forAllMatchingDoPreAndPostOrder(const IR::Node* root, Func&& function, Func2&& function2) {
    struct NodeVisitor : public Inspector {
        explicit NodeVisitor(Func && function, Func2 && function2) :
            function(function), function2(function2) { }
        Func function;
        Func2 function2;
        bool preorder(const NodeType* node) override { function(node); return true; }
        void postorder(const NodeType* node) override { function2(node); }
    };
    root->apply(NodeVisitor(std::forward<Func>(function), std::forward<Func2>(function2)));
}

template <typename NodeType, typename Func>
void forAllMatchingDoPostOrder(const IR::Node* root, Func&& function) {
    struct NodeVisitor : public Inspector {
        explicit NodeVisitor(Func&& function) : function(function) { }
        Func function;
        void postorder(const NodeType* node) override { function(node); }
    };
    root->apply(NodeVisitor(std::forward<Func>(function)));
}

// This class identifies all metadata fields that have alignment constraints
// due to usage in digest field list.
// The collected digest field mapping is currently not used.
class GatherDigestFields : public Inspector {
 public:
    using FieldToFieldSet = ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>>;

 private:
    const PhvInfo& phv;
    ordered_map<cstring, ordered_set<std::vector<const PHV::Field*>>> headers;
    ordered_map<cstring, ordered_set<std::vector<const PHV::Field*>>> digests;
    FieldToFieldSet digestFieldMap;
    FieldToFieldSet reverseDigestFieldMap;

 public:
    explicit GatherDigestFields(const PhvInfo& p) : phv(p) { }
    bool preorder(const IR::BFN::DigestFieldList* fl) override;
    bool preorder(const IR::HeaderOrMetadata* hdr) override;
    void end_apply() override;

    const FieldToFieldSet& getDigestMap() const { return digestFieldMap; }
    const FieldToFieldSet& getReverseDigestMap() const { return reverseDigestFieldMap; }
};

using AlignmentConstraint = Constraints::AlignmentConstraint;
using SolitaryConstraint = Constraints::SolitaryConstraint;

/**
 * Compute alignment constraints for bridging fields
 */
class CollectConstraints : public Inspector {
    PhvInfo& phv;

    struct Constraints {
        // collected alignment constraints;
        ordered_map<const PHV::Field*, ordered_set<AlignmentConstraint>> alignment;
        // two field must have the same constraint, exact value to be determined by solver.
        ordered_map<const PHV::Field*, std::vector<const PHV::Field*>> mutualAlignment;

        ordered_set<std::pair<const PHV::Field*, const PHV::Field*>> mustPack;
        ordered_set<std::pair<const PHV::Field*, SolitaryConstraint::SolitaryReason>> noPack;
    };
    Constraints constraints;

    const CollectIngressBridgedFields& ingressBridgedFields;
    const CollectEgressBridgedFields& egressBridgedFields;
    const GatherParserExtracts& parserAlignedFields;
    const GatherDigestFields& digestFields;
    const ActionPhvConstraints& actionConstraints;

    // determine alignment constraint on a single field.
    cstring getOppositeGressFieldName(cstring);
    cstring getEgressFieldName(cstring);

    ordered_set<const PHV::Field*> findAllRelatedFields(const PHV::Field* f);
    ordered_set<const PHV::Field*> findAllReachingFields(const PHV::Field* f);
    ordered_set<const PHV::Field*> findAllSourcingFields(const PHV::Field* f);
    ordered_set<const PHV::Field*> findAllRelatedFieldsOfCopackedFields(const PHV::Field* f);
    void computeAlignmentConstraint(const ordered_set<const PHV::Field*>&, bool);

    bool mustPack(const ordered_set<const PHV::Field*>& , const ordered_set<const PHV::Field*>&,
                  const ordered_set<const IR::MAU::Action*>&);
    void computeMustPackConstraints(const ordered_set<const PHV::Field*>&, bool);

    void computeNoPackIfIntrinsicMeta(const ordered_set<const PHV::Field*>&, bool);
    void computeNoPackIfActionDataWrite(const ordered_set<const PHV::Field*>&, bool);
    void computeNoPackIfSpecialityRead(const ordered_set<const PHV::Field*>&, bool);
    void computeNoPackIfDigestUse(const ordered_set<const PHV::Field*>&, bool);
    void computeNoSplitConstraints(const ordered_set<const PHV::Field*>&, bool);

    bool preorder(const IR::HeaderOrMetadata*) override;
    bool preorder(const IR::BFN::DigestFieldList*) override;
    profile_t init_apply(const IR::Node* root) override;
    void end_apply() override;

    /**
     * Invoke an inspector @p function for every node of type @p NodeType in the
     * subtree rooted at @p root. The behavior is the same as a postorder
     * Inspector. Extended with a lambda for preorder function.
     */
    template <typename NodeType, typename Func, typename Func2>
    void forAllMatching(const IR::Node* root, Func&& function, Func2&& function2) {
        struct NodeVisitor : public Inspector {
            explicit NodeVisitor(Func && function, Func2 && function2) :
                function(function), function2(function2) { }
            Func function;
            Func2 function2;
            bool preorder(const NodeType* node) override { function(node); return true; }
            void postorder(const NodeType* node) override { function2(node); }
        };
        root->apply(NodeVisitor(std::forward<Func>(function), std::forward<Func2>(function2)));
    }

 public:
    explicit CollectConstraints(PhvInfo& p,
            const CollectIngressBridgedFields& b,
            const CollectEgressBridgedFields& e,
            const GatherParserExtracts& g,
            const GatherDigestFields& d,
            const ActionPhvConstraints& a) :
        phv(p), ingressBridgedFields(b),
        egressBridgedFields(e), parserAlignedFields(g),
        digestFields(d),
        actionConstraints(a) {}
};

/**
 *
 */
class GatherAlignmentConstraints : public PassManager {
 private:
    // XXX(hanw): a dependency on Alias pass.
    CollectIngressBridgedFields collectIngressBridgedFields;
    CollectEgressBridgedFields  collectEgressBridgedFields;
    GatherParserExtracts        collectParserAlignedFields;
    GatherDigestFields          collectDigestFields;

 public:
    GatherAlignmentConstraints(PhvInfo& p, const ActionPhvConstraints& a) :
        collectIngressBridgedFields(p),
        collectEgressBridgedFields(p),
        collectParserAlignedFields(p),
        collectDigestFields(p) {
        addPasses({
            &collectIngressBridgedFields,
            &collectEgressBridgedFields,
            &collectParserAlignedFields,
            &collectDigestFields,
            new CollectConstraints(p,
                    collectIngressBridgedFields, collectEgressBridgedFields,
                    collectParserAlignedFields, collectDigestFields, a),
        });
    }
};

// header -> constraint type -> constraint
using DebugInfo = ordered_map<cstring, ordered_map<cstring, ordered_set<cstring>>>;

/**
 * Class to generate packing for a set of phv fields given a set of constraints
 */
class ConstraintSolver {
    const PhvInfo& phv;
    z3::context& context;
    z3::optimize& solver;
    DebugInfo& debug_info;

    void add_field_alignment_constraints(cstring, const PHV::Field*, int);
    void add_non_overlap_constraints(cstring, ordered_set<const PHV::Field*>&);
    void add_extract_together_constraints(cstring, ordered_set<const PHV::Field*>&);
    void add_solitary_constraints(cstring, ordered_set<const PHV::Field*>&);
    void add_deparsed_to_tm_constraints(cstring, ordered_set<const PHV::Field*>&);
    void add_no_pack_constraints(cstring, ordered_set<const PHV::Field*>&);
    void add_no_split_constraints(cstring, ordered_set<const PHV::Field*>&);

    const PHV::Field* create_padding(int size);
    std::vector<const PHV::Field*> insert_padding(
            std::vector<std::pair<unsigned, std::string>>&);

    void dump_unsat_core();

 public:
    explicit ConstraintSolver(const PhvInfo& p, z3::context& context,
            z3::optimize& solver, DebugInfo& dbg) :
        phv(p), context(context), solver(solver), debug_info(dbg) {}

    void add_constraints(cstring, ordered_set<const PHV::Field*>&);
    void add_mutually_aligned_constraints(ordered_set<const PHV::Field*>&);
    ordered_map<cstring, std::vector<const PHV::Field*>> solve(
            ordered_map<cstring, ordered_set<const PHV::Field*>>&);

    void print_assertions();
};

// This class computes the optimal field packing for all flexible field lists.
// We modeled as a single (larger) optimization problem as opposed to multiple
// (smaller) optimization because a field may exists in multiple flexible field
// lists. The computed alignment for the field must be consistent across all
// instances of the flexible field list. However, the optimizer is still
// optimizing each field list with individual optimization goals and
// constraints.  The number of constraints scales linearly with respect to the
// number of fields list instances. Within each field lists, the number of
// constraints scales at O(n^2) with respect to the number of fields.
class PackWithConstraintSolver : public Inspector {
    const PhvInfo& phv;
    ConstraintSolver& solver;
    ordered_set<cstring>& candidates;

    ordered_map<cstring, const IR::Type_StructLike*>& repackedTypes;

    // These maps collect information about @flexible fields from each
    // IR::HeaderOrMetadata and IR::BFN::DigestFieldList.
    ordered_map<cstring, ordered_set<const PHV::Field*>> nonByteAlignedFieldsMap;
    ordered_map<cstring, ordered_set<const PHV::Field*>> byteAlignedFieldsMap;
    ordered_map<cstring, ordered_map<const PHV::Field*, const IR::StructField*>>
                                                         phvFieldToStructFieldMap;
    ordered_map<cstring, const IR::Type_StructLike*>     headerMap;

 public:
    explicit PackWithConstraintSolver(const PhvInfo& p,
            ConstraintSolver& solver,
            ordered_set<cstring>& c,
            ordered_map<cstring, const IR::Type_StructLike*>& r):
        phv(p), solver(solver), candidates(c), repackedTypes(r) {}

    Visitor::profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::HeaderOrMetadata* hdr) override;
    bool preorder(const IR::BFN::DigestFieldList* dfl) override;
    void end_apply() override;

    void optimize();
    void solve();
};

// Pad phase0 and resubmit header to hardware-defined sizes.
class PadFixedSizeHeaders : public Inspector {
    ordered_map<cstring, const IR::Type_StructLike*>& repackedTypes;

 public:
    explicit PadFixedSizeHeaders(
            ordered_map<cstring, const IR::Type_StructLike*>& r) :
        repackedTypes(r) {}

    bool preorder(const IR::BFN::Type_FixedSizeHeader* h) override {
        auto width = [&](const IR::Type_StructLike* s) -> int {
            int rv = 0;
            for (auto f : s->fields)
                rv += f->type->width_bits();
            return rv;
        };

        auto countPadding = [&](const IR::IndexedVector<IR::StructField>& fields) -> int {
            int count = 0;
            for (auto f = fields.begin(); f != fields.end(); f++) {
                if ((*f)->getAnnotation("padding"))
                    count++; }
            return count;
        };

        auto genPadding = [&](int size, int id) {
            cstring padFieldName = "__pad_" + cstring::to_cstring(id);
            auto* fieldAnnotations =
                new IR::Annotations({ new IR::Annotation(IR::ID("padding"), { }),
                    new IR::Annotation(IR::ID("overlayable"), { }) });
            const IR::StructField* padField =
                new IR::StructField(padFieldName, fieldAnnotations,
                    IR::Type::Bits::get(size));
            return padField;
        };

        size_t bits = static_cast<size_t>(width(h));
        ERROR_CHECK(bits <= Device::pardeSpec().bitResubmitSize(),
                "%1% digest limited to %2% bits", h->name,
                Device::pardeSpec().bitResubmitSize());
        auto pad_size = h->fixed_size - bits;

        auto fields = new IR::IndexedVector<IR::StructField>();
        fields->append(h->fields);
        auto index = countPadding(h->fields);
        if (pad_size != 0) {
            auto padding = genPadding(pad_size, index++);
            fields->push_back(padding);
        }

        auto newType = new IR::Type_Header(h->name, *fields);
        repackedTypes.emplace(h->name, newType);
        return false;
    }
};

using RepackedHeaderTypes = ordered_map<cstring, const IR::Type_StructLike*>;
using FieldListEntry = std::pair<int, const IR::Type*>;

// Given the mapping from original flexible header type and the optimized
// type, replace the use of type in program.
class ReplaceFlexibleType : public Transform {
    const RepackedHeaderTypes& repackedTypes;

 public:
    explicit ReplaceFlexibleType(const RepackedHeaderTypes& m) : repackedTypes(m) {}

    // if used in backend
    const IR::Node* postorder(IR::HeaderOrMetadata* h) override;
    const IR::Node* postorder(IR::BFN::DigestFieldList* d) override;
    const IR::BFN::DigestFieldList* repackFieldList(cstring digest,
            std::vector<FieldListEntry> repackedFieldIndices,
            const IR::Type_StructLike* repackedHeaderType,
            const IR::BFN::DigestFieldList* origFieldList) const;

    // if used in midend
    const IR::Node* postorder(IR::Type_StructLike* h) override;
    const IR::Node* postorder(IR::StructExpression* h) override;
};

#endif /* EXTENSIONS_BF_P4C_COMMON_BRIDGED_PACKING_H_ */
