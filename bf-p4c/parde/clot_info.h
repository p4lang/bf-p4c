#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_INFO_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_INFO_H_

#include <algorithm>

#include "clot.h"
#include "lib/ordered_map.h"
#include "bf-p4c/parde/parde_utils.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/parde/parde_visitor.h"

class PhvInfo;

class FieldExtractInfo;

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
    std::map<const Clot*, cstring> clot_to_parser_state_;
    std::map<cstring, std::set<const Clot*>> parser_state_to_clots_;

    std::map<cstring, std::map<PHV::Container, nw_byterange>> container_range_;
    std::map<const IR::BFN::ParserState*,
             std::map<const PHV::Field*, nw_bitrange>> field_range_;

    std::map<const Clot*, const IR::BFN::EmitChecksum*> clot_to_emit_checksum_;

    // Maps fields to their equivalence class of aliases.
    std::map<const PHV::Field*, std::set<const PHV::Field*>*> field_aliases_;

 public:
    explicit ClotInfo(PhvUse& uses) : uses(uses) {}

 private:
    unsigned num_clots_allocated(gress_t gress) const { return Clot::tagCnt.at(gress); }

    /// The bit offset of a given field for a given parser state.
    unsigned offset(const IR::BFN::ParserState* state, const PHV::Field* field) const {
        return field_range_.at(state).at(field).lo;
    }

 public:
    const std::map<const Clot*, cstring>& clot_to_parser_state() const {
        return clot_to_parser_state_;
    }

    const std::map<cstring, std::set<const Clot*>>& parser_state_to_clots() const {
        return parser_state_to_clots_;
    }

 public:
    const Clot* parser_state_to_clot(const IR::BFN::LoweredParserState *state, unsigned tag) const {
        auto state_name = state->name;
        if (!parser_state_to_clots_.count(state_name)) {
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
        if (parser_state_to_clots_.count(state_name)) {
            auto& clots = parser_state_to_clots_.at(state_name);
            auto it = std::find_if(clots.begin(), clots.end(), [&](const Clot* sclot) {
                return (sclot->tag == tag); });
            if (it != clots.end()) return *it;
        }
        return nullptr;
    }

    std::map<cstring, std::map<PHV::Container, nw_byterange>>& container_range() {
        return container_range_;
    }

    const std::map<cstring, std::map<PHV::Container, nw_byterange>>& container_range() const {
        return container_range_;
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
        LOG4("adding " << f->name << " to " << state->name << " (range " << rval->range() << ")");
        parser_state_to_fields_[state].push_back(f);
        field_to_parser_states_[f].insert(state);
        field_range_[state][f] = rval->range();
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
        clot_to_parser_state_[cl] = state->name;
        parser_state_to_clots_[state->name].insert(cl);
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

    /// Determines whether a field can be the first one in a CLOT.
    bool can_start_clot(const FieldExtractInfo* extract_info) const;

    /// Determines whether a field can be the last one in a CLOT.
    bool can_end_clot(const FieldExtractInfo* extract_info) const;

    /// Determines whether a field extracts its full width from the packet.
    /// Returns false if the field is not extracted.
    bool extracts_full_width(const PHV::Field* field) const;

    /// Memoization table for @ref is_modified.
    mutable std::map<const PHV::Field*, bool> is_modified_;

 public:
    /// Determines whether a field is a checksum field.
    bool is_checksum(const PHV::Field* field) const;

    /// Determines whether a field is modified, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    bool is_modified(const PHV::Field* field) const;

    /// Determines whether a field is read-only, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    bool is_readonly(const PHV::Field* field) const;

    /// Determines whether a field is unused, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    bool is_unused(const PHV::Field* field) const;

    /// @return the given field's CLOT if the field is unused and is covered in a CLOT. Otherwise,
    /// nullptr is returned.
    Clot* allocated(const PHV::Field* field) const {
        return is_unused(field) ? clot(field) : nullptr;
    }

    /// Adjusts a CLOT so that it neither starts nor ends with an overwritten field. See
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    ///
    /// @return true if the CLOT is non-empty as a result of the adjustment.
    bool adjust(const PhvInfo& phv, Clot* clot);

    /// Adjusts all allocated CLOTs so that they neither start nor end with an overwritten field.
    /// See https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    void adjust_clots(const PhvInfo& phv);

    /// Determines whether a field in a CLOT will be overwritten by a PHV container or a checksum
    /// calculation when deparsed. See
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
    ///
    /// @return true when @arg f is a field in @arg clot and will be overwritten by a PHV container
    ///         or a checksum calculation when deparsed.
    bool field_overwritten(const PhvInfo& phvInfo, const Clot* clot, const PHV::Field* f) const;

    /// Determines whether @arg f is a field in @arg clot that will be deparsed from the CLOT.
    ///
    /// @return true when @arg f is a non-checksum field in @arg clot that will not be overwritten
    ///         by a PHV when deparsed.
    bool field_deparsed_from_clot(const PhvInfo& phvInfo,
                                  const Clot* clot,
                                  const PHV::Field* f) const;

    /// @return the given field's CLOT, if any; otherwise, nullptr.
    Clot* clot(const PHV::Field* field) const {
        for (auto c : clots_)
            if (c->has_field(field))
                return c;
        return nullptr;
    }

    std::string print(const PhvInfo* phvInfo = nullptr) const;

 private:
    void add_alias(const PHV::Field* f1, const PHV::Field* f2);

    void clear();
};

class CollectClotInfo : public Inspector {
    const PhvInfo& phv;
    ClotInfo& clotInfo;

 public:
    explicit CollectClotInfo(const PhvInfo& phv, ClotInfo& clotInfo) :
        phv(phv), clotInfo(clotInfo) {}

 private:
    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);
        clotInfo.clear();
        return rv;
    }

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

    bool preorder(const IR::BFN::EmitChecksum* emit) override {
        auto f = phv.field(emit->dest->field);
        clotInfo.checksum_dests_.insert(f);

        for (auto s : emit->sources) {
            auto src = phv.field(s->field);
            clotInfo.field_to_checksum_updates_[src].push_back(emit);
        }

        return true;
    }

    bool preorder(const IR::BFN::AliasMember* alias) override {
        add_alias_field(alias);
        return true;
    }

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

    void end_apply(const IR::Node* root) override {
        clotInfo.compute_byte_maps();
        return Inspector::end_apply(root);
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

 public:
    ClotAdjuster(ClotInfo& clotInfo, const PhvInfo& phv) : clotInfo(clotInfo), phv(phv) { }

    const IR::Node *apply_visitor(const IR::Node* root, const char*) override;
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_INFO_H_ */
