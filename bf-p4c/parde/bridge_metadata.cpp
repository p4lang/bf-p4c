#include "bridge_metadata.h"

#include <set>

#include "parde_visitor.h"

class AddBridgedMetadata::FindFieldsToBridge : public ThreadVisitor, Inspector {
    AddBridgedMetadata &self;
    std::set<const PhvInfo::Field*> bridgedFields;

    bool preorder(const IR::Expression *e) override {
        if (auto *field = self.phv.field(e)) {
            for (auto &loc : self.defuse.getAllUses(field->id)) {
                if (loc.first->thread() == EGRESS && field->metadata) {
                    if (bridgedFields.find(field) == bridgedFields.end()) {
                      LOG2("bridging field " << loc.second << " id=" << field->id);
                      bridgedFields.insert(field);

                      // If this field has an alignment constraint, make sure
                      // that we generate a packing that respects it.
                      if (field->alignment)
                          self.packing.padToAlignment(8, field->alignment->network);

                      self.packing.appendField(loc.second,
                                               loc.second->type->width_bits());
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

        auto alwaysDeparseBit =
            new IR::TempVar(IR::Type::Bits::get(1), true, "$always_deparse");
        IR::Vector<IR::Tofino::DeparserPrimitive> bridge;
        for (auto& item : self.packing.fields) {
            if (item.isPadding()) continue;
            bridge.push_back(new IR::Tofino::Emit(item.field, alwaysDeparseBit));
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

            // Pad the field packing out to a byte boundary so the resulting
            // parser state will extract an integer number of bytes.
            self.packing.padToAlignment(8);

            // Replace this placeholder state with a generated parser program
            // that extracts the bridged metadata.
            auto next = state->match[0]->next;
            cstring stateName = "$bridge_metadata_extract";
            return self.packing.createExtractionState(EGRESS, stateName, next);
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

