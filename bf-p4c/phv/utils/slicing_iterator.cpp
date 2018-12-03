#include "bf-p4c/phv/utils/slicing_iterator.h"
#include "bf-p4c/lib/union_find.hpp"

cstring PHV::SlicingIterator::get_slice_coordinates(
        const int slice_list_size,
        const std::pair<int, int>& slice_locations) const {
    std::stringstream ss;
    ss << slice_list_size << "b, " << slice_locations.first << "L, " << slice_locations.second <<
        "R.";
    return ss.str();
}

PHV::SlicingIterator::SlicingIterator(
        const SuperCluster* sc,
        const std::map<const PHV::Field*, std::vector<PHV::Size>>& pa,
        bool e)
        : sc_i(sc), enforcePragmas(e), done_i(false) {
    LOG5("Making SlicingIterator for SuperCluster:");
    LOG5(sc);
    num_slicings = 0;

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

        // Map of field slice to its byte location; the value pair is [left byte, right byte] within
        // within the slicing schema. If the field is the first field in the slice list, the left
        // byte is set to -1; similarly, the right byte is set to -1 if the field is the last field
        // in the slice list. The first and last field slices are special because we always
        // pre-slice the supercluster before the first field slice and after the last field slice in
        // that supercluster.
        ordered_map<FieldSlice, std::pair<int, int>> sliceLocations;

        // Map of field slice to the size of the slice list it is in. The field slices in this map
        // must belong to slice lists that have an exact containers requirement.
        ordered_map<FieldSlice, int> exactSliceListSize;

        // List of compiler-inserted padding fields encountered in this supercluster.
        ordered_set<FieldSlice> paddingFields;

        // Map of slice list to a pair <starting offset within bitvec for slice list, bitvec size
        // required for that slice list>.
        ordered_map<const PHV::SuperCluster::SliceList*, std::pair<int, int>> sliceListDetails;

        // Map of slice to offset within its original slice list.
        ordered_map<FieldSlice, std::pair<int, int>> originalSliceOffset;

        // List of all slice lists that have exact containers requirement. We will sort these slice
        // lists in order of decreasing to increasing slice list slice later.
        std::list<PHV::SuperCluster::SliceList*> candidateSliceLists;

        int offset = populate_initial_maps(candidateSliceLists, sliceLocations, exactSliceListSize,
                            paddingFields, sliceListDetails, originalSliceOffset, pa);

        if (LOGGING(5)) {
            LOG5("\tPrinting slicing related information for each slice in the format " <<
                 "SLICE : sliceListSize, left limit, right limit");
            for (auto kv : exactSliceListSize)
                LOG5("\t  " << get_slice_coordinates(kv.second, sliceLocations[kv.first]) <<
                     "\t:\t" << kv.first); }

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

        // Sort all the slice lists with exact containers requirement in increasing order of slice
        // list size.
        auto SliceListComparator =
            [&](PHV::SuperCluster::SliceList* s1,
                PHV::SuperCluster::SliceList* s2) {
            FieldSlice& slice1 = *(s1->begin());
            FieldSlice& slice2 = *(s2->begin());
            BUG_CHECK(exactSliceListSize.count(slice1), "No entry in exactSliceListSize map");
            BUG_CHECK(exactSliceListSize.count(slice2), "No entry in exactSliceListSize map");
            return exactSliceListSize.at(slice1) < exactSliceListSize.at(slice2);
        };
        candidateSliceLists.sort(SliceListComparator);

        for (auto it = candidateSliceLists.begin(); it != candidateSliceLists.end(); ++it)
            LOG1(**it);

        impose_MAU_constraints(candidateSliceLists, sliceLocations, exactSliceListSize,
                paddingFields, originalSliceOffset);

        // Break 24b slice lists into 16b and 8b slices appropriately (only check is that the
        // slicing should not be in the middle of a slice).
        break_24b_slice_lists(exactSliceListSize, sliceLocations, originalSliceOffset);

        if (LOGGING(5)) {
            LOG5("\tPrinting slicing related information for each slice in the format " <<
                 "SLICE : sliceListSize, left limit, right limit");
            for (auto kv : exactSliceListSize)
                LOG5("\t  " << get_slice_coordinates(kv.second, sliceLocations[kv.first]) <<
                     "\t:\t" << kv.first); }

        candidateSliceLists.sort(SliceListComparator);

        // We need a second round of impose_MAU_constraints to take into account the new constraints
        // imposed by the 24b slicing.
        impose_MAU_constraints(candidateSliceLists, sliceLocations, exactSliceListSize,
                paddingFields, originalSliceOffset);

        if (LOGGING(5)) {
            LOG5("\tPrinting slicing related information for each slice in the format " <<
                 "SLICE : sliceListSize, left limit, right limit");
            for (auto kv : exactSliceListSize)
                LOG5("\t  " << get_slice_coordinates(kv.second, sliceLocations[kv.first]) <<
                     "\t:\t" << kv.first); }

        if (LOGGING(6)) {
            std::stringstream ss;
            for (int i = 0; i < sentinel_idx_i; ++i)
                ss << (required_slices_i[i] ? "1" : "-");
            LOG6("Initial compressed schemas before enforcing pragmas: " << ss.str()); }

        // Enforce the slicing imposed by pa_container_size pragmas specified by the programmer.
        if (enforcePragmas)
            enforce_container_size_pragmas(sliceListDetails);

        compressed_schemas_i = required_slices_i;

        if (LOGGING(6)) {
            std::stringstream ss;
            for (int i = 0; i < sentinel_idx_i; ++i)
                ss << (compressed_schemas_i[i] ? "1" : "-");
            LOG6("Initial compressed schemas before enforcing containers: " << ss.str()); }

        // Start with the smallest number that has sequences of exactly zero,
        // one, or three zeroes, which corresponds to slices sizes of 8b, 16b,
        // and 32b.  @see PHV::inc().
        PHV::enforce_container_sizes(compressed_schemas_i,
                                     sentinel_idx_i,
                                     boundaries_i,
                                     required_slices_i,
                                     exact_containers_i);

        if (LOGGING(6)) {
            std::stringstream ss;
            for (int i = 0; i < sentinel_idx_i; ++i)
                ss << (compressed_schemas_i[i] ? "1" : "-");
            LOG6("Initial compressed schemas after enforcing containers: " << ss.str()); }
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
        LOG6("Initial compressed schema: " << compressed_schemas_i);
        std::stringstream ss;
        for (int i = 0; i < sentinel_idx_i; ++i)
            ss << (compressed_schemas_i[i] ? "1" : "-");
        LOG6("Initial compressed schemas: " << ss.str()); }

    // Look for the first valid slicing.
    if (auto res = get_slices()) {
        cached_i = *res;
        LOG6("FOUND VALID SLICING");
    } else {
        LOG6("DID NOT FIND VALID SLICING");
        this->operator++();
    }
}

