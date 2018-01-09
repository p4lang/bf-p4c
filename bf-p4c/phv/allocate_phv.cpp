#include "allocate_phv.h"
#include <boost/format.hpp>
#include <boost/range/adaptor/reversed.hpp>
#include <numeric>
#include "lib/log.h"

using ContainerAllocStatus = PHV::Allocation::ContainerAllocStatus;

/** Metrics are prioritized by
 * 1. is_tphv.
 * 2. n_wasted_bits, to avoid no_pack slice allocated to large containers.
 * 3. n_packing_bits
 * 4. n_overlay_bits
 * 5. use new container.
 * 6. set gress.
 */
bool AllocScore::operator>(const AllocScore& other) {
    if (is_tphv && !other.is_tphv) return true;
    if (!is_tphv && other.is_tphv) return false;
    if (n_wasted_bits != other.n_wasted_bits) {
        return n_wasted_bits < other.n_wasted_bits; }
    if (n_packing_bits != other.n_packing_bits) {
        return n_packing_bits > other.n_packing_bits; }
    if (n_overlay_bits != other.n_overlay_bits) {
        return n_overlay_bits > other.n_overlay_bits; }
    if (n_inc_containers != other.n_inc_containers) {
        return n_inc_containers < other.n_inc_containers; }
    if (n_set_gress != other.n_set_gress) {
        return n_set_gress < other.n_set_gress; }
    return false;
}

// static
AllocScore AllocScore::make_lowest() {
    return AllocScore();
}

/** The metrics are calculated:
 * + is_tphv: type of @p group.
 * + n_set_gress:
 *     number of containers which set their gress
 *     to ingress/egress from boost::none.
 * + n_overlay_bits: container bits already used in parent alloc get overlaid.
 * + n_packing_bits: use bits that ContainerAllocStatus is PARTIAL in parent.
 * + n_inc_containers: the number of container used that was EMPTY.
 * + n_wasted_bits: if field is no_pack, container.size() - slice.width().
 */
AllocScore::AllocScore(
    const PHV::Transaction& alloc,
    const PHV::ContainerGroup& group) : AllocScore() {
    // tagalong
    if (group.is(PHV::Kind::tagalong)) is_tphv = true;

    const auto& parent = alloc.getParent();
    // Forall allocated slices group by container.
    for (const auto kv : alloc.getTransactionStatus()) {
        const auto& container = kv.first;
        const auto& gress = kv.second.gress;
        const auto& slices = kv.second.slices;
        bitvec parent_alloc_vec = calcContainerAllocVec(parent.slices(container));

        // skip, if there is no allocated slices.
        if (slices.size() == 0) {
            continue; }

        // calc n_wasted_bits
        for (const auto& slice : slices) {
            if (slice.field()->no_pack()) {
                n_wasted_bits += (container.size() - slice.width()); } }

        // calc_n_inc_containers
        ContainerAllocStatus merged_status =
                calcContainerStatus(container, alloc.slices(container));
        ContainerAllocStatus parent_status =
                calcContainerStatus(container, parent.slices(container));
        if (parent_status == ContainerAllocStatus::EMPTY
            && merged_status != ContainerAllocStatus::EMPTY) {
            n_inc_containers++; }

        // calc n_packing_bits
        if (parent_status == ContainerAllocStatus::PARTIAL) {
            for (auto i = container.lsb(); i <= container.msb(); ++i) {
                if (parent_alloc_vec[i]) continue;
                for (const auto& slice : slices) {
                    if (slice.container_slice().contains(i)) {
                        n_packing_bits++;
                        break; }
                } } }

        // calc n_overlay_bits
        for (const int i : parent_alloc_vec) {
            for (const auto slice : slices) {
                if (slice.container_slice().contains(i)) {
                    n_overlay_bits++; } } }

        // gress
        if (!parent.gress(container) && gress) {
            n_set_gress++; }
    }
}

bitvec
AllocScore::calcContainerAllocVec(const ordered_set<PHV::AllocSlice>& slices) {
    bitvec allocatedBits;
    for (auto slice : slices) {
        allocatedBits |= bitvec(slice.container_slice().lo,
                                slice.container_slice().size()); }
    return allocatedBits;
}

ContainerAllocStatus
AllocScore::calcContainerStatus(const PHV::Container& container,
                                const ordered_set<PHV::AllocSlice>& slices) {
    bitvec allocatedBits = calcContainerAllocVec(slices);
    if (allocatedBits == bitvec(0, container.size()))
        return ContainerAllocStatus::FULL;
    else if (!allocatedBits.empty())
        return ContainerAllocStatus::PARTIAL;
    else
        return ContainerAllocStatus::EMPTY;
}

std::ostream& operator<<(std::ostream& s, const AllocScore& score) {
    s << "[";
    s << "tphv: " << score.is_tphv << ", ";
    s << "set_gress: " << score.n_set_gress << ", ";
    s << "overlay_bits: " << score.n_overlay_bits << ", ";
    s << "packing_bits: " << score.n_packing_bits << ", ";
    s << "inc_containers: " << score.n_inc_containers << ", ";
    s << "]";
    return s;
}

