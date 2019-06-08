#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_INFO_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_INFO_H_

#include <algorithm>

#include "clot.h"
#include "lib/ordered_map.h"
#include "bf-p4c/lib/cmp.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/parde/parde_visitor.h"

class PhvInfo;

class FieldSliceExtractInfo;

/// Implements equality correctly.
class PovBitSet : public std::set<const PHV::FieldSlice*, PHV::FieldSlice::Less> {
 public:
    bool operator==(const PovBitSet& other) {
        if (size() != other.size()) return false;

        auto it1 = begin();
        auto it2 = other.begin();
        while (it1 != end()) {
            if (!PHV::FieldSlice::equal(*it1, *it2)) return false;
            ++it1;
            ++it2;
        }

        return true;
    }

    bool operator !=(const PovBitSet& other) {
        return !operator==(other);
    }
};

/// Represents a sequence of fields that are always contiguously emitted by the deparser. A
/// pseudoheader may be emitted multiple times by the deparser, each time with a different POV bit.
class Pseudoheader : public LiftLess<Pseudoheader> {
    friend class ClotInfo;

 public:
    const int id;

    /// The set of all POV bits under which this pseudoheader is emitted.
    const PovBitSet pov_bits;

    /// The sequence of fields that constitute this pseudoheader.
    const std::vector<const PHV::Field*> fields;

 private:
    static int nextId;

 public:
    explicit Pseudoheader(const PovBitSet pov_bits,
                          const std::vector<const PHV::Field*> fields)
        : id(nextId++), pov_bits(pov_bits), fields(fields) { }

    /// Lexicographic ordering on (fields, pov_bits).
    bool operator<(const Pseudoheader& other) const {
        if (fields != other.fields)
            return std::lexicographical_compare(fields.begin(), fields.end(),
                                                other.fields.begin(), other.fields.end(),
                                                PHV::Field::Less());

        return pov_bits < other.pov_bits;
    }
};

class ClotInfo {
    friend class CollectClotInfo;
    friend class ClotCandidate;
    friend class GreedyClotAllocator;

    PhvUse &uses;

    ordered_map<const IR::BFN::ParserState*,
                std::vector<const PHV::Field*>> parser_state_to_fields_;

    ordered_map<const PHV::Field*,
                std::set<const IR::BFN::ParserState*>> field_to_parser_states_;

    /// Maps the fields extracted in each state to the state-relative byte indices
    /// occupied by the field.
    std::map<const IR::BFN::ParserState*,
             std::map<const PHV::Field*, std::set<unsigned>>> field_to_byte_idx;

    /// Maps state-relative byte indices in each state to the fields occupying
    /// that byte.
    std::map<const IR::BFN::ParserState*,
             std::map<unsigned, std::set<const PHV::Field*>>> byte_idx_to_field;

    std::set<const PHV::Field*> checksum_dests_;
    std::map<const PHV::Field*,
              std::vector<const IR::BFN::EmitChecksum*>> field_to_checksum_updates_;

    std::vector<Clot*> clots_;
    std::map<const Clot*, std::pair<gress_t, cstring>, Clot::Less> clot_to_parser_state_;
    std::map<gress_t, std::map<cstring, std::set<const Clot*>>> parser_state_to_clots_;

    std::map<const IR::BFN::ParserState*,
             std::map<const PHV::Field*, nw_bitrange>> field_range_;

    std::map<const Clot*, const IR::BFN::EmitChecksum*> clot_to_emit_checksum_;

    /// Maps fields to their equivalence class of aliases.
    std::map<const PHV::Field*, std::set<const PHV::Field*>*> field_aliases_;

    /// Names of headers that might be added by MAU.
    std::set<cstring> headers_added_by_mau_;

    std::vector<const Pseudoheader*> pseudoheaders_;
    std::map<const PHV::Field*, std::set<const Pseudoheader*>> field_to_pseudoheaders_;

 public:
    explicit ClotInfo(PhvUse& uses) : uses(uses) {}

 private:
    unsigned num_clots_allocated(gress_t gress) const { return Clot::tagCnt.at(gress); }

    /// The bit offset of a given field for a given parser state.
    unsigned offset(const IR::BFN::ParserState* state, const PHV::Field* field) const {
        return field_range_.at(state).at(field).lo;
    }

