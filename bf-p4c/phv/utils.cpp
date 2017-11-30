#include "utils.h"
#include <boost/optional/optional_io.hpp>
#include <iostream>

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
}

void PHV::Allocation::addSlice(PHV::Container c, AllocSlice slice) {
    container_status_i[c].slices.insert(slice);
    field_status_i[slice.field()].insert(slice);
}

void PHV::Allocation::setGress(PHV::Container c, GressAssignment gress) {
    container_status_i[c].gress = gress;
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

/** Assign @slice to @slice.container, updating the gress information of
 * the container and its MAU group if necessary.  Fails if the gress of
 * @slice.field does not match any gress in the MAU group.
 */
void PHV::Allocation::allocate(PHV::AllocSlice slice) {
    auto& phvSpec = Device::phvSpec();
    unsigned slice_cid = phvSpec.containerToId(slice.container());

    BUG_CHECK(contains(slice.container()),
              "Trying to allocate slice %1% to an allocation that does not include container %2%",
              cstring::to_cstring(slice), slice.container());

    // Fail if any part of this field slice has already been allocated.
    const auto& existing_alloc = this->slices(slice.field(), slice.field_slice());
    BUG_CHECK(existing_alloc.size() == 0, "Trying to allocate slice %1%, but other overlapping "
              "slices of this field have already been allocated: %2%",
              cstring::to_cstring(slice), cstring::to_cstring(existing_alloc));

    LOG4("tentatively allocating " << slice.container() <<
         "(" << this->gress(slice.container()) << ") " << slice.container_slice() <<
         " <-- " << slice.field() << "(" << slice.field()->gress << ") " << slice.field_slice());

    // Check and update gress for all containers in this deparser group.
    if (!this->gress(slice.container())) {
        for (unsigned cid : phvSpec.deparserGroup(slice_cid)) {
            auto c = phvSpec.idToContainer(cid);
            BUG_CHECK(!this->gress(c) ||
                      *this->gress(c) == slice.field()->gress,
                "Trying to allocate field %1% with gress %2% to container %3% with gress %4%",
                slice.field()->name, slice.field()->gress, slice.container(),
                this->gress(c));
            LOG5("    ...maybe assigning " << c << " to " << slice.field()->gress);
            this->setGress(c, slice.field()->gress); } }

    BUG_CHECK(this->gress(slice.container()) &&
              *this->gress(slice.container()) == slice.field()->gress,
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
        this->addStatus(kv.first, kv.second);
    }
    view.clearTransactionStatus();
}

PHV::Transaction PHV::Allocation::makeTransaction() const {
    return Transaction(mutex_i, *this);
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
        container_status_i[c] = { gress, { } }; }
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

/// @returns a summary of the status of each container by type and gress.
cstring PHV::ConcreteAllocation::getSummary() const {
    enum Status { EMPTY, PARTIAL, FULL };
    std::map<boost::optional<gress_t>,
        std::map<PHV::Type,
            std::map<Status,
                int>>> alloc_status;

    // Compute status.
    for (auto kv : container_status_i) {
        PHV::Container c = kv.first;
        Status status = EMPTY;
        bitvec allocatedBits;
        for (auto slice : kv.second.slices)
            allocatedBits |= bitvec(slice.container_slice().lo, slice.container_slice().size());
        if (allocatedBits == bitvec(0, c.size()))
            status = FULL;
        else if (!allocatedBits.empty())
            status = PARTIAL;
        alloc_status[container_status_i.at(c).gress][c.type()][status]++;
    }

    // Print container status.
    std::stringstream ss;
    ss << "CONTAINER STATUS (after allocation so far):" << std::endl;
    ss << boost::format("%1% %|10t| %2% %|20t| %3% %|30t| %4%\n")
        % "GRESS" % "TYPE" % "STATUS" % "COUNT";

    bool first_by_gress = true;
    auto gresses = std::list<boost::optional<gress_t>>({INGRESS, EGRESS, boost::none});
    auto statuses = {EMPTY, PARTIAL, FULL};
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
                  case EMPTY:   s_status = "EMPTY"; break;
                  case PARTIAL: s_status = "PARTIAL"; break;
                  case FULL:    s_status = "FULL"; break; }
                ss << boost::format("%1% %|10t| %3% %|20t| %2% %|30t| %4%\n")
                      % (first_by_gress  ? ss_gress.str() : "")
                      % type.toString()
                      % s_status
                      % alloc_status[gress][type][status];
                first_by_gress = false; } } }

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
    rv = parent_i.slices(c, range);

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
    return parent_i.gress(c);
}

ordered_set<PHV::AllocSlice>
PHV::Transaction::slices(const PHV::Field* f, le_bitrange range) const {
    ordered_set<PHV::AllocSlice> rv;

    // Copy in parent slices first, as they were allocated first.
    rv = parent_i.slices(f, range);

    // Then insert any transaction slices.
    if (field_status_i.find(f) != field_status_i.end()) {
        for (auto& slice : field_status_i.at(f))
            if (slice.field_slice().overlaps(range))
                rv.insert(slice); }

    return rv;
}

