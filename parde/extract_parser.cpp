#include "extract_parser.h"

bool GetTofinoParser::preorder(const IR::Parser *p) {
    states[p->name] = new IR::Tofino::ParserState(p);
    return true;
}
