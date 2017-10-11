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

                      // Decide on an alignment to use for this field. If it has
                      // an alignment constraint, we just use that. Otherwise,
                      // we align it enough so that its LSB lines up with a byte
                      // boundary, which reproduces the behavior of the PHV
                      // allocator.
                      // XXX(seth): In practice, that should match the current
                      // behavior of the PHV allocator most of the time. The
                      // right solution is to actually use the *output* of the
                      // PHV allocator to determine the packing.
                      if (field->alignment) {
                          LOG3("using alignment " << field->alignment->network
                                 << " from constraint for field " << field->name);
                          self.packing.padToAlignment(8, field->alignment->network);
                      } else {
                          const int nextByteBoundary = 8 * ((field->size + 7) / 8);
                          const int alignment = nextByteBoundary - field->size;
                          LOG3("using default alignment " << alignment
                                 << " for field " << field->name);
                          self.packing.padToAlignment(8, alignment);
                      }

                      self.packing.appendField(loc.second,
                                               loc.second->type->width_bits());

                      // Pad out to the next byte boundary.
                      // XXX(seth): Again, this is just an attempt to match the
                      // behavior of the PHV allocator, which uses a strategy
                      // that usually looks like "use the smallest container
                      // that can hold the metadata field and whatever padding
                      // is necessary to align it".
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

    bool preorder(IR::BFN::Deparser *deparser) override {
        if (deparser->gress != INGRESS) return false;
        if (!self.packing.containsFields()) return false;

        auto alwaysDeparseBit =
            new IR::TempVar(IR::Type::Bits::get(1), true, "$always_deparse");
        IR::Vector<IR::BFN::DeparserPrimitive> bridge;
        for (auto& item : self.packing.fields) {
            if (item.isPadding()) continue;
            bridge.push_back(new IR::BFN::Emit(item.field, alwaysDeparseBit));
        }

        deparser->emits.insert(deparser->emits.begin(),
                               bridge.begin(), bridge.end());
        return false;
    }

    bool preorder(IR::BFN::Parser *parser) override {
        if (parser->gress != EGRESS) return false;
        if (!self.packing.containsFields()) return false;

        auto start = transformAllMatching<IR::BFN::ParserState>(parser->start,
                     [this](const IR::BFN::ParserState* state) {
            if (state->name != "$bridged_metadata") return state;

            // Replace this placeholder state with a generated parser program
            // that extracts the bridged metadata.
            auto* next = state->transitions[0]->next;
            cstring stateName = "$bridge_metadata_extract";
            return self.packing.createExtractionState(EGRESS, stateName, next);
        });

        parser->start = start->to<IR::BFN::ParserState>();
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

