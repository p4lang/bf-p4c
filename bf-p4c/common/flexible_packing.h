#ifndef EXTENSIONS_BF_P4C_COMMON_FLEXIBLE_PACKING_H_
#define EXTENSIONS_BF_P4C_COMMON_FLEXIBLE_PACKING_H_

#include "ir/ir.h"
#include "lib/symbitmatrix.h"
#include "bf-p4c/logging/pass_manager.h"
#include "bf-p4c/common/map_tables_to_actions.h"
#include "bf-p4c/mau/action_mutex.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/common/bridged_metadata_replacement.h"

using RepackedHeaderTypes = ordered_map<cstring, const IR::Type_StructLike*>;

bool findFlexibleAnnotation(const IR::Type_StructLike*);

/// This class gathers all the bridged metadata fields also used as deparser parameters. The
/// CollectPhvInfo pass sets the deparsed_bottom_bits() property for all deparser parameters to
/// true. Therefore, this alignment constraint needs to be recognized and respected during bridged
/// metadata packing.
class GatherDeparserParameters : public Inspector {
 private:
    const PhvInfo& phv;
    /// Set of detected deparser parameters.
    ordered_set<const PHV::Field*>& params;

    profile_t init_apply(const IR::Node* root) override {
        params.clear();
        return Inspector::init_apply(root);
    }

    bool preorder(const IR::BFN::DeparserParameter* p) override;

 public:
    explicit GatherDeparserParameters(const PhvInfo& p, ordered_set<const PHV::Field*>& f)
            : phv(p), params(f) { }
};

/// This class identifies all fields initialized in the parser during Phase 0. The output of this
/// pass is used later by RepackFlexHeaders as follows: If a bridged field is also initialized in
/// Phase 0, then that field is not packed with any other field.
class GatherPhase0Fields : public Inspector {
 private:
    const PhvInfo& phv;
    /// Set of all fields initialized in phase 0.
    ordered_set<const PHV::Field*>& noPackFields;
    static constexpr char const *PHASE0_PARSER_STATE_NAME = "ingress::$phase0";

    profile_t init_apply(const IR::Node* root) override {
        noPackFields.clear();
        return Inspector::init_apply(root);
    }

    bool preorder(const IR::BFN::ParserState* p) override;

    bool preorder(const IR::BFN::DigestFieldList* d) override;

 public:
    explicit GatherPhase0Fields(
            const PhvInfo& p,
            ordered_set<const PHV::Field*>& f)
            : phv(p), noPackFields(f) { }
};

/// This class identifies all metadata fields that have alignment constraints due to initialization
/// by SavedRVals in the parser.
class GatherParserExtracts : public Inspector {
 public:
    using FieldToFieldSet = ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>>;

 private:
    const PhvInfo& phv;
    /// Map of all fields with alignment constraints due to initialization in the parser with values
    /// being the field they are initialized to.
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

// Gather egress bridge metadata map
class GatherAliasConstraintsInEgress : public Inspector {
    const PhvInfo& phv;
    ordered_map<const PHV::Field*,
        ordered_map<const PHV::Field*,
        ordered_set<const IR::BFN::ParserState*>>> candidateSourcesInParser;

 public:
    explicit GatherAliasConstraintsInEgress(const PhvInfo& p) : phv(p) {}

    /// Key: Bridged field name, Value: Original field name.
    ordered_map<cstring, cstring> bridged_to_orig;

    bool preorder(const IR::BFN::Extract* extract) override;
    void end_apply() override;
};

/** This class analyzes all bridged metadata headers, which until this point, insert padding to byte
  * alignment after every nonbyte aligned bridged metadata field. This pass takes into account
  * action-related as well as some alignment related constraints (such as deparser_bottom_bits() set
  * for DeparserParameters) and creates new bridged metadata headers that potentially have fewer
  * padding bits. The new header generated by RepackFlexHeaders always has the byte-aligned fields
  * at the beginning followed by the nonbyte-aligned fields with appropriate padding.
  * XXX(Deep): Right now, we do not pack bridged fields that have alignment constraints with any
  * other bridged field. In future, we could relax this requirement to achieve tighter packing of
  * bridged metadata fields.
  *
  * XXX(HanW): This class has been updated to operate on
  * ordered_set<PHV::Field*>, and should work on repacking DigestFieldList as
  * well.
  */
class RepackFlexHeaders : public Transform, public TofinoWriteContext {
 public:
    using FieldListEntry = std::pair<int, const IR::Type*>;

