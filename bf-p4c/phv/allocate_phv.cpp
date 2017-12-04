#include "allocate_phv.h"
#include <boost/format.hpp>
#include <boost/range/adaptor/reversed.hpp>
#include "lib/log.h"


/* static */
std::vector<le_bitrange>
AllocatePHV::make_field_slices(int aggregate_size, int slice_size, int start) {
    BUG_CHECK(aggregate_size >= 0, "Negative aggregate slice size");
    BUG_CHECK(slice_size >= 0, "Negative slice size");
    BUG_CHECK(start >= 0, "Negative slice start");

    if (aggregate_size == 0 || slice_size == 0)
        return { };

    std::vector<le_bitrange> rv;
    le_bitinterval aggregate_interval = StartLen(0, aggregate_size);

    // The slice window may be smaller than `slice_size` for the first slice,
    // depending on the `start` position`.
    le_bitinterval slice_window = aggregate_interval & StartLen(0, slice_size - start);

    while (!slice_window.empty()) {
        // Make a new slice
        rv.emplace_back(*toClosedRange(slice_window));

        // Shift the slice window, then intersect with the aggregate range.
        slice_window = slice_window.shiftedByBits(slice_window.size());
        slice_window = slice_window.resizedToBits(slice_size);
        slice_window &= aggregate_interval; }

    return rv;
}

