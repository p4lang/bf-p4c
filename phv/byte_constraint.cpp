#include "byte_constraint.h"
#include <base/logging.h>
#include "constraints.h"
#include "ir/ir.h"

bool ByteConstraint::preorder(const IR::Primitive *prim) {
    if ("emit" == prim->name) {
        LOG2("Adding byte/deparser constraints for " << (*prim));
        const IR::Tofino::Deparser *deparser = findContext<IR::Tofino::Deparser>();
        CHECK(nullptr != deparser) << "; Cannot find context for " << (*prim);
        const gress_t gress = deparser->gress;
        auto bytes(GetBytes(prim->operands[0], nullptr));
        CHECK(false == bytes.empty()) << "; Cannot find bytes in " << (*prim);
        constraints_.SetEqualByte(bytes.begin(), bytes.end());
        constraints_.SetDeparsedHeader(bytes.begin(), bytes.end(), gress);
        if (auto *hdr = prim->operands[0]->to<IR::HeaderRef>()) {
            if (auto *pov = phv.field(hdr->toString() + ".$valid"))
                constraints_.SetDeparsedPOV(pov->bit(0), gress);
            else
                BUG("header %s doesn't have POV bit?", hdr);
        } else if (auto *pov = phv.field("$bridge-metadata")) {
            constraints_.SetDeparsedPOV(pov->bit(0), gress); }
    } else if ("extract" == prim->name) {
        // FIXME: When extract primitive has been changed to
        // extract(IR::HeaderSliceRef*) where the HeaderSliceRef object points to
        // the whole header, uncomment the code below.
        // auto bytes(GetBytes(prim->operands[0], nullptr));
        // constraints_.SetEqualByte(bytes.begin(), bytes.end());
    } else if (prim->name == "set_metadata") {
        auto bytes(GetBytes(prim->operands[0], prim->operands[1]));
        constraints_.SetEqualByte(bytes.begin(), bytes.end()); }
    if ("add" == prim->name || "subtract" == prim->name ||
        "add_to_field" == prim->name || "subtract_from_field" == prim->name) {
        LOG2("Setting constraint for " << (*prim));
        for (auto &op : prim->operands) {
            std::list<PHV::Bit> bits = GetBits(op);
            constraints_.SetContiguousBits(PHV::Bits(bits.begin(), bits.end())); } }
    return false;
}

bool ByteConstraint::preorder(const IR::Tofino::Deparser *dp) {
    std::list<PHV::Bit> bits = GetBits(dp->egress_port);
    constraints_.SetOffset(*bits.begin(), 0, 7);
    LOG2("Setting deparser egress port constraint for " << PHV::Bits(bits.begin(), bits.end()));
    constraints_.SetContiguousBits(PHV::Bits(bits.begin(), bits.end()));
    constraints_.SetDeparserBits(bits.begin(), bits.end(), dp->gress);
    return true;
}
