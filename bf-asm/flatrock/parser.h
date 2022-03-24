#ifndef BF_ASM_FLATROCK_PARSER_H_
#define BF_ASM_FLATROCK_PARSER_H_

#include "../parser.h"
#include <boost/optional.hpp>
#include "flatrock/pseudo_parser.h"
#include "asm-types.h"
#include "vector.h"
#include "target.h"

class FlatrockParser : public BaseParser, public Parsable {
 public:
    void input(VECTOR(value_t) args, value_t data) override;
    void write_config(RegisterSetBase &regs, json::map &json, bool legacy = true) override;
};

class FlatrockAsmParser : public BaseAsmParser {
    FlatrockParser parser;
    FlatrockPseudoParser pseudo_parser;

    void start(int lineno, VECTOR(value_t) args) override;
    void input(VECTOR(value_t) args, value_t data) override;
    void output(json::map &) override;

 public:
    FlatrockAsmParser() : BaseAsmParser("parser") {}
};

#endif  // BF_ASM_FLATROCK_PARSER_H_
