#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_INFO_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_INFO_H_

#include "clot.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/parde/parde_visitor.h"

class PhvInfo;
class PhvUse;

class ClotInfo {
    friend class CollectClotInfo;
    friend class NaiveClotAlloc;

    std::map<const IR::BFN::ParserState*, std::vector<const PHV::Field*>> all_fields_;

    std::vector<const Clot*> clots_;
    std::map<const Clot*, const IR::BFN::ParserState*> clot_to_parser_state_;
    std::map<const IR::BFN::ParserState*, std::vector<const Clot*>> parser_state_to_clots_;

 public:
    // TODO(zma) encapsulate this properly
    std::map<PHV::Container, nw_byterange> container_range_;

 public:
    const std::vector<const Clot*>& clots() const { return clots_; }

    const std::map<const IR::BFN::ParserState*, std::vector<const Clot*>>&
        parser_state_to_clots() const { return parser_state_to_clots_; }

    void add(const Clot* cl, const IR::BFN::ParserState* state) {
        clots_.push_back(cl);

        clot_to_parser_state_[cl] = state;
        parser_state_to_clots_[state].push_back(cl);
    }

    const Clot* allocated(const PHV::Field* field) const {
        for (auto c : clots_)
            for (auto f : c->all_fields)
                if (f == field)
                    return c;
        return nullptr;
    }

    void clear() {
        all_fields_.clear();
        clots_.clear();
        clot_to_parser_state_.clear();
        parser_state_to_clots_.clear();
    }

    void dbprint(std::ostream &out) const;
};

class AllocateClot : public PassManager {
 public:
    explicit AllocateClot(ClotInfo &clot, const PhvInfo &phv, PhvUse &uses);
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_INFO_H_ */