 public:
    static constexpr char const *INGRESS_FIELD_PREFIX = "ingress::";
    static constexpr char const *EGRESS_FIELD_PREFIX = "egress::";
    static constexpr char const *BRIDGED_INIT_ACTION_NAME = "act";

    /** @returns the name of the flex struct @flexType that is a part of the header @h.
      */
    static cstring getFlexStructName(
            const IR::HeaderOrMetadata* h,
            const IR::Type_Struct* flexType);

    /** @returns the egress version of a field name when the ingress name is specified.
     *  @returns the ingress version of a field name when the egress name is specified.
      */
    static cstring getOppositeGressFieldName(cstring name);

 protected:
    /// Not a const PhvInfo because this pass create padding PHV::Field.
    PhvInfo& phv;
    const PhvUse& uses;
    /// Reference to mapping of original P4 field to the bridged field.
    const CollectBridgedFields& fields;
    /// Alias egress bridge metadata to egress metadata
    const GatherAliasConstraintsInEgress& aliasInEgress;
    /// Reference to object used to query action-related constraints.
    const ActionPhvConstraints& actionConstraints;
    /// doNotPack(x, y) = true implies that a bridged field with id x cannot be packed with another
    /// bridged field with id y.
    SymBitMatrix& doNotPack;
    /// Set of all fields initialized in phase 0.
    const ordered_set<const PHV::Field*>& noPackFields;
    /// Set of all fields used as deparser parameters.
    const ordered_set<const PHV::Field*>& deparserParams;
    /// Set of all fields with alignment constraints induced by the parser.
    const GatherParserExtracts& parserAlignedFields;

    /** Map of original egress field name to the field name in the egress bridged metadata header.
      * E.g. egress::ingress_metadata.ingress_port is the original backenrepackedHeadersd name for a field, and
      * egress::^bridged_metadata.md_ingress_metadata_ingress_port is the name of the field
      * generated as part of egress bridged header. This map maintains the correspondence between
      * the two.
      */
    ordered_map<cstring, cstring> egressBridgedMap;

    /** Map of field name in the egress bridged metadata header to the original egress field name.
      */
    ordered_map<cstring, cstring> reverseEgressBridgedMap;

    /** Map of original field to a related field from which this field will derive its alignment
      * constraints from.
      */
    ordered_map<const PHV::Field*, const PHV::Field*> fieldAlignmentMap;

    /** List of all padding field names generated during the repacking of flexible headers.
      */
    ordered_set<cstring> paddingFieldNames;

    /** Map of an original flexible struct type to the new type generated by reordering fields in
      * the flexible struct.
      */
    // ordered_map<const IR::Type_Struct*, const IR::Type_Struct*> ingressFlexibleTypes;
    ordered_map<const IR::HeaderOrMetadata*, const IR::HeaderOrMetadata*> ingressFlexibleTypes;

    /** Map of header to all the flexible fields in that header.
      */
    ordered_map<const IR::HeaderOrMetadata*, ordered_set<const IR::StructField*>>
            headerToFlexibleStructsMap;

    /** Map of digest field list to all the flexible fields in that digest field list.
     */
    ordered_map<const IR::BFN::DigestFieldList*, ordered_set<const IR::StructField*>>
            digestToFlexibleStructsMap;

    /** Map of header name to the new header type produced after repacking.
      */
    ordered_map<cstring, const IR::HeaderOrMetadata*> repackedHeaders;

    /** Map of field to all the fields that are required to be in the same supercluster.
      * Transitive closure over MAU instructions.
      */
    ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>> clusterFields;

    /**
     * Reference to a map of header type to new header type produced after packing.
     *
     * This map is shared between RepackDigestFieldList and RepackFlexHeaders,
     * both passes modify the map. RepackDigestFieldList modifies it first,
     * RepackFlexHeaders read and modifies the map next.
     */
    RepackedHeaderTypes& repackedTypes;

