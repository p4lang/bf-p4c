#include "elim_unused.h"
#include <string.h>
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "lib/log.h"

const IR::BFN::Extract*
AbstractElimUnusedInstructions::preorder(IR::BFN::Extract* extract) {
    auto unit = findOrigCtxt<IR::BFN::Unit>();
    if (!unit) return extract;

    // Do not eliminate extract that it is serialized from deparser so that its layout
    // might be change due to phv allcoation.
    // TODO(yumin): again, the reason we can not do it now is because that we do not have
    // the `input buffer layout` stored with the parser state. Instead, we rely on all those
    // primitives and shift and range to determine what is on the buffer, which has already
    // created some troubles in ResolveComputed. Once we can do the input buffer layout
    // refactoring, this can be removed as well, as long as from_marshaled is migrated onto
    // input buffer layout as well.
    if (extract->marshaled_from) {
        return extract; }

    if (elim_extract(unit, extract)) {
        if (auto lval = extract->dest->to<IR::BFN::FieldLVal>())
            eliminated.insert(lval->toString());
        LOG1("ELIM UNUSED " << extract << " IN UNIT " << DBPrint::Brief << unit);
        return nullptr;
    }

    return extract;
}

const IR::BFN::FieldLVal*
AbstractElimUnusedInstructions::preorder(IR::BFN::FieldLVal* lval) {
    auto tcs = findOrigCtxt<IR::BFN::TotalContainerSize>();
    if (!tcs) return lval;

    if (eliminated.count(lval->toString())) {
        LOG1("ELIM UNUSED " << lval << " IN UNIT " << DBPrint::Brief << tcs);
        return nullptr;
    }

    return lval;
}

class ElimUnused::Instructions : public AbstractElimUnusedInstructions {
    bool elim_extract(const IR::BFN::Unit* unit, const IR::Expression* field) {
        return defuse.getUses(unit, field).empty();
    }

    bool elim_extract(const IR::BFN::Unit* unit,
                      const IR::BFN::Extract* extract) override {
        if (auto lval = extract->dest->to<IR::BFN::FieldLVal>())
            return elim_extract(unit, lval->field);

        return false;
    }

    const IR::BFN::ChecksumVerify* preorder(IR::BFN::ChecksumVerify* verify) override {
        auto unit = findOrigCtxt<IR::BFN::Unit>();
        if (!unit) return verify;
        if (verify->dest && !defuse.getUses(unit, verify->dest->field).empty())
            return verify;

        LOG1("ELIM UNUSED " << verify << " IN UNIT " << DBPrint::Brief << unit);
        return nullptr;
    }

    const IR::MAU::Instruction *preorder(IR::MAU::Instruction *i) override {
        auto unit = findOrigCtxt<IR::BFN::Unit>();
        if (!unit) return i;
        if (!i->operands[0]) return i;
        if (!defuse.getUses(unit, i->operands[0]).empty()) return i;
        LOG1("ELIM UNUSED instruction " << i << " IN UNIT " << DBPrint::Brief << unit);
        return nullptr;
    }

    const IR::MAU::Instruction *postorder(IR::MAU::Instruction *inst) override {
        /// HACK(hanw): copy-propagation introduces set(a, a) instructions, which
        /// is not deadcode eliminated because 'a' is still in-use in the control flow.
        if (inst->operands.size() < 2) return inst;
        auto left = (inst->operands[0])->apply(ReplaceMember());
        auto right = (inst->operands[1])->apply(ReplaceMember());
        if (auto lmem = left->to<IR::Member>()) {
            if (auto rmem = right->to<IR::Member>()) {
                if (inst->name == "set" && lmem->equiv(*rmem))
                    return nullptr; } }
        return inst;
    }

 public:
    explicit Instructions(ElimUnused &self)
      : AbstractElimUnusedInstructions(self.defuse) {}
};