 public:
    const std::map<const Clot*, std::pair<gress_t, cstring>, Clot::Less>&
    clot_to_parser_state() const {
        return clot_to_parser_state_;
    }

    std::map<cstring, std::set<const Clot*>>& parser_state_to_clots(gress_t gress) {
        return parser_state_to_clots_.at(gress);
    }

    const std::map<cstring, std::set<const Clot*>>& parser_state_to_clots(gress_t gress) const {
        return parser_state_to_clots_.at(gress);
    }

    const Clot* parser_state_to_clot(const IR::BFN::LoweredParserState *state, unsigned tag) const {
        auto state_name = state->name;
        auto& parser_state_to_clots = this->parser_state_to_clots(state->thread());
        if (!parser_state_to_clots.count(state_name)) {
            // Prefix gress to generate full state name
            if (state->thread() == INGRESS)
                state_name = "ingress::" + state_name;
            else if (state->thread() == EGRESS)
                state_name = "egress::" + state_name;
            // It is likely the state name is that of a split state,
            // e.g. Original state = ingress::stateA
            //      Split state = ingress::stateA.$common.0
            // The parser_state_to_clots_ map is created before splitting and
            // carries the original state name. We regenerate the original state
            // name by stripping out the split name addition ".$common.0"
            std::string st(state_name.c_str());
            auto pos = st.find(".$");
            if (pos != std::string::npos)
                state_name = st.substr(0, pos);
        }
        if (parser_state_to_clots.count(state_name)) {
            auto& clots = parser_state_to_clots.at(state_name);
            auto it = std::find_if(clots.begin(), clots.end(), [&](const Clot* sclot) {
                return (sclot->tag == tag); });
            if (it != clots.end()) return *it;
        }
        return nullptr;
    }

    /// @return a map from overwrite offsets to corresponding containers.
    std::map<int, PHV::Container>
    get_overwrite_containers(const Clot* clot, const PhvInfo& phv) const;

    /// @return a map from overwrite offsets to corresponding checksum fields.
    std::map<int, const PHV::Field*>
    get_csum_fields(const Clot* clot) const {
        std::map<int, const PHV::Field*> csum_fields;

        for (auto f : clot->csum_fields()) {
            auto offset = clot->byte_offset(new PHV::FieldSlice(f));
            if (csum_fields.count(offset)) {
                auto other_field = csum_fields.at(offset);
                BUG_CHECK(false,
                    "CLOT %d has more than one checksum field at overwrite offset %d: %s and %s",
                    f->name, other_field->name);
            }

            csum_fields[offset] = f;
        }

        return csum_fields;
    }

    std::map<const Clot*, const IR::BFN::EmitChecksum*>& clot_to_emit_checksum() {
        return clot_to_emit_checksum_;
    }

    const std::map<const Clot*, const IR::BFN::EmitChecksum*>& clot_to_emit_checksum() const {
        return clot_to_emit_checksum_;
    }

 private:
    void add_field(const PHV::Field* f, const IR::BFN::PacketRVal* rval,
                   const IR::BFN::ParserState* state) {
        LOG4("adding " << f->name << " to " << state->name << " (range " << rval->range << ")");
        parser_state_to_fields_[state].push_back(f);
        field_to_parser_states_[f].insert(state);
        field_range_[state][f] = rval->range;
    }

    /// Populates @ref field_to_byte_idx and @ref byte_idx_to_field.
    void compute_byte_maps() {
        for (auto kv : parser_state_to_fields_) {
            auto state = kv.first;
            auto& fields_in_state = kv.second;

            for (auto f : fields_in_state) {
                unsigned f_offset = offset(state, f);
                unsigned start_byte =  f_offset / 8;
                unsigned end_byte = (f_offset + f->size - 1) / 8;

                for (unsigned i = start_byte; i <= end_byte; i++) {
                    field_to_byte_idx[state][f].insert(i);
                    byte_idx_to_field[state][i].insert(f);
                }
            }
        }

        if (LOGGING(4)) {
            std::clog << "=====================================================" << std::endl;

            for (auto kv : field_to_byte_idx) {
                std::clog << "state: " << kv.first->name << std::endl;
                for (auto fb : kv.second) {
                    std::clog << "  " << fb.first->name << " in byte";
                    for (auto id : fb.second)
                        std::clog << " " << id;
                    std::clog << std::endl;
                }
            }

            std::clog << "-----------------------------------------------------" << std::endl;

            for (auto kv : byte_idx_to_field) {
                std::clog << "state: " << kv.first->name << std::endl;
                for (auto bf : kv.second) {
                    std::clog << "  Byte " << bf.first << " has:";
                    for (auto f : bf.second)
                        std::clog << " " << f->name;
                    std::clog << std::endl;
                }
            }

            std::clog << "=====================================================" << std::endl;
        }
    }