int PHV::SlicingIterator::populate_initial_maps(
        std::list<PHV::SuperCluster::SliceList*>& candidateSliceLists,
        ordered_map<FieldSlice, std::pair<int, int>>& sliceLocations,
        ordered_map<FieldSlice, int>& exactSliceListSize,
        ordered_set<FieldSlice>& paddingFields,
        ordered_map<const PHV::SuperCluster::SliceList*, std::pair<int, int>>& sliceListDetails,
        ordered_map<FieldSlice, std::pair<int, int>>& originalSliceOffset,
        const std::map<const PHV::Field*, std::vector<PHV::Size>>& pa) {
    int offset = 0;
    // Offset of the first field in the slice list. We go through slice lists in a supercluster
    // in sequence, and the offset represents that sequence.
    int sliceListOffset = 0;
    for (auto* list : sc_i->slice_lists()) {
        LOG6("Determining initial co-ordinates for slice list");
        LOG6("\t" << *list);
        int sliceOffsetWithinSliceList = 0;
        // set to true, if any slice in the slice list has an exact containers requirement.
        bool has_exact_containers = false;

        // Set, if a slice is a padding field, to the size of the padding field.
        int paddingFieldSize = -1;
        // Used to track the last field in a slice list; the last field's right coordinate is
        // always -1 to indicate that no slicing is required there (there is implicit slicing at
        // each slice list boundary).
        FieldSlice* lastSliceInSliceList = nullptr;

        // Calculate the size of the slice list up front.
        int sliceListSize = 0;
        for (auto& slice : *list) {
            sliceListSize += slice.size();
            auto it = pa.find(slice.field());
            if (it == pa.end()) continue;
            // Note down pa_container_size pragmas for all fields in this slice list (if
            // specified). Then add the same pragmas for all fields in the rotational cluster
            // with that field.
            pa_container_sizes_i[it->first] = it->second;
            LOG6("  Adding pa_container_size for field: " << it->first);
            for (auto sz : it->second)
                LOG6("    " << sz);
            auto& rot_cluster = sc_i->cluster(slice);
            for (auto& rot_slice : rot_cluster.slices()) {
                if (slice == rot_slice) continue;
                if (pa_container_sizes_i.count(rot_slice.field())) {
                    LOG6("    Both original field and rotational cluster field have "
                            "container size pragmas!");
                    // XXX(Deep): Compare the two specifications of size.
                }
                pa_container_sizes_i[rot_slice.field()] = it->second;
                LOG6("  Adding pa_container_size for field: " << rot_slice);
                for (auto sz : it->second)
                    LOG6("    " << sz); } }

        // Set to true, if all slices in the slice list are of the same field AND there is a
        // no-split constraint on the field.
        bool allSlicesNoSplitSameField = true;
        const PHV::Field* fieldObserved = nullptr;
        // Check if the slice list is made up of slices of the same field and is less than
        // 32-bits in size. (no_split() is not applied to fields of more than 32 bit width).
        if (sliceListSize <= 32) {
            for (auto& slice : *list) {
                if (!slice.field()->no_split()) {
                    allSlicesNoSplitSameField = false;
                    break;
                }
                if (fieldObserved == nullptr) {
                    fieldObserved = slice.field();
                    continue;
                }
                if (fieldObserved != slice.field()) {
                    allSlicesNoSplitSameField = false;
                    break;
                }
            }
            LOG6("\tIs the slice list composed of slices of the same no-split field? " <<
                    (allSlicesNoSplitSameField ? "YES" : "NO"));
        } else {
            allSlicesNoSplitSameField = false;
        }

        const FieldSlice* prevSlice = nullptr;
        for (auto& slice : *list) {
            originalSliceOffset[slice].first = sliceOffsetWithinSliceList;
            // Set the last seen slice.
            LOG6("\tDetermining co-ordinates for slice: " << slice);
            if (prevSlice)
                LOG6("\t\tPrevious slice: " << prevSlice);
            lastSliceInSliceList = &slice;
            if (slice.field()->exact_containers())
                has_exact_containers = true;
            // Ignore the padding bits beyond the ones that are necessary to make a field with
            // deparsed, exact containers requirement aligned to byte boundaries.
            if (slice.field()->isCompilerGeneratedPaddingField()) {
                paddingFieldSize = slice.size();
                paddingFields.insert(list->begin(), list->end());
                if (prevSlice && !prevSlice->field()->isCompilerGeneratedPaddingField()) {
                    if (sliceLocations.at(*prevSlice).second != -1) {
                        required_slices_i.setbit(sliceLocations.at(*prevSlice).second);
                        LOG6("\t\t  Slicing before padding field " << slice);
                    }
                }
            }

            // Always require a split at the beginning of a slice with deparsed_bottom_bits.
            if (slice.field()->deparsed_bottom_bits()
                    && slice.range().lo == 0 && sliceOffsetWithinSliceList > 0) {
                // XXX(cole): 'BUG_CHECK' here might be too strong.
                BUG_CHECK(sliceOffsetWithinSliceList % 8 == 0,
                        "Can't slice on field %1% in slice list %2% "
                        "(which has deparsed bottom bits) because it is not byte aligned",
                        cstring::to_cstring(slice), cstring::to_cstring(list));
                LOG6("\t  Required slice at " << offset + (sliceOffsetWithinSliceList/ 8 - 1)
                        << " for field slice " << slice);
                required_slices_i.setbit(offset + (sliceOffsetWithinSliceList / 8 - 1)); }

            // If this slice is of the same field as the previous slice and the field is
            // no_split(), then the current slice should take the same sliceLocations pair as
            // the previous slice.
            if (prevSlice && prevSlice->field() == slice.field() && slice.field()->no_split()) {
                sliceLocations[slice] = sliceLocations[*prevSlice];
                LOG6("\t  A. Setting co-ordinates for a no-split field's slice to the prev " <<
                        "slice's co-ordinates: " <<
                        get_slice_coordinates(sliceListSize, sliceLocations.at(slice)));
                sliceOffsetWithinSliceList += slice.size();
                continue;
            }
            // Nearest byte aligned interval before this field slice.
            // Detect the byte limits for each slice.
            int left_limit = -1;
            int right_limit = -1;

            // If this is not the first slice in the slice list (indicated by
            // sliceOffsetWithinSliceList == 0), and if this slice list is not composed
            // exclusively of slices of the same no-split field, and if the slice is not byte
            // aligned, then its left limit is the previous byte boundary. Left limit of -1
            // indicates that the slice may be split at its start.
            LOG6("\t\tsliceOffsetWithinSliceList: " << sliceOffsetWithinSliceList <<
                    ", offset: " << offset);
            if (sliceOffsetWithinSliceList != 0 && !allSlicesNoSplitSameField &&
                    (sliceOffsetWithinSliceList / 8) != 0) {
                if (sliceOffsetWithinSliceList < 8)
                    left_limit = -1;
                else
                    left_limit = offset - 1 + (sliceOffsetWithinSliceList / 8);
            }
            sliceOffsetWithinSliceList += slice.size();

            // Figure out the byte boundary for the right side (the end of this slice).
            int addFactor = (sliceOffsetWithinSliceList / 8) -
                (1 - bool(sliceOffsetWithinSliceList % 8));
            // Calculate the number of bytes in the slice list.
            int sliceListBytesNeeded = sliceListSize / 8 - (1 - bool(sliceListSize % 8));
            LOG6("\t\tSlice list size: " << sliceListSize << ", sliceListBytesNeeded: " <<
                    sliceListBytesNeeded);

            // If all slices in the slice list do not all correspond to the same no-split field,
            // and if the
            if (!allSlicesNoSplitSameField && addFactor != sliceListBytesNeeded) {
                right_limit = offset + addFactor;
                LOG6("\t\tSetting right limit offset to: " << right_limit << " (" << offset <<
                        " + " << addFactor << ")");
            }
            sliceLocations[slice] = std::make_pair(left_limit, right_limit);
            LOG6("\t  B. Setting initial co-ordinates for slice " << slice << " to: " <<
                    get_slice_coordinates(sliceListSize, sliceLocations.at(slice)));
            prevSlice = &slice;
        }
        // By this time, the value of sliceOffsetWithinSliceList should be equal to the size of
        // the slice list.
        BUG_CHECK(sliceOffsetWithinSliceList == sliceListSize,
                "Is one of sliceListSize and sliceOffsetWithinSliceList wrong?");
        // Make sure that we went through all the slices in a slice list and that the slice list
        // was not empty.
        BUG_CHECK(sliceOffsetWithinSliceList > 0, "Empty slice list");

        // (range[list].hi + 1) * 8 is the first split position *beyond the
        // end* of the slice list.  Note that slice lists 8b or smaller
        // cannot be sliced, which is reflected in bitsNeededForBoundaries = 0.
        // bitsNeededForBoundaries indicates the number of bits needed to represent the
        // boundaries at which we can slice the slice list. E.g. for a 32-bit slice list, we can
        // split at the 8-bit boundary, 16-bit boundary, and 24-bit boundary (the split at the
        // beginning and end of the slice list is implicit). Therefore, we need 3-bits to
        // replace the boundaries.
        int bitsNeededForBoundaries = sliceListSize / 8 - (1 - bool(sliceListSize % 8));
        ranges_i[list] = StartLen(offset, bitsNeededForBoundaries);
        if (has_exact_containers) {
            candidateSliceLists.push_back(list);
            exact_containers_i.setrange(offset, bitsNeededForBoundaries);
            for (auto& slice : *list) {
                if (paddingFieldSize == -1)
                    exactSliceListSize[slice] = sliceListSize;
                else
                    exactSliceListSize[slice] = 8 * ROUNDUP(sliceListSize - paddingFieldSize,
                            8);
            }
        }

        for (auto& slice : *list) {
            int sliceOffset = originalSliceOffset[slice].first;
            if (exactSliceListSize.count(slice))
                originalSliceOffset[slice].second = exactSliceListSize.at(slice) - sliceOffset;
            else
                originalSliceOffset[slice].second = sliceListSize - sliceOffset;
        }

        offset += bitsNeededForBoundaries;
        boundaries_i.setbit(offset);
        LOG5("    ...slice list (" << sliceListSize << "b) with compressed bitvec size "
                << bitsNeededForBoundaries << " and offset " << offset);

        BUG_CHECK(lastSliceInSliceList != nullptr, "Were there no slices in the slice list?");
        sliceLocations[*lastSliceInSliceList].second = -1;
        sliceListOffset += sliceListSize;
        sliceListDetails[list] = std::make_pair(offset, bitsNeededForBoundaries);
    }
    return offset;
}

