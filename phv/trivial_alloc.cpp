#include "trivial_alloc.h"
#include "lib/range.h"
#include "lib/exceptions.h"

class PHV::TrivialAlloc::Uses : public Inspector {
 public:
    bitvec      use[2][2];
    /*              |  ^- gress                 */
    /*              0 == use in parser/deparser */
    /*              1 == use in mau             */
    explicit Uses(const PhvInfo &p) : phv(p) { }

 private:
    const PhvInfo       &phv;
    gress_t             thread;
    bool                in_mau;
    bool preorder(const IR::Tofino::Parser *p) {
        in_mau = false;
        thread = p->gress;
        revisit_visited();
        return true; }
    bool preorder(const IR::Tofino::Deparser *d) {
        thread = d->gress;
        in_mau = true;  // treat egress_port as in mau as it can't go in TPHV
        revisit_visited();
        visit(d->egress_port);
        in_mau = false;
        revisit_visited();
        d->emits.visit_children(*this);
        return false; }
    bool preorder(const IR::MAU::TableSeq *) {
        in_mau = true;
        revisit_visited();
        return true; }
    bool preorder(const IR::HeaderRef *hr) {
        if (auto head = phv.header(hr))
            use[in_mau][thread].setrange(head->first, head->second - head->first + 1);
        return false; }
    bool preorder(const IR::Expression *e) {
        if (auto info = phv.field(e)) {
            LOG3("use " << info->name << " in " << thread << (in_mau ? " mau" : ""));
            use[in_mau][thread][info->id] = true;
            return false; }
        return true; }
};

struct PHV::TrivialAlloc::Regs {
    PHV::Container      B, H, W;
};

static bool tagalong_full(int size, PHV::TrivialAlloc::Regs *use) {
    unsigned bytes = (size+7)/8U;
    return  (bytes >= 4 && use->W.index() + bytes/4 > 32) ||
            ((bytes & 2) && use->H.index() >= 48) ||
            ((bytes & 1) && use->B.index() >= 32);
}

void PHV::TrivialAlloc::do_alloc(PhvInfo::Field *i, Regs *use, Regs *skip, int merge_follow) {
    /* greedy allocate space for field */
    static struct {
        PHV::Container PHV::TrivialAlloc::Regs::*   alloc;
        int                                         size;
    } alloc_types[3] = {
        { &PHV::TrivialAlloc::Regs::W, 32 },
        { &PHV::TrivialAlloc::Regs::H, 16 },
        { &PHV::TrivialAlloc::Regs::B, 8 },
    };

    int size = i->size;
    int isize = i->size;
    LOG2(i->id << ": " << (i->metadata ? "metadata " : "header ") << i->name <<
         " size=" << i->size);
    for (int m = 1; m <= merge_follow; ++m) {
        size += phv.field(i->id + m)->size;
        LOG2("+ " << (i->id+m) << " : " << phv.field(i->id + m)->name << " size=" <<
             phv.field(i->id + m)->size); }
    for (auto &rtype : alloc_types) {
        while (size > rtype.size - 8 || (size > 16 && i->metadata)) {
            int abits = rtype.size;
            while (isize < abits && merge_follow) {
                i->alloc.emplace_back(use->*rtype.alloc, 0, abits-isize, isize);
                LOG3("   allocated " << i->alloc << " for " << i->gress);
                abits -= isize;
                i = phv.field(i->id + 1);
                merge_follow--;
                isize = i->size; }
            if ((isize -= abits) < 0) {
                abits += isize;
                isize = 0; }
            i->alloc.emplace_back((use->*rtype.alloc)++, isize, 0, abits);
            if (skip && use->*rtype.alloc == skip[0].*rtype.alloc)
                use->*rtype.alloc = skip[1].*rtype.alloc;
            size -= rtype.size; } }
    LOG3("   allocated " << i->alloc << " for " << i->name);
}