    void add_clot(Clot* cl, const IR::BFN::ParserState* state) {
        clots_.push_back(cl);
        clot_to_parser_state_[cl] = {state->thread(), state->name};
        parser_state_to_clots_[state->thread()][state->name].insert(cl);
    }

    /// @return a set of parser states to which no more CLOTs may be allocated,
    /// because doing so would exceed the maximum number CLOTs allowed per
    /// state or per packet.
    const std::set<const IR::BFN::ParserState*>* find_full_states(
            const IR::BFN::ParserGraph* graph) const;

    // A field may participate in multiple checksum updates, e.g. IPv4 fields
    // may be included in both IPv4 and TCP checksum updates. In such cases,
    // we require the IPv4 fields in both updates to be identical sets in order
    // to be allocated to a CLOT (each CLOT can only compute one checksum)
    // see P4C-1509
    bool is_used_in_multiple_checksum_update_sets(const PHV::Field* field) const {
         if (!field_to_checksum_updates_.count(field))
             return false;

          return field_to_checksum_updates_.at(field).size() > 1;

         // TODO it's probably still ok to allocate field to CLOT
         // if the checksum updates it involves in are such that
         // one's source list is a subset of the update?
    }

    // Fields extracted in multiple mutex states can be allocated to CLOT
    // though it complicates things. We can allocate them to their own
    // CLOT or combine them with other fields in their states and create
    // synthetic POV bits so that we don't deparse them multiple times at
    // deparser. TODO(zma)
    bool is_extracted_in_multiple_states(const PHV::Field* f) const {
        return field_to_parser_states_.count(f) &&
            field_to_parser_states_.at(f).size() > 1;
    }

    /// Determines whether a field can be part of a CLOT. This can include
    /// fields that are PHV-allocated.
    bool can_be_in_clot(const PHV::Field* field) const;

    /// Determines whether a field slice can be the first one in a CLOT.
    bool can_start_clot(const FieldSliceExtractInfo* extract_info) const;

    /// Determines whether a field slice can be the last one in a CLOT.
    bool can_end_clot(const FieldSliceExtractInfo* extract_info) const;

    /// Determines whether a field extracts its full width from the packet.
    /// Returns false if the field is not extracted.
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

    /// @return nullptr if the @arg field is read-only or modified. Otherwise, if the @arg field is
    /// unused, returns a map from each CLOT-allocated slice for the field to its corresponding
    /// CLOT.
    std::map<const PHV::FieldSlice*, Clot*, PHV::FieldSlice::Greater>*
    allocated_slices(const PHV::Field* field) const {
        return is_unused(field) ? slice_clots(field) : nullptr;
    }

    /// @return the given field's CLOT if the field is unused and is entirely covered in a CLOT.
    /// Otherwise, nullptr is returned.
    const Clot* fully_allocated(const PHV::Field* field) const {
        return is_unused(field) ? whole_field_clot(field) : nullptr;
    }

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
    slice_clots(const PHV::FieldSlice* slice) const {
        auto result = new std::map<const PHV::FieldSlice*, Clot*, PHV::FieldSlice::Greater>();
        auto field = slice->field();
        for (auto c : clots_) {
            auto fields_to_slices = c->fields_to_slices();
            if (!fields_to_slices.count(field)) continue;

            auto clot_slice = fields_to_slices.at(field);
            if (clot_slice->range().overlaps(slice->range()))
                (*result)[clot_slice] = c;
        }

        return result;
    }

