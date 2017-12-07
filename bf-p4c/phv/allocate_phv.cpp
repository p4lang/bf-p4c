#include "allocate_phv.h"
#include <boost/format.hpp>
#include <boost/range/adaptor/reversed.hpp>
#include "lib/log.h"

/* static */
std::list<PHV::SuperCluster*> AllocatePHV::split_super_cluster(PHV::SuperCluster* sc) {
    // XXX(cole): This is a heuristic that splits the SuperCluster into the
    // largest container-sized slices.  We'll need to do something more
    // sophisticated in the future.

    // XXX(cole): This heuristic only works on SuperClusters with no slice
    // lists.  To split slice lists, we'll need to replace them with
    // parser/deparser schema.
    LOG5("Trying to slice supercluster with max field slice width of " << sc->max_width() << ":");
    LOG5(sc);

    if (sc->slice_lists().size()) {
        LOG5("    ...but cannot split superclusters with slice lists");
        return { sc }; }

    std::list<PHV::SuperCluster*> rv;
    ordered_set<PHV::RotationalCluster*> to_slice = sc->clusters();
    int remaining_width = sc->max_width();

    while (remaining_width > 0) {
        // If the widest slice is exactly a container size or smaller than 8b,
        // then we're done.  Otherwise, decide the next split size.
        int chunk;
        if (remaining_width < int(PHV::Size::b8)
                || remaining_width == int(PHV::Size::b8)
                || remaining_width == int(PHV::Size::b16)
                || remaining_width == int(PHV::Size::b32)) {
            rv.push_back(new PHV::SuperCluster(to_slice, { }));
            break;
        } else if (remaining_width < int(PHV::Size::b16)) {
            chunk = int(PHV::Size::b8);
        } else if (remaining_width < int(PHV::Size::b32)) {
            chunk = int(PHV::Size::b16);
        } else {
            chunk = int(PHV::Size::b32);
        }

        // Slice each rotational cluster.
        using OptResult = boost::optional<PHV::RotationalCluster::SliceResult>;
        std::vector<OptResult> results;
        for (auto* cluster : to_slice)
            results.push_back(cluster->slice(chunk));

        // If any cluster failed to slice, give up.
        auto IsNone = [](const OptResult& res) { return res == boost::none; };
        if (std::any_of(results.begin(), results.end(), IsNone)) {
            rv.push_back(new PHV::SuperCluster(to_slice, { }));
            break; }

        // Add the lo clusters, which are now container-sized, to the result
        // list, and continue slicing the hi clusters.
        to_slice.clear();
        ordered_set<PHV::RotationalCluster*> container_sized_clusters;
        for (auto& res : results) {
            container_sized_clusters.insert(res->lo);
            to_slice.insert(res->hi); }
        rv.push_back(new PHV::SuperCluster(container_sized_clusters, { }));
        remaining_width -= chunk; }

    if (LOGGING(5) && rv.size() == 1 && rv.front() == sc) {
        LOG5("    ...but supercluster was not split");
    } else if (LOGGING(5)) {
        std::stringstream ss;
        for (auto* cl : rv)
            ss << cl->max_width() << " ";
        LOG5("    ...and produced new superclusters of sizes " << ss.str() << ":");
        for (auto* cl : rv)
            LOG5(cl);
    }

    return rv;
}

/* static */
bool AllocatePHV::can_overlay(
        SymBitMatrix mutex,
        const PHV::Field* f,
        const ordered_set<PHV::AllocSlice>& slices) {
    for (auto slice : slices) {
        if (!PHV::Allocation::mutually_exclusive(mutex, f, slice.field()))
            return false; }
    return true;
}

bitvec AllocatePHV::satisfies_constraints(
        const PHV::ContainerGroup& group, const PHV::AlignedCluster& cluster) const {
    // Check that these containers support the operations required by fields in
    // this cluster.
    if (!cluster.okIn(group.type().kind())) {
        LOG5("    ...but cluster cannot be placed in " << group.type().kind() << "PHV containers");
        return bitvec();
    }

    // Check that a valid start alignment exists for containers of this size.
    auto valid_start_options = cluster.validContainerStart(group.type().size());
    if (!valid_start_options)
        LOG5("    ...but there are no valid starting bit alignments for cluster in containers of "
             "this size");

    return valid_start_options;
}

