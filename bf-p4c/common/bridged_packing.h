#ifndef EXTENSIONS_BF_P4C_COMMON_BRIDGED_PACKING_H_
#define EXTENSIONS_BF_P4C_COMMON_BRIDGED_PACKING_H_

#include "z3++.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/constraints/constraints.h"
#include "bf-p4c/phv/phv_fields.h"

/**
 * \ingroup bridged_packing
 * \brief Adjusted packing of bridged and fixed-size headers;
 *        output of BFN::BridgedPacking, input for BFN::SubstitutePackedHeaders.
 *
 * There are two sources of adjusted packing:
 * - PackWithConstraintSolver::solve
 * - PadFixedSizeHeaders::preorder
 *
 * Adjusted packing is then used in the ReplaceFlexibleType pass.
 */
using RepackedHeaderTypes = ordered_map<cstring, const IR::Type_StructLike*>;

/**
 * The inspector builds a map of aliased fields (IR::BFN::AliasMember) mapping
 * alias destinations to their sources. Only aliases with destinations annotated
 * with the \@flexible annotation are considered.
 *
 * <table>
 * <caption>Logging options</caption>
 * <tr>
 * <td>-Tbridged_packing:5
 * <td>
 * - The aliases being added to the map
 * - Notice when a field is marked bridged in PhvInfo and is not included
 *   in the CollectIngressBridgedFields::bridged_to_orig map
 * </table>
 *
 * @pre The Alias pass needs to be performed before this one to create
 *      IR::BFN::AliasMember IR nodes.
 *      XXX(hanw): We could figure out the mapping from def-use analysis instead.
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

    /// Key: bridged field name, value: original field name
    ordered_map<cstring, cstring> bridged_to_orig;
};

/**
 * The inspector builds the CollectEgressBridgedFields::bridged_to_orig map
 * mapping source (bridged) fields to the destination (original) fields.
 * Only non-solitary destination fields are considered
 * (those not used in an arithmetic operation).
 * Only flexible source fields are considered.
 *
 * The information is later used to induce alignment constraints.
 *
 * <table>
 * <caption>Logging options</caption>
 * <tr>
 * <td>-Tbridged_packing:5
 * <td>
 * - Candidate fields to be added to the CollectEgressBridgedFields::bridged_to_orig map.
 * </table>
 *
 * @pre The ParserCopyProp pass cannot be run before this inspector since
 *      it removes assignment statements in parser states.
 *      TODO Why assignments? This pass processes only extracts.
 */
class CollectEgressBridgedFields : public Inspector {
    const PhvInfo& phv;
    /// Map-map-set: destination (IR::BFN::ParserLVal) -> source (IR::BFN::SavedRVal) -> state
    ordered_map<const PHV::Field*,
                ordered_map<const PHV::Field*,
                            ordered_set<const IR::BFN::ParserState*>>> candidateSourcesInParser;

 public:
    explicit CollectEgressBridgedFields(const PhvInfo& p) : phv(p) {}

    /// Map: bridged field name -> original field name
    ordered_map<cstring, cstring> bridged_to_orig;

    Visitor::profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::BFN::Extract* extract) override;
    void end_apply() override;
};

/**
 * The inspector collects all fields extracted in parser and stores both directions
 * of mapping between source (original) fields (IR::BFN::SavedRVal)
 * and bridged (destination) fields (IR::BFN::FieldLVal).
 *
 * The information is later used to induce alignment constraints.
 *
 * <table>
 * <caption>Logging options</caption>
 * <tr>
 * <td>-Tbridged_packing:5
 * <td>
 * - The fields being extracted to in parser
 * </table>
 */
class GatherParserExtracts : public Inspector {
 public:
    using FieldToFieldSet = ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>>;

 private:
    const PhvInfo& phv;
    /// Extracted fields (IR::BFN::FieldLVal -> IR::BFN::SavedRVal)
    FieldToFieldSet parserAlignedFields;
    /// Extracted fields (IR::BFN::SavedRVal -> IR::BFN::FieldLVal)
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

/**
 * The inspector collects all header/metadata/digest field list fields
 * with the \@flexible annotation and builds both directions of mapping
 * between digest field list fields and their source header/metadata fields.
 *
 * The information would be later used to induce alignment constraints.
 * **However, it is not currently being used anywhere.**
 *
 * <table>
 * <caption>Logging options</caption>
 * <tr>
 * <td>-Tbridged_packing:1
 * <td>
 * - The header/metadata/digest field list fields with the \@flexible annotation
 *   and header/metadata/digest field list type names
 * </table>
 */
class GatherDigestFields : public Inspector {
 public:
    using FieldToFieldSet = ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>>;