    /// @return the CLOT-allocated slices of the given @arg field, mapped to the CLOTs containing
    /// those slices.
    std::map<const PHV::FieldSlice*, Clot*, PHV::FieldSlice::Greater>*
    slice_clots(const PHV::Field* field) const {
        return slice_clots(new PHV::FieldSlice(field));
    }

    /// @return the CLOT containing the entirety of the given field, or nullptr if no such CLOT
    /// exists.
    Clot* whole_field_clot(const PHV::Field* field) const {
        for (auto c : clots_)
            if (c->has_slice(new PHV::FieldSlice(field)))
                return c;
        return nullptr;
    }

    /// @return true if the given @arg slice is covered by the given @arg clot.
    bool clot_covers_slice(const Clot* clot, const PHV::FieldSlice* slice) const;

    std::string print(const PhvInfo* phvInfo = nullptr) const;

 private:
    void add_alias(const PHV::Field* f1, const PHV::Field* f2);

    void clear();
};

class CollectClotInfo : public Inspector {
    const PhvInfo& phv;
    ClotInfo& clotInfo;
    std::map<const PHV::Field*, PovBitSet> fields_to_pov_bits;
    Logging::FileLog* log = nullptr;

 public:
    explicit CollectClotInfo(const PhvInfo& phv, ClotInfo& clotInfo) :
        phv(phv), clotInfo(clotInfo) {}

