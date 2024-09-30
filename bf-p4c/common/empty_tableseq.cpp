#include "empty_tableseq.h"

void AddEmptyTableSeqs::postorder(P4::IR::BFN::Pipe* pipe) {
    // Ensure pipes do not have null table sequences.
    for (auto& thread : pipe->thread) {
        if (!thread.mau) thread.mau = new P4::IR::MAU::TableSeq();
    }
}

void AddEmptyTableSeqs::postorder(P4::IR::MAU::Table* tbl) {
    if (tbl->next.empty()) {
        // No conditional flow based on the result of this table, so nothing to do here.
        return;
    }

    if (tbl->hit_miss_p4()) {
        for (auto key : { "$hit"_cs, "$miss"_cs }) {
            if (tbl->next.count(key) == 0) tbl->next[key] = new P4::IR::MAU::TableSeq();
        }
    } else if (tbl->has_default_path()) {
        // Nothing to do.
    } else if (tbl->action_chain() && tbl->next.size() < tbl->actions.size()) {
        tbl->next["$default"_cs] = new P4::IR::MAU::TableSeq();
    }

    for (auto& row : tbl->gateway_rows) {
        auto key = row.second;
        if (key && tbl->next.count(key) == 0) {
            tbl->next[key] = new P4::IR::MAU::TableSeq();
        }
    }
}
