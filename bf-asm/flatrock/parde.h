#ifndef FLATROCK_PARDE_H_
#define FLATROCK_PARDE_H_

#include "asm-types.h"
#include "target.h"

bool check_range_state_subfield(value_t msb, value_t lsb, bool only8b = false);

struct PovSelect {
    struct PovSelectKey {
        enum { FLAGS = 0, STATE = 1} src = FLAGS;
        uint8_t start = 0;
        bool used = false;
    } key[Target::Flatrock::PARSER_POV_SELECT_NUM];

    bool input(value_t data);
    bool check_match(const match_t match) const;
};

#endif  // FLATROCK_PARDE_H_
