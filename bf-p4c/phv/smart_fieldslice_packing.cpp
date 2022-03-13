#include "smart_fieldslice_packing.h"

namespace {
// PackChoice is a list of fieldslice/SuperCluster pair. This list of fieldslice has the possiblity
// to be packed into a slice list.
using PackChoice = std::vector<std::pair<PHV::FieldSlice, PHV::SuperCluster*>>;

/// @returns a vector of PackChoices based on @p packed_fs
std::vector<PackChoice> prepare_packing_solutions(
    const std::list<PHV::SuperCluster*> &cluster_groups,
    ordered_set<PHV::FieldSlice> &packed_fs) {
    std::vector<PackChoice> packing_solutions;

    ordered_map<PHV::FieldSlice, ordered_set<PHV::SuperCluster*>> sc_to_merge;
    ordered_map<PHV::FieldSlice, ordered_set<le_bitrange>> candidates_to_pack;

    // this function checks that if a fieldslice as the result of packing has some ranges that are
    // already packed in a slice list.
    auto some_ranges_packed = [&](PHV::FieldSlice fs) {
        for (auto sc : cluster_groups) {
            for (auto sl : sc->slice_lists()) {
                int num_fs_in_pack_range = 0;
                for (auto candidate_fs : *sl) {
                    if (candidate_fs.field() == fs.field() &&
                        candidate_fs.range().overlaps(fs.range())) {
                        num_fs_in_pack_range++;
                        if (num_fs_in_pack_range > 1) {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    };

    for (auto fs : packed_fs) {
        auto field = fs.field();
        auto pack_range = fs.range();
        // search super clusters to merge
        ordered_set<PHV::SuperCluster *> to_merge;
        PackChoice to_pack;
        // skip fieldslice who has already been packed in a slice list
        if (some_ranges_packed(fs)) continue;
        for (auto sc : cluster_groups) {
            for (auto candidate_fs : sc->slices()) {
                if (candidate_fs.field() == field) {
                    if (pack_range.contains(candidate_fs.range())) {
                        to_pack.push_back(std::make_pair(candidate_fs, sc));
                        continue;
                    }
                    BUG_CHECK(!pack_range.overlaps(candidate_fs.range()), "pack_range should "
                        "not overlap with any fieldslice");
                }
            }
        }
        packing_solutions.push_back(to_pack);
    }
    return packing_solutions;
}

/// @returns a list of possible PackChoice.
std::vector<PackChoice> get_smart_packing_candidates(
    const std::list<PHV::SuperCluster*> &cluster_groups,
    const TableFieldPackOptimization& table_pack_opt) {
    ordered_set<PHV::FieldSlice> packed_fs;
    for (auto sc : cluster_groups) {
        for (auto fs_to_pack : sc->slices()) {
            // skip the fieldslice with aligment.
            if (fs_to_pack.field()->alignment.is_initialized()) continue;
            // skip pov bits
            if (fs_to_pack.field()->pov) continue;
            // skip header field
            if (!fs_to_pack.field()->metadata) continue;
            std::vector<PHV::FieldSlice> same_field_candidates;
            for (const auto& candidate : table_pack_opt.getPackCandidate(fs_to_pack)) {
                // only care about fieldslice with the same field.
                if (candidate.field() != fs_to_pack.field()) continue;
                same_field_candidates.push_back(candidate);
            }

            if (same_field_candidates.size() == 0) continue;

            // get the ranges covered in same_field_candidates
            bitvec shadowed_ranges;
            for (const auto & candidate : same_field_candidates) {
                shadowed_ranges.setrange(candidate.range().lo, candidate.range().size());
            }

            // only care about the ranges that are adjacent to fs_to_pack.
            auto packed_range = fs_to_pack.range();
            for (int i = packed_range.lo - 1; i >= 0; i--) {
                if (shadowed_ranges.getbit(i)) {
                    packed_range.lo = packed_range.lo - 1;
                } else {
                    break;
                }
            }
            for (int i = packed_range.hi + 1; i < fs_to_pack.field()->size; i++) {
                if (shadowed_ranges.getbit(i)) {
                    packed_range.hi = packed_range.hi + 1;
                } else {
                    break;
                }
            }

            // if the fs_to_pack is in packed_fs, ignore it.
            bool has_this_range = false;
            for (auto fs : packed_fs) {
                if (fs.field() != fs_to_pack.field()) continue;
                if (fs.range() == packed_range) {
                    has_this_range = true;
                    continue;
                }
                BUG_CHECK(!fs.range().overlaps(packed_range),
                    "pack range candidates should not overlap");
                BUG_CHECK(fs.range().hi != packed_range.lo - 1 &&
                    fs.range().lo - 1 != packed_range.hi,
                    "pack range candidates should not be next to each other");
            }
            if (has_this_range) continue;

            // We ask to pack the whole field for now.
            if ((fs_to_pack.field()->size != packed_range.size()) && packed_range.lo != 0)
                continue;

            packed_fs.insert(PHV::FieldSlice(fs_to_pack.field(), packed_range));
        }
    }
    return prepare_packing_solutions(cluster_groups, packed_fs);
}

PHV::SuperCluster* create_merged_cluster(
    const ordered_set<PHV::SuperCluster*>& superclusters,
    PHV::Field *field,
    const std::vector<le_bitrange> &sorted_fs_candidates
    ) {
    // create an empty sc
    auto merged_sc = new PHV::SuperCluster(
        ordered_set<const PHV::RotationalCluster*>(),
        ordered_set<PHV::SuperCluster::SliceList*>());
    for (auto sc : superclusters) {
        // remove the sc about to merge in clusters group
        merged_sc = merged_sc->merge(sc);
    }

    // inject alignments for these fieldslice
    BUG_CHECK(field->alignment == boost::none,
        "smart packing should not touch field with alignment");
    field->updateAlignment(
        PHV::AlignmentReason::PA_BYTE_PACK,
        FieldAlignment(le_bitrange(StartLen(0, field->size))),
        Util::SourceInfo());
    // refresh all fieldslice of this field in this supercluster.
    ordered_set<PHV::SuperCluster::SliceList*> refreshed_merged_sl;
    for (auto slicelist : merged_sc->slice_lists()) {
        auto refreshed_sl = new PHV::SuperCluster::SliceList;
        for (auto slice : *slicelist) {
                if (slice.field()->id == field->id) {
                    refreshed_sl->push_back(PHV::FieldSlice(field, slice.range()));
                } else {
                    refreshed_sl->push_back(slice);
                }
        }
        refreshed_merged_sl.insert(refreshed_sl);
    }

    // inject the extra slice list to pack these candidates.
    auto sl = new PHV::SuperCluster::SliceList;
    for (auto candidate : sorted_fs_candidates) {
        sl->push_back(PHV::FieldSlice(field, candidate));
    }
    refreshed_merged_sl.insert(sl);

    // create the refreshed rotational clusters.
    ordered_set<const PHV::RotationalCluster*> refreshed_merged_clusters;
    for (auto roc : merged_sc->clusters()) {
        ordered_set<PHV::AlignedCluster*> refreshed_clusters;
        for (auto cluster : roc->clusters()) {
            ordered_set<PHV::FieldSlice> refreshed_slices;
            for (auto slice : cluster->slices()) {
                if (slice.field()->id == field->id) {
                    refreshed_slices.insert(PHV::FieldSlice(field, slice.range()));
                } else {
                    refreshed_slices.insert(slice);
                }
            }

            refreshed_clusters.insert(
                new PHV::AlignedCluster(cluster->kind(), refreshed_slices));
        }

        refreshed_merged_clusters.insert(new PHV::RotationalCluster(refreshed_clusters));
    }

    // finalize the merged super cluster.
    merged_sc = new PHV::SuperCluster(refreshed_merged_clusters, refreshed_merged_sl);
    return merged_sc;
}

}

namespace PHV {

std::list<PHV::SuperCluster*> get_packed_cluster_group(
    const std::list<PHV::SuperCluster*> &cluster_groups,
    const TableFieldPackOptimization &table_pack_opt,
    PhvInfo &phv_i,
    AllocVerifier verifier,
    const PHV::Allocation& alloc) {
    const auto pack_choices = get_smart_packing_candidates(cluster_groups, table_pack_opt);
    // create a map from super cluster to a set of fieldslice as the result of packing. If
    // fieldslice is included in a supercluster, create the mapping. Also create the reverse mapping
    // in fs_to_sc.
    ordered_map<PHV::SuperCluster *, ordered_set<PHV::FieldSlice>> sc_to_fs;
    ordered_map<PHV::FieldSlice, PHV::SuperCluster *> fs_to_sc;
    for (auto pack_choice : pack_choices) {
        for (auto candidate : pack_choice) {
            auto fs = candidate.first;
            auto sc = candidate.second;
            sc_to_fs[sc].insert(fs);
            fs_to_sc[fs] = sc;
        }
    }
    // once sc_to_fs and fs_to_sc mapping are created, pack_choices will only be used to provide
    // fieldslice packing information. Pairing between a fieldslice and a supercluster should be
    // queried in sc_to_fs and fs_to_sc. sc_to_fs and fs_to_sc will be updated accordingly if any
    // superclusters are merged.

    auto current_cluster_groups = new std::list<PHV::SuperCluster*>(cluster_groups);
    auto original_cluster_groups = new std::list<PHV::SuperCluster*>(cluster_groups);
    for (auto pack_choice : pack_choices) {
        ordered_set<PHV::SuperCluster*> superclusters;
        ordered_set<le_bitrange> fs_candidates;
        for (auto pair : pack_choice) {
            fs_candidates.insert(pair.first.range());
            superclusters.insert(fs_to_sc[pair.first]);
        }
        std::vector<le_bitrange>
            sorted_fs_candidates(fs_candidates.begin(), fs_candidates.end());
        std::sort(sorted_fs_candidates.begin(), sorted_fs_candidates.end(),
            [](le_bitrange r1, le_bitrange r2) { return r1.hi < r2.hi; });

        BUG_CHECK(pack_choice.size(), "pack_choice should have at least one candidate");
        auto field = phv_i.field(pack_choice[0].first.field()->id);
        auto merged_sc = create_merged_cluster(superclusters, field, sorted_fs_candidates);
        for (auto sc : superclusters) {
            // remove the sc about to merge in clusters group
            current_cluster_groups->remove(sc);
        }
        current_cluster_groups->push_back(merged_sc);

        // try allocate this super cluster.
        std::list<PHV::SuperCluster *> single_cluster({merged_sc});
        auto unallocated = verifier(alloc.makeTransaction(), single_cluster);

        if (!unallocated.empty()) {
            // if allocation failed, roll back
            current_cluster_groups = new std::list<PHV::SuperCluster*>(*original_cluster_groups);
            // set field aligment to boost::none, and since the alignment of fieldslices in
            // original_cluster_groups remain unchanged, no need to roll back fieldslices' alignment
            field->alignment = boost::none;
            continue;
        }
        // save the latest feasible super clusters to original_cluster_groups
        original_cluster_groups = new std::list<PHV::SuperCluster*>(*current_cluster_groups);

        // if merging is validated, update fs_to_sc and sc_to_fs
        for (auto sc : superclusters) {
            for (auto fs_in_cluster_removed : sc_to_fs[sc]) {
                fs_to_sc[fs_in_cluster_removed] = merged_sc;
            }
        }
        for (auto sc : superclusters) {
            sc_to_fs[merged_sc].insert(sc_to_fs[sc].begin(), sc_to_fs[sc].end());
            sc_to_fs.erase(sc);
        }
    }
    return *current_cluster_groups;
}

}  // namespace PHV
