#include "ir/ir.h"

IR::Tofino_ParserState::Tofino_ParserState (const IR::Parser *parser) {
    p4state = parser;
    select = *parser->select;
}