 private:
    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);
        clotInfo.clear();
        fields_to_pov_bits.clear();

        // Configure logging for this visitor.
        if (BackendOptions().verbose > 0) {
            auto pipe = root->to<IR::BFN::Pipe>();
            log = new Logging::FileLog(pipe->id, "parser.log");
        }

        return rv;
    }

    /// Collects the set of fields extracted.
    bool preorder(const IR::BFN::Extract* extract) override {
        auto state = findContext<IR::BFN::ParserState>();

        if (auto rval = extract->source->to<IR::BFN::PacketRVal>()) {
            if (auto field_lval = extract->dest->to<IR::BFN::FieldLVal>()) {
                if (auto f = phv.field(field_lval->field))
                    clotInfo.add_field(f, rval, state);
            }
        }

        return true;
    }

    /// Collects the set of POV bits on which each field's emit is predicated.
    bool preorder(const IR::BFN::EmitField* emit) override {
        auto field = phv.field(emit->source->field);
        auto irPov = emit->povBit->field;

        le_bitrange slice;
        auto pov = phv.field(irPov, &slice);

        fields_to_pov_bits[field].insert(new PHV::FieldSlice(pov, slice));
        return true;
    }

    /// Identifies checksum fields, collects the set of fields over which checksums are computed,
    /// and collects the set of POV bits on which each field's emit is predicated.
    bool preorder(const IR::BFN::EmitChecksum* emit) override {
        auto f = phv.field(emit->dest->field);
        clotInfo.checksum_dests_.insert(f);

        for (auto s : emit->sources) {
            auto src = phv.field(s->field);
            clotInfo.field_to_checksum_updates_[src].push_back(emit);
        }

        le_bitrange slice;
        auto pov = phv.field(emit->povBit->field, &slice);

        fields_to_pov_bits[f].insert(new PHV::FieldSlice(pov, slice));

        return true;
    }

    /// Uses @ref fields_to_pov_bits to identify pseudoheaders.
    void postorder(const IR::BFN::Deparser* deparser) override {
        // Used for deduplicating pseudoheaders. Contains the POV bits and fields of pseudoheaders
        // that have already been allocated.
        std::set<std::pair<const PovBitSet,
                           const std::vector<const PHV::Field*>>> allocated;

        // The POV bits and field list for the current pseudoheader we are building.
        PovBitSet cur_pov_bits;
        std::vector<const PHV::Field*> cur_fields;

        for (auto emit : deparser->emits) {
            const PHV::Field* cur_field = nullptr;
            if (auto emit_field = emit->to<IR::BFN::EmitField>()) {
                cur_field = phv.field(emit_field->source->field);
            } else if (auto emit_checksum = emit->to<IR::BFN::EmitChecksum>()) {
                cur_field = phv.field(emit_checksum->dest->field);
            } else {
                BUG("Unexpected deparser emit: %1%", emit);
            }

            auto pov_bits = fields_to_pov_bits.at(cur_field);
            if (cur_pov_bits != pov_bits) {
                add_pseudoheader(cur_pov_bits, cur_fields, allocated);
                cur_pov_bits = pov_bits;
                cur_fields.clear();
            }

            cur_fields.push_back(cur_field);
        }

        add_pseudoheader(cur_pov_bits, cur_fields, allocated);
    }

    /// Helper. Adds a new pseudoheader with the given @arg pov_bits and @arg fields, if one hasn't
    /// already been allocated, and @arg fields is non-empty.
    void add_pseudoheader(const PovBitSet pov_bits,
                          const std::vector<const PHV::Field*> fields,
                          std::set<std::pair<const PovBitSet,
                                             const std::vector<const PHV::Field*>>>& allocated) {
        if (fields.empty()) return;

        auto key = std::make_pair(pov_bits, fields);
        if (allocated.count(key)) return;

        // Have a new pseudoheader.
        auto pseudoheader = new Pseudoheader(pov_bits, fields);
        clotInfo.pseudoheaders_.push_back(pseudoheader);

        for (auto field : fields) {
            clotInfo.field_to_pseudoheaders_[field].insert(pseudoheader);
        }

        allocated.insert(key);

        if (LOGGING(6)) {
            LOG6("Pseudoheader " << pseudoheader->id);
            std::stringstream out;
            out << "  POV bits: ";
            bool first = true;
            for (auto pov : pov_bits) {
                if (!first) out << ", ";
                first = false;
                out << pov->shortString();
            }
            LOG6(out.str());
            LOG6("  Fields:");
            for (auto field : fields)
                LOG6("    " << field->name);
        }
    }

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

    void add_alias_field(const IR::Expression* alias) {
        const PHV::Field* aliasSource = nullptr;
        const PHV::Field* aliasDestination = nullptr;
        if (auto aliasMem = alias->to<IR::BFN::AliasMember>()) {
            aliasSource = phv.field(aliasMem->source);
            aliasDestination = phv.field(aliasMem);
        } else if (auto aliasSlice = alias->to<IR::BFN::AliasSlice>()) {
            aliasSource = phv.field(aliasSlice->source);
            aliasDestination = phv.field(aliasSlice);
        }
        BUG_CHECK(aliasSource, "Alias source for field %1% not found", alias);
        BUG_CHECK(aliasDestination, "Reference to alias field %1% not found", alias);
        clotInfo.add_alias(aliasSource, aliasDestination);
    }

    /// Collects the set of headers that are made valid by MAU.
    bool preorder(const IR::MAU::Instruction* instruction) override {
        // Make sure we have a call to "set".
        if (instruction->name != "set") return true;

        auto dst = instruction->operands.at(0);
        auto src = instruction->operands.at(1);

        // Make sure we are setting a header's validity bit.
        auto dst_field = phv.field(dst);
        if (!dst_field || !dst_field->pov) return true;

        // Make sure we are not assigning 0 to the validity bit. Conservatively, we assume that any
        // other kind of assignment might make the header valid.
        if (auto constant = src->to<IR::Constant>()) {
            if (constant->value == 0) return true;
        }

        clotInfo.headers_added_by_mau_.insert(dst_field->header());
        return true;
    }

    void end_apply(const IR::Node* root) override {
        clotInfo.compute_byte_maps();

        if (log) {
            delete(log);
            log = nullptr;
        }

        Inspector::end_apply(root);
    }
};

class AllocateClot : public PassManager {
    CollectParserInfo parserInfo;

 public:
    explicit AllocateClot(ClotInfo &clot, const PhvInfo &phv, PhvUse &uses);
};

/**
 * Adjusts allocated CLOTs to avoid PHV containers that straddle the CLOT boundary. See
 * https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU/edit#bookmark=id.42g1j75kjqs5
 */
class ClotAdjuster : public Visitor {
    ClotInfo& clotInfo;
    const PhvInfo& phv;
    Logging::FileLog* log = nullptr;

 public:
    ClotAdjuster(ClotInfo& clotInfo, const PhvInfo& phv) : clotInfo(clotInfo), phv(phv) { }

    Visitor::profile_t init_apply(const IR::Node* root) override;
    const IR::Node *apply_visitor(const IR::Node* root, const char*) override;
    void end_apply(const IR::Node* root) override;
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_INFO_H_ */
