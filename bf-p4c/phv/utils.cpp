#include "utils.h"
#include <boost/optional/optional_io.hpp>
#include <iostream>
#include <numeric>
#include "bf-p4c/lib/union_find.hpp"

static int cluster_id_g = 0;                // global counter for assigning cluster ids

PHV::ContainerGroup::ContainerGroup(PHV::Type type, const std::vector<PHV::Container> containers)
: type_i(type), containers_i(containers) {
    // Check that all containers are the right size.
    for (auto c : containers_i) {
        BUG_CHECK(c.type() == type_i,
            "PHV container group constructed with type %1% but has container %2% of type %3%",
            cstring::to_cstring(type_i),
            cstring::to_cstring(c),
            cstring::to_cstring(c.type()));
        ids_i.setbit(Device::phvSpec().containerToId(c)); }
}

PHV::ContainerGroup::ContainerGroup(PHV::Type type, bitvec container_group)
: type_i(type), ids_i(container_group) {
    const PhvSpec& phvSpec = Device::phvSpec();
    for (auto cid : container_group) {
        auto c = phvSpec.idToContainer(cid);
        BUG_CHECK(c.type() == type_i,
            "PHV container group constructed with type %1% but has container %2% of type %3%",
            cstring::to_cstring(type_i),
            cstring::to_cstring(c),
            cstring::to_cstring(c.type()));
        containers_i.push_back(c); }
}

PHV::AllocSlice::AllocSlice(
        PHV::Field* f,
        PHV::Container c,
        int field_bit_lo,
        int container_bit_lo,
        int width)
: field_i(f), container_i(c), field_bit_lo_i(field_bit_lo),
  container_bit_lo_i(container_bit_lo), width_i(width) {
    BUG_CHECK(width_i <= 32,
        "Slice larger than largest container: %1%",
        cstring::to_cstring(this));

    le_bitrange field_range = StartLen(0, f->size);
    le_bitrange slice_range = StartLen(field_bit_lo, width);
    BUG_CHECK(field_range.contains(slice_range),
              "Trying to slice field %1% at [%2%:%3%] but it's only %4% bits wide",
              cstring::to_cstring(f), slice_range.lo, slice_range.hi, f->size);
}

PHV::AllocSlice::AllocSlice(
        PHV::Field* f,
        PHV::Container c,
        le_bitrange field_slice,
        le_bitrange container_slice)
: AllocSlice(f, c, field_slice.lo, container_slice.lo, field_slice.size()) {
    BUG_CHECK(field_slice.size() == container_slice.size(),
              "Trying to allocate field slice %1% to a container slice %2% of different "
              "size.",
              cstring::to_cstring(field_slice),
              cstring::to_cstring(container_slice));
}

bool PHV::AllocSlice::operator==(const PHV::AllocSlice& other) const {
    return field_i             == other.field_i
        && container_i         == other.container_i
        && field_bit_lo_i      == other.field_bit_lo_i
        && container_bit_lo_i  == other.container_bit_lo_i
        && width_i             == other.width_i;
}

bool PHV::AllocSlice::operator!=(const PHV::AllocSlice& other) const {
    return !this->operator==(other);
}

bool PHV::AllocSlice::operator<(const PHV::AllocSlice& other) const {
    if (field_i->id != other.field_i->id)
        return field_i->id < other.field_i->id;
    if (container_i != other.container_i)
        return container_i < other.container_i;
    if (field_bit_lo_i != other.field_bit_lo_i)
        return field_bit_lo_i < other.field_bit_lo_i;
    if (container_bit_lo_i != other.container_bit_lo_i)
        return container_bit_lo_i < other.container_bit_lo_i;
    if (width_i < other.width_i)
        return width_i < other.width_i;
    return false;
}

void PHV::Allocation::addStatus(PHV::Container c, const ContainerStatus& status) {
    // Update container status.
    auto& this_status = container_status_i[c];
    this_status.gress = status.gress;
    this_status.slices |= status.slices;

    // Update field status.
    for (auto& slice : status.slices)
        field_status_i[slice.field()].insert(slice);

    // Recalculate container allocation status for updated fields.  It's
    // necessary to recalculate, rather that copy the child's count wholesale,
    // because the parent may have merged other children since creating this
    // child.
    PHV::Allocation::ContainerAllocStatus old_status = this_status.alloc_status;
    bitvec allocated_bits;
    for (auto& slice : this_status.slices)
        allocated_bits |= bitvec(slice.container_slice().lo, slice.width());
    if (allocated_bits == bitvec())
        this_status.alloc_status = PHV::Allocation::ContainerAllocStatus::EMPTY;
    else if (allocated_bits == bitvec(0, c.size()))
        this_status.alloc_status = PHV::Allocation::ContainerAllocStatus::FULL;
    else
        this_status.alloc_status = PHV::Allocation::ContainerAllocStatus::PARTIAL;

    BUG_CHECK(this_status.alloc_status != PHV::Allocation::ContainerAllocStatus::EMPTY ||
              (this_status.alloc_status == PHV::Allocation::ContainerAllocStatus::EMPTY &&
               this_status.alloc_status == old_status),
              "Changing allocation status from FULL or PARTIAL to EMPTY");

    if (this_status.alloc_status != old_status) {
        --count_by_status_i[c.type().size()][old_status];
        ++count_by_status_i[c.type().size()][this_status.alloc_status]; }
}

void PHV::Allocation::addSlice(PHV::Container c, AllocSlice slice) {
    field_status_i[slice.field()].insert(slice);
    container_status_i[c].slices.insert(slice);

    // Update the allocation status of the container.
    if (container_status_i[c].alloc_status != PHV::Allocation::ContainerAllocStatus::FULL) {
        PHV::Allocation::ContainerAllocStatus old_status = container_status_i[c].alloc_status;
        bitvec allocated_bits;
        for (auto slice : container_status_i[c].slices)
            allocated_bits |= bitvec(slice.container_slice().lo, slice.width());
        if (allocated_bits == bitvec())
            container_status_i[c].alloc_status = PHV::Allocation::ContainerAllocStatus::EMPTY;
        else if (allocated_bits == bitvec(0, c.size()))
            container_status_i[c].alloc_status = PHV::Allocation::ContainerAllocStatus::FULL;
        else
            container_status_i[c].alloc_status = PHV::Allocation::ContainerAllocStatus::PARTIAL;

        BUG_CHECK(
            container_status_i[c].alloc_status != PHV::Allocation::ContainerAllocStatus::EMPTY ||
            (container_status_i[c].alloc_status == PHV::Allocation::ContainerAllocStatus::EMPTY &&
            container_status_i[c].alloc_status == old_status),
            "Changing allocation status from FULL or PARTIAL to EMPTY");

        if (old_status != container_status_i[c].alloc_status) {
            --count_by_status_i[c.type().size()][old_status];
            ++count_by_status_i[c.type().size()][container_status_i[c].alloc_status]; } }
}

void PHV::Allocation::setGress(PHV::Container c, GressAssignment gress) {
    container_status_i[c].gress = gress;
}

PHV::Allocation::MutuallyLiveSlices
PHV::Allocation::slicesByLiveness(const PHV::Container c, const AllocSlice& sl) const {
    PHV::Allocation::MutuallyLiveSlices rs;
    auto slices = this->slices(c);
    for (auto& slice : slices) {
        if (!PHV::Allocation::mutually_exclusive(mutex_i, slice.field(), sl.field()))
            rs.insert(slice); }
    return rs;
}

PHV::Allocation::MutuallyLiveSlices
PHV::Allocation::slicesByLiveness(const PHV::Container c,
                                  std::vector<AllocSlice>& slices) const {
    PHV::Allocation::MutuallyLiveSlices rs;
    auto existingSlices = this->slices(c);
    for (auto& slice : existingSlices) {
        for (auto sl : slices) {
            if (!PHV::Allocation::mutually_exclusive(mutex_i, slice.field(), sl.field()))
                rs.insert(slice); } }
    return rs;
}

std::vector<PHV::Allocation::MutuallyLiveSlices>
PHV::Allocation::slicesByLiveness(PHV::Container c) const {
    // Idea: set of bitvecs, where each bitvec is a collection of mutually live
    // field IDs.
    auto slices = this->slices(c);
    ordered_map<unsigned, ordered_set<bitvec>> by_round;
    ordered_map<unsigned, ordered_set<bitvec>> remove_by_round;
    ordered_map<int, PHV::AllocSlice*> fid_to_slice;

    // Populate round 1.
    for (auto& slice : slices) {
        by_round[1U].insert(bitvec(slice.field()->id, 1));
        fid_to_slice[slice.field()->id] = &slice;
    }

    // Start at round 2.
    for (unsigned round = 2U; round <= slices.size(); round++) {
        // Try adding each slice to each set in the previous round.
        for (auto& slice : slices) {
            int fid = slice.field()->id;
            for (bitvec bv : by_round[round-1]) {
                if (bv[fid])
                    continue;
                // If fid is live with all fields in bv, add it to bv and
                // schedule bv for eventual removal.
                bool all_live = true;
                for (int fid2 : bv) {
                    if (PHV::Allocation::mutually_exclusive(
                            mutex_i, fid_to_slice.at(fid)->field(),
                                     fid_to_slice.at(fid2)->field())) {
                        all_live = false;
                        break; } }
                if (all_live) {
                    remove_by_round[round - 1].insert(bv);
                    bv.setbit(fid);
                    by_round[round].insert(bv); } } } }

    // Build a set from the non-removed bitvecs of each round.
    ordered_set<bitvec> rvset;
    for (unsigned round = 1; round <= slices.size(); round++) {
        rvset |= by_round[round];
        rvset -= remove_by_round[round]; }

    std::vector<PHV::Allocation::MutuallyLiveSlices> rv;
    for (bitvec bv : rvset) {
        if (bv.empty())
            continue;
        rv.push_back({ });
        for (int fid : bv)
            rv.back().insert(*fid_to_slice[fid]); }

    return rv;
}

int PHV::Allocation::empty_containers(PHV::Size size) const {
    auto status = PHV::Allocation::ContainerAllocStatus::EMPTY;
    if (count_by_status_i.find(size) == count_by_status_i.end())
        return 0;
    if (count_by_status_i.at(size).find(status) == count_by_status_i.at(size).end())
        return 0;
    return count_by_status_i.at(size).at(status);
}

