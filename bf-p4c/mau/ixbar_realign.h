#ifndef BF_P4C_MAU_IXBAR_REALIGN_H_
#define BF_P4C_MAU_IXBAR_REALIGN_H_

#include <array>
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "lib/safe_vector.h"

class IXBarVerify: public MauModifier {
    const PhvInfo       &phv;
    const IR::MAU::Table* currentTable = nullptr;
    profile_t init_apply(const IR::Node *) override;
    bool preorder(IR::Expression *) override { return false; }
    void postorder(IR::MAU::Table *) override;
    void verify_format(const IXBar::Use &);
    class GetCurrentUse;
    safe_vector<std::unique_ptr<IXBar>> stage;

 public:
    explicit IXBarVerify(const PhvInfo &phv) : phv(phv) {}
};

#endif /* BF_P4C_MAU_IXBAR_REALIGN_H_ */