    /**
     * Map of header name ot the old header type before repacking.
     */
    ordered_map<cstring, const IR::HeaderOrMetadata*> originalHeaders;

    /** Map of all candidate flexible fields that are used in digests. The padding for these fields
      * cannot be overlaid with other fields, and these fields cannot be packed with other fields to
      * prevent pollution of the digest.
      */
    ordered_set<const PHV::Field*> digestFlexFields;

    /**
     *
     */
    boost::optional<const IR::HeaderOrMetadata*> checkIfAlreadyPacked(const IR::HeaderOrMetadata*);

    /**
     * mkPhvFieldSet : take IR::HeaderOrMetadata, generate a set of PHV::Field that must be packed.
     */
    const ordered_set<const PHV::Field*> mkPhvFieldSet(const IR::HeaderOrMetadata* h);

    /**
     * zip DigestFieldList->sources and DigestFieldList->type->fields.
     */
    const std::vector<std::tuple<const IR::StructField*, const IR::BFN::FieldLVal*>>
        zipDigestSourcesAndTypes(const IR::BFN::DigestFieldList* d);

    const std::map<const PHV::Field*, const IR::StructField*>
        getPhvFieldToStructFieldMap(const IR::BFN::DigestFieldList* d);

    /**
     * mkPhvFieldSet : take IR::DigestFieldList, generate a set of PHV::Field that must be packed.
     */
    const ordered_set<const PHV::Field*> mkPhvFieldSet(const IR::BFN::DigestFieldList* d);

    int getPackSize(const PHV::Field* f) const;

    /**
     * packPhvFieldSet : take a set of PHV::Field, pack the set and return the packing.
     */
    // using PhvFieldPacking = pair<std::vector<const PHV::Field*>, std::vector<int>>;
    const std::vector<const PHV::Field*>
        packPhvFieldSet(const ordered_set<const PHV::Field*>& fieldsToBePacked);

    void determineClusterFields(const PHV::Field* f);

    /** @repacks the fields by checking no pack conflicts in 32b chunks across the header.
      */
    const std::vector<const PHV::Field*>
        verifyPackingAcrossBytes(const std::vector<const PHV::Field*>& fields) const;

    /** @returns true if header @h contains a flexible struct that can be reordered by the compiler.
      */
    bool isFlexibleHeader(const IR::HeaderOrMetadata* h);
    bool isFlexibleHeader(const IR::BFN::DigestFieldList* d);

    /** Action analysis for the set of @nonByteAlignedFields in header @h. It populates the
      * doNotPack matrix based on results of this analysis.
      *
      * @param alignmentConstraints will be populated with the alignment of must-pack fields.
      *
      * @returns a matrix of fields that must be packed together.
      */
    SymBitMatrix bridgedActionAnalysis(
        std::vector<const PHV::Field*>& fieldsToBePacked,
        ordered_map<const PHV::Field*, le_bitrange>& alignmentConstraints);

    void updateNoPackForDigestFields(const std::vector<const PHV::Field*>& nonByteAlignedFields,
            const SymBitMatrix& mustPack);

    /// Pretty print a no-pack constraint determined by bridgedActionAnalysis.
    void printNoPackConstraint(
            cstring errorMessage,
            const PHV::Field* f1,
            const PHV::Field* f2) const;

    /** Returns a map of field to starting position within the nearest byte aligned chunk for fields
      * that can be packed in the bridged metadata header @h with field @f in the same byte.
      * @alignment is the number of bits available for packing.
      * @candidates are the candidate fields for bridged metadata packing.
      * @alreadyPackedFields are the list of bridged fields that have already been packed.
      * @alignmentConstraints refers to the alignment constarints on bridged fields.
      * @conflictingAlignmentConstraints refers to the set of fields that may have mutually
      * conflicting alignment constraints, and hence may never be packed together.
      */
    ordered_map<const PHV::Field*, int> packWithField(
            const int alignment,
            const PHV::Field* f,
            const ordered_set<const PHV::Field*>& candidates,
            const ordered_set<const PHV::Field*>& alreadyPackedFields,
            const ordered_map<const PHV::Field*, le_bitrange>& alignmentConstraints,
            const ordered_map<const PHV::Field*, std::set<int>>&
            conflictingAlignmentConstraints,
            const SymBitMatrix& mustPack) const;