 private:
    const PhvInfo& phv;
    ordered_map<cstring, ordered_set<std::vector<const PHV::Field*>>> headers;
    ordered_map<cstring, ordered_set<std::vector<const PHV::Field*>>> digests;
    FieldToFieldSet digestFieldMap;
    FieldToFieldSet reverseDigestFieldMap;

    /// Made private to make sure the pass is not used anywhere
    const FieldToFieldSet& getDigestMap() const { return digestFieldMap; }
    /// Made private to make sure the pass is not used anywhere
    const FieldToFieldSet& getReverseDigestMap() const { return reverseDigestFieldMap; }

 public:
    explicit GatherDigestFields(const PhvInfo& p) : phv(p) { }
    bool preorder(const IR::BFN::DigestFieldList* fl) override;
    bool preorder(const IR::HeaderOrMetadata* hdr) override;
    void end_apply() override;
};

using AlignmentConstraint = Constraints::AlignmentConstraint;
using SolitaryConstraint = Constraints::SolitaryConstraint;

/**
 * The inspector induces alignment constraints for bridged fields based on the information
 * collected in the CollectIngressBridgedFields, CollectEgressBridgedFields,
 * GatherParserExtracts, GatherDigestFields, and ActionPhvConstraints passes,
 * and updates PhvInfo.
 *
 * \par no_split and no_split_container_size constraints
 * The alignment constraint analysis may collect multiple alignment constraints
 * on a single bridged field. In this case, the bridge packing algorithm must
 * pick one of the alignment constraint as the final alignment for packing. If
 * the selected alignment constraint is derived from a source field that span
 * across byte boundary, then we generate additional no_split and
 * no_split_container_size constraint on the bridged field. E.g.,
 * if the alignment requirement is bit 6 with a field size of 6, then the
 * no_split constraint is 1 and no_split_container_size is round_up(6 + 6).
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
 * @pre XXX(hanw): The Alias pass TODO why
 */
class GatherAlignmentConstraints : public PassManager {
 private:
    CollectIngressBridgedFields collectIngressBridgedFields;
    CollectEgressBridgedFields  collectEgressBridgedFields;
    GatherParserExtracts        collectParserAlignedFields;
    GatherDigestFields          collectDigestFields;  // Outputs currently not used

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

/**
 * Represents constraints induced in the ConstraintSolver class in the form
 * header -> constraint type -> description of constraint.
 */
using DebugInfo = ordered_map<cstring, ordered_map<cstring, ordered_set<cstring>>>;

/**
 * \brief The class uses the Z3 solver to generate packing for a set of %PHV fields
 *        given a set of constraints.
 *
 * The constraints for the Z3 solver are determined using the information from PhvInfo
 * for the set of %PHV fields delivered using the ConstraintSolver::add_constraints
 * and ConstraintSolver::add_mutually_aligned_constraints methods.
 *
 * The method ConstraintSolver::solve executes the Z3 solver and it returns,
 * for each header, a vector of fields whose offset is adjusted based on the
 * solution of the Z3 solver with padding fields inserted where necessary.
 *
 * <table>
 * <caption>Logging options</caption>
 * <tr>
 * <td>-Tbridged_packing:1
 * <td>
 * - The fields the constraints are being added for to the Z3 solver
 * - The constraints being added to the Z3 solver
 * <tr>
 * <td>-Tbridged_packing:3
 * <td>
 * - The Z3 solver model in the case of a satisfied solution
 * - The Z3 solver core in the case of an unsatisfied solution
 * <tr>
 * <td>-Tbridged_packing:5
 * <td>
 * - The Z3 solver assertions
 * </table>
 *
 * @pre Up-to-date PhvInfo.
 */
class ConstraintSolver {
    const PhvInfo& phv;
    z3::context& context;
    z3::optimize& solver;
    /// Stores induced per-header-per-type constraints in a human-readable form.
    /// For use outside of this class.
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

/**
 * The class adjusts the packing of headers/metadata/digest field lists
 * that contain the fields with the \@flexible annotation whose width is
 * not a multiply of eight bits.
 *
 * The candidates for packing adjustment can be delivered through the constructor.
 * This approach is used for bridged headers. If the list of candidates
 * (PackWithConstraintSolver::candidates) is empty, the inspector looks
 * for the candidates among all headers/metadata (IR::HeaderOrMetadata)
 * and digest field lists (IR::BFN::DigestFieldList).
 *
 * The class then computes the optimal field packing using the constraint solver
 * (PackWithConstraintSolver::solver).
 * We modeled as a single (larger) optimization problem as opposed to multiple
 * (smaller) optimization because a field may exists in multiple flexible field
 * lists. The computed alignment for the field must be consistent across all
 * instances of the flexible field list. However, the optimizer is still
 * optimizing each field list with individual optimization goals and
 * constraints.  The number of constraints scales linearly with respect to the
 * number of fields list instances. Within each field lists, the number of
 * constraints scales at O(n^2) with respect to the number of fields.
 *
 * <table>
 * <caption>Logging options</caption>
 * <tr>
 * <td>-Tbridged_packing:1
 * <td>
 * - A list of \@flexible fields whose width is not a multiple of eight bits
 * - Original (non-\@flexible) and adjusted (\@flexible whose width in not a multiply
 *   of eight bits) fields being used in the adjusted headers/metadata/digest field lists
 * - Adjusted headers/metadata/digest field lists
 * <tr>
 * <td>-Tbridged_packing:3
 * <td>
 * - Which digest field list is being processed
 * <tr>
 * <td>-Tbridged_packing:5
 * <td>
 * - Print candidates to pack and when a header/metadata/digest field list is skipped
 * </table>
 *
 * @pre Up-to-date PhvInfo.
 */
class PackWithConstraintSolver : public Inspector {
    const PhvInfo& phv;
    /// The constraint solver wrapping the Z3 solver to be used for adjusted packing
    /// of \@flexible fields whose width is not a multiply of eight bits
    ConstraintSolver& solver;
    /// A list of candidates to be processed.
    /// If empty, the candidates are found by this inspector.
    const ordered_set<cstring>& candidates;

