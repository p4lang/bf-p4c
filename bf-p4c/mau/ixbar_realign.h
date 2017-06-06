#ifndef TOFINO_MAU_IXBAR_REALIGN_H_
#define TOFINO_MAU_IXBAR_REALIGN_H_

#include "resource.h"
#include "mau_visitor.h"

class IXBarRealign : public MauModifier {
    const PhvInfo       &phv;
    profile_t init_apply(const IR::Node *) override;
    bool preorder(IR::Expression *) override { return false; }
    void postorder(IR::MAU::Table *) override;
    class GetCurrentUse;
    struct Realign {
        bool need_remap = false;
        array<array<unsigned char, IXBar::EXACT_BYTES_PER_GROUP>, IXBar::EXACT_GROUPS> remap;
        Realign(const PhvInfo &phv, int stage, const IXBar &ixbar);
        bool remap_use(IXBar::Use &);
    };
    vector<IXBar>       stage;
    vector<Realign>     stage_fix;

 public:
    explicit IXBarRealign(const PhvInfo &phv) : phv(phv) {}
};

#endif /* TOFINO_MAU_IXBAR_REALIGN_H_ */
