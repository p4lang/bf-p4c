#include "trivial_alloc.h"

#include <algorithm>
#include "lib/bitvec.h"
#include "lib/exceptions.h"
#include "lib/range.h"
#include "tofino/phv/phv.h"
#include "tofino/ir/gress.h"

namespace PHV {
namespace {

class Uses : public Inspector {
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
        in_mau = true;  // treat egress_port and digests as in mau as they can't go in TPHV
        revisit_visited();
        visit(d->egress_port);
        d->digests.visit_children(*this);
        in_mau = false;
        revisit_visited();
        d->emits.visit_children(*this);
        return false; }
    bool preorder(const IR::MAU::TableSeq *) {
        in_mau = true;
        revisit_visited();
        return true; }
    bool preorder(const IR::HeaderRef *hr) {
        PhvInfo::StructInfo info = phv.struct_info(hr);
        use[in_mau][thread].setrange(info.first_field_id, info.size);
        return false; }
    bool preorder(const IR::Expression *e) {
        if (auto info = phv.field(e)) {
            LOG3("use " << info->name << " in " << thread << (in_mau ? " mau" : ""));
            use[in_mau][thread][info->id] = true;
            return false; }
        return true; }
};

}  // namespace

/// A group of fields that should be allocated contiguously. Offers a
/// std::vector-like interface.
struct FieldGroup final {
    /// Construct a FieldGroup which will contain fields for thread @gress.
    explicit FieldGroup(gress_t gress) : gress(gress), size(0), tagalong(false) { }

    /// Construct a FieldGroup with @field as its first field. The thread and
    /// other properties are derived from @field.
    explicit FieldGroup(PhvInfo::Field& field)
        : gress(field.gress)
        , fields{&field}
        , ids(field.id, 1)
        , size(field.size)
        , tagalong(false)
    { }

    PhvInfo::Field& back() const {
        BUG_CHECK(!fields.empty(), "Calling back() on a group with no fields");
        return *fields.back();
    }

    void push_back(PhvInfo::Field& field) {
        BUG_CHECK(field.gress == gress,
                  "Mixing fields for different threads in group?");
        fields.push_back(&field);
        ids.setbit(field.id);
        size += field.size;
    }

    const gress_t gress;                  /// This group's thread.
    std::vector<PhvInfo::Field*> fields;  /// The fields in this group.
    bitvec ids;                           /// The ids of those fields.
    int size;                             /// The total size of all fields.
    bool tagalong;                        /// If true, allocate in TPHV.
};

struct TrivialAlloc::Regs {
    PHV::Container      B, H, W;
};

/* static */ bool
TrivialAlloc::tagalong_full(int size, PHV::TrivialAlloc::Regs *use) {
    unsigned bytes = (size+7)/8U;
    return  (bytes >= 4 && use->W.index() + bytes/4 > 32) ||
            ((bytes & 2) && use->H.index() >= 48) ||
            ((bytes & 1) && use->B.index() >= 32);
}

void TrivialAlloc::do_alloc(const FieldGroup& group, Regs *use, Regs *skip) {
    /* greedy allocate space for field */
    static struct {
        PHV::Container PHV::TrivialAlloc::Regs::*   alloc;
        int                                         size;
    } alloc_types[3] = {
        { &PHV::TrivialAlloc::Regs::W, 32 },
        { &PHV::TrivialAlloc::Regs::H, 16 },
        { &PHV::TrivialAlloc::Regs::B, 8 },
    };

    PhvInfo::Field *i = group.fields[0];
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
                i->alloc_i.emplace_back(i, use->*rtype.alloc, 0, abits-isize, isize);
                LOG3("   allocated " << i->alloc_i << " for " << i->gress);
                abits -= isize;
                i = group.fields[++group_index];
                merge_follow--;
                isize = i->size; }
            if ((isize -= abits) < 0) {
                abits += isize;
                isize = 0; }
            i->alloc_i.emplace_back(i, (use->*rtype.alloc)++, isize, 0, abits);
            if (skip && use->*rtype.alloc == skip[0].*rtype.alloc)
                use->*rtype.alloc = skip[1].*rtype.alloc;
            size -= rtype.size; } }
    LOG3("   allocated " << i->alloc_i << " for " << i->name);
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