void PHV::SlicingIterator::impose_MAU_constraints(
        const std::list<PHV::SuperCluster::SliceList*>& candidateSliceLists,
        ordered_map<FieldSlice, std::pair<int, int>>& sliceLocations,
        ordered_map<FieldSlice, int>& exactSliceListSize,
        const ordered_set<FieldSlice>& paddingFields,
        const ordered_map<FieldSlice, std::pair<int, int>>& originalSliceOffset) {
    // XXX(Deep): The true constraint is that slices, which are part of a rotational cluster
    // must be sliced in the same way. This prevents searching through invalid values of the
    // slicing iterator.

    // For now, we ensure that if multiple slices in the same rotational cluster belong to
    // different slice lists with exact container requirements, and the width of those slice
    // lists are different, then the required slicing should necessarily be equivalent for all
    // those multiple slices in the same rotational cluster.
    ordered_set<FieldSlice> alreadyConsidered;
    for (auto* list : candidateSliceLists) {
        for (auto& candidate : *list) {
            if (alreadyConsidered.count(candidate)) {
                LOG6("Ignoring slice " << candidate << " that has already been processed.");
                continue;
            }
            alreadyConsidered.insert(candidate);
            LOG6("Considering rotational cluster constraints for slice: " << candidate);
            // { candidate } set are all slices that have an exact container requirement and belong
            // to slice lists.
            auto& rot_cluster = sc_i->cluster(candidate);
            int minSize = exactSliceListSize[candidate];
            boost::optional<FieldSlice> minSlice;
            for (auto& slice : rot_cluster.slices()) {
                LOG6("\tRotational cluster slice: " << slice);
                // Ignore the loop if the slice in the rotational cluster is the same as the
                // candidate slice.
                if (slice == candidate) {
                    LOG6("\t\tRotational slice same as the one being considered.");
                    continue;
                }
                // If the slice in the rotational cluster does not have the exact containers
                // requirement (it is metadata), then it does not induce any slicing requirements.
                if (!slice.field()->exact_containers()) {
                    LOG6("\t\tRotational slice does not have exact containers requirement.");
                    continue;
                }
                // If the slice list size for the non metadata slice is greater than or equal to the
                // current field's slice list size, then continue. Because this slice might be the
                // smallest slice of the rotational slices.
                bool smaller = exactSliceListSize[candidate] < exactSliceListSize[slice];
                bool equal = exactSliceListSize[candidate] == exactSliceListSize[slice];
                if (!paddingFields.count(candidate)) {
                    if (smaller) {
                        LOG6("\t\tSlice list for candidate slice (" << exactSliceListSize[candidate]
                             << "b) smaller than the slice list for slice " << slice << " (" <<
                             exactSliceListSize[slice] << "b)");
                        continue;
                    }
                    if (equal) {
                        LOG6("\t\tSlice list for candidate slice (" << exactSliceListSize[candidate]
                             << "b) equal in size to the slice list for slice " << slice << " (" <<
                             exactSliceListSize[slice] << "b)");
                        continue;
                    }
                }
                if (minSize > exactSliceListSize[slice]) {
                    minSlice = slice;
                    minSize = exactSliceListSize[slice];
                    LOG6("\t\tSetting minSlice to " << slice << " and minSize to " << minSize <<
                            "b.");
                }
            }

            // minSlice represents the slice in the rotational cluster with the exact containers
            // requirement and the smallest slice list size. In other words, this is the slice
            // according to which the current slice's slice list must be sliced. If minSlice not
            // found, then it means one of the following things:
            // 1. There are no slices with exact container requirements in the same rotational
            //    cluster.
            // 2. The current slice itself belongs to the smallest slice list with exact containers
            //    requirement in this rotational cluster.
            // 3. The field is a padding field, so it may be cut off; we do not need to enforce
            //    slicing for padding fields.
            if (!minSlice) {
                LOG6("\tMin slice not found. Continuing...");
                continue;
            }
            LOG6("\tNeed to slice around " << candidate << " to match slice list size " << minSize
                 << "b of " << *minSlice);

            // Extract information about the slice list for the slice under consideration.
            auto& slice_lists = sc_i->slice_list(candidate);
            BUG_CHECK(slice_lists.size() == 1, "Multiple slice lists contain slice %1%?",
                    candidate);
            const auto* slice_list = *(slice_lists.begin());
            // offsetWithinSliceList is the offset of the current slice within its slice list. This
            // is determined by iterating through (in sequence) each slice of the slice list, until
            // we arrive at the current slice.
            // XXX(Deep): This may be memoized in the future?
            int offsetWithinSliceList = 0;
            int offsetWithinOriginalSliceList = 0;
            const FieldSlice* firstSliceInCurrentSliceList = nullptr;
            for (auto& slice : *slice_list) {
                // Potential first slice in the slice list for the current slice.
                if (offsetWithinOriginalSliceList == 0) firstSliceInCurrentSliceList = &slice;
                // If the left limit is -1, then it indicates the start of a new slice list.
                // Remember that a slice list at this point may have already been marked for
                // splitting into multiple slice lists. This condition is essential is necessary for
                // keeping track of the new slice list limits that are created.  Ignore the first
                // byte of the slice list while counting offsetWithinSliceList.
                if (offsetWithinOriginalSliceList > 8 && sliceLocations[slice].first == -1) {
                    LOG6("\t\t\tCurrent slice: " << slice << ", setting offset to 0.");
                    firstSliceInCurrentSliceList = &slice;
                    offsetWithinSliceList = 0;
                    offsetWithinOriginalSliceList += slice.size();
                    if (slice != candidate) continue;
                }
                // Do not include the current slice list in the offsetWithinSliceList. That way, we
                // only slice before the current slice.
                if (slice == candidate) {
                    LOG6("\t\t\tCurrent slice: " << slice << ", found it! offset: " <<
                            offsetWithinSliceList);
                    break;
                }
                LOG6("\t\t\tCurrent slice: " << slice << " " << slice.size() <<
                        "b, offset within original slice list: " << offsetWithinSliceList);
                offsetWithinSliceList += slice.size();
                offsetWithinOriginalSliceList += slice.size();
            }
            BUG_CHECK(firstSliceInCurrentSliceList != nullptr, "No slice in slice list?");
            LOG6("\t\tFirst slice in current slice's slice list is: " <<
                    *firstSliceInCurrentSliceList);
            bool foundFirstSliceInCurrentSliceList = false;

            // For any slice, the update limits should be as follows:
            // 1. If offsetWithinSliceList % minSize == 0 and left != -1, then the slice is byte
            //    aligned and a slice boundary must be created to the left of the slice.
            // 2. If offsetWithinSliceList % minSize != 0, then the slice needs to be created to the
            //    left of the current slice between the previously specified boundary of a slice
            //    list and the current slice. These possible slicing points are represented by the
            //    possibleSlicingPoints set. We then need to choose the appropriate slicing point
            //    among these and update the slice lists accordingly.
            ordered_set<FieldSlice> alreadyProcessedSlices;
            int processedBits = 0;
            int left = sliceLocations[candidate].first;
            int right = sliceLocations[candidate].second;
            LOG6("\t  For candidate slice, left = " << left << " and right = " << right);
            // Set if a new split in the slice list is created before the current slice.
            bool newSliceBoundaryFoundLeft = false;

            std::vector<FieldSlice> sliceListToProcess;
            ordered_set<FieldSlice> possibleSlicingPoints;
            // Populate sliceListToProcess with the part of the slice list that have not been
            // assigned to slice lists yet (remove already processed slices). Also find, all the
            // possible points where this sliceListToProcess can be sliced; we skip slicing points
            // that straddle the same field in this case.
            for (auto& slice : *slice_list) {
                if (!foundFirstSliceInCurrentSliceList) {
                    if (slice == *firstSliceInCurrentSliceList) {
                        foundFirstSliceInCurrentSliceList = true;
                        sliceListToProcess.push_back(slice);
                        LOG6("\t\t  Must process " << slice);
                        if ((originalSliceOffset.at(slice).first % 8) == 0)
                            possibleSlicingPoints.insert(slice);
                    } else {
                        continue;
                    }
                } else {
                    sliceListToProcess.push_back(slice);
                    LOG6("\t\t  Must process " << slice);
                    int offsetWithinOriginalSliceList = originalSliceOffset.at(slice).first;
                    int bitsLeftAfterThisSlice = originalSliceOffset.at(slice).second;
                    if (offsetWithinOriginalSliceList % 8 == 0 && bitsLeftAfterThisSlice >= minSize
                        && offsetWithinOriginalSliceList <= originalSliceOffset.at(candidate).first)
                        possibleSlicingPoints.insert(slice);
                }
            }
            if (possibleSlicingPoints.size() > 0)
                for (auto& slice : possibleSlicingPoints)
                    LOG6("\t\t\tPossible slicing point: " << slice);

            if (offsetWithinSliceList % minSize == 0 && left != -1) {
                required_slices_i.setbit(left);
                newSliceBoundaryFoundLeft = true;
                LOG6("\t  A. Slicing before slice " << candidate);
                // New slice list started.
                offsetWithinSliceList = 0;
                int newSliceListSize = processSliceListBefore(alreadyProcessedSlices,
                        exactSliceListSize, sliceLocations, originalSliceOffset, sliceListToProcess,
                        candidate);
                LOG6("\t\tCreated a new slice list of " << newSliceListSize << "b.");
            } else if (left != -1) {
                auto slicingPoint = getBestSlicingPoint(sliceListToProcess, possibleSlicingPoints,
                        minSize);
                LOG6("\t\t  Best slicing point: " << slicingPoint);
                if (sliceLocations[slicingPoint].first != -1) {
                    LOG6("\t  B. Slicing before slice " << slicingPoint);
                    required_slices_i.setbit(sliceLocations[slicingPoint].first);
                    newSliceBoundaryFoundLeft = true;
                    processedBits = processSliceListBefore(alreadyProcessedSlices,
                            exactSliceListSize, sliceLocations, originalSliceOffset,
                            sliceListToProcess, slicingPoint);
                }
            }

            // 2. If carryOver == 0, and right == -1, it means that we have reached the slice
            //    after which the original slice list should be split but the split is not yet
            //    satisfied at that slice (because right == -1). Therefore, create a slice boundary
            //    to the right of the slice.

            // carryOver is the number of bits after the current slice in the slice list that must
            // be put into the same slice list.
            // E.g. if we have fields a<3b>, b<3b>, c<2b>, and b is the field under consideration
            // (slice) and minSize is 8b, then posInSliceList = 3, and carryOver = 2b.
            LOG6("\t  minSize: " << minSize << ", offset: " << offsetWithinSliceList <<
                    ", slice size: " << candidate.size() << ", processedBits: " << processedBits);
            int carryOver = minSize - (offsetWithinSliceList - processedBits);
            int carryOverAfterSlice = carryOver - candidate.size();
            LOG6("\t  " << carryOverAfterSlice << " more bits must be included in this slice "
                 "list.");

            // Set if a new split in the slice list is created after the current slice.
            bool newSliceBoundaryFoundRight = false;
            if (carryOverAfterSlice == 0 && right != -1) {
                newSliceBoundaryFoundRight = true;
                required_slices_i.setbit(right);
                LOG6("\t  Slicing after slice " << candidate);
            }
            bool slicesLeftToProcess = carryOverAfterSlice > 0;
            // If no new slice boundary is found, then we do not need to update any of the slice
            // list related state. Also, if there are more slices left to process, we need to update
            // the state for those fields accordingly.
            if (!newSliceBoundaryFoundLeft && !newSliceBoundaryFoundRight && !slicesLeftToProcess)
                continue;

            // Update the slice list maps that help us decide the required_slices_i value. Once we
            // decide to break a slice list at a particular boundary, we will get new slice lists;
            // we need to update the slice lists sizes and the byte boundaries for each slice, once
            // the point for the slicing is found.
            LOG6("\t  Need to update the resulting slice list.");

            int intraListSize = 0;
            std::vector<FieldSlice> seenFieldSlices;
            bool allSlicesGoToNewSliceList = false;
            for (auto& slice : sliceListToProcess) {
                if (alreadyProcessedSlices.count(slice)) {
                    LOG6("\t\tNew slice list for slice " << slice << " has already been created.");
                    continue;
                }
                LOG6("\t\tCo-ordinate for slice " << slice << ": " << exactSliceListSize[slice] <<
                        "b, " << sliceLocations[slice].first << "L, " <<
                        sliceLocations[slice].second << "R.");
                // Boundary was shifted to before this field, so change the size for the fields seen
                // so far.
                if (newSliceBoundaryFoundLeft) {
                    // Still processing fields before the slicing point.
                    if (slice != candidate) {
                        LOG6("\t\t  Adding " << slice << " to seen fields before slicing point.");
                        seenFieldSlices.push_back(slice);
                        continue;
                    }
                    // Finally we reach the field slice before which the slicing is done.
                    for (auto& sl : seenFieldSlices) {
                        intraListSize += sl.size();
                        exactSliceListSize[sl] = minSize;
                        LOG6("\t\t  C. Setting " << sl << " co-ordinates to: " <<
                                get_slice_coordinates(exactSliceListSize[sl], sliceLocations[sl]));
                        alreadyProcessedSlices.insert(sl);
                    }
                    // After all the slices in the first slice list are adjusted, clear seenFields
                    // and reset the intraListSize to 0.
                    seenFieldSlices.clear();
                    newSliceBoundaryFoundLeft = false;
                    LOG6("\t\t\tClearing state because we finished the previous slice.");
                }

                // Add data related to the current slice whose MAU constraints are being considered.
                // In this case, there is a new slice list created after the current slice and there
                // is no other slice after this slice in the current slice list.
                if (slice == candidate && newSliceBoundaryFoundRight) {
                    intraListSize += slice.size();
                    BUG_CHECK(intraListSize % 8 == 0, "How did we create a slice list at a non "
                            "byte boundary?");
                    exactSliceListSize[slice] = intraListSize;
                    sliceLocations[slice].first = -1;
                    LOG6("\t\t  D. Setting " << slice << " co-ordinates to: " <<
                         get_slice_coordinates(exactSliceListSize[slice], sliceLocations[slice]));
                    intraListSize = 0;
                    alreadyProcessedSlices.insert(slice);
                    continue;
                }

                if (originalSliceOffset.at(candidate).first > originalSliceOffset.at(slice).first) {
                    seenFieldSlices.push_back(slice);
                    intraListSize += slice.size();
                    LOG6("\t\t  e. Discovered already accounted for slice " << slice);
                    LOG6("\t\t  intraListSize: " << intraListSize << " bits. Carry over: " <<
                            carryOver);
                    continue;
                }

                if (carryOverAfterSlice == 0 || (carryOverAfterSlice > 0 && slice == candidate)) {
                    seenFieldSlices.push_back(slice);
                    intraListSize += slice.size();
                    carryOver = carryOverAfterSlice;
                    LOG6("\t\t  a. Discovered " << intraListSize << " bits. Carry over: " <<
                            carryOver);
                    continue;
                }
                if (allSlicesGoToNewSliceList) {
                    seenFieldSlices.push_back(slice);
                    intraListSize += slice.size();
                    carryOver -= slice.size();
                    LOG6("\t\t  b. Discovered " << intraListSize << " bits. Carry over: " <<
                            carryOver);
                    continue;
                } else {
                    int carryOverAfterThisSlice = carryOver - slice.size();
                    if (carryOverAfterThisSlice <= 0) {
                        // Check for padding fields and setbit on the vector here.
                        intraListSize += carryOver;
                        LOG6("\t\t\tintraListSize increased to " << intraListSize <<
                                " due to carryOver.");
                        int sliceListSizeWithoutPadding = 0;
                        int lastRightOffset = -1;
                        // Current slice is part of the previous slice list if the carry over after
                        // this slice is going to be 0.
                        if (carryOverAfterThisSlice == 0) {
                            seenFieldSlices.push_back(slice);
                            carryOver -= slice.size();
                        }
                        for (auto& sl : seenFieldSlices) {
                            if (!sl.field()->isCompilerGeneratedPaddingField()) {
                                sliceListSizeWithoutPadding += sl.size();
                                lastRightOffset = sliceLocations[sl].second;
                            }
                            exactSliceListSize[sl] = minSize;
                            // Set the correct right limit for the field slice. If the rounded up
                            // size of the slice list from its beginning to the current slice is
                            // equal to the size of the new slice list (represented by
                            // intraListSize), then it means we need to slice to the right of slice
                            // sl, and so we set its right limit to -1.
                            int roundedUpSizeSoFar = 8 * ROUNDUP(sliceListSizeWithoutPadding, 8);
                            if (roundedUpSizeSoFar == intraListSize)
                                sliceLocations[sl].second = -1;
                            LOG6("\t\t  E. Setting " << sl << " co-ordinates to: " <<
                                 get_slice_coordinates(exactSliceListSize[sl], sliceLocations[sl]));
                        }
                        if (slice.field()->isCompilerGeneratedPaddingField()) {
                            exactSliceListSize[slice] = intraListSize;
                            sliceLocations[slice].second = lastRightOffset;
                            LOG6("\t\t  F. Setting " << slice << " co-ordinates to: " <<
                                    get_slice_coordinates(exactSliceListSize[slice],
                                        sliceLocations[slice]));
                            alreadyConsidered.insert(slice);
                        } else {
                            allSlicesGoToNewSliceList = true;
                            LOG6("\t\t\tMark all slices as part of new slice list.");
                        }
                        // We have to slice at the lastRightOffset bit.
                        if (lastRightOffset != -1)
                            required_slices_i.setbit(lastRightOffset);
                        seenFieldSlices.clear();
                        intraListSize = 0;
                        LOG6("\t\t\tClearing state in preparation for new slice list.");
                        continue;
                    } else {
                        // Handle case where carryOver > 0.
                        LOG6("\t\t  G. Setting " << slice << " co-ordinates to: " <<
                                get_slice_coordinates(exactSliceListSize[slice],
                                    sliceLocations[slice]));
                        carryOver -= slice.size();
                        seenFieldSlices.push_back(slice);
                        intraListSize += slice.size();
                        LOG6("\t\t  c. Discovered " << intraListSize << " bits. Carry over: " <<
                                carryOver);
                        continue;
                    }
                }
                seenFieldSlices.push_back(slice);
                intraListSize += slice.size();
                LOG6("\t\t  d. Discovered " << intraListSize << " bits. Carry over: " << carryOver);
            }

            // At this point, the seenFieldSlices object contains all the remaining slices that must
            // now be in the same slice list together.
            int remainingBitsVisited = 0;
            for (auto& slice : seenFieldSlices) {
                if (remainingBitsVisited / 8 == 0)
                    sliceLocations[slice].first = -1;
                remainingBitsVisited += slice.size();
                int nextByteBoundary;
                if (slice.field()->isCompilerGeneratedPaddingField()) {
                    exactSliceListSize[slice] = 8 * ROUNDUP(intraListSize - slice.size(), 8);
                    nextByteBoundary = (exactSliceListSize[slice] < remainingBitsVisited)
                        ? -1 : (8 * ROUNDUP(remainingBitsVisited, 8));
                } else {
                    exactSliceListSize[slice] = 8 * ROUNDUP(intraListSize, 8);
                    nextByteBoundary = 8 * ROUNDUP(remainingBitsVisited, 8);
                }
                if (nextByteBoundary == -1 || nextByteBoundary == exactSliceListSize[slice])
                    sliceLocations[slice].second = -1;
                LOG6("\t\t  H. Setting " << slice << " co-ordinates to: " <<
                        get_slice_coordinates(exactSliceListSize[slice], sliceLocations[slice]));
            }
        }
    }
}

