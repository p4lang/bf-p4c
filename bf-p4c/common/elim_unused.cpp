#include "elim_unused.h"
#include <string.h>
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "lib/log.h"

class ElimUnused::Instructions : public Transform {
    ElimUnused &self;
    IR::MAU::StatefulAlu *preorder(IR::MAU::StatefulAlu *salu) override {
        prune();
        return salu; }

    IR::BFN::Extract* preorder(IR::BFN::Extract* extract) override {
        auto unit = findOrigCtxt<IR::BFN::Unit>();
        if (!unit) return extract;
        if (!self.defuse.getUses(unit, extract->dest->field).empty())
            return extract;

        // XXX(cole): We should find a better mechanism rather than overlaying stkvalid.
        if (strstr(extract->dest->field->toString().c_str(), "$stkvalid"))
            return extract;

        LOG1("ELIM UNUSED " << extract << " IN UNIT " << DBPrint::Brief << unit);
        return nullptr;
    }

    IR::BFN::VerifyChecksum* preorder(IR::BFN::VerifyChecksum* verify) override {
        auto unit = findOrigCtxt<IR::BFN::Unit>();
        if (!unit) return verify;
        if (verify->parserError &&
            !self.defuse.getUses(unit, verify->parserError->field).empty())
            return verify;

        LOG1("ELIM UNUSED " << verify << " IN UNIT " << DBPrint::Brief << unit);
        return nullptr;
    }

    IR::MAU::Instruction *preorder(IR::MAU::Instruction *i) override {
        auto unit = findOrigCtxt<IR::BFN::Unit>();
        if (!unit) return i;
        if (!i->operands[0]) return i;
        if (!self.defuse.getUses(unit, i->operands[0]).empty()) return i;
        LOG1("ELIM UNUSED instruction " << i << " IN UNIT " << DBPrint::Brief << unit);
        return nullptr;
    }

    IR::GlobalRef *preorder(IR::GlobalRef *gr) override {
        prune();  // don't go through these.
        return gr; }

 public:
    explicit Instructions(ElimUnused &self) : self(self) {}
};

class ElimUnused::Headers : public PardeTransform {
    ElimUnused &self;

    IR::BFN::Transition *postorder(IR::BFN::Transition *transition) override {
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
        // XXX(seth): We should really be checking if any reaching definition
        // could be setting it to something other than zero.
        auto* field = self.phv.field(fieldRef);
        if (!field) return true;
        return !self.defuse.getAllDefs(field->id).empty();
    }

    IR::BFN::Emit* preorder(IR::BFN::Emit* emit) override {
        prune();

        // The emit primitive is used if the POV bit being set somewhere.
        if (hasDefs(emit->povBit->field)) return emit;

        LOG1("ELIM UNUSED emit " << emit << " IN UNIT " <<
             DBPrint::Brief << findContext<IR::BFN::Unit>());
        return nullptr;
    }

    IR::BFN::EmitChecksum* preorder(IR::BFN::EmitChecksum* emit) override {
        prune();

        // The emit checksum primitive is used if the POV bit being set somewhere.
        if (hasDefs(emit->povBit->field)) return emit;

        LOG1("ELIM UNUSED emit checksum " << emit << " IN UNIT " <<
             DBPrint::Brief << findContext<IR::BFN::Unit>());
        return nullptr;
    }

    IR::BFN::DeparserParameter*
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