/** Assign @slice to @slice.container, updating the gress information of
 * the container and its MAU group if necessary.  Fails if the gress of
 * @slice.field does not match any gress in the MAU group.
 */
void PHV::Allocation::allocate(PHV::AllocSlice slice) {
    auto& phvSpec = Device::phvSpec();
    unsigned slice_cid = phvSpec.containerToId(slice.container());

    // Check and update gress for all containers in this deparser group.
    if (!this->gress(slice.container())) {
        for (unsigned cid : phvSpec.deparserGroup(slice_cid)) {
            auto c = phvSpec.idToContainer(cid);
            auto opt_gress = this->gress(c);
            BUG_CHECK(!opt_gress || *opt_gress == slice.field()->gress,
                "Trying to allocate field %1% with gress %2% to container %3% with gress %4%",
                slice.field()->name, slice.field()->gress, slice.container(),
                this->gress(c));
            LOG5("    ...maybe assigning " << c << " to " << slice.field()->gress);
            this->setGress(c, slice.field()->gress); } }

    auto gress = this->gress(slice.container());
    BUG_CHECK(gress && *gress == slice.field()->gress,
        "Trying to allocate field %1% with gress %2% to container %3% with gress %4%",
        slice.field()->name, slice.field()->gress, slice.container(),
        this->gress(slice.container()));

    // Update gress.  XXX(cole): This is subtle and should probably be
    // refactored; in order to avoid code duplication, allocate() uses virtual
    // accessors, eg. this->gress() and this->setGress(), effectively
    // parameterizing allocation.  However, when inserting a new value into a
    // Transaction, we need to set the gress, even if it's already been set.
    this->setGress(slice.container(), slice.field()->gress);

    // Update allocation.
    this->addSlice(slice.container(), slice);
}

void PHV::Allocation::commit(Transaction& view) {
    // XXX(cole): Add Allocation identifiers and check that this transaction
    // came from this Allocation.

    for (auto kv : view.getTransactionStatus()) {
        // Fail if any part of this field slice has already been allocated.
        for (auto& slice : kv.second.slices) {
            const auto& existing_alloc = slices(slice.field(), slice.field_slice());
            BUG_CHECK(existing_alloc.size() == 0, "Trying to allocate slice %1%, but other "
                      "overlapping slices of this field have already been allocated: %2%",
                      cstring::to_cstring(slice), cstring::to_cstring(existing_alloc)); }

        // Merge the status from the view.
        this->addStatus(kv.first, kv.second); }

    // Clear the view.
    view.clearTransactionStatus();
}

PHV::Transaction PHV::Allocation::makeTransaction() const {
    return Transaction(mutex_i, this);
}

/// @returns a pretty-printed representation of this Allocation.
cstring PHV::Allocation::toString() const {
    return cstring::to_cstring(*this);
}

/* static */ bool
PHV::Allocation::mutually_exclusive(
        SymBitMatrix mutex,
        const PHV::Field *f1,
        const PHV::Field *f2) {
    // NB: We use std::set here because ordered_set doesn't implement
    // `insert(Iterator first, Iterator last)`, and the order we check the
    // Cartesian product of two sets doesn't matter anyway.
    std::set<const PHV::Field *> f1_fields, f2_fields;

    // Insert f1 and f2 and CCGF members, if any.
    f1_fields.insert(f1);
    f1_fields.insert(f1->ccgf_fields().begin(), f1->ccgf_fields().end());
    f2_fields.insert(f2);
    f2_fields.insert(f2->ccgf_fields().begin(), f2->ccgf_fields().end());

    // Check that all fields associated with `f1` are mutually exclusive with
    // all fields associated with `f2`.
    for (auto f1_x : f1_fields)
        for (auto f2_x : f2_fields)
            if (!mutex(f1_x->id, f2_x->id))
                return false;
    return true;
}

std::set<PHV::Allocation::AvailableSpot>
PHV::Allocation::available_spots() const {
    std::set<AvailableSpot> rst;
    // Compute status.
    for (auto cid : Device::phvSpec().physicalContainers()) {
        PHV::Container c = Device::phvSpec().idToContainer(cid);
        auto slices = this->slices(c);
        auto gress = this->gress(c);
        // Empty
        if (slices.size() == 0) {
            rst.insert(AvailableSpot(c, gress, c.size()));
            continue; }
        // calculate allocate bitvec
        bitvec allocatedBits;
        for (auto slice : slices) {
            allocatedBits |= bitvec(slice.container_slice().lo,
                                    slice.container_slice().size()); }
        // Full
        if (allocatedBits == bitvec(0, c.size())) {
            continue;
        } else {
            // Occupied by no_pack field
            if (slices.size() == 1 && slices.begin()->field()->no_pack()) {
                continue; }
            int used = std::accumulate(allocatedBits.begin(),
                                       allocatedBits.end(), 0,
                                       [] (int a, int) { return a + 1; });
            rst.insert(AvailableSpot(c, gress, c.size() - used)); }
    }
    return rst;
}

/** Create an allocation from a vector of container IDs.  Physical
 * containers that the Device pins to a particular gress are
 * initialized to that gress.
 */
PHV::ConcreteAllocation::ConcreteAllocation(const SymBitMatrix& mutex, bitvec containers) {
    this->mutex_i = mutex;
    auto& phvSpec = Device::phvSpec();
    for (auto cid : containers) {
        PHV::Container c = phvSpec.idToContainer(cid);

        // Initialize container status with hard-wired gress info and
        // an empty alloc slice list.
        boost::optional<gress_t> gress = boost::none;
        if (phvSpec.ingressOnly()[phvSpec.containerToId(c)])
            gress = INGRESS;
        else if (phvSpec.egressOnly()[phvSpec.containerToId(c)])
            gress = EGRESS;
        container_status_i[c] = { gress, { }, PHV::Allocation::ContainerAllocStatus::EMPTY }; }
}

PHV::ConcreteAllocation::ConcreteAllocation(const SymBitMatrix& mutex)
: PHV::ConcreteAllocation::ConcreteAllocation(mutex, Device::phvSpec().physicalContainers()) { }

/// @returns true if this allocation owns @c.
bool PHV::ConcreteAllocation::contains(PHV::Container c) const {
    return container_status_i.find(c) != container_status_i.end();
}

/// @returns the allocation status of @c and fails if @c is not present.
ordered_set<PHV::AllocSlice> PHV::ConcreteAllocation::slices(PHV::Container c) const {
    return slices(c, StartLen(0, int(c.type().size())));
}

ordered_set<PHV::AllocSlice>
PHV::ConcreteAllocation::slices(PHV::Container c, le_bitrange range) const {
    BUG_CHECK(container_status_i.find(c) != container_status_i.end(),
              "Trying to get status for container %1% not in Allocation",
              cstring::to_cstring(c));
    const auto& slices = container_status_i.at(c).slices;
    ordered_set<PHV::AllocSlice> rv;
    for (auto& slice : slices)
        if (slice.container_slice().intersectWith(range).size() > 0)
            rv.insert(slice);
    return rv;
}

/// @returns the set of containers to which a slice of the field @f with a le_bitrange @range is
/// allocated
ordered_set<PHV::AllocSlice>
PHV::ConcreteAllocation::slices(const PHV::Field* f, le_bitrange range) const {
    if (field_status_i.find(f) == field_status_i.end())
        return { };

    ordered_set<PHV::AllocSlice> rv;
    for (auto& slice : field_status_i.at(f))
        if (slice.field_slice().overlaps(range)) {
            rv.insert(slice); }

    return rv;
}

/// @returns the container status of @c and fails if @c is not present.
PHV::Allocation::GressAssignment PHV::ConcreteAllocation::gress(PHV::Container c) const {
    BUG_CHECK(container_status_i.find(c) != container_status_i.end(),
              "Trying to get gress for container %1% not in Allocation",
              cstring::to_cstring(c));
    return container_status_i.at(c).gress;
}

PHV::Allocation::ContainerAllocStatus
PHV::ConcreteAllocation::alloc_status(PHV::Container c) const {
    BUG_CHECK(container_status_i.find(c) != container_status_i.end(),
              "Trying to get allocation status for container %1% not in Allocation",
              cstring::to_cstring(c));
    return container_status_i.at(c).alloc_status;
}