cstring PHV::Transaction::getSummary() const {
    P4C_UNIMPLEMENTED("Transaction::getSummary()");
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

    for (auto* f : fields_i) {
        // XXX(cole): These constraints will be subsumed by deparser schema.
        exact_containers_i += f->exact_containers() ? 1 : 0;
        max_width_i = std::max(max_width_i, f->size);
        aggregate_size_i += f->size;

        auto f_alignment = boost::optional<unsigned>(f->phv_alignment());
        if (alignment_i && f_alignment && *alignment_i != *f_alignment) {
            std::stringstream msg;
            msg << "Fields involved in the same MAU operations have conflicting PARDE alignment "
                << "requirements: " << *alignment_i << " and " << *f_alignment << std::endl;
            msg << "Fields in cluster:" << std::endl;
            for (auto* f : fields_i)
                msg << "    " << f << std::endl;
            ::error("%1%", msg.str());
        } else if (!alignment_i && f_alignment) {
            alignment_i = f_alignment;
        }

        // XXX(cole): This should probably live in the field object.
        if (f->deparsed())              num_constraints_i++;
        if (f->no_pack())               num_constraints_i++;
        if (f->deparsed_bottom_bits())  num_constraints_i++;
        if (f->exact_containers())      num_constraints_i++;
        if (f->mau_phv_no_pack())       num_constraints_i++; }
}


boost::optional<le_bitrange>
PHV::AlignedCluster::validContainerStartRange(PHV::Size container_size) const {
    le_bitrange slice = StartLen(0, int(container_size));
    LOG5("Computing valid container start range for cluster " <<
         " for placement in " << slice << " slices of " << container_size << " containers.");

    // Compute the range of valid alignment of the first bit (low, little
    // Endian) of all cluster fields, which is the intersection of the valid
    // starting bit positions of each field in the cluster.
    bool has_deparsed_bottom_bits = false;
    le_bitinterval valid_start_interval = ZeroToMax();
    for (auto* f : fields_i) {
        // If the field has deparsed bottom bits, then all fields in the cluster
        // will need to be aligned at zero.
        has_deparsed_bottom_bits |= f->deparsed_bottom_bits();
        if (f->deparsed_bottom_bits())
            LOG5("\tField " << f << " has deparsed bottom bits");

        // Compute the total size of the slices required to hold this field.
        int field_placement_size = f->is_ccgf() ? f->ccgf_width() : f->size;
        int req_slices_for_field = field_placement_size / slice.size() +
                                   (field_placement_size % slice.size() ? 1 : 0);
        int aggregate_slice_bits = req_slices_for_field * slice.size();
        auto aggregate_slice_range = nw_bitrange(StartLen(0, aggregate_slice_bits));

        LOG5("\tField " << f << " to be placed across " << req_slices_for_field << " slices has "
             << (f->validContainerRange() == ZeroToMax() ? "no" :
                 cstring::to_cstring(f->validContainerRange())) << " alignment requirement.");

        // ...intersecting with the valid range for this field
        nw_bitinterval valid_interval =
            aggregate_slice_range.intersectWith(f->validContainerRange());
        BUG_CHECK(!valid_interval.empty(), "Bad absolute container range; "
                  "field %1% has valid container range %2%, which has no "
                  "overlap with aggregate container range %3%",
                  f->name, f->validContainerRange(), aggregate_slice_range);

        // ...and converted to little Endian with respect to the coordinate
        // space formed by the sum of all slices.
        le_bitrange valid_range =
            (*toClosedRange(valid_interval)).toOrder<Endian::Little>(
                aggregate_slice_bits);

        // Convert from a range denoting a valid placement of the whole field
        // to a range denoting the valid placement of the first (lo, little
        // Endian) bit of the field in the first slice.
        //
        // (We add 1 to reflect that the valid starting range for a field
        // includes its first bit.)
        le_bitinterval this_valid_start_interval =
            valid_range
              .resizedToBits(valid_range.size() - field_placement_size + 1)
              .intersectWith(slice);

        LOG5("\tField " << f << " has valid start interval of " << this_valid_start_interval);

        valid_start_interval =
            valid_start_interval.intersectWith(this_valid_start_interval); }

    // If any field has this requirement, then all fields must be aligned
    // at (little Endian) 0 in each container.
    if (has_deparsed_bottom_bits && valid_start_interval.contains(0))
        return le_bitrange(StartLen(0, 1));
    else if (has_deparsed_bottom_bits)
        return boost::none;
    else
        return toClosedRange(valid_start_interval);
}

