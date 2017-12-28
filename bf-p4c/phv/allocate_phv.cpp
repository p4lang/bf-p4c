#include "allocate_phv.h"
#include <boost/format.hpp>
#include <boost/range/adaptor/reversed.hpp>
#include <numeric>
#include "lib/log.h"

/** Implements a dynamic programming algorithm for determining the best way to
 * slice fields in a field list to produce container-sized chunks of the field
 * list.  Prefers (a) minimizing the number of fields split, then (b) using the
 * largest container sizes.
 */
class SplitSliceList {
    const PHV::SuperCluster& super_cluster;
    const PHV::SuperCluster::SliceList& slice_list;
    int max_split;

    /// For a given slice list, maps a range of bits of the slice list to the
    /// best bit positions to slice.  An empty bitvec implies slicing is not
    /// needed, while boost::none implies slicing is necessary but impossible.
    ordered_map<le_bitrange, boost::optional<bitvec>> best_subslice;

    /// Map the absolute bit position within a slice list to the corresponding
    /// relative position of the field at that position.
    ordered_map<int, std::pair<PHV::FieldSlice, int>> absolute_to_relative;

    /// The range of the entire slice list.
    le_bitrange slice_list_range;

    /// Categorizes the quality of a given split.
    enum class SplitKind {
        NONE = 0,       // no split found
        FIELD = 1,      // found a split, but it splits a field
        BOUNDARY = 2,   // found a split, and it splits the slice list between
                        // slices---the best option
    };

    /// Recursive method that builds `best_subslice`.
    boost::optional<bitvec> find_best_subslice(le_bitrange range) {
        // If we have already computed the best subslice for this range,
        // return.
        if (best_subslice.find(range) != best_subslice.end())
            return best_subslice.at(range);

        // Otherwise, try slicing off 8b, 16b, and 32b chunks and recursing.
        auto chunks = { int(PHV::Size::b32),
                        int(PHV::Size::b16),
                        int(PHV::Size::b8) };
        auto kind = SplitKind::NONE;
        for (int chunk : chunks) {
            // We can't create slices larger than max_split.
            if (max_split < chunk)
                continue;

            // We can't do better than fitting range exactly in a container.
            if (range.size() == chunk) {
                best_subslice[range] = bitvec();
                return bitvec(); }

            // Ditto for ranges smaller than chunk that don't have any
            // exact_containers requirements.
            if (range.size() < chunk) {
                bool has_exact = false;
                for (int i = range.lo; i <= range.hi /* closed range */; ++i) {
                    BUG_CHECK(absolute_to_relative.find(i) != absolute_to_relative.end(),
                              "Looking for bad slice %1% of slice list %2%",
                              cstring::to_cstring(range), cstring::to_cstring(slice_list));
                    if (absolute_to_relative.at(i).first.field()->exact_containers())
                        has_exact = true; }
                if (has_exact) {
                    // Can't put a slice list in a chunk size (i.e. container size) larger
                    // than the list width if it has an exact_container requirement.
                    continue;
                } else {
                    best_subslice[range] = bitvec();
                    return bitvec(); } }

            BUG_CHECK(absolute_to_relative.find(chunk) != absolute_to_relative.end(),
                      "Looking for bad split (%1%) of slice list %2%",
                      chunk, cstring::to_cstring(slice_list));

            // Otherwise, try slicing of the first chunk of the range.
            auto& local_info = absolute_to_relative.at(chunk);
            if (local_info.second == 0) {
                kind = SplitKind::BOUNDARY;
            } else {
                // If the split isn't along a slice boundary, and the cluster
                // containing the slice to be split can't support the split,
                // then continue.
                if (!super_cluster.cluster(local_info.first).slice(chunk))
                    continue;
                kind = SplitKind::FIELD;
            }
            le_bitrange lo_range = range.resizedToBits(chunk);
            le_bitrange hi_range = range.shiftedByBits(chunk).resizedToBits(range.size() - chunk);
            auto lo_res = find_best_subslice(lo_range);
            auto hi_res = find_best_subslice(hi_range);
            if (!lo_res || !hi_res) {
                best_subslice[range] = boost::none;
            } else if (kind == SplitKind::BOUNDARY) {
                best_subslice[range] = *lo_res | *hi_res | bitvec(chunk, 1);
                break;
            } else if (best_subslice.find(range) != best_subslice.end() &&
                       best_subslice.at(range)) {
                // Determine whether this slice is better than previous slices by counting
                // the number of bits in each bitvec; lower (fewer slices) is better.
                auto GetSize = [](int acc, int) { return acc + 1; };
                int count = std::accumulate(lo_res->begin(), lo_res->end(), 0, GetSize)
                          + std::accumulate(hi_res->begin(), hi_res->end(), 0, GetSize)
                          + 1;
                bitvec other = *best_subslice.at(range);
                int other_count = std::accumulate(other.begin(), other.end(), 0, GetSize);
                if (count < other_count)
                    best_subslice[range] = *lo_res | *hi_res | bitvec(chunk, 1);
            } else {
                best_subslice[range] = *lo_res | *hi_res | bitvec(chunk, 1);
            }
        }

        // If we haven't yet found a best subslice for this range, it means
        // none exists, eg. because the range includes slices with
        // exact_container requirements but doesn't match a container width.
        if (best_subslice.find(range) == best_subslice.end())
            best_subslice[range] = boost::none;

        return best_subslice.at(range);
    }

