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

/// This class identifies all parser state that have extracted @flexible metadata, which needs
/// to be modified after the layout of the flexible header is changed.
/// This should happen before the ReplaceOriginalFieldWithBridged pass.
class GatherParserStateToModify : public Inspector {
 private:
    const PhvInfo& phv;
    ordered_set<cstring>& parserStatesToModify;

 public:
    profile_t init_apply(const IR::Node* root) override;
    bool processExtract(const IR::BFN::Extract* e);
    bool preorder(const IR::BFN::ParserState* ps) override;
    GatherParserStateToModify(const PhvInfo& p, ordered_set<cstring>& ps) :
        phv(p), parserStatesToModify(ps) {}
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

    /** @returns the egress version of a field name when the @ingressName is specified.
      */
    static cstring getEgressFieldName(cstring ingressName);

    /** @returns the ingress version of a field name when the @egressName is specified. Only works
      * if called on egress names.
      */
    static cstring getIngressFieldName(cstring egressName);

 protected:
    /// Not a const PhvInfo because this pass create padding PHV::Field.
    PhvInfo& phv;
    /// Reference to mapping of original P4 field to the bridged field.
    const CollectBridgedFields& fields;
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
    /// No pack constraints reported by MAU backtracker.
    const MauBacktracker& alloc;

    /** Map from an egress field to all other egress fields which are packed with the key field, and
      * therefore, must be extracted together.
      */
    ordered_map<cstring, ordered_set<cstring>> extractedTogether;

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

    /**
     * Reference to a map of header type to new header type produced after packing.
     *
     * This map is shared between RepackDigestFieldList and RepackFlexHeaders,
     * both passes modify the map. RepackDigestFieldList modifies it first,
     * RepackFlexHeaders read and modifies the map next.
     */
    ordered_map<const IR::Type_StructLike*, const IR::Type_StructLike*>& repackedTypes;

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

    /**
     * packPhvFieldSet : take a set of PHV::Field, pack the set and return the packing.
     */
    // using PhvFieldPacking = pair<std::vector<const PHV::Field*>, std::vector<int>>;
    const std::vector<const PHV::Field*>
        packPhvFieldSet(const ordered_set<const PHV::Field*>& fieldsToBePacked);

    /** @returns true if header @h contains a flexible struct that can be reordered by the compiler.
      */
    bool isFlexibleHeader(const IR::HeaderOrMetadata* h);
    bool isFlexibleHeader(const IR::BFN::DigestFieldList* d);

    /** Action analysis for the set of @nonByteAlignedFields in header @h. It populates the
      * doNotPack matrix based on results of this analysis. @returns a matrix of fields that must be
      * packed together.
      */
    SymBitMatrix bridgedActionAnalysis(std::vector<const PHV::Field*>& fieldsToBePacked);

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

    /** @returns a matrix in which matrix(f1->id, f2->id) = true, if fields @f1 and @f2 in @fields
      * must be packed together within the same byte.
      */
    SymBitMatrix mustPack(const ordered_set<const PHV::Field*>& fields) const;

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

    void resetState();

 public:
    explicit RepackFlexHeaders(
        PhvInfo& p,
        const CollectBridgedFields& f,
        const ActionPhvConstraints& a,
        SymBitMatrix& s,
        const ordered_set<const PHV::Field*>& z,
        const ordered_set<const PHV::Field*>& d,
        const GatherParserExtracts& pa,
        const MauBacktracker& b,
        ordered_map<const IR::Type_StructLike*, const IR::Type_StructLike*>& rt)
        : phv(p), fields(f), actionConstraints(a), doNotPack(s), noPackFields(z), deparserParams(d),
          parserAlignedFields(pa), alloc(b), repackedTypes(rt) { }

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

    const ordered_map<cstring, ordered_set<cstring>>& getExtractedTogether() const {
        return extractedTogether;
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
            const CollectBridgedFields& f,
            const ActionPhvConstraints& a,
            SymBitMatrix& s,
            const ordered_set<const PHV::Field*>& z,
            const ordered_set<const PHV::Field*>& d,
            const GatherParserExtracts& pa,
            const MauBacktracker& b,
            ordered_map<const IR::Type_StructLike*, const IR::Type_StructLike*>& rt)
        : RepackFlexHeaders(p, f, a, s, z, d, pa, b, rt) { }

    profile_t init_apply(const IR::Node* root) override;
    const IR::Node* preorder(IR::HeaderOrMetadata* h) override { return h; }
    const IR::Node* preorder(IR::BFN::Pipe* p) override { return p; }
    const IR::Node* preorder(IR::BFN::DigestFieldList* d) override;
};

class ProduceParserMappings : public Inspector {
 private:
    const PhvInfo& phv;

    ordered_map<cstring, std::vector<cstring>> parserStateToHeadersMap;
    ordered_map<cstring, const IR::HeaderOrMetadata*> headerNameToRefMap;
    ordered_map<cstring, IR::Member*> bridgedToExpressionsMap;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::BFN::ParserState* p) override;
    bool preorder(const IR::HeaderOrMetadata* h) override;

 public:
    explicit ProduceParserMappings(const PhvInfo& p) : phv(p) { }

    const std::vector<cstring> getExtractedHeaders(const IR::BFN::ParserState* p) const {
        static std::vector<cstring> empty;
        if (!parserStateToHeadersMap.count(p->name)) return empty;
        return parserStateToHeadersMap.at(p->name);
    }

    const IR::HeaderOrMetadata* getHeaderRefForName(cstring headerName) const {
        if (headerNameToRefMap.count(headerName)) return headerNameToRefMap.at(headerName);
        return nullptr;
    }

    const ordered_map<cstring, IR::Member*> getBridgedToExpressionsMap() const {
        return bridgedToExpressionsMap;
    }
};

