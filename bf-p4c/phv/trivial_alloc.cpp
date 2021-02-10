#include "trivial_alloc.h"

#include <algorithm>
#include <boost/range/irange.hpp>  // NOLINT
#include "bf-p4c/device.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/ir/gress.h"
#include "lib/bitvec.h"
#include "lib/exceptions.h"
#include "lib/range.h"

namespace PHV {

static ordered_set<const IR::MAU::Action*> emptyInitSet = {};

/// A group of fields that should be allocated contiguously. Offers a
/// std::vector-like interface.
struct FieldGroup final {
    /// Construct a FieldGroup which will contain fields for thread @gress.
    explicit FieldGroup(gress_t gress) : gress(gress), size(0) { }

    /// Construct a FieldGroup with @field as its first field. The thread and
    /// other properties are derived from @field.
    explicit FieldGroup(PHV::Field& field)
        : gress(field.gress)
        , fields{&field}
        , ids(field.id, 1)
        , size(field.size)
    { }

    PHV::Field& back() const {
        BUG_CHECK(!fields.empty(), "Calling back() on a group with no fields");
        return *fields.back();
    }

    void push_back(PHV::Field& field) {
        BUG_CHECK(field.gress == gress,
                  "Mixing fields for different threads in group?");
        fields.push_back(&field);
        ids.setbit(field.id);
        size += field.size;
    }

    const gress_t gress;                  /// This group's thread.
    std::vector<PHV::Field*> fields;      /// The fields in this group.
    bitvec ids;                           /// The ids of those fields.
    int size;                             /// The total size of all fields.
};

struct TrivialAlloc::Regs {
    PHV::Container      B, H, W;
};

/* 'from' and 'to' are aliased to use the same container(s) so copy the allocations */
void TrivialAlloc::copy_alias(const PHV::Field &from, PHV::Field &to) {
    if (from.is_unallocated()) return;   // nothing to copy (yet)
    from.foreach_alloc(StartLen(0, to.size), [&to](const PHV::AllocSlice &sl) {
        to.add_alloc(sl); });
}

void TrivialAlloc::do_alloc(const FieldGroup& group, Regs *use) {
    /* greedy allocate space for field */
    static struct {
        PHV::Container PHV::TrivialAlloc::Regs::*   alloc;
        int                                         size;
    } alloc_types[3] = {
        { &PHV::TrivialAlloc::Regs::W, 32 },
        { &PHV::TrivialAlloc::Regs::H, 16 },
        { &PHV::TrivialAlloc::Regs::B, 8 },
    };

    if (group.fields.empty()) return;
    PHV::Field *i = group.fields[0];
    unsigned group_index = 0;
    int merge_follow = group.fields.size() - 1;
    int size = i->size;
    int isize = i->size;
    LOG2(i->id << ": " << (i->metadata ? "metadata " : "header ") << i->name <<
         " size=" << i->size);
    for (int m = 1; m <= merge_follow; ++m) {
        size += group.fields[m]->size;
        LOG2("+ " << group.fields[m]->id << " : " << group.fields[m]->name
                  << " size=" << group.fields[m]->size); }
    for (auto &rtype : alloc_types) {
        while (size > rtype.size - 8 || (size > 16 && i->metadata)) {
            int abits = rtype.size;
            while (isize < abits && merge_follow) {
                auto *slice = i->add_and_return_alloc(i, use->*rtype.alloc, 0, abits-isize, isize,
                        emptyInitSet);
                LOG3("   allocated " << *slice << " for " << i->gress);
                abits -= isize;
                i = group.fields[++group_index];
                merge_follow--;
                isize = i->size; }
            if ((isize -= abits) < 0) {
                abits += isize;
                isize = 0; }
            i->add_and_return_alloc(i, (use->*rtype.alloc)++, isize, 0, abits, emptyInitSet);
            size -= rtype.size; } }

    LOG3("   allocated " << i->get_alloc() << " for " << i->name);
}

void TrivialAlloc::postorder(const IR::BFN::AliasMember *alias) {
    aliasSrcs[phv.field(alias->source)->id] = 1;
}
void TrivialAlloc::postorder(const IR::BFN::AliasSlice *alias) {
    aliasSrcs[phv.field(alias->source)->id] = 1;
}

bool TrivialAlloc::preorder(const IR::BFN::Pipe *) {
    aliasSrcs.clear();
    return !phv.alloc_done();
}

void TrivialAlloc::postorder(const IR::BFN::Pipe *pipe) {
    Phv_Parde_Mau_Use uses(phv);
    Regs normal = { "B0", "H0", "W0" };
    pipe->apply(uses);
    std::map<gress_t, FieldGroup> pov_fields;

    for (auto &field : phv) {
        if (!aliasSrcs[field.id] && field.is_unallocated()) {
            if (field.pov) {
                if (!pov_fields.count(field.gress))
                    pov_fields.emplace(field.gress, field.gress);
                pov_fields.at(field.gress).push_back(field);
            } else {
                FieldGroup group(field);
                if (field.metadata) {
                    while (group.size < 8) {
                        auto* mfield = phv.field(group.back().id + 1);
                        if (mfield->gress != group.gress || group.size + mfield->size > 8)
                            break;
                        group.push_back(*mfield); }
                } else if (field.size % 8U != 0 && field.offset > 0) {
                    while (group.size % 8U != 0) {
                        auto* mfield = phv.field(group.back().id + 1);
                        if (mfield->gress != group.gress)
                            break;
                        group.push_back(*mfield);
                        assert(!mfield->metadata);
                        if (mfield->offset == 0) break; } }
                do_alloc(group, &normal); } } }

    for (auto &pov : Values(pov_fields))
        do_alloc(pov, &normal);
}

void TrivialAlloc::end_apply(const IR::Node *) {
    phv.set_done(true);
}

}  // namespace PHV
