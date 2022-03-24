#include "flatrock/parser.h"

void FlatrockParser::write_config(RegisterSetBase &regs, json::map &json, bool legacy) {
}

void FlatrockParser::input(VECTOR(value_t) args, value_t data) {
}

void FlatrockAsmParser::start(int lineno, VECTOR(value_t) args) {
    if (args.size != 1 || (args[0] != "ingress" && args[0] != "egress"))
        error(lineno, "parser must specify ingress or egress;"
            " ingress represents parser and egress represents pseudo parser");
}

void FlatrockAsmParser::input(VECTOR(value_t) args, value_t data) {
    if (CHECKTYPE(data, tMAP)) {
        if (args.size == 1 && args[0] == "ingress") {
            parser.input(args, data);
        } else {
            pseudo_parser.input(args, data);
        }
    }
}

void FlatrockAsmParser::output(json::map &json) {
    auto *regs = new Target::Flatrock::parser_regs;
    declare_registers(regs);
    parser.write_config(*regs, json, false);
    pseudo_parser.write_config(*regs, json, false);
}