/// Removes no-op tables that have the @hidden annotation.
class ElimUnused::Tables : public MauTransform {
 public:
    const IR::Node* postorder(IR::MAU::Table* table) override {
        // Don't remove the table unless it has the @hidden annotation.
        std::vector<IR::ID> val;
        if (!table->getAnnotation(IR::Annotation::hiddenAnnotation, val)) return table;

        // Don't remove the table unless its gateway payload is a no-op.
        if (table->uses_gateway_payload()) {
            for (auto payload_row : Values(table->gateway_payload)) {
                if (!isNoOp(table->actions.at(payload_row.first))) return table;
            }
        }

        // Don't remove the table unless all its match actions are empty.
        if (!table->conditional_gateway_only()) {
            for (auto& entry : table->actions) {
                if (!isNoOp(entry.second)) return table;
            }
        }

        // Don't remove the table if it has an attached table.
        if (!table->attached.empty()) return table;

        // Don't remove the table unless its "next" entries are all the same.
        bool first = true;
        const IR::MAU::TableSeq* theEntry = nullptr;
        for (auto& entry : table->next) {
            auto curEntry = normalize(entry.second);
            if (first) {
                theEntry = curEntry;
                first = false;
                continue;
            }

            if (*curEntry != *theEntry) return table;
        }

        if (theEntry && !theEntry->tables.empty()) {
            // Don't remove the table unless all paths through the table have a "next" lookup.

            // Handle the gateway-inhibited half of the table.
            for (auto& gw : table->gateway_rows) {
                auto tag = gw.second;
                if (!tag || !table->next.count(tag)) return table;
            }

            // Handle the match table.
            bool haveHitMiss = table->next.count("$hit") || table->next.count("$miss");
            for (auto& kv : table->actions) {
                auto action_name = kv.first;
                auto& action = kv.second;

                if (haveHitMiss) {
                    if (!action->miss_only() && !table->next.count("$hit")) return table;
                    if (!action->hit_only() && !table->next.count("$miss")) return table;
                } else {
                    if (!table->next.count(action_name) && !table->next.count("$default"))
                        return table;
                }
            }

            // Actually remove the table by replacing with theEntry.
            LOG1("ELIM UNUSED table " << table->name << " IN UNIT " <<
                 DBPrint::Brief << findContext<IR::BFN::Unit>());
            return theEntry;
        }

        // Actually remove the table by replacing with nullptr.
        LOG1("ELIM UNUSED table " << table->name << " IN UNIT " <<
             DBPrint::Brief << findContext<IR::BFN::Unit>());
        return nullptr;
    }

 private:
    /// An action is a no-op if it is nullptr, or if it is empty and doesn't exit.
    bool isNoOp(const IR::MAU::Action* action) {
        return !action || (action->action.empty() && !action->exitAction);
    }

    /// Normalizes a TableSeq* by turning nullptrs into empty sequences.
    const IR::MAU::TableSeq* normalize(const IR::MAU::TableSeq* seq) {
        static IR::MAU::TableSeq* empty = new IR::MAU::TableSeq();
        return seq ? seq : empty;
    }

 public:
    explicit Tables(ElimUnused&) {}
};

class ElimUnused::Headers : public PardeTransform {
    ElimUnused &self;

    bool hasDefs(const IR::Expression* fieldRef) const {
        auto* field = self.phv.field(fieldRef);
        if (!field) return true;
        for (const auto& def : self.defuse.getAllDefs(field->id)) {
            if (!def.second->is<ImplicitParserInit>()) {
                return true; } }
        return false;
    }

    const IR::BFN::EmitField* preorder(IR::BFN::EmitField* emit) override {
        prune();

        // The emit primitive is used if the POV bit being set somewhere.
        if (hasDefs(emit->povBit->field)) return emit;

        LOG1("ELIM UNUSED emit " << emit << " IN UNIT " <<
             DBPrint::Brief << findContext<IR::BFN::Unit>());
        return nullptr;
    }

    const IR::BFN::EmitChecksum* preorder(IR::BFN::EmitChecksum* emit) override {
        prune();

        // The emit checksum primitive is used if the POV bit being set somewhere.
        if (hasDefs(emit->povBit->field)) return emit;

        LOG1("ELIM UNUSED emit checksum " << emit << " IN UNIT " <<
             DBPrint::Brief << findContext<IR::BFN::Unit>());
        return nullptr;
    }

    const IR::BFN::DeparserParameter*
    preorder(IR::BFN::DeparserParameter* param) override {
        prune();

        // We don't need to set a deparser parameter if the field it gets its
        // value from is never set.
        if (hasDefs(param->source->field)) return param;

        LOG1("ELIM UNUSED deparser parameter " << param << " IN UNIT " <<
             DBPrint::Brief << findContext<IR::BFN::Unit>());
        return nullptr;
    }

 public:
    explicit Headers(ElimUnused &self) : self(self) { }
};

ElimUnused::ElimUnused(const PhvInfo &phv, FieldDefUse &defuse) : phv(phv), defuse(defuse) {
    addPasses({
        LOGGING(4) ? new DumpParser("before_elim_unused") : nullptr,
        new PassRepeated({
            new Instructions(*this),
            &defuse,
            new Tables(*this),
            &defuse,
            new Headers(*this),
            &defuse}),
        LOGGING(4) ? new DumpParser("after_elim_unused") : nullptr
    });
}