bool AllocatePHV::satisfies_constraints(
        const PHV::ContainerGroup& group,
        const PHV::Field* f) const {
    // Check that TM deparsed fields aren't split
    if (f->no_split() && int(group.type().size()) < f->size) {
        LOG5("        constraint: can't split field size " << f->size <<
             " across " << group.type().size() << " containers");
        return false; }
    return true;
}

bool AllocatePHV::satisfies_constraints(
        const PHV::ContainerGroup& group,
        const PHV::FieldSlice& slice) const {
    return satisfies_constraints(group, slice.field());
}

bool AllocatePHV::satisfies_constraints(std::vector<PHV::AllocSlice> slices) const {
    // Slices placed together must be placed in the same container.
    auto DifferentContainer = [](const PHV::AllocSlice& left, const PHV::AllocSlice& right) {
            return left.container() != right.container();
        };
    if (std::adjacent_find(slices.begin(), slices.end(), DifferentContainer) != slices.end()) {
        LOG5("        constraint: slices placed together must be placed in the same container: "
             << slices);
        return false; }

    // Check exact containers for deparsed fields
    auto IsDeparsed = [](const PHV::AllocSlice& slice) {
            // XXX(cole): This is a hack to deal with bridged metadata; it
            // should be revisited once bridged metadata is moved to the
            // midend.
            return (slice.field()->deparsed() || slice.field()->exact_containers())
                   && !slice.field()->bridged;
        };
    if (std::any_of(slices.begin(), slices.end(), IsDeparsed)) {
        // Reject mixes of deparsed/not deparsed fields.
        if (!std::all_of(slices.begin(), slices.end(), IsDeparsed)) {
            LOG5("        constraint: mix of deparsed/not deparsed fields cannot be placed "
                 "together:" << slices);
            return false; }

        // Calculate total size of slices.
        int aggregate_size = 0;
        int container_size = 0;
        for (auto& slice : slices) {
            aggregate_size += slice.width();
            container_size = int(slice.container().size()); }

        // Reject slices that cannot fit in the container.
        if (container_size < aggregate_size) {
            LOG5("        constraint: slices placed together are " << aggregate_size <<
                 "b wide and cannot fit in an " << container_size <<
                 "b container");
            return false; }

        // Reject slices that do not totally fill the container.
        if (container_size > aggregate_size) {
            LOG5("        constraint: deparsed slices placed together are " << aggregate_size <<
                 "b wide but do not completely fill an " << container_size <<
                 "b container");
            return false; } }

    // Check if any fields have the no_pack constraint, which is mutually
    // unsatisfiable with slice lists, which induce packing.
    std::vector<PHV::AllocSlice> used;
    for (auto& slice : slices)
        if ((uses_i.is_deparsed(slice.field()) || uses_i.is_used_mau(slice.field()))
                && !clot_i.allocated(slice.field())) {
            used.push_back(slice); }
    if (used.size() > 1) {
        for (auto& slice : used) {
            if (slice.field()->no_pack()) {
                std::stringstream ss;
                for (auto& s : used)
                    ss << "    " << s.field() << std::endl;
                // XXX(cole): Is there a way to immediate abort compilation?
                // Otherwise this error is produced for every slice
                // list/container group pair.
                ::error("Field %1% must be "
                        "placed alone in a PHV container, but the parser must pack it "
                        "contiguously with its adjacent slices.  This is unsatisfiable.  The "
                        "list of adjacent slices is:\n%2%", cstring::to_cstring(slice.field()),
                        ss.str());
                return false; } } }

    return true;
}

bool AllocatePHV::satisfies_constraints(
        const PHV::Allocation& alloc,
        PHV::AllocSlice slice) const {
    PHV::Field* f = slice.field();
    PHV::Container c = slice.container();

    // Check gress.
    if (alloc.gress(c) && *alloc.gress(c) != f->gress) {
        LOG5("        constraint: container is " << *alloc.gress(c) <<
                    " but slice needs " << f->gress);
        return false; }

    // Check no pack for this field.
    const auto& slices = alloc.slices(c);
    if (slices.size() > 0 && slice.field()->no_pack()) {
        LOG5("        constraint: slice has no_pack constraint but container has slices " <<
                      slices);
        return false; }

    // Check no pack for any other fields already in the container.
    for (auto& slice : slices) {
        if (slice.field()->no_pack()) {
            LOG5("        constraint: field " << slice.field() << " has no_pack constraint and is "
                         "already placed in this container");
            return false; } }

    return true;
}

