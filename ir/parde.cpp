#include "ir/ir.h"

IR::Tofino_ParserState::Tofino_ParserState(const IR::Parser *parser) {
    name = parser->name;
    if (name == "start" || name == "end")
        name += "$";
    p4state = parser;
    if (parser->select)
      select = *parser->select;
}