 public:
    explicit SplitSliceList(
            const PHV::SuperCluster& sc,
            const PHV::SuperCluster::SliceList& slice_list,
            int max_split)
            : super_cluster(sc), slice_list(slice_list), max_split(max_split) {
        int pos = 0;
        for (auto& slice : slice_list)
            for (int i = 0; i < slice.range().size(); ++i, ++pos)
                absolute_to_relative.emplace(pos, std::make_pair(slice, i));
        slice_list_range = StartLen(0, pos);
    }

    // Return the best position to split each field slice.
    boost::optional<ordered_map<const PHV::FieldSlice, int>> find_best_slicing() {
        ordered_map<const PHV::FieldSlice, int> rv;
        auto res = find_best_subslice(slice_list_range);
        // No valid split locations.
        if (!res)
            return boost::none;
        // No split needed.
        if (res->empty())
            return rv;

        int list_offset = 0;
        auto list_it = slice_list.begin();
        for (int split_loc : *res) {
            // Find field at split_loc.
            while (split_loc >= list_offset + list_it->size()) {
                list_offset += list_it->size();
                list_it++;
                BUG_CHECK(list_it != slice_list.end(), "Bad slice schema"); }
            int relative_offset = split_loc - list_offset;
            // If the relative offset is 0, then this split lies on a slice
            // boundary, and no slice needs to be split.
            if (relative_offset > 0)
                rv[*list_it] = relative_offset; }
        return rv;
    }
};

namespace PHV {
// Helper for split_super_cluster;
using ListClusterPair = std::pair<PHV::SuperCluster::SliceList*, const PHV::RotationalCluster*>;
std::ostream &operator<<(std::ostream &out, const ListClusterPair& pair) {
    out << "(" << pair.first << ", " << pair.second << ")";
    return out;
}
std::ostream &operator<<(std::ostream &out, const ListClusterPair* pair) {
    if (pair)
        out << *pair;
    else
        out << "-null-listclusterpair-";
    return out;
}

}  // namespace PHV

