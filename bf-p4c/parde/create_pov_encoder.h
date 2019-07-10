#ifndef BF_P4C_PARDE_CREATE_POV_ENCODER_H_
#define BF_P4C_PARDE_CREATE_POV_ENCODER_H_

#include <ir/ir.h>

struct MatchAction {
    MatchAction(std::vector<const IR::Expression*> k,
                ordered_set<const IR::TempVar*> o,
                ordered_map<unsigned, unsigned> ma) :
        keys(k), outputs(o), match_to_action_param(ma) { }
    std::vector<const IR::Expression*> keys;
    ordered_set<const IR::TempVar*> outputs;
    ordered_map<unsigned, unsigned> match_to_action_param;

    std::string print() const;
};

IR::MAU::Table*
create_compiler_generated_table(gress_t gress, cstring tableName, cstring action_name,
                                const MatchAction& match_action);

#endif /*BF_P4C_PARDE_CREATE_POV_ENCODER_H_*/