/* static */
bool AllocatePHV::satisfies_CCGF_constraints(
        const PHV::Allocation& alloc,
        const PHV::Field *f, PHV::Container c) {
    if (alloc.gress(c) && *alloc.gress(c) != f->gress)
        return false;
    return true;
}

/* static */
bool AllocatePHV::satisfies_constraints(const PHV::ContainerGroup& g, const PHV::SuperCluster& sc) {
    if (int(g.type().size()) < sc.max_width())
        return false;

    return true;
}

boost::optional<PHV::Transaction> AllocatePHV::tryAllocCCGF(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        PHV::Field* f,
        int start) {
    if (!f->is_ccgf())
        return boost::none;
    LOG5("    ...and field is a CCGF");

    PHV::Transaction alloc_attempt = alloc.makeTransaction();
    int container_size = int(group.type().size());
    int ccgf_size = 0;

    // Calculate CCGF size
    for (auto* member : f->ccgf_fields_i)
        ccgf_size += member->size;
    if (f->header_stack_pov_ccgf())
        ccgf_size++;

    if (container_size < ccgf_size + start) {
        LOG4("    ...but CCGF is " << ccgf_size << "b, which is too big for an " <<
             container_size << "b container starting at bit " << start);
        return boost::none;
    } else if (f->exact_containers() && container_size != ccgf_size) {
        // XXX(cole): This is a hack to deal with the fact that CCGFs have special
        // constraints right now, eg. all the fields might be "exact_containers",
        // but that really means the whole CCGF must be placed in exact containers.
        LOG4("    ...but a CCGF has " << ccgf_size << " bits total and requires an exact "
             "container");
        return boost::none;
    }

    // For each container, check if it satisfies the constraints on each CCGF
    // member.  If so, allocate the whole CCGF to it.
    boost::optional<PHV::Container> candidate = boost::none;
    for (const PHV::Container c : group) {
        // XXX(cole): This assumes that CCGF fields can be allocated
        // together and the constraints have already been checked, but this
        // should really check CCGF/container or even member/container
        // constraints, if there are such constraints.
        if (!satisfies_CCGF_constraints(alloc_attempt, f, c)) {
            LOG5("    ...but CCGF constraints not met");
            continue; }

        bool container_empty = alloc_attempt.slices(c).size() == 0;
        if (can_overlay(mutex_i, f, alloc_attempt.slices(c)) && !container_empty) {
            LOG5("    ...and can overlay" << alloc_attempt.slices(c));
            candidate = c;
            break;
        } else if (container_empty) {
            LOG5("    ...and container is empty");
            candidate = c;
        } else {
            LOG5("    ...but " << c << " already contains " << alloc_attempt.slices(c)); } }

    if (!candidate) {
        LOG5("    ...but there is no free container for (non-special) CCGF field");
        return boost::none; }

    // Create an aligned slice for each CCGF member and allocate it to the
    // candidate container.
    int offset = start;

    // If f is a header stack CCGF, then allocate .stkvalid at `start` and
    // increment the offset by 1.  The CCGF members (which do not include
    // .stkvalid) will be overlaid atop .stkvalid[1:end].
    if (f->header_stack_pov_ccgf()) {
        alloc_attempt.allocate(
            PHV::AllocSlice(f, *candidate,
                            StartLen(0, f->size),         // field range
                            StartLen(offset, f->size)));  // container range
        offset++; }

    // Walk CCGF and make an AllocSlice for each field in the CCGF, taking care
    // to iterate in reverse.
    for (auto* member : boost::adaptors::reverse(f->ccgf_fields_i)) {
        BUG_CHECK(offset + member->size <= container_size,
            "When allocating CCGF of size %1% with owner %2% to a container of size %3%, "
            "ran out of container space when allocating field %4% of size %5% at offset %6%.",
            ccgf_size, cstring::to_cstring(f), container_size, cstring::to_cstring(member),
            member->size, offset);

        // Only allocate referenced fields.
        if (uses_i.is_referenced(member) && !clot_i.allocated(member)) {
            LOG5("    ...attempt allocating CCGF member at offset " << offset << ": " << member);
            alloc_attempt.allocate(
                PHV::AllocSlice(member, *candidate,
                                StartLen(0, member->size),            // field range
                                StartLen(offset, member->size))); }   // container range

        // Increment the offset regardless of whether this member was
        // allocated or skipped, in order to preserve the alignment of its
        // adjecent members.
        offset += member->size; }

    return alloc_attempt;
}