    /** Given the map of alignment constraints for fields @alignmentConstraints, a set of
      * potentially packable fields @potentiallyPackableFields and the base field @f, @return the
      * list of fields that must be eliminated from consideration to avoid alignment conflicts. E.g.
      * if field A (2b) must be packed in bits 2-3, and field B (3b) must be packed in bits 1-3,
      * then field B is added to the set to the be returned (always pick the smaller sized fields as
      * the reason for alignment conflict).
      */
    ordered_set<const PHV::Field*> checkPotentialPackAlignmentReqs(
            const ordered_map<const PHV::Field*, le_bitrange>& alignmentConstraints,
            ordered_set<const PHV::Field*>& potentiallyPackableFields,
            const PHV::Field* f) const;

    /** Determine alignment constraints associated with the set of @nonByteAlignedFields in header
      * @h. The result is stored in the @alignmentConstraints map.
      * @alignmentConstraints stores the actual alignment constraints.
      * @conflictingAlignmentConstraints stores fields with conflicting alignment constraints.
      * @mustAlignFields stores fields that must be aligned at the given alignment (as opposed to
      * may-align).
      */
    void determineAlignmentConstraints(
            const std::vector<const PHV::Field*>& fieldsToBePacked,
            ordered_map<const PHV::Field*, le_bitrange>& alignmentConstraints,
            ordered_map<const PHV::Field*, std::set<int>>& conflictingAlignmentConstraints,
            ordered_map<const PHV::Field*, le_bitrange>& nonNegotiableAlignments,
            ordered_set<const PHV::Field*>& mustAlignFields);

    /** @returns all the actions in which both @field1 and @field2 are accessed. @returns an empty
      * set if the fields are never written in the same action. @acts contains mapping of fields to
      * the actions in which they are accessed. @written is passed as true if @acts summarizes
      * writes, and false if @acts summarizes reads.
      */
    ordered_set<const IR::MAU::Action*> fieldsAccessedSameAction(
            const PHV::Field* field1,
            const PHV::Field* field2,
            const ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Action*>>& acts,
            bool written = true) const;

    /**
     * @param alignmentConstraints will be populated with the alignment of must-pack fields.
     *
     * @returns a matrix in which matrix(f1->id, f2->id) = true, if fields @f1 and @f2 in @fields
     * must be packed together within the same byte.
     */
    SymBitMatrix mustPack(const ordered_set<const PHV::Field*>& fields,
        ordered_map<const PHV::Field*, le_bitrange>& alignmentConstraints) const;

    /** If the fields @f1 and @f2 must be packed together and @actions is the set of actions where
      * these fields are written, @returns a map of the field and its corresponding required
      * alignment.
      */
    boost::optional<ordered_map<const PHV::Field*, int>> mustBePackedTogether(
            const PHV::Field* f1,
            const PHV::Field* f2,
            const ordered_set<const IR::MAU::Action*>& actions) const;

    /** @returns true if the bridged field @field must be packed at the alignment determined by
      * determineAlignmentConstraints.
      */
    bool mustAlign(const PHV::Field* field) const;

    /** @returns a field object of @size bits and with the unique @id in its name. The format of the
      * padding field is __pad_id.
      */
    const IR::StructField* getPaddingField(int size, int id, bool overlay = true) const;

    /** Clear state for member objects. Also, extract bridged header information from the
      * CollectBridgedFields pass into maps accessible locally.
      */
    profile_t init_apply(const IR::Node* root) override;

    /** Examine each header, and initiate the repacking if any flexible structs are found in that
      * header. @returns a new header with repacked flexible structs, and with all structs flattened
      * into a list of fields.
      */
    const IR::Node* preorder(IR::HeaderOrMetadata* h) override;
    const IR::Node* preorder(IR::BFN::Pipe* p) override;

    // constraint pretty printer
    void print_alignment_constraints();

    void resetState();

