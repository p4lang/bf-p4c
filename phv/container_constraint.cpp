#include "container_constraint.h"
#include "constraints.h"

bool ContainerConstraint::preorder(const IR::Primitive *prim) {
    // FIXME: This should include the extract instruction too. But extract() has
    // to be fixed in the IR.
    if (prim->name == "emit" || prim->name == "extract") {
        LOG2("Setting constraints for " << (*prim));
        for (auto &byte : GetBytes(prim->operands[0], nullptr)) {
            constraints_.SetEqual(byte.cfirst(), byte.clast(),
                                  Constraints::CONTAINER);
        }
    }
    if (prim->name == "set_metadata") {
        LOG2("Setting constraints for " << (*prim));
        for (auto &byte : GetBytes(prim->operands[0], prim->operands[1])) {
            constraints_.SetEqual(byte.cfirst(), byte.clast(),
                                  Constraints::CONTAINER);
        }
    }
    return false;
}

bool ContainerConstraint::preorder(const IR::MAU::Instruction *inst) {
    if (inst->name == "set" ||
        inst->name == "and" || inst->name == "or" || inst->name == "xor" ||
        inst->name == "nand" || inst->name == "nor" || inst->name == "xnor" ||
        inst->name == "andca" || inst->name == "andcb" ||
        inst->name == "orca" || inst->name == "orcb" ||
        inst->name == "alu_a" || inst->name == "alu_b" ||
        inst->name == "nota" || inst->name == "notb" ||
        inst->name == "setz" || inst->name == "sethi") {
        // these instructions can all be split into multiple parallel instructions
        return false; }

    // FIXME: We still do not handle the case where an operands can be split
    // across to adjacent PHVs.
    LOG2("Setting constraint for " << (*inst));
    for (auto &op : inst->operands) {
        std::list<PHV::Bit> bits = GetBits(op);
        constraints_.SetEqual(bits.cbegin(), bits.cend(), Constraints::CONTAINER); }
    return false;
}

bool ContainerConstraint::preorder(const IR::Tofino::Deparser *dp) {
    std::list<PHV::Bit> bits = GetBits(dp->egress_port);
    constraints_.SetEqual(bits.cbegin(), bits.cend(), Constraints::CONTAINER);
    auto ep_field = phv.field(dp->egress_port);
    for (auto &f : phv) {
        if (!f.referenced) continue;
        if (&f == ep_field) continue;
        for (auto b : bits)
            for (int i = 0; i < f.size; ++i)
                constraints_.SetContainerConflict(b, f.bit(i)); }
    return true;
}

namespace {
class FindDests : public Inspector {
    const PhvInfo                       &phv;
    std::set<const PhvInfo::Field *>    &out;
    bool preorder(const IR::MAU::Instruction *inst) override {
        out.insert(phv.field(inst->operands[0]));
        return false; }
    bool preorder(const IR::MAU::TableSeq *) override { return false; }
 public:
    FindDests(const PhvInfo &phv, std::set<const PhvInfo::Field *> &out) : phv(phv), out(out) {}
};
}  // namespace

void ContainerConstraint::postorder(const IR::MAU::Table *tbl) {
    if (size_t(tbl->stage()) >= uses.size())
        uses.resize(tbl->stage() + 1);
    auto &tbl_uses = uses[tbl->stage()][tbl];
    tbl->apply(FindDests(phv, tbl_uses));
    if (tbl_uses.empty()) return;
    for (auto &other : uses[tbl->stage()]) {
        if (other.first == tbl || mutex(other.first, tbl))
            continue;
        for (auto f1 : tbl_uses)
            for (int i = 0; i < f1->size; ++i)
                for (auto f2 : other.second) {
                    if (f1 == f2)
                        continue;
                    for (int j = 0; j < f2->size; ++j)
                        constraints_.SetContainerConflict(f1->bit(i), f2->bit(j)); } }
}