/// @returns a summary of the status of each container by type and gress.
cstring PHV::ConcreteAllocation::getSummary(const PhvUse& uses) const {
    std::map<boost::optional<gress_t>,
        std::map<PHV::Type,
            std::map<ContainerAllocStatus,
                int>>> alloc_status;

    std::map<PHV::Container, int> partial_containers_stat;
    int total_unalloacted_bits = 0;
    int valid_ingress_unallocated_bits = 0;
    int valid_egress_unallocated_bits = 0;

    // TODO(yumin): code duplication of available_spots()
    // Compute status.
    for (auto kv : container_status_i) {
        PHV::Container c = kv.first;
        ContainerAllocStatus status = ContainerAllocStatus::EMPTY;
        bitvec allocatedBits;
        auto& slices = kv.second.slices;
        for (auto slice : slices)
            allocatedBits |= bitvec(slice.container_slice().lo, slice.container_slice().size());
        if (allocatedBits == bitvec(0, c.size())) {
            status = ContainerAllocStatus::FULL;
        } else if (!allocatedBits.empty()) {
            int used = std::accumulate(allocatedBits.begin(),
                                       allocatedBits.end(), 0,
                                       [] (int a, int) { return a + 1; });
            partial_containers_stat[c] = c.size() - used;
            total_unalloacted_bits += partial_containers_stat[c];
            if (slices.size() > 1
                || (slices.size() == 1 && !slices.begin()->field()->no_pack())) {
                if (kv.second.gress == INGRESS) {
                    valid_ingress_unallocated_bits += partial_containers_stat[c];
                } else {
                    valid_egress_unallocated_bits += partial_containers_stat[c]; } }
            status = ContainerAllocStatus::PARTIAL; }
        alloc_status[container_status_i.at(c).gress][c.type()][status]++;
    }

    // Print container status.
    std::stringstream ss;
    ss << "CONTAINER STATUS (after allocation so far):" << std::endl;
    ss << boost::format("%1% %|10t| %2% %|20t| %3% %|30t| %4%\n")
        % "GRESS" % "TYPE" % "STATUS" % "COUNT";

    bool first_by_gress = true;
    auto gresses = std::vector<boost::optional<gress_t>>({INGRESS, EGRESS, boost::none});
    auto statuses = {ContainerAllocStatus::EMPTY,
                     ContainerAllocStatus::PARTIAL,
                     ContainerAllocStatus::FULL};
    for (auto gress : gresses) {
        first_by_gress = true;
        for (auto status : statuses) {
            for (auto type : Device::phvSpec().containerTypes()) {
                if (alloc_status[gress][type][status] == 0)
                    continue;
                std::stringstream ss_gress;
                std::string s_status;
                ss_gress << gress;
                switch (status) {
                  case ContainerAllocStatus::EMPTY:   s_status = "EMPTY"; break;
                  case ContainerAllocStatus::PARTIAL: s_status = "PARTIAL"; break;
                  case ContainerAllocStatus::FULL:    s_status = "FULL"; break; }
                ss << boost::format("%1% %|10t| %3% %|20t| %2% %|30t| %4%\n")
                      % (first_by_gress  ? ss_gress.str() : "")
                      % type.toString()
                      % s_status
                      % alloc_status[gress][type][status];
                first_by_gress = false; } } }
    ss << std::endl;

    // Compute overlay status.
    std::map<PHV::Container, int> overlay_result;
    int overlay_statistics[2][2] = {{0}};
    for (auto kv : container_status_i) {
        PHV::Container c = kv.first;
        int n_overlay = -c.size();
        for (auto i = c.lsb(); i <= c.msb(); ++i) {
            const auto& slices = kv.second.slices;
            n_overlay += std::accumulate(
                slices.begin(), slices.end(), 0,
                [&] (int l, const PHV::AllocSlice& r) {
                    return l + r.container_slice().contains(i); }); }
        if (n_overlay > 0) {
            overlay_result[c] = n_overlay;
            if (c.type().kind() == PHV::Kind::tagalong) {
                overlay_statistics[*kv.second.gress][0] += n_overlay;
            } else {
                overlay_statistics[*kv.second.gress][1] += n_overlay; } } }

    ss << "======== CONTAINER OVERLAY STAT ===========" << std::endl;
    ss << "TOTAL INGRESS T-PHV OVERLAY BITS: " << overlay_statistics[INGRESS][0] << std::endl;
    ss << "TOTAL INGRESS PHV OVERLAY BITS: "   << overlay_statistics[INGRESS][1] << std::endl;
    ss << "TOTAL EGRESS T-PHV OVERLAY BITS: "  << overlay_statistics[EGRESS][0] << std::endl;
    ss << "TOTAL EGRESS PHV OVERLAY BITS: "    << overlay_statistics[EGRESS][1] << std::endl;

    for (auto kv : overlay_result) {
        ss << kv.first << " has overlaid: " << kv.second << " bits " << std::endl;
        for (const auto& slice : this->slices(kv.first)) {
            ss << slice << std::endl; } }
    ss << std::endl;

    // Output Partial Containers
    ss << "======== PARTIAL CONTAINERS STAT ==========" << std::endl;
    ss << "TOTAL UNALLOCATED BITS: " << total_unalloacted_bits << std::endl;
    ss << "VALID INGRESS UNALLOCATED BITS: " << valid_ingress_unallocated_bits << std::endl;
    ss << "VALID EGRESS UNALLOCATED BITS: " << valid_egress_unallocated_bits << std::endl;
    for (const auto& kv : partial_containers_stat) {
        ss << kv.first << " has unallocated bits: " << kv.second << std::endl;
        for (const auto& slice : this->slices(kv.first)) {
            ss << slice << std::endl; } }

    // compute tphv fields allocated on phv fields
    int total_tphv_on_phv = 0;
    std::map<PHV::Container, int> tphv_on_phv;
    for (auto kv : container_status_i) {
        PHV::Container c = kv.first;
        if (c.is(PHV::Kind::tagalong)) {
            continue; }
        int n_tphvs = 0;
        for (auto slice : kv.second.slices) {
            if (slice.field()->is_tphv_candidate(uses)) {
                n_tphvs += slice.width(); } }
        if (n_tphvs == 0) continue;
        tphv_on_phv[c] = n_tphvs;
        total_tphv_on_phv += n_tphvs; }

    ss << "======== TPHV ON PHV STAT ========" << std::endl;
    ss << "Total bits: " << total_tphv_on_phv << std::endl;
    for (auto kv : tphv_on_phv) {
        ss << kv.first << " has " << kv.second << " bits " << std::endl;
        for (const auto& slice : slices(kv.first)) {
            if (slice.field()->is_tphv_candidate(uses)) {
                ss << slice << std::endl; } } }

    return ss.str();
}

PHV::Allocation::const_iterator PHV::Transaction::begin() const {
    P4C_UNIMPLEMENTED("Transaction::begin()");
}

PHV::Allocation::const_iterator PHV::Transaction::end() const {
    P4C_UNIMPLEMENTED("Transaction::end()");
}

// Returns the contents of this transaction *and* its parent.
ordered_set<PHV::AllocSlice> PHV::Transaction::slices(PHV::Container c) const {
    return slices(c, StartLen(0, int(c.type().size())));
}

// Returns the contents of this transaction *and* its parent.
ordered_set<PHV::AllocSlice> PHV::Transaction::slices(PHV::Container c, le_bitrange range) const {
    ordered_set<PHV::AllocSlice> rv;

    // Copy in any parent slices first, as they were allocated first.
    rv = parent_i->slices(c, range);

    // Then insert any transaction slices.
    if (container_status_i.find(c) != container_status_i.end()) {
        for (auto& slice : container_status_i.at(c).slices)
            if (slice.container_slice().intersectWith(range).size() > 0)
                rv.insert(slice); }

    return rv;
}

PHV::Allocation::GressAssignment PHV::Transaction::gress(PHV::Container c) const {
    if (container_status_i.find(c) != container_status_i.end())
        return container_status_i.at(c).gress;
    return parent_i->gress(c);
}

PHV::Allocation::ContainerAllocStatus PHV::Transaction::alloc_status(PHV::Container c) const {
    if (container_status_i.find(c) != container_status_i.end())
        return container_status_i.at(c).alloc_status;
    return parent_i->alloc_status(c);
}

ordered_set<PHV::AllocSlice>
PHV::Transaction::slices(const PHV::Field* f, le_bitrange range) const {
    ordered_set<PHV::AllocSlice> rv;

    // Copy in parent slices first, as they were allocated first.
    rv = parent_i->slices(f, range);

    // Then insert any transaction slices.
    if (field_status_i.find(f) != field_status_i.end()) {
        for (auto& slice : field_status_i.at(f))
            if (slice.field_slice().overlaps(range))
                rv.insert(slice); }

    return rv;
}

cstring PHV::Transaction::getTransactionSummary() const {
    std::map<boost::optional<gress_t>,
        std::map<PHV::Type,
            std::map<ContainerAllocStatus,
                int>>> alloc_status;

    // Compute status.
    for (auto kv : getTransactionStatus()) {
        PHV::Container c = kv.first;
        ContainerAllocStatus status = ContainerAllocStatus::EMPTY;
        bitvec allocatedBits;
        for (auto slice : kv.second.slices)
            allocatedBits |= bitvec(slice.container_slice().lo, slice.container_slice().size());
        if (allocatedBits == bitvec(0, c.size()))
            status = ContainerAllocStatus::FULL;
        else if (!allocatedBits.empty())
            status = ContainerAllocStatus::PARTIAL;
        alloc_status[container_status_i.at(c).gress][c.type()][status]++;
    }

    // Print container status.
    std::stringstream ss;
    ss << "TRANSACTION STATUS (Only for this transaction):" << std::endl;
    ss << boost::format("%1% %|10t| %2% %|20t| %3% %|30t| %4%\n")
        % "GRESS" % "TYPE" % "STATUS" % "COUNT";

    bool first_by_gress = true;
    auto gresses = std::vector<boost::optional<gress_t>>({INGRESS, EGRESS, boost::none});
    auto statuses = {ContainerAllocStatus::EMPTY,
                     ContainerAllocStatus::PARTIAL,
                     ContainerAllocStatus::FULL};
    for (auto gress : gresses) {
        first_by_gress = true;
        for (auto status : statuses) {
            for (auto type : Device::phvSpec().containerTypes()) {
                if (alloc_status[gress][type][status] == 0)
                    continue;
                std::stringstream ss_gress;
                std::string s_status;
                ss_gress << gress;
                switch (status) {
                  case ContainerAllocStatus::EMPTY:   s_status = "EMPTY"; break;
                  case ContainerAllocStatus::PARTIAL: s_status = "PARTIAL"; break;
                  case ContainerAllocStatus::FULL:    s_status = "FULL"; break; }
                ss << boost::format("%1% %|10t| %3% %|20t| %2% %|30t| %4%\n")
                      % (first_by_gress  ? ss_gress.str() : "")
                      % type.toString()
                      % s_status
                      % alloc_status[gress][type][status];
                first_by_gress = false; } } }

    return ss.str();
}

cstring PHV::Transaction::getSummary(const PhvUse& /* uses */) const {
    P4C_UNIMPLEMENTED("Transaction::getSummary()");
}

bool PHV::AlignedCluster::operator==(const PHV::AlignedCluster& other) const {
    return kind_i == other.kind_i && slices_i == other.slices_i;
}

void PHV::AlignedCluster::set_cluster_id() {
    id_i = cluster_id_g++;
}

void PHV::AlignedCluster::initialize_constraints() {
    exact_containers_i = 0;
    max_width_i = 0;
    num_constraints_i = 0;
    aggregate_size_i = 0;
    alignment_i = boost::none;

    for (auto& slice : slices_i) {
        // XXX(cole): These constraints will be subsumed by deparser schema.
        exact_containers_i += slice.field()->exact_containers() ? 1 : 0;
        max_width_i = std::max(max_width_i, slice.size());
        aggregate_size_i += slice.size();
        gress_i = slice.gress();

        auto s_alignment = slice.alignment();
        if (alignment_i && s_alignment && *alignment_i != *s_alignment) {
            std::stringstream msg;
            msg << "Fields involved in the same MAU operations have conflicting PARDE alignment "
                << "requirements: " << *alignment_i << " and " << *s_alignment << std::endl;
            msg << "Fields in cluster:" << std::endl;
            for (auto& slice : slices_i)
                msg << "    " << slice << std::endl;
            ::error("%1%", msg.str());
        } else if (!alignment_i && s_alignment) {
            alignment_i = s_alignment;
        }

        // XXX(cole): This should probably live in the field object.
        if (slice.field()->deparsed())              num_constraints_i++;
        if (slice.field()->no_pack())               num_constraints_i++;
        if (slice.field()->deparsed_bottom_bits())  num_constraints_i++;
        if (slice.field()->exact_containers())      num_constraints_i++; }
}

