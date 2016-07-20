#include "lib/log.h"
#include "elim_unused.h"
#include "tofino/ir/thread_visitor.h"
#include "tofino/parde/parde_visitor.h"

class ElimUnused::ParserMetadata : public Transform {
    ElimUnused &self;
    IR::Primitive *preorder(IR::Primitive *prim) override {
        if (prim->name == "extract" && self.phv.field(prim->operands[0]) &&
            self.defuse.getUses(this, prim->operands[0]).empty()) {
            LOG1("elim unused extract metadata " << prim);
            return nullptr; }
        return prim; }
    IR::MAU::Instruction *preorder(IR::MAU::Instruction *i) override {
        if (self.defuse.getUses(this, i->operands[0]).empty()) {
            LOG1("elim unused instruction " << i);
            return nullptr; }
        return i; }
 public:
    ParserMetadata(ElimUnused &self) : self(self) {}
};

class ElimUnused::FindHeaderUse : public Inspector, ThreadVisitor {
    ElimUnused &self;
    bool parser;  /* looking in parser only or mau only? */
    profile_t init_apply(const IR::Node *root) override {
        self.hdr_use.clear();
        return Inspector::init_apply(root); }
    bool preorder(const IR::MAU::Table *) override { return !parser; }
    bool preorder(const IR::MAU::TableSeq *) override { return !parser; }
    bool preorder(const IR::Tofino::Parser *) override { return parser; }
    bool preorder(const IR::Tofino::Deparser *) override { return false; }

    bool preorder(const IR::HeaderRef *hr) override {
        self.hdr_use.insert(hr->toString());
        return false; }
 public:
    FindHeaderUse(ElimUnused &self, gress_t thread, bool parser)
    : ThreadVisitor(thread), self(self), parser(parser) {}
};

class ElimUnused::Headers : public PardeTransform, ThreadVisitor {
    ElimUnused &self;
    bool parser;  /* looking in parser only or deparser only? */
    IR::Tofino::Parser *preorder(IR::Tofino::Parser *p) override {
        if (!parser) prune();
        return p; }

    IR::Tofino::ParserMatch *postorder(IR::Tofino::ParserMatch *match) override {
        if (match->next || match->except) return match;
        auto *state = findContext<IR::Tofino::ParserState>();
        if (state->name == "ingress::$ingress_metadata_shim" ||
            state->name == "egress::$egress_metadata_shim")
            return match;  // do not eliminate the shims
        if (state->name == "ingress::start$")
            /* FIXME -- it SHOULD be ok to eliminate this if it isn't needed in the
             * ingress pipe (all processing done in egress pipe), but harlyn doesn't
             * like it */
            return match;
        for (auto stmt : match->stmts) {
            auto *prim = stmt->to<IR::Primitive>();
            if (!prim) {
                BUG("non-primitive %s in parse state %s", stmt, state->name);
                return match; }
            if (prim->name == "extract" || prim->name == "set_metadata") {
                auto *hr = prim->operands[0]->to<IR::HeaderRef>();
                if (!hr || self.hdr_use.count(hr->toString()))
                    return match;
            } else {
                BUG("unexpected primitive %s in parse state %s", prim, state->name);
                return match; } }
        LOG1("eliminating match from " << state->name);
        return nullptr; }

    IR::Tofino::ParserState *postorder(IR::Tofino::ParserState *state) override {
        if (!state->match.empty()) return state;
        LOG1("eliminating parser state " << state->name);
        return nullptr; }

    IR::Tofino::Deparser *preorder(IR::Tofino::Deparser *d) override {
        if (parser) prune();
        return d; }

    IR::Primitive *preorder(IR::Primitive *prim) override {
        prune();
        if (!parser) {
            if (prim->name == "emit") {
                auto *hr = prim->operands[0]->to<IR::HeaderRef>();
                if (hr && !self.hdr_use.count(hr->toString())) {
                    LOG1("eliminating " << prim);
                    return nullptr; }
            } else {
                BUG("unexpected primitive %s in deparser", prim); } }
        return prim; }

 public:
    Headers(ElimUnused &self, gress_t thread, bool parser)
    : ThreadVisitor(thread), self(self), parser(parser) {}
};

ElimUnused::ElimUnused(const PhvInfo &phv, const FieldDefUse &defuse) : phv(phv), defuse(defuse) {
    addPasses({
        new ParserMetadata(*this),
        // Find headers used in MAU pipe
        new FindHeaderUse(*this, INGRESS, false),
        // Eliminate headers from parser if they're not used in MAU pipe
        new Headers(*this, INGRESS, true),
        // Find headers still used in parser
        new FindHeaderUse(*this, INGRESS, true),
        // Eliminate headers from deparser if they're not in the parser
        new Headers(*this, INGRESS, false),
        // repeat for egress
        new FindHeaderUse(*this, EGRESS, false),
        new Headers(*this, EGRESS, true),
        new FindHeaderUse(*this, EGRESS, true),
        new Headers(*this, EGRESS, false),
    });
}
