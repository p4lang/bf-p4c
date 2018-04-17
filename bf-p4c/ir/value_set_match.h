#ifndef EXTENSIONS_BF_P4C_IR_VALUE_SET_MATCH_H_
#define EXTENSIONS_BF_P4C_IR_VALUE_SET_MATCH_H_

#include <lib/match.h>

struct value_set_match_t : match_t {
    explicit value_set_match_t(const IR::P4ValueSet* inst) :
        match_t(), inst(inst) {}
    const IR::P4ValueSet* inst;
};

#endif /* EXTENSIONS_BF_P4C_IR_VALUE_SET_MATCH_H_ */