boost::optional<le_bitrange>
PHV::AlignedCluster::validContainerStartRangeAfterSlicing(PHV::Size container_size) const {
    // Compute the range of valid alignment of the first bit (low, little
    // Endian) of all cluster fields, which is the intersection of the valid
    // starting bit positions of each field in the cluster.
    bool has_deparsed_bottom_bits = false;
    le_bitinterval cluster_valid_start_interval = ZeroToMax();
    for (auto* f : fields_i) {
        // Return `none` if f is too large to fit in containers of this size.
        // XXX(cole): Add this in along with slicing.
        // if (int(container_size) < f->size)
        //     return boost::none;

        // If the field has deparsed bottom bits, then all fields in the cluster
        // will need to be aligned at zero.
        has_deparsed_bottom_bits |= f->deparsed_bottom_bits();
        if (f->deparsed_bottom_bits())
            LOG5("\tField " << f << " has deparsed bottom bits");

        // Start with the range of the container
        nw_bitrange nw_container_range(StartLen(0, int(container_size)));

        // ...intersecting with the valid range for this field
        nw_bitinterval nw_valid_interval =
            nw_container_range.intersectWith(f->validContainerRange());

        if (nw_valid_interval.size() < f->size)
            return boost::none;

        // ...and converted to little Endian with respect to the coordinate
        // space formed by the container size.
        le_bitrange valid_range =
            (*toClosedRange(nw_valid_interval)).toOrder<Endian::Little>(int(container_size));

        // Convert from a range denoting a valid placement of the whole field
        // to a range denoting the valid placement of the first (lo, little
        // Endian) bit of the field.
        //
        // (We add 1 to reflect that the valid starting range for a field
        // includes its first bit.)
        le_bitinterval valid_start_interval =
            toHalfOpenRange(valid_range.resizedToBits(valid_range.size() - f->size + 1));

        LOG5("\tField " << f << " has valid start interval of " << valid_start_interval);

        cluster_valid_start_interval =
            cluster_valid_start_interval.intersectWith(valid_start_interval); }


    // If any field has this requirement, then all fields must be aligned
    // at (little Endian) 0 in each container.
    if (has_deparsed_bottom_bits && cluster_valid_start_interval.contains(0))
        return le_bitrange(StartLen(0, 1));
    else if (has_deparsed_bottom_bits)
        return boost::none;
    else
        return toClosedRange(cluster_valid_start_interval);
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

bool PHV::AlignedCluster::contains(const PHV::Field *f1) const {
    for (auto* f2 : fields_i)
        if (f1 == f2)
            return true;
    return false;
}

PHV::SuperCluster::SuperCluster(
        ordered_set<PHV::AlignedCluster*> clusters,
        ordered_set<FieldList*> field_lists)
        : clusters_i(clusters), field_lists_i(field_lists) {
    // Populate the field-->cluster map (fields_to_clusters_i), checking that
    // every field is present in some cluster.
    for (auto* field_list : field_lists) {
        for (auto* field : *field_list) {
            for (auto* cluster : clusters) {
                if (cluster->contains(field)) {
                    fields_to_clusters_i[field] = cluster;
                    break; } }
            BUG_CHECK(fields_to_clusters_i.find(field) != fields_to_clusters_i.end(),
                      "Trying to form cluster group with a field list containing %1%, "
                      "which is not present in any cluster", cstring::to_cstring(field)); } }

    // Tally stats.
    kind_i = PHV::Kind::tagalong;
    for (auto* cluster : clusters_i) {
        // XXX(cole): We'll need to update this for JBay.
        if (!cluster->okIn(kind_i))
            kind_i = PHV::Kind::normal;
        if (cluster->exact_containers())
            exact_containers_i++;
        max_width_i = std::max(max_width_i, cluster->max_width());
        num_constraints_i += cluster->num_constraints();
        aggregate_size_i += cluster->aggregate_size(); }
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
        << slice.field()->name << slice.field_slice();
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
    for (auto f : cl.fields()) {
        count++;
        out << f;
        if (count < cl.fields().size())
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

// TODO(cole): This could really stand to be improved.
std::ostream &operator<<(std::ostream &out, const PHV::SuperCluster& g) {
    // Print the field lists.
    if (g.field_lists().size() == 0) {
        out << "[ ]";
    } else {
        out << "[ ";
        unsigned count = 0U;
        for (auto* field_list : g.field_lists()) {
            out << boost::format("%|8t|%1%") % cstring::to_cstring(*field_list);
            if (++count < g.field_lists().size())
                out << std::endl; }
        out << " ]" << std::endl;
    }

    // Print aligned clusters.
    if (g.clusters().size() == 0) {
        out << "{ }";
    } else {
        out << "{ ";
        unsigned count = 0U;
        for (auto* cluster : g.clusters()) {
            out << boost::format("%|8t|%1%") % cstring::to_cstring(cluster);
            if (++count < g.clusters().size())
                out << std::endl; }
        out << " }" << std::endl;
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