// FIELD LIST <--> CONTAINER GROUP allocation.
boost::optional<PHV::Transaction> AllocatePHV::tryAlloc(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const std::vector<PHV::FieldSlice>& slices,
        const ordered_map<const PHV::FieldSlice, int>& start_positions) {
    LOG4("trying to allocate slices at container indices: ");
    for (auto& slice : slices) {
        BUG_CHECK(start_positions.find(slice) != start_positions.end(),
                  "Trying to place slice list with no container index for slice %1%",
                  cstring::to_cstring(slice));
        LOG4("  " << start_positions.at(slice) << ": " << slice); }

    // Check FIELD<-->GROUP constraints for each field.
    for (auto& slice : slices) {
        if (!satisfies_constraints(group, slice)) {
            LOG5("    ...but slice " << slice << " doesn't satisfy slice<-->group constraints");
            return boost::none; } }

    PHV::Transaction alloc_attempt = alloc.makeTransaction();
    int container_size = int(group.type().size());

    // XXX(cole): If the list is entirely comprised of a CCGF, allocate it.
    if (slices.size() == 1 && slices[0].field()->is_ccgf())
        return tryAllocCCGF(alloc, group, slices[0].field(), start_positions.at(slices[0]));

    // XXX(cole): Otherwise, fail (for now) if a slice list contains a CCGF
    // owner or member.
    for (auto& slice : slices) {
        if (slice.field()->is_ccgf() || slice.field()->ccgf() != nullptr) {
            LOG5("    ...but slice list contains a CCGF field " << slice);
            return boost::none; } }

    // Return if the slices can't fit together in a container.
    int aggregate_size = 0;
    for (auto& slice : slices)
        aggregate_size += slice.size();
    if (container_size < aggregate_size) {
        LOG5("    ...but these slices are " << aggregate_size << "b in total and cannot fit in a "
             << container_size << "b container");
        return boost::none; }

    // Look for a container to allocate all slices in.
    boost::optional<std::vector<PHV::AllocSlice>> candidate = boost::none;
    int max_overlays = 0;
    for (const PHV::Container c : group) {
        std::vector<PHV::AllocSlice> alloc_slices;
        for (auto& field_slice : slices) {
            le_bitrange container_slice =
                StartLen(start_positions.at(field_slice), field_slice.size());
            alloc_slices.push_back(PHV::AllocSlice(field_slice, c, container_slice)); }

        // Check slice list<-->container constraints.
        if (!satisfies_constraints(alloc_slices))
            continue;

        // Check that each field slice satisfies slice<-->container constraints.
        bool constraints_ok =
            std::all_of(alloc_slices.begin(), alloc_slices.end(),
                        [&](const PHV::AllocSlice& slice) {
                            return satisfies_constraints(alloc_attempt, slice); });
        if (!constraints_ok)
            continue;

        // Check that there's space.
        bool can_place = true;
        int num_overlays = 0;
        for (auto& slice : alloc_slices) {
            const auto& alloced_slices =
                alloc_attempt.slices(slice.container(), slice.container_slice());
            if (alloced_slices.size() > 0 && can_overlay(mutex_i, slice.field(), alloced_slices)) {
                num_overlays++;
            } else if (alloced_slices.size() > 0) {
                LOG5("    ...but " << c << " already contains " << alloced_slices);
                can_place = false;
                break; } }
        if (can_place && (!candidate || num_overlays > max_overlays)) {
            candidate = alloc_slices;
            max_overlays = num_overlays; } }

    if (!candidate) {
        LOG5("    ...hence there is no suitable candidate");
        return boost::none; }

    for (auto& slice : *candidate) {
        // XXX(cole): This ignores the no deadcode elimination compiler flag!
        // It should be fixed when parser/deparser schema are introduced.
        if (uses_i.is_referenced(slice.field()) && !clot_i.allocated(slice.field()))
            alloc_attempt.allocate(slice); }
    return alloc_attempt;
}

