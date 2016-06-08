#include "ixbar_realign.h"
#include "tofino/phv/phv_fields.h"
#include "lib/hex.h"

class IXBarRealign::GetCurrentUse : public MauInspector {
    IXBarRealign        &self;
    bool preorder(const IR::Expression *) override { return false; }
    bool preorder(const IR::MAU::Table *t) override {
        BUG_CHECK(t->logical_id >= 0, "Table not placed");
        unsigned stage = t->stage();
        if (stage >= self.stage.size())
            self.stage.resize(stage + 1);
        self.stage[stage].update(t);
        return true; }
 public:
    explicit GetCurrentUse(IXBarRealign &s) : self(s) {}
};

IXBarRealign::Realign::Realign(const PhvInfo &phv, int stage, const IXBar &ixbar) {
    for (int grp = 0; grp < IXBar::EXACT_GROUPS; ++grp) {
        unsigned inuse = 0, do_remap = 0;
        for (int i = 0; i < IXBar::EXACT_BYTES_PER_GROUP; ++i) {
            remap[grp][i] = 0;
            auto &use = ixbar.exact_use.at(grp, i);
            if (!use.first) continue;
            auto *field = phv.field(use.first);
            BUG_CHECK(field, "%s on ixbar but not in phv?", use.first);
            auto &alloc = field->for_bit(use.second * 8);
            unsigned mask = (1 << alloc.container.log2sz()) - 1;
            int byte = (use.second*8 - alloc.field_bit + alloc.container_bit)/8;
            if (((i ^ byte) & mask) == 0) {
                remap[grp][i] = i;
                inuse |= 1 << i;
            } else {
                remap[grp][i] = mask + (byte << 4);
                do_remap |= 1 << i; } }
        if (!do_remap) continue;
        need_remap = true;
        LOG2("need realignment for stage " << stage << " group " << grp <<
             " inuse=" << hex(inuse) << " do_remap=" << hex(do_remap));
        for (int i = 0; i < IXBar::EXACT_BYTES_PER_GROUP; ++i, do_remap >>= 1) {
            if (!(do_remap & 1)) continue;
            int byte = remap[grp][i] >> 4;
            int step = (remap[grp][i] & 0xf) + 1;
            bool done = false;
            for (int j = byte; j < IXBar::EXACT_BYTES_PER_GROUP; j += step) {
                if (!((inuse >> j) & 1)) {
                    remap[grp][i] = j;
                    inuse |= 1 << j;
                    done = true;
                    break; } }
            BUG_CHECK(done, "Failed to remap ixbar for alignment, stage %d group %d",
                            stage, grp); } }
}

bool IXBarRealign::Realign::remap_use(IXBar::Use &use) {
    if (use.ternary) return false;
    bool rv = false;
    for (auto &byte : use.use) {
        int nbyte = remap[byte.loc.group][byte.loc.byte];
        if (nbyte != byte.loc.byte) {
            byte.loc.byte = nbyte;
            rv = true; } }
    return rv;
}

Visitor::profile_t IXBarRealign::init_apply(const IR::Node *root) {
    auto rv = MauModifier::init_apply(root);
    root->apply(GetCurrentUse(*this));
    int stageno = 0;
    for (auto &ixbar : stage)
        stage_fix.emplace_back(phv, stageno++, ixbar);
    return rv;
}

void IXBarRealign::postorder(IR::MAU::Table *tbl) {
    auto &remap = stage_fix[tbl->stage()];
    if (remap.need_remap) {
        auto rsrc = new TableResourceAlloc(*tbl->resources);
        if (remap.remap_use(rsrc->gateway_ixbar) | remap.remap_use(rsrc->match_ixbar))
            tbl->resources = rsrc; }
}