boost::optional<le_bitrange>
PHV::AlignedCluster::validContainerStartRange(PHV::Size container_size) const {
    le_bitrange container_slice = StartLen(0, int(container_size));
    LOG5("Computing valid container start range for cluster " <<
         " for placement in " << container_slice << " slices of " <<
         container_size << " containers.");

    // Compute the range of valid alignment of the first bit (low, little
    // Endian) of all cluster fields, which is the intersection of the valid
    // starting bit positions of each field in the cluster.
    le_bitinterval valid_start_interval = ZeroToMax();
    for (auto& slice : slices_i) {
        auto this_valid_start_range = validContainerStartRange(slice, container_size);
        if (!this_valid_start_range)
            return boost::none;

        LOG5("\tField slice " << slice << " has valid start interval of " <<
             *this_valid_start_range);

        valid_start_interval =
            valid_start_interval.intersectWith(toHalfOpenRange(*this_valid_start_range)); }

    return toClosedRange(valid_start_interval);
}

/* static */
boost::optional<le_bitrange> PHV::AlignedCluster::validContainerStartRange(
        PHV::FieldSlice slice,
        PHV::Size container_size) {
    le_bitrange container_slice = StartLen(0, int(container_size));
    LOG5("Computing valid container start range for cluster " <<
         " for placement in " << container_slice << " slices of " <<
         container_size << " containers.");

    // Compute the range of valid alignment of the first bit (low, little
    // Endian) of all cluster fields, which is the intersection of the valid
    // starting bit positions of each field in the cluster.
    bool has_deparsed_bottom_bits = false;
    le_bitinterval valid_start_interval = ZeroToMax();

    // If the field has deparsed bottom bits, and it includes the LSB for
    // the field, then all fields in the cluster will need to be aligned at
    // zero.
    if (slice.field()->deparsed_bottom_bits() && slice.range().lo == 0) {
        has_deparsed_bottom_bits = true;
        LOG5("\tSlice " << slice << " has deparsed bottom bits"); }

    BUG_CHECK(slice.size() <= int(container_size), "Slice size greater than container size");
    LOG5("\tField slice " << slice << " to be placed in container size " << container_size <<
         " slices has " << (slice.validContainerRange() == ZeroToMax() ? "no" :
             cstring::to_cstring(slice.validContainerRange())) << " alignment requirement.");

    // Intersect the valid range of this field with the container size.
    nw_bitrange container_range = StartLen(0, int(container_size));
    nw_bitinterval valid_interval = container_range.intersectWith(slice.validContainerRange());
    BUG_CHECK(!valid_interval.empty(), "Bad absolute container range; "
              "field slice %1% has valid container range %2%, which has no "
              "overlap with container range %3%",
              slice.field()->name, slice.validContainerRange(), container_range);

    // ...and converted to little Endian with respect to the coordinate
    // space formed by the container.
    le_bitrange valid_range =
        (*toClosedRange(valid_interval)).toOrder<Endian::Little>(int(container_size));

    // Convert from a range denoting a valid placement of the whole slice
    // to a range denoting the valid placement of the first (lo, little
    // Endian) bit of the field in the first slice.
    //
    // (We add 1 to reflect that the valid starting range for a field
    // includes its first bit.)
    valid_start_interval =
        valid_range.resizedToBits(valid_range.size() - slice.range().size() + 1)
                   .intersectWith(container_slice);

    LOG5("\tField slice " << slice << " has valid start interval of " <<
         valid_start_interval);

    // If any field has this requirement, then all fields must be aligned
    // at (little Endian) 0 in each container.
    if (has_deparsed_bottom_bits && valid_start_interval.contains(0))
        return le_bitrange(StartLen(0, 1));
    else if (has_deparsed_bottom_bits)
        return boost::none;
    else
        return toClosedRange(valid_start_interval);
}

bool PHV::AlignedCluster::okIn(PHV::Kind kind) const {
    return kind_i <= kind;
}

bitvec PHV::AlignedCluster::validContainerStart(PHV::Size container_size) const {
    boost::optional<le_bitrange> opt_valid_start_range = validContainerStartRange(container_size);
    if (!opt_valid_start_range)
        return bitvec();
    auto valid_start_range = *opt_valid_start_range;

    if (!this->alignment())
        return bitvec(valid_start_range.lo, valid_start_range.size());

    // account for relative alignment
    int align_start = valid_start_range.lo;
    if (align_start % 8 != int(*this->alignment())) {
        bool next_byte = align_start % 8 > int(*this->alignment());
        align_start += *this->alignment() + (next_byte ? 8 : 0) - align_start % 8; }

    bitvec rv;
    while (valid_start_range.contains(align_start)) {
        rv.setbit(align_start);
        align_start += 8; }

    return rv;
}

/* static */
bitvec PHV::AlignedCluster::validContainerStart(PHV::FieldSlice slice, PHV::Size container_size) {
    boost::optional<le_bitrange> opt_valid_start_range =
        validContainerStartRange(slice, container_size);
    if (!opt_valid_start_range)
        return bitvec();
    auto valid_start_range = *opt_valid_start_range;

    if (!slice.alignment())
        return bitvec(valid_start_range.lo, valid_start_range.size());

    // account for relative alignment
    int align_start = valid_start_range.lo;
    if (align_start % 8 != int(slice.alignment()->littleEndian)) {
        bool next_byte = align_start % 8 > int(slice.alignment()->littleEndian);
        align_start += slice.alignment()->littleEndian + (next_byte ? 8 : 0) - align_start % 8; }

    bitvec rv;
    while (valid_start_range.contains(align_start)) {
        rv.setbit(align_start);
        align_start += 8; }

    return rv;
}

bool PHV::AlignedCluster::contains(const PHV::Field *f) const {
    for (auto& s : slices_i)
        if (s.field() == f)
            return true;
    return false;
}

bool PHV::AlignedCluster::contains(const PHV::FieldSlice& s1) const {
    for (auto& s2 : slices_i)
        if (s1.field() == s2.field())
            return true;
    return false;
}

boost::optional<PHV::SliceResult<PHV::AlignedCluster>> PHV::AlignedCluster::slice(int pos) const {
    BUG_CHECK(pos >= 0, "Trying to slice cluster at negative position");
    PHV::SliceResult<PHV::AlignedCluster> rv;
    std::vector<PHV::FieldSlice> lo_slices;
    std::vector<PHV::FieldSlice> hi_slices;
    for (auto& slice : slices_i) {
        // Put slice in lo if pos is larger than the slice.
        if (slice.range().size() <= pos) {
            lo_slices.push_back(slice);
            rv.slice_map.emplace(PHV::FieldSlice(slice), std::make_pair(slice, boost::none));
            continue; }
        // Check whether the field in `slice` can be sliced.
        if (slice.field()->no_split())
            return boost::none;
        // Create new slices.
        le_bitrange lo_range = StartLen(slice.range().lo, pos);
        le_bitrange hi_range = StartLen(slice.range().lo + pos,
                                        slice.range().size() - lo_range.size());
        auto lo_slice = PHV::FieldSlice(slice, lo_range);
        auto hi_slice = PHV::FieldSlice(slice, hi_range);
        lo_slices.push_back(lo_slice);
        hi_slices.push_back(hi_slice);
        // Update the slice map.
        rv.slice_map.emplace(PHV::FieldSlice(slice), std::make_pair(lo_slice, hi_slice));
    }

    rv.lo = new PHV::AlignedCluster(kind_i, lo_slices);
    rv.hi = new PHV::AlignedCluster(kind_i, hi_slices);
    return rv;
}

PHV::RotationalCluster::RotationalCluster(ordered_set<PHV::AlignedCluster*> clusters)
        : clusters_i(clusters) {
    // Populate the field-->cluster map (slices_to_clusters_i).
    for (auto* cluster : clusters_i)
        for (auto& slice : *cluster)
            slices_to_clusters_i[slice] = cluster;

    // Tally stats.
    kind_i = PHV::Kind::tagalong;
    for (auto* cluster : clusters_i) {
        // XXX(cole): We'll need to update this for JBay.
        if (!cluster->okIn(kind_i))
            kind_i = PHV::Kind::normal;
        if (cluster->exact_containers())
            exact_containers_i++;
        gress_i = cluster->gress();
        max_width_i = std::max(max_width_i, cluster->max_width());
        num_constraints_i += cluster->num_constraints();
        aggregate_size_i += cluster->aggregate_size(); }
}

bool PHV::RotationalCluster::operator==(const PHV::RotationalCluster& other) const {
    if (clusters_i.size() != other.clusters_i.size())
        return false;

    for (auto* cluster : clusters_i) {
        bool found = false;
        for (auto* cluster2 : other.clusters_i) {
            if (*cluster == *cluster2) {
                found = true;
                break; } }
        if (!found)
            return false; }

    return true;
}

bool PHV::RotationalCluster::okIn(PHV::Kind kind) const {
    return kind_i <= kind;
}

bool PHV::RotationalCluster::contains(const PHV::Field* f) const {
    for (auto& kv : slices_to_clusters_i)
        if (f == kv.first.field())
            return true;
    return false;
}

bool PHV::RotationalCluster::contains(const PHV::FieldSlice& slice) const {
    return slices_to_clusters_i.find(slice) != slices_to_clusters_i.end();
}


boost::optional<PHV::SliceResult<PHV::RotationalCluster>>
PHV::RotationalCluster::slice(int pos) const {
    BUG_CHECK(pos >= 0, "Trying to slice cluster at negative position");
    PHV::SliceResult<PHV::RotationalCluster> rv;
    ordered_set<PHV::AlignedCluster*> lo_clusters;
    ordered_set<PHV::AlignedCluster*> hi_clusters;
    for (auto* aligned_cluster : clusters_i) {
        auto new_clusters = aligned_cluster->slice(pos);
        if (!new_clusters)
            return boost::none;
        // Filter empty clusters, as some clusters may only have fields smaller
        // than pos.
        if (new_clusters->lo->slices().size())
            lo_clusters.insert(new_clusters->lo);
        if (new_clusters->hi->slices().size())
            hi_clusters.insert(new_clusters->hi);
        for (auto& kv : new_clusters->slice_map)
            rv.slice_map.emplace(kv.first, kv.second); }

    rv.lo = new PHV::RotationalCluster(lo_clusters);
    rv.hi = new PHV::RotationalCluster(hi_clusters);
    return rv;
}