// SUPERCLUSTER <--> CONTAINER GROUP allocation.
boost::optional<PHV::Transaction> AllocatePHV::tryAlloc(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& container_group,
        PHV::SuperCluster& super_cluster) {
    // Check container group/cluster group constraints.
    if (!satisfies_constraints(container_group, super_cluster))
        return boost::none;

    // Make a new transaction.
    PHV::Transaction alloc_attempt = alloc.makeTransaction();

    // Try to allocate slice lists together, storing the offsets required of each
    // slice's cluster.
    ordered_map<const PHV::AlignedCluster*, int> cluster_alignment;
    ordered_set<PHV::FieldSlice> allocated;
    for (const PHV::SuperCluster::SliceList* slice_list : super_cluster.slice_lists()) {
        int le_offset = 0;
        ordered_map<const PHV::FieldSlice, int> slice_alignment;
        for (auto& slice : *slice_list) {
            const PHV::AlignedCluster& cluster = super_cluster.aligned_cluster(slice);
            auto valid_start_options = satisfies_constraints(container_group, cluster);
            if (valid_start_options.empty())
                return boost::none;

            // If this is the first slice, then its starting alignment can be adjusted.
            if (le_offset == 0)
                le_offset = *valid_start_options.min();

            // Return if the slice 's cluster cannot be placed at the current
            // starting offset.
            if (!valid_start_options.getbit(le_offset)) {
                LOG5("    ...but slice list requires slice to start at " << le_offset <<
                     " which its cluster cannot support");
                return boost::none; }

            // Return if the slice is part of another slice list but was previously
            // placed at a different start location.
            // XXX(cole): We may need to be smarter about coordinating all
            // valid starting ranges for all slice lists.
            if (cluster_alignment.find(&cluster) != cluster_alignment.end() &&
                    cluster_alignment.at(&cluster) != le_offset) {
                LOG5("    ...but two slice lists have conflicting alignment requirements for "
                     "field slice %1%" << slice);
                return boost::none; }

            // Otherwise, update the alignment for this slice's cluster.
            cluster_alignment[&cluster] = le_offset;
            slice_alignment[slice] = le_offset;
            le_offset += slice.size(); }

        // Try allocating the slice list.
        auto partial_alloc =
            tryAlloc(alloc_attempt, container_group, *slice_list, slice_alignment);
        if (!partial_alloc)
            return boost::none;
        alloc_attempt.commit(*partial_alloc);

        // Track allocated slices in order to skip them when allocating their clusters.
        for (auto& slice : *slice_list)
            allocated.insert(slice); }

    // After allocating each slice list, use the alignment for each slice in
    // each list to place its cluster.
    for (auto* rotational_cluster : super_cluster.clusters()) {
        for (auto* cluster : rotational_cluster->clusters()) {
            for (const PHV::FieldSlice& slice : cluster->slices()) {
                // Skip fields that have already been allocated above.
                if (allocated.find(slice) != allocated.end())
                    continue;

                int start = 0;
                if (cluster_alignment.find(cluster) != cluster_alignment.end()) {
                    start = cluster_alignment.at(cluster);
                } else {
                    auto valid_start_options = satisfies_constraints(container_group, *cluster);
                    if (valid_start_options.empty())
                        return boost::none;
                    start = *valid_start_options.min();
                }

                ordered_map<const PHV::FieldSlice, int> start_map = { { slice, start } };
                auto partial_alloc = tryAlloc(alloc_attempt, container_group, {slice}, start_map);
                if (partial_alloc)
                    alloc_attempt.commit(*partial_alloc);
                else
                    return boost::none; } } }

    return alloc_attempt;
}


