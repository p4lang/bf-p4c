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

    IR::MAU::Instruction *preorder(IR::MAU::Instruction *i) override {
        auto unit = findOrigCtxt<IR::BFN::Unit>();
        if (!unit) return i;
        if (!i->operands[0]) return i;
        if (!self.defuse.getUses(unit, i->operands[0]).empty()) return i;
        LOG1("elim unused instruction " << i << " IN UNIT " << DBPrint::Brief << unit);
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

    IR::BFN::ParserState *postorder(IR::BFN::ParserState *state) override {
        // XXX(seth): It's unclear to me whether there's any reason to maintain
        // these restrictions.
        if (state->name == "ingress::$ingress_metadata_shim" ||
            state->name == "egress::$egress_metadata_shim")
            return state;  // do not eliminate the shims
        if (state->name == "ingress::start$")
            /* FIXME -- it SHOULD be ok to eliminate this if it isn't needed in the
             * ingress pipe (all processing done in egress pipe), but harlyn doesn't
             * like it */
            return state;
        if (state->name == "egress::start$")
            /* FIXME -- similar reason to ingress::start$. In addition, eliminating
             * start state in egress triggers a NULL check in IR */
            return state;

        if (!state->statements.empty()) return state;

        for (auto* transition : state->transitions) {
            if (transition->next) return state;
            if (transition->shift && *transition->shift == 0) return state;
        }

        LOG1("ELIMINATING parser state " << state->name);
        return nullptr; }

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

        LOG1("ELIMINATING emit " << emit << " IN UNIT " <<
             DBPrint::Brief << findContext<IR::BFN::Unit>());
        return nullptr;
    }

    IR::BFN::EmitChecksum* preorder(IR::BFN::EmitChecksum* emit) override {
        prune();

        // The emit checksum primitive is used if the POV bit being set somewhere.
        if (hasDefs(emit->povBit->field)) return emit;

        LOG1("ELIMINATING emit checksum " << emit << " IN UNIT " <<
             DBPrint::Brief << findContext<IR::BFN::Unit>());
        return nullptr;
    }

    IR::BFN::DeparserParameter*
    preorder(IR::BFN::DeparserParameter* param) override {
        prune();

        // We don't need to set a deparser parameter if the field it gets its
        // value from is never set.
        if (hasDefs(param->source->field)) return param;

        LOG1("ELIMINATING deparser parameter " << param << " IN UNIT " <<
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
