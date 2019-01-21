#ifndef BF_P4C_PARDE_EGRESS_PACKET_LENGTH_H_
#define BF_P4C_PARDE_EGRESS_PACKET_LENGTH_H_


#include "ir/ir.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/parde/parde_visitor.h"

// Issue (paragraph below copied from Glass):
//
// When packet is sent from ingress to egress, packet length presented to egress pipeline is
// the original packet length as the packet entered the ingress pipeline. (It will be 0 if
// in cut-through mode.)
//
// That is, there is no addition/subtraction based on headers added/removed or if bridged
// metadata is added.
//
// For mirrored packets, the packet length presented to the egress pipeline is:
//   the original packet length as it entered ingress plus the size of the mirror table plus 4 bytes
//   (for the CRC that is appended)
//
// So, we only have to perform adjustment for mirrored packets.
//
//
// Implementation:
//
// 1) In each mirror field list parser state, we inserts a parser extract which writes the adjust
//    amount to a field, "egress_pkt_len_adjust". The value to extract, a compile time constant,
//    is known after PHV allocation, when we known which containers mirror metadata is allocated
//    in, and therefore can calculate total number of bytes to adjust (in terms of container size).
//    To carry this late binding constant in the IR, we introduce the IR::BFN::TotalContainerSize
//    type. We resolve these in the LowerParser pass.
//
// 2) Inserts a no-match table that runs the action below, somewhere in the egress table sequence
//    before the first use of "egress_pkt_length" [*].
//
//    egress_pkt_length = egress_pkt_length - egress_pkt_len_adjust
//
// *] We can potentially even save this table by inserting the action in all actions that preceed
//    the first use of "egress_pkt_length". But this could be general table fusing optimization
//    in the figure.

class ExtractEgressPacketLengthAdjust : public ParserModifier {
    const PhvInfo& phv;
    const FieldDefUse& defuse;

 public:
    const IR::TempVar* egressPacketLengthAdjust;

    ExtractEgressPacketLengthAdjust(const PhvInfo& phv,
                                    const FieldDefUse& defuse,
                                    IR::TempVar* epla) :
        phv(phv),
        defuse(defuse),
        egressPacketLengthAdjust(epla) { }

 private:
    bool preorder(IR::BFN::Parser* parser) override {
        auto f = phv.field("egress::eg_intr_md.pkt_length");

        bool hasUse = f && !defuse.getAllUses(f->id).empty();

        return (hasUse && parser->gress == EGRESS);
    }

    bool preorder(IR::BFN::ParserState* state) override {
        if (state->name.startsWith("$mirror_field_list_")) {
            IR::Vector<IR::BFN::FieldLVal> dests;
            for (auto stmt : state->statements) {
                if (auto extract = stmt->to<IR::BFN::Extract>()) {
                    if (auto lval = extract->dest->to<IR::BFN::FieldLVal>())
                        dests.push_back(lval);
                }
            }

            auto adjustAmount = new IR::BFN::TotalContainerSize(dests);
            auto extract = new IR::BFN::Extract(egressPacketLengthAdjust, adjustAmount);
            state->statements.push_back(extract);
        }

        return true;
    }
};


class InsertEgressPacketLengthAdjustTable : public MauTransform {
    const PhvInfo& phv;
    const FieldDefUse& defuse;

 public:
    const IR::TempVar* egressPacketLengthAdjust;

    InsertEgressPacketLengthAdjustTable(const PhvInfo& phv,
                                        const FieldDefUse& defuse,
                                        IR::TempVar* epla) :
        phv(phv),
        defuse(defuse),
        egressPacketLengthAdjust(epla) { }

 private:
    IR::MAU::TableSeq* preorder(IR::MAU::TableSeq* tableSeq) override {
        prune();

        auto f = phv.field("egress::eg_intr_md.pkt_length");

        bool hasUse = f && !defuse.getAllUses(f->id).empty();

        if (!hasUse)
            return tableSeq;

        auto gress = VisitingThread(this);
        if (gress != EGRESS) return tableSeq;

        auto adjustTable = new IR::MAU::Table("egress_pkt_length_adjust", EGRESS);
        adjustTable->is_compiler_generated = true;

        adjustTable->match_table = new IR::P4Table(cstring("no_match"), new IR::TableProperties());

        auto action = new IR::MAU::Action("_subtract_adjust_amount_");
        action->default_allowed = action->init_default = true;

        auto pipe = findContext<IR::BFN::Pipe>();
        auto egMetadata = getMetadataType(pipe, "egress::egress_intrinsic_metadata");
        auto egressPacketLength = gen_fieldref(egMetadata, "pkt_length");

        auto subtract = new IR::MAU::Instruction("sub",
            { egressPacketLength, egressPacketLength, egressPacketLengthAdjust });

        action->action.push_back(subtract);
        adjustTable->actions[action->name] = action;
        tableSeq->tables.insert(tableSeq->tables.begin(), adjustTable);

        return tableSeq;
    }
};


class AdjustEgressPacketLength : public PassManager {
 public:
    AdjustEgressPacketLength(const PhvInfo& phv, const FieldDefUse& defuse) {
        // TODO(zma) put this in the compiler_generated_meta header?
        IR::TempVar* egressPacketLengthAdjust =
            new IR::TempVar(IR::Type::Bits::get(16), false, "egress_pkt_len_adjust");

        addPasses({
            new ExtractEgressPacketLengthAdjust(phv, defuse, egressPacketLengthAdjust),
            new InsertEgressPacketLengthAdjustTable(phv, defuse, egressPacketLengthAdjust)
        });
    }
};

#endif  /* BF_P4C_PARDE_EGRESS_PACKET_LENGTH_H_ */
