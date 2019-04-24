#include <boost/optional/optional_io.hpp>
#include <iostream>
#include <numeric>
#include "bf-p4c/common/table_printer.h"
#include "lib/algorithm.h"
#include "bf-p4c/device.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/phv/utils/report.h"

static int cluster_id_g = 0;                // global counter for assigning cluster ids

int PHV::ClusterStats::nextId = 0;

PHV::ContainerGroup::ContainerGroup(PHV::Size sz, const std::vector<PHV::Container> containers)
: size_i(sz), containers_i(containers) {
    // Check that all containers are the right size.
    for (auto c : containers_i) {
        BUG_CHECK(c.type().size() == size_i,
            "PHV container group constructed with size %1% but has container %2% of size %3%",
            cstring::to_cstring(size_i),
            cstring::to_cstring(c),
            cstring::to_cstring(c.size()));
        types_i.insert(c.type());
        ids_i.setbit(Device::phvSpec().containerToId(c)); }
}

PHV::ContainerGroup::ContainerGroup(PHV::Size sz, bitvec container_group)
: size_i(sz), ids_i(container_group) {
    const PhvSpec& phvSpec = Device::phvSpec();
    for (auto cid : container_group) {
        auto c = phvSpec.idToContainer(cid);
        BUG_CHECK(c.type().size() == size_i,
            "PHV container group constructed with size %1% but has container %2% of size %3%",
            cstring::to_cstring(size_i),
            cstring::to_cstring(c),
            cstring::to_cstring(c.size()));
        types_i.insert(c.type());
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
    container_status_i[c] = status;

    // Update field status.
    for (auto& slice : status.slices)
        field_status_i[slice.field()].insert(slice);
}

void PHV::Allocation::addMetaInitPoints(
        PHV::AllocSlice slice,
        ordered_set<const IR::MAU::Action*> actions) {
    meta_init_points_i[slice] = actions;
    LOG5("Adding init points for " << slice);
    LOG5("Number of entries in meta_init_points_i: " << meta_init_points_i.size());
    if (meta_init_points_i.size() > 0)
        for (auto kv : meta_init_points_i)
            LOG5("  Init points for " << kv.first << " : " << kv.second.size());
    for (const IR::MAU::Action* act : actions)
        init_writes_i[act].insert(slice.field());
}

void PHV::Allocation::addSlice(PHV::Container c, PHV::AllocSlice slice) {
    // Get the current status in container_status_i, or its ancestors, if any.
    ContainerStatus status = this->getStatus(c).get_value_or(ContainerStatus());
    status.slices.insert(slice);
    container_status_i[c] = status;

    // Update field status.
    field_status_i[slice.field()].insert(slice);

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

void PHV::Allocation::addMetadataInitialization(
        PHV::AllocSlice slice,
        LiveRangeShrinkingMap initNodes) {
    // If no initialization required for the slice, return.
    if (!initNodes.count(slice.field()))
        // Initialization is on a different AllocSlice.
        return;

    // If initialization required for the slice, then add it.
    this->addMetaInitPoints(slice, initNodes.at(slice.field()));
}

void PHV::Allocation::setGress(PHV::Container c, GressAssignment gress) {
    // Get the current status in container_status_i, or its ancestors, if any.
    ContainerStatus status = this->getStatus(c).get_value_or(ContainerStatus());
    status.gress = gress;
    container_status_i[c] = status;
}

void PHV::Allocation::setParserGroupGress(PHV::Container c, GressAssignment parserGroupGress) {
    // Get the current status in container_status_i, or its ancestors, if any.
    ContainerStatus status = this->getStatus(c).get_value_or(ContainerStatus());
    status.parserGroupGress = parserGroupGress;
    container_status_i[c] = status;
}

void PHV::Allocation::setDeparserGroupGress(PHV::Container c, GressAssignment deparserGroupGress) {
    // Get the current status in container_status_i, or its ancestors, if any.
    ContainerStatus status = this->getStatus(c).get_value_or(ContainerStatus());
    status.deparserGroupGress = deparserGroupGress;
    container_status_i[c] = status;
}

PHV::Allocation::MutuallyLiveSlices
PHV::Allocation::slicesByLiveness(const PHV::Container c, const AllocSlice& sl) const {
    PHV::Allocation::MutuallyLiveSlices rs;
    auto slices = this->slices(c);
    for (auto& slice : slices) {
        if (!PHV::Allocation::mutually_exclusive(*mutex_i, slice.field(), sl.field()))
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
            if (!PHV::Allocation::mutually_exclusive(*mutex_i, slice.field(), sl.field()))
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
                            *mutex_i, fid_to_slice.at(fid)->field(),
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
void PHV::Allocation::allocate(
        PHV::AllocSlice slice,
        boost::optional<LiveRangeShrinkingMap> initNodes) {
    auto& phvSpec = Device::phvSpec();
    unsigned slice_cid = phvSpec.containerToId(slice.container());
    auto containerGress = this->gress(slice.container());
    auto parserGroupGress = this->parserGroupGress(slice.container());
    auto deparserGroupGress = this->deparserGroupGress(slice.container());
    bool isDeparsed = uses_i->is_deparsed(slice.field());

    // If the container has been pinned to a gress, check that the gress
    // matches that of the slice.  Otherwise, pin it.
    if (containerGress) {
        BUG_CHECK(*containerGress == slice.field()->gress,
            "Trying to allocate field %1% with gress %2% to container %3% with gress %4%",
            slice.field()->name, slice.field()->gress, slice.container(),
            this->gress(slice.container()));
    } else {
        this->setGress(slice.container(), slice.field()->gress);
    }

    // If the slice is extracted, check (and maybe set) the parser group gress.
    if (uses_i->is_extracted(slice.field())) {
        if (parserGroupGress) {
            BUG_CHECK(*parserGroupGress == slice.field()->gress,
                "Trying to allocate field %1% with gress %2% to container %3% with "
                "parser group gress %4%", slice.field()->name, slice.field()->gress,
                slice.container(), *parserGroupGress);
        } else {
            for (unsigned cid : phvSpec.parserGroup(slice_cid)) {
                auto c = phvSpec.idToContainer(cid);
                auto cGress = this->parserGroupGress(c);
                BUG_CHECK(!cGress || *cGress == slice.field()->gress,
                        "Container %1% already has parser group gress set to %2%",
                        c, *this->parserGroupGress(c));
                this->setParserGroupGress(c, slice.field()->gress);
            }
        }
    }


    // If the slice is deparsed but the deparser group gress has not yet been
    // set, then set it for each container in the deparser group.
    if (isDeparsed && !deparserGroupGress) {
        for (unsigned cid : phvSpec.deparserGroup(slice_cid)) {
            auto c = phvSpec.idToContainer(cid);
            auto cGress = this->deparserGroupGress(c);
            BUG_CHECK(!cGress || *cGress == slice.field()->gress,
                    "Container %1% already has deparser group gress set to %2%",
                    c, *this->deparserGroupGress(c));
            this->setDeparserGroupGress(c, slice.field()->gress); }
    } else if (isDeparsed) {
        // Otherwise, check that the slice gress (which is equal to the
        // container's gress at this point) matches the deparser group gress.
        BUG_CHECK(slice.field()->gress == *deparserGroupGress,
                "Cannot allocate %1%, because container is already assigned to %2% but has a "
                "deparser group assigned to %3%", slice, slice.field()->gress, *deparserGroupGress);
    }

    // Set gress for all the containers in a tagalong group (for container only).
    if (slice.container().is(PHV::Kind::tagalong)) {
        for (unsigned cid : phvSpec.tagalongCollection(slice_cid)) {
            auto c = phvSpec.idToContainer(cid);
            auto cGress = this->gress(c);
            BUG_CHECK(!cGress || *cGress == slice.field()->gress,
                    "Container %1% already has gress set to %2%", c, *cGress);
            this->setGress(c, slice.field()->gress);
        }
    }

    // Update allocation.
    this->addSlice(slice.container(), slice);

    // Remember the initialization points for metadata.
    if (initNodes)
        this->addMetadataInitialization(slice, *initNodes);
}

void PHV::Allocation::commit(Transaction& view) {
    BUG_CHECK(view.getParent() == this, "Trying to commit PHV allocation transaction to an "
              "allocation that is not its parent");

    state_to_containers_i.clear();

    // Merge the status from the view.
    for (auto kv : view.getTransactionStatus())
        this->addStatus(kv.first, kv.second);

    // Merge the metadata initialization points from the view.
    for (auto kv : view.getMetaInitPoints())
        this->addMetaInitPoints(kv.first, kv.second);

    // Print the initialization information for this transaction.
    if (view.getInitWrites().size() != 0)
        for (auto kv : view.getInitWrites())
            this->init_writes_i[kv.first].insert(kv.second.begin(), kv.second.end());

    // Clear the view.
    view.clearTransactionStatus();
}

PHV::Transaction PHV::Allocation::makeTransaction() const {
    return Transaction(*this);
}

/// @returns a pretty-printed representation of this Allocation.
cstring PHV::Allocation::toString() const {
    return cstring::to_cstring(*this);
}

const ordered_set<const PHV::Field*>
PHV::Allocation::getMetadataInits(const IR::MAU::Action* act) const {
    ordered_set<const PHV::Field*> emptySet;
    if (!init_writes_i.count(act)) return emptySet;
    return init_writes_i.at(act);
}

const ordered_set<const IR::MAU::Action*>
PHV::Allocation::getInitPointsForField(const PHV::Field* f) const {
    ordered_set<const IR::MAU::Action*> rs;
    for (auto kv : meta_init_points_i) {
        if (kv.first.field() != f) continue;
        rs.insert(kv.second.begin(), kv.second.end());
    }
    return rs;
}

const ordered_set<unsigned>
PHV::Allocation::getTagalongCollectionsUsed() const {
    ordered_set<unsigned> rv;

    for (const auto kv : container_status_i) {
        const auto& container = kv.first;
        const auto& status = kv.second;

        const auto kind = container.type().kind();
        if (kind != PHV::Kind::tagalong) continue;
        if (status.alloc_status == ContainerAllocStatus::EMPTY) continue;

        unsigned collectionID = Device::phvSpec().getTagalongCollectionId(container);
        rv.insert(collectionID);
    }

    return rv;
}

const ordered_map<cstring, std::set<PHV::Container>>&
PHV::Allocation::getParserStateToContainers(const PhvInfo& phv) const {
    if (state_to_containers_i.empty()) {
        for (const auto& kv : field_status_i) {
            const auto& field = kv.first;
            const auto& container_slices = kv.second;

            for (auto slice : container_slices) {
                if (phv.field_to_parser_states.count(field->name)) {
                    for (auto state : phv.field_to_parser_states.at(field->name))
                        state_to_containers_i[state].insert(slice.container());
                }
            }
        }
    }

    return state_to_containers_i;
}

/* static */ bool
PHV::Allocation::mutually_exclusive(
        const SymBitMatrix& mutex,
        const PHV::Field *f1,
        const PHV::Field *f2) {
    return mutex(f1->id, f2->id);
}

std::set<PHV::Allocation::AvailableSpot>
PHV::Allocation::available_spots() const {
    std::set<AvailableSpot> rst;
    // Compute status.
    for (auto cid : Device::phvSpec().physicalContainers()) {
        PHV::Container c = Device::phvSpec().idToContainer(cid);
        auto slices = this->slices(c);
        auto gress = this->gress(c);
        auto parserGroupGress = this->parserGroupGress(c);
        auto deparserGroupGress = this->deparserGroupGress(c);
        // Empty
        if (slices.size() == 0) {
            rst.insert(AvailableSpot(c, gress, parserGroupGress, deparserGroupGress, c.size()));
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
            rst.insert(AvailableSpot(c, gress, parserGroupGress, deparserGroupGress,
                                     c.size() - used)); }
    }
    return rst;
}

/** Create an allocation from a vector of container IDs.  Physical
 * containers that the Device pins to a particular gress are
 * initialized to that gress.
 */
PHV::ConcreteAllocation::ConcreteAllocation(
        const SymBitMatrix& mutex,
        const PhvUse& uses,
        bitvec containers)
        : PHV::Allocation(mutex, uses) {
    auto& phvSpec = Device::phvSpec();
    for (auto cid : containers) {
        PHV::Container c = phvSpec.idToContainer(cid);

        // Initialize container status with hard-wired gress info and
        // an empty alloc slice list.
        boost::optional<gress_t> gress = boost::none;
        boost::optional<gress_t> parserGroupGress = boost::none;
        boost::optional<gress_t> deparserGroupGress = boost::none;
        if (phvSpec.ingressOnly()[phvSpec.containerToId(c)]) {
            gress = INGRESS;
            parserGroupGress = INGRESS;
            deparserGroupGress = INGRESS;
        } else if (phvSpec.egressOnly()[phvSpec.containerToId(c)]) {
            gress = EGRESS;
            parserGroupGress = EGRESS;
            deparserGroupGress = EGRESS; }
        container_status_i[c] =
            { gress, parserGroupGress, deparserGroupGress, { },
              PHV::Allocation::ContainerAllocStatus::EMPTY }; }
}

PHV::ConcreteAllocation::ConcreteAllocation(const SymBitMatrix& mutex, const PhvUse& uses)
: PHV::ConcreteAllocation::ConcreteAllocation(mutex, uses, Device::phvSpec().physicalContainers())
{ }

/// @returns true if this allocation owns @c.
bool PHV::ConcreteAllocation::contains(PHV::Container c) const {
    return container_status_i.find(c) != container_status_i.end();
}

ordered_set<const IR::MAU::Action*>
PHV::Allocation::getInitPoints(const PHV::AllocSlice& slice) const {
    static ordered_set<const IR::MAU::Action*> emptySet;
    if (!meta_init_points_i.count(slice)) return emptySet;
    return meta_init_points_i.at(slice);
}

ordered_set<const IR::MAU::Action*>
PHV::Transaction::getInitPoints(const PHV::AllocSlice& slice) const {
    if (meta_init_points_i.count(slice))
        return meta_init_points_i.at(slice);
    ordered_set<const IR::MAU::Action*> initPointsInParent;
    const Transaction* parentTransaction = dynamic_cast<const PHV::Transaction*>(parent_i);
    if (parentTransaction)
        initPointsInParent = parentTransaction->getInitPoints(slice);
    else
        initPointsInParent = parent_i->getInitPoints(slice);
    return initPointsInParent;
}

void PHV::Transaction::printMetaInitPoints() const {
    LOG5("\t\tTransaction: Getting init points for slices:");
    for (auto kv : meta_init_points_i)
        LOG5("\t\t  " << kv.first << " : " << kv.second.size());
    const Transaction* parentTransaction = dynamic_cast<const PHV::Transaction*>(parent_i);
    while (parentTransaction) {
        LOG5("\t\tAllocation: Getting init points for slices:");
        for (auto kv : parentTransaction->get_meta_init_points())
            LOG5("\t\t  " << kv.first << " : " << kv.second.size());
        parentTransaction = dynamic_cast<const PHV::Transaction*>(parentTransaction->parent_i);
    }
}

ordered_set<const IR::MAU::Action*>
PHV::ConcreteAllocation::getInitPoints(const PHV::AllocSlice slice) const {
    static ordered_set<const IR::MAU::Action*> emptySet;
    if (!meta_init_points_i.count(slice)) return emptySet;
    return meta_init_points_i.at(slice);
}

boost::optional<PHV::Allocation::ContainerStatus>
PHV::ConcreteAllocation::getStatus(PHV::Container c) const {
    if (container_status_i.find(c) != container_status_i.end())
        return container_status_i.at(c);
    return boost::none;
}

PHV::Allocation::FieldStatus PHV::ConcreteAllocation::getStatus(const PHV::Field* f) const {
    if (field_status_i.find(f) != field_status_i.end())
        return field_status_i.at(f);
    return { };
}

/// @returns the container status of @c and fails if @c is not present.
PHV::Allocation::GressAssignment PHV::Allocation::gress(PHV::Container c) const {
    auto status = this->getStatus(c);
    BUG_CHECK(status, "Trying to get gress for container %1% not in Allocation",
              cstring::to_cstring(c));
    return status->gress;
}

PHV::Allocation::GressAssignment
PHV::Allocation::parserGroupGress(PHV::Container c) const {
    auto status = this->getStatus(c);
    BUG_CHECK(status, "Trying to get parser group gress for container %1% not in Allocation",
              cstring::to_cstring(c));
    return status->parserGroupGress;
}

PHV::Allocation::GressAssignment
PHV::Allocation::deparserGroupGress(PHV::Container c) const {
    auto status = this->getStatus(c);
    BUG_CHECK(status, "Trying to get deparser group gress for container %1% not in Allocation",
              cstring::to_cstring(c));
    return status->deparserGroupGress;
}

PHV::Allocation::ContainerAllocStatus
PHV::Allocation::alloc_status(PHV::Container c) const {
    auto status = this->getStatus(c);
    BUG_CHECK(status, "Trying to get allocation status for container %1% not in Allocation",
              cstring::to_cstring(c));
    return status->alloc_status;
}

PHV::Allocation::const_iterator PHV::Transaction::begin() const {
    P4C_UNIMPLEMENTED("Transaction::begin()");
}

PHV::Allocation::const_iterator PHV::Transaction::end() const {
    P4C_UNIMPLEMENTED("Transaction::end()");
}

// Returns the contents of this transaction *and* its parent.
ordered_set<PHV::AllocSlice> PHV::Allocation::slices(PHV::Container c) const {
    return slices(c, StartLen(0, int(c.type().size())));
}

// Returns the contents of this transaction *and* its parent.
ordered_set<PHV::AllocSlice> PHV::Allocation::slices(PHV::Container c, le_bitrange range) const {
    ordered_set<PHV::AllocSlice> rv;

    if (auto status = this->getStatus(c))
        for (auto& slice : status->slices)
            if (slice.container_slice().intersectWith(range).size() > 0)
                rv.insert(slice);

    return rv;
}

boost::optional<PHV::Allocation::ContainerStatus>
PHV::Transaction::getStatus(PHV::Container c) const {
    // If a status exists in the transaction, then it includes info from the
    // parent.
    if (container_status_i.find(c) != container_status_i.end())
        return container_status_i.at(c);

    // Otherwise, retrieve and cache parent info.
    auto parentStatus = parent_i->getStatus(c);
    if (parentStatus)
        container_status_i[c] = *parentStatus;
    return parentStatus;
}

PHV::Allocation::FieldStatus
PHV::Transaction::getStatus(const PHV::Field* f) const {
    // If a status exists in the transaction, then it includes info from the
    // parent.
    if (field_status_i.find(f) != field_status_i.end())
        return field_status_i.at(f);

    // Otherwise, retrieve and cache parent info.
    auto parentStatus = parent_i->getStatus(f);
    field_status_i[f] = parentStatus;
    return parentStatus;
}

ordered_set<PHV::AllocSlice>
PHV::Allocation::slices(const PHV::Field* f, le_bitrange range) const {
    ordered_set<PHV::AllocSlice> rv;

    // Get status, which includes parent and child info.
    for (auto& slice : this->getStatus(f))
        if (slice.field_slice().overlaps(range))
            rv.insert(slice);

    return rv;
}

cstring PHV::Transaction::getTransactionSummary() const {
    ordered_map<boost::optional<gress_t>,
        ordered_map<PHV::Type,
            ordered_map<ContainerAllocStatus,
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
    hasDeparsedFields_i = false;

    for (auto& slice : slices_i) {
        // XXX(cole): These constraints will be subsumed by deparser schema.
        exact_containers_i += slice.field()->exact_containers() ? 1 : 0;
        max_width_i = std::max(max_width_i, slice.size());
        aggregate_size_i += slice.size();
        gress_i = slice.gress();
        if (slice.field()->deparsed() || slice.field()->deparsed_to_tm())
            hasDeparsedFields_i = true;

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
    bitvec rv = bitvec(valid_start_range.lo, valid_start_range.size());

    for (auto slice : *this)
        rv &= slice.getStartBits(container_size);

    // Account for relative alignment.
    if (this->alignment()) {
        bitvec bitInByteStarts;
        int idx(*this->alignment());
        while (idx < int(container_size)) {
            bitInByteStarts.setbit(idx);
            idx += 8; }
        rv &= bitInByteStarts; }

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
        if (slice.field()->no_split_at(pos)) {
            return boost::none; }
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
    for (auto* cluster : clusters_i) {
        for (auto& slice : *cluster) {
            slices_to_clusters_i[slice] = cluster;
            slices_i.insert(slice); } }

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
        aggregate_size_i += cluster->aggregate_size();
        hasDeparsedFields_i |= cluster->deparsed(); }
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
                      "which is not present in any cluster", cstring::to_cstring(slice));
            slices_to_slice_lists_i[slice].insert(slice_list); } }

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
        aggregate_size_i += cluster->aggregate_size();
        hasDeparsedFields_i |= cluster->deparsed(); }
}