/* static */
std::vector<le_bitrange>
AllocatePHV::make_container_slices(int aggregate_size, int slice_size, int start) {
    std::vector<le_bitrange> rv;
    for (le_bitrange field_slice : make_field_slices(aggregate_size, slice_size, start)) {
        // Align the first container slice at `start` and every slice thereafter at 0.
        if (field_slice.lo == 0)
            rv.push_back(field_slice.shiftedByBits(start));
        else
            rv.emplace_back(field_slice.shiftedByBits(-field_slice.lo)); }
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
    // unsatisfiable with field lists, which induce packing.
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
                // Otherwise this error is produced for every field
                // list/container group pair.
                ::error("Field %1% must be "
                        "placed alone in a PHV container, but the parser must pack it "
                        "contiguously with its adjacent fields.  This is unsatisfiable.  The "
                        "list of adjacent fields is:\n%2%", cstring::to_cstring(slice.field()),
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
                    " but field needs " << f->gress);
        return false; }

    // Check no pack for this field.
    const auto& slices = alloc.slices(c);
    if (slices.size() > 0 && slice.field()->no_pack()) {
        LOG5("        constraint: field has no_pack constraint but container has slices " <<
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
bool AllocatePHV::satisfies_constraints(const PHV::ContainerGroup&, const PHV::SuperCluster&) {
    // TODO (cole): fill this in.
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

    /* XXX(cole): The following several stanzas are an ad hoc approach to CCGF
     * allocation that do the following:
     *
     *  - If the CCGF has members that are no_pack or deparsed_bottom_bits,
     *    then split the CCGF into individual containers at offset 0.
     *  - Otherwise, if the CCGF is less than the size of the container, unpack it
     *    and assign each member field in order in a container.
     *  - Otherwise return boost::none.
     *
     * Need to replace with comprehensive CCGF splitting.
     */

    // If f is a CCGF with special constraints, then allocate each member field individually.
    bool special_ccgf_placement =
        std::any_of(f->ccgf_fields_i.begin(), f->ccgf_fields_i.end(), [&](PHV::Field *member) {
            return member->deparsed_bottom_bits()
                || member->no_pack()
                || member->mau_phv_no_pack(); });
    if (special_ccgf_placement) {
        // Allocate members, deconstructing CCGF.
        LOG4("    ...and CCGF has deparsed_bottom_bits, no_pack, or mau_phv_no_pack");

        // Check that this container group has enough free containers to place
        // each CCGF member alone in a container.
        int max_width = 0;
        for (auto* member : f->ccgf_fields_i)
            max_width = std::max(max_width, member->size);
        if (container_size < max_width) {
            LOG4("    ...but container size " << container_size <<
                 " is too small to hold largest member field");
            return boost::none;
        }

        for (auto* member : boost::adaptors::reverse(f->ccgf_fields_i)) {
            // Don't allocate unreferenced fields.
            if (!uses_i.is_referenced(member) || clot_i.allocated(member))
                continue;

            int offset = member->deparsed_bottom_bits() ? 0 : start;

            // Find a container
            boost::optional<PHV::AllocSlice> candidate = boost::none;
            for (const PHV::Container c : group) {
                auto slice = PHV::AllocSlice(member, c,
                                             StartLen(0, member->size),         // field slice
                                             StartLen(offset, member->size));   // container slice
                if (!satisfies_constraints(alloc_attempt, slice)) {
                    LOG5("    ...but " << slice << " doesn't satisfy constraints");
                    continue;
                }
                // Prioritize overlaying
                bool container_empty = alloc_attempt.slices(c, slice.container_slice()).size() == 0;
                if (can_overlay(mutex_i, member, alloc_attempt.slices(c)) && !container_empty) {
                    LOG5("    ...and can overlay" << alloc_attempt.slices(c));
                    candidate = slice;
                    break;
                } else if (container_empty) {
                    candidate = slice;
                } else {
                    LOG5("    ...but " << c << " already contains " << alloc_attempt.slices(c)); } }

            // Prioritize overlaying vs. using a new container.  If no
            // containers are available, return false.
            if (!candidate) {
                LOG4("    ...but ran out of containers allocating special CCGF fields");
                return boost::none;
            }

            alloc_attempt.allocate(*candidate); }
        return alloc_attempt; }

    // Otherwise, if f is a normal CCGF
    LOG5("    ...and CCGF is not special");
    int ccgf_size = 0;
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
        const std::vector<PHV::Field*>& fields,
        const ordered_map<const PHV::Field*, int>& start_positions) {
    LOG4("trying to allocate fields at container indices: ");
    for (auto* f : fields) {
        BUG_CHECK(start_positions.find(f) != start_positions.end(),
                  "Trying to place field list with no container index for field %1%",
                  cstring::to_cstring(f));
        LOG4("  " << start_positions.at(f) << ": " << f); }

    // Check FIELD<-->GROUP constraints for each field.
    for (auto* f : fields) {
        if (!satisfies_constraints(group, f)) {
            LOG5("    ...but field " << f << " doesn't satisfy field<-->group constraints");
            return boost::none; } }

    PHV::Transaction alloc_attempt = alloc.makeTransaction();
    int container_size = int(group.type().size());

    // XXX(cole): Slicing is really a whole cluster operation.  Eventually,
    // this method will be able to return boost::none if the whole field list
    // can't fit in a single container.  In the meantime, distinguish between
    // singleton lists, which will be split.

    if (fields.size() == 1) {
        /* Split f into container-sized chunks, starting at `start` (the first and
         * last chunks may be smaller than a full container).
         *
         *     For each chunk, look for a container that is occupied with fields
         *     that `f` can overlay; failing that, pick an empty container.  Mark
         *     it.
         *
         * Continue until all chunks of all fields are allocated.  If no containers
         * remain, return false.
         */
        PHV::Field *f = fields.front();
        int start = start_positions.at(f);

        if (f->is_ccgf())
            return tryAllocCCGF(alloc, group, f, start);

        // Return the transaction (rather than boost::none) immediately if the
        // field is never referenced.
        if (!uses_i.is_referenced(f)) {
            LOG5("    ...but field is never referenced, so ignore");
            return alloc_attempt; }

        // Don't allocate fields in a CLOT.
        if (clot_i.allocated(f)) {
            LOG5("    ...but field is in a CLOT, so ignore");
            return alloc_attempt; }

        // Check constraints on this field and container group.
        if (!satisfies_constraints(group, f)) {
            LOG5("    ...but these containers do not satisfy field/container constraints");
            return boost::none; }

        // XXX(cole): This is an awful hack!  Because CCGF members can show
        // up in clusters, they may be submitted for allocation
        // independently of their owners.  Eventually CCGFs will go away,
        // but in the meantime, filter out members.
        if (!f->is_ccgf() && f->ccgf() != nullptr)
            return alloc_attempt;

        // Otherwise, tile the field across containers.
        auto field_slices = make_field_slices(f->size, container_size, start);
        auto container_slices = make_container_slices(f->size, container_size, start);
        BUG_CHECK(field_slices.size() > 0, "Field with no slices: %1%", cstring::to_cstring(f));
        for (unsigned i = 0; i < field_slices.size(); ++i) {
            boost::optional<PHV::AllocSlice> candidate = boost::none;
            // Find a container
            for (const PHV::Container c : group) {
                auto slice = PHV::AllocSlice(f, c, field_slices[i], container_slices[i]);
                if (!satisfies_constraints(alloc_attempt, slice)
                        || !satisfies_constraints({slice})) {
                    LOG5("    ...but " << slice << " doesn't satisfy constraints");
                    continue; }

                // Prioritize overlaying
                bool container_empty = alloc_attempt.slices(c, slice.container_slice()).size() == 0;
                if (can_overlay(mutex_i, f, alloc_attempt.slices(c)) && !container_empty) {
                    LOG5("    ...and can overlay" << alloc_attempt.slices(c));
                    candidate = slice;
                    break;
                } else if (container_empty) {
                    candidate = slice;
                } else {
                    LOG5("    ...but " << c << " already contains " << alloc_attempt.slices(c)); } }

            // Prioritize overlaying vs. using a new container.  If no
            // containers are available, return false.
            if (!candidate) {
                LOG5("    ...hence there is no suitable container");
                return boost::none; }

            alloc_attempt.allocate(*candidate); }

        return alloc_attempt; }

    // XXX(cole): For now, fail if a field list contains a CCGF owner or member.
    for (auto* f : fields) {
        if (f->is_ccgf() || f->ccgf() != nullptr) {
            LOG5("    ...but field list contains a CCGF field " << f);
            return boost::none; } }

    // Return if the fields can't fit together in a container.
    int aggregate_size = 0;
    for (auto* f : fields)
        aggregate_size += f->size;
    if (container_size < aggregate_size) {
        LOG5("    ...but these fields are " << aggregate_size << "b in total and cannot fit in a "
             << container_size << "b container");
        return boost::none; }

    // Look for a container to allocate all fields in.
    boost::optional<std::vector<PHV::AllocSlice>> candidate = boost::none;
    int max_overlays = 0;
    for (const PHV::Container c : group) {
        std::vector<PHV::AllocSlice> slices;
        for (auto* field : fields) {
            le_bitrange field_slice = StartLen(0, field->size);
            le_bitrange container_slice = StartLen(start_positions.at(field), field->size);
            slices.push_back(PHV::AllocSlice(field, c, field_slice, container_slice)); }

        // Check field list<-->container constraints.
        if (!satisfies_constraints(slices))
            continue;

        // Check that each field slice satisfies slice<-->container constraints.
        bool constraints_ok =
            std::all_of(slices.begin(), slices.end(),
                        [&](const PHV::AllocSlice& slice) {
                            return satisfies_constraints(alloc_attempt, slice); });
        if (!constraints_ok)
            continue;

        // Check that there's space.
        bool can_place = true;
        int num_overlays = 0;
        for (auto& slice : slices) {
            const auto& alloced_slices =
                alloc_attempt.slices(slice.container(), slice.container_slice());
            if (alloced_slices.size() > 0 && can_overlay(mutex_i, slice.field(), alloced_slices)) {
                num_overlays++;
            } else if (alloced_slices.size() > 0) {
                LOG5("    ...but " << c << " already contains " << alloced_slices);
                can_place = false;
                break; } }
        if (can_place && (!candidate || num_overlays > max_overlays)) {
            candidate = slices;
            max_overlays = num_overlays; } }

    if (!candidate) {
        LOG5("    ...hence there is no suitable candidate");
        return boost::none; }

    for (auto& slice : *candidate) {
        // XXX(cole): Is it always safe to not allocate unreferenced fields?
        if (uses_i.is_referenced(slice.field()) && !clot_i.allocated(slice.field()))
            alloc_attempt.allocate(slice); }
    return alloc_attempt;
}

// CLUSTER GROUP <--> CONTAINER GROUP allocation.
boost::optional<PHV::Transaction> AllocatePHV::tryAlloc(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& container_group,
        PHV::SuperCluster& cluster_group) {
    // Check container group/cluster group constraints.
    if (!satisfies_constraints(container_group, cluster_group))
        return boost::none;

    // Make a new transaction.
    PHV::Transaction alloc_attempt = alloc.makeTransaction();

    // Try to allocate CCGFs together, storing the offsets required of each
    // field's cluster.
    ordered_map<const PHV::AlignedCluster*, int> cluster_alignment;
    ordered_set<const PHV::Field*> allocated;
    for (const PHV::SuperCluster::FieldList* field_list : cluster_group.field_lists()) {
        int le_offset = 0;
        ordered_map<const PHV::Field*, int> field_alignment;
        for (auto* field : *field_list) {
            auto& cluster = cluster_group.cluster(field);
            auto valid_start_options = satisfies_constraints(container_group, cluster);
            if (valid_start_options.empty())
                return boost::none;

            // If this is the first field, then its starting alignment can be adjusted.
            if (le_offset == 0)
                le_offset = *valid_start_options.min();

            // Return if the field's cluster cannot be placed at the current
            // starting offset.
            if (!valid_start_options.getbit(le_offset)) {
                LOG5("    ...but field list requires field to start at " << le_offset <<
                     " which its cluster cannot support");
                return boost::none; }

            // Return if the field is part of another CCGF but was previously
            // placed at a different start location.
            // XXX(cole): We may need to be smarter about coordinating all
            // valid starting ranges for all CCGFs.
            if (cluster_alignment.find(&cluster) != cluster_alignment.end() &&
                    cluster_alignment.at(&cluster) != le_offset) {
                LOG5("    ...but two field lists have conflicting alignment requirements for "
                     "field %1%" << field);
                return boost::none; }

            // Otherwise, update the alignment for this field's cluster.
            cluster_alignment[&cluster] = le_offset;
            field_alignment[field] = le_offset;
            le_offset += field->size; }

        // Try allocating the field list.
        auto partial_alloc =
            tryAlloc(alloc_attempt, container_group, *field_list, field_alignment);
        if (!partial_alloc)
            return boost::none;
        alloc_attempt.commit(*partial_alloc);

        // Track allocated fields in order to skip them when allocating their clusters.
        for (auto* field : *field_list)
            allocated.insert(field); }

    // After allocating each field list, use the alignment for each field in
    // each list to place its cluster.
    for (auto* cluster : cluster_group.clusters()) {
        for (PHV::Field* f : cluster->fields()) {
            // Skip fields that have already been allocated above.
            if (allocated.find(f) != allocated.end())
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

            ordered_map<const PHV::Field*, int> start_map = { { f, start } };
            auto partial_alloc = tryAlloc(alloc_attempt, container_group, {f}, start_map);
            if (partial_alloc)
                alloc_attempt.commit(*partial_alloc);
            else
                return boost::none; } }

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

    for (auto* cluster_group : unallocated) {
        msg << "---" << std::endl;
        for (auto* cluster : cluster_group->clusters()) {
            for (auto* f : cluster->fields()) {
                // XXX(cole): Need to update this for JBay.
                bool can_be_tphv = cluster->okIn(PHV::Kind::tagalong);
                cstring s = can_be_tphv ? "tphv" : "phv";
                msg << "    " << (LOGGING(3) ? (cstring::to_cstring(f)+" --"+s) : f->name)
                    << std::endl;
                unallocated_bits += f->size;
                if (f->gress == INGRESS) {
                    if (!can_be_tphv)
                        ingress_phv_bits += f->size;
                    else
                        ingress_t_phv_bits += f->size;
                } else {
                    if (!can_be_tphv)
                        egress_phv_bits += f->size;
                    else
                        egress_t_phv_bits += f->size; } } } }

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

    std::list<PHV::SuperCluster*> cluster_groups;
    cluster_groups.insert(cluster_groups.begin(), clustering_i.cluster_groups().begin(),
                                                  clustering_i.cluster_groups().end());

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
