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

class ClotInfo {
    friend class CollectClotInfo;
    friend class RemoveChecksumExtract;
    friend class NaiveClotAlloc;

    PhvUse &uses;

    ordered_map<const IR::BFN::ParserState*,
                std::vector<const PHV::Field*>> parser_state_to_fields_;

    ordered_map<const PHV::Field*,
                std::set<const IR::BFN::ParserState*>> field_to_parser_states_;

    std::set<const PHV::Field*> checksum_dests_;
    std::map<const PHV::Field*,
              std::vector<const IR::BFN::EmitChecksum*>> field_to_checksum_updates_;

    std::vector<Clot*> clots_;
    std::map<const Clot*, cstring> clot_to_parser_state_;
    std::map<cstring, std::vector<const Clot*>> parser_state_to_clots_;

    std::map<cstring, std::map<PHV::Container, nw_byterange>> container_range_;
    std::map<const PHV::Field*, nw_bitrange> field_range_;

    std::map<const Clot*, const IR::BFN::EmitChecksum*> clot_to_emit_checksum_;

 public:
    explicit ClotInfo(PhvUse& uses) : uses(uses) {}

 public:
    const std::vector<Clot*>& clots() const { return clots_; }

    unsigned num_clots_allocated() const { return Clot::tagCnt; }

    const std::map<const Clot*, cstring>&
        clot_to_parser_state()const { return clot_to_parser_state_; }

    const std::map<cstring, std::vector<const Clot*>>&
        parser_state_to_clots() const { return parser_state_to_clots_; }

    const Clot* parser_state_to_clot(cstring state, unsigned tag) const {
            if (parser_state_to_clots_.count(state)) {
                auto& clots = parser_state_to_clots_.at(state);
                auto it = std::find_if(clots.begin(), clots.end(), [&](const Clot* sclot) {
                    return (sclot->tag == tag); });
                if (it != clots.end()) return *it;
            }
            return nullptr;
    }

    std::map<cstring,
              std::map<PHV::Container, nw_byterange>>& container_range() {
        return container_range_; }

    const std::map<cstring,
              std::map<PHV::Container, nw_byterange>>& container_range() const {
        return container_range_; }

    std::map<const Clot*,
             const IR::BFN::EmitChecksum*>& clot_to_emit_checksum() {
        return clot_to_emit_checksum_;
    }

    const std::map<const Clot*,
                   const IR::BFN::EmitChecksum*>& clot_to_emit_checksum() const {
        return clot_to_emit_checksum_;
    }

    void add_field(const PHV::Field* f, const IR::BFN::PacketRVal* rval,
             const IR::BFN::ParserState* state) {
        parser_state_to_fields_[state].push_back(f);
        field_to_parser_states_[f].insert(state);
        field_range_[f] = rval->range();
    }

    void add_clot(Clot* cl, const IR::BFN::ParserState* state) {
        clots_.push_back(cl);
        clot_to_parser_state_[cl] = state->name;
        parser_state_to_clots_[state->name].push_back(cl);
    }

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

    bool is_clot_candidate(const PHV::Field* field) const {
        return !uses.is_used_mau(field) &&
                uses.is_used_parde(field) &&
               !is_used_in_multiple_checksum_update_sets(field) &&
               !is_extracted_in_multiple_states(field);
    }

    /// @return the CLOT if field is not used in MAU pipe
    /// and is covered in a CLOT
    Clot* allocated(const PHV::Field* field) const {
        if (!is_clot_candidate(field))
            return nullptr;

        return clot(field);
    }

    /// @return the pointer to the CLOT if field is covered in a CLOT
    Clot* clot(const PHV::Field* field) const {
        for (auto c : clots_)
            for (auto f : c->all_fields)
                if (f == field)
                    return c;
        return nullptr;
    }

    void clear() {
        parser_state_to_fields_.clear();
        field_to_parser_states_.clear();
        checksum_dests_.clear();
        field_to_checksum_updates_.clear();
        clots_.clear();
        clot_to_parser_state_.clear();
        parser_state_to_clots_.clear();
        container_range_.clear();
        field_range_.clear();
        Clot::tagCnt = 0;
    }

    std::string print() const;
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

        return false;
    }

    bool preorder(const IR::BFN::EmitChecksum* emit) override {
        auto f = phv.field(emit->dest->field);
        clotInfo.checksum_dests_.insert(f);

        for (auto s : emit->sources) {
            auto src = phv.field(s->field);
            clotInfo.field_to_checksum_updates_[src].push_back(emit);
        }

        return false;
    }
};

class AllocateClot : public PassManager {
    CollectParserInfo parserInfo;

 public:
    explicit AllocateClot(ClotInfo &clot, const PhvInfo &phv, PhvUse &uses);
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_INFO_H_ */
