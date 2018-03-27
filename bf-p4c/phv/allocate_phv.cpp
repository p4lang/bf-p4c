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
bool AllocScore::operator>(const AllocScore& other) const {
    // Less TPHV over PHV
    // This is not redundent even if we have weight_factor for TPHV/PHV score,
    // because we want to avoid the case that placing TPHV candidates to PHV containers
    // so that the score is higher, because scores are calculated based on
    // container type, not field type.
    if (n_tphv_on_phv_bits != other.n_tphv_on_phv_bits) {
        return n_tphv_on_phv_bits < other.n_tphv_on_phv_bits; }

    int weight_factor = 2;
    int delta_wasted_bits = 0;
    int delta_packing_bits = 0;
    int delta_overlay_bits = 0;
    int delta_inc_containers = 0;
    int delta_set_gress = 0;
    int delta_container_imbalance = 0;

    for (auto kind : { PHV::Kind::normal, PHV::Kind::tagalong }) {
        int penalty = kind == PHV::Kind::normal ? weight_factor : 1;
        int bonus = kind == PHV::Kind::tagalong ? weight_factor : 1;

        // Add this score.
        if (score.find(kind) != score.end()) {
            delta_wasted_bits += penalty * score.at(kind).n_wasted_bits;
            delta_packing_bits += bonus * score.at(kind).n_packing_bits;
            delta_overlay_bits += bonus * score.at(kind).n_overlay_bits;
            delta_inc_containers += penalty * score.at(kind).n_inc_containers;
            delta_set_gress += penalty * score.at(kind).n_set_gress;
            delta_container_imbalance += penalty * score.at(kind).container_imbalance; }

        // Subtract other score.
        if (other.score.find(kind) != other.score.end()) {
            delta_wasted_bits -= penalty * other.score.at(kind).n_wasted_bits;
            delta_packing_bits -= bonus * other.score.at(kind).n_packing_bits;
            delta_overlay_bits -= bonus * other.score.at(kind).n_overlay_bits;
            delta_inc_containers -= penalty * other.score.at(kind).n_inc_containers;
            delta_set_gress -= penalty * other.score.at(kind).n_set_gress;
            delta_container_imbalance -=
                penalty * other.score.at(kind).container_imbalance; }
    }

    // A AllocScore has several metrics, some are positive while some are negative.
    // The delta is `others - mine`, so that:
    // if delta == 0, then the metic are the same.
    // if delta >  0, then the metic is higher than other's.
    // if delta <  0, then the metric is lower than other's.
    // For positive metrics (overlay_bits, packing_bits...), the higher is better.
    // For negative metrics (wasted_bits, inc_container...), the lower is better.
    // Operator> return true if this score is better.
    if (delta_wasted_bits != 0) {
        // This score has less wasted bits.
        return delta_wasted_bits < 0; }
    if (delta_overlay_bits != 0) {
        // This score has more overlay bits.
        return delta_overlay_bits > 0; }
    if (delta_packing_bits != 0) {
        // This score has more packing bits.
        return delta_packing_bits > 0; }
    if (delta_inc_containers != 0) {
        // This score requires more new containers.
        return delta_inc_containers < 0; }
    if (delta_set_gress != 0) {
        // This score pins less containers to a new gress.
        return delta_set_gress < 0; }

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
 * + container_imbalance: the sum of the difference between free 8b, 16b, and 32b containers.
 */
AllocScore::AllocScore(const PHV::Transaction& alloc,
                       const PhvUse& uses) : AllocScore() {
    const auto* parent = alloc.getParent();

    // Forall allocated slices group by container.
    for (const auto kv : alloc.getTransactionStatus()) {
        const auto& container = kv.first;
        const auto kind = container.type().kind();
        const auto& gress = kv.second.gress;
        const auto& slices = kv.second.slices;
        bitvec parent_alloc_vec = calcContainerAllocVec(parent->slices(container));

        // skip, if there is no allocated slices.
        if (slices.size() == 0)
            continue;

        // calc n_wasted_bits
        for (const auto& slice : slices) {
            if (slice.field()->no_pack()) {
                score[kind].n_wasted_bits += (container.size() - slice.width()); } }

        if (kind == PHV::Kind::normal) {
            for (const auto& slice : slices) {
                if (slice.field()->is_tphv_candidate(uses)) {
                    n_tphv_on_phv_bits += (slice.width()); } } }

        // calc_n_inc_containers
        ContainerAllocStatus merged_status = alloc.alloc_status(container);
        ContainerAllocStatus parent_status = parent->alloc_status(container);
        if (parent_status == ContainerAllocStatus::EMPTY
            && merged_status != ContainerAllocStatus::EMPTY) {
            score[kind].n_inc_containers++; }

        // calc n_packing_bits
        if (parent_status == ContainerAllocStatus::PARTIAL) {
            for (auto i = container.lsb(); i <= container.msb(); ++i) {
                if (parent_alloc_vec[i]) continue;
                for (const auto& slice : slices) {
                    if (slice.container_slice().contains(i)) {
                        score[kind].n_packing_bits++;
                        break; }
                } } }

        // calc n_overlay_bits
        for (const int i : parent_alloc_vec) {
            for (const auto slice : slices) {
                if (slice.container_slice().contains(i)) {
                    score[kind].n_overlay_bits++; } } }

        // gress
        if (!parent->gress(container) && gress) {
            score[kind].n_set_gress++; }

        // container imbalance
        // XXX(cole): This currently weights packing into 32b containers
        // highest, followed by 16b, and then 8b.
        auto count8  = alloc.empty_containers(PHV::Size::b8) * 4;
        auto count16 = alloc.empty_containers(PHV::Size::b16) * 2;
        auto count32 = alloc.empty_containers(PHV::Size::b32);
        score[kind].container_imbalance =
            std::abs(count8 - count16) +
            std::abs(count16 - count32);
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

std::ostream& operator<<(std::ostream& s, const AllocScore& score) {
    bool any_positive_score = false;
    for (auto kind : { PHV::Kind::tagalong, PHV::Kind::normal }) {
        if (score.score.find(kind) == score.score.end())
            continue;
        any_positive_score = true;
        s << "[";
        s << "tphv: " << (kind == PHV::Kind::tagalong) << ", ";
        s << "wasted_bits: " << score.score.at(kind).n_wasted_bits << ", ";
        s << "overlay_bits: " << score.score.at(kind).n_overlay_bits << ", ";
        s << "packing_bits: " << score.score.at(kind).n_packing_bits << ", ";
        s << "inc_containers: " << score.score.at(kind).n_inc_containers << ", ";
        s << "set_gress: " << score.score.at(kind).n_set_gress << ", ";
        s << "free container imbalance: " << score.score.at(kind).container_imbalance;
        s << "]"; }

    if (!any_positive_score)
        s << "[ score: 0 ]";

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
    auto req = pragmas_i.pa_container_sizes().field_slice_req(slice);
    if (req && !group.is(*req)) {
        LOG5("        constraint: @pa_container_size mark that: "
             << slice << " must go to " << *req << " container ");
        return false; }
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
            return (slice.field()->deparsed() || slice.field()->exact_containers());
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
    for (auto& slice : slices) {
        bool isDeparsedOrMau = uses_i.is_deparsed(slice.field()) ||
            uses_i.is_used_mau(slice.field());
        bool isClot = clot_i.allocated(slice.field());
        bool alwaysPackable = slice.field()->alwaysPackable;
        if (isDeparsedOrMau && !isClot && !alwaysPackable)
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

// NB: action-induced PHV constraints are checked separately as part of
// `can_pack` on slice lists.
bool CoreAllocation::satisfies_constraints(
        const PHV::Allocation& alloc,
        PHV::AllocSlice slice) const {
    const PHV::Field* f = slice.field();
    PHV::Container c = slice.container();

    // Check gress.
    if (alloc.gress(c) && *alloc.gress(c) != f->gress) {
        LOG5("        constraint: container " << c << " is " << *alloc.gress(c) <<
                    " but slice needs " << f->gress);
        return false; }

    // Check no pack for this field.
    const auto& slices = alloc.slicesByLiveness(c, slice);
    if (slices.size() > 0 && slice.field()->no_pack()) {
        LOG5("        constraint: slice has no_pack constraint but container has slices ");
        return false; }

    // Check no pack for any other fields already in the container.
    for (auto& slice : slices) {
        if (slice.field()->no_pack()) {
            LOG5("        constraint: field " << slice.field() << " has no_pack constraint and is "
                         "already placed in this container");
            return false; } }

    // pov bits are parser initialized as well.
    bool hasUninitializedRead = std::any_of(
            slices.begin(), slices.end(), [&] (const PHV::AllocSlice& s) {
        return s.field()->pov || defuse_i.hasUninitializedRead(s.field()->id);
    });

    bool hasExtracted = std::any_of(slices.begin(), slices.end(), [&] (const PHV::AllocSlice& s) {
        return !s.field()->pov && uses_i.is_extracted(s.field());
    });

    bool isThisSliceExtracted = !slice.field()->pov && uses_i.is_extracted(slice.field());
    bool isThisSliceUninitialized = (slice.field()->pov
                                     || defuse_i.hasUninitializedRead(slice.field()->id));

    if (hasExtracted && (isThisSliceUninitialized || isThisSliceExtracted)) {
        LOG5("        constraint: container already contains extracted slices, "
             "can not be packed, because: this slice is "
             << (isThisSliceExtracted ? "extracted" : "uninitialized"));
        return false; }

    if (isThisSliceExtracted && (hasUninitializedRead || hasExtracted)) {
        LOG5("        constraint: this slice is extracted, "
             "can not be packed, because allocated fields has "
             << (hasExtracted ? "extracted" : "uninitialized"));
        return false; }

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
            LOG5("    ...but " << c << " already contains slices at this position"); } }

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

boost::optional<PHV::Transaction>
CoreAllocation::tryAllocSliceList(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const PHV::SuperCluster& super_cluster,
        const ordered_map<PHV::FieldSlice, int>& start_positions) const {
    PHV::Allocation::ConditionalConstraints start_pos;
    for (auto kv : start_positions)
        start_pos[kv.first] = PHV::Allocation::ConditionalConstraintData(kv.second);
    return tryAllocSliceList(alloc, group, super_cluster, start_pos);
}

// FIELDSLICE LIST <--> CONTAINER GROUP allocation.
// This function generally is used under two cases:
// 1. Allocating the slice list of a super_cluster.
// 2. Allocating a single field.
// For the both cases, @p start_positions are valid starting positions of slices.
// Additionally, start_positions also now represents conditional constraints that are generated by
// ActionPhvConstraints.
// The sub-problem here, is to find the best container for this SliceList that
// 1. It is valid.
// 2. Try to maximize overlays. (in terms of the number of overlays).
// 3. If same n_overlay, try to maximize packing,
//    in terms of choosing the container with least free room).
boost::optional<PHV::Transaction>
CoreAllocation::tryAllocSliceList(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const PHV::SuperCluster& super_cluster,
        const PHV::Allocation::ConditionalConstraints& start_positions) const {
    PHV::SuperCluster::SliceList slices;
    for (auto& kv : start_positions)
        slices.push_back(kv.first);

    // Set previous_container to the container returned as part of start_positions
    boost::optional<PHV::Container> previous_container = boost::none;
    LOG5("trying to allocate slices at container indices: ");
    for (auto& slice : slices) {
        if (LOGGING(5)) {
            std::stringstream ss;
            ss << "  " << start_positions.at(slice).bitPosition << ": " << slice;
            if (start_positions.at(slice).container)
                ss << " (Required container: " << *(start_positions.at(slice).container) << ")";
            LOG5(ss.str()); }
        if (start_positions.at(slice).container) {
            PHV::Container tmpContainer = *(start_positions.at(slice).container);
            if (!previous_container)
                previous_container = tmpContainer; } }

    // Check if any of these slices have already been allocated.  If so, record
    // where.  Because we have already finely sliced each field, we can check
    // slices for equivalence rather than containment.
    ordered_map<PHV::FieldSlice, PHV::AllocSlice> previous_allocations;

    for (auto& slice : slices) {
        // XXX(cole): Looking up existing allocations is expensive in the
        // current implementation.  Consider refactoring.
        auto alloc_slices = alloc.slices(slice.field(), slice.range());
        BUG_CHECK(alloc_slices.size() <= 1, "Fine slicing failed");
        if (alloc_slices.size() == 0)
            continue;
        auto alloc_slice = *alloc_slices.begin();

        // Check if previous allocations were to a container in this group.
        if (!group.contains(alloc_slice.container())) {
            LOG5("    ...but slice " << slice << " has already been allocated to a different "
                 "container group");
            return boost::none; }

        // Check if all previous allocations were to the same container.
        if (previous_container && *previous_container != alloc_slice.container()) {
            LOG5("    ...but some slices in this list have already been allocated to different "
                 "containers");
            return boost::none; }
        previous_container = alloc_slice.container();

        // Check that previous allocations match the proposed bit positions in this allocation.
        if (alloc_slice.container_slice().lo != start_positions.at(slice).bitPosition) {
            LOG5("    ...but " << alloc_slice << " has already been allocated and does not start "
                 "at " << start_positions.at(slice).bitPosition);
            return boost::none; }

        // Record previous allocations for use later.
        previous_allocations.emplace(slice, alloc_slice); }

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
                min_start_pos = start_positions.at(slice).bitPosition;
                continue; }
            if (slice.field() != acc->field()) {
                LOG5("    ...but slice list contains CCGF slices of different fields");
                return boost::none; }
            min_start_pos = std::min(*min_start_pos, start_positions.at(slice).bitPosition); }
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
    boost::optional<PHV::Transaction> best_candidate = boost::none;
    for (const PHV::Container c : group) {
        // If any slices were already allocated, ensure that unallocated slices
        // are allocated to the same container.
        if (previous_container && *previous_container != c) {
            LOG5("    ...but some slices were already allocated to " << *previous_container);
            continue; }

        std::vector<PHV::AllocSlice> candidate_slices;

        // Generate candidate_slices if we choose this container.
        for (auto& field_slice : slices) {
            le_bitrange container_slice =
                StartLen(start_positions.at(field_slice).bitPosition, field_slice.size());
            // Field slice has a const Field*, so get the non-const version using the PhvInfo object
            candidate_slices.push_back(PHV::AllocSlice(phv_i.field(field_slice.field()->id),
                        c, field_slice.range(), container_slice)); }

        // Check slice list<-->container constraints.
        if (!satisfies_constraints(candidate_slices))
            continue;

        // Check that there's space.
        bool can_place = true;
        for (auto& slice : candidate_slices) {
            if (!uses_i.is_referenced(slice.field()))
                continue;
            // Skip slices that have already been allocated.
            if (previous_allocations.find(PHV::FieldSlice(slice.field(), slice.field_slice()))
                    != previous_allocations.end())
                continue;
            const auto& alloced_slices =
                alloc_attempt.slices(slice.container(), slice.container_slice());
            if (alloced_slices.size() > 0 && can_overlay(mutex_i, slice.field(), alloced_slices)) {
                LOG5("    ...and can overlay " << slice.field() << " on " << alloced_slices);
            } else if (alloced_slices.size() > 0) {
                LOG5("    ...but " << c << " already contains slices at this position");
                can_place = false;
                break; } }
        if (!can_place) continue;  // try next container

        // Check that each field slice satisfies slice<-->container
        // constraints, skipping slices that have already been allocated.
        bool constraints_ok =
            std::all_of(candidate_slices.begin(), candidate_slices.end(),
                [&](const PHV::AllocSlice& slice) {
                    PHV::FieldSlice fs(slice.field(), slice.field_slice());
                    bool alloced = previous_allocations.find(PHV::FieldSlice(fs)) !=
                                   previous_allocations.end();
                    return alloced ? true : satisfies_constraints(alloc_attempt, slice); });
        if (!constraints_ok)
            continue;

        // Check whether the candidate slice allocations respect action-induced constraints.
        auto action_constraints = actions_i.can_pack(alloc_attempt, candidate_slices);
        if (!action_constraints) {
            LOG5("        ...action constraint: cannot pack into container " << c);
            continue;
        } else if (action_constraints->size() > 0) {
            if (LOGGING(5)) {
                LOG5("    ...but only if the following placements are respected:");
                for (auto kv : *action_constraints) {
                    std::stringstream ss;
                    ss << "        " << kv.first << " @ " << kv.second.bitPosition;
                    if (kv.second.container)
                        ss << " and @container " << *(kv.second.container);
                    LOG5(ss.str()); } }

            // Find slice lists that contain slices in action_constraints.
            boost::optional<const PHV::SuperCluster::SliceList*> slice_list = boost::none;
            bool has_not_in_list = false;
            for (auto& slice_and_pos : *action_constraints) {
                const auto& slice_lists = super_cluster.slice_list(slice_and_pos.first);

                // Disregard slices that aren't in slice lists.
                if (slice_lists.size() == 0) {
                    has_not_in_list = true;
                    continue; }

                // If a slice is in multiple slice lists, abort.
                // XXX(cole): This is overly constrained.
                if (slice_lists.size() > 1) {
                    LOG5("    ...but a conditional placement is in multiple slice lists");
                    return boost::none; }

                // If another slice in these action constraints is in a
                // different slice list, abort.
                // XXX(cole): This is also overly constrained.
                if (slice_list && *slice_list != *slice_lists.begin()) {
                    LOG5("    ...but two conditional placements are in two different slice lists");
                    return boost::none; }

                slice_list = *slice_lists.begin(); }

            // XXX(cole): Abort if the requirements a mix of slices in slice
            // lists and those not in slice lists.  This is overly constrained.
            if (has_not_in_list && slice_list) {
                LOG5("    ...but action constraints include some slices in a slice list and "
                     "some that are not");
                return boost::none; }

            if (slice_list) {
                // Check that the positions induced by action constraints match
                // the positions in the slice list.  The offset is relative to
                // the beginning of the slice list until the first
                // action-constrained slice is encountered, at which point the
                // offset is set to the required offset.
                int offset = 0;
                bool absolute = false;
                int size = 0;
                for (auto& slice : **slice_list) {
                    size += slice.range().size();
                    if (action_constraints->find(slice) == action_constraints->end()) {
                        offset += slice.range().size();
                        continue; }

                    int required_pos = action_constraints->at(slice).bitPosition;
                    if (!absolute && required_pos < offset) {
                        // This is the first slice with an action alignment
                        // constraint.  Check that the constraint is >= the
                        // bits seen so far.
                        LOG5("    ...action constraint: " << slice << " must be placed at bit "
                             << required_pos << " but is " << offset << "b deep in a slice list");
                        return boost::none;
                    } else if (!absolute) {
                        absolute = true;
                        offset = required_pos + slice.range().size();
                    } else if (offset != required_pos) {
                        LOG5("    ...action constraint: " << slice << " must be placed at bit "
                             << required_pos << " which conflicts with another action-induced "
                             "constraint for another slice in the slice list");
                        return boost::none;
                    } else {
                        offset += slice.range().size(); } }

                // If we've reached here, then all the slices that have
                // conditional constraints are in slice_list, and the slice
                // list must be placed with its first field starting at
                // offset - size.
                // Update the action constraints with positions for all fields
                // in the slice list.
                int required_offset = offset - size;
                action_constraints->clear();
                for (auto& slice : **slice_list) {
                    (*action_constraints)[slice] =
                        PHV::Allocation::ConditionalConstraintData(required_offset);
                    required_offset += slice.range().size(); } } }

        // Create this alloc for calculating score.
        auto this_alloc = alloc_attempt.makeTransaction();
        for (auto& slice : candidate_slices) {
            bool is_referenced = uses_i.is_referenced(slice.field());
            bool is_clot = clot_i.allocated(slice.field());
            bool is_allocated =
                previous_allocations.find(PHV::FieldSlice(slice.field(), slice.field_slice()))
                    != previous_allocations.end();
            if (is_referenced && !is_clot && !is_allocated) {
                this_alloc.allocate(slice);
            } else if (!is_referenced) {
                LOG5("NOT ALLOCATING unreferenced field: " << slice); } }

        // Recursively try to allocate slices according to conditional
        // constraints induced by actions.  NB: By allocating the current slice
        // list first, we guarantee that recursion terminates, because each
        // invocation allocates fields or fails before recursion, and there are
        // finitely many fields.
        if (action_constraints->size() > 0) {
            auto action_alloc =
                tryAllocSliceList(this_alloc, group, super_cluster, *action_constraints);
            if (!action_alloc) {
                LOG5("    ...but slice list has conditional constraints that cannot be satisfied");
                continue; }
            LOG5("    ...and conditional constraints are satisfied");
            this_alloc.commit(*action_alloc); }

        auto score = AllocScore(this_alloc, uses_i);
        LOG5("    ...SLICE LIST score: " << score);

        // update the best
        if ((!best_candidate || score > best_score)) {
            best_score = score;
            best_candidate = std::move(this_alloc); }
    }  // end of for containers

    if (!best_candidate) {
        LOG5("    ...hence there is no suitable candidate");
        return boost::none; }

    alloc_attempt.commit(*best_candidate);
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
        ordered_map<PHV::FieldSlice, int> slice_alignment;
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
            tryAllocSliceList(alloc_attempt, container_group, super_cluster, slice_alignment);
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
            boost::optional<PHV::Transaction> best_alloc = boost::none;
            AllocScore best_score = AllocScore::make_lowest();
            for (auto start : starts) {
                bool failed = false;
                auto this_alloc = alloc_attempt.makeTransaction();
                // Try allocating all fields at this alignment.
                for (const PHV::FieldSlice& slice : slice_list) {
                    // Skip fields that have already been allocated above.
                    if (allocated.find(slice) != allocated.end()) continue;
                    ordered_map<PHV::FieldSlice, int> start_map = { { slice, start } };
                    auto partial_alloc_result =
                        tryAllocSliceList(this_alloc, container_group, super_cluster, start_map);
                    if (partial_alloc_result) {
                        this_alloc.commit(*partial_alloc_result);
                    } else {
                        failed = true;
                        break; }
                }  // for slices

                if (failed) continue;
                auto score = AllocScore(this_alloc, uses_i);
                if (!best_alloc || score > best_score) {
                    best_alloc = std::move(this_alloc);
                    best_score = score; } }

            if (!best_alloc)
                return boost::none;

            alloc_attempt.commit(*best_alloc); } }

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
    // HACK WARNING:
    // The meter hack, all destination of meter color go to 8-bit container.
    // TODO(yumin): remove this once this hack is removed in mau.
    for (const auto* f : actions_i.meter_color_dests()) {
        auto* meter_color_dest = phv_i.field(f->id);
        meter_color_dest->set_no_split(true);
        pragmas_i.pa_container_sizes().add_constraint(f, { PHV::Size::b8 }); }

    LOG1(pragmas_i.pa_container_sizes());
    LOG1(pragmas_i.pa_atomic());
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
        LOG1("PHV ALLOCATION SUCCESSFUL");
        LOG2(alloc);
        LOG2(alloc.getSummary(uses_i));
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
    msg << "SuperClusters unallocated: " << std::endl;
    for (auto* sc : unallocated)
        msg << sc;
    msg << std::endl;

    if (LOGGING(3)) {
        msg << "Fields successfully allocated: " << std::endl;
        msg << alloc << std::endl; }
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
    // ::error("%1%", msg.str());
    throw Util::CompilationError("%1%", msg.str());
}