PHV::SuperCluster::SuperCluster(
        ordered_set<const PHV::RotationalCluster*> clusters,
        ordered_set<SliceList*> slice_lists)
        : clusters_i(clusters), slice_lists_i(slice_lists) {
    // Populate the field slice-->cluster map (slices_to_clusters_i)
    for (auto* rotational_cluster : clusters)
        for (auto* aligned_cluster : rotational_cluster->clusters())
            for (auto& slice : *aligned_cluster)
                slices_to_clusters_i[slice] = rotational_cluster;

    // Check that every field is present in some cluster.
    for (auto* slice_list : slice_lists) {
        for (auto& slice : *slice_list) {
            BUG_CHECK(slices_to_clusters_i.find(slice) != slices_to_clusters_i.end(),
                      "Trying to form cluster group with a slice list containing %1%, "
                      "which is not present in any cluster", cstring::to_cstring(slice)); } }

    // Tally stats.
    kind_i = PHV::Kind::tagalong;
    for (auto* cluster : clusters_i) {
        // XXX(cole): We'll need to update this for JBay.
        if (!cluster->okIn(kind_i))
            kind_i = PHV::Kind::normal;
        if (cluster->exact_containers())
            exact_containers_i++;
        gress_i = cluster->gress();
        max_width_i = std::max(max_width_i, cluster->max_width());
        num_constraints_i += cluster->num_constraints();
        aggregate_size_i += cluster->aggregate_size(); }
}

bool PHV::SuperCluster::operator==(const PHV::SuperCluster& other) const {
    if (clusters_i.size() != other.clusters_i.size() ||
            slice_lists_i.size() != other.slice_lists_i.size()) {
        return false; }

    for (auto* cluster : clusters_i) {
        bool found = false;
        for (auto* cluster2 : other.clusters_i) {
            if (*cluster == *cluster2) {
                found = true;
                break; } }
        if (!found)
            return false; }

    for (auto* list : slice_lists_i) {
        bool found = false;
        for (auto* list2 : other.slice_lists_i) {
            if (*list == *list2) {
                found = true;
                break; } }
        if (!found)
            return false; }

    return true;
}

bool PHV::SuperCluster::okIn(PHV::Kind kind) const {
    return kind_i <= kind;
}

bool PHV::SuperCluster::contains(const PHV::Field* f) const {
    for (auto* cluster : clusters_i)
        if (cluster->contains(f))
            return true;
    return false;
}

bool PHV::SuperCluster::contains(const PHV::FieldSlice& slice) const {
    for (auto* cluster : clusters_i)
        if (cluster->contains(slice))
            return true;
    return false;
}

void PHV::Allocation::print_occupancy() const {
    if (!LOGGING(2)) return;
    const auto& phvSpec = Device::phvSpec();
    std::set<PHV::Container> containers_used;
    std::map<bitvec, size_t> groups_usage;
    std::map<bitvec, size_t> groups_containers;
    std::map<bitvec, int> groups_to_ids;

    // Extract MAU group specific information from phvSpec
    std::pair<int, int> numBytes = phvSpec.mauGroupNumAndSize(PHV::Type::B);
    std::pair<int, int> numHalfs = phvSpec.mauGroupNumAndSize(PHV::Type::H);
    std::pair<int, int> numWords = phvSpec.mauGroupNumAndSize(PHV::Type::W);

    for (auto cid : Device::phvSpec().physicalContainers()) {
        PHV::Container c = Device::phvSpec().idToContainer(cid);

        // Calculate bits used in this container.
        int bitsUsed = 0;
        for (auto& mutually_live_slices : this->slicesByLiveness(c)) {
            int used = 0;
            for (auto& slice : mutually_live_slices)
                used += slice.width();
            bitsUsed = std::max(bitsUsed, used); }

        if (boost::optional<bitvec> mau_group = phvSpec.mauGroup(cid)) {
            groups_containers[mau_group.get()] += 1;
            groups_usage[mau_group.get()] += bitsUsed;
            // Group numbers go from Words -> Bytes -> Halfwords
            // In Tofino, this is (0-3) -> (4-7) -> (8-13)
            if (c.type() == PHV::Type::B)
                groups_to_ids[mau_group.get()] = (c.index() / numBytes.second) + numWords.first;
            else if (c.type() == PHV::Type::H)
                groups_to_ids[mau_group.get()] = (c.index() / numHalfs.second) + (numWords.first
                        + numBytes.first);
            else if (c.type() == PHV::Type::W)
                groups_to_ids[mau_group.get()] = (c.index() / numWords.second); } }

    LOG2("\nPHV Groups Allocation State:\n");
    LOG2("-----------------------------------------------------");
    LOG2("|     PHV Group     |   Containers   |   Bits Used  |");
    LOG2("|  (container bits) |      Used      |              |");
    LOG2("-----------------------------------------------------");

    // Print PHV groups
    for (auto container_type : Device::phvSpec().containerTypes()) {
        for (auto mau_group : Device::phvSpec().mauGroups(container_type)) {
            LOG2("|\t\t" << groups_to_ids[mau_group] << " (" << container_type << ")\t\t|\t\t" <<
                    groups_containers[mau_group] << "\t\t|\t\t" << groups_usage[mau_group] <<
                    "\t\t|"); }
        // Ensure that the line appears only for B, H, and W; not for TB, TH, TW
        if (Device::phvSpec().mauGroups(container_type).size() != 0)
            LOG2("-----------------------------------------------------"); }
}


/// @returns true if all slices lists and slices are smaller than 32b and no
/// slice list contains more than one slice per aligned cluster.

/// XXX(cole): Also check that slice lists with exact_container requirements
/// are all the same size.  We should check this ahead of time, though.

/// XXX(cole): Also check that deparsed bottom bits fields are at the front of
/// their slice lists.
bool PHV::SuperCluster::is_well_formed(const SuperCluster* sc) {
    LOG6("Examining sliced SuperCluster: ");
    LOG6(sc);
    ordered_set<int> exact_list_sizes;
    int widest = 0;

    // Check that slice lists do not contain slices from the same
    // AlignedCluster.
    for (auto* list : sc->slice_lists()) {
        ordered_set<const PHV::AlignedCluster*> seen;
        int size = 0;
        bool has_exact_containers = false;
        for (auto& slice : *list) {
            if (slice.field()->deparsed_bottom_bits() && slice.range().lo == 0 && size != 0) {
                LOG6("    ...but slice at offset " << size << " has deparsed_bottom_bits: "
                     << slice);
                return false; }
            has_exact_containers |= slice.field()->exact_containers();
            size += slice.size();
            auto* cluster = &sc->aligned_cluster(slice);
            if (seen.find(cluster) != seen.end()) {
                LOG6("    ...but slice list has two slices from the same aligned cluster: ");
                LOG6("        " << list);
                return false; }
            seen.insert(cluster); }
        widest = std::max(widest, size);
        if (has_exact_containers)
            exact_list_sizes.insert(size);
        if (size > int(PHV::Size::b32)) {
            LOG6("    ...but 32 < " << list);
            return false; } }

    // Check the widths of slices in RotationalClusters, which could be wider
    // than fields in slice lists in the case of non-uniform operand widths.
    for (auto* rotational : sc->clusters())
        for (auto* aligned : rotational->clusters())
            for (auto& slice : *aligned)
                widest = std::max(widest, slice.size());

    // Check that all slice lists with exact container requirements are the
    // same size.
    if (exact_list_sizes.size() > 1) {
        LOG6("    ...but slice lists with 'exact container' constraints differ in size");
        return false; }

    // Check that nothing is wider than the widest slice list with exact
    // container requirements.
    if (exact_list_sizes.size() > 0 && widest > *exact_list_sizes.begin()) {
        LOG6("    ...but supercluster contains a slice/slice list wider than a slice list with "
             "the 'exact container' constraint");
        return false; }

    for (auto* rotational : sc->clusters())
        for (auto* aligned : rotational->clusters())
            for (auto& slice : *aligned)
                if (slice.size() > int(PHV::Size::b32)) {
                    LOG6("    ...but 32 < " << slice);
                    return false; }

    LOG6("    ...and SC is well formed");
    return true;
}

