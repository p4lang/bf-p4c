#include "bridge_metadata.h"
#include "parde_visitor.h"

class AddBridgedMetadata::FindFieldsToBridge : public ThreadVisitor, Inspector {
    AddBridgedMetadata &self;
    bool preorder(const IR::Expression *e) override {
        if (auto *field = self.phv.field(e)) {
            for (auto &loc : self.defuse.getUses(this, e)) {
                if (loc.first->thread() == EGRESS) {
                    assert(field->metadata);
                    if (!field->bridged) {
                      LOG2("bridging field " << loc.second << " id=" << field->id);
                      field->bridged = true;
                      // XXX(seth): We should pack these fields more efficiently...
                      self.packing.appendField(loc.second,
                                               loc.second->type->width_bits());
                      self.packing.padToAlignment(8);
                    }
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
        if (deparser->gress != INGRESS) return false;
        if (!self.packing.containsFields()) return false;

        IR::Vector<IR::Expression> bridge;
        for (auto& item : self.packing.fields) {
            if (item.isPadding()) continue;
            bridge.push_back(new IR::Primitive("emit", item.field));
        }

        deparser->emits.insert(deparser->emits.begin(),
                               bridge.begin(), bridge.end());
        return false;
    }

    bool preorder(IR::Tofino::Parser *parser) override {
        if (parser->gress != EGRESS) return false;
        if (!self.packing.containsFields()) return false;

        auto start = transformAllMatching<IR::Tofino::ParserState>(parser->start,
                     [this](const IR::Tofino::ParserState* state) {
            if (state->name != "$bridged_metadata") return state;

            // Replace this placeholder state with a generated parser program
            // that extracts the bridged metadata.
            auto next = state->match[0]->next;
            cstring stateName = "$bridge_metadata_extract";
            return self.packing.createExtractionStates(EGRESS, stateName, next);
        });

        parser->start = start->to<IR::Tofino::ParserState>();
        return false;
    }

 public:
    explicit AddBridge(AddBridgedMetadata &self) : self(self) {}
};

AddBridgedMetadata:: AddBridgedMetadata(PhvInfo &phv, const FieldDefUse &defuse)
: phv(phv), defuse(defuse) {
    addPasses({
        new FindFieldsToBridge(*this),
        new AddBridge(*this),
    });
}