bool TrivialAlloc::preorder(const IR::Tofino::Pipe *pipe) {
    if (phv.alloc_done()) return false;
    PHV::Uses uses(phv);
    Regs normal = { "B0", "H0", "W0" },
         tagalong = { "TB0", "TH0", "TW0" },
         skip[2] = { { "B16", "H16", "W16" }, { "B32", "H32", "W32" } };
            // skip over egress-only regs in ingress
    pipe->apply(uses);
    for (auto gr : Range(INGRESS, EGRESS)) {
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

        FieldGroup pov_fields(gr);
        for (auto &field : phv) {
            if (field.gress != gr)
                continue;
            if (field.alloc_i.empty()) {
                if (field.pov) {
                    pov_fields.push_back(field);
                } else {
                    bool use_mau = uses.use[1][gr][field.id];
                    bool use_any = uses.use[0][gr][field.id];
                    FieldGroup group(field);
                    if (!field.metadata && field.size % 8U != 0 && field.offset > 0) {
                        while (group.size % 8U != 0) {
                            auto* mfield = phv.field(group.back().id + 1);
                            group.push_back(*mfield);
                            use_mau |= uses.use[1][gr][mfield->id];
                            use_any |= uses.use[0][gr][mfield->id];
                            assert(!mfield->metadata);
                            if (mfield->offset == 0) break; } }
                    if (use_mau) {
                        do_alloc(group, &normal, skip);
                    } else if (use_any) {
                        if (tagalong_full(field.size, &tagalong))
                            do_alloc(group, &normal, skip);
                        else
                            do_alloc(group, &tagalong, nullptr);
                    } else {
                        LOG2(field.id << ": " << field.name << " unused in " << gr); } } } }

        do_alloc(pov_fields, &normal, skip);
    }
    return false;
}

/// Tracks which containers are allocated and which threads they're allocated to.
struct ContainerAllocation final {
    enum AllocationSource {
        AUTOMATIC,  /// Requested by the allocation algorithm.
        MANUAL      /// Requested by the user.
    };

    /**
     * Allocates @container. The container's entire group is reserved for
     * @gress.
     *
     * It's normally an error to reallocate a container which has already been
     * allocated, or to assign a container to one thread when it's already
     * reserved for another, but this is allowed if @source is MANUAL.
     */
    void allocate(gress_t gress, PHV::Container container,
                  AllocationSource source = AUTOMATIC) {
        BUG_CHECK(source == MANUAL || !allocatedContainers[container.id()],
                  "Reallocating container %1%", container);
        BUG_CHECK(source == MANUAL || !threadAssignments[~gress][container.id()],
                  "Container %1% is already assigned to %2%", container, ~gress);

        LOG3("Allocating container " << container << " to thread " << gress);

        // Allocate this container and reserve its entire group for this thread.
        // reserveForThread() calls updateNext(), so we don't have to call it
        // directly here.
        allocatedContainers[container.id()] = true;
        reserveForThread(gress, container.group(), source);
    }

    /**
     * Allocates a container of size and category @kind for thread @gress.
     * @return the newly allocated container.
     */
    PHV::Container allocateNext(gress_t gress, PHV::Container::Kind kind) {
        auto container = next[gress][unsigned(kind)];
        allocate(gress, container);
        return container;
    }

    /**
     * Reserves all containers in @ids for thread @gress. This does not actually
     * allocate the containers; it just ensures that if they *are* allocated,
     * they will only be allocated for the given thread.
     *
     * It's normally an error to reserve a container for one thread when it's
     * already reserved for another, but this is allowed if @source is MANUAL.
     */
    void reserveForThread(gress_t gress, const bitvec& ids,
                          AllocationSource source = AUTOMATIC) {
        BUG_CHECK(source == MANUAL || !threadAssignments[~gress].intersects(ids),
                  "Range (min %1%, max %2%) contains containers which are "
                  "already assigned to %3%", PHV::Container::fromId(*ids.min()),
                  PHV::Container::fromId(*ids.max()), ~gress);

        LOG3("Container range (min " << PHV::Container::fromId(*ids.min()) <<
             ", max " << PHV::Container::fromId(*ids.max()) << ") " <<
             "reserved for thread " << gress);
        threadAssignments[gress] |= ids;

        updateNext();
    }

 private:
    /**
     * Find the next available container for all combinations of thread and
     * container kind. Called when allocations or reservations change.
     */
    void updateNext() {
        for (gress_t gress : { INGRESS, EGRESS }) {
            for (unsigned kindId = 0; kindId < PHV::Container::NumKinds; kindId++) {
                PHV::Container& nextContainer = next[gress][kindId];
                while (allocatedContainers[nextContainer.id()] ||
                       threadAssignments[~gress][nextContainer.id()])
                    nextContainer++;
            }
        }
    }

    /// The set of allocated container ids.
    bitvec allocatedContainers;
    /// The set of reserved container ids for each thread.
    bitvec threadAssignments[2];
    /// The next available container for each (thread, kind) combination.
    PHV::Container next[2][PHV::Container::NumKinds] = {
        { "B0", "H0", "W0", "TB0", "TH0", "TW0" },
        { "B0", "H0", "W0", "TB0", "TH0", "TW0" }
    };
};