// A map from the original field index to the repacked field index,
// This is used to reorder the flattened field list in emit calls.
using RepackedFieldIndexMap = std::map<int, int>;

/** This class takes the results of RepackFlexHeaders and for all flexible fields, changes all Emits
  * in the ingress deparser and all Extracts in the egress parser to use the newly generate flexible
  * header type.
  */
class ReplaceFlexFieldUses : public Transform {
 private:
    const PhvInfo& phv;
    const RepackFlexHeaders& pack;
    const ProduceParserMappings& info;
    ordered_map<cstring, ordered_set<cstring>>& extractedTogether;

    /// Map: Bridged field name to IR::Type*.
    ordered_map<cstring, const IR::Type*> bridgedFields;

    /// Set of parser states to be modified to reflect the repacking of headers.
    /// Collected before ReplaceOriginalFieldWithBridged pass is executed to
    /// avoid counting ingress states as state that parses bridge metadata due
    /// to the backward 'copy-propagation'.
    const ordered_set<cstring>& parserStatesToModify;

    /// Set of header names whose emits must be replaced.
    ordered_set<cstring> emitsToBeReplaced;

    /// Set of fields used as SavedRVal references, which now need to be replaced to reflect the
    /// new type of those fields post repacking.
    ordered_set<cstring> fieldsToReplace;

    ordered_map<cstring, cstring> egressBridgedMap;
    ordered_map<cstring, cstring> reverseEgressBridgedMap;

    profile_t init_apply(const IR::Node* root) override;
    IR::Node* preorder(IR::BFN::Pipe* pipe) override;
    IR::Node* preorder(IR::BFN::EmitField* e) override;
    IR::Node* preorder(IR::BFN::Extract* e) override;
    void end_apply() override;

    bool processExtract(const IR::BFN::Extract* e);
    IR::BFN::Extract* getNewSavedVal(const IR::BFN::Extract* e) const;
    boost::optional<const std::vector<IR::BFN::Extract*>>
        getNewExtracts(cstring h, unsigned& packetOffset) const;
    const std::vector<IR::BFN::EmitField*> getNewEmits(
            const IR::HeaderOrMetadata* h,
            const IR::BFN::FieldLVal* e) const;

    RepackedFieldIndexMap mkFieldIndexMap(const IR::HeaderOrMetadata* repackedHeader,
                                          const IR::HeaderOrMetadata* originalHeader) const;
    /// Add emits for the revised bridged metadata packing to the deparser.
    IR::Node* postorder(IR::BFN::Deparser* d) override;

    /// Adjusts the shift of each transition out of the egress bridged metadata header, after taking
    /// into account the new structure of the bridged metadata header.
    IR::Node* postorder(IR::BFN::ParserState* p) override;

    /// Builds up a list of all bridged metadata fields, with separate entries for ingress and
    /// egress versions. Note that this list is created by walking through the fields in the
    /// bridged_metadata headers.
    void addBridgedFields(const IR::HeaderOrMetadata* header);

 public:
    explicit ReplaceFlexFieldUses(
            const PhvInfo& p,
            const RepackFlexHeaders& pbm,
            const ProduceParserMappings& pm,
            ordered_map<cstring, ordered_set<cstring>>& e,
            ordered_set<cstring>& ps)
            : phv(p), pack(pbm), info(pm), extractedTogether(e),
            parserStatesToModify(ps) { }

    ordered_set<cstring> getBridgedFields() const {
        ordered_set<cstring> rv;
        for (auto kv : bridgedFields)
            rv.insert(kv.first);
        return rv;
    }
};

class FlexiblePacking : public Logging::PassManager {
 private:
    CollectBridgedFields&                               bridgedFields;
    PackConflicts                                       packConflicts;
    MapTablesToActions                                  tableActionsMap;
    ActionPhvConstraints                                actionConstraints;
    GatherParserExtracts                                parserAlignedFields;
    RepackDigestFieldList                               packDigestFieldLists;
    RepackFlexHeaders                                   packHeaders;
    ProduceParserMappings                               parserMappings;
    ReplaceFlexFieldUses                                bmUses;
    SymBitMatrix                                        doNotPack;
    TablesMutuallyExclusive                             tMutex;
    ActionMutuallyExclusive                             aMutex;
    ordered_set<const PHV::Field*>                      noPackFields;
    ordered_set<const PHV::Field*>                      deparserParams;
    ordered_set<cstring>                                parserStatesToModify;

    ordered_map<const IR::Type_StructLike*, const IR::Type_StructLike*> repackedTypes;

 public:
    explicit FlexiblePacking(
            PhvInfo& p,
            PhvUse& u,
            DependencyGraph& dg,
            CollectBridgedFields& b,
            ordered_map<cstring, ordered_set<cstring>>& e,
            const MauBacktracker& alloc);
};

#endif  /* EXTENSIONS_BF_P4C_COMMON_FLEXIBLE_PACKING_H_ */