PHV::FieldSlice PHV::SlicingIterator::getBestSlicingPoint(
        const std::vector<FieldSlice>& list,
        const ordered_set<FieldSlice>& points,
        const int minSize) const {
    for (auto& point : points) {
        bool pointFound = false;
        int sliceListSize = 0;
        for (auto& slice : list) {
            if (!pointFound && slice != point) continue;
            if (slice == point) pointFound = true;
            sliceListSize += slice.size();
            if (sliceListSize == minSize) return point;
            if (sliceListSize > minSize) break;
        }
        LOG6("\t\t\tSlicing at " << point << " causes a slice boundary to fall between slices.");
    }
    // If none of the candidates is suitable, just choose the first possible slicing point.
    return *(points.begin());
}

int PHV::SlicingIterator::processSliceListBefore(
        ordered_set<FieldSlice>& alreadyProcessedSlices,
        ordered_map<FieldSlice, int>& exactSliceListSize,
        ordered_map<FieldSlice, std::pair<int, int>>& sliceLocations,
        const ordered_map<FieldSlice, std::pair<int, int>>& originalSliceOffset,
        const std::vector<FieldSlice>& list,
        const FieldSlice& point) {
    int newSliceListSize = 0;
    ordered_set<FieldSlice> processedSlices;
    int pointOriginalOffset = originalSliceOffset.at(point).first;
    int seenSlicePoint = false;
    int postSlicePointBits = 0;
    for (auto& slice : list) {
        // All slices until one byte past the slicing point processed.
        if (slice == point) {
            sliceLocations[slice].first = -1;
            seenSlicePoint = true;
            postSlicePointBits += slice.size();
        }
        // Set left limit for all slices within the same byte as the slicing point.
        if (postSlicePointBits > 0 && postSlicePointBits <= 8) {
            sliceLocations[slice].first = -1;
            postSlicePointBits += slice.size();
        }
        if (seenSlicePoint)
            LOG6("\t\t  J. Setting " << slice << " co-ordinates to: " <<
                 get_slice_coordinates(exactSliceListSize[slice], sliceLocations[slice]));
        if (postSlicePointBits > 8) break;
        if (seenSlicePoint) continue;
        // Processing slices before the slicing point here.
        // These are part of the first byte in the new slice list, so left limit is set accordingly.
        if (newSliceListSize < 8)
            sliceLocations[slice].first = -1;
        // For the slices in the last byte in the new slice list, set right limit to -1.
        int sliceOriginalOffset = originalSliceOffset.at(slice).first;
        if (pointOriginalOffset - sliceOriginalOffset <= 8)
            sliceLocations[slice].second = -1;
        newSliceListSize += slice.size();
        processedSlices.insert(slice);
    }
    // Set the slice list size for the processed slices.
    for (auto& slice : processedSlices) {
        exactSliceListSize[slice] = newSliceListSize;
        LOG6("\t\t  I. Setting " << slice << " co-ordinates to: " <<
                get_slice_coordinates(exactSliceListSize[slice], sliceLocations[slice]));
        alreadyProcessedSlices.insert(slice);
    }
    return newSliceListSize;
}

