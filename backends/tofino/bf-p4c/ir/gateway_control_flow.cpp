#include "gateway_control_flow.h"

const IR::MAU::Table *BFN::GatewayControlFlow::gateway_context(int &idx) const {
    const Context *ctxt = nullptr;
    if (auto *rv = findContext<IR::MAU::Table>(ctxt)) {
        if (size_t(ctxt->child_index) >= rv->gateway_rows.size())
            return nullptr;
        idx = ctxt->child_index;
        return rv; }
    return nullptr;
}

const IR::MAU::Table *BFN::GatewayControlFlow::gateway_context(cstring &tag) const {
    int idx;
    auto *rv = gateway_context(idx);
    if (rv)
        tag = rv->gateway_rows[idx].second;
    return rv;
}

std::set<cstring> BFN::GatewayControlFlow::gateway_earlier_tags() const {
    const Context *ctxt = nullptr;
    std::set<cstring> rv;
    if (auto *tbl = findContext<IR::MAU::Table>(ctxt)) {
        for (int i = 0; i < ctxt->child_index &&
                        i < static_cast<int>(tbl->gateway_rows.size()); ++i)
            rv.insert(tbl->gateway_rows[i].second); }
    return rv;
}

std::set<cstring> BFN::GatewayControlFlow::gateway_later_tags() const {
    const Context *ctxt = nullptr;
    std::set<cstring> rv;
    if (auto *tbl = findContext<IR::MAU::Table>(ctxt)) {
        for (size_t i = ctxt->child_index + 1; i < tbl->gateway_rows.size(); ++i)
            rv.insert(tbl->gateway_rows[i].second); }
    return rv;
}
