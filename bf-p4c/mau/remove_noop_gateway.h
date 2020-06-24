#ifndef BF_P4C_MAU_REMOVE_NOOP_GATEWAY_H_
#define BF_P4C_MAU_REMOVE_NOOP_GATEWAY_H_

#include "mau_visitor.h"

/* "Noop" gateways that don't actually test anything and just trigger another TableSeq
 * may be introduced by MulitpleApply::MergeTails; they don't actually do anything, but
 * are needed to allow table placement to place the tables properly.  We may be able to
 * eliminate them after table placement, which this pass attempts to do */
class RemoveNoopGateway : public MauTransform {
    const IR::MAU::TableSeq *preorder(IR::MAU::TableSeq *seq) override {
        if (seq->size() < 1) return seq;
        auto *last = seq->back();
        if (!last->conditional_gateway_only() || last->gateway_rows.size() != 1
            || last->next.size() != 1) {
            // not a noop gateway
            return seq; }
        if (seq->size() == 1) {
            // drop the noop gateway, going directly to the target TableSeq
            return last->next.begin()->second; }
        auto *prev = seq->tables.at(seq->size() - 2);
        if (!prev->next.empty()) {
            // can't move the dependent tables to the previous table
            return seq; }
        seq->tables.pop_back();         // toss the gateway;
        auto *clone = prev->clone();    // clone the last table
        clone->next["$default"] = last->next.begin()->second;
        // move the dependent sequence to the last table as default next
        seq->tables.back() = clone;
        return seq;
    }
};

#endif /* BF_P4C_MAU_REMOVE_NOOP_GATEWAY_H_ */