/* static */
void AllocatePHV::makeAllocationStrategy(
        const PHV::Allocation& alloc,
        std::list<PHV::SuperCluster*>& cluster_groups,
        std::list<PHV::ContainerGroup*>& container_groups) {
    /* Waterfall allocation ordering:
     *
     *  - PHV clusters > 4 bits  --> PHV                (smallest to largest)
     *  - TPHV fields  > 4 bits  --> TPHV               (smallest to largest)
     *  - TPHV fields  > 4 bits  --> PHV                (smallest to largest)
     *  - POV fields             --> PHV
     *  - PHV fields  <= 4 bits  --> PHV
     *  - TPHV fields <= 4 bits  --> TPHV
     *  - TPHV fields <= 4 bits  --> PHV
     */

    // Sorts clusters by whether any field has the exact_containers
    // requirement, then by the number of constraints, then number of
    // containers required, then by width.
    auto ClusterGroupComparator = [](PHV::SuperCluster* l, PHV::SuperCluster* r) {
        if (l->exact_containers() && !r->exact_containers())
            return true;
        if (!l->exact_containers() && r->exact_containers())
            return false;

        // If both clusters require exact containers, try the NARROWER cluster
        // first.
        if (l->exact_containers() && r->exact_containers()) {
            if (l->max_width() != r->max_width())
                return l->max_width() < r->max_width();
            if (l->num_constraints() != r->num_constraints())
                return l->num_constraints() > r->num_constraints();

            // XXX(cole): Aggregate size may give preference to large clusters
            // that, despite their size, fit into fewer containers.
            return l->aggregate_size() > r->aggregate_size(); }

        // Otherwise, try the wider cluster first.
        if (l->num_constraints() != r->num_constraints())
            return l->num_constraints() > r->num_constraints();
        if (l->aggregate_size() != r->aggregate_size())
            return l->aggregate_size() > r->aggregate_size();
        return l->max_width() > r->max_width(); };

    cluster_groups.sort(ClusterGroupComparator);

    // Sorts groups by capability (TPHV, then PHV), then by gress (INGRESS,
    // EGRESS, either), and then by size (smallest to largest).
    auto ContainerGroupComparator = [&](PHV::ContainerGroup* l, PHV::ContainerGroup* r) {
        if (l->type().kind() != r->type().kind())
            return l->type().kind() == PHV::Kind::tagalong;

        // Count pinned gress.
        ordered_map<const PHV::ContainerGroup*, int> count;
        for (auto* group : { l, r }) {
            for (auto& c : *group) {
                if (auto gress = alloc.gress(c)) {
                    count[group]++; } } }

        if (count[l] != count[r])
            return count[l] < count[r];

        return int(l->type().size()) < int(r->type().size()); };

    container_groups.sort(ContainerGroupComparator);
}

/* static */
std::list<PHV::ContainerGroup *> AllocatePHV::makeDeviceContainerGroups() {
    const PhvSpec& phvSpec = Device::phvSpec();
    std::list<PHV::ContainerGroup *> rv;

    // Build MAU groups
    for (const PHV::Type t : phvSpec.containerTypes()) {
        for (auto group : phvSpec.mauGroups(t)) {
            // Get type of group
            if (group.empty())
                continue;
            // Create group
            rv.emplace_back(new PHV::ContainerGroup(t, group)); } }

    // Build TPHV collections
    for (auto collection : phvSpec.tagalongGroups()) {
        // Each PHV_MAU_Group holds containers of the same size.  Hence, TPHV
        // collections are split into three groups, by size.
        ordered_map<PHV::Type, bitvec> groups_by_type;

        // Add containers to groups by size
        for (auto cid : collection) {
            auto type = phvSpec.idToContainer(cid).type();
            groups_by_type[type].setbit(cid); }

        for (auto kv : groups_by_type)
            rv.emplace_back(new PHV::ContainerGroup(kv.first, kv.second)); }

    return rv;
}

void AllocatePHV::clearSlices(PhvInfo& phv) {
    phv.clear_container_to_fields();
    for (auto& f : phv) {
        f.alloc_i.clear();
        // ccgf members, if any
        for (auto* m : f.ccgf_fields())
            m->alloc_i.clear(); }
}

/* static */
void AllocatePHV::bindSlices(const PHV::ConcreteAllocation& alloc, PhvInfo& phv) {
    // Translate AllocSlice to alloc_slice, and attach alloc_slice to
    // PHV::Field.
    for (auto container_and_slices : alloc) {
        for (PHV::AllocSlice slice : container_and_slices.second.slices) {
            auto* f = slice.field();
            f->alloc_i.emplace_back(
                slice.field(),
                slice.container(),
                slice.field_slice().lo,
                slice.container_slice().lo,
                slice.field_slice().size());
            phv.add_container_to_field_entry(slice.container(), f); } }

    // later passes assume that phv alloc info is sorted in field bit order,
    // msb first
    for (auto& f : phv) {
        std::sort(f.alloc_i.begin(), f.alloc_i.end(),
            [](PHV::Field::alloc_slice l, PHV::Field::alloc_slice r) {
                return l.field_bit > r.field_bit; }); }
}

