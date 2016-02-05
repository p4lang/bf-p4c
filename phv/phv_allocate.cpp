#include "phv_allocate.h"
#include "lib/range.h"
#include "lib/exceptions.h"

class PhvAllocate::Uses : public Inspector {
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
    bool preorder(const IR::FieldRef *fr) {
        if (auto info = phv.field(fr))
            use[in_mau][thread][info->id] = true;
        return false; }
    bool preorder(const IR::HeaderSliceRef *hs) {
        if (auto info = phv.field(hs))
            use[in_mau][thread][info->id] = true;
        return false; }
};

struct PhvAllocate::Regs {
    PHV::Container      B, H, W;
};

void PhvAllocate::do_alloc(PhvInfo::Info *i, gress_t thread, Regs *use) {
    /* greedy allocate space for field */
    LOG2(i->id << ": " << (i->metadata ? "metadata " : "header ") << i->name <<
         " size=" << i->size);
    int size = i->size, bit = 0;
    while (size > 32) {
        i->alloc[thread].emplace_back(use->W++, bit, 0, 32);
        bit += 32;
        size -= 32; }
    if (size > 16)
        i->alloc[thread].emplace_back(use->W++, bit, 0, size);
    else if (size > 8)
        i->alloc[thread].emplace_back(use->H++, bit, 0, size);
    else
        i->alloc[thread].emplace_back(use->B++, bit, 0, size);
    LOG3("   allocated " << i->alloc[thread] << " for " << thread);
}

void alloc_pov(PhvInfo::Info *i, gress_t thread, PhvInfo::Info *pov, int pov_bit) {
    LOG2(i->id << ": POV " << i->name << " bit=" << pov_bit);
    if (i->size != 1)
        BUG("more than 1 bit for POV bit %s", i->name);
    for (auto &sl : pov->alloc[thread]) {
        int bit = pov_bit - sl.field_bit;
        if (bit >= 0 && bit < sl.width) {
            i->alloc[thread].emplace_back(sl.container, 0, bit + sl.container_bit, 1);
            LOG3("   allocated " << i->alloc[thread] << " for " << thread);
            return; } }
    BUG("Failed to allocate POV bit for %s, POV too small?", i->name);
}

bool PhvAllocate::preorder(const IR::Tofino::Pipe *pipe) {
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
        while (tagalong.B.index() % 4) ++tagalong.B;
        while (tagalong.H.index() % 6) ++tagalong.H;
        while (tagalong.W.index() % 4) ++tagalong.W;
        for (auto &field : phv) {
            if (field.alloc[gr].empty()) {
                if (pov)
                    alloc_pov(&field, gr, pov, pov_bit++);
                else if (field.name == "$POV")
                    do_alloc((pov = &field), gr, &normal);
                else if (uses.use[1][gr][field.id])
                    do_alloc(&field, gr, &normal);
                else if (uses.use[0][gr][field.id])
                    do_alloc(&field, gr, &tagalong);
                else
                    LOG2(field.id << ": " << field.name << " unused in " << gr); } } }
    return false;
}

