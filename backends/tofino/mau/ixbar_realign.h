#ifndef BF_P4C_MAU_IXBAR_REALIGN_H_
#define BF_P4C_MAU_IXBAR_REALIGN_H_

#include <array>
#include "backends/tofino/mau/mau_visitor.h"
#include "backends/tofino/mau/resource.h"
#include "lib/safe_vector.h"

class IXBarVerify: public MauModifier {
    const PhvInfo       &phv;
    const IR::MAU::Table* currentTable = nullptr;
    profile_t init_apply(const IR::Node *) override;
    bool preorder(IR::Expression *) override { return false; }
    void postorder(IR::MAU::Table *) override;
    void verify_format(const IXBar::Use *);
    class GetCurrentUse;
    // Array of Map of Stage -> Input Xbar
    // Tofino 1/2 only uses ixbar[0] for both ingress and egress.
    // TOF3-DOC: Tofino 3 also only uses ixbar[0] for both ingress and egress.
    // TOF5-DOC: Tofino 5 uses ixbar[0] for ingress and ixbar[1] for egress.
    std::map<int, std::unique_ptr<IXBar>> ixbar[2];

 public:
    explicit IXBarVerify(const PhvInfo &phv) : phv(phv) {}
};

#endif /* BF_P4C_MAU_IXBAR_REALIGN_H_ */
