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

    std::map<const IR::BFN::ParserState*, std::vector<const PHV::Field*>> all_fields;

    std::vector<const Clot*> clots;
    std::map<const PHV::Field*, const Clot*> field_to_clot;
    std::map<const Clot*, const IR::BFN::ParserState*> clot_to_parser_state;
    std::map<const IR::BFN::ParserState*, std::vector<const Clot*>> parser_state_to_clots;

 public:
    void add(const Clot* cl, const IR::BFN::ParserState* state) {
        clots.push_back(cl);

        for (auto f : cl->all_fields)
            field_to_clot[f] = cl;

        clot_to_parser_state[cl] = state;
        parser_state_to_clots[state].push_back(cl);
    }

    const Clot* allocated(const PHV::Field* field) const {
        auto find = field_to_clot.find(field);
        if (find == field_to_clot.end())
            return nullptr;
        auto* clot = find->second;
        return clot;
    }

    void clear() {
        all_fields.clear();
        clots.clear();
        field_to_clot.clear();
        clot_to_parser_state.clear();
        parser_state_to_clots.clear();
    }
};

class AllocateClot : public PassManager {
 public:
    explicit AllocateClot(ClotInfo &clot, const PhvInfo &phv, PhvUse &uses);
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_INFO_H_ */