/* static */
void AllocatePHV::formatAndThrowError(
        const PHV::Allocation& alloc,
        const std::list<PHV::SuperCluster *>& unallocated) {
    int unallocated_bits = 0;
    int ingress_phv_bits = 0;
    int egress_phv_bits = 0;
    int ingress_t_phv_bits = 0;
    int egress_t_phv_bits = 0;
    std::stringstream msg;

    msg << "PHV allocation was not successful "
        << "(" << unallocated.size() << " cluster groups remaining)" << std::endl;

    if (LOGGING(5)) {
        msg << "Fields successfully allocated: " << std::endl;
        msg << alloc << std::endl; }

    for (auto* super_cluster : unallocated) {
        msg << "---" << std::endl;
        for (auto* rotational_cluster : super_cluster->clusters()) {
            for (auto* cluster : rotational_cluster->clusters()) {
                for (auto& slice : cluster->slices()) {
                    // XXX(cole): Need to update this for JBay.
                    bool can_be_tphv = cluster->okIn(PHV::Kind::tagalong);
                    cstring s = can_be_tphv ? "tphv" : "phv";
                    msg << "    " <<
                        (LOGGING(3) ? (cstring::to_cstring(slice)+" --"+s) : slice.field()->name)
                        << std::endl;
                    unallocated_bits += slice.size();
                    if (slice.gress() == INGRESS) {
                        if (!can_be_tphv)
                            ingress_phv_bits += slice.size();
                        else
                            ingress_t_phv_bits += slice.size();
                    } else {
                        if (!can_be_tphv)
                            egress_phv_bits += slice.size();
                        else
                            egress_t_phv_bits += slice.size(); } } } } }

    if (LOGGING(3)) {
        msg << std::endl
            << "..........Unallocated bits = " << unallocated_bits << std::endl;
        msg << "..........ingress phv bits = " << ingress_phv_bits << std::endl;
        msg << "..........egress phv bits = " << egress_phv_bits << std::endl;
        msg << "..........ingress t_phv bits = " << ingress_t_phv_bits << std::endl;
        msg << "..........egress t_phv bits = " << egress_t_phv_bits << std::endl;
        msg << std::endl; }

    msg << alloc.getSummary() << std::endl;

    ::error("%1%", msg.str());
}

void AllocatePHV::end_apply() {
    LOG1("--- BEGIN PHV ALLOCATION ----------------------------------------------------");

    // Split SuperClusters that don't have slice lists along container
    // boundaries, preferring the largest container size possible.
    std::list<PHV::SuperCluster*> cluster_groups;
    for (auto* sc : clustering_i.cluster_groups())
        for (auto* new_sc : AllocatePHV::split_super_cluster(sc))
            cluster_groups.push_back(new_sc);

    auto alloc = PHV::ConcreteAllocation(mutex_i);
    auto container_groups = AllocatePHV::makeDeviceContainerGroups();
    AllocatePHV::makeAllocationStrategy(alloc, cluster_groups, container_groups);

    // For each cluster, try assigning to each group (in order) until
    // successful or no groups remain.
    std::list<PHV::SuperCluster*> to_remove;
    for (PHV::SuperCluster* cluster_group : cluster_groups) {
        for (PHV::ContainerGroup* container_group : container_groups) {
            LOG4("TRY CLUSTER/GROUP pair:");
            LOG4(cluster_group);
            LOG4(container_group);
            if (auto partial_alloc = tryAlloc(alloc, *container_group, *cluster_group)) {
                alloc.commit(*partial_alloc);
                to_remove.push_back(cluster_group);
                LOG5("    this cluster/group allocation SUCCESSFUL");
                break; } } }

    // XXX(cole): There must be a better way to remove elements from a list
    // while iterating, but `it = clusters_i.erase(it)` skips elements.
    for (auto cluster_group : to_remove)
        cluster_groups.remove(cluster_group);

    // If allocation was unsuccessful, pretty-print a helpful error message.
    if (cluster_groups.size() > 0) {
        formatAndThrowError(alloc, cluster_groups);
        return; }

    // Translate this allocation to PHV::Field::alloc_slice, which the rest of
    // the compiler uses as the output of PHV allocation.
    AllocatePHV::clearSlices(phv_i);
    AllocatePHV::bindSlices(alloc, phv_i);
    phv_i.set_done();

    LOG5("ALLOCATION SUCCESSFUL:");
    LOG5(alloc);
}
