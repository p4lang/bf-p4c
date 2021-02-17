#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_CLOT_INFO_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_CLOT_INFO_H_

#include <algorithm>

#include "clot.h"
#include "deparse_graph.h"
#include "field_slice_set.h"
#include "pseudoheader.h"
#include "lib/ordered_map.h"
#include "bf-p4c/lib/cmp.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/parde/parde_visitor.h"

class PhvInfo;

class FieldSliceExtractInfo;

class ClotInfo {
    friend class AllocateClot;
    friend class CollectClotInfo;
    friend class ClotCandidate;
    friend class GreedyClotAllocator;

    PhvUse &uses;

    /// Maps parser states to all fields extracted in that state, regardless of source.
    ordered_map<const IR::BFN::ParserState*,
                std::vector<const PHV::Field*>> parser_state_to_fields_;

    /// Maps fields to all states that extract the field, regardless of source. Each state is
    /// further mapped to the source from which the field is extracted.
    ordered_map<const PHV::Field*,
                std::unordered_map<const IR::BFN::ParserState*,
                                   const IR::BFN::ParserRVal*>> field_to_parser_states_;

    /// Maps the fields extracted from the packet in each state to the state-relative byte indices
    /// occupied by the field.
    ordered_map<const IR::BFN::ParserState*,
             ordered_map<const PHV::Field*, std::set<unsigned>>> field_to_byte_idx;

    /// Maps state-relative byte indices in each state to the fields occupying
    /// that byte.
    ordered_map<const IR::BFN::ParserState*,
             std::map<unsigned, ordered_set<const PHV::Field*>>> byte_idx_to_field;

    std::set<const PHV::Field*> checksum_dests_;
    std::map<const PHV::Field*,
              std::vector<const IR::BFN::EmitChecksum*>> field_to_checksum_updates_;

    std::vector<Clot*> clots_;
    std::map<const Clot*,
             std::pair<gress_t, std::set<cstring>>,
             Clot::Less> clot_to_parser_states_;
    std::map<gress_t, std::map<cstring, std::set<const Clot*>>> parser_state_to_clots_;

    std::map<const IR::BFN::ParserState*,
             ordered_map<const PHV::Field*, nw_bitrange>> field_range_;

    std::map<const Clot*, std::vector<const IR::BFN::EmitChecksum*>> clot_to_emit_checksum_;

    /// Maps fields to their equivalence class of aliases.
    std::map<const PHV::Field*, std::set<const PHV::Field*>*> field_aliases_;

    /// Names of headers that might be added by MAU.
    std::set<cstring> headers_added_by_mau_;

    /// Maps each field that is part of a pseudoheader to the pseudoheaders containing that field.
    std::map<const PHV::Field*, std::set<const Pseudoheader*>> field_to_pseudoheaders_;

    std::map<gress_t, DeparseGraph> deparse_graph_;

    /// Maps each field to its pov bits.
    std::map<const PHV::Field*, PovBitSet> fields_to_pov_bits_;

 public:
    explicit ClotInfo(PhvUse& uses) : uses(uses) {}

 private:
    unsigned num_clots_allocated(gress_t gress) const { return Clot::tagCnt.at(gress); }

    /// The extracted packet range of a given field for a given parser state.
    boost::optional<nw_bitrange> field_range(const IR::BFN::ParserState* state,
                                             const PHV::Field* field) const;

    /// The bit offset of a given field for a given parser state.
    boost::optional<unsigned> offset(const IR::BFN::ParserState* state,
                                     const PHV::Field* field) const;

 public:
    CollectParserInfo parserInfo;

    /// A POV is in this set if there is a path through the parser in which the field is not
    /// extracted, but its POV bit is set.
    std::set<const PHV::Field*> pov_extracted_without_fields;

    const std::map<const Clot*, std::pair<gress_t, std::set<cstring>>, Clot::Less>&
    clot_to_parser_states() const {
        return clot_to_parser_states_;
    }

    std::map<cstring, std::set<const Clot*>>& parser_state_to_clots(gress_t gress) {
        return parser_state_to_clots_.at(gress);
    }

    const std::map<cstring, std::set<const Clot*>>& parser_state_to_clots(gress_t gress) const {
        return parser_state_to_clots_.at(gress);
    }

