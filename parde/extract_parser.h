#ifndef _TOFINO_PARDE_EXTRACT_PARSER_H_
#define _TOFINO_PARDE_EXTRACT_PARSER_H_

#include "ir/ir.h"
#include "ir/visitor.h"

class GetTofinoParser : public Inspector {
    const IR::Global                            *program;
    map<cstring, IR::Tofino::ParserState *>     states;
    bool preorder(const IR::Parser *) override;
public:
    GetTofinoParser(const IR::Global *g) : program(g) {}
};

#endif /* _TOFINO_PARDE_EXTRACT_PARSER_H_ */
