#include "elim_unused.h"
#include <string.h>
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/parde/dump_parser.h"
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
        if (extract->marshaled_from) {
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

    const IR::GlobalRef *preorder(IR::GlobalRef *gr) override {
        prune();  // don't go through these.
        return gr; }

 public:
    explicit Instructions(ElimUnused &self) : self(self) {}
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
            new Headers(*this),
            &defuse}),
        LOGGING(4) ? new DumpParser("after_elim_unused") : nullptr
    });
}