/// Use @alloc to allocate PHV containers for all fields in @group.
void ManualAlloc::allocateFieldGroup(const FieldGroup& group,
                                     ContainerAllocation& alloc) {
    PHV::Container container;
    int containerBit = 0;
    int remainingBits = group.size;

    LOG2("Allocating field group:");
    for (auto field : group.fields) {
        LOG2(" - " << field->id << ": " << (field->metadata ? "metadata " : "header ")
                   << field->name << " size=" << field->size);
        BUG_CHECK(field->alloc_i.empty(), "Already allocated field in field group?");

        // Bit 0 is the LSB, but the fields in @group are in network byte order,
        // so we start at the MSB and count down.
        int fieldBit = field->size;

        while (fieldBit > 0) {
            // If we've run out of space in this container, allocate a new one.
            if (!container || containerBit == 0) {
                // Choose the next container size such that it contains as many
                // bits as possible without introducing unnecessary wasted bits.
                using Kind = PHV::Container::Kind;
                Kind kind;
                if (remainingBits > 24)
                    kind = group.tagalong ? Kind::TW : Kind::W;
                else if (remainingBits > 8)
                    kind = group.tagalong ? Kind::TH : Kind::H;
                else
                    kind = group.tagalong ? Kind::TB : Kind::B;

                // Find the next container of this size that's available.
                container = alloc.allocateNext(group.gress, kind);
                containerBit = container.size();
            }

            // Allocate as many bits as possible from this field into the
            // current container. This will consume either the rest of the
            // container or the rest of the field (or, ideally, both).
            int width = std::min<int>(containerBit, fieldBit);

            fieldBit -= width;
            BUG_CHECK(fieldBit >= 0, "Overflowed field");
            containerBit -= width;
            BUG_CHECK(containerBit >= 0, "Overflowed container");
            remainingBits -= width;
            BUG_CHECK(remainingBits >= 0, "Overflowed field group");

            field->alloc_i.emplace_back(field, container, fieldBit,
                                        containerBit, width);
        }

        LOG3("   " << field->alloc_i);
    }

    BUG_CHECK(remainingBits == 0, "Didn't allocate entire group?");
}

bool ManualAlloc::preorder(const IR::Tofino::Pipe *pipe) {
    BUG_CHECK(!phv.alloc_done(), "PHV allocation was already performed");

    // Some containers are specific to a thread at the hardware level. Reserve
    // those containers before doing any allocation.
    ContainerAllocation alloc;
    alloc.reserveForThread(INGRESS, PHV::Container::ingressOnly());
    alloc.reserveForThread(EGRESS, PHV::Container::egressOnly());

    // Normally, we treat the user's manual assignments differently than the
    // ones generated by the allocator itself - in particular, we don't check
    // the manual assignments for errors. If requested by the user, though,
    // we'll treat manual assignments the same as the automatic ones.
    const auto manualAllocationSource = checkAssignments
                                      ? ContainerAllocation::AUTOMATIC
                                      : ContainerAllocation::MANUAL;

    // Allocate all the manually assigned fields.
    for (auto& assignment : assignments) {
        auto field = phv.field(assignment.first);
        BUG_CHECK(field != nullptr, "Allocation for a nonexistent field?");

        // Downstream code that uses the PHV allocation assumes that the slices
        // are sorted by the position of the slice's MSB within the field. Since
        // the LSB is bit 0, that means we need to sort by `field_bit` in
        // descending order.
        auto& slices = assignment.second;
        std::sort(slices.begin(), slices.end(), [](const Slice& a, const Slice& b) {
            return a.field_bit > b.field_bit;
        });

        for (auto& slice : slices) {
            alloc.allocate(field->gress, slice.container, manualAllocationSource);
            field->alloc_i.emplace_back(field, slice.container, slice.field_bit,
                                        slice.container_bit, slice.width);
        }
    }

    // Collect information about where fields are used.
    PHV::Uses uses(phv);
    pipe->apply(uses);

    // Allocate all fields except for POV bits.
    FieldGroup povFields[2] = { FieldGroup(INGRESS), FieldGroup(EGRESS) };
    for (auto& field : phv) {
        if (!field.alloc_i.empty()) continue;
        if (field.pov) {
            povFields[field.gress].push_back(field);
            continue;
        }

        // Merge this field with subsequent fields until we get a byte-aligned
        // group or reach the end of the header. This is necessary because
        // Tofino hardware can only deparse byte-aligned data.
        FieldGroup group(field);
        while (!group.back().metadata &&
               group.size % 8U != 0 &&
               group.back().offset > 0) {
            auto* nextField = phv.field(group.back().id + 1);
            if (nextField == nullptr) break;
            BUG_CHECK(nextField->alloc_i.empty(), "Adding allocated field to group?");
            group.push_back(*nextField);
        }

        if (group.ids.intersects(uses.use[1][group.gress])) {
            // This group is used in the MAU pipeline.
        } else if (group.ids.intersects(uses.use[0][group.gress])) {
            // This group is only used in the parser/deparser.
            group.tagalong = true;
        } else {
            LOG2(field.id << ": field group beginning with " << field.name
                          << " is unused in " << field.gress);
            continue;
        }

        allocateFieldGroup(group, alloc);
    }

    // Allocate all POV bit fields, packed together.
    for (auto gress : { INGRESS, EGRESS })
        allocateFieldGroup(povFields[gress], alloc);

    return false;
}

void ManualAlloc::end_apply(const IR::Node*) {
    phv.set_done();
}

}  // namespace PHV
