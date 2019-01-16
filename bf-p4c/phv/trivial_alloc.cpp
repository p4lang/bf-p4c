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
    explicit FieldGroup(gress_t gress) : gress(gress), size(0), tagalong(false) { }

    /// Construct a FieldGroup with @field as its first field. The thread and
    /// other properties are derived from @field.
    explicit FieldGroup(PHV::Field& field)
        : gress(field.gress)
        , fields{&field}
        , ids(field.id, 1)
        , size(field.size)
        , tagalong(false)
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
    std::vector<PHV::Field*> fields;  /// The fields in this group.
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
                auto slice = PHV::Field::alloc_slice(i, use->*rtype.alloc, 0, abits-isize, isize,
                        emptyInitSet);
                i->add_alloc(slice);
                LOG3("   allocated " << slice << " for " << i->gress);
                abits -= isize;
                i = group.fields[++group_index];
                merge_follow--;
                isize = i->size; }
            if ((isize -= abits) < 0) {
                abits += isize;
                isize = 0; }
            i->add_alloc(i, (use->*rtype.alloc)++, isize, 0, abits, emptyInitSet);
            if (skip && use->*rtype.alloc == skip[0].*rtype.alloc)
                use->*rtype.alloc = skip[1].*rtype.alloc;
            size -= rtype.size; } }

    LOG3("   allocated " << i->get_alloc() << " for " << i->name);
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

bool TrivialAlloc::preorder(const IR::BFN::Pipe *pipe) {
    if (phv.alloc_done()) return false;
    Phv_Parde_Mau_Use uses(phv);
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
            tagalong.B = PHV::Container(PHV::Type::TB, tagalong_group * 4);
            tagalong.H = PHV::Container(PHV::Type::TH, tagalong_group * 6);
            tagalong.W = PHV::Container(PHV::Type::TW, tagalong_group * 4); }

        FieldGroup pov_fields(gr);
        for (auto &field : phv) {
            if (field.gress != gr)
                continue;
            if (field.is_unallocated()) {
                if (field.pov) {
                    pov_fields.push_back(field);
                } else {
                    bool use_mau = uses.is_used_mau(&field);
                    bool use_parde = uses.is_used_parde(&field);
                    FieldGroup group(field);
                    if (!field.metadata && field.size % 8U != 0 && field.offset > 0) {
                        while (group.size % 8U != 0) {
                            auto* mfield = phv.field(group.back().id + 1);
                            group.push_back(*mfield);
                            use_mau |= uses.is_used_mau(mfield);
                            use_parde |= uses.is_used_parde(mfield);
                            assert(!mfield->metadata);
                            if (mfield->offset == 0) break; } }
                    if (use_mau) {
                        do_alloc(group, &normal, skip);
                    } else if (use_parde) {
                        if (Device::currentDevice() != Device::TOFINO ||
                            tagalong_full(field.size, &tagalong))
                            do_alloc(group, &normal, skip);
                        else
                            do_alloc(group, &tagalong, nullptr);
                    } else {
                        LOG2(field.id << ": " << field.name << " unused in " << gr); } } } }

        do_alloc(pov_fields, &normal, skip);
    }
    return false;
}

