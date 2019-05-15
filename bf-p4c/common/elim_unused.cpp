#include "elim_unused.h"
#include <string.h>
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "lib/log.h"

class ElimUnused::Instructions : public Transform {
    ElimUnused &self;

    std::set<cstring> eliminated;

    const IR::MAU::StatefulAlu *preorder(IR::MAU::StatefulAlu *salu) override {
        prune();
        return salu;
    }

    bool elim_extract(const IR::BFN::Unit* unit, const IR::Expression* field) {
        if (!self.defuse.getUses(unit, field).empty())
            return false;
        return true;
    }

    const IR::BFN::Extract* preorder(IR::BFN::Extract* extract) override {
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
        if (extract->marshaled_from || extract->hdr_len_inc_stop) {
            return extract; }

        if (auto lval = extract->dest->to<IR::BFN::FieldLVal>()) {
            if (elim_extract(unit, lval->field)) {
                eliminated.insert(lval->toString());
                LOG1("ELIM UNUSED " << extract << " IN UNIT " << DBPrint::Brief << unit);
                return nullptr;
            }
        }

        return extract;
    }

    const IR::BFN::FieldLVal* preorder(IR::BFN::FieldLVal* lval) override {
        auto tcs = findOrigCtxt<IR::BFN::TotalContainerSize>();
        if (!tcs) return lval;

        if (eliminated.count(lval->toString())) {
            LOG1("ELIM UNUSED " << lval << " IN UNIT " << DBPrint::Brief << tcs);
            return nullptr;
        }

        return lval;
    }

    const IR::BFN::ChecksumVerify* preorder(IR::BFN::ChecksumVerify* verify) override {
        auto unit = findOrigCtxt<IR::BFN::Unit>();
        if (!unit) return verify;
        if (verify->dest && !self.defuse.getUses(unit, verify->dest->field).empty())
            return verify;

        LOG1("ELIM UNUSED " << verify << " IN UNIT " << DBPrint::Brief << unit);
        return nullptr;
    }

    const IR::MAU::Instruction *preorder(IR::MAU::Instruction *i) override {
        auto unit = findOrigCtxt<IR::BFN::Unit>();
        if (!unit) return i;
        if (!i->operands[0]) return i;
        if (!self.defuse.getUses(unit, i->operands[0]).empty()) return i;
        LOG1("ELIM UNUSED instruction " << i << " IN UNIT " << DBPrint::Brief << unit);
        return nullptr;
    }

    bool equiv(const IR::Expression *a, const IR::Expression *b) {
        if (*a == *b) return true;
        if (typeid(*a) != typeid(*b)) return false;
        if (auto ca = a->to<IR::Cast>()) {
            auto cb = b->to<IR::Cast>();
            return ca->type == cb->type && equiv(ca->expr, cb->expr);
        }
        return false;
    }

    const IR::MAU::Instruction *postorder(IR::MAU::Instruction *i) override {
        /// HACK(hanw): copy-propagation introduces set(a, a) instructions, which
        /// is not deadcode eliminated because 'a' is still in-use in the control flow.
        if (i->name == "set" && (i->operands[0])->equiv(*i->operands[1]))
            return nullptr;
        return i;
    }

    const IR::GlobalRef *preorder(IR::GlobalRef *gr) override {
        prune();  // don't go through these.
        return gr; }

 public:
    explicit Instructions(ElimUnused &self) : self(self) {}
};

class ElimUnused::Headers : public PardeTransform {
    ElimUnused &self;

    const IR::BFN::Transition *postorder(IR::BFN::Transition *transition) override {
        const auto* next = transition->next;

        if (!next)
            return transition;

        // If the next state has any statement, any branching, it's not dead.
        if (next->statements.size() > 0 || next->transitions.size() > 1)
            return transition;

        // No transition
        if (next->transitions.size() == 0) {
            transition->next = nullptr;
            return transition;
        }

        auto* next_single_transition = *next->transitions.begin();
        // Not a leaf state.
        if (next_single_transition->next != nullptr)
            return transition;

        // Eliminate that state.
        transition->next = nullptr;
        if (next_single_transition->shift)
            transition->shift = *transition->shift + *next_single_transition->shift;

        LOG1("ELIM UNUSED parser state " << next->name);
        return transition;
    }

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
    addPasses({ new PassRepeated({
        new Instructions(*this),
        &defuse,
        new Headers(*this),
        &defuse
    })});
}