    /// Adjusted packing
    ordered_map<cstring, const IR::Type_StructLike*>& repackedTypes;

    /// An ordered set of \@flexible fields whose width is not a multiply of eight bits
    /// for each header/metadata/digest field list
    ordered_map<cstring, ordered_set<const PHV::Field*>> nonByteAlignedFieldsMap;
    /// An ordered set of \@flexible fields whose width is a multiply of eight bits
    /// for each header/metadata/digest field list
    ordered_map<cstring, ordered_set<const PHV::Field*>> byteAlignedFieldsMap;
    /// A mapping from \@flexible PHV::Field to the corresponding IR::StructField
    /// for each header/metadata/digest field list
    ordered_map<cstring, ordered_map<const PHV::Field*, const IR::StructField*>>
                                                         phvFieldToStructFieldMap;
    /// A mapping from header/metadata/digest field list name to the corresponding
    /// IR::Type_StructLike for each header/metadata/digest field list
    ordered_map<cstring, const IR::Type_StructLike*>     headerMap;

 public:
    explicit PackWithConstraintSolver(const PhvInfo& p,
            ConstraintSolver& solver,
            const ordered_set<cstring>& c,
            ordered_map<cstring, const IR::Type_StructLike*>& r):
        phv(p), solver(solver), candidates(c), repackedTypes(r) {}

    Visitor::profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::HeaderOrMetadata* hdr) override;
    bool preorder(const IR::BFN::DigestFieldList* dfl) override;
    void end_apply() override;

    void optimize();
    void solve();
};

/**
 * The inspector looks for the phase0 and resubmit headers and adds their adjusted
 * versions to the PadFixedSizeHeaders::repackedTypes map. The adjusted versions
 * include a padding so that the headers have hardware-defined sizes.
 */
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

/**
 * The transformer replaces specified headers/metadata/digest field lists
 * with adjusted versions. The adjusted versions are to be delivered through
 * the constructor (ReplaceFlexibleType::repackedTypes).
 *
 * The transformer works both with midend and backend IR.
 */
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