/* static */
bool CoreAllocation::can_overlay(
        SymBitMatrix mutex,
        const PHV::Field* f,
        const ordered_set<PHV::AllocSlice>& slices) {
    for (auto slice : slices) {
        if (!PHV::Allocation::mutually_exclusive(mutex, f, slice.field()))
            return false; }
    return true;
}

boost::optional<bitvec> CoreAllocation::satisfies_constraints(
        const PHV::ContainerGroup& group, const PHV::AlignedCluster& cluster) const {
    // Check that these containers support the operations required by fields in
    // this cluster.
    if (!cluster.okIn(group.type().kind())) {
        LOG5("    ...but cluster cannot be placed in " << group.type().kind() << "PHV containers");
        return boost::none; }

    // Check that a valid start alignment exists for containers of this size.
    // An empty bitvec indicates no valid starting positions.
    return cluster.validContainerStart(group.type().size());
}

bool CoreAllocation::satisfies_constraints(
        const PHV::ContainerGroup& group,
        const PHV::Field* f) const {
    // Check that TM deparsed fields aren't split
    if (f->no_split() && int(group.type().size()) < f->size) {
        LOG5("        constraint: can't split field size " << f->size <<
             " across " << group.type().size() << " containers");
        return false; }
    return true;
}

bool CoreAllocation::satisfies_constraints(
        const PHV::ContainerGroup& group,
        const PHV::FieldSlice& slice) const {
    auto req = pa_container_sizes_i.field_slice_req(slice);
    if (req && !group.is(*req)) {
        LOG5("        constraint: @pa_container_size mark that: "
             << slice << " must go to " << *req << " container "); }
    return satisfies_constraints(group, slice.field());
}

bool CoreAllocation::satisfies_constraints(std::vector<PHV::AllocSlice> slices) const {
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
    // unsatisfiable with slice lists, which induce packing.  Ignore adjacent slices of the same
    // field.
    std::vector<PHV::AllocSlice> used;
    for (auto& slice : slices)
        if ((uses_i.is_deparsed(slice.field()) || uses_i.is_used_mau(slice.field()))
                && !clot_i.allocated(slice.field())) {
            used.push_back(slice); }
    auto NotAdjacent = [](const PHV::AllocSlice& left, const PHV::AllocSlice& right) {
            return left.field() != right.field() ||
                   left.field_slice().hi + 1 != right.field_slice().lo ||
                   left.container_slice().hi + 1 != right.container_slice().lo;
        };
    auto NoPack = [](const PHV::AllocSlice& s) { return s.field()->no_pack(); };
    bool not_adjacent = std::adjacent_find(used.begin(), used.end(), NotAdjacent) != used.end();
    bool no_pack = std::find_if(used.begin(), used.end(), NoPack) != used.end();
    if (not_adjacent && no_pack) {
        LOG5("    ...but slice list contains multiple fields and one has the 'no pack' constraint");
        return false; }

    return true;
}

bool CoreAllocation::satisfies_constraints(
        const PHV::Allocation& alloc,
        PHV::AllocSlice slice) const {
    const PHV::Field* f = slice.field();
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

    // Check action analysis induced constraints if multiple slices are to be packed in the same
    // container.
    if (slices.size() > 0) {
        boost::optional<UnionFind<PHV::FieldSlice>> rv = actions_i.can_pack(alloc, slice);
        if (!rv) {
            LOG5("        ...action constraint: cannot pack into container " << c);
            return false;
        } else {
            LOG5("        ...action constraint: can pack into container " << c); } }

    return true;
}

/* static */
bool CoreAllocation::satisfies_CCGF_constraints(
        const PHV::Allocation& alloc,
        const PHV::Field *f, PHV::Container c) {
    if (alloc.gress(c) && *alloc.gress(c) != f->gress) {
        LOG5("    ...but CCGF gress does not match container gress");
        return false; }
    return true;
}

/* static */
bool
CoreAllocation::satisfies_constraints(const PHV::ContainerGroup& g, const PHV::SuperCluster& sc) {
    // Check max individual field width.
    if (int(g.type().size()) < sc.max_width()) {
        LOG5("    ...but container size " << g.type().size() <<
             " is too small for max field width " << sc.max_width());
        return false; }

    // Check max slice list width.
    for (auto* slice_list : sc.slice_lists()) {
        int size = 0;
        for (auto& slice : *slice_list)
            size += slice.size();
        if (int(g.type().size()) < size) {
            LOG5("    ...but container size " << g.type().size() <<
                 " is too small for slice list width " << size);
            return false; } }

    return true;
}

boost::optional<PHV::Transaction> CoreAllocation::tryAllocCCGF(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        PHV::Field* f,
        int start) const {
    if (!f->is_ccgf())
        return boost::none;
    LOG5("    ...and field is a CCGF");

    BUG_CHECK(f->header_stack_pov_ccgf(), "CCGF is not a header stack POV CCGF: %1%",
              cstring::to_cstring(f));

    PHV::Transaction alloc_attempt = alloc.makeTransaction();
    int container_size = int(group.type().size());
    int ccgf_size = 0;

    // Calculate CCGF size
    for (auto* member : f->ccgf_fields_i)
        ccgf_size += member->size;

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

    // Allocate the $stkvalid field, which overlays the CCGF member fields.
    auto stkvalid = PHV::AllocSlice(f, *candidate, StartLen(0, f->size), StartLen(start, f->size));
    alloc_attempt.allocate(stkvalid);

    return alloc_attempt;
}