/* static */
std::list<PHV::SuperCluster*> CoreAllocation::split_super_cluster(PHV::SuperCluster* sc) {
    // XXX(cole): This is a heuristic that splits the SuperCluster into the
    // largest container-sized slices.  We'll need to do something more
    // sophisticated in the future.

    LOG5("Trying to slice supercluster with max field slice width of " << sc->max_width() << ":");
    LOG5(sc);

    std::list<PHV::SuperCluster*> rv;
    int max_split = int(PHV::Size::b32);
    ordered_set<PHV::SuperCluster::SliceList*> slice_lists;
    for (auto* slice_list : sc->slice_lists()) {
        slice_lists.insert(slice_list);
        int size = 0;
        for (auto& slice : *slice_list)
            size += slice.size();
        if (size <= int(PHV::Size::b8))
            max_split = int(PHV::Size::b8);
        else if (size <= int(PHV::Size::b16))
            max_split = std::min(max_split, int(PHV::Size::b16)); }

    // Find a slice list that needs to be split, if any.
    boost::optional<ordered_map<const PHV::FieldSlice, int>> split_schema = boost::none;
    for (auto* slice_list : slice_lists) {
        LOG5("    ...considering splitting (max chunk " << max_split << ") " << slice_list);

        // XXX(cole): We don't handle splitting slice lists with multiple slices
        // from the same rotational cluster yet.
        ordered_set<const PHV::RotationalCluster*> seen;
        for (auto& slice : *slice_list) {
            auto* cluster = &sc->cluster(slice);
            if (seen.find(cluster) != seen.end()) {
                LOG5("    ...but cannot split superclusters with slice lists with slices from the "
                     "same rotational cluster");
                return { sc }; }
            seen.insert(cluster); }

        SplitSliceList splitter(*sc, *slice_list, max_split);
        split_schema = splitter.find_best_slicing();
        if (!split_schema) {
            LOG5("    ...but slice list cannot be split");
            continue;
        } else if (split_schema->empty()) {
            LOG5("    ...but slice list does not need to be split");
            continue;
        } else {
            break; } }

    bool found_slicing_schema = split_schema && !split_schema->empty();

    // If this SuperCluster contains slice lists, but no split could be found,
    // then return.
    if (slice_lists.size() && !found_slicing_schema) {
        LOG5("    ...no slicing schema found");
        return { sc }; }

    // If there is a split schema, then at least one slice list needs to be
    // split.  Split all clusters of slices in the split schema, create new
    // SuperClusters, and invoke this method recursively.
    if (found_slicing_schema) {
        // Track live clusters. Clusters that have been split are no longer live.
        ordered_set<const PHV::RotationalCluster*> new_clusters;
        new_clusters.insert(sc->clusters().begin(), sc->clusters().end());

        // Keep a map of slices to clusters (both old and new).
        ordered_map<const PHV::FieldSlice, const PHV::RotationalCluster*> slices_to_clusters;
        for (auto* slice_list : slice_lists)
            for (auto& slice : *slice_list)
                slices_to_clusters[slice] = &sc->cluster(slice);

        // Slice each field in the split schema.
        for (auto& kv : *split_schema) {
            auto& slice = kv.first;
            int split_pos = kv.second;
            LOG5("    ...and trying to split slice " << slice << " at bit " << split_pos);
            BUG_CHECK(slices_to_clusters.find(slice) != slices_to_clusters.end(),
                      "Slice in split schema but not in slice list");
            auto rotational = slices_to_clusters.at(slice);
            auto split_res = rotational->slice(split_pos);
            BUG_CHECK(split_res, "Bad split schema: failed to slice cluster");
            BUG_CHECK(split_res->slice_map.find(slice) != split_res->slice_map.end(),
                      "Bad split schema: slice map does not contain split slice");

            // Update the set of live clusters.
            auto old = new_clusters.find(rotational);
            if (old != new_clusters.end())
                new_clusters.erase(old);
            new_clusters.insert(split_res->lo);
            new_clusters.insert(split_res->hi);

            for (auto& kv : split_res->slice_map) {
                auto& slice_lo = kv.second.first;
                auto& slice_hi = kv.second.second;
                slices_to_clusters[slice_lo] = split_res->lo;
                slices_to_clusters[slice_hi] = split_res->hi; }

            // Replace the old slice with the new, split slices in each slice
            // list.
            for (auto* slice_list : slice_lists) {
                for (auto slice_it  = slice_list->begin();
                          slice_it != slice_list->end();
                          slice_it++) {
                    if (split_res->slice_map.find(*slice_it) != split_res->slice_map.end()) {
                        auto& slice_lo = split_res->slice_map.at(*slice_it).first;
                        auto& slice_hi = split_res->slice_map.at(*slice_it).second;
                        slice_it = slice_list->erase(slice_it);
                        slice_it = slice_list->insert(slice_it, slice_lo);
                        slice_it++;
                        slice_it = slice_list->insert(slice_it, slice_hi); } } } }

        // Create new slice lists by breaking existing slice lists at container
        // boundaries.
        ordered_set<PHV::SuperCluster::SliceList*> new_slice_lists;
        ordered_map<const PHV::FieldSlice, ordered_set<PHV::SuperCluster::SliceList*>>
            slices_to_lists;
        for (auto* slice_list : slice_lists) {
            auto* new_slice_list = new PHV::SuperCluster::SliceList();
            int list_size = 0;
            for (auto& slice : *slice_list) {
                LOG5("    ...adding slice " << slice);
                new_slice_list->push_back(slice);
                slices_to_lists[slice].insert(new_slice_list);
                list_size += slice.size();
                if (list_size == int(PHV::Size::b8) ||
                    list_size == int(PHV::Size::b16) ||
                    list_size == int(PHV::Size::b32)) {
                    new_slice_lists.insert(new_slice_list);
                    LOG5("    ...new slice list: " << new_slice_list);
                    new_slice_list = new PHV::SuperCluster::SliceList();
                    list_size = 0; } }
            if (new_slice_list->size() > 0) {
                LOG5("    ...new slice list: " << new_slice_list);
                new_slice_lists.insert(new_slice_list); } }

        // We need to ensure that all the slice lists and clusters that overlap
        // (i.e. share slices) end up in the same SuperCluster.
        UnionFind<PHV::ListClusterPair> uf;
        ordered_map<PHV::FieldSlice, ordered_set<PHV::SuperCluster::SliceList*>>
            slices_to_slice_lists;

        // Populate UF universe.
        auto* empty_slice_list = new PHV::SuperCluster::SliceList();
        for (auto* slice_list : new_slice_lists) {
            for (auto& slice : *slice_list) {
                BUG_CHECK(slices_to_clusters.find(slice) != slices_to_clusters.end(),
                          "No slice to cluster map for %1%", cstring::to_cstring(slice));
                auto* cluster = slices_to_clusters.at(slice);
                uf.insert({ slice_list, cluster });
                new_clusters.insert(cluster);
                slices_to_slice_lists[slice].insert(slice_list); } }
        for (auto* rotational : new_clusters)
            uf.insert({ empty_slice_list, rotational });

        // Union over slice lists.
        for (auto* slice_list : new_slice_lists) {
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
            auto rec =
                split_super_cluster(new PHV::SuperCluster(clusters, slice_lists));
            rv.insert(rv.end(), rec.begin(), rec.end()); }

        return rv; }

    // XXX(cole): Clean up this method and break it into smaller methods.

    // Otherwise, if this SuperCluster doesn't have any slice lists, then slice
    // the rotational clusters directly.
    int remaining_width = sc->max_width();
    ordered_set<const PHV::RotationalCluster*> to_slice;
    to_slice.insert(sc->clusters().begin(), sc->clusters().end());

    while (remaining_width > 0) {
        // Get the remaining bits of the smallest field slice that requires
        // exact containers and has bits remaining.
        // XXX(cole): Should cache this.
        int min_remaining = remaining_width;
        for (auto* rot : to_slice)
            for (auto* aln : rot->clusters())
                for (auto& slice : *aln)
                    if (slice.field()->exact_containers())
                        min_remaining = std::min(min_remaining, slice.size());

        // If the widest slice is exactly a container size or smaller than 8b,
        // then we're done.  Otherwise, decide the next split size.
        int chunk;
        if (min_remaining < int(PHV::Size::b16)) {
            chunk = int(PHV::Size::b8);
        } else if (min_remaining < int(PHV::Size::b32)) {
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
        ordered_set<const PHV::RotationalCluster*> container_sized_clusters;
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
bool CoreAllocation::can_overlay(
        SymBitMatrix mutex,
        const PHV::Field* f,
        const ordered_set<PHV::AllocSlice>& slices) {
    for (auto slice : slices) {
        if (!PHV::Allocation::mutually_exclusive(mutex, f, slice.field()))
            return false; }
    return true;
}

bitvec CoreAllocation::satisfies_constraints(
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
    if (alloc.gress(c) && *alloc.gress(c) != f->gress)
        return false;
    return true;
}

/* static */
bool
CoreAllocation::satisfies_constraints(const PHV::ContainerGroup& g, const PHV::SuperCluster& sc) {
    // Check max individual field width.
    if (int(g.type().size()) < sc.max_width())
        return false;

    // Check max slice list width.
    for (auto* slice_list : sc.slice_lists()) {
        int size = 0;
        for (auto& slice : *slice_list)
            size += slice.size();
        if (int(g.type().size()) < size)
            return false; }

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
boost::optional<std::pair<PHV::Transaction, CoreAllocation::MatchScore>>
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
    if (slices.size() == 1 && slices.front().field()->is_ccgf()) {
        auto rst = tryAllocCCGF(alloc, group, phv_i.field(slices.front().field()->id),
                start_positions.at(slices.front()));
        if (!rst) return boost::none;
        return std::make_pair(*rst, MatchScore(0, 0)); }

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
    MatchScore best_score(0, 0);
    boost::optional<std::vector<PHV::AllocSlice>> candidate = boost::none;
    for (const PHV::Container c : group) {
        std::vector<PHV::AllocSlice> alloc_slices;
        int n_packings = int(alloc_attempt.slices(c).size() > 0);  // 1: hasPacking, 0: not.
        MatchScore score(0 , n_packings);

        // If we already have a candidate and this is an empty container, skip it.
        if (candidate && n_packings == 0) continue;

        // Generate alloc_slices if we choose this container.
        for (auto& field_slice : slices) {
            le_bitrange container_slice =
                StartLen(start_positions.at(field_slice), field_slice.size());
            // Field slice has a const Field*, so get the non-const version using the PhvInfo object
            alloc_slices.push_back(PHV::AllocSlice(phv_i.field(field_slice.field()->id),
                        c, field_slice.range(), container_slice)); }

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

        // In case there are multiple members in alloc_slices, need to check how their packing is
        // affected by action induced constraints
        if (alloc_slices.size() > 1) {
            boost::optional<UnionFind<PHV::FieldSlice>> rv = actions_i.can_pack(alloc_attempt,
                    alloc_slices);
            if (!rv) {
                LOG5("        ...action constraint: cannot pack into container " << c);
                continue;
            } else {
                LOG5("        ...action constraint: can pack into container " << c); } }

        auto calc_overlay_length = [&] (const PHV::AllocSlice& slice,
                                        const ordered_set<PHV::AllocSlice>& alloced_slices) {
            bitvec allocatedBits;
            bitvec slice_vec = bitvec(slice.container_slice().lo,
                                      slice.container_slice().size());
            int n_overlays = 0;
            for (auto s : alloced_slices) {
                allocatedBits |= bitvec(s.container_slice().lo, s.container_slice().size()); }
            for (const int i : slice_vec) {
                if (!allocatedBits[i]) n_overlays++; }
            return n_overlays;
        };

        // Check that there's space.
        bool can_place = true;
        for (auto& slice : alloc_slices) {
            const auto& alloced_slices =
                alloc_attempt.slices(slice.container(), slice.container_slice());
            if (alloced_slices.size() > 0 && can_overlay(mutex_i, slice.field(), alloced_slices)) {
                score.n_overlays += calc_overlay_length(slice, alloced_slices);
            } else if (alloced_slices.size() > 0) {
                LOG5("    ...but " << c << " already contains " << alloced_slices);
                can_place = false;
                break; } }
        if (!can_place) continue;  // try next container

        // update the best
        if ((!candidate || best_score < score)) {
            best_score = score;
            candidate = alloc_slices; } }  // end of for containers

    if (!candidate) {
        LOG5("    ...hence there is no suitable candidate");
        return boost::none; }

    for (auto& slice : *candidate) {
        // XXX(cole): This ignores the no deadcode elimination compiler flag!
        // It should be fixed when parser/deparser schema are introduced.
        if (uses_i.is_referenced(slice.field()) && !clot_i.allocated(slice.field()))
            alloc_attempt.allocate(slice); }
    return std::make_pair(alloc_attempt, best_score);
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
        auto partial_alloc_result =
            tryAllocSliceList(alloc_attempt, container_group, *slice_list, slice_alignment);
        if (!partial_alloc_result)
            return boost::none;
        alloc_attempt.commit((*partial_alloc_result).first);

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
                starts = satisfies_constraints(container_group, *aligned_cluster); }

            // Compute all possible alignments
            // need this because Transaction is non-copyable somehow
            // DO NOT change this std::list to std::vector, iterators are kept.
            boost::optional<std::list<PHV::Transaction>::iterator> best_alloc = boost::none;
            std::list<PHV::Transaction> alloc_results;
            MatchScore best_score(0, 0);
            for (auto start : starts) {
                bool failed = false;
                alloc_results.emplace_back(alloc_attempt.makeTransaction());
                auto possible_alloc = std::prev(alloc_results.end());
                MatchScore score(0, 0);
                for (const PHV::FieldSlice &slice : slice_list) {
                // for (const PHV::FieldSlice &slice : aligned_cluster->slices()) {
                    // Skip fields that have already been allocated above.
                    if (allocated.find(slice) != allocated.end()) continue;
                    ordered_map<const PHV::FieldSlice, int> start_map = { { slice, start } };
                    auto partial_alloc_result =
                        tryAllocSliceList(*possible_alloc, container_group, {slice}, start_map);
                    if (partial_alloc_result) {
                        (*possible_alloc).commit((*partial_alloc_result).first);
                        score += (*partial_alloc_result).second;
                    } else {
                        failed = true;
                        break; }
                }  // for slices
                if (failed) continue;
                if (!best_alloc || best_score < score) {
                    // Since we can't copy/move transaction,
                    // we create a new transaction and commit the best result in.
                    // so, just treat it as best_alloc = possible_alloc.
                    best_alloc = possible_alloc;
                    best_score = score; }
            }  // for starts
            if (!best_alloc) return boost::none;
            alloc_attempt.commit(*(best_alloc.value()));
        }  // for aligned_cluster
    }  // for rotational_cluster
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

    auto alloc = make_concrete_allocation();
    auto container_groups = makeDeviceContainerGroups();
    std::list<PHV::SuperCluster*> cluster_groups = make_cluster_groups();
    std::stringstream report;

    AllocationStrategy *strategy = new GreedySortingAllocationStrategy(core_alloc_i, report);
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
        msg << alloc << std::endl; }

    for (auto* super_cluster : unallocated) {
        msg << super_cluster << std::endl;
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
    for (auto* sc : cluster_groups_input)
        for (auto* new_sc : CoreAllocation::split_super_cluster(sc))
            cluster_groups.push_back(new_sc);

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
    for (auto* sc : cluster_groups_input)
        for (auto* new_sc : CoreAllocation::split_super_cluster(sc))
                cluster_groups.push_back(new_sc);

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