PHV::SlicingIterator::SlicingIterator(const SuperCluster* sc) : sc_i(sc), done_i(false) {
    LOG5("Making SlicingIterator for SuperCluster:");
    LOG5(sc);

    has_slice_lists_i = sc->slice_lists().size() > 0;
    if (has_slice_lists_i) {
        // A "slicing schema" is a bitvec where each bit corresponds to a bit
        // position in a slice list to be split.  Each '1' corresponds to where
        // the slice list should be split.
        //
        // A "compressed slicing schema" encodes combinations of byte-aligned
        // slices, where bit k of a compressed schema corresponds to bit (k +
        // 1) * 8 of an (expanded) slicing schema.
        //
        // To explore all possible combinations of splitting each slice list at
        // byte-aligned boundaries, we concatenate a compressed slicing schema
        // for each slice list, forming one big bitvec with subranges
        // corresponding to each slice list.  The `ranges_i` map records these
        // locations.
        //
        // Then, exploring all combinations corresponds to exploring all bit
        // patterns in the concatenated schema, which we accomplish by treating
        // the bitvec like an integer, starting at zero, and incrementing by 1
        // until all combinations have been tried.
        //
        // However, we can eagerly prune some invalid bit combinations:
        //
        //  - Slices need to be 8b, 16b, or 32b, which implies that sequences
        //    of '0' in the bitvec need to be exactly zero, one, or three.
        //
        //  - The first slice of a field with the `deparsed_bottom_bits`
        //    constraint must be the first slice in its slice list.  The
        //    `required_slices_i` bitvec is a compressed schema with bits that
        //    must always be 1.
        int offset = 0;
        for (auto* list : sc->slice_lists()) {
            int size = 0;
            // Always require a split at the beginning of a slice with deparsed_bottom_bits.
            for (auto& slice : *list) {
                if (slice.field()->deparsed_bottom_bits() && slice.range().lo == 0 && size > 0) {
                    // XXX(cole): 'BUG_CHECK' here might be too strong.
                    BUG_CHECK(size % 8 == 0, "Can't slice on field %1% in slice list %2% "
                        "(which has deparsed bottom bits) because it is not byte aligned",
                        cstring::to_cstring(slice), cstring::to_cstring(list));
                    LOG6("Required slice at " << offset + (size / 8 - 1)
                         << " for field slice " << slice);
                    required_slices_i.setbit(offset + (size / 8 - 1)); }
                size += slice.size(); }
            BUG_CHECK(size > 0, "Empty slice list");

            // (range[list].hi + 1) * 8 is the first split position *beyond the
            // end* of the slice list.  Note that slice lists 8b or smaller
            // cannot be sliced, which is reflected in bits_needed == 0.
            int bits_needed = size / 8 - (1 - bool(size % 8));
            ranges_i[list] = StartLen(offset, bits_needed);
            offset += bits_needed;
            boundaries_i.setbit(offset);
            LOG5("    ...slice list (" << size << "b) with compressed bitvec size "
                 << bits_needed); }

        // TODO: Consider `no_pack` constraints in required_slices.  If a slice
        // in a slice list has `no_pack`, then the slice list needs to be
        // sliced exactly around it.

        // TODO: Add a dual `prohibited_slices`, which are slices that cannot
        // be considered (i.e. AND -prohibited_slices).  This accounts for
        // `no_split` constraints and will be necessary for the @pragma
        // pa_container_size.

        // `offset` holds the size of the entire concatenated slicing schemas.
        // If this is zero, then no slice list is larger than 8b, and
        // the only possible slicing is no slicing at all.
        if (offset <= 0) {
            LOG5("    ...but no slicing needed");
            auto new_sc = new PHV::SuperCluster(sc->clusters(), sc->slice_lists());
            if (PHV::SuperCluster::is_well_formed(new_sc)) {
                sentinel_idx_i = 0;
                cached_i = { new_sc };
            } else {
                done_i = true;
            }
            return; }

        // When the sentinel_idx bit is set, all bits corresponding to all
        // split schemas have rolled over to zero.
        sentinel_idx_i = offset;
        if (LOGGING(5) && !required_slices_i.empty()) {
            std::stringstream ss;
            for (int x : required_slices_i)
                ss << ((x + 1) * 8) << " ";
            LOG5("    ...with fixed slices at " << ss.str()); }

        compressed_schemas_i = required_slices_i;
        // Start with the smallest number that has sequences of exactly zero,
        // one, or three zeroes, which corresponds to slices sizes of 8b, 16b,
        // and 32b.  @see PHV::inc().
        PHV::enforce_container_sizes(compressed_schemas_i,
                                     sentinel_idx_i,
                                     boundaries_i,
                                     required_slices_i);
    } else {
        // In this case, there are no slice lists, and the SuperCluster
        // contains a single RotationalCluster.  We will try all slicings of
        // the RotationalCluster.  We use the same compressed slicing schema
        // approach as for slice lists, where bit[n] indicates whether index (n
        // + 1) * 8 should be split.
        sentinel_idx_i = sc->max_width() / 8 - (1 - bool(sc->max_width() % 8));
        if (sentinel_idx_i <= 0) {
            LOG5("    ...but no slicing needed");
            auto new_sc = new PHV::SuperCluster(sc->clusters(), sc->slice_lists());
            if (PHV::SuperCluster::is_well_formed(new_sc)) {
                sentinel_idx_i = 0;
                cached_i = { new_sc };
            } else {
                done_i = true;
            }
            return; } }

    BUG_CHECK(sentinel_idx_i > 0, "Bad compressed schema sentinel: %1%", sentinel_idx_i);
    LOG3("    ...there are 2^" << sentinel_idx_i << " ways to slice");
    if (LOGGING(6)) {
        std::stringstream ss;
        for (int i = 0; i < sentinel_idx_i; ++i)
            ss << (compressed_schemas_i[i] ? "1" : "-");
        LOG6("Initial compressed schemas: " << ss.str()); }

    // Look for the first valid slicing.
    if (auto res = get_slices())
        cached_i = *res;
    else
        this->operator++();
}

namespace PHV {

// Helper for split_super_cluster;
using ListClusterPair = std::pair<SuperCluster::SliceList*, const RotationalCluster*>;
std::ostream &operator<<(std::ostream &out, const ListClusterPair& pair) {
    out << std::endl;
    out << "(    " << pair.first << std::endl;
    out << ",    " << pair.second << "    )";
    return out;
}
std::ostream &operator<<(std::ostream &out, const ListClusterPair* pair) {
    if (pair)
        out << *pair;
    else
        out << "-null-listclusterpair-";
    return out;
}

// Helper function to update internal state of split_super_cluster after
// splitting a rotational cluster.  Mutates each argument.
static void update_slices(const RotationalCluster* old,
    const SliceResult<RotationalCluster>& split_res,
    ordered_set<const RotationalCluster*>& new_clusters,
    ordered_set<SuperCluster::SliceList*>& slice_lists,
    ordered_map<FieldSlice, ordered_set<SuperCluster::SliceList*>>& slices_to_slice_lists,
    ordered_map<const FieldSlice, const RotationalCluster*>& slices_to_clusters) {
    // Update the set of live clusters.
    auto old_it = new_clusters.find(old);
    if (old_it != new_clusters.end()) {
        LOG6("    ...erasing old cluster " << old);
        new_clusters.erase(old); }
    new_clusters.insert(split_res.lo);
    LOG6("    ...adding new lo cluster " << split_res.lo);
    new_clusters.insert(split_res.hi);
    LOG6("    ...adding new hi cluster " << split_res.hi);

    // Update the slices_to_clusters map.
    LOG6("    ...updating slices_to_clusters");
    for (auto& kv : split_res.slice_map) {
        BUG_CHECK(slices_to_clusters.find(kv.first) != slices_to_clusters.end(),
                  "Slice not in map: %1%", cstring::to_cstring(kv.first));
        LOG6("        - erasing " << kv.first);
        slices_to_clusters.erase(kv.first);
        auto& slice_lo = kv.second.first;
        LOG6("        - adding " << slice_lo);
        slices_to_clusters[slice_lo] = split_res.lo;
        if (auto& slice_hi = kv.second.second) {
            LOG6("        - adding " << *slice_hi);
            slices_to_clusters[*slice_hi] = split_res.hi; } }

    // Replace the old slices with the new, split slices in each slice
    // list.
    LOG6("    ...updating slice_lists");
    for (auto* slice_list : slice_lists) {
        for (auto slice_it  = slice_list->begin();
                  slice_it != slice_list->end();
                  slice_it++) {
            auto& old_slice = *slice_it;
            if (split_res.slice_map.find(old_slice) != split_res.slice_map.end()) {
                auto& slice_lo = split_res.slice_map.at(old_slice).first;
                auto& slice_hi = split_res.slice_map.at(old_slice).second;
                slice_it = slice_list->erase(slice_it);
                LOG6("        - erasing " << old_slice);
                slice_it = slice_list->insert(slice_it, slice_lo);
                LOG6("        - adding " << slice_lo);
                if (slice_hi) {
                    slice_it++;
                    slice_it = slice_list->insert(slice_it, *slice_hi);
                    LOG6("        - adding " << *slice_hi); } } } }

    // Update the slices_to_slice_lists map.
    LOG6("    ...updating slices_to_slice_lists");
    for (auto& kv : split_res.slice_map) {
        // Slices in RotationalClusters but not in slice lists do not need to
        // be updated.
        if (slices_to_slice_lists.find(kv.first) == slices_to_slice_lists.end())
            continue;
        slices_to_slice_lists[kv.second.first] = slices_to_slice_lists.at(kv.first);
        if (kv.second.second)
            slices_to_slice_lists[*kv.second.second] = slices_to_slice_lists.at(kv.first);
        slices_to_slice_lists.erase(kv.first); }
}

}   // namespace PHV