void PHV::SlicingIterator::break_24b_slice_lists(
        ordered_map<FieldSlice, int>& exactSliceListSize,
        ordered_map<FieldSlice, std::pair<int, int>>& sliceLocations,
        const ordered_map<FieldSlice, std::pair<int, int>>& originalSliceOffset) {
    LOG6("Breaking 24b slice lists");
    for (auto kv : exactSliceListSize) {
        if (kv.second != 24) continue;
        LOG6("\t\tNeed to break slice " << kv.first << " (" <<
             get_slice_coordinates(exactSliceListSize.at(kv.first), sliceLocations.at(kv.first))
             << ")");
        auto& slice_lists = sc_i->slice_list(kv.first);
        BUG_CHECK(slice_lists.size() == 1, "Multiple slice lists contain slice %1%?", kv.first);
        auto* slice_list = *(slice_lists.begin());

        auto& slice = *(slice_list->begin());
        int sliceListSize = originalSliceOffset.at(slice).first +
            originalSliceOffset.at(slice).second;
        LOG6("\t\t  Slice list size: " << sliceListSize);

        // Right now, we only slice lists whose original size was 24b. We do not process slice lists
        // which become 24b in width as a result of slicing itself.
        // XXX(Deep): Include created 24b slice lists in this analysis.
        std::vector<FieldSlice> sliceListToProcess;
        if (sliceListSize == 24) {
            for (auto& slice : *slice_list)
                sliceListToProcess.push_back(slice);
            break_24b_slice_list(exactSliceListSize, sliceLocations, sliceListToProcess);
            continue;
        }
    }
}