    const Clot* parser_state_to_clot(const IR::BFN::LoweredParserState *state, unsigned tag) const;

    const std::vector<Clot*>& clots() { return clots_; }

    /// @return a map from overwrite offsets to corresponding containers.
    std::map<int, PHV::Container>
    get_overwrite_containers(const Clot* clot, const PhvInfo& phv) const;

    /// @return a map from overwrite offsets to corresponding checksum fields.
    std::map<int, const PHV::Field*> get_csum_fields(const Clot* clot) const;

    std::map<const Clot*, std::vector<const IR::BFN::EmitChecksum*>>& clot_to_emit_checksum() {
        return clot_to_emit_checksum_;
    }

    const std::map<const Clot*,
             std::vector<const IR::BFN::EmitChecksum*>>& clot_to_emit_checksum() const {
        return clot_to_emit_checksum_;
    }

 private:
    void add_field(const PHV::Field* f, const IR::BFN::ParserRVal* source,
                   const IR::BFN::ParserState* state);

    /// Populates @ref field_to_byte_idx and @ref byte_idx_to_field.
    void compute_byte_maps();

    void add_clot(Clot* clot, ordered_set<const IR::BFN::ParserState*> states);

    /// @return a set of parser states to which no more CLOTs may be allocated,
    /// because doing so would exceed the maximum number CLOTs allowed per packet.
    const ordered_set<const IR::BFN::ParserState*>* find_full_states(
            const IR::BFN::ParserGraph* graph) const;

    // A field may participate in multiple checksum updates, e.g. IPv4 fields
    // may be included in both IPv4 and TCP checksum updates. In such cases,
    // we require the IPv4 fields in both updates to be identical sets in order
    // to be allocated to a CLOT (each CLOT can only compute one checksum)
    // see P4C-1509
    bool is_used_in_multiple_checksum_update_sets(const PHV::Field* field) const;

    /// Determines whether a field is extracted in multiple states that are not mutually exclusive.
    bool is_extracted_in_multiple_non_mutex_states(const PHV::Field* f) const;

    /// Returns true when all paths that set @field's pov bit also extracts @field
    bool extracted_with_pov(const PHV::Field* field) const;

    /// Determines whether a field has the same bit-in-byte offset (i.e., the same bit offset,
    /// modulo 8) in all parser states that extract the field.
    bool has_consistent_bit_in_byte_offset(const PHV::Field* field) const;

    /// Determines whether a field can be part of a CLOT. This can include
    /// fields that are PHV-allocated.
    bool can_be_in_clot(const PHV::Field* field) const;

    /// Determines whether a field slice can be the first one in a CLOT.
    bool can_start_clot(const FieldSliceExtractInfo* extract_info) const;

    /// Determines whether a field slice can be the last one in a CLOT.
    bool can_end_clot(const FieldSliceExtractInfo* extract_info) const;

    /// Determines whether a field extracts its full width whenever it is extracted from the
    /// packet. Returns false if, in any state, the field is not extracted from the packet or is
    /// extracted from a non-packet source.
    bool extracts_full_width(const PHV::Field* field) const;

    /// Memoization table for @ref is_modified.
    mutable std::map<const PHV::Field*, bool> is_modified_;

 public:
    /// Determines whether a field is a checksum field.
    bool is_checksum(const PHV::Field* field) const;
    bool is_checksum(const PHV::FieldSlice* slice) const;

    /// Determines whether a field is modified, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    bool is_modified(const PHV::Field* field) const;
    bool is_modified(const PHV::FieldSlice* slice) const;

    /// Determines whether a field is read-only, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    bool is_readonly(const PHV::Field* field) const;
    bool is_readonly(const PHV::FieldSlice* slice) const;

    /// Determines whether a field is unused, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    bool is_unused(const PHV::Field* field) const;
    bool is_unused(const PHV::FieldSlice* slice) const;

    /// Produces the set of CLOT-eligible fields.
    const std::set<const PHV::Field*>* clot_eligible_fields() const;

    /// @return nullptr if the @arg field is read-only or modified. Otherwise, if the @arg field is
    /// unused, returns a map from each CLOT-allocated slice for the field to its corresponding
    /// CLOT.
    std::map<const PHV::FieldSlice*, Clot*, PHV::FieldSlice::Greater>*
    allocated_slices(const PHV::Field* field) const {
        return is_unused(field) ? slice_clots(field) : nullptr;
    }