void TrivialAlloc::end_apply(const IR::Node *) {
    phv.set_done();
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
        auto containerId = Device::phvSpec().containerToId(container);
        BUG_CHECK(source == MANUAL || !allocatedContainers[containerId],
                  "Reallocating container %1%", container);
        BUG_CHECK(source == MANUAL || !threadAssignments[~gress][containerId],
                  "Container %1% is already assigned to %2%", container, ~gress);

        LOG3("Allocating container " << container << " to thread " << gress);

        // Allocate this container and reserve its entire group for this thread.
        // reserveForThread() calls updateNext(), so we don't have to call it
        // directly here.
        allocatedContainers[containerId] = true;
        reserveForThread(gress, Device::phvSpec().deparserGroup(containerId), source);
    }

    /**
     * Allocates a container of size and category @type for thread @gress.
     * @return the newly allocated container.
     */
    PHV::Container allocateNext(gress_t gress, PHV::Type type) {
        auto container = next[gress][Device::phvSpec().containerTypeToId(type)];
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
                  "already assigned to %3%",
                  Device::phvSpec().idToContainer(*ids.min()),
                  Device::phvSpec().idToContainer(*ids.max()), ~gress);

        LOG3("Container range (min " << Device::phvSpec().idToContainer(*ids.min())
             << ", max " << Device::phvSpec().idToContainer(*ids.max()) << ") "
             << "reserved for thread " << gress);
        threadAssignments[gress] |= ids;

        updateNext();
    }

 private:
    /**
     * Find the next available container for all combinations of thread and
     * container type. Called when allocations or reservations change.
     */
    void updateNext() {
        const auto& phvSpec = Device::phvSpec();
        for (gress_t gress : { INGRESS, EGRESS }) {
            for (auto typeId : boost::irange(0u, phvSpec.numContainerTypes())) {
                PHV::Container& nextContainer = next[gress][typeId];
                while (allocatedContainers[phvSpec.containerToId(nextContainer)] ||
                       threadAssignments[~gress][phvSpec.containerToId(nextContainer)])
                    nextContainer++;
            }
        }
    }

    /// The set of allocated container ids.
    bitvec allocatedContainers;
    /// The set of reserved container ids for each thread.
    bitvec threadAssignments[2];
    /// The next available container for each (thread, type) combination.
    std::vector<std::vector<PHV::Container>> next = {
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
        BUG_CHECK(field->is_unallocated(), "Already allocated field in field group?");

        // Bit 0 is the LSB, but the fields in @group are in network byte order,
        // so we start at the MSB and count down.
        int fieldBit = field->size;

        while (fieldBit > 0) {
            // If we've run out of space in this container, allocate a new one.
            if (!container || containerBit == 0) {
                // Choose the next container size such that it contains as many
                // bits as possible without introducing unnecessary wasted bits.
                PHV::Kind kind = PHV::Kind::normal;

                if (group.tagalong)
                    kind = PHV::Kind::tagalong;

                PHV::Size size;

                if (remainingBits > 24)
                    size = PHV::Size::b32;
                else if (remainingBits > 8)
                    size = PHV::Size::b16;
                else
                    size = PHV::Size::b8;

                // Find the next container of this size that's available.
                container = alloc.allocateNext(group.gress, PHV::Type(kind, size));
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

            field->add_alloc(field, container, fieldBit, containerBit, width, emptyInitSet);
            phv.add_container_to_field_entry(container, field);
        }

        LOG3("   allocated " << field->get_alloc() << " for " << field->name);
    }

    BUG_CHECK(remainingBits == 0, "Didn't allocate entire group?");
}

bool ManualAlloc::preorder(const IR::BFN::Pipe *pipe) {
    BUG_CHECK(!phv.alloc_done(), "PHV allocation was already performed");

    // Some containers are specific to a thread at the hardware level. Reserve
    // those containers before doing any allocation.
    ContainerAllocation alloc;
    alloc.reserveForThread(INGRESS, Device::phvSpec().ingressOnly());
    alloc.reserveForThread(EGRESS, Device::phvSpec().egressOnly());

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
            field->add_alloc(field, slice.container, slice.field_bit,
                             slice.container_bit, slice.width, emptyInitSet);
            phv.add_container_to_field_entry(slice.container, field);
        }
    }

    // Collect information about where fields are used.
    Phv_Parde_Mau_Use uses(phv);
    pipe->apply(uses);

    // Allocate all fields except for POV bits.
    FieldGroup povFields[2] = { FieldGroup(INGRESS), FieldGroup(EGRESS) };
    for (auto& field : phv) {
        if (!field.is_unallocated()) continue;
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
            BUG_CHECK(nextField->is_unallocated(), "Adding allocated field to group?");
            group.push_back(*nextField);
        }

        bool mau_use = false;
        bool parde_use = false;
        for (auto id : group.ids) {
            auto* f = phv.field(id);
            if (uses.is_used_mau(f))
                mau_use = true;
            if (uses.is_used_parde(f))
                parde_use = true;
        }
        if (mau_use) {
            // This group is used in the MAU pipeline.
        } else if (parde_use) {
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