void PHV::SlicingIterator::break_24b_slice_list(
        ordered_map<FieldSlice, int>& exactSliceListSize,
        ordered_map<FieldSlice, std::pair<int, int>>& sliceLocations,
        const std::vector<FieldSlice>& sliceListToProcess) {
    LOG6("\t\tInside break 24b slice list");
    int offset = 0;
    std::vector<FieldSlice> seenSlices;
    int sliceOffset = -1;
    int slicePoint = -1;
    // If the offset after a field slice in the slice list is at byte boundaries, choose that as the
    // right slicing point.
    // seenSlices is the set of all slices that appear in the slice list before the slicing point,
    // so they will be part of the first slice list that is created.
    for (auto& slice : sliceListToProcess) {
        offset += slice.size();
        seenSlices.push_back(slice);
        LOG6("\t\t  Offset for slice " << slice << " : " << offset);
        if (offset != 8 && offset != 16) continue;
        sliceOffset = offset;
        slicePoint = sliceLocations[slice].second;
        break;
    }
    LOG6("\t\tSlice at offset " << sliceOffset << " within slice list");
    // If the slice offset is not 8 or 16, then we will not break slice list here and instead will
    // rely on enforce_container_sizes to break the 24b slice list.
    if (sliceOffset != 8 && sliceOffset != 16) return;
    BUG_CHECK(slicePoint != -1, "Slice point cannot be -1 at this point.");
    required_slices_i.setbit(slicePoint);
    // Set new slicing points for slices before the slicing point.
    offset = 0;
    // Process slice lists before the determined slicing point.
    for (auto& slice : seenSlices) {
        offset += slice.size();
        exactSliceListSize[slice] = sliceOffset;
        int right = 8 * ROUNDUP(offset, 8);
        if (right == sliceOffset)
            sliceLocations[slice].second = slicePoint;
        LOG6("\t\t  K. Setting " << slice << " co-ordinates to: " <<
                get_slice_coordinates(exactSliceListSize[slice], sliceLocations[slice]));
    }
    offset = 0;
    int remainingSliceListSize = 24 - sliceOffset;
    // Process the second slice list created. These are slices after the slicing point.
    for (auto& slice : sliceListToProcess) {
        if (offset + slice.size() <= sliceOffset) {
            offset += slice.size();
            continue;
        }
        exactSliceListSize[slice] = remainingSliceListSize;
        if ((8 * (offset / 8)) == sliceOffset)
            sliceLocations[slice].first = -1;
        LOG6("\t\t  L. Setting " << slice << " co-ordinates to: " <<
                get_slice_coordinates(exactSliceListSize[slice], sliceLocations[slice]));
        offset += slice.size();
    }
}