    /// @return nullptr if the field containing the @arg slice is read-only or modified. Otherwise,
    /// if the field containing the @arg slice is unused, returns each CLOT-allocated slice that
    /// overlaps with the given @arg slice, mapped to its corresponding CLOT.
    //
    // If we had more precise slice-level usage information, we could instead return a non-null
    // result if the given slice were unused.
    std::map<const PHV::FieldSlice*, Clot*, PHV::FieldSlice::Greater>*
    allocated_slices(const PHV::FieldSlice* slice) const {
        return is_unused(slice->field()) ? slice_clots(slice) : nullptr;
    }

    /// @return the given field's CLOT if the field is unused and is entirely covered in a CLOT.
    /// Otherwise, nullptr is returned.
    const Clot* fully_allocated(const PHV::Field* field) const {
        return is_unused(field) ? whole_field_clot(field) : nullptr;
    }

    /// @return the given field slice's CLOT allocation if the field containing the slice is unused
    /// and the slice is entirely CLOT-allocated. Otherwise, nullptr is returned.
    //
    // If we had more precise slice-level usage information, we could instead return a non-null
    // result if the given slice were unused.
    std::set<const Clot*, Clot::Less>* fully_allocated(const PHV::FieldSlice& slice) const {
        return fully_allocated(&slice);
    }

    /// @return the given field slice's CLOT allocation if the field containing the slice is unused
    /// and the slice is entirely CLOT-allocated. Otherwise, nullptr is returned.
    //
    // If we had more precise slice-level usage information, we could instead return a non-null
    // result if the given slice were unused.
    std::set<const Clot*, Clot::Less>* fully_allocated(const PHV::FieldSlice* slice) const;

    /// Adjusts all allocated CLOTs so that they neither start nor end with an overwritten field
    /// slice. See
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU/edit#bookmark=id.42g1j75kjqs5
    void adjust_clots(const PhvInfo& phv);

 private:
    /// Adjusts a CLOT so that it neither starts nor ends with an overwritten field slice. See
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU/edit#bookmark=id.42g1j75kjqs5
    ///
    /// @return true if the CLOT is non-empty as a result of the adjustment.
    bool adjust(const PhvInfo& phv, Clot* clot);

    /// Removes bits from the start and end of the given @arg clot.
    void crop(Clot* clot, unsigned start_bits, unsigned end_bits);

    void crop(Clot* clot, unsigned num_bits, bool from_start);

 public:
    /// Determines whether a field slice in a CLOT will be overwritten by a PHV container or a
    /// checksum calculation when deparsed. See
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    ///
    /// @return true when @arg f is a field slice covered by @arg clot and at least part of @arg f
    ///         will be overwritten by a PHV container or a checksum calculation when deparsed.
    bool slice_overwritten(const PhvInfo& phvInfo,
                           const Clot* clot,
                           const PHV::FieldSlice* f) const;

    /// Determines whether a field slice in a CLOT will be overwritten by a PHV container when
    /// deparsed. See
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    ///
    /// @return true when @arg f is a field slice covered by @arg clot and at least part of @arg f
    ///         will be overwritten by a PHV container when deparsed.
    bool slice_overwritten_by_phv(const PhvInfo& phvInfo,
                                  const Clot* clot,
                                  const PHV::FieldSlice* f) const;

 private:
    /// Determines which bits in the given field slice @arg f will be overwritten by a PHV
    /// container or a checksum calculation when deparsed. See
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    ///
    /// @return a bit vector with the given @arg Order, indicating those bits in @arg f that
    ///         will be overwritten.
    template<Endian Order = Endian::Network>
    bitvec bits_overwritten(const PhvInfo& phvInfo,
                            const Clot* clot,
                            const PHV::FieldSlice* f) const;

    /// Determines which bits in the given field slice @arg f will be overwritten by a PHV
    /// container when deparsed. See
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    ///
    /// @return a bit vector with the given @arg Order, indicating those bits in @arg f that
    ///         will be overwritten.
    template<Endian Order = Endian::Network>
    bitvec bits_overwritten_by_phv(const PhvInfo& phvInfo,
                                   const Clot* clot,
                                   const PHV::FieldSlice* f) const;