// FIELDSLICE LIST <--> CONTAINER GROUP allocation.
// This function generally is used under two cases:
// 1. Allocating the slice list of a super_cluster.
// 2. Allocating a single field.
// For the both cases, @p start_positions are valid starting positions of slices.
// The sub-problem here, is to find the best container for this SliceList that
// 1. It is valid.
// 2. Try to maximize overlays. (in terms of the number of overlays).
// 3. If same n_overlay, try to maximize packing,
//    in terms of choosing the container with least free room).
boost::optional<PHV::Transaction>
CoreAllocation::tryAllocSliceList(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const PHV::SuperCluster::SliceList& slices,
        const ordered_map<const PHV::FieldSlice, int>& start_positions) const {
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
    bool all_ccgf = std::all_of(slices.begin(), slices.end(),
                        [](const PHV::FieldSlice& s) { return s.field()->is_ccgf(); });
    if (all_ccgf && slices.size() > 0) {
        boost::optional<PHV::FieldSlice> acc = boost::none;
        boost::optional<int> min_start_pos = boost::none;
        for (auto& slice : slices) {
            if (!acc) {
                acc = slice;
                min_start_pos = start_positions.at(slice);
                continue; }
            if (slice.field() != acc->field()) {
                LOG5("    ...but slice list contains CCGF slices of different fields");
                return boost::none; }
            min_start_pos = std::min(*min_start_pos, start_positions.at(slice)); }
        PHV::Field* acc_field = phv_i.field(acc->field()->id);
        auto rst = tryAllocCCGF(alloc, group, acc_field, *min_start_pos);
        if (!rst) return boost::none;
        return *rst; }

    // XXX(cole): fail (for now) if a slice list contains a CCGF
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
    AllocScore best_score = AllocScore::make_lowest();
    boost::optional<std::vector<PHV::AllocSlice>> best_candidate = boost::none;
    for (const PHV::Container c : group) {
        std::vector<PHV::AllocSlice> candidate_slices;

        // Generate candidate_slices if we choose this container.
        for (auto& field_slice : slices) {
            le_bitrange container_slice =
                StartLen(start_positions.at(field_slice), field_slice.size());
            // Field slice has a const Field*, so get the non-const version using the PhvInfo object
            candidate_slices.push_back(PHV::AllocSlice(phv_i.field(field_slice.field()->id),
                        c, field_slice.range(), container_slice)); }

        // Check slice list<-->container constraints.
        if (!satisfies_constraints(candidate_slices))
            continue;

        // Check that each field slice satisfies slice<-->container constraints.
        bool constraints_ok =
            std::all_of(candidate_slices.begin(), candidate_slices.end(),
                        [&](const PHV::AllocSlice& slice) {
                            return satisfies_constraints(alloc_attempt, slice); });
        if (!constraints_ok)
            continue;

        // In case there are multiple members in alloc_slices, need to check how their packing is
        // affected by action induced constraints
        if (candidate_slices.size() > 1) {
            boost::optional<UnionFind<PHV::FieldSlice>> rv = actions_i.can_pack(alloc_attempt,
                    candidate_slices);
            if (!rv) {
                LOG5("        ...action constraint: cannot pack into container " << c);
                continue;
            } else {
                LOG5("        ...action constraint: can pack into container " << c); } }

        // Check that there's space.
        bool can_place = true;
        for (auto& slice : candidate_slices) {
            const auto& alloced_slices =
                alloc_attempt.slices(slice.container(), slice.container_slice());
            if (alloced_slices.size() > 0 && can_overlay(mutex_i, slice.field(), alloced_slices)) {
                LOG5("    ...and can overlay " << slice.field() << " on " << alloced_slices);
            } else if (alloced_slices.size() > 0) {
                LOG5("    ...but " << c << " already contains " << alloced_slices);
                can_place = false;
                break; } }
        if (!can_place) continue;  // try next container

        // Create a temporary alloc for calculating score.
        auto this_alloc = alloc_attempt.makeTransaction();
        for (auto& slice : candidate_slices) {
            if (uses_i.is_referenced(slice.field())
                && !clot_i.allocated(slice.field()))
            this_alloc.allocate(slice); }

        auto score = AllocScore(this_alloc, group);
        // update the best
        if ((!best_candidate || score > best_score)) {
            best_score = score;
            best_candidate = candidate_slices; }
    }  // end of for containers

    if (!best_candidate) {
        LOG5("    ...hence there is no suitable candidate");
        return boost::none; }

    for (auto& slice : *best_candidate) {
        // XXX(cole): This ignores the no deadcode elimination compiler flag!
        // It should be fixed when parser/deparser schema are introduced.
        if (uses_i.is_referenced(slice.field()) && !clot_i.allocated(slice.field()))
            alloc_attempt.allocate(slice);
        else
            LOG5("NOT ALLOCATING unreferenced field: " << slice); }
    return alloc_attempt;
}