 public:
    explicit RepackFlexHeaders(
        PhvInfo& p,
        const PhvUse& u,
        const CollectBridgedFields& f,
        const GatherAliasConstraintsInEgress& g,
        const ActionPhvConstraints& a,
        SymBitMatrix& s,
        const ordered_set<const PHV::Field*>& z,
        const ordered_set<const PHV::Field*>& d,
        const GatherParserExtracts& pa,
        RepackedHeaderTypes& rt)
        : phv(p), uses(u), fields(f), aliasInEgress(g),
          actionConstraints(a), doNotPack(s), noPackFields(z),
          deparserParams(d), parserAlignedFields(pa), repackedTypes(rt) {}

    /// @returns the set of all repacked headers.
    const ordered_map<cstring, const IR::HeaderOrMetadata*> getRepackedHeaders() const {
        return repackedHeaders;
    }

    /// @returns the repack map of all repacked headers.
    const ordered_map<cstring, const IR::HeaderOrMetadata*> getOriginalHeaders() const {
        return originalHeaders;
    }

    /// @returns a reference to the structure that maps the original egress field name to the field
    /// name in the egress bridged metadata header.
    const ordered_map<cstring, cstring>& getEgressBridgedMap() const {
        return egressBridgedMap;
    }

    /// @returns the non-bridged egress header version of a field with name @fName.
    cstring getNonBridgedEgressFieldName(cstring fName) const;

    /// @returns the size of the header in bits.
    int getHeaderBits(const IR::HeaderOrMetadata* h) const;

    /// @returns the size of the header in bits.
    int getHeaderBits(const IR::BFN::DigestFieldList* d) const;

    /// @returns the size of the header in bytes. Errors out if the header is not byte-aligned, so
    /// use this carefully.
    int getHeaderBytes(const IR::HeaderOrMetadata* h) const;

    /// @returns the size of the flexible struct type in bits.
    unsigned getFlexTypeBits(const IR::Type_Struct* flexType) const;

    /// @returns true if there are any common actions in the two sets @set1 and @set2.  Analysis
    /// does not consider the action 'act' added specifically for bridged metadata initialization.
    bool hasCommonAction(
            ordered_set<const IR::MAU::Action*>& set1,
            ordered_set<const IR::MAU::Action*>& set2) const;

    /** @returns the backend name of the field, given the @header and the the @field.
      * This performs a simple string concatenation.
      */
    cstring getFieldName(cstring hdr, const IR::StructField* field) const;

    const ordered_map<const IR::HeaderOrMetadata*, ordered_set<const IR::StructField*>>&
    getHeaderToFlexibleStructsMap() const {
        return headerToFlexibleStructsMap;
    }

    const ordered_set<cstring>& getPaddingFieldNames() const {
        return paddingFieldNames;
    }

    void repackFlexibleHeader(const IR::Type* type, cstring name);

    const IR::BFN::DigestFieldList* repackFieldList(
            cstring name,
            std::vector<FieldListEntry>,
            const IR::Type_StructLike* repackedHeaderType,
            const IR::BFN::DigestFieldList*) const;

    friend class RepackDigestFieldList;
};

/**
 * IR::BFN::DigestFieldList packing must be done before IR::HeaderOrMetadata
 * packing as there are more alignment constraints to the digest field list
 * that is not known during IR::HeaderOrMetadata packing.
 *
 * Unfortunately, compiler visits IR::HeaderOrMetadata before
 * IR::BFN::DigestFieldList. We had to separate the digest packing into a
 * different pass while sharing most of the code via subclassing.
 *
 * visitor to IR::HeaderOrMetadata* is nulled in this pass.
 */
class RepackDigestFieldList : public RepackFlexHeaders {
 public:
    explicit RepackDigestFieldList(
            PhvInfo& p,
            const PhvUse& u,
            const CollectBridgedFields& f,
            const GatherAliasConstraintsInEgress& g,
            const ActionPhvConstraints& a,
            SymBitMatrix& s,
            const ordered_set<const PHV::Field*>& z,
            const ordered_set<const PHV::Field*>& d,
            const GatherParserExtracts& pa,
            RepackedHeaderTypes& rt)
        : RepackFlexHeaders(p, u, f, g, a, s, z, d, pa, rt) { }