void PHV::SuperCluster::calc_pack_conflicts() {
    // calculate number of no pack conditions for each super cluster
    forall_fieldslices([&] (const PHV::FieldSlice& fs) {
        num_pack_conflicts_i += fs.field()->num_pack_conflicts();
    });
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

const ordered_set<const PHV::SuperCluster::SliceList*>&
PHV::SuperCluster::slice_list(const PHV::FieldSlice& slice) const {
    static const ordered_set<const SliceList*> empty;
    if (slices_to_slice_lists_i.find(slice) == slices_to_slice_lists_i.end())
        return empty;
    return slices_to_slice_lists_i.at(slice);
}

bool PHV::SuperCluster::okIn(PHV::Kind kind) const {
    return kind_i <= kind;
}

PHV::SuperCluster* PHV::SuperCluster::mergeAndSortBasedOnWideArith(
  const PHV::SuperCluster *sc) {
    std::list<SliceList*> non_wide_slice_lists;
    std::list<SliceList*> wide_lo_slice_lists;
    std::list<SliceList*> wide_hi_slice_lists;

    auto processSliceList =
        [&](const ordered_set<SliceList*> *sl) {
        for (auto *a_list : *sl) {
            bool w = false;
            bool wLo = false;
            for (auto& fs : *a_list) {
                if (fs.field()->bit_used_in_wide_arith(fs.range().lo)) {
                    w = true;
                    wLo = fs.field()->bit_is_wide_arith_lo(fs.range().lo);
                    if (wLo)
                        wide_lo_slice_lists.push_back(a_list);
                    else
                        wide_hi_slice_lists.push_back(a_list);
                    break; } }
            if (!w) {
                non_wide_slice_lists.push_back(a_list);
            }
        }
    };
    processSliceList(&slice_lists_i);
    processSliceList(&sc->slice_lists_i);

    // Sort all the slice lists with wide arithmetic requirements
    // such that least significant bits of a field slice appear
    // earlier in the list, and the paired field slices are
    // adjacent in the list.
    // When we assign slices to containers, we need to consider
    // them in order so some other slice doesn't swoop in and take
    // its required location.
    std::list<SliceList*> wide_slice_lists;
    for (auto *lo_slice : wide_lo_slice_lists) {
        wide_slice_lists.push_back(lo_slice);
        // find its linked hi slice list
        auto *hi_slice = sc->findLinkedWideArithSliceList(lo_slice);
        // Possible that the hi_slice may be a part of the current supercluster, and not the passed
        // parameter.
        if (!hi_slice) hi_slice = findLinkedWideArithSliceList(lo_slice);
        BUG_CHECK(hi_slice, "Unable to find linked hi slice for %1%",
                  cstring::to_cstring(lo_slice));
        wide_slice_lists.push_back(hi_slice);
    }
    ordered_set<const RotationalCluster*> new_clusters_i;
    ordered_set<SliceList*> new_slice_lists;
    for (auto c : clusters_i) { new_clusters_i.insert(c); }
    for (auto *c2 : sc->clusters_i) { new_clusters_i.insert(c2); }
    for (auto sl : wide_slice_lists) { new_slice_lists.insert(sl); }
    for (auto sl : non_wide_slice_lists) { new_slice_lists.insert(sl); }
    return new SuperCluster(new_clusters_i, new_slice_lists);
}

bool PHV::SuperCluster::needToMergeForWideArith(const SuperCluster *sc) const {
    for (auto* list : slice_lists()) {
        for (auto& fs : *list) {
            int lo1 = fs.range().lo;
            if (fs.field()->bit_used_in_wide_arith(lo1)) {
                for (auto* list2 : sc->slice_lists()) {
                    for (auto& fs2 : *list2) {
                        int lo2 = fs2.range().lo;
                        if (lo1 != lo2 && fs.field() == fs2.field()) {
                            if (fs2.field()->bit_used_in_wide_arith(lo2)) {
                                if (((lo1 + 32) == lo2) || (lo2 + 32) == lo1) {
                                    return true; } } } } } } } }
    return false;
}

PHV::SuperCluster::SliceList* PHV::SuperCluster::findLinkedWideArithSliceList(
  const PHV::SuperCluster::SliceList *sl) const {
    // if a particular field slice participates in wide arithmetic,
    // search for its linked SliceList (either hi or lo)
    for (auto &fs : *sl) {
        int slice_lsb = fs.range().lo;
        if (fs.field()->bit_used_in_wide_arith(slice_lsb)) {
            bool lo_slice = false;
            if (fs.field()->bit_is_wide_arith_lo(fs.range().lo))
                lo_slice = true;
            LOG7("Looking for slice list " << sl);
            LOG7("   lo_slice?  " << lo_slice);
            LOG7("   slice_lsb = " << slice_lsb);
            for (auto* list : slice_lists()) {
                for (auto &fs2 : *list) {
                    int slice_lsb2 = fs2.range().lo;
                    LOG7("   Looking for slice list " << list);
                    LOG7("      slice_lsb2 = " << slice_lsb2);
                    if (fs2.field()->bit_used_in_wide_arith(slice_lsb2)) {
                        if (0 == std::strcmp(fs.field()->name, fs2.field()->name)) {
                            if (lo_slice && (slice_lsb + 32) == slice_lsb2)
                                return list;
                            else if (!lo_slice && (slice_lsb - 32) == slice_lsb2)
                                return list;
                        } } } } }
    }
    return nullptr;  // not linked (or not wide arith slice)
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

namespace PHV {

std::ostream &operator<<(std::ostream &out, const PHV::Allocation& alloc) {
    if (dynamic_cast<const PHV::Transaction *>(&alloc)) {
        P4C_UNIMPLEMENTED("<<(PHV::Transaction)");
        return out; }

    AllocationReport report(alloc);
    out << report.printSummary() << std::endl;

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
    out << "SUPERCLUSTER Uid: " << g.uid << std::endl;
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