// SUPERCLUSTER <--> CONTAINER GROUP allocation.
boost::optional<PHV::Transaction> CoreAllocation::tryAlloc(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& container_group,
        PHV::SuperCluster& super_cluster) const {
    // Check container group/cluster group constraints.
    if (!satisfies_constraints(container_group, super_cluster))
        return boost::none;

    // Make a new transaction.
    PHV::Transaction alloc_attempt = alloc.makeTransaction();

    // Try to allocate slice lists together, storing the offsets required of each
    // slice's cluster.
    ordered_map<const PHV::AlignedCluster*, int> cluster_alignment;
    ordered_set<PHV::FieldSlice> allocated;
    std::list<const PHV::SuperCluster::SliceList*> slice_lists;
    for (const PHV::SuperCluster::SliceList* slice_list : super_cluster.slice_lists())
        slice_lists.push_back(slice_list);
    // Sort slice lists according to the number of times they have been written to and read from in
    // various actions. This helps simplify constraints by placing destinations before sources
    actions_i.sort(slice_lists);
    for (const PHV::SuperCluster::SliceList* slice_list : slice_lists) {
        int le_offset = 0;
        ordered_map<const PHV::FieldSlice, int> slice_alignment;
        for (auto& slice : *slice_list) {
            const PHV::AlignedCluster& cluster = super_cluster.aligned_cluster(slice);
            auto valid_start_options = satisfies_constraints(container_group, cluster);
            if (valid_start_options == boost::none)
                return boost::none;

            if (valid_start_options->empty()) {
                LOG5("    ...but there are no valid starting positions for " << slice);
                return boost::none; }

            // If this is the first slice, then its starting alignment can be adjusted.
            if (le_offset == 0)
                le_offset = *valid_start_options->begin();

            // Return if the slice 's cluster cannot be placed at the current
            // starting offset.
            if (!valid_start_options->getbit(le_offset)) {
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
        auto partial_alloc_result =
            tryAllocSliceList(alloc_attempt, container_group, *slice_list, slice_alignment);
        if (!partial_alloc_result)
            return boost::none;
        alloc_attempt.commit(*partial_alloc_result);

        // Track allocated slices in order to skip them when allocating their clusters.
        for (auto& slice : *slice_list)
            allocated.insert(slice); }

    // After allocating each slice list, use the alignment for each slice in
    // each list to place its cluster.
    for (auto* rotational_cluster : super_cluster.clusters()) {
        for (auto* aligned_cluster : rotational_cluster->clusters()) {
            // Sort all field slices in an aligned cluster based on the number of times they are
            // written to or read from in different actions
            std::vector<PHV::FieldSlice> slice_list;
            for (PHV::FieldSlice slice : aligned_cluster->slices())
                slice_list.push_back(slice);
            actions_i.sort(slice_list);

            // Forall fields in an aligned cluster, they must share a same start position.
            // Compute possible starts.
            bitvec starts;
            if (cluster_alignment.find(aligned_cluster) != cluster_alignment.end()) {
                starts = bitvec(cluster_alignment.at(aligned_cluster), 1);
            } else {
                auto optStarts = satisfies_constraints(container_group, *aligned_cluster);
                if (!optStarts) {
                    // Other constraints not satisfied, eg. container type mismatch.
                    return boost::none; }
                if (optStarts && optStarts->empty()) {
                    // Other constraints satisfied, but alignment constraints
                    // cannot be satisfied.
                    LOG5("    ...but no valid start positions");
                    return boost::none; }
                // Constraints satisfied so long as aligned_cluster is placed
                // starting at a bit position in `starts`.
                starts = *optStarts; }

            // Compute all possible alignments
            // need this because Transaction is non-copyable somehow
            // DO NOT change this std::list to std::vector, iterators are kept.
            boost::optional<std::list<PHV::Transaction>::iterator> best_alloc = boost::none;
            std::list<PHV::Transaction> alloc_results;
            AllocScore best_score = AllocScore::make_lowest();
            for (auto start : starts) {
                bool failed = false;
                alloc_results.emplace_back(alloc_attempt.makeTransaction());
                auto possible_alloc = std::prev(alloc_results.end());
                // Try allocating all fields at this alignment.
                for (const PHV::FieldSlice& slice : slice_list) {
                    // Skip fields that have already been allocated above.
                    if (allocated.find(slice) != allocated.end()) continue;
                    ordered_map<const PHV::FieldSlice, int> start_map = { { slice, start } };
                    auto partial_alloc_result =
                        tryAllocSliceList(*possible_alloc, container_group, {slice}, start_map);
                    if (partial_alloc_result) {
                        (*possible_alloc).commit(*partial_alloc_result);
                    } else {
                        failed = true;
                        break; }
                }  // for slices

                if (failed) continue;
                auto score = AllocScore(*possible_alloc, container_group);
                if (!best_alloc || score > best_score) {
                    // Since we can't copy/move transaction,
                    // we create a new transaction and commit the best result in.
                    // so, just treat it as best_alloc = possible_alloc.
                    best_alloc = possible_alloc;
                    best_score = score; } }

            if (!best_alloc)
                return boost::none;

            alloc_attempt.commit(*(best_alloc.value())); } }

    return alloc_attempt;
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

    // Merge adjacent field slices that have been allocated adjacently in the
    // same container.  This can happen when the field is involved in a set
    // instruction with another field that has been split---it needs to be
    // "split" to match the invariants on rotational clusters, but in practice
    // to the two slices remain adjacent.
    for (auto& f : phv) {
        boost::optional<PHV::Field::alloc_slice> last = boost::none;
        safe_vector<PHV::Field::alloc_slice> merged_alloc;
        for (auto& slice : f.alloc_i) {
            if (last == boost::none) {
                last = slice;
                continue; }
            if (last->container == slice.container
                    && last->field_bits().lo == slice.field_bits().hi + 1
                    && last->container_bits().lo == slice.container_bits().hi + 1) {
                int new_width = last->width + slice.width;
                PHV::Field::alloc_slice new_slice(slice.field,
                                                  slice.container,
                                                  slice.field_bit,
                                                  slice.container_bit,
                                                  new_width);
                BUG_CHECK(new_slice.field_bits().contains(last->field_bits()),
                          "Merged alloc slice %1% does not contain hi slice %2%",
                          cstring::to_cstring(new_slice), cstring::to_cstring(*last));
                BUG_CHECK(new_slice.field_bits().contains(slice.field_bits()),
                          "Merged alloc slice %1% does not contain lo slice %2%",
                          cstring::to_cstring(new_slice), cstring::to_cstring(slice));
                last = new_slice;
                LOG5("MERGING " << last->field << ": " << *last << " and " << slice <<
                     " into " << new_slice);
            } else {
                merged_alloc.push_back(*last);
                last = slice; } }
        if (last)
            merged_alloc.push_back(*last);
        f.alloc_i = merged_alloc; }
}

void AllocatePHV::end_apply() {
    LOG1("--- BEGIN PHV ALLOCATION ----------------------------------------------------");
    LOG1(pa_container_sizes_i);
    auto alloc = make_concrete_allocation();
    auto container_groups = makeDeviceContainerGroups();
    std::list<PHV::SuperCluster*> cluster_groups = make_cluster_groups();
    std::stringstream report;

    AllocationStrategy *strategy =
        new BruteForceAllocationStrategy(core_alloc_i, report,
                                         critical_path_clusters_i, field_interference_i);
    auto result = strategy->tryAllocation(alloc, cluster_groups, container_groups);

    // Later we can try different strategies,
    // and commit result only when it reaches our expectation.
    alloc.commit(result.transaction);

    if (result.remaining_clusters.size() == 0) {
        clearSlices(phv_i);
        bindSlices(alloc, phv_i);
        phv_i.set_done();
        LOG5("ALLOCATION SUCCESSFUL:");
        LOG5(alloc);
        LOG5(alloc.getSummary(uses_i));
    } else {
        formatAndThrowError(alloc, result.remaining_clusters);
    }
}

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
        msg << alloc << std::endl;
        msg << "SuperClusters unallocated: " << std::endl;
        for (auto* sc : unallocated)
            msg << sc; }
    for (auto* super_cluster : unallocated) {
        for (auto* rotational_cluster : super_cluster->clusters()) {
            for (auto* cluster : rotational_cluster->clusters()) {
                for (auto& slice : cluster->slices()) {
                    // XXX(cole): Need to update this for JBay.
                    bool can_be_tphv = cluster->okIn(PHV::Kind::tagalong);
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
                            egress_t_phv_bits += slice.size(); } } } }
    }

    if (LOGGING(3)) {
        msg << std::endl
            << "..........Unallocated bits = " << unallocated_bits << std::endl;
        msg << "..........ingress phv bits = " << ingress_phv_bits << std::endl;
        msg << "..........egress phv bits = " << egress_phv_bits << std::endl;
        msg << "..........ingress t_phv bits = " << ingress_t_phv_bits << std::endl;
        msg << "..........egress t_phv bits = " << egress_t_phv_bits << std::endl;
        msg << std::endl; }

    msg << alloc.getSummary(uses_i) << std::endl;
    ::error("%1%", msg.str());
}

