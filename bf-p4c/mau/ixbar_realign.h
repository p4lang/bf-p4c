#ifndef BF_P4C_MAU_IXBAR_REALIGN_H_
#define BF_P4C_MAU_IXBAR_REALIGN_H_

#include <array>
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "lib/safe_vector.h"

class IXBarRealign : public MauModifier {
    const PhvInfo       &phv;
    profile_t init_apply(const IR::Node *) override;
    bool preorder(IR::Expression *) override { return false; }
    void postorder(IR::MAU::Table *) override;
    void verify_format(const IXBar::Use &);
    class GetCurrentUse;
    struct Realign {
        bool need_remap = false;
        std::array<std::array<unsigned char, IXBar::EXACT_BYTES_PER_GROUP>,
                   IXBar::EXACT_GROUPS> remap;
        Realign(const PhvInfo &phv, int stage, const IXBar &ixbar);
        bool remap_use(IXBar::Use &);
    };
    safe_vector<IXBar>       stage;
    safe_vector<Realign>     stage_fix;

 public:
    explicit IXBarRealign(const PhvInfo &phv) : phv(phv) {}
};

#endif /* BF_P4C_MAU_IXBAR_REALIGN_H_ */
