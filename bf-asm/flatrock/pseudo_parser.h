#ifndef BF_ASM_FLATROCK_PSEUDO_PARSER_H_
#define BF_ASM_FLATROCK_PSEUDO_PARSER_H_

#include "../parser.h"
#include "asm-types.h"
#include "vector.h"

class FlatrockPseudoParser : virtual public Parsable, virtual public Configurable {
 public:
    int pov_flags_pos = -1;
    int pov_state_pos = -1;

    void input(VECTOR(value_t) args, value_t data) override;
    void write_config(RegisterSetBase &regs, json::map &json, bool legacy = true) override;
};

#endif  // BF_ASM_FLATROCK_PSEUDO_PARSER_H_