void PHV::SlicingIterator::enforce_container_size_pragmas(
        const ordered_map<const PHV::SuperCluster::SliceList*, std::pair<int, int>>& listDetails) {
    // If there are no container size pragmas for this supercluster, nothing to be done.
    if (pa_container_sizes_i.size() == 0) return;
    // If there are no slice lists in the super cluster, nothing to be done.
    if (!has_slice_lists_i) return;
    for (auto* list : sc_i->slice_lists()) {
        // Offset of the slice (in bits) within this slice list.
        int slice_offset = 0;
        // Start offset of the bitvec corresponding to this slice list within the supercluster's
        // comperessed slicing schema.
        int slice_list_offset = listDetails.at(list).first - listDetails.at(list).second;
        // For each slice in the slice list:
        for (auto& slice : *list) {
            auto it = pa_container_sizes_i.find(slice.field());
            // If the slice doesn't belong to a field with a pa_container_size pragma, then nothing
            // to be done here.
            if (it == pa_container_sizes_i.end()) {
                slice_offset += slice.size();
                continue;
            }
            // Set at bitpositions within the field that we need to slice at to respect the pragmas.
            std::set<int> slicingPoints;
            // Only one size specified, implying that either the field spans only one container
            // size, or it must be divided into even chunks of the specified size.
            if (it->second.size() == 1) {
                int size = static_cast<int>(*((it->second).begin()));
                // If there is a pragma where the container size is less than the size of the field,
                // then no slicing is required.
                if (slice.field()->size <= size) {
                    slice_offset += slice.size();
                    continue;
                }
                // XXX(Deep): Account for case where we have to evenly split the fields.
            } else {
                // Offset inside the field at which slicing should be done.
                int field_offset = 0;
                for (auto sz : it->second) {
                    int size = static_cast<int>(sz);
                    // Ignore slicing points at the end of the field.
                    // XXX(Deep): What if the field is not at the end of the slice list?
                    if (field_offset + size > slice.field()->size) continue;
                    slicingPoints.insert(field_offset + size);
                    field_offset += size;
                }
            }
            LOG6("  Slice " << slice << " has an associated pa_container_size pragma");
            for (auto sz : it->second)
                LOG6("    Size: " << sz);
            if (slicingPoints.size() > 0) {
                std::stringstream ss;
                for (auto limit : slicingPoints)
                    ss << limit << " ";
                LOG6("      Slice at: " << ss.str());
            }
            for (auto limit : slicingPoints) {
                // Byte range for the slicing point.
                le_bitrange sliceRange = StartLen(limit, 1);
                // If the current slice includes the slicing point, then set the corresponding bit
                // in the required_slices bitvec to force a slice at the required slicing point.
                if (slice.range().overlaps(sliceRange)) {
                    LOG6("      Slice at bit position " << limit << " within this slice");
                    // Starting index of the field slice.
                    int field_lo = slice.range().lo;
                    // bitvec is indexed at 0, so the -1 is necessary.
                    int slice_pos = slice_list_offset - 1 +
                        ((slice_offset + (limit - field_lo)) / 8);
                    LOG6("      Slice at byte " << slice_pos << " within this slice list");
                    // XXX(Deep): What if the field is not at the end of the slice list?
                    if (slice_pos >= 0 && slice_pos < listDetails.at(list).first)
                        required_slices_i.setbit(slice_pos);
                }
            }
            slice_offset += slice.size();
        }
    }
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

void PHV::SlicingIterator::enforce_MAU_constraints_for_meta_slice_lists(
        ordered_map<PHV::SuperCluster::SliceList*, bitvec>& split_schema) const {
    ordered_map<FieldSlice, ordered_set<int>> splitSlices;
    ordered_map<FieldSlice, std::pair<int, int>> nonExactContainerSlices;
    ordered_map<FieldSlice, PHV::SuperCluster::SliceList*> sliceToLists;
    // The split schema is a representation of the bits where each slice in the slice list must be
    // split, as part of this slicing attempt. It maps each slice in the slice list to a bitvec
    // representing possible slicing points (1 at a bit position in the bitvec implies that a slice
    // must be made at that bit position).
    // This loop does two things:
    // 1. It identifies all the slice lists with non exact container requirements and memoizes the
    //    start and end positions of that slice within the slice list (this is memoized as a pair
    //    stored as a value corresponding to each key field slice). For this purpose, we maintain
    //    two bit indexes: slice_list_offset (how far we are in the slice list, includes the current
    //    slice) and the prev_list_offset (which indicates how far into the slice list the current
    //    slice is).
    // 2. The loop also identifies all the slices that have been split somewhere in the middle (i.e.
    //    at non slice boundaries). Note, that middle here means any position in the range [1, size
    //    - 2], where size is the width of the current slice. The splitSlices map stores a mapping
    //    from such field slices to the set of bit positions within the slice (not the global
    //    position in the slice list) where the splits must be performed.
    for (auto& kv : split_schema) {
        int slice_list_offset = 0;
        int prev_slice_offset = 0;
        // For each slice in the slice list.
        for (auto slice : *kv.first) {
            slice_list_offset += slice.size();
            if (!slice.field()->exact_containers()) {
                nonExactContainerSlices[slice] = std::make_pair(prev_slice_offset, slice_list_offset
                        - 1);
                sliceToLists[slice] = kv.first; }
            for (int i = prev_slice_offset + 1 ; i < slice_list_offset - 1; i++) {
                if (kv.second[i] && slice.field()->exact_containers()) {
                    LOG6("\t  Slice at bit " << (i - prev_slice_offset) << " within slice " <<
                            slice);
                    splitSlices[slice].insert(i - prev_slice_offset); } }
            prev_slice_offset = slice_list_offset; } }

    // If there are no slices with splits within the slice, we don't need to do anything else.
    if (splitSlices.size() == 0) return;
    LOG6("\t  Slices split in the middle");
    for (auto& kv : splitSlices) {
        std::stringstream ss;
        ss << "  " << kv.first << " @ ";
        for (const int b : kv.second)
            ss << b << " ";
        LOG6("\t\t" << ss.str());
    }
    // If there are no non exact container slice lists, then we don't need to do anything either.
    if (nonExactContainerSlices.size() == 0) return;
    LOG6("\t  Slices with non exact container requirements");
    for (auto& kv : nonExactContainerSlices)
        LOG6("\t\t" << kv.first << " [" << kv.second.first << ", " << kv.second.second << "]");

    // We check if any of the field slices in the rotational cluster of nonExactContainerSlices
    // (slice list slices without the exact container requirements) are split in the middle. If they
    // are, then we slice the non exact container slice list at the same position as the candidate
    // slice in the rotational cluster.
    for (auto& kv : nonExactContainerSlices) {
        auto& slice = kv.first;
        PHV::SuperCluster::SliceList* sc = sliceToLists[slice];
        int lo = kv.second.first;
        int hi = kv.second.second;
        auto& rot_cluster = sc_i->cluster(slice);
        for (auto& rot_slice : rot_cluster.slices()) {
            if (rot_slice == slice) continue;
            if (splitSlices.count(rot_slice)) {
                LOG6("\t    Found slice in cluster " << rot_slice << " which is split down the "
                     "middle.");
                for (auto b : splitSlices.at(rot_slice)) {
                    if (lo + b > hi) continue;
                    LOG6("\t    Setting slice at bit " << (lo + b) << " in " << rot_slice);
                    split_schema[sc].setbit(lo + b); } } }
    }
}

boost::optional<std::list<PHV::SuperCluster*>> PHV::SlicingIterator::get_slices() const {
    LOG6("Inside get_slices()");
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

        // enforce MAU constraints for non exact container size slices lists here. We have to do it
        // here, because splitting may occur on a non-byte boundary for these non exact container
        // size slices.
        enforce_MAU_constraints_for_meta_slice_lists(split_schemas);

        // Try slicing using this set of expanded schemas.
        auto res = split_super_cluster(sc_i, split_schemas);

        // If we found a good slicing, return it.
        if (res && std::all_of(res->begin(), res->end(), PHV::SuperCluster::is_well_formed)) {
            LOG6("Supercluster with slice list produces well-formed superclusters");
            return res;
        } else {
            LOG6("Supercluster does not get sliced into well-formed superclusters");
            return boost::none;
        }
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
        if (num_slicings % 10000 == 0)
            LOG4("Tried " << num_slicings << " slicings.");
        if (num_slicings > 0 && num_slicings > SLICING_THRESHOLD) {
            std::stringstream ss;
            ss << "Slicing the following supercluster is taking too long..." << std::endl;
            ss << "Tried " << num_slicings << " slicings." << std::endl;
            ss << sc_i;
            BUG("%1%", ss.str());
        }
        // Increment the bitvec...
        PHV::inc(compressed_schemas_i);
        // Increment the counter for number of slicings.
        ++num_slicings;
        // and set the required slices...
        compressed_schemas_i |= required_slices_i;
        // and set the least significant bits necessary to ensure that
        // slices correspond to container sizes.
        PHV::enforce_container_sizes(compressed_schemas_i,
                                     sentinel_idx_i,
                                     boundaries_i,
                                     required_slices_i,
                                     exact_containers_i);

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
        const bitvec& required,
        const bitvec& exact_containers) {
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

            if ((break_next && zeroes == 2 && exact_containers[i]) || zeroes > 3) {
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
            if (zeroes > 3 || (zeroes == 2 && at_last_bit && exact_containers[i])) {
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

}  // namespace PHV
