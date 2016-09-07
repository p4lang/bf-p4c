#ifndef _TOFINO_PARDE_EXTRACT_PARSER_H_
#define _TOFINO_PARDE_EXTRACT_PARSER_H_

#include "ir/ir.h"

class GetTofinoParser : public Inspector {
    const IR::V1Program                        *program = 0;
    const IR::P4Parser                         *container = 0;
    gress_t                                     gress = INGRESS;
    map<cstring, IR::Tofino::ParserState *>     states;
    IR::ID                                      ingress_control;
    bool preorder(const IR::V1Parser *) override;
    bool preorder(const IR::ParserState *) override;

    struct Context {
        /* records the path through the parser state machine from the start state to the
         * current state.  Not to be confused with Visitor::Context */
        const Context               *parent;
        int                         depth;
        IR::Tofino::ParserState     *state;
        const Context *find(IR::Tofino::ParserState *s) const {
            for (auto *c = this; c; c = c->parent)
                if (c->state == s)
                    return c;
            return nullptr; }
    };
    class FindLatestExtract;
    class FindStackExtract;
    class RewriteExtractNext;
    void addMatch(IR::Tofino::ParserState *, match_t, const IR::Vector<IR::Expression> &,
                  const IR::ID &, const Context *);
    IR::Tofino::ParserState *state(cstring, const Context *);

 public:
    explicit GetTofinoParser(const IR::V1Program *g) : program(g) {}
    explicit GetTofinoParser(const IR::P4Parser *p) : container(p) {}
    explicit GetTofinoParser(const IR::Node *n)
    : program(n->to<IR::V1Program>()), container(n->to<IR::P4Parser>()) {
        BUG_CHECK(program || container, "Invalid top level for GetTofinoParser"); }
    IR::Tofino::Parser *parser(gress_t);
    cstring ingress_entry();
};

class RemoveSetMetadata : public Transform {
    IR::Primitive *preorder(IR::Primitive *prim) override {
        return prim->name == "set_metadata" ? nullptr : prim; }
};

#endif /* _TOFINO_PARDE_EXTRACT_PARSER_H_ */
