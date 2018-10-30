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

    ordered_map<const PHV::Field*, const IR::BFN::ParserState*> field_to_parser_state_;

    std::set<const PHV::Field*> checksum_dests_;

    std::vector<const Clot*> clots_;
    std::map<const Clot*, cstring> clot_to_parser_state_;
    std::map<cstring, std::vector<const Clot*>> parser_state_to_clots_;

    std::map<cstring, std::map<PHV::Container, nw_byterange>> container_range_;
    std::map<const PHV::Field*, nw_bitrange> field_range_;

 public:
    explicit ClotInfo(PhvUse& uses) : uses(uses) {}

 public:
    const std::vector<const Clot*>& clots() const { return clots_; }

    unsigned num_clots_allocated() const { return Clot::tagCnt; }

    const std::map<const Clot*, cstring>&
        clot_to_parser_state()const { return clot_to_parser_state_; }

    const std::map<cstring, std::vector<const Clot*>>&
        parser_state_to_clots() const { return parser_state_to_clots_; }

    std::map<cstring,
              std::map<PHV::Container, nw_byterange>>& container_range() {
        return container_range_; }

    const std::map<cstring,
              std::map<PHV::Container, nw_byterange>>& container_range() const {
        return container_range_; }

    void add_field(const PHV::Field* f, const IR::BFN::PacketRVal* rval,
             const IR::BFN::ParserState* state) {
        parser_state_to_fields_[state].push_back(f);
        field_to_parser_state_[f] = state;
        field_range_[f] = rval->range();
    }

    void add_clot(const Clot* cl, const IR::BFN::ParserState* state) {
        clots_.push_back(cl);
        clot_to_parser_state_[cl] = state->name;
        parser_state_to_clots_[state->name].push_back(cl);
    }

    bool is_clot_candidate(const PHV::Field* field) const {
        return !uses.is_used_mau(field) && uses.is_used_parde(field);
    }

    /// @return the CLOT if field is not used in MAU pipe
    /// and is covered in a CLOT
    const Clot* allocated(const PHV::Field* field) const {
        if (!is_clot_candidate(field))
            return nullptr;

        return clot(field);
    }

    /// @return the pointer to the CLOT if field is covered in a CLOT
    const Clot* clot(const PHV::Field* field) const {
        for (auto c : clots_)
            for (auto f : c->all_fields)
                if (f == field)
                    return c;
        return nullptr;
    }

    void clear() {
        parser_state_to_fields_.clear();
        field_to_parser_state_.clear();
        checksum_dests_.clear();
        clots_.clear();
        clot_to_parser_state_.clear();
        parser_state_to_clots_.clear();
        container_range_.clear();
        field_range_.clear();
        Clot::tagCnt = 0;
    }

    void dbprint(std::ostream &out) const;
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

    bool preorder(const IR::BFN::ParserPrimitive* prim) override {
        auto state = findContext<IR::BFN::ParserState>();

        if (auto extract = prim->to<IR::BFN::Extract>()) {
            auto rval = extract->source->to<IR::BFN::PacketRVal>();
            if (rval) {
                if (auto field_lval = extract->dest->to<IR::BFN::FieldLVal>()) {
                    if (auto f = phv.field(field_lval->field))
                        clotInfo.add_field(f, rval, state);
                } else if (auto checksum_lval = extract->dest->to<IR::BFN::ChecksumLVal>()) {
                    if (auto f = phv.field(checksum_lval->field))
                        clotInfo.add_field(f, rval, state);
                }
            }
        }

        return false;
    }

    bool preorder(const IR::BFN::EmitChecksum* emit) override {
        auto f = phv.field(emit->dest->field);
        clotInfo.checksum_dests_.insert(f);
        return false;
    }
};

class AllocateClot : public PassManager {
    CollectParserInfo parserInfo;

 public:
    explicit AllocateClot(ClotInfo &clot, const PhvInfo &phv, PhvUse &uses);
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_INFO_H_ */
