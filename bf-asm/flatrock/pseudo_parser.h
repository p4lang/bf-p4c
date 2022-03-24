#ifndef BF_ASM_FLATROCK_PSEUDO_PARSER_H_
#define BF_ASM_FLATROCK_PSEUDO_PARSER_H_

#include "../parser.h"
#include "asm-types.h"
#include "vector.h"

class FlatrockPseudoParser : public Parsable, public Configurable {
 public:
    void input(VECTOR(value_t) args, value_t data) override;
    void write_config(RegisterSetBase &regs, json::map &json, bool legacy = true) override;
};

#endif  // BF_ASM_FLATROCK_PSEUDO_PARSER_H_