 public:
    /// Determines whether @arg h is a header that might be added by MAU.
    bool is_added_by_mau(cstring h) const;

    /// @return the CLOT-allocated slices that overlap with the given @arg slice, mapped to the
    /// corresponding CLOTs.
    std::map<const PHV::FieldSlice*, Clot*, PHV::FieldSlice::Greater>*
    slice_clots(const PHV::FieldSlice* slice) const;

    /// @return the CLOT-allocated slices of the given @arg field, mapped to the CLOTs containing
    /// those slices.
    std::map<const PHV::FieldSlice*, Clot*, PHV::FieldSlice::Greater>*
    slice_clots(const PHV::Field* field) const {
        return slice_clots(new PHV::FieldSlice(field));
    }

    /// @return the CLOT containing the entirety of the given field, or nullptr if no such CLOT
    /// exists.
    Clot* whole_field_clot(const PHV::Field* field) const;

    /// @return true if the given @arg slice is covered by the given @arg clot.
    bool clot_covers_slice(const Clot* clot, const PHV::FieldSlice* slice) const;

    std::string print(const PhvInfo* phvInfo = nullptr) const;

 private:
    void add_alias(const PHV::Field* f1, const PHV::Field* f2);

    void clear();

    /// Finds the paths with the largest number of CLOTs allocated.
    ///
    /// @arg memo is a memoization table that maps each visited parser state to the corresponding
    ///     result of the recursive call.
    ///
    /// @return the maximum number of CLOTs allocated on paths starting at the given @arg state,
    ///     paired with the aggregate set of nodes on those maximal paths.
    //
    // DANGER: This function assumes the parser graph is a DAG.
    std::pair<unsigned, ordered_set<const IR::BFN::ParserState*>*>* find_largest_paths(
            const std::map<cstring, std::set<const Clot*>>& parser_state_to_clots,
            const IR::BFN::ParserGraph* graph,
            const IR::BFN::ParserState* state,
            std::map<const IR::BFN::ParserState*,
                     std::pair<unsigned,
                               ordered_set<const IR::BFN::ParserState*>*>*>* memo = nullptr) const;
};

class CollectClotInfo : public Inspector {
    const PhvInfo& phv;
    ClotInfo& clotInfo;
    Logging::FileLog* log = nullptr;

 public:
    explicit CollectClotInfo(const PhvInfo& phv, ClotInfo& clotInfo) :
        phv(phv), clotInfo(clotInfo) {}

 private:
    Visitor::profile_t init_apply(const IR::Node* root) override;

    /// Collects the set of fields extracted.
    bool preorder(const IR::BFN::Extract* extract) override;

    /// Collects the set of POV bits on which each field's emit is predicated.
    bool preorder(const IR::BFN::EmitField* emit) override;

    /// Identifies checksum fields, collects the set of fields over which checksums are computed,
    /// and collects the set of POV bits on which each field's emit is predicated.
    bool preorder(const IR::BFN::EmitChecksum* emit) override;

    /// Uses @ref fields_to_pov_bits to identify pseudoheaders.
    void postorder(const IR::BFN::Deparser* deparser) override;

    /// Helper.
    ///
    /// Does nothing if @arg fields is empty. Otherwise, adds a new pseudoheader with the given
    /// @arg pov_bits and @arg fields, if one hasn't already been allocated.
    void add_pseudoheader(const PovBitSet pov_bits,
                          const std::vector<const PHV::Field*> fields,
                          std::map<std::pair<const PovBitSet,
                                             const std::vector<const PHV::Field*>>,
                                   const Pseudoheader*>& allocated);

    /// Collects aliasing information.
    bool preorder(const IR::BFN::AliasMember* alias) override {
        add_alias_field(alias);
        return true;
    }

    /// Collects aliasing information.
    bool preorder(const IR::BFN::AliasSlice* alias) override {
        add_alias_field(alias);
        return true;
    }

    void add_alias_field(const IR::Expression* alias);

    /// Collects the set of headers that are made valid by MAU.
    bool preorder(const IR::MAU::Instruction* instruction) override;

    void end_apply(const IR::Node* root) override;
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_CLOT_INFO_H_ */