void AllocationStrategy::writeTransactionSummary(
    const PHV::Transaction& transaction,
    const std::list<PHV::SuperCluster *>& allocated) {
    report_i << transaction.getTransactionSummary() << std::endl;
    report_i << "......Allocated......." << std::endl;
    for (const auto& v : allocated) {
        report_i << v << std::endl; }
}

void GreedySortingAllocationStrategy::greedySort(
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

AllocResult
GreedySortingAllocationStrategy::tryAllocation(
    const PHV::Allocation& alloc,
    const std::list<PHV::SuperCluster*>& cluster_groups_input,
    std::list<PHV::ContainerGroup *>& container_groups) {
    // Split SuperClusters that don't have slice lists along container
    // boundaries, preferring the largest container size possible.
    std::list<PHV::SuperCluster*> cluster_groups;
    for (auto* sc : cluster_groups_input) {
        auto it = PHV::SlicingIterator(sc);
        if (!it.done()) {
            for (auto* new_sc : *it)
                cluster_groups.push_back(new_sc);
        } else {
            cluster_groups.push_back(sc); } }

    auto rst = alloc.makeTransaction();
    greedySort(rst, cluster_groups, container_groups);
    std::list<PHV::SuperCluster*> to_remove;
    for (PHV::SuperCluster* cluster_group : cluster_groups) {
        for (PHV::ContainerGroup* container_group : container_groups) {
            LOG4("TRY CLUSTER/GROUP pair:");
            LOG4(cluster_group);
            LOG4(container_group);
            if (auto partial_alloc = core_alloc_i.tryAlloc(rst, *container_group, *cluster_group)) {
                rst.commit(*partial_alloc);
                to_remove.push_back(cluster_group);
                LOG5("    this cluster/group allocation SUCCESSFUL");
                break; } } }

    // XXX(cole): There must be a better way to remove elements from a list
    // while iterating, but `it = clusters_i.erase(it)` skips elements.
    for (auto cluster_group : to_remove)
    cluster_groups.remove(cluster_group);

    // If allocation was unsuccessful, pretty-print a helpful error message.
    if (cluster_groups.size() > 0) {
        report_i << "Greedy Sorting Allocation Failed.\n";
        writeTransactionSummary(rst, to_remove);
        return AllocResult(AllocResultCode::FAIL, std::move(rst), std::move(cluster_groups));
    } else {
        return AllocResult(AllocResultCode::SUCCESS, std::move(rst), std::move(cluster_groups)); }
}

void BalancedPickAllocationStrategy::sortContainerBy(const PHV::Allocation& alloc,
        std::list<PHV::ContainerGroup *>& container_groups, const PHV::SuperCluster* cluster) {
    // The majority width of this cluster.
    int cluster_width = cluster->max_width();
    ordered_map<PHV::ContainerGroup*, int> rest_fitable_container;
    ordered_map<PHV::Size, int> rest_fitable_container_of_type;
    ordered_map<PHV::ContainerGroup*, int> opened;
    for (const auto& v : container_groups) {
        rest_fitable_container[v] = 0;
        opened[v] = 0;
        rest_fitable_container_of_type[v->type().size()] = 0;
    }

    for (const auto& c_group : container_groups) {
        int container_size = static_cast<int>(c_group->type().size());
        if (container_size < cluster_width) {
            rest_fitable_container[c_group] = 0;
            continue; }
        for (const auto& c : (*c_group)) {
            if (alloc.slices(c).size() > 0) {
                opened[c_group]++; }
            std::vector<bool> container_vec(container_size, false);
            // Not necessary to consider the liveness of slices
            for (const auto& slice : alloc.slices(c)) {
                auto range = slice.container_slice();
                for (int i = range.lo; i <= range.hi; ++i) {
                    container_vec[i] = true; } }
            int largest_gap = 0;
            for (int i = 0; i < container_size; ++i) {
                int j = i;
                while (j < container_size && !container_vec[j]) {
                    j++; }
                largest_gap = std::max(largest_gap, j - i);
                i = j; }
            if (largest_gap >= cluster_width) {
                rest_fitable_container[c_group]++; }
        }  // for containers of a group
        if (rest_fitable_container[c_group] > 0) {
            rest_fitable_container_of_type[c_group->type().size()]++; }
    }

    // Sort container groups by
    // 1. type
    // 2. pined gress.
    // 3. number of containers is used in this group
    // 4  number of rest fitable container of the type of the group
    // 4. size.
    auto ContainerGroupComparator = [&] (PHV::ContainerGroup* l, PHV::ContainerGroup* r) {
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

        if (opened[l] != opened[r])
            return opened[l] > opened[r];

        if (rest_fitable_container_of_type[l->type().size()]
            != rest_fitable_container_of_type[r->type().size()]) {
            return rest_fitable_container_of_type[l->type().size()]
                   < rest_fitable_container_of_type[r->type().size()]; }

        return int(l->type().size()) < int(r->type().size()); };

    container_groups.sort(ContainerGroupComparator);
}

void
BalancedPickAllocationStrategy::greedySortClusters(std::list<PHV::SuperCluster*>& cluster_groups) {
    // Sorts clusters by
    // the number of constraints
    // width.
    auto ClusterGroupComparator = [&] (PHV::SuperCluster* l, PHV::SuperCluster* r) {
        if (l->num_constraints() != r->num_constraints())
        return l->num_constraints() > r->num_constraints();
        return l->max_width() > r->max_width();
    };

    cluster_groups.sort(ClusterGroupComparator);
}

std::list<PHV::SuperCluster*>
BalancedPickAllocationStrategy::allocLoop(PHV::Transaction& rst,
                                          std::list<PHV::SuperCluster*>& cluster_groups,
                                          std::list<PHV::ContainerGroup *>& container_groups) {
    std::list<PHV::SuperCluster*> allocated;
    for (PHV::SuperCluster* cluster_group : cluster_groups) {
        this->sortContainerBy(rst, container_groups, cluster_group);
        for (PHV::ContainerGroup* container_group : container_groups) {
            LOG4("TRY CLUSTER/GROUP pair:");
            LOG4(cluster_group);
            LOG4(container_group);
            if (auto partial_alloc = core_alloc_i.tryAlloc(rst, *container_group, *cluster_group)) {
                rst.commit(*partial_alloc);
                allocated.push_back(cluster_group);
                LOG5("    this cluster/group allocation SUCCESSFUL");
                break; } } }

    // XXX(cole): There must be a better way to remove elements from a list
    // while iterating, but `it = clusters_i.erase(it)` skips elements.
    for (auto cluster_group : allocated)
    cluster_groups.remove(cluster_group);
    return allocated;
}

AllocResult
BalancedPickAllocationStrategy::tryAllocation(
    const PHV::Allocation& alloc,
    const std::list<PHV::SuperCluster*>& cluster_groups_input,
    std::list<PHV::ContainerGroup *>& container_groups) {
    auto rst = alloc.makeTransaction();

    // slice the rest unallocated clusters.
    std::list<PHV::SuperCluster*> cluster_groups;
    for (auto* sc : cluster_groups_input) {
        auto it = PHV::SlicingIterator(sc);
        if (!it.done()) {
            for (auto* new_sc : *it)
                cluster_groups.push_back(new_sc);
        } else {
            cluster_groups.push_back(sc); } }

    greedySortClusters(cluster_groups);
    std::list<PHV::SuperCluster*> allocated_clusters =
        allocLoop(rst, cluster_groups, container_groups);

    // If allocation was unsuccessful, pretty-print a helpful error message to report
    if (cluster_groups.size() > 0) {
        report_i << "BalancedPickAllocationStrategy Allocation Failed.\n";
        writeTransactionSummary(rst, allocated_clusters);
        return AllocResult(AllocResultCode::FAIL, std::move(rst), std::move(cluster_groups));
    } else {
        return AllocResult(AllocResultCode::SUCCESS, std::move(rst), std::move(cluster_groups)); }
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::remove_unreferenced_clusters(
        const std::list<PHV::SuperCluster*>& cluster_groups_input) {
    std::set<PHV::SuperCluster*> un_ref_singleton;
    for (auto* super_cluster : cluster_groups_input) {
        bool has_in_slist = false;
        for (const auto* slice_list : super_cluster->slice_lists()) {
            for (const auto& slice : *slice_list) {
                if (!core_alloc_i.uses().is_referenced(slice.field())) {
                    LOG4("Unreferenced slice in slice_list" << slice);
                    has_in_slist = true;
                    break; } }
            if (has_in_slist) break; }
        if (has_in_slist) continue;

        for (const auto* rot : super_cluster->clusters()) {
            for (const auto* ali : rot->clusters()) {
                for (const auto& slice : ali->slices()) {
                    if (!core_alloc_i.uses().is_referenced(slice.field())) {
                        un_ref_singleton.insert(super_cluster);
                        break; } } } }
    }

    std::list<PHV::SuperCluster*> cluster_groups_filtered;
    for (const auto& c : cluster_groups_input) {
        if (un_ref_singleton.count(c)) continue;
        cluster_groups_filtered.push_back(c); }

    return cluster_groups_filtered;
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::crush_clusters(
        const std::list<PHV::SuperCluster*>& cluster_groups) {
    std::list<PHV::SuperCluster*> cluster_groups_powders;
    for (auto* sc : cluster_groups) {
        // clusters with slice lists are not considered.
        if (sc->slice_lists().size()) {
            cluster_groups_powders.push_back(sc);
            continue; }

        // slice them to 1-bit chunks.
        bitvec slice_schema;
        for (int i = 1; i < sc->max_width(); i += 1) {
            slice_schema.setbit(i); }
        if (auto slice_rst = PHV::SlicingIterator::split_super_cluster(sc, slice_schema)) {
            for (auto* new_sc : *slice_rst) {
                cluster_groups_powders.push_back(new_sc); }
        } else {
            cluster_groups_powders.push_back(sc); } }
    return cluster_groups_powders;
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::slice_clusters(
        const std::list<PHV::SuperCluster*>& cluster_groups) {
    std::list<PHV::SuperCluster*> rst;
    for (auto* sc : cluster_groups) {
        auto it = PHV::SlicingIterator(sc);
        if (!it.done()) {
            while (!it.done()) {
                if (core_alloc_i.pa_container_sizes().satisfies_pragmas(*it)) {
                    break; }
                ++it; }
            if (it.done()) {
                ::warning("%1% No way to slice to satisfy"
                          "@pa_container_size, pragma ignored", cstring::to_cstring(sc));
                it = PHV::SlicingIterator(sc); }
            for (auto* new_sc : *it)
                rst.push_back(new_sc);
        } else {
            if (!core_alloc_i.pa_container_sizes().satisfies_pragmas({ sc })) {
                ::warning("%1% can not be sliced, and it can not satisfy some"
                          "@pa_container_size, pragma ignored",
                          cstring::to_cstring(sc)); }
            rst.push_back(sc); } }

    return rst;
}

AllocResult
BruteForceAllocationStrategy::tryAllocation(
    const PHV::Allocation &alloc,
    const std::list<PHV::SuperCluster*>& cluster_groups_input,
    std::list<PHV::ContainerGroup *>& container_groups) {
    // remove singleton un_referenced fields
    std::list<PHV::SuperCluster*> cluster_groups =
        remove_unreferenced_clusters(cluster_groups_input);

    // slice and then sort clusters.
    cluster_groups = slice_clusters(cluster_groups);
    sortClusters(cluster_groups);

    // Results are not used
    // field_interference_i.calcSliceInterference(cluster_groups);

    auto rst = alloc.makeTransaction();

    auto allocated_clusters = allocLoop(rst, cluster_groups, container_groups);

    // It is currently disable.
    // Pounder Round
    // LOG5(cluster_groups.size() << " are unallocated before Pounder Round, they are:");
    // for (auto* sc : cluster_groups) {
    //     LOG5(sc); }

    // LOG5("Pounder Round");
    // cluster_groups = crush_clusters(cluster_groups);
    // auto allocated_cluster_powders = allocLoop(rst, cluster_groups, container_groups);

    if (cluster_groups.size() > 0) {
        report_i << "BruteForceStrategy Allocation Failed.\n";
        writeTransactionSummary(rst, allocated_clusters);
        return AllocResult(AllocResultCode::FAIL, std::move(rst), std::move(cluster_groups));
    } else {
        return AllocResult(AllocResultCode::SUCCESS, std::move(rst), std::move(cluster_groups)); }
}

void
BruteForceAllocationStrategy::sortClusters(std::list<PHV::SuperCluster*>& cluster_groups) {
    auto critical_clusters = critical_path_clusters_i.calc_critical_clusters(cluster_groups);
    std::set<const PHV::SuperCluster*> need_align;
    std::set<const PHV::SuperCluster*> has_no_pack;
    std::set<const PHV::SuperCluster*> has_no_split;
    std::map<const PHV::SuperCluster*, int> n_valid_starts;
    std::set<const PHV::SuperCluster*> pounder_clusters;

    for (const auto* super_cluster : cluster_groups) {
        n_valid_starts[super_cluster] = (std::numeric_limits<int>::max)();
        for (const auto* rot : super_cluster->clusters()) {
            for (const auto* ali : rot->clusters()) {
                if (ali->alignment()) need_align.insert(super_cluster);

                bitvec starts = ali->validContainerStart(PHV::Size::b32);
                int n_starts = std::accumulate(starts.begin(), starts.end(), 0,
                                               [] (int a, int) { return a + 1; });
                n_valid_starts[super_cluster] =
                    std::min(n_valid_starts[super_cluster], n_starts);

                for (const auto& slice : ali->slices()) {
                    if (slice.field()->no_pack()) {
                        has_no_pack.insert(super_cluster); }
                    if (slice.field()->no_split()) {
                        has_no_split.insert(super_cluster); }
                } } }
    }
    for (const auto* super_cluster : cluster_groups) {
        if (has_no_split.count(super_cluster) || has_no_pack.count(super_cluster)) continue;
        if (n_valid_starts[super_cluster] < 10) continue;
        if (super_cluster->slice_lists().size() >= 1) continue;
        if (super_cluster->aggregate_size() <= 4) continue;
        pounder_clusters.insert(super_cluster);
    }

    auto ClusterGroupComparator = [&] (PHV::SuperCluster* l, PHV::SuperCluster* r) {
        if (pounder_clusters.count(l) != pounder_clusters.count(r)) {
            return pounder_clusters.count(l) < pounder_clusters.count(r); }
        if (n_valid_starts.at(l) != n_valid_starts.at(r)) {
            return n_valid_starts.at(l) < n_valid_starts.at(r); }
        if (has_no_pack.count(l) != has_no_pack.count(r)) {
            return has_no_pack.count(l) > has_no_pack.count(r); }
        if (has_no_split.count(l) != has_no_split.count(r)) {
            return has_no_split.count(l) > has_no_split.count(r); }
        // if (need_align.count(l) != need_align.count(r)) {
        //     return need_align.count(l) > need_align.count(r); }
        // if (critical_clusters.count(l) != critical_clusters.count(r)) {
        //     return critical_clusters.count(l) > critical_clusters.count(r); }
        // if (l->slice_lists().size() != r->slice_lists().size()) {
        //     return l->slice_lists().size() > r->slice_lists().size(); }
        if (l->num_constraints() != r->num_constraints()) {
            return l->num_constraints() > r->num_constraints(); }
        if (l->max_width() != r->max_width()) {
            return l->max_width() > r->max_width(); }
        if (l->aggregate_size() != r->aggregate_size()) {
            return l->aggregate_size() > r->aggregate_size(); }
        return false;
    };
    cluster_groups.sort(ClusterGroupComparator);

    LOG5("============ Sorted SuperClusters ===============");
    for (const auto& v : cluster_groups) {
        LOG5(v); }
    LOG5("========== end Sorted SuperClusters =============");
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::allocLoop(PHV::Transaction& rst,
                                        std::list<PHV::SuperCluster*>& cluster_groups,
                                        std::list<PHV::ContainerGroup *>& container_groups) {
    std::list<PHV::SuperCluster*> allocated;
    for (PHV::SuperCluster* cluster_group : cluster_groups) {
        auto best_score = AllocScore::make_lowest();
        boost::optional<PHV::ContainerGroup*> best_group = boost::none;
        for (PHV::ContainerGroup* container_group : container_groups) {
            LOG4("TRY CLUSTER/GROUP pair:");
            LOG4(cluster_group);
            LOG4(container_group);
            if (auto partial_alloc = core_alloc_i.tryAlloc(rst, *container_group, *cluster_group)) {
                AllocScore score = AllocScore(*partial_alloc, *container_group);
                LOG4("score: " << score);
                if (!best_group || score > best_score) {
                    best_score = score;
                    best_group = container_group; } } }
        if (best_group) {
            auto partial_alloc = core_alloc_i.tryAlloc(rst, *(best_group.value()), *cluster_group);
            rst.commit(*partial_alloc);
            allocated.push_back(cluster_group); }
    }

    // XXX(cole): There must be a better way to remove elements from a list
    // while iterating, but `it = clusters_i.erase(it)` skips elements.
    for (auto cluster_group : allocated)
    cluster_groups.remove(cluster_group);
    return allocated;
}