void alloc_pov(PhvInfo::Field *i, PhvInfo::Field *pov) {
    LOG2(i->id << ": POV " << i->name << " bit=" << i->offset);
    int width = i->size, use = 0;
    while ((use = width) > 0) {
        auto &sl = pov->for_bit(i->offset + width - 1);
        if (i->offset < sl.field_bit)
            use -= sl.field_bit - i->offset;
        width -= use;
        i->alloc.emplace_back(sl.container, width, i->offset + width - sl.field_bit, use); }
    LOG3("   allocated " << i->alloc << " for " << i->name);
}

static void adjust_skip_for_egress(PHV::Container &reg, unsigned group_size,
                                   PHV::Container &skip0, PHV::Container &skip1) {
    if (reg.index() > skip1.index()) {
        /* we allocateds some shared regs to ingress, so skip over those groups while
         * allocating for egress */
        while (reg.index() % group_size) ++reg;
        auto tmp = skip0;
        skip0 = skip1;
        skip1 = reg;
        reg = tmp;
    } else {
        /* didn't get to shared regs, so no need to skip anything in egress */
        reg = skip1 = skip0; }
}

bool PHV::TrivialAlloc::preorder(const IR::Tofino::Pipe *pipe) {
    if (phv.alloc_done()) return false;
    Uses uses(phv);
    Regs normal = { "B0", "H0", "W0" },
         tagalong = { "TB0", "TH0", "TW0" },
         skip[2] = { { "B16", "H16", "W16" }, { "B32", "H32", "W32" } };
            // skip over egress-only regs in ingress
    pipe->apply(uses);
    for (auto gr : Range(INGRESS, EGRESS)) {
        PhvInfo::Field *pov = nullptr;
        /* enforce group splitting limits between ingress and egress */
        if (gr == EGRESS) {
            adjust_skip_for_egress(normal.B, 8, skip[0].B, skip[1].B);
            adjust_skip_for_egress(normal.H, 8, skip[0].H, skip[1].H);
            adjust_skip_for_egress(normal.W, 4, skip[0].W, skip[1].W);
            unsigned tagalong_group = std::max((tagalong.B.index() + 3)/4,
                    std::max((tagalong.H.index() + 5)/6, (tagalong.W.index() + 3)/4));
            tagalong.B = PHV::Container::TB(tagalong_group * 4);
            tagalong.H = PHV::Container::TH(tagalong_group * 6);
            tagalong.W = PHV::Container::TW(tagalong_group * 4); }

        std::vector<PhvInfo::Field *> pov_fields;
        for (auto &field : phv) {
            if (field.gress != gr)
                continue;
            if (field.alloc.empty()) {
                if (pov) {
                    BUG_CHECK(field.pov, "Non POV field after POV");
                    alloc_pov(&field, pov);
                } else if (field.name.endsWith("$POV")) {
                    do_alloc((pov = &field), &normal, skip);
                    for (auto *f : pov_fields)
                        alloc_pov(f, pov);
                } else if (field.pov) {
                    pov_fields.push_back(&field);
                } else {
                    bool use_mau = uses.use[1][gr][field.id];
                    bool use_any = uses.use[0][gr][field.id];
                    int merge_follow = 0;
                    if (!field.metadata && field.size % 8U != 0 && field.offset > 0) {
                        int size = field.size;
                        while (size % 8U != 0) {
                            auto mfield = phv.field(field.id + ++merge_follow);
                            use_mau |= uses.use[1][gr][mfield->id];
                            use_any |= uses.use[0][gr][mfield->id];
                            size += mfield->size;
                            assert(!mfield->metadata);
                            if (mfield->offset == 0) break; } }
                    if (use_mau) {
                        do_alloc(&field, &normal, skip, merge_follow);
                    } else if (use_any) {
                        if (tagalong_full(field.size, &tagalong))
                            do_alloc(&field, &normal, skip, merge_follow);
                        else
                            do_alloc(&field, &tagalong, nullptr, merge_follow);
                    } else {
                        LOG2(field.id << ": " << field.name << " unused in " << gr); } } } } }
    return false;
}