// Keys of split_schemas must be slice lists in sc.
/* static */
boost::optional<std::list<PHV::SuperCluster*>> PHV::SlicingIterator::split_super_cluster(
        const PHV::SuperCluster* sc,
        ordered_map<PHV::SuperCluster::SliceList*, bitvec> split_schemas) {
    if (LOGGING(6)) {
        LOG6("Split schema:");
        for (auto& kv : split_schemas) {
            int size = 0;
            for (auto slice : *kv.first)
                size += slice.size();
            std::stringstream ss;
            for (int idx = 0; idx < size; ++idx)
                ss << (kv.second[idx] ? "1" : "-");
            LOG6("    " << ss.str());
            LOG6("    " << kv.first); }
        LOG6(""); }

    std::list<PHV::SuperCluster*> rv;
    // Deep copy all slice lists, so they can be updated without mutating sc.
    // Update split_schemas to point to the new slice lists, and build a map
    // of slices to new slice lists.
    ordered_set<PHV::SuperCluster::SliceList*> slice_lists;
    ordered_map<PHV::FieldSlice, ordered_set<PHV::SuperCluster::SliceList*>>
        slices_to_slice_lists;

    for (auto* old_list : sc->slice_lists()) {
        BUG_CHECK(old_list->size(), "Empty slice list in SuperCluster %1%",
                  cstring::to_cstring(sc));
        // Make new list.
        auto* new_list = new PHV::SuperCluster::SliceList();
        slice_lists.insert(new_list);
        // Copy from old to new.
        new_list->insert(new_list->begin(), old_list->begin(), old_list->end());
        // Update split_schema.
        if (split_schemas.find(old_list) != split_schemas.end()) {
            split_schemas[new_list] = split_schemas.at(old_list);
            split_schemas.erase(old_list); }
        // Build map.
        for (auto& slice : *new_list)
            slices_to_slice_lists[slice].insert(new_list); }

    // Track live RotationalClusters. Clusters that have been split are no
    // longer live.
    ordered_set<const PHV::RotationalCluster*> new_clusters;
    new_clusters.insert(sc->clusters().begin(), sc->clusters().end());

    // Keep a map of slices to clusters (both old and new for this schema).
    ordered_map<const PHV::FieldSlice, const PHV::RotationalCluster*> slices_to_clusters;
    for (auto* rotational : new_clusters)
        for (auto* aligned : rotational->clusters())
            for (auto& slice : *aligned)
                slices_to_clusters[slice] = rotational;

    // Split each slice list according to its schema.  If a slice is split,
    // then split its RotationalCluster.  Produces a new set of slice lists and
    // rotational clusters.  Fail if a proposed split would violate
    // constraints, like `no_split`.
    for (auto& kv : split_schemas) {
        auto* slice_list = kv.first;
        bitvec split_schema = kv.second;

        // If there are no bits set in the split schema, then no split has been
        // requested.
        if (split_schema.empty())
            continue;

        // Remove this list, which will be replaced with new lists.
        slice_lists.erase(slice_list);

        // Iterate through split positions.
        int offset = 0;
        auto* slice_list_lo = new PHV::SuperCluster::SliceList();
        bitvec::nonconst_bitref next_split = split_schema.begin();
        BUG_CHECK(*next_split >= 0, "Trying to split slice list at negative index");
        auto next_slice = slice_list->begin();

        // This loop stutter-steps both `next_slice` and `next_split`.
        while (next_slice != slice_list->end()) {
            auto slice = *next_slice;
            // After processing the last split, just place all remaining slices
            // into slice_list_lo.
            if (next_split == split_schema.end()) {
                slice_list_lo->push_back(slice);
                ++next_slice;
                continue; }

            // Otherwise, process slices up to the next split position, then
            // advance the split position.
            if (offset < *next_split && offset + slice.size() <= *next_split) {
                // Slice is completely before the split position.
                LOG6("    ...(" << offset << ") adding to slice list: " << slice);
                slice_list_lo->push_back(slice);
                ++next_slice;
                offset += slice.size();
            } else if (offset == *next_split) {
                // Split position falls between slices.  Advance next_split BUT
                // NOT next_slice.
                LOG6("    ...(" << offset << ") split falls between slices");

                // Check that this position doesn't split adjacent slices of a
                // no_split field.
                if (next_slice != slice_list->begin()) {
                    auto last_it = next_slice;
                    last_it--;
                    if (last_it->field() == next_slice->field()
                            && next_slice->field()->no_split()) {
                        LOG6("    ...(" << offset << ") field cannot be split: "
                             << next_slice->field());
                        return boost::none; } }

                // Otherwise, create new slice list and advance the split position.
                slice_lists.insert(slice_list_lo);
                slice_list_lo = new PHV::SuperCluster::SliceList();
                LOG6("    ...(" << offset << ") starting new slice list");

                // XXX(cole): next_split++ fails to resolve to
                // next_split.operator++().  Not sure why.
                next_split.operator++();
            } else if (offset < *next_split && *next_split < offset + slice.size()) {
                // The split position falls within a slice and will need to be
                // split.  Advance next_split and set next_slice to point to the
                // top half of the post-split subslice.
                LOG6("    ...(" << offset << ") found slice to split at idx "
                     << *next_split << ": " << slice);

                // Split slice.
                auto* rotational = slices_to_clusters.at(slice);
                auto split_result = rotational->slice(*next_split - offset);
                if (!split_result) {
                    LOG6("    ...(" << offset << ") but split failed");
                    return boost::none; }
                BUG_CHECK(split_result->slice_map.find(slice) != split_result->slice_map.end(),
                          "Bad split schema: slice map does not contain split slice");

                // Update this slice list (which has been
                // removed and is no longer part of slice_lists), taking care to ensure
                // the next_slice iterator is updated to point to the new *lower* subslice.
                for (auto it = slice_list->begin(); it != slice_list->end(); ++it) {
                    auto s = *it;
                    if (split_result->slice_map.find(s) == split_result->slice_map.end())
                        continue;
                    bool is_this_slice = it == next_slice;
                    // Replace s with its two new subslices.
                    auto& subs = split_result->slice_map.at(s);
                    it = slice_list->erase(it);
                    LOG6("    ...erasing " << s << " in this slice list");
                    it = slice_list->insert(it, subs.first);
                    LOG6("    ...adding " << subs.first << " in this slice list");
                    if (is_this_slice)
                        next_slice = it;
                    if (subs.second) {
                        ++it;
                        it = slice_list->insert(it, *subs.second);
                        LOG6("    ...adding " << *subs.second << " in this slice list"); } }

                // Advance the iterator to the next slice, which is either the
                // new upper slice (if it exists).
                ++next_slice;

                // Add current list, make new list, advance next_split.
                auto& new_slices = split_result->slice_map.at(slice);
                slice_list_lo->push_back(new_slices.first);
                LOG6("    ...(" << offset << ") adding to slice list: " << slice);
                slice_lists.insert(slice_list_lo);
                slice_list_lo = new PHV::SuperCluster::SliceList();
                LOG6("    ...(" << offset << ") starting new slice list");
                // XXX(cole): next_split++ fails to resolve to
                // next_split.operator++().  Not sure why.
                next_split.operator++();
                offset += new_slices.first.size();

                // Update all slices/clusters in new_clusters,
                // slices_to_clusters, and slice_lists.
                PHV::update_slices(
                    rotational, *split_result,
                    new_clusters, slice_lists, slices_to_slice_lists, slices_to_clusters);
            } else {
                // Adding this to ensure the above logic (which is a bit
                // complicated) covers all cases.  Note that *next_split < offset
                // should never be true, as other cases should advance next_split.
                std::stringstream ss;
                for (int x : split_schema)
                    ss << x << " ";
                BUG("Bad split.\nOffset: %3%\nNext split: %4%\nSplit schema: %1%\nSlice list: %2%",
                    ss.str(), cstring::to_cstring(slice_list), offset, *next_split); } }

            BUG_CHECK(next_split == split_schema.end(),
                      "Slicing schema tries to slice at %1% but slice list is %2%b long",
                      *next_split, offset);

            if (slice_list_lo->size())
                slice_lists.insert(slice_list_lo); }

        // We need to ensure that all the slice lists and clusters that overlap
        // (i.e. share slices) end up in the same SuperCluster.
        UnionFind<PHV::ListClusterPair> uf;
        slices_to_slice_lists.clear();

        // Populate UF universe.
        auto* empty_slice_list = new PHV::SuperCluster::SliceList();
        for (auto* slice_list : slice_lists) {
            for (auto& slice : *slice_list) {
                BUG_CHECK(slices_to_clusters.find(slice) != slices_to_clusters.end(),
                          "No slice to cluster map for %1%", cstring::to_cstring(slice));
                auto* cluster = slices_to_clusters.at(slice);
                uf.insert({ slice_list, cluster });
                slices_to_slice_lists[slice].insert(slice_list); } }
        for (auto* rotational : new_clusters)
            uf.insert({ empty_slice_list, rotational });

        // Union over slice lists.
        for (auto* slice_list : slice_lists) {
            BUG_CHECK(slices_to_clusters.find(slice_list->front()) != slices_to_clusters.end(),
                      "No slice to cluster map for front slice %1%",
                      cstring::to_cstring(slice_list->front()));
            auto first = uf.find({ slice_list, slices_to_clusters.at(slice_list->front()) });
            for (auto& slice : *slice_list) {
                BUG_CHECK(slices_to_clusters.find(slice) != slices_to_clusters.end(),
                          "No slice to cluster map for slice %1%",
                          cstring::to_cstring(slice));
                uf.makeUnion(first, { slice_list, slices_to_clusters.at(slice) }); } }

        // Union over clusters.
        for (auto* rotational : new_clusters) {
            PHV::ListClusterPair first = { empty_slice_list, rotational };
            for (auto* aligned : rotational->clusters()) {
                for (auto& slice : *aligned) {
                    for (auto* slice_list : slices_to_slice_lists[slice])
                        uf.makeUnion(first, { slice_list, rotational }); } } }

        for (auto* pairs : uf) {
            ordered_set<const PHV::RotationalCluster*> clusters;
            ordered_set<PHV::SuperCluster::SliceList*> slice_lists;
            for (auto& pair : *pairs) {
                if (pair.first->size())
                    slice_lists.insert(pair.first);
                clusters.insert(pair.second); }
            rv.push_back(new PHV::SuperCluster(clusters, slice_lists)); }

    return rv;
}


// For splitting a supercluster without any slice lists.  As superclusters
// only contain rotational clusters with fields in the same slice list, then
// superclusters with no slice lists can only contain a single rotational
// cluster.  @split_schema splits it.
boost::optional<std::list<PHV::SuperCluster*>>
PHV::SlicingIterator::split_super_cluster(const PHV::SuperCluster* sc, bitvec split_schema) {
    // This method cannot handle super clusters with slice lists.
    if (sc->slice_lists().size() > 0)
        return boost::none;

    BUG_CHECK(sc->clusters().size() != 0, "SuperCluster with no RotationalClusters: %1%",
              cstring::to_cstring(sc));
    BUG_CHECK(sc->clusters().size() == 1,
              "SuperCluster with no slice lists but more than one RotationalCluster: %1%",
              cstring::to_cstring(sc));

    // An empty split schema means no split is necessary.
    if (split_schema.empty())
        return std::list<PHV::SuperCluster*>({
            new PHV::SuperCluster(sc->clusters(), sc->slice_lists()) });

    // Otherwise, if this SuperCluster doesn't have any slice lists, then slice
    // the rotational clusters directly.
    std::list<PHV::SuperCluster*> rv;
    auto* remainder = *sc->clusters().begin();
    int offset = 0;
    for (int next_split : split_schema) {
        BUG_CHECK(next_split >= 0, "Trying to split remainder cluster at negative index");
        auto res = remainder->slice(next_split - offset);
        if (!res)
            return boost::none;
        offset = next_split;
        rv.push_back(new PHV::SuperCluster({ res->lo }, { }));
        remainder = res->hi; }

    rv.push_back(new PHV::SuperCluster({ remainder }, { }));
    return rv;
}

boost::optional<std::list<PHV::SuperCluster*>> PHV::SlicingIterator::get_slices() const {
    if (has_slice_lists_i) {
        // Convert the compressed schema for each slice list into an expanded schema.
        ordered_map<PHV::SuperCluster::SliceList*, bitvec> split_schemas;
        for (auto& kv : ranges_i) {
            le_bitrange range = kv.second;
            bitvec compressed_schema = compressed_schemas_i.getslice(range.lo, range.size());
            bitvec expanded_schema;
            for (int i = 0; i < range.size(); ++i)
                if (compressed_schema[i])
                    expanded_schema.setbit((i + 1) * 8);
            split_schemas[kv.first] = expanded_schema; }

        // Try slicing using this set of expanded schemas.
        auto res = split_super_cluster(sc_i, split_schemas);

        // If we found a good slicing, return it.
        if (res && std::all_of(res->begin(), res->end(), PHV::SuperCluster::is_well_formed))
            return res;
        else
            return boost::none;
    } else {
        // Expand the compressed schema.
        bitvec split_schema;
        for (int i : compressed_schemas_i)
            split_schema.setbit((i + 1) * 8);

        if (LOGGING(6)) {
            std::stringstream ss;
            for (int i = 0; i < sentinel_idx_i; i++)
                ss << (compressed_schemas_i[i] ? "1" : "0");
            LOG6("Splitting RotationalCluster with compressed schema " << ss.str()); }

        // Split the supercluster.
        auto res = split_super_cluster(sc_i, split_schema);

        // If successful, return it.
        if (res && std::all_of(res->begin(), res->end(), PHV::SuperCluster::is_well_formed))
            return res;
        else
            return boost::none; }
}

