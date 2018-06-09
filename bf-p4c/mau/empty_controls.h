#ifndef BF_P4C_MAU_EMPTY_CONTROLS_H_
#define BF_P4C_MAU_EMPTY_CONTROLS_H_

#include "mau_visitor.h"

class RemoveEmptyControls : public MauTransform {
    const IR::MAU::Table *postorder(IR::MAU::Table *tbl) override {
        if (tbl->next.count("$default")) {
            auto def = tbl->next.at("$default");
            if (def->tables.empty())
                tbl->next.erase("$default"); }
        else {
            for (auto it = tbl->next.begin(); it != tbl->next.end();) {
                if (it->second->tables.empty())
                    it = tbl->next.erase(it);
                else
                    ++it; } }
        if (tbl->gateway_only() && tbl->next.empty())
            return nullptr;
        return tbl; }
};

#endif /* BF_P4C_MAU_EMPTY_CONTROLS_H_ */
