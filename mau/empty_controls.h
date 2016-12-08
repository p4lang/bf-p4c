#ifndef TOFINO_MAU_EMPTY_CONTROLS_H_
#define TOFINO_MAU_EMPTY_CONTROLS_H_

#include "mau_visitor.h"

class RemoveEmptyControls : public MauTransform {
    const IR::MAU::Table *postorder(IR::MAU::Table *tbl) override {
        if (auto def = tbl->next.get<IR::MAU::TableSeq>("$default")) {
            if (def->tables.empty())
                tbl->next.erase("$default"); }
        if (!tbl->next.count("$default")) {
            for (auto it = tbl->next.begin(); it != tbl->next.end();) {
                if (it->second->tables.empty())
                    it = tbl->next.erase(it);
                else
                    ++it; } }
        if (!tbl->match_table && tbl->next.empty())
            return nullptr;
        return tbl; }
};

#endif /* TOFINO_MAU_EMPTY_CONTROLS_H_ */