std::list<PHV::SuperCluster*> PHV::SlicingIterator::operator*() const {
    return cached_i;
}

PHV::SlicingIterator PHV::SlicingIterator::operator++() {
    if (done_i)
        return *this;

    while (!compressed_schemas_i[sentinel_idx_i]) {
        // Increment the bitvec...
        PHV::inc(compressed_schemas_i);
        // and set the required slices...
        compressed_schemas_i |= required_slices_i;
        // and set the least significant bits necessary to ensure that
        // slices correspond to container sizes.
        PHV::enforce_container_sizes(compressed_schemas_i,
                                     sentinel_idx_i,
                                     boundaries_i,
                                     required_slices_i);

        // Stop if we find a valid slicing.
        if (auto res = get_slices()) {
            cached_i = *res;
            break; } }

    if (compressed_schemas_i[sentinel_idx_i])
        done_i = true;

    return *this;
}

bool PHV::SlicingIterator::operator==(const SlicingIterator& other) const {
    bool both_done = done_i && other.done_i;
    bool equal_compressed_schemas = compressed_schemas_i == other.compressed_schemas_i;
    return sc_i == other.sc_i && (both_done || equal_compressed_schemas);
}

namespace PHV {

// Assumes required_bits are set beforehand and ensures they remain set.
inline void enforce_container_sizes(
        bitvec& bv,
        int sentinel,
        const bitvec& boundaries,
        const bitvec& required) {
    // Eagerly break invalid sequences of zeroes.  See comment in utils.h.
    // NB: Because we're walking backwards, boundaries[i] is true for the last
    // bit of each range, eg. boundaries[i] implies that the *next* bit (i-1)
    // crosses a boundary.
    enum state_t { COUNTING, SETTING };
    state_t state = COUNTING;
    int zeroes = 0;
    for (int i = sentinel - 1; i >= 0; --i) {
        if (state == COUNTING) {
            // If this is a break point and we're not setting, reset the count.
            if (bv[i])
                zeroes = 0;
            else
                ++zeroes;

            // Look ahead to see if the next bit is a breaking point.
            bool break_next = i == 0 || boundaries[i] || bv[i-1];

            if ((break_next && zeroes == 2) || zeroes > 3) {
                state = SETTING;
                zeroes = 0;
                bv.setbit(i); }

            if (boundaries[i])
                zeroes = 0;
        } else {
            // state == SETTING.
            if (bv[i])
                bv.clrbit(i);
            ++zeroes;

            if (required[i]) {
                bv.setbit(i);
                zeroes = 0; }

            bool at_last_bit = i == 0 || boundaries[i];
            if (zeroes > 3 || (zeroes == 2 && at_last_bit)) {
                bv.setbit(i);
                zeroes = 0; }

            if (boundaries[i]) {
                state = COUNTING;
                zeroes = 0; }
        }
    }
}

void inc(bitvec& bv) {
    if (bv.empty()) {
        bv.setbit(0);
        return; }

    int max = *bv.max();
    int zeroes = 0;
    int i;
    for (i = 0; i <= max; ++i) {
        if (bv.getbit(i)) {
            zeroes++;
            bv.clrbit(i);
        } else {
            break; } }

    bv.setbit(i);
}
std::ostream &operator<<(std::ostream &out, const PHV::Allocation& alloc) {
    if (dynamic_cast<const PHV::Transaction *>(&alloc)) {
        P4C_UNIMPLEMENTED("<<(PHV::Transaction)");
        return out; }

    for (auto kv : alloc) {
        if (kv.second.slices.size() == 0) {
            out << boost::format("%1%(%2%)\n")
                 % cstring::to_cstring(kv.first)
                 % cstring::to_cstring(kv.second.gress);
            continue; }

        for (auto slice : kv.second.slices) {
            std::stringstream container_slice;
            std::stringstream field_slice;
            if (slice.container_slice().size() != int(slice.container().size()))
                container_slice << "[" << slice.container_slice().lo << ":" <<
                slice.container_slice().hi << "]";
            if (slice.field_slice().size() != slice.field()->size)
                field_slice << "[" << slice.field_slice().lo << ":" <<
                slice.field_slice().hi << "]";
            out << boost::format("%1%(%2%)%3% %|25t| <-- %|30t|%4%%5%\n")
                 % cstring::to_cstring(slice.container())
                 % cstring::to_cstring(kv.second.gress)
                 % container_slice.str()
                 % cstring::to_cstring(slice.field())
                 % field_slice.str(); } }
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::Allocation* alloc) {
    if (alloc)
        out << *alloc;
    else
        out << "-null-alloc-";
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::AllocSlice& slice) {
    out << slice.container() << slice.container_slice() << "<--"
        << PHV::FieldSlice(slice.field(), slice.field_slice());
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::AllocSlice* slice) {
    if (slice)
        out << *slice;
    else
        out << "-null-alloc-slice-";
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::ContainerGroup& g) {
    out << "(";
    auto it = g.begin();
    while (it != g.end()) {
        out << *it;
        ++it;
        if (it != g.end())
            out << ", "; }
    out << ")";
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::ContainerGroup* g) {
    if (g)
        out << *g;
    else
        out << "-null-container-group-";
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::AlignedCluster& cl) {
    out << "[";
    unsigned count = 0;
    for (auto& slice : cl) {
        count++;
        out << slice;
        if (count < cl.slices().size())
            out << ", "; }
    out << "]";
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::AlignedCluster* cl) {
    if (cl)
        out << *cl;
    else
        out << "-null-aligned-cluster-";
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::RotationalCluster& cl) {
    out << "[";
    unsigned count = 0;
    for (auto& cluster : cl.clusters()) {
        count++;
        out << cluster;
        if (count < cl.clusters().size())
            out << ", "; }
    out << "]";
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::RotationalCluster* cl) {
    if (cl)
        out << *cl;
    else
        out << "-null-rotational-cluster-";
    return out;
}

// TODO(cole): This could really stand to be improved.
std::ostream &operator<<(std::ostream &out, const PHV::SuperCluster& g) {
    // Print the slice lists.
    out << "SUPERCLUSTER" << std::endl;
    out << "    slice lists:\t";
    if (g.slice_lists().size() == 0) {
        out << "[ ]" << std::endl;
    } else {
        out << std::endl;
        for (auto* slice_list : g.slice_lists()) {
            out << boost::format("%|8t|%1%") % cstring::to_cstring(*slice_list);
            out << std::endl; }
    }

    // Print aligned clusters.
    out << "    rotational clusters:\t";
    if (g.clusters().size() == 0) {
        out << "{ }" << std::endl;
    } else {
        out << std::endl;
        for (auto* cluster : g.clusters()) {
            out << boost::format("%|8t|%1%") % cstring::to_cstring(cluster);
            out << std::endl; }
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::SuperCluster* g) {
    if (g)
        out << *g;
    else
        out << "-null-cluster-group-";
    return out;
}

std::ostream &operator<<(std::ostream &out, const SuperCluster::SliceList& list) {
    out << "[";
    for (auto& slice : list) {
        if (slice == list.front())
            out << " " << slice;
        else
            out << "          " << slice;
        if (slice != list.back())
            out << std::endl; }
    out << " ]";
    return out;
}

std::ostream &operator<<(std::ostream &out, const SuperCluster::SliceList* list) {
    if (list)
        out << *list;
    else
        out << "-null-slice-list-";
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::FieldSlice& fs) {
    if (fs.field() == nullptr) {
        out << "-field-slice-of-null-field-ptr-";
        return out; }

    auto& field = *fs.field();
    out << field.name << "<" << field.size << ">";
    if (fs.alignment())
        out << " ^" << fs.alignment()->littleEndian;
    if (fs.validContainerRange() != ZeroToMax())
        out << " ^" << fs.validContainerRange();
    if (field.bridged) out << " bridge";
    if (field.metadata) out << " meta";
    if (field.mirror_field_list.member_field)
        out << " mirror%{"
            << field.mirror_field_list.member_field->id
            << ":" << field.mirror_field_list.member_field->name
            << "#" << field.mirror_field_list.field_list
            << "}%";
    if (field.pov) out << " pov";
    if (field.deparsed()) out << " deparsed";
    if (field.no_pack()) out << " no_pack";
    if (field.no_split()) out << " no_split";
    if (field.deparsed_bottom_bits()) out << " deparsed_bottom_bits";
    if (field.deparsed_to_tm()) out << " deparsed_to_tm";
    if (field.exact_containers()) out << " exact_containers";
    out << " [" << fs.range().lo << ":" << fs.range().hi << "]";
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::FieldSlice* fs) {
    if (fs)
        out << *fs;
    else
        out << "-null-field-slice ";
    return out;
}

/// Partial order for allocation status.
bool operator<(
        PHV::Allocation::ContainerAllocStatus left,
        PHV::Allocation::ContainerAllocStatus right) {
    if (left == right)
        return false;
    else if (right == PHV::Allocation::ContainerAllocStatus::EMPTY)
        return false;
    else if (right == PHV::Allocation::ContainerAllocStatus::PARTIAL &&
             left == PHV::Allocation::ContainerAllocStatus::FULL)
        return false;
    else
        return true;
}

bool operator<=(
        PHV::Allocation::ContainerAllocStatus left,
        PHV::Allocation::ContainerAllocStatus right) {
    return left < right || left == right;
}

bool operator>(
        PHV::Allocation::ContainerAllocStatus left,
        PHV::Allocation::ContainerAllocStatus right) {
    return !(left <= right);
}

bool operator>=(
        PHV::Allocation::ContainerAllocStatus left,
        PHV::Allocation::ContainerAllocStatus right) {
    return !(left < right);
}

}  // namespace PHV