void AllocationStrategy::writeTransactionSummary(
    const PHV::Transaction& transaction,
    const std::list<PHV::SuperCluster *>& allocated) {
    report_i << transaction.getTransactionSummary() << std::endl;
    report_i << "......Allocated......." << std::endl;
    for (const auto& v : allocated) {
        report_i << v << std::endl; }
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::remove_unreferenced_clusters(
        const std::list<PHV::SuperCluster*>& cluster_groups_input) {
    std::set<PHV::SuperCluster*> un_ref_singleton;
    for (auto* super_cluster : cluster_groups_input) {
        bool should_skip = false;
        for (const auto* slice_list : super_cluster->slice_lists()) {
            bool has_referenced = false;
            bool has_unreferenced = false;
            for (const auto& slice : *slice_list) {
                if (core_alloc_i.uses().is_referenced(slice.field())) {
                    has_referenced = true;
                } else {
                    has_unreferenced = true; } }

            if (has_referenced && has_unreferenced) {
                LOG4("Unreferenced slice in slice_list as padding: " << slice_list);
                should_skip = true;
                break; } }
        // skip if unreferenced slice is used as padding in non-byte-aligned field.
        if (should_skip) continue;

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

std::vector<bitvec> BruteForceAllocationStrategy::calc_slicing_schemas(
        const PHV::SuperCluster* sc,
        const std::set<PHV::ConcreteAllocation::AvailableSpot>& spots) {
    std::vector<bitvec> rst;
    const std::vector<int> chunk_sizes = {7, 6, 5, 4, 3, 2, 1};

    auto gress = sc->gress();
    int size = sc->max_width();

    // available spots suggested slicing
    bitvec suggested_slice_schema;
    int covered_size = 0;
    for (const auto& spot : boost::adaptors::reverse(spots)) {
        if (spot.gress && spot.gress != gress) continue;
        if (spot.n_bits >= size) continue;
        if (!sc->okIn(spot.container.type().kind())) continue;
        covered_size += spot.n_bits;
        if (covered_size >= size) break;
        suggested_slice_schema.setbit(covered_size); }
    if (covered_size >= size) {
        rst.push_back(suggested_slice_schema); }

    // slice them to n-bit chunks.
    for (int sz : chunk_sizes) {
        bitvec slice_schema;
        for (int i = sz; i < sc->max_width(); i += sz) {
            slice_schema.setbit(i); }
        rst.push_back(slice_schema); }

    return rst;
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::pounderRoundAllocLoop(
        PHV::Transaction& rst,
        std::list<PHV::SuperCluster*>& cluster_groups,
        const std::list<PHV::ContainerGroup *>& container_groups) {
    // PounderRound in JBay make some tests timeout because
    // there are so many unallocated clusters in some JBay tests.
    // If there are so many unallocated clusters, pounder round is unlikely to
    // work in this case, and it might make compiler timeout.
    const int N_CLUSTER_LIMITATION = 20;
    if (cluster_groups.size() > N_CLUSTER_LIMITATION) {
        return { }; }
#if HAVE_JBAY
    if (Device::currentDevice() == "JBay") {
        return { }; }
#endif  // HAVE_JBAY

    std::list<PHV::SuperCluster*> allocated_sc;
    for (auto* sc : cluster_groups) {
        // clusters with slice lists are not considered.
        if (sc->slice_lists().size()) {
            continue; }

        auto available_spots = rst.available_spots();
        std::vector<bitvec> slice_schemas = calc_slicing_schemas(sc, available_spots);
        // Try different slicing, from large to small
        for (const auto& slice_schema : slice_schemas) {
            auto slice_rst = PHV::SlicingIterator::split_super_cluster(sc, slice_schema);
            if (!slice_rst) continue;

            if (LOGGING(5)) {
                LOG5("Pounder slicing: " << sc << " to ");
                for (auto* new_sc : *slice_rst) {
                    LOG5(new_sc); } }

            std::list<PHV::SuperCluster*> sliced_sc = *slice_rst;
            auto try_this_slicing = rst.makeTransaction();
            allocLoop(try_this_slicing, sliced_sc, container_groups);
            // succ
            if (sliced_sc.size() == 0) {
                rst.commit(try_this_slicing);
                allocated_sc.push_back(sc);
                break; } }
    }

    for (auto cluster_group : allocated_sc)
        cluster_groups.remove(cluster_group);
    return allocated_sc;
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::slice_clusters(
        const std::list<PHV::SuperCluster*>& cluster_groups) {
    LOG5("===================  Pre-Slicing ===================");
    std::list<PHV::SuperCluster*> rst;
    for (auto* sc : cluster_groups) {
        LOG5("PRESLICING " << sc);
        auto it = PHV::SlicingIterator(sc);
        std::set<const PHV::Field*> unsatisfiable_fields;
        auto& pa_container_sizes = core_alloc_i.pragmas().pa_container_sizes();
        if (!it.done()) {
            // Try until we find one satisfies pa_container_size pragmas.
            while (!it.done()) {
                pa_container_sizes.adjust_requirements(*it);
                unsatisfiable_fields = pa_container_sizes.unsatisfiable_fields(*it);
                if (unsatisfiable_fields.size() == 0) {
                    break; }
                ++it; }
            // If failed to find it, use the first slicing as pre-slicing.
            if (it.done()) {
                ::warning("%1% No way to slice to satisfy "
                          "@pa_container_size",
                          cstring::to_cstring(sc));
                it = PHV::SlicingIterator(sc);
                unsatisfiable_fields = pa_container_sizes.unsatisfiable_fields(*it); }

            LOG5("--- into new slices -->");
            for (auto* new_sc : *it) {
                LOG5(new_sc);
                rst.push_back(new_sc); }
        } else {
            unsatisfiable_fields = pa_container_sizes.unsatisfiable_fields({ sc });
            if (unsatisfiable_fields.size() > 0) {
                ::warning("%1% can not be sliced, and it can not satisfy "
                          "@pa_container_size",
                          cstring::to_cstring(sc)); }
            LOG5("    ...but preslicing failed");
            rst.push_back(sc); }
        pa_container_sizes.ignore_fields(unsatisfiable_fields); }
    return rst;
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::remove_singleton_slicelist_metadata(
        const std::list<PHV::SuperCluster*>& cluster_groups) {
    std::list<PHV::SuperCluster*> rst;
    for (auto* super_cluster : cluster_groups) {
        // Supercluster has more than one slice list.
        if (super_cluster->slice_lists().size() != 1) {
            rst.push_back(super_cluster);
            continue; }
        auto* slice_list = *super_cluster->slice_lists().begin();
        // The slice list has more than one fieldslice.
        if (slice_list->size() != 1) {
            rst.push_back(super_cluster);
            continue; }
        // The fieldslice is pov, or not metadata. Nor does supercluster is singleton.
        auto fs = slice_list->front();
        if (fs.size() != int(super_cluster->aggregate_size())
            || !fs.field()->metadata
            || fs.field()->pov) {
            rst.push_back(super_cluster);
            continue; }

        ordered_set<PHV::SuperCluster::SliceList*> empty;
        PHV::SuperCluster* new_cluster =
            new PHV::SuperCluster(super_cluster->clusters(), empty);
        rst.push_back(new_cluster);
        LOG5("Replacing singleton " << super_cluster << " with " << new_cluster);
    }
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

    // remove singleton metadata slice list
    cluster_groups = remove_singleton_slicelist_metadata(cluster_groups);

    // slice and then sort clusters.
    cluster_groups = slice_clusters(cluster_groups);
    sortClusters(cluster_groups);

    // Results are not used
    // field_interference_i.calcSliceInterference(cluster_groups);

    auto rst = alloc.makeTransaction();
    auto allocated_clusters = allocLoop(rst, cluster_groups, container_groups);

    // Pounder Round
    if (cluster_groups.size() > 0) {
        LOG5(cluster_groups.size()
             << " supercluster are unallocated before Pounder Round, they are:");
        for (auto* sc : cluster_groups) {
            LOG5(sc); }

        LOG5("Pounder Round");
        auto allocated_cluster_powders =
            pounderRoundAllocLoop(rst, cluster_groups, container_groups); }

    if (cluster_groups.size() > 0) {
        report_i << "BruteForceStrategy Allocation Failed.\n";
        writeTransactionSummary(rst, allocated_clusters);
        return AllocResult(AllocResultCode::FAIL, std::move(rst), std::move(cluster_groups));
    } else {
        return AllocResult(AllocResultCode::SUCCESS, std::move(rst), std::move(cluster_groups)); }
}

void
BruteForceAllocationStrategy::sortClusters(std::list<PHV::SuperCluster*>& cluster_groups) {
    // Critical Path result are not used.
    // auto critical_clusters = critical_path_clusters_i.calc_critical_clusters(cluster_groups);
    std::set<const PHV::SuperCluster*> has_no_pack;
    std::set<const PHV::SuperCluster*> has_no_split;
    std::map<const PHV::SuperCluster*, int> n_valid_starts;
    std::map<const PHV::SuperCluster*, int> n_required_length;
    std::set<const PHV::SuperCluster*> pounder_clusters;
    std::set<const PHV::SuperCluster*> non_slicable;

    // calc num_pack_conflicts
    for (auto* super_cluster : cluster_groups)
        super_cluster->calc_pack_conflicts();

    // calc no_pack and no_split.
    for (const auto* super_cluster : cluster_groups) {
        n_valid_starts[super_cluster] = (std::numeric_limits<int>::max)();
        for (const auto* rot : super_cluster->clusters()) {
            for (const auto* ali : rot->clusters()) {
                bitvec starts = ali->validContainerStart(PHV::Size::b32);
                int n_starts = std::accumulate(starts.begin(), starts.end(), 0,
                                               [] (int a, int) { return a + 1; });
                n_valid_starts[super_cluster] =
                    std::min(n_valid_starts[super_cluster], n_starts);

                for (const auto& slice : ali->slices()) {
                    if (slice.field()->no_pack()) {
                        has_no_pack.insert(super_cluster); }
                    if (slice.field()->no_split()) {
                        has_no_split.insert(super_cluster); } }
            } } }

    // calc pounder-able clusters.
    for (const auto* super_cluster : cluster_groups) {
        if (has_no_split.count(super_cluster) || has_no_pack.count(super_cluster)) continue;
        if (super_cluster->exact_containers()) continue;
        if (n_valid_starts[super_cluster] <= 4) continue;
        if (super_cluster->slice_lists().size() > 1) continue;

        bool is_candidate = true;

        for (const auto* slice_list : super_cluster->slice_lists()) {
            if (slice_list->size() > 1) is_candidate = false; }

        for (const auto* rot : super_cluster->clusters()) {
            for (const auto* ali : rot->clusters()) {
                if (ali->slices().size() > 1) is_candidate = false;
                for (const auto& fs : ali->slices()) {
                    // pov bits are not
                    if (fs.field()->pov) {
                        is_candidate = false; } } } }

        if (!is_candidate) continue;
        pounder_clusters.insert(super_cluster);
    }

    // calc non_slicable clusters
    // i.e. 8-bit and exact container required.
    for (const auto* super_cluster : cluster_groups) {
        for (const auto* slice_list : super_cluster->slice_lists()) {
            BUG_CHECK(slice_list->size() > 0, "empty slice list");
            int length = std::accumulate(
                    slice_list->begin(), slice_list->end(), 0,
                    [] (int a, const PHV::FieldSlice& b) { return a + b.size(); });
            if (slice_list->front().field()->exact_containers()
                && length == 8) {
                non_slicable.insert(super_cluster);
                break; }
        } }

    // calc required_length, i.e. max(max{fieldslice.size()}, {slicelist.size()}).
    for (const auto* super_cluster : cluster_groups) {
        n_required_length[super_cluster] = super_cluster->max_width();
        for (const auto* slice_list : super_cluster->slice_lists()) {
            BUG_CHECK(slice_list->size() > 0, "empty slice list");
            int length = std::accumulate(
                    slice_list->begin(), slice_list->end(), 0,
                    [] (int a, const PHV::FieldSlice& b) { return a + b.size(); });
            n_required_length[super_cluster] =
                std::max(n_required_length[super_cluster], length);
        } }

    auto ClusterGroupComparator = [&] (PHV::SuperCluster* l, PHV::SuperCluster* r) {
        if (has_no_pack.count(l) != has_no_pack.count(r)) {
            return has_no_pack.count(l) > has_no_pack.count(r); }
        if (has_no_split.count(l) != has_no_split.count(r)) {
            return has_no_split.count(l) > has_no_split.count(r); }
        if (non_slicable.count(l) != non_slicable.count(r)) {
            return non_slicable.count(l) > non_slicable.count(r); }
        if (pounder_clusters.count(l) != pounder_clusters.count(r)) {
            return pounder_clusters.count(l) < pounder_clusters.count(r); }
        if (bool(l->exact_containers()) != bool(r->exact_containers())) {
            return bool(l->exact_containers()) > bool(r->exact_containers()); }
        // if it's header fields
        if (bool(l->exact_containers())) {
            if (n_required_length[l] != n_required_length[r]) {
                return n_required_length[l] < n_required_length[r]; }
            if (l->slice_lists().size() != r->slice_lists().size()) {
                return l->slice_lists().size() > r->slice_lists().size(); }
        } else {
            // for non header field, aggregate size matters
            if (n_valid_starts.at(l) != n_valid_starts.at(r)) {
                return n_valid_starts.at(l) < n_valid_starts.at(r); }
            if (l->aggregate_size() != r->aggregate_size()) {
                return l->aggregate_size() > r->aggregate_size(); }
            if (n_required_length[l] != n_required_length[r]) {
                return n_required_length[l] < n_required_length[r]; }
        }
        if (l->num_pack_conflicts() != r->num_pack_conflicts()) {
            return l->num_pack_conflicts() > r->num_pack_conflicts(); }
        // if (critical_clusters.count(l) != critical_clusters.count(r)) {
        //     return critical_clusters.count(l) > critical_clusters.count(r); }
        if (l->num_constraints() != r->num_constraints()) {
            return l->num_constraints() > r->num_constraints(); }
        // if (l->max_width() != r->max_width()) {
        //     return l->max_width() > r->max_width(); }
        return false;
    };
    cluster_groups.sort(ClusterGroupComparator);

    if (LOGGING(5)) {
        LOG5("============ Sorted SuperClusters ===============");
        int i = 0;
        std::stringstream logs;
        for (const auto& v : cluster_groups) {
            ++i;
            logs << i << "th "<< " [";
            logs << "is_no_pack: "             << has_no_pack.count(v) << ", ";
            logs << "is_no_split: "            << has_no_split.count(v) << ", ";
            logs << "is_non_slicable: "       << non_slicable.count(v) << ", ";
            logs << "is_exact_container: "    << v->exact_containers() << ", ";
            logs << "is_pounderable: "        << pounder_clusters.count(v) << ", ";
            logs << "required_length: "       << n_required_length[v] << ", ";
            logs << "n_valid_starts: "        << n_valid_starts[v] << ", ";
            logs << "]\n";
            logs << v; }
        LOG5(logs.str());
        LOG5("========== end Sorted SuperClusters ============="); }
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::allocLoop(PHV::Transaction& rst,
                                        std::list<PHV::SuperCluster*>& cluster_groups,
                                        const std::list<PHV::ContainerGroup *>& container_groups) {
    const int MAX_SLICING_TRY = 65535;
    std::stringstream alloc_history;
    std::list<PHV::SuperCluster*> allocated;
    for (PHV::SuperCluster* cluster_group : cluster_groups) {
        alloc_history << "TRYING to allocate " << cluster_group;
        LOG5("TRYING to allocate " << cluster_group);
        auto best_score = AllocScore::make_lowest();
        boost::optional<PHV::Transaction> best_alloc = boost::none;
        boost::optional<std::list<PHV::SuperCluster*>> best_slicing = boost::none;

        // Try all possible slicings.
        auto slice_it = PHV::SlicingIterator(cluster_group);
        int n_tried = 0;
        if (slice_it.done())
            LOG4("    ...but there are no valid slicings");
        while (!slice_it.done()) {
            auto slicing_alloc = rst.makeTransaction();
            // Place all slices, then get score for that placement.
            bool succeeded = true;
            for (auto* sc : *slice_it) {
                // Find best container group for this slice.
                auto best_slice_score = AllocScore::make_lowest();
                boost::optional<PHV::Transaction> best_slice_alloc = boost::none;
                for (PHV::ContainerGroup* container_group : container_groups) {
                    LOG4(container_group);
                    if (auto partial_alloc =
                            core_alloc_i.tryAlloc(slicing_alloc, *container_group, *sc)) {
                        AllocScore score = AllocScore(*partial_alloc, core_alloc_i.uses());
                        LOG4("    ...SUPERCLUSTER score: " << score);
                        if (!best_slice_alloc || score > best_slice_score) {
                            best_slice_score = score;
                            best_slice_alloc = partial_alloc; } } }

                // Break if this slice couldn't be placed.
                if (best_slice_alloc == boost::none) {
                    succeeded = false;
                    break; }

                // Otherwise, update the score.
                slicing_alloc.commit(*best_slice_alloc); }

            // If allocation succeeded, check the score.
            auto slicing_score = AllocScore(slicing_alloc, core_alloc_i.uses());
            LOG4("Best SUPERCLUSTER score: " << slicing_score);
            if (succeeded && (!best_alloc || slicing_score > best_score)) {
                best_score = slicing_score;
                best_alloc = slicing_alloc;
                best_slicing = *slice_it;
            }

            // Try the next slice.
            ++slice_it;
            ++n_tried;
            if (n_tried >= MAX_SLICING_TRY) {
                break; }
        }

        // If any allocation was found, commit it.
        if (best_alloc) {
            if (LOGGING(4)) {
                LOG4("SUCCESSFULLY allocated " << cluster_group);
                LOG4("by slicing it into the following superclusters:");
                for (auto* sc : *best_slicing)
                    LOG5(sc);
                LOG4("SCORE: " << best_score); }
            rst.commit(*best_alloc);
            allocated.push_back(cluster_group);
            alloc_history << "SUCCESSFULLY" << std::endl;
            alloc_history << rst.getTransactionSummary() << std::endl;
        } else {
            LOG4("FAILED to allocate " << cluster_group);
            LOG4("when the things are like: ");
            LOG4(rst.getTransactionSummary());
            alloc_history << "FAILED" << std::endl;
            alloc_history << rst.getTransactionSummary() << std::endl;
        } }


    // XXX(cole): There must be a better way to remove elements from a list
    // while iterating, but `it = clusters_i.erase(it)` skips elements.
    for (auto cluster_group : allocated)
        cluster_groups.remove(cluster_group);
    LOG5("Allocation History");
    LOG5(alloc_history.str());
    return allocated;
}