    profile_t init_apply(const IR::Node* root) override;
    const IR::Node* preorder(IR::HeaderOrMetadata* h) override { return h; }
    const IR::Node* preorder(IR::BFN::Pipe* p) override { return p; }
    const IR::Node* preorder(IR::BFN::DigestFieldList* d) override;
};

// A map from the original field index to the repacked field index,
// This is used to reorder the flattened field list in emit calls.
using RepackedFieldIndexMap = std::map<int, int>;

using RepackedHeaders = std::vector<std::pair<const IR::HeaderOrMetadata*, std::string>>;

class LogRepackedHeaders : public Inspector {
 private:
    // Need this for field names
    const PhvInfo& phv;
    // Contains all of the (potentially) repacked headers
    RepackedHeaders repacked;
    // All headers we have seen before, but with "egress" or "ingress" removed (avoid duplication)
    std::unordered_set<std::string> hdrs;

    // Collects all headers/metadatas that may have been repacked (i.e. have a field that is
    // flexible)
    bool preorder(const IR::HeaderOrMetadata* h) override;

    // Pretty print all of the flexible headers
    void end_apply() override;

    // Returns the full field name
    std::string getFieldName(std::string hdr, const IR::StructField* field) const;

    // Pretty prints a single header/metadata
    std::string pretty_print(const IR::HeaderOrMetadata* h, std::string hdr);

    // Strips the given prefix from the front of the cstring, returns as string
    std::string strip_prefix(cstring str, std::string pre);

 public:
    explicit LogRepackedHeaders(const PhvInfo& p) : phv(p) { }

    std::string asm_output() const;
};

class LogFlexiblePacking : public Logging::PassManager {
    LogRepackedHeaders* flexibleLogging;

 public:
    explicit LogFlexiblePacking(const PhvInfo& phv) :
    Logging::PassManager("flexible_packing", Logging::Mode::AUTO) {
        flexibleLogging = new LogRepackedHeaders(phv);
        addPasses({
            flexibleLogging,
        });
    }

    const LogRepackedHeaders *get_flexible_logging() const { return flexibleLogging; }
};

class FlexiblePacking : public PassManager {
 private:
    const BFN_Options&                                  options;
    CollectBridgedFields&                               bridgedFields;
    GatherAliasConstraintsInEgress                      aliasInEgress;
    MauBacktracker                                      table_alloc;
    PackConflicts                                       packConflicts;
    MapTablesToActions                                  tableActionsMap;
    ActionPhvConstraints                                actionConstraints;
    GatherParserExtracts                                parserAlignedFields;
    RepackDigestFieldList                               packDigestFieldLists;
    RepackFlexHeaders                                   packHeaders;
    SymBitMatrix                                        doNotPack;
    TablesMutuallyExclusive                             tMutex;
    ActionMutuallyExclusive                             aMutex;
    ordered_set<const PHV::Field*>                      noPackFields;
    ordered_set<const PHV::Field*>                      deparserParams;
    RepackedHeaderTypes                                 repackedTypes;

 public:
    explicit FlexiblePacking(
            PhvInfo& p,
            const PhvUse& u,
            DependencyGraph& dg,
            const BFN_Options &o,
            CollectBridgedFields& b);

    // Return a Json representation of flexible headers to be saved in .bfa/context.json
    // must be called after the pass is applied
    std::string asm_output() const;

    RepackedHeaderTypes getRepackedTypes() { return repackedTypes; }
};

using ExtractedTogether = ordered_map<cstring, ordered_set<cstring>>;

// A collection of passes that rewrite the program optimize bridge metadata packing.
// Both input and output are a vector of IR::BFN::Pipe.
class PackFlexibleHeaders : public PassManager {
    std::vector<const IR::BFN::Pipe*> pipe;
    SymBitMatrix mutually_exclusive_field_ids;
    PhvInfo phv;
    PhvUse uses;
    FieldDefUse defuse;
    DependencyGraph deps;
    CollectBridgedFields bridged_fields;
    FlexiblePacking *flexiblePacking;

 public:
    explicit PackFlexibleHeaders(const BFN_Options& options);

    RepackedHeaderTypes getPackedHeaders() { return flexiblePacking->getRepackedTypes(); }
};


#endif  /* EXTENSIONS_BF_P4C_COMMON_FLEXIBLE_PACKING_H_ */
