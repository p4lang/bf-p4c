#include "greedy_alloc.h"
#include "lib/range.h"
#include "lib/exceptions.h"

class PHV::GreedyAlloc::Uses : public Inspector {
 public:
    bitvec      use[2][2];
    /*              |  ^- gress                 */
    /*              0 == use in parser/deparser */
    /*              1 == use in mau             */
    explicit Uses(const PhvInfo &p) : phv(p) {}

 private:
    const PhvInfo       &phv;
    gress_t             thread;
    bool                in_mau;
    bool preorder(const IR::Tofino::Parser *p) {
        in_mau = false;
        thread = p->gress;
        return true; }
    bool preorder(const IR::Tofino::Deparser *d) {
        thread = d->gress;
        in_mau = true;  // treat egress_port as in mau as it can't go in TPHV
        visit(d->egress_port);
        in_mau = false;
        d->emits.visit_children(*this);
        return false; }
    bool preorder(const IR::MAU::TableSeq *) {
        in_mau = true;
        return true; }
    bool preorder(const IR::HeaderRef *hr) {
        if (auto head = phv.header(hr))
            use[in_mau][thread].setrange(head->first, head->second - head->first + 1);
        return false; }
    bool preorder(const IR::Member *fr) {
        if (auto info = phv.field(fr))
            use[in_mau][thread][info->id] = true;
        return false; }
    bool preorder(const IR::HeaderSliceRef *hs) {
        if (auto info = phv.field(hs))
            use[in_mau][thread][info->id] = true;
        return false; }
};

struct PHV::GreedyAlloc::Regs {
    PHV::Container      B, H, W;
};

void PHV::GreedyAlloc::do_alloc(PhvInfo::Info *i, Regs *use) {
    /* greedy allocate space for field */
    LOG2(i->id << ": " << (i->metadata ? "metadata " : "header ") << i->name <<
         " size=" << i->size);
    int size = i->size;
    while (size > 32) {
        i->alloc.emplace_back(use->W++, size-32, 0, 32);
        size -= 32; }
    if (size > 16)
        i->alloc.emplace_back(use->W++, 0, 0, size);
    else if (size > 8)
        i->alloc.emplace_back(use->H++, 0, 0, size);
    else
        i->alloc.emplace_back(use->B++, 0, 0, size);
    LOG3("   allocated " << i->alloc << " for " << i->gress);
}

void alloc_pov(PhvInfo::Info *i, PhvInfo::Info *pov, int pov_bit) {
    LOG2(i->id << ": POV " << i->name << " bit=" << pov_bit);
    if (i->size != 1)
        BUG("more than 1 bit for POV bit %s", i->name);
    for (auto &sl : pov->alloc) {
        int bit = pov_bit - sl.field_bit;
        if (bit >= 0 && bit < sl.width) {
            i->alloc.emplace_back(sl.container, 0, bit + sl.container_bit, 1);
            LOG3("   allocated " << i->alloc << " for " << i->gress);
            return; } }
    BUG("Failed to allocate POV bit for %s, POV too small?", i->name);
}

bool PHV::GreedyAlloc::preorder(const IR::Tofino::Pipe *pipe) {
    Uses uses(phv);
    Regs normal = { "B0", "H0", "W0" },
         tagalong = { "TB0", "TH0", "TW0" };
    pipe->apply(uses);
    for (auto gr : Range(INGRESS, EGRESS)) {
        PhvInfo::Info *pov = nullptr;
        int pov_bit = 0;
        /* enforce group splitting limits between ingress and egress */
        while (normal.B.index() % 8) ++normal.B;
        while (normal.H.index() % 8) ++normal.H;
        while (normal.W.index() % 4) ++normal.W;
        unsigned tagalong_group = std::max((tagalong.B.index() + 3)/4,
                std::max((tagalong.H.index() + 5)/6, (tagalong.W.index() + 3)/4));
        tagalong.B = PHV::Container::TB(tagalong_group * 4);
        tagalong.H = PHV::Container::TH(tagalong_group * 6);
        tagalong.W = PHV::Container::TW(tagalong_group * 4);

        for (auto &field : phv) {
            if (field.gress != gr)
                continue;
            if (field.alloc.empty()) {
                if (pov)
                    alloc_pov(&field, pov, pov_bit++);
                else if (field.name.endsWith("$POV"))
                    do_alloc((pov = &field), &normal);
                else if (uses.use[1][gr][field.id])
                    do_alloc(&field, &normal);
                else if (uses.use[0][gr][field.id])
                    do_alloc(&field, &tagalong);
                else
                    LOG2(field.id << ": " << field.name << " unused in " << gr); } } }
    return false;
}

