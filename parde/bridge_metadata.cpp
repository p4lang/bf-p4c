#include "bridge_metadata.h"
#include "parde_visitor.h"

class AddBridgedMetadata::FindFieldsToBridge : public ThreadVisitor, Inspector {
    AddBridgedMetadata &self;
    bool preorder(const IR::Expression *e) override {
        if (auto *field = self.phv.field(e)) {
            for (auto &loc : self.defuse.getUses(this, e)) {
                if (loc.first->thread() == EGRESS) {
                    assert(field->metadata);
                    self.need_bridge[field->id] = loc.second;
                    break; } }
            return false;
        } else {
            return true; } }
 public:
    explicit FindFieldsToBridge(AddBridgedMetadata &self) : ThreadVisitor(INGRESS), self(self) {}
};

class AddBridgedMetadata::AddBridge : public PardeModifier {
    AddBridgedMetadata &self;
    bool preorder(IR::Tofino::Deparser *deparser) override {
        if (deparser->gress == INGRESS && !self.need_bridge.empty()) {
            IR::Vector<IR::Expression> bridge;
            for (auto &f : self.need_bridge) {
                LOG2("bridging field " << f.second << " id=" << f.first);
                bridge.push_back(new IR::Primitive("emit", f.second)); }
            deparser->emits.insert(deparser->emits.begin(), bridge.begin(), bridge.end()); }
        return false; }
    bool preorder(IR::Tofino::Parser *parser) override {
        if (self.need_bridge.empty()) return false;
        if (parser->gress == INGRESS) {
            /* FIXME -- nasty hack here -- in order to deparse the bridged metadata we need
             * a fixed constant POV bit for use in the deparser.  So we create a NamedRef here
             * that we recognize in POV allocation as a POV bit we need to allocate.  Should
             * have a better mechanism for managing and allocating POV bits */
            parser->start = new IR::Tofino::ParserState("$bridge-metadata", parser->gress, {}, {
                new IR::Tofino::ParserMatch(match_t(), -1, {
                    new IR::Primitive("set_metadata",
                        new IR::NamedRef(IR::Type::Bits::get(1), "$bridge-metadata"),
                        new IR::Constant(IR::Type::Bits::get(1), 1))
                }, parser->start) });
        } else {
            auto *shim = new IR::Tofino::ParserMatch(match_t(), -1, {}, parser->start);
            for (auto field : Values(self.need_bridge))
                shim->stmts.push_back(new IR::Primitive("extract", field));
            parser->start = new IR::Tofino::ParserState("$bridge-metadata", parser->gress,
                                                        {}, { shim }); }
        return false; }

 public:
    explicit AddBridge(AddBridgedMetadata &self) : self(self) {}
};

AddBridgedMetadata:: AddBridgedMetadata(const PhvInfo &phv, const FieldDefUse &defuse)
: phv(phv), defuse(defuse) {
    addPasses({
        new FindFieldsToBridge(*this),
        new AddBridge(*this),
    });
}

