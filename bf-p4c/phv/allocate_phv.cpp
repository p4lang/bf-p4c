#include "bf-p4c/phv/allocate_phv.h"

#include <boost/format.hpp>
#include <boost/optional/optional_io.hpp>
#include <boost/range/adaptor/reversed.hpp>
#include <numeric>
#include <sstream>

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/device.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/optimize_phv.h"
#include "bf-p4c/phv/parser_extract_balance_score.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/slicing/phv_slicing_iterator.h"
#include "bf-p4c/phv/slicing/phv_slicing_split.h"
#include "bf-p4c/phv/utils/report.h"
#include "bf-p4c/phv/utils/slice_alloc.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/common/pragma/all_pragmas.h"
#include "lib/error.h"
#include "lib/log.h"
#include "lib/ordered_map.h"

// AllocScore metrics.
namespace {

using MetricName = AllocScore::MetricName;

// general
const MetricName n_tphv_on_phv_bits = "tphv_on_phv_bits";
const MetricName n_mocha_on_phv_bits = "mocha_on_phv_bits";
const MetricName n_dark_on_phv_bits = "dark_on_phv_bits";
const MetricName n_dark_on_mocha_bits = "dark_on_mocha_bits";
/// Number of bitmasked-set operations introduced by this transaction.
// Opt for the AllocScore, which minimizes the number of bitmasked-set instructions.
// This helps action data packing and gives table placement a better shot
// at fitting within the number of stages available on the device.

const MetricName n_bitmasked_set = "n_bitmasked_set";
/// Number of container bits wasted because POV slice lists/slices
/// do not fill the container wholly.
const MetricName n_wasted_pov_bits = "wasted_pov_bits";
const MetricName parser_extractor_balance = "parser_extractor_balance";
const MetricName n_inc_tphv_collections = "n_inc_tphv_collections";

// by kind
const MetricName n_set_gress = "n_set_gress";
const MetricName n_set_parser_group_gress = "n_set_parser_group_gress";
const MetricName n_set_deparser_group_gress = "n_set_deparser_group_gress";
const MetricName n_overlay_bits = "n_overlay_bits";
// how many wasted bits in partial container get used.
const MetricName n_packing_bits = "n_packing_bits";
// smaller, better.
const MetricName n_packing_priority = "n_packing_priority";
const MetricName n_inc_containers = "n_inc_containers";
// if solitary but taking a container larger than it.
const MetricName n_wasted_bits = "n_wasted_bits";
// use of 8/16 bit containers
const MetricName n_inc_small_containers = "n_inc_small_containers";
// The number of CLOT-eligible bits that have been allocated to PHV
// (JBay only).
const MetricName n_clot_bits = "n_clot_bits";
// The number of containers in a deparser group allocated to
// non-deparsed fields of a different gress than the deparser group.
const MetricName n_mismatched_deparser_gress = "n_mismatched_deparser_gress";

void log_packing_opportunities(
    const FieldPackingOpportunity* p, const std::list<PHV::SuperCluster*> sc) {
    if (LOGGING(4)) {
        if (p == nullptr) {
            LOG4("FieldPackingOpportunity is null.");
            return;
        }
        for (const auto* cluster : sc) {
            std::set<const PHV::Field*> showed;
            cluster->forall_fieldslices([&] (const PHV::FieldSlice& fs) {
                if (showed.count(fs.field())) return;
                showed.insert(fs.field());
                LOG4("Field " << fs.field() << " has " << p->nOpportunities(fs.field()));
            });
        }
    }
}

std::string str_supercluster_alignments(PHV::SuperCluster& sc, const AllocAlignment& align) {
    std::stringstream ss;
    ss << "slicelist alignments: " << "\n";
    for (const auto* sl : sc.slice_lists()) {
        ss << "[";
        cstring sep = "";
        for (const auto& fs : *sl) {
            ss << sep << "{" << fs << ", " << align.slice_alignment.at(fs) << "}";
            sep = ", ";
        }
        ss << "]" << "\n";
    }
    return ss.str();
}

// alloc_alignment_merge return merged alloc alignment if no conflict.
boost::optional<AllocAlignment> alloc_alignment_merge(
    const AllocAlignment& a, const AllocAlignment& b) {
    AllocAlignment rst;
    for (auto& alignment : std::vector<const AllocAlignment*>{&a, &b}) {
        // wont' be conflict
        for (auto& fs_int : alignment->slice_alignment) {
            rst.slice_alignment[fs_int.first] = fs_int.second;
        }
        // may conflict
        for (auto& cluster_int : alignment->cluster_alignment) {
            const auto* cluster = cluster_int.first;
            auto align = cluster_int.second;
            if (rst.cluster_alignment.count(cluster) &&
                rst.cluster_alignment[cluster] != align) {
                return boost::none;
            }
            rst.cluster_alignment[cluster] = align;
        }
    }
    return rst;
}

enum class CondIsBetter {equal, yes, no};

struct AllocScoreCmpCond {
    cstring name;
    int delta;
    bool is_positive_better;
    AllocScoreCmpCond(cstring name, int delta, bool is_positive_better) :
        name(name), delta(delta), is_positive_better(is_positive_better) {}

    CondIsBetter is_better() const {
        if (delta == 0) {
            return CondIsBetter::equal;
        }
        if (is_positive_better) {
            return delta > 0 ? CondIsBetter::yes : CondIsBetter::no;
        } else {
            return delta < 0 ? CondIsBetter::yes : CondIsBetter::no;
        }
    }
};

std::pair<bool, cstring> prioritized_cmp(std::vector<AllocScoreCmpCond> conds) {
    for (const auto& c : conds) {
        switch (c.is_better()) {
        case CondIsBetter::equal: { continue; break; }
        case CondIsBetter::yes:   { return {true, c.name}; }
        case CondIsBetter::no:    { return {false, c.name}; }
        }
    }
    return {false, "equal"};
}

ordered_map<MetricName, int> weighted_sum(const AllocScore& delta,
                                          const int dark_weight = 0,
                                          const int mocha_weight = 3,
                                          const int normal_weight = 3,
                                          const int tagalong_weight = 1) {
    ordered_map<MetricName, int> weighted_delta;
    for (auto kind : Device::phvSpec().containerKinds()) {
        int weight = 0;
        switch (kind) {
            case PHV::Kind::dark:  weight = dark_weight;        break;
            case PHV::Kind::mocha: weight = mocha_weight;       break;
            case PHV::Kind::normal:weight = normal_weight;      break;
            case PHV::Kind::tagalong:weight = tagalong_weight;  break;
        }
        if (weight == 0) {
            continue;
        }
        if (delta.by_kind.count(kind)) {
            const auto& ks = delta.by_kind.at(kind);
            for (const auto& m : AllocScore::g_by_kind_metrics) {
                if (!ks.count(m)) {
                    continue;
                }
                weighted_delta[m] += weight * ks.at(m);
            }
        }
    }
    return weighted_delta;
}

/** default_alloc_score_is_better
 * As of 04/07/2020, followings is the same heuristic set as the current master .
 */
bool default_alloc_score_is_better(const AllocScore& left, const AllocScore& right) {
    AllocScore delta = left - right;
    const int DARK_TO_PHV_DISTANCE = 2;
    int container_type_score = 0;
    if (Device::currentDevice() == Device::TOFINO) {
        container_type_score = delta.general[n_tphv_on_phv_bits];
    } else {
        container_type_score = DARK_TO_PHV_DISTANCE * delta.general[n_dark_on_phv_bits] +
                               delta.general[n_mocha_on_phv_bits] +
                               delta.general[n_dark_on_mocha_bits];
    }

    auto weighted_delta = weighted_sum(delta);
    std::vector<AllocScoreCmpCond> conds;
    if (Device::currentDevice() != Device::TOFINO) {
        conds = {
            {n_clot_bits, weighted_delta[n_clot_bits], false},
            {n_overlay_bits, weighted_delta[n_overlay_bits], true},  // if !tofino
            {"container_type_score",
             // XXX(yumin):
             // The code below simply wants to reproduce:
             // allocate_phv.cpp#L235 at 405005d67b1bb0e31c36cbb274518780bf86f1aa.
             container_type_score * int(weighted_delta[n_inc_containers] == 0), false},
            {n_wasted_pov_bits, delta.general[n_wasted_pov_bits], false},
            {n_inc_tphv_collections, delta.general[n_inc_tphv_collections], false},
            {n_bitmasked_set, delta.general[n_bitmasked_set], false},
            {n_inc_containers, weighted_delta[n_inc_containers], false},
            {n_wasted_bits, weighted_delta[n_wasted_bits], false},
            {n_packing_bits, weighted_delta[n_packing_bits], true},
            {n_packing_priority, weighted_delta[n_packing_priority], false},
            {n_set_gress, weighted_delta[n_set_gress], false},
            {n_set_deparser_group_gress, weighted_delta[n_set_deparser_group_gress], false},
            {n_set_parser_group_gress, weighted_delta[n_set_parser_group_gress], false},
            // suspicious why true?
            {n_mismatched_deparser_gress, weighted_delta[n_mismatched_deparser_gress], true},
        };
    } else {
        conds = {
            {parser_extractor_balance, delta.general[parser_extractor_balance], true},
            {n_clot_bits, weighted_delta[n_clot_bits], false},
            {"container_type_score", container_type_score, false},
            {n_inc_tphv_collections, delta.general[n_inc_tphv_collections], false},
            {n_bitmasked_set, delta.general[n_bitmasked_set], false},
            {n_inc_containers, weighted_delta[n_inc_containers], false},
            {n_overlay_bits, weighted_delta[n_overlay_bits], true},  // if tofino
            {n_wasted_bits, weighted_delta[n_wasted_bits], false},
            {n_packing_bits, weighted_delta[n_packing_bits], true},
            {n_packing_priority, weighted_delta[n_packing_priority], false},
            {n_set_gress, weighted_delta[n_set_gress], false},
            {n_set_deparser_group_gress, weighted_delta[n_set_deparser_group_gress], false},
            {n_set_parser_group_gress, weighted_delta[n_set_parser_group_gress], false},
            // suspicious why true?
            {n_mismatched_deparser_gress, weighted_delta[n_mismatched_deparser_gress], true},
        };
    }
    auto rst = prioritized_cmp(conds);
    if (rst.second != "equal") {
        LOG6((rst.first ? "better" : "worse") << ", because: " << rst.second);
    }

    return rst.first;
}

/** less_fragment_alloc_score_is_better
 * This is a generally better heuristic set: rules and priorities are reasonable compared
 * with the default one. We still keep the default one there because the compiler is still
 * buggy at this moment. If we entirely retired the default strategy, we will see a lot of
 * regressions because bugs are triggered.
 */
bool less_fragment_alloc_score_is_better(const AllocScore& left, const AllocScore& right) {
    AllocScore delta = left - right;
    auto weighted_delta = weighted_sum(delta, 0, 1, 3, 1);

    std::vector<AllocScoreCmpCond> conds;
    if (Device::currentDevice() == Device::TOFINO) {
        conds = {
            {n_tphv_on_phv_bits, delta.general[n_tphv_on_phv_bits], false},
            {n_wasted_bits, weighted_delta[n_wasted_bits], false},
            {n_inc_small_containers, weighted_delta[n_inc_small_containers], false},
            {n_inc_tphv_collections, delta.general[n_inc_tphv_collections], false},
            {n_inc_containers, weighted_delta[n_inc_containers], false},
            {n_overlay_bits, weighted_delta[n_overlay_bits], true},
            {n_packing_bits, weighted_delta[n_packing_bits], true},
            {n_packing_priority, weighted_delta[n_packing_priority], false},
            {n_bitmasked_set, delta.general[n_bitmasked_set], false},
            {parser_extractor_balance, delta.general[parser_extractor_balance], true},
            {n_set_gress, weighted_delta[n_set_gress], false},
            {n_set_deparser_group_gress, weighted_delta[n_set_deparser_group_gress], false},
            {n_set_parser_group_gress, weighted_delta[n_set_parser_group_gress], false},
            {n_mismatched_deparser_gress, weighted_delta[n_mismatched_deparser_gress], false},
        };
    } else {
        const int dark_penalty = 2;
        const int mocha_penalty = 3;
        int bad_container_bits = delta.general[n_tphv_on_phv_bits] +
                                   dark_penalty * delta.general[n_dark_on_phv_bits] +
                                   mocha_penalty * delta.general[n_mocha_on_phv_bits] +
                                   delta.general[n_dark_on_mocha_bits];
        conds = {
            {n_clot_bits, weighted_delta[n_clot_bits], false},
            {"bad_container_bits", bad_container_bits, false},
            {n_wasted_pov_bits, delta.general[n_wasted_pov_bits], false},
            {n_wasted_bits, weighted_delta[n_wasted_bits], false},
            // XXX(yumin): Starting with Tofino2, because of dark containers, we have to
            // promote the priority of overlay to almost the highest to encourage dark
            // overlay fields.
            {n_overlay_bits, weighted_delta[n_overlay_bits], true},
            {n_inc_small_containers, weighted_delta[n_inc_small_containers], false},
            {n_inc_containers, weighted_delta[n_inc_containers], false},
            {n_packing_bits, weighted_delta[n_packing_bits], true},
            {n_packing_priority, weighted_delta[n_packing_priority], false},
            {n_bitmasked_set, delta.general[n_bitmasked_set], false},
            {n_set_gress, weighted_delta[n_set_gress], false},
            {n_set_deparser_group_gress, weighted_delta[n_set_deparser_group_gress], false},
            {n_set_parser_group_gress, weighted_delta[n_set_parser_group_gress], false},
            {n_mismatched_deparser_gress, weighted_delta[n_mismatched_deparser_gress], false},
        };
    }

    auto rst = prioritized_cmp(conds);
    if (rst.second != "equal") {
        LOG6("left-hand-side score is better because: " << rst.second);
    }
    return rst.first;
}

/// @returns a new slice list where any adjacent slices of the same field with
/// contiguous little Endian ranges are merged into one slice, eg f[0:3], f[4:7]
/// become f[0:7].
const PHV::SuperCluster::SliceList*
mergeContiguousSlices(const PHV::SuperCluster::SliceList* list) {
    if (!list->size()) return list;

    auto* rv = new PHV::SuperCluster::SliceList();
    auto slice = list->front();
    for (auto it = ++list->begin(); it != list->end(); ++it) {
        if (slice.field() == it->field() && slice.range().hi == it->range().lo - 1)
            slice = PHV::FieldSlice(slice.field(), FromTo(slice.range().lo, it->range().hi));
        else
            rv->push_back(slice); }
    if (rv->size() == 0 || rv->back() != slice)
        rv->push_back(slice);
    return rv;
}

bool satisfies_container_type_constraints(const PHV::ContainerGroup& group,
                                          const PHV::AlignedCluster& cluster) {
    // Check that these containers support the operations required by fields in
    // this cluster.
    for (auto t : group.types()) {
        if (cluster.okIn(t.kind())) {
            return true;
        }
    }
    return false;
}

/// @returns a concrete allocation based on current phv info object.
PHV::ConcreteAllocation make_concrete_allocation(const PhvInfo& phv, const PhvUse& uses) {
    return PHV::ConcreteAllocation(phv, uses);
}

}  // namespace

const std::vector<MetricName> AllocScore::g_general_metrics = {
    n_tphv_on_phv_bits,
    n_mocha_on_phv_bits,
    n_dark_on_phv_bits,
    n_dark_on_mocha_bits,
    n_bitmasked_set,
    n_wasted_pov_bits,
    parser_extractor_balance,
    n_inc_tphv_collections,
};

const std::vector<MetricName> AllocScore::g_by_kind_metrics = {
    n_set_gress,
    n_set_parser_group_gress,
    n_set_deparser_group_gress,
    n_overlay_bits,
    n_packing_bits,
    n_packing_priority,
    n_inc_containers,
    n_wasted_bits,
    n_inc_small_containers,
    n_clot_bits,
    n_mismatched_deparser_gress,
};

AllocScore AllocScore::operator-(const AllocScore& right) const {
    AllocScore rst = *this;  // copy
    for (const auto& m : AllocScore::g_general_metrics) {
        rst.general[m] -= right.general.count(m) ? right.general.at(m) : 0;
    }

    for (auto kind : Device::phvSpec().containerKinds()) {
        if (!right.by_kind.count(kind)) {
            continue;
        }
        const auto& rs = right.by_kind.at(kind);
        for (const auto& m : AllocScore::g_by_kind_metrics) {
            if (rs.count(m)) {
                rst.by_kind[kind][m] -= rs.at(m);
            }
        }
    }
    return rst;
}

/** The metrics are calculated:
 * + is_tphv: type of @p group.
 * + n_set_gress:
 *     number of containers which set their gress
 *     to ingress/egress from boost::none.
 * + n_overlay_bits: container bits already used in parent alloc get overlaid.
 * + n_packing_bits: use bits that ContainerAllocStatus is PARTIAL in parent.
 * + n_inc_containers: the number of container used that was EMPTY.
 * + n_wasted_bits: if field is solitary, container.size() - slice.width().
 */
AllocScore::AllocScore(
        const PHV::Transaction& alloc,
        const PhvInfo& phv,
        const ClotInfo& clot,
        const PhvUse& uses,
        const MapFieldToParserStates& field_to_parser_states,
        const CalcParserCriticalPath& parser_critical_path,
        FieldPackingOpportunity* packing_opportunities,
        const int bitmasks) {
    using ContainerAllocStatus = PHV::Allocation::ContainerAllocStatus;
    const auto* parent = alloc.getParent();

    general[n_bitmasked_set] = bitmasks;

    ordered_set<std::pair<const PHV::Field*, PHV::Container>> wasted_bits_counted;

    // Forall allocated slices group by container.
    for (const auto& kv : alloc.getTransactionStatus()) {
        const auto& container = kv.first;
        const auto kind = container.type().kind();
        const auto& gress = kv.second.gress;
        const auto& parserGroupGress = kv.second.parserGroupGress;
        const auto& deparserGroupGress = kv.second.deparserGroupGress;
        bitvec parent_alloc_vec = calcContainerAllocVec(parent->slices(container));
        // The set of slices that are allocated in this transaction, by subtracting out
        // slices allocated in parent, robust in that @p alloc can commit things that
        // are already in the parent.
        auto slices = kv.second.slices;
        for (const auto& slice : parent->slices(container)) {
            slices.erase(slice); }

        // skip, if there is no allocated slices.
        if (slices.size() == 0)
            continue;

        // Calculate number of wasted container bits, if POV bits are present in this container.
        size_t n_pov_bits = 0;
        for (const auto& slice : slices)
            if (slice.field()->pov)
                n_pov_bits += slice.width();
        if (n_pov_bits != 0)
            general[n_wasted_pov_bits] +=
                (container.size() > n_pov_bits ? (container.size() - n_pov_bits) : 0);

        // calc n_wasted_bits and n_clot_bits
        for (const auto& slice : slices) {
            if (!slice.field()->is_solitary()) continue;
            PHV::FieldSlice field_slice(slice.field(), slice.field_slice());
            if (wasted_bits_counted.count({slice.field(), container})) {
                // correct over-counted bits
                by_kind[kind][n_wasted_bits] -= slice.field()->size;
            } else {
                // Assume all other bits are wasted because of this slice.
                // The number will be corrected when fieldslice of the same field
                // enter the if branch above.
                by_kind[kind][n_wasted_bits] += (container.size() - field_slice.size());
                wasted_bits_counted.insert({slice.field(), container});
            }
        }

        // calc n_clot_bits
        for (const auto& slice : slices) {
            // Loop over all CLOT-allocated slices that overlap with "slice" and add the number of
            // overlapping bits to the score.
            PHV::FieldSlice field_slice(slice.field(), slice.field_slice());
            const auto& slice_range = field_slice.range();
            for (auto* clotted_slice : Keys(*clot.slice_clots(&field_slice))) {
                const auto& clot_range = slice_range.intersectWith(clotted_slice->range());
                by_kind[kind][n_clot_bits] += clot_range.size();
            }
        }

        if (kind == PHV::Kind::normal) {
            for (const auto& slice : slices) {
                PHV::FieldSlice fieldSlice(slice.field(), slice.field_slice());
                if (Device::currentDevice() == Device::TOFINO) {
                    if (fieldSlice.is_tphv_candidate(uses))
                        general[n_tphv_on_phv_bits] += (slice.width());
                } else {
                    if (slice.field()->is_mocha_candidate())
                        general[n_mocha_on_phv_bits] += (slice.width());
                    else if (slice.field()->is_dark_candidate())
                        general[n_dark_on_phv_bits] += (slice.width());
                }
            }
        }

        if (kind == PHV::Kind::mocha)
            for (const auto& slice : slices)
                if (slice.field()->is_dark_candidate())
                    general[n_dark_on_mocha_bits] += (slice.width());

        // calc_n_inc_containers
        auto merged_status = alloc.alloc_status(container);
        auto parent_status = parent->alloc_status(container);
        if (parent_status == ContainerAllocStatus::EMPTY
            && merged_status != ContainerAllocStatus::EMPTY) {
            by_kind[kind][n_inc_containers]++;

            // calc n_inc_small_containers
            if (container.size() < 32 && container.type().kind() == PHV::Kind::normal) {
                by_kind[kind][n_inc_small_containers]++;
            }
        }

        if (parent_status == ContainerAllocStatus::PARTIAL) {
            // calc n_packing_bits
            for (auto i = container.lsb(); i <= container.msb(); ++i) {
                if (parent_alloc_vec[i]) continue;
                for (const auto& slice : slices) {
                    if (slice.container_slice().contains(i)) {
                        by_kind[kind][n_packing_bits]++;
                        break; }
                }
            }

            // calc n_packing_priority.
            if (packing_opportunities && by_kind[kind][n_packing_bits]) {
                int n_packing_priorities = 100000;  // do not use max because it might overflow.
                for (auto i = container.lsb(); i <= container.msb(); ++i) {
                    for (const auto& p_slice : parent->slices(container)) {
                        for (const auto& slice : slices) {
                            if (p_slice.container_slice().contains(i)
                                && slice.container_slice().contains(i)) {
                                auto* f1 = p_slice.field();
                                auto* f2 = slice.field();
                                n_packing_priorities = std::min(
                                    n_packing_priorities,
                                    packing_opportunities->nOpportunitiesAfter(f1, f2));
                            }
                        }
                    }
                }
                by_kind[kind][n_packing_priority] = n_packing_priorities;
            }
        }

        // calc n_overlay_bits
        for (const int i : parent_alloc_vec) {
            for (const auto& slice : slices) {
                if (slice.container_slice().contains(i)) {
                    by_kind[kind][n_overlay_bits]++; } } }

        // If overlay is between multiple fields in the same transaction,
        // then that value needs to be calculated separately.
        int overlay_bits = 0;
        for (const auto& slice1 : slices) {
            for (const auto& slice2 : slices) {
                if (slice1 == slice2) continue;
                for (unsigned int i = 0; i < container.size(); i++) {
                    if (slice1.container_slice().contains(i) &&
                            slice2.container_slice().contains(i))
                        overlay_bits++; } } }
        // Slices are counted twice in the above loop, so divide by 2.
        by_kind[kind][n_overlay_bits] += (overlay_bits / 2);

        // gress
        if (!parent->gress(container) && gress) {
            by_kind[kind][n_set_gress]++;
            if (gress != deparserGroupGress)
                by_kind[kind][n_mismatched_deparser_gress]++; }

        // Parser group gress
        if (!parent->parserGroupGress(container) && parserGroupGress) {
            by_kind[kind][n_set_parser_group_gress]++; }

        // Deparser group gress
        if (!parent->deparserGroupGress(container) && deparserGroupGress) {
            by_kind[kind][n_set_deparser_group_gress]++; }
    }

    // calc_n_inc_tphv_collections
    if (Device::currentDevice() == Device::TOFINO) {
        auto my_tphv_collections = alloc.getTagalongCollectionsUsed();
        auto parent_tphv_collections = parent->getTagalongCollectionsUsed();
        for (auto col : my_tphv_collections) {
            if (!parent_tphv_collections.count(col))
                general[n_inc_tphv_collections]++;
        }
    }

    if (Device::currentDevice() == Device::TOFINO) {
        // This only matters for Tofino.
        // For JBay, all extractors are of same size (16-bit).
        calcParserExtractorBalanceScore(alloc, phv, field_to_parser_states, parser_critical_path);
    }
}

void AllocScore::calcParserExtractorBalanceScore(const PHV::Transaction& alloc, const PhvInfo& phv,
        const MapFieldToParserStates& field_to_parser_states,
        const CalcParserCriticalPath& parser_critical_path) {
    const auto* parent = alloc.getParent();

    ordered_map<const IR::BFN::ParserState*, std::set<PHV::Container>> critical_state_to_containers;

    auto& my_state_to_containers = alloc.getParserStateToContainers(phv, field_to_parser_states);
    auto& parent_state_to_containers =
        parent->getParserStateToContainers(phv, field_to_parser_states);

    // If program has user specified critical states, we will only compute score for those.
    //
    // Otherwise, we compute the score on the critical path (path with most extracted bits),
    // if --parser-bandwidth-opt is turned on.
    //
    if (!parser_critical_path.get_ingress_user_critical_states().empty() ||
        !parser_critical_path.get_egress_user_critical_states().empty()) {
        for (auto& kv : my_state_to_containers) {
            if (parser_critical_path.is_user_specified_critical_state(kv.first))
                critical_state_to_containers[kv.first].insert(kv.second.begin(), kv.second.end());
        }

        for (auto& kv : parent_state_to_containers) {
            if (parser_critical_path.is_user_specified_critical_state(kv.first))
                critical_state_to_containers[kv.first].insert(kv.second.begin(), kv.second.end());
        }
    } else if (BackendOptions().parser_bandwidth_opt) {
        for (auto& kv : my_state_to_containers) {
            if (parser_critical_path.is_on_critical_path(kv.first))
                critical_state_to_containers[kv.first].insert(kv.second.begin(), kv.second.end());
        }

        for (auto& kv : parent_state_to_containers) {
            if (parser_critical_path.is_on_critical_path(kv.first))
                critical_state_to_containers[kv.first].insert(kv.second.begin(), kv.second.end());
        }
    }

    for (auto& kv : critical_state_to_containers) {
        StateExtractUsage use(kv.second);
        general[parser_extractor_balance] += ParserExtractScore::get_score(use);
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
    s << "{";
    for (const auto& m : AllocScore::g_general_metrics) {
        if (m == n_wasted_pov_bits && Device::currentDevice() == Device::TOFINO) {
            continue;
        }
        if (score.general.count(m) && score.general.at(m) > 0) {
            s << m << ": " << score.general.at(m) << ", ";
        }
    }

    for (auto kind : Device::phvSpec().containerKinds()) {
        if (!score.by_kind.count(kind))
            continue;
        s << kind << "[";
        for (const auto& m : AllocScore::g_by_kind_metrics) {
            if (score.by_kind.at(kind).count(m) && score.by_kind.at(kind).at(m) > 0) {
                s << m << ": " << score.by_kind.at(kind).at(m) << ", ";
            }
        }
        s << "], ";
    }
    s << "}";
    return s;
}

AllocScore AllocContext::make_score(
    const PHV::Transaction& alloc,
    const PhvInfo& phv,
    const ClotInfo& clot,
    const PhvUse& uses,
    const MapFieldToParserStates& f_ps,
    const CalcParserCriticalPath& cp,
    const int bitmasks) const {
    return AllocScore(
        alloc, phv, clot, uses, f_ps, cp, packing_opportunities_i, bitmasks);
}


/* static */
bool CoreAllocation::can_overlay(
        const SymBitMatrix& mutex,
        const PHV::Field* f,
        const ordered_set<PHV::AllocSlice>& slices) {
    for (auto slice : slices)
        if (!mutex(f->id, slice.field()->id))
            return false;
    return true;
}

bool CoreAllocation::satisfies_constraints(
        const PHV::ContainerGroup& group,
        const PHV::Field* f) const {
    // Check that TM deparsed fields aren't split
    if (f->no_split() && int(group.width()) < f->size) {
        LOG5("        constraint: can't split field size " << f->size << " across " << group.width()
             << " containers");
        return false; }
    return true;
}

bool CoreAllocation::satisfies_constraints(
        const PHV::ContainerGroup& group,
        const PHV::FieldSlice& slice) const {
    auto req = pragmas_i.pa_container_sizes().expected_container_size(slice);
    if (req && !group.is(*req)) {
        LOG5("        constraint: @pa_container_size mark that: "
             << slice << " must go to " << *req << " container ");
        return false; }
    return satisfies_constraints(group, slice.field());
}

bool CoreAllocation::satisfies_constraints(
        std::vector<PHV::AllocSlice> slices,
        const PHV::Allocation& alloc) const {
    if (slices.size() == 0) return true;

    // pa_container_type constraint check
    auto& pa_ct = pragmas_i.pa_container_type();
    for (const auto& slice : slices) {
        auto required_kind = pa_ct.required_kind(slice.field());
        if (required_kind && *required_kind != slice.container().type().kind()) {
            return false;
        }
    }

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
        return (slice.field()->deparsed() || slice.field()->exact_containers());
    };
    auto IsDeparsedOrDigest = [](const PHV::AllocSlice& slice) {
        return (slice.field()->deparsed() || slice.field()->exact_containers() ||
                slice.field()->is_digest());
    };
    if (std::any_of(slices.begin(), slices.end(), IsDeparsed)) {
        // Reject mixes of deparsed/not deparsed fields.
        if (!std::all_of(slices.begin(), slices.end(), IsDeparsedOrDigest)) {
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

    // Check if any fields have the solitary constraint, which is mutually
    // unsatisfiable with slice lists, which induce packing.  Ignore adjacent slices of the same
    // field.
    std::vector<PHV::AllocSlice> used;
    ordered_set<const PHV::Field*> pack_fields;
    for (auto& slice : slices) {
        bool isDeparsedOrMau = uses_i.is_deparsed(slice.field()) ||
            uses_i.is_used_mau(slice.field());
        bool overlayablePadding = slice.field()->overlayable;
        if (isDeparsedOrMau && !overlayablePadding)
            used.push_back(slice);
        if (!slice.field()->is_solitary()) pack_fields.insert(slice.field());
    }
    auto NotAdjacent = [](const PHV::AllocSlice& left, const PHV::AllocSlice& right) {
            return left.field() != right.field() ||
                   left.field_slice().hi + 1 != right.field_slice().lo ||
                   left.container_slice().hi + 1 != right.container_slice().lo;
        };
    auto NoPack = [](const PHV::AllocSlice& s) { return s.field()->is_solitary(); };
    bool not_adjacent = std::adjacent_find(used.begin(), used.end(), NotAdjacent) != used.end();
    bool solitary = std::find_if(used.begin(), used.end(), NoPack) != used.end();
    if (not_adjacent && solitary) {
        if (!std::all_of(pack_fields.begin(), pack_fields.end(), [](const PHV::Field* f) {
                    return f->padding;
                })) {
            LOG5("    ...but slice list contains multiple fields and one has the 'no pack' "
                 "constraint");
            return false; } }

    // Check sum of constraints.
    ordered_set<const PHV::Field*> containerBytesFields;
    ordered_map<const PHV::Field*, int> allocatedBitsInThisTransaction;
    for (auto& slice : slices) {
        if (slice.field()->hasMaxContainerBytesConstraint())
            containerBytesFields.insert(slice.field());
        allocatedBitsInThisTransaction[slice.field()] += slice.width();
    }

    // Check that slices that appear in wide arithmetic operations
    // are being allocated to the correct odd/even container number.
    for (auto& alloc_slice : slices) {
        if (alloc_slice.field()->used_in_wide_arith()) {
            auto cidx = alloc_slice.container().index();
            int lo_bit = alloc_slice.field_slice().lo;
            LOG7("   cidx = " << cidx << " and lo_bit = " << lo_bit);
            if (alloc_slice.field()->bit_is_wide_arith_lo(lo_bit)) {
                if ((cidx % 2) != 0) {
                    LOG5("    cannot start wide arith lo at odd container.");
                    return false; }
            } else {
                if ((cidx % 2) == 0) {
                    LOG5("    cannot start wide arith hi at even container.");
                    return false; }

                // Find the lo AllocSlice for the field.
                // Check that it is one less than the current container.
                // Note: Allocation approach assumes that the lo slice is
                // allocated before the hi.
                bool found = false;
                for (auto &as : alloc.slices(alloc_slice.field())) {
                    // It is possible that there are multiple slices in the hi part of the
                    // slice list. E.g. field[32:47], field[48:63]. So for the latter field, we need
                    // to check the lo_bit corresponding to the nearest 32-bit interval. The
                    // following transformation of lo_bit is, therefore, necessary.
                    lo_bit -= (lo_bit % 32);
                    if (as.field() == alloc_slice.field()) {
                        int lo_bit2 = as.field_slice().lo;
                        if (lo_bit2 == (lo_bit - 32)) {
                            found = true;
                            LOG6("   Found linked lo slice " << as);
                            auto lo_container_idx = as.container().index();
                            if (cidx != (lo_container_idx + 1)) {
                                LOG5("    cannot start wide arith hi at non-adjacent container.");
                                return false; }
                            break; } } }
                BUG_CHECK(found, "Unable to find lo field slice associated with"
                          " wide arithmetic operation %1%", alloc_slice);
            }
        } }

    bool isExtracted = false;
    for (auto slice : slices) {
        if (uses_i.is_extracted(slice.field())) {
            isExtracted = true;
            break;
        }
    }
    // Check if two different fields are extracted in different mutex states
    // - Two different field can be extracted in same state
    // - Same field can be extracted in two non-mutex state(This includes clear-on-writes,
    //   and local parser variables)
    // - Constant extracts and strided headers are excluded
    int container_size = 0;
    if (isExtracted) {
        ordered_map<const IR::BFN::ParserState*, bitvec> state_to_vec;
        cstring prev_field;
        for (auto slice : slices) {
            auto field = slice.field();
            container_size = slice.container().size();
            if (field->padding || field->pov || field->is_solitary())
                continue;
            if (!field_to_parser_states_i.field_to_extracts.count(slice.field()))
                continue;
            if (strided_headers_i.get_strided_group(field))
                continue;
            for (auto extract : field_to_parser_states_i.field_to_extracts.at(field)) {
                auto state = field_to_parser_states_i.extract_to_state.at(extract);
                if ((extract->write_mode) == IR::BFN::ParserWriteMode::CLEAR_ON_WRITE)
                    continue;
                if (auto range = extract->source->to<IR::BFN::PacketRVal>()) {
                    if (!state_to_vec.count(state) && prev_field != field->name) {
                       auto parser = field_to_parser_states_i.state_to_parser.at(state);
                       for (auto &sv : state_to_vec) {
                           if (!parser_info_i.graph(parser).is_mutex(sv.first, state)) {
                               LOG5("    ...fields in the slice list are extracted"
                                    " in non-mutex states " << sv.first->name << " and "
                                    << state->name);
                               return false;
                           }
                       }
                    }
                    auto extract_field = extract->dest->to<IR::BFN::FieldLVal>();
                    auto slice_range = slice.field_slice();
                    // If extraction happens over a field slice, then find if this
                    // particular slice is being extracted or not
                    if (auto extract_slice = extract_field->field->to<IR::Slice>()) {
                        int min = std::min(slice_range.hi,
                                      extract_slice->e1->to<IR::Constant>()->asInt());
                        int max = std::max(slice_range.lo,
                                      extract_slice->e2->to<IR::Constant>()->asInt());
                        // overlap range of field_slice and extract_slice is [max,min]
                        if (max <= min) {
                            state_to_vec[state].setrange(range->range.lo + max, (min - max));
                        }
                    } else {
                        state_to_vec[state].setrange(range->range.hi - slice.field_slice().hi,
                                                 slice.width());
                    }
                }
                prev_field = field->name;
            }
        }
        for (auto& sv : state_to_vec) {
            if (sv.second.max().index() - sv.second.min().index() + 1 > container_size) {
                LOG5("    ...extraction size exceeds container size. Illegal extraction");
                return false;
            }
        }
    }

    // If there are no fields that have the max container bytes constraints, then return true.
    if (containerBytesFields.size() == 0) return true;

    PHV::Container container = slices.begin()->container();
    int containerBits = 0;
    LOG6("Container bit: " << containerBits);
    for (const auto* f : containerBytesFields) {
        auto allocated_slices = alloc.slices(f);
        ordered_set<PHV::Container> containers;
        int allocated_bits = 0;
        for (auto& slice : allocated_slices) {
            LOG6("Slice: " << slice);
            containers.insert(slice.container());
            allocated_bits += slice.width();
        }
        if (allocated_bits != f->size)
            allocated_bits += allocatedBitsInThisTransaction.at(f);
        containers.insert(container);
        int unallocated_bits = f->size - allocated_bits;
        for (auto& c : containers) {
            LOG6("Container: " << c);
            containerBits += static_cast<int>(c.size());
        }
        LOG6("Field: " << f->name);
        LOG6("  allocated_bits: " << allocated_bits << ", container_bits: " << containerBits <<
             ", unallocated_bits: " << unallocated_bits);
        BUG_CHECK(containerBits % 8 == 0, "Sum of container bits cannot be non byte multiple.");
        int containerBytes = (containerBits / 8) + ROUNDUP(unallocated_bits, 8);
        if (containerBytes > f->getMaxContainerBytes()) {
            LOG5("    ...but allocation would violate maximum container bytes allowed for field " <<
                 f->name);
            return false;
        }
    }
    return true;
}

// NB: action-induced PHV constraints are checked separately as part of
// `can_pack` on slice lists.
bool CoreAllocation::satisfies_constraints(
        const PHV::Allocation& alloc,
        PHV::AllocSlice slice,
        ordered_set<PHV::AllocSlice>& initFields) const {
    const PHV::Field* f = slice.field();
    PHV::Container c = slice.container();
    auto container_status = alloc.getStatus(c);

    // Check gress.
    auto containerGress = alloc.gress(c);
    if (containerGress && *containerGress != f->gress) {
        LOG5("        constraint: container " << c << " is " << *containerGress <<
                    " but slice needs " << f->gress);
        return false; }

    // Check parser group constraints.

    auto parserGroupGress = alloc.parserGroupGress(c);
    bool isExtracted = uses_i.is_extracted(f);

    // Check 1: all containers within parser group must have same gress assignment
    if (parserGroupGress) {
        if ((isExtracted || singleGressParserGroups) && (*parserGroupGress != f->gress)) {
            LOG5("        constraint: container " << c << " has parser group gress " <<
                 *parserGroupGress << " but slice needs " << f->gress <<
                 " (singleGressParserGroups = " << singleGressParserGroups << ")");
            return false;
        }
    }

    // Check 2: all constainers within parser group must have same parser write mode
    if (isExtracted && parserGroupGress) {
        const PhvSpec& phvSpec = Device::phvSpec();
        unsigned slice_cid = phvSpec.containerToId(slice.container());

        boost::optional<IR::BFN::ParserWriteMode> write_mode;
        for (auto sl : (*container_status).slices) {
            auto container_field = sl.field();
            if (container_field == f) {
                continue;
            }
            if (!field_to_parser_states_i.field_to_extracts.count(container_field))
                continue;
            for (auto ef : field_to_parser_states_i.field_to_extracts.at(f)) {
                auto ef_state = field_to_parser_states_i.extract_to_state.at(ef);
                for (auto esl : field_to_parser_states_i.field_to_extracts.at(container_field)) {
                    auto esl_state = field_to_parser_states_i.extract_to_state.at(esl);
                    // A container cannot have same extract in same state
                    if (esl_state == ef_state && ef->source->equiv(*esl->source) &&
                         ef->source->is<IR::BFN::PacketRVal>()) {
                        LOG5("Slices of field " << f << " and " << container_field <<
                             " have same extract source in the same state " << esl_state->name
                             << " which is illegal");
                        return false;
                    }
                }
            }
        }

        if (field_to_parser_states_i.field_to_extracts.count(f)) {
            for (auto e : field_to_parser_states_i.field_to_extracts.at(f)) {
                write_mode = e->write_mode;
            }
        }

        BUG_CHECK(write_mode, "parser write mode not exist for extracted field %1%", f->name);
        for (unsigned cid : phvSpec.parserGroup(slice_cid)) {
            auto other = phvSpec.idToContainer(cid);
            auto cs = alloc.getStatus(other);
            if (c == other)
                continue;

            if (cs) {
                for (auto sl : (*cs).slices) {
                    if (!field_to_parser_states_i.field_to_extracts.count(sl.field()))
                        continue;

                    boost::optional<IR::BFN::ParserWriteMode> other_write_mode;

                    for (auto e : field_to_parser_states_i.field_to_extracts.at(sl.field())) {
                        other_write_mode = e->write_mode;
                        // See P4C-3033 for more details
                        // In tofino2, all extractions happen using 16b extracts.
                        // So a 16-bit parser extractor extracts over a pair of even and
                        // odd phv 8-bit containers to perforn 8-bit extraction.
                        // If any of 8 -bit containers in the pair  are in CLEAR_ON_WRITE mode,
                        // then both containers will be cleared everytime an extraction happens.
                        // In order to avoid this corruption, if one container in the
                        // pair in in CLEAR_ON_WRITE mode, the other is not used in parser.
                        if (*other_write_mode == IR::BFN::ParserWriteMode::CLEAR_ON_WRITE) {
                            LOG5("        constraint: container " << c <<
                              " has parser write mode " << *write_mode << " but "
                              << other << " has parser write mode " << *other_write_mode <<
                              " which is conflicting");
                            return false;
                        }
                    }

                    if (*write_mode != *other_write_mode) {
                        LOG5("        constraint: container " << c << " has parser write mode " <<
                              *write_mode << " but " << other << " in parser group has conflicting"
                              " write mode " << *other_write_mode);

                        return false;
                    }
                }
            }
        }
    }

    // Check deparser group gress.
    auto deparserGroupGress = alloc.deparserGroupGress(c);
    bool isDeparsed = uses_i.is_deparsed(f);
    if (isDeparsed && deparserGroupGress && *deparserGroupGress != f->gress) {
        LOG5("        constraint: container " << c << " has deparser group gress " <<
             *deparserGroupGress << " but slice needs " << f->gress);
        return false; }

    // true if @a is the same field allocated right before @b. e.g.
    // B1[0:1] <- f1[0:1], B1[2:7] <- f1[2:7]
    auto is_aligned_same_field_alloc = [](PHV::AllocSlice a, PHV::AllocSlice b) {
        if (a.field() != b.field() || a.container() != b.container()) {
            return false;
        }
        if (a.container_slice().hi > b.container_slice().hi) {
            std::swap(a, b);
        }
        return  b.field_slice().lo - a.field_slice().hi ==
            b.container_slice().lo - a.container_slice().hi;
    };
    // Check no pack for this field.
    const auto& slices = alloc.slicesByLiveness(c, slice);
    std::vector<PHV::FieldSlice> liveFieldSlices;
    ordered_set<PHV::FieldSlice> initFieldSlices;
    for (auto& sl : slices) {
        // XXX(yumin): aligned fieldslice from the same field can be ignored
        if (is_aligned_same_field_alloc(slice, sl)) {
            continue;
        }
        liveFieldSlices.push_back(PHV::FieldSlice(sl.field(), sl.field_slice()));
    }
    for (auto& sl : initFields) {
        // XXX(yumin): aligned fieldslice from the same field can be ignored
        if (is_aligned_same_field_alloc(slice, sl)) {
            continue;
        }
        initFieldSlices.insert(PHV::FieldSlice(sl.field(), sl.field_slice()));
    }
    if (slices.size() > 0 && slice.field()->is_solitary()) {
        for (auto& sl : slices) {
            LOG5("\t\t\tChecking no-pack for live slice: " << sl);
            if (slice.isLiveRangeDisjoint(sl) ||
                (slice.container_slice().overlaps(sl.container_slice()) &&
                 phv_i.isMetadataMutex(sl.field(), slice.field()))) {
                LOG5("\t\t\t  Ignoring because of disjoint live range");
                continue;
            }
            LOG5("        constraint: slice has solitary constraint but container has slices ");
            return false;
        }
    }

    // Check no pack for any other fields already in the container.
    for (auto& sl : slices) {
        if (sl.field()->is_solitary()) {
            if (slice.isLiveRangeDisjoint(sl) ||
                (slice.container_slice().overlaps(sl.container_slice()) &&
                 phv_i.isMetadataMutex(slice.field(), sl.field())))
                continue;
            LOG5("        constraint: field " << sl.field()->name << " has solitary constraint and "
                 "is already placed in this container");
            return false; } }

    // pov bits are parser initialized as well.
    // discount slices that are going to be initialized through metadata initialization from being
    // considered uninitialized reads.
    bool hasOtherUninitializedRead =
        std::any_of(liveFieldSlices.begin(), liveFieldSlices.end(), [&](const PHV::FieldSlice& s) {
            return s.field()->pov
                || (defuse_i.hasUninitializedRead(s.field()->id) && !initFieldSlices.count(s));
        });

    bool hasOtherExtracted = std::any_of(
            liveFieldSlices.begin(), liveFieldSlices.end(), [&] (const PHV::FieldSlice& s) {
                    return !s.field()->pov && uses_i.is_extracted(s.field()) &&
                        !uses_i.is_extracted_from_constant(s.field());
    });

    bool isThisSliceExtracted = !slice.field()->pov && uses_i.is_extracted(slice.field());
    bool isThisSliceUninitialized = (slice.field()->pov
            || (defuse_i.hasUninitializedRead(slice.field()->id) && !initFields.count(slice) &&
                !pragmas_i.pa_no_init().getFields().count(slice.field())));

    bool hasExtractedTogether = std::all_of(
            liveFieldSlices.begin(), liveFieldSlices.end(), [&] (const PHV::FieldSlice& s) {
        auto extracted_together = phv_i.are_bridged_extracted_together(slice.field(), s.field());
        LOG5("check if " << slice.field() << " and " << s.field()
                << " are extracted together " << extracted_together);
        return extracted_together;
    });

    if (hasOtherExtracted && !hasExtractedTogether &&
        (isThisSliceUninitialized || isThisSliceExtracted)) {
        LOG5("        constraint: container already contains extracted slices, "
             "can not be packed, because: this slice is "
             << (isThisSliceExtracted ? "extracted" : "uninitialized"));
        return false; }

    // Account for metadata initialization and ensure that initialized fields are not considered
    // uninitialized any more.
    if (isThisSliceExtracted && (hasOtherUninitializedRead || hasOtherExtracted)) {
        if (!hasExtractedTogether || !hasOtherUninitializedRead) {
            LOG5("        constraint: this slice is extracted, "
                 "can not be packed, because allocated fields has "
                 << (hasOtherExtracted ? "extracted" : "uninitialized"));
            return false; } }

    return true;
}

/* static */
bool
CoreAllocation::satisfies_constraints(const PHV::ContainerGroup& g, const PHV::SuperCluster& sc) {
    // Check max individual field width.
    if (int(g.width()) < sc.max_width()) {
        LOG5("    ...but container size " << g.width() <<
             " is too small for max field width " << sc.max_width());
        return false; }

    // Check max slice list width.
    for (auto* slice_list : sc.slice_lists()) {
        int size = 0;
        for (auto& slice : *slice_list)
            size += slice.size();
        if (int(g.width()) < size) {
            LOG5("    ...but container size " << g.width() <<
                 " is too small for slice list width " << size);
            return false; } }

        // Check container type.
        for (const auto* rot : sc.clusters()) {
            for (const auto* ali : rot->clusters()) {
                auto rst = satisfies_container_type_constraints(g, *ali);
                if (!rst) {
                    LOG5("    ...but ContainerGroup type cannot satisfy cluster constraints");
                    return false;
                }
            }
        }

        return true;
    }

boost::optional<PHV::Transaction>
CoreAllocation::tryAllocSliceList(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const PHV::SuperCluster& super_cluster,
        const PHV::SuperCluster::SliceList& slice_list,
        const ordered_map<PHV::FieldSlice, int>& start_positions,
        const AllocContext& score_ctx) const {
    PHV::Allocation::ConditionalConstraint start_pos;
    for (auto fs : slice_list) {
        start_pos[fs] = PHV::Allocation::ConditionalConstraintData(start_positions.at(fs));
    }
    return tryAllocSliceList(alloc, group, super_cluster, start_pos, score_ctx);
}


// ALEX : Check for overlapping liveranges between slices of non-overlapping bitranges
bool CoreAllocation::hasCrossingLiveranges(std::vector<PHV::AllocSlice> candidate_slices,
                                           ordered_set<PHV::AllocSlice> alloc_slices) const {
    bool lr_overlap = false;  // candidate liverange overlaps with allocated liverage?
    for (auto& cnd_slice : candidate_slices) {
        std::set<int> write_stages;
        if (cnd_slice.getEarliestLiveness().second.isWrite())
            write_stages.insert(cnd_slice.getEarliestLiveness().first);
        if (cnd_slice.getLatestLiveness().second.isWrite())
            write_stages.insert(cnd_slice.getLatestLiveness().first);
        if (write_stages.size() == 0) continue;

        for (auto& alc_slice : alloc_slices) {
            if (alc_slice.field() == cnd_slice.field())
                continue;

            if (alc_slice.container() != cnd_slice.container())
                continue;

            // Check non bitrange-overlapping slices (missed by phv_action_constraints)
            if (!alc_slice.container_slice().overlaps(cnd_slice.container_slice())) {
                for (int stg : write_stages) {
                    if ((stg >= alc_slice.getEarliestLiveness().first) &&
                        (stg < alc_slice.getLatestLiveness().first)) {
                        lr_overlap = true;
                        LOG4("\t\t Found overlapping liverange between allocated " <<
                             alc_slice << " and candidate " << cnd_slice);
                    }

                    if ((stg == alc_slice.getLatestLiveness().first) &&
                        alc_slice.getLatestLiveness().second.isWrite()) {
                        lr_overlap = true;
                        LOG4("\t\t Found overlapping liverange between allocated " <<
                             alc_slice << " and candidate " << cnd_slice);
                    }
                }
            }
        }
        if (lr_overlap) break;
    }
    if (lr_overlap)
        LOG4("\t\t Stop considering mocha container due to overlapping liveranges"
             " of candidate slices with allocated slices in non-oevrlapping container "
             "bitrange");

    return lr_overlap;
}

// Check dark mutex of all candidates and build bitvec of container
// slice corresponding to dark mutex slices. If the bitvec is not contiguous
// then turn off ARA initializations; instead use regular table inits
bool CoreAllocation::checkDarkOverlay(std::vector<PHV::AllocSlice> candidate_slices,
                                      PHV::Transaction alloc) const {
    bitvec cntr_bits;

    for (auto sl : candidate_slices) {
        const auto& alloced_slices = alloc.slices(sl.container(), sl.container_slice());

        // Find slices that can be dark overlaid
        if (can_overlay(phv_i.dark_mutex(), sl.field(), alloced_slices)) {
            // Skip the ones that can also be meta and parser overlaid
            if (can_overlay(phv_i.metadata_mutex(), sl.field(), alloced_slices) ||
                can_overlay(mutex_i, sl.field(), alloced_slices)) continue;

            // *ALEX* TODO: Could add checks for liveranges if initializations
            //              may happen at different stages

            // Update bitvec
            le_bitrange cntr_slice = sl.container_slice();
            cntr_bits.setrange(cntr_slice.lo, cntr_slice.size());
        }
    }

    return cntr_bits.is_contiguous();
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
        const PHV::Allocation::ConditionalConstraint& start_positions,
        const AllocContext& score_ctx) const {
    // Collect up the field slices to be allocated.
    PHV::SuperCluster::SliceList slices;
    for (auto& kv : start_positions)
        slices.push_back(kv.first);

    PHV::Transaction alloc_attempt = alloc.makeTransaction();
    int container_size = int(group.width());

    // Set previous_container to the container provided as part of start_positions, if any.
    PHV::Container previous_container;
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
            if (previous_container == PHV::Container())
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
        if (previous_container != PHV::Container() &&
                previous_container != alloc_slice.container()) {
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

    // Return if the slices can't fit together in a container.
    //
    // Compute the aggregate size required for the slices before comparing against the container
    // size. As we do this, figure out whether we have a wide arithmetic lo operation and find the
    // associated hi field slice.
    int aggregate_size = 0;
    bool wide_arith_lo = false;
    PHV::SuperCluster::SliceList *hi_slice = nullptr;
    for (auto& slice : slices) {
        aggregate_size += slice.size();
        if (slice.field()->bit_used_in_wide_arith(slice.range().lo)) {
            if (slice.field()->bit_is_wide_arith_lo(slice.range().lo)) {
                wide_arith_lo = true;
                hi_slice = super_cluster.findLinkedWideArithSliceList(&slices);
                BUG_CHECK(hi_slice, "Unable to find hi field slice associated with"
                          " wide arithmetic operation in the cluster %1%", super_cluster);
                LOG7("   \nthink slice is wide arith lo: " << slice);
                LOG7("   found linked slice list: " << hi_slice);
            } }
    }  // end for (auto& slice : slices)
    if (container_size < aggregate_size) {
        LOG5("    ...but these slices are " << aggregate_size << "b in total and cannot fit in a "
             << container_size << "b container");
        return boost::none; }

    // Look for a container to allocate all slices in.
    AllocScore best_score = AllocScore::make_lowest();
    boost::optional<PHV::Transaction> best_candidate = boost::none;
    for (const PHV::Container& c : group) {
        LOG5("    trying allocate to " << c);

        // If any slices were already allocated, ensure that unallocated slices
        // are allocated to the same container.
        if (previous_container != PHV::Container() && previous_container != c) {
            LOG5("    ...but some slices were already allocated to " << previous_container);
            continue;
        }

        // true if field slices can be placed in this container.
        bool can_place = true;

        // Generate candidate_slices if we choose this container.
        std::vector<PHV::AllocSlice> candidate_slices;
        std::vector<PHV::AllocSlice> new_candidate_slices;
        for (auto& field_slice : slices) {
            if (c.is(PHV::Kind::mocha) && !field_slice.field()->is_mocha_candidate()) {
                LOG5("    ..." << c << " cannot contain the non-mocha field slice " << field_slice);
                can_place = false;
                break;
            }
            if (c.is(PHV::Kind::dark) && !field_slice.field()->is_dark_candidate()) {
                LOG5("    ..." << c << " cannot contain the non-dark field slice " << field_slice);
                can_place = false;
                break;
            }
            le_bitrange container_slice =
                StartLen(start_positions.at(field_slice).bitPosition, field_slice.size());
            // Field slice has a const Field*, so get the non-const version using the PhvInfo object
            candidate_slices.push_back(PHV::AllocSlice(phv_i.field(field_slice.field()->id),
                        c, field_slice.range(), container_slice));
        }
        if (!can_place) continue;

        // Check slice list<-->container constraints.
        if (!satisfies_constraints(candidate_slices, alloc_attempt)) continue;


        // Check that there's space.
        // Results of metadata initialization. This is a map of field to the initialization actions
        // determined by FindInitializationNode methods.
        boost::optional<PHV::Allocation::LiveRangeShrinkingMap> initNodes = boost::none;
        boost::optional<ordered_set<PHV::AllocSlice>> allocedSlices = boost::none;
        // The metadata slices that require initialization after live range shrinking.
        ordered_set<PHV::AllocSlice> metaInitSlices;
        PHV::Transaction perContainerAlloc = alloc_attempt.makeTransaction();
        // Flag case that overlay requires new container such as dark overlay
        bool new_overlay_container = false;
        bool canDarkInitUseARA = checkDarkOverlay(candidate_slices, perContainerAlloc);
        // Check that the placement can be done through metadata initialization.
        for (auto& slice : candidate_slices) {
            if (!uses_i.is_referenced(slice.field()) && !slice.field()->isGhostField()) continue;
            // Skip slices that have already been allocated.
            if (previous_allocations.find(PHV::FieldSlice(slice.field(), slice.field_slice()))
                    != previous_allocations.end())
                continue;
            const auto& alloced_slices =
                perContainerAlloc.slices(slice.container(), slice.container_slice());
            LOG6("    Can we overlay " << slice.field() << " on " << alloced_slices);
            LOG6("      Parser overlay: " << can_overlay(mutex_i, slice.field(), alloced_slices));
            LOG6("      Metadata overlay: " << can_overlay(phv_i.metadata_mutex(), slice.field(),
                        alloced_slices));
            LOG6("      Dark overlay: " << can_overlay(phv_i.dark_mutex(), slice.field(),
                        alloced_slices));
            if (alloced_slices.size() > 0 && can_overlay(mutex_i, slice.field(), alloced_slices)) {
                LOG5("    ...and can overlay " << slice << " on " << alloced_slices);
                new_candidate_slices.push_back(slice);
            } else if (alloced_slices.size() > 0) {
                // If there are slices already allocated for these container bits, then check if
                // overlay is enabled by live shrinking is possible. If yes, then note down
                // information about the initialization required and allocated slices for later
                // constraint verification.
                bool is_mocha_or_dark = c.is(PHV::Kind::dark) || c.is(PHV::Kind::mocha);
                // Get non parser-mutually-exclusive slices allocated in container c
                PHV::Allocation::MutuallyLiveSlices container_state =
                    perContainerAlloc.slicesByLiveness(c, candidate_slices);
                // Actual slices in the container, after accounting for metadata overlay.
                PHV::Allocation::MutuallyLiveSlices actual_cntr_state;
                for (auto& field_slice : container_state) {
                    bool sliceOverlaysAllCandidates = true;
                    for (auto& candidate_slice : candidate_slices) {
                        if (!phv_i.metadata_mutex()(
                                field_slice.field()->id, candidate_slice.field()->id))
                                sliceOverlaysAllCandidates = false;
                    }
                    if (sliceOverlaysAllCandidates) continue;
                    actual_cntr_state.insert(field_slice);
                }
                // Disable metadata initialization if the container for metadata overlay is a mocha
                // or dark container.
                // XXX(Deep): P4C-1187
                if (!is_mocha_or_dark && can_overlay(phv_i.metadata_mutex(), slice.field(),
                            alloced_slices)) {
                    bool prevDeparserZero = std::all_of(alloced_slices.begin(),
                            alloced_slices.end(), [](const PHV::AllocSlice& a) {
                        return a.field()->is_deparser_zero_candidate();
                    });
                    if (prevDeparserZero && !slice.field()->is_deparser_zero_candidate()) {
                        LOG5("    ...and cannot metadata overlay on deparsed zero container " << c);
                        can_place = false;
                        break;
                    }

                    LOG5("    ...and can overlay " << slice << " on " << alloced_slices <<
                         " with metadata initialization.");
                    initNodes = meta_init_i.findInitializationNodes(alloced_slices, slice,
                            perContainerAlloc, actual_cntr_state);
                    bool noInitPresent = true;
                    if (!initNodes) {
                        LOG5("       ...but cannot find initialization points.");
                        can_place = false;
                        break;
                    } else {
                        can_place = true;
                        allocedSlices = alloced_slices;
                        new_candidate_slices.push_back(slice);
                        LOG5("       ...found the following initialization points:");
                        LOG5(meta_init_i.printLiveRangeShrinkingMap(*initNodes, "\t\t"));
                        // For the initialization plan returned, note the fields that would need to
                        // be initialized in the MAU.
                        for (auto kv : *initNodes) {
                            if (kv.second.size() > 0) noInitPresent = false;
                            if (!slice.field()->is_padding() && kv.first == slice.field()) {
                                LOG5("\t\tA. Inserting " << slice << " into metaInitSlices");
                                metaInitSlices.insert(slice);
                                continue; }
                            for (const auto& sl : alloced_slices) {
                                if (!sl.field()->is_padding() && kv.first == sl.field()) {
                                    LOG5("\t\tB. Inserting " << sl << " into metaInitSlices");
                                    metaInitSlices.insert(sl);
                                    continue; } } } }
                    if (!noInitPresent && disableMetadataInit) {
                        LOG5("       ...but live range shrinking requiring metadata initialization "
                             "is disabled in this round");
                        can_place = false;
                        break;
                    }
                } else if (!c.is(PHV::Kind::dark) && can_overlay(phv_i.dark_mutex(), slice.field(),
                            alloced_slices)) {
                    LOG5("    ...and can overlay " << slice << " on " << alloced_slices <<
                         " by pushing one of them into a dark container.");
                    auto darkInitNodes = dark_init_i.findInitializationNodes(
                        group, alloced_slices, slice, perContainerAlloc, canDarkInitUseARA);
                    if (!darkInitNodes) {
                        LOG5("       ...but cannot find initialization points for dark "
                             "containers.");
                        can_place = false;
                        break;
                    } else {
                        // Create initialization points for the dark container.
                        if (!generateNewAllocSlices(slice, alloced_slices, *darkInitNodes,
                                                    new_candidate_slices, perContainerAlloc,
                                                    actual_cntr_state)) {
                            LOG5("\t\tNew dark primitives extend previously defined slice "
                                 "live ranges; thus skipping container " << c);
                            can_place = false;
                            break; }

                        can_place = true;
                        LOG5("    ...found " << darkInitNodes->size() <<
                             " initialization points for dark containers.");
                        unsigned primNum = 0;
                        for (auto& prim : *darkInitNodes) {
                            LOG5("\t\t" << prim);
                            if (primNum++ == 0) continue;
                            metaInitSlices.insert(prim.getDestinationSlice());
                        }
                        new_overlay_container = true;

                        // XXX(ALEX) We should  populate InitNodes with darkInitNodes to later
                        // properly populate initActions
                        // TODO(ALEX)
                    }
                } else {
                    LOG5("    ...but " << c << " already contains slices at this position");
                    can_place = false;
                    break; }
            } else {
                new_candidate_slices.push_back(slice);
            }
        }
        if (!can_place) continue;  // try next container

        if ((new_candidate_slices.size() > 0) ||
            (new_overlay_container && (metaInitSlices.size() > 0))) {
            candidate_slices.clear();
            for (auto& sl : new_candidate_slices)
                candidate_slices.push_back(sl);
            if (new_overlay_container) {
                for (auto& sl : metaInitSlices)
                    candidate_slices.push_back(sl);
            }
        }

        if (LOGGING(5) && metaInitSlices.size() > 0) {
            LOG5("\t  Printing all fields for whom metadata has been initialized");
            for (const auto& sl : metaInitSlices)
                LOG5("\t\t" << sl); }

        if (LOGGING(6)) {
            LOG6("\t\tCandidate slices:");
            for (auto& slice : candidate_slices) LOG6("\t\t  " << slice);
            LOG6("\t\tExisting slices in container: " << c);
            for (auto& slice : perContainerAlloc.slices(c)) LOG6("\t\t\t" << slice);
        }

        // check pa_container_type constraints for candidates after dark overlay.
        bool pa_container_type_ok = true;
        for (const auto& sl : candidate_slices) {
            auto req_kind = pragmas().pa_container_type().required_kind(sl.field());
            if (req_kind && sl.container().type().kind() != *req_kind) {
                LOG5("\t\t not possible because @pa_container_type specify that "
                     << sl.field() << " must be allocated to " << *req_kind << ", so "
                     << sl.container() << " is not allowed");
                pa_container_type_ok = false;
                break;
            }
        }
        if (!pa_container_type_ok) {
            continue;
        }

        // ALEX : Add special handling for dark overlays of Mocha containers
        //        - If the overlaying candidate slice liverange overlaps
        //          with the liverange of other existing slices in the container
        //          then do skip the dark overlay
        if (new_overlay_container && c.is(PHV::Kind::mocha)) {
            if (hasCrossingLiveranges(candidate_slices, perContainerAlloc.slices(c)))
                continue;
        }

        // Check that each field slice satisfies slice<-->container
        // constraints, skipping slices that have already been allocated.
        bool constraints_ok =
            std::all_of(candidate_slices.begin(), candidate_slices.end(),
                [&](const PHV::AllocSlice& slice) {
                    PHV::FieldSlice fs(slice.field(), slice.field_slice());
                    bool alloced = previous_allocations.find(PHV::FieldSlice(fs)) !=
                                   previous_allocations.end();
                    return alloced ? true : satisfies_constraints(perContainerAlloc, slice,
                            metaInitSlices); });
        if (!constraints_ok) {
            initNodes = boost::none;
            allocedSlices = boost::none;
            continue; }

        // Maintain a list of conditional constraints that are already a part of a slice list that
        // follows the required alignment. Therefore, we do not need to recursively call
        // tryAllocSliceList() for those slice lists because those slice lists will be allocated at
        // the required alignment later on during the allocation of the supercluster.
        std::set<int> conditionalConstraintsToErase;
        // Check whether the candidate slice allocations respect action-induced constraints.
        CanPackErrorCode canPackErrorCode;
        boost::optional<PHV::Allocation::ConditionalConstraints> action_constraints;
        PHV::Allocation::LiveRangeShrinkingMap initActions;

        // Gather the initialization actions for all the fields that are allocated to/are candidates
        // for allocation in this container. All these are summarized in the initActions map.
        for (auto& field_slice : candidate_slices) {
            // Get the initialization actions for all the field slices that are candidates for
            // allocation and in the parent transaction.
            auto initPointsForTransaction = perContainerAlloc.getInitPoints(field_slice);
            if (initPointsForTransaction && initPointsForTransaction->size() > 0)
                initActions[field_slice.field()].insert(initPointsForTransaction->begin(),
                        initPointsForTransaction->end());
        }
        // Get the initialization actions that were determined as part of the current transaction.
        if (initNodes) {
            for (auto kv : *initNodes) {
                initActions[kv.first].insert(kv.second.begin(), kv.second.end());
                LOG6("\t\t\tAdding initActions for field: " << kv.first);
            }
        }

        // -  Populate actual_container_state with allocated slices that
        //    do not have overlap with any of the candidate_slices
        // - Also update initActions with the actions of the slices in actual_container_state
        PHV::Allocation::MutuallyLiveSlices container_state = perContainerAlloc.slicesByLiveness(c,
                candidate_slices);
        // Actual slices in the container, after accounting for metadata overlay.
        PHV::Allocation::MutuallyLiveSlices actual_container_state;
        for (auto& field_slice : container_state) {
            bool sliceLiveRangeDisjointWithAllCandidates = true;
            auto Overlaps = [&](const PHV::AllocSlice& slice) {
                return slice.container_slice().overlaps(field_slice.container_slice());
            };
            // Check if any of the candidate slices being considered for allocation overlap with the
            // slice already in the container. Even if one of the slices overlaps, it is considered
            // a case of metadata overlay enabled by live range shrinking.
            bool hasOverlay = std::any_of(candidate_slices.begin(), candidate_slices.end(),
                Overlaps);
            for (auto& candidate_slice : candidate_slices) {
                if (!phv_i.metadata_mutex()(
                            field_slice.field()->id, candidate_slice.field()->id))
                    sliceLiveRangeDisjointWithAllCandidates = false;
            }
            // If the current slice overlays with at least one candidate slice AND its live range
            // does not overlap with the candidate slices, we do not consider the existing slice to
            // be part of the live container state.
            LOG6("\t\tKeep container_state slice " << field_slice << " in actual_container_state:"
                 << ((hasOverlay && sliceLiveRangeDisjointWithAllCandidates) ? "NO" : "YES") );
            if (hasOverlay && sliceLiveRangeDisjointWithAllCandidates) continue;
            actual_container_state.insert(field_slice);
            // Get initialization actions for all other slices in this container and not overlaying
            // with the candidate fields.
            auto initPointsForTransaction = perContainerAlloc.getInitPoints(field_slice);
            if (initPointsForTransaction && initPointsForTransaction->size() > 0)
                initActions[field_slice.field()].insert(initPointsForTransaction->begin(),
                        initPointsForTransaction->end());
        }

        if (initActions.size() > 0)
            LOG5("Printing total initialization map:\n" <<
                 meta_init_i.printLiveRangeShrinkingMap(initActions, "\t\t"));

        if (LOGGING(6)) {
            LOG6("Candidates sent to ActionPhvConstraints:");
            for (auto& slice : candidate_slices) LOG6("  " << slice);
        }

        std::tie(canPackErrorCode, action_constraints) =
            actions_i.can_pack(perContainerAlloc, candidate_slices,
                    actual_container_state, initActions, super_cluster);
        bool creates_new_container_conflicts =
            actions_i.creates_container_conflicts(actual_container_state, initActions,
                    meta_init_i.getTableActionsMap());
        // If metadata initialization causes container conflicts to be created, then do not use this
        // allocation.
        if (action_constraints && initActions.size() > 0 && creates_new_container_conflicts) {
            LOG5("\t\t...action constraint: creates new container conflicts for this packing."
                 " cannot pack into container " << c << canPackErrorCode);
            continue;
        }

        int num_bitmasks = 0;
        if (!action_constraints) {
            LOG5("        ...action constraint: cannot pack into container " << c
                    << canPackErrorCode);
            continue;
        } else if (action_constraints->size() > 0) {
            if (LOGGING(5)) {
                LOG5("    ...but only if the following placements are respected:");
                for (auto kv_source : *action_constraints) {
                    LOG5("      Source " << kv_source.first);
                    for (auto kv : kv_source.second) {
                        std::stringstream ss;
                        ss << "        " << kv.first << " @ " << kv.second.bitPosition;
                        if (kv.second.container)
                            ss << " and @container " << *(kv.second.container);
                        LOG5(ss.str()); } } }

            // Find slice lists that contain slices in action_constraints.
            can_place = true;
            for (auto kv_source : *action_constraints) {
                auto slice_list =
                    boost::make_optional<const PHV::SuperCluster::SliceList *>(false, 0);
                for (auto& slice_and_pos : kv_source.second) {
                    const auto& slice_lists = super_cluster.slice_list(slice_and_pos.first);
                    if (slice_lists.size() > 1) {
                        // If a slice is in multiple slice lists, abort.
                        // XXX(cole): This is overly constrained.
                        LOG5("    ...but a conditional placement is in multiple slice lists");
                        can_place = false;
                        break;
                    } else if (slice_lists.size() == 0) {
                        // XXX(yumin): this seems to be too conservative. We can craft a slice
                        // list to satisfy the condition constraint, as long as the slicelist
                        // is valid.
                        if (slice_list) {
                            LOG5("    ...but slice " << slice_and_pos.first << " is not in a "
                                 "slice list, while other slices in the same conditional constraint"
                                 " is in a slice list.");
                            can_place = false;
                            break;
                        } else {
                            // not in a slicelist ignored.
                            continue;
                        }
                    }

                    auto* candidate = slice_lists.front();
                    if (slice_list) {
                        auto& fs1 = slice_list.get()->front();
                        auto& fs2 = candidate->front();
                        if (fs1.field()->exact_containers() != fs2.field()->exact_containers()) {
                            LOG5("    ...but two slice cannot be placed in one container because "
                                 "different exact_containers: "<< fs1 << " " << fs2);
                            can_place = false;
                            break;
                        }
                        // XXX(yumin): Even with above fix, this conditional constraint
                        // slicelist allocation is still wrong. It overwrites previous
                        // slice_list found for one constraint, which does not make
                        // sense here. We need a further fix for this behavior.
                    }
                    slice_list = candidate;
                }
                // Try the next container.
                if (!can_place) break;

                // At this point, all conditional placements for this source are in the same slice
                // list. If the alignments check out, we do not need to apply the conditional
                // constraints for this source.
                if (slice_list) {
                    // Check that the positions induced by action constraints match
                    // the positions in the slice list.  The offset is relative to
                    // the beginning of the slice list until the first
                    // action-constrained slice is encountered, at which point the
                    // offset is set to the required offset.
                    LOG5("      ...Found field in another slice list.");
                    int offset = 0;
                    bool absolute = false;
                    int size = 0;
                    auto requiredContainer = boost::make_optional(false, PHV::Container());
                    std::map<PHV::FieldSlice, int> bitPositions;
                    for (auto& slice : **slice_list) {
                        size += slice.range().size();
                        if (kv_source.second.find(slice) == kv_source.second.end()) {
                            bitPositions[slice] = offset;
                            offset += slice.range().size();
                            continue; }

                        int required_pos = kv_source.second.at(slice).bitPosition;
                        if (requiredContainer && *requiredContainer !=
                                kv_source.second.at(slice).container)
                            BUG("Error setting up conditional constraints: Multiple containers "
                                "%1% and %2% found", *requiredContainer,
                                kv_source.second.at(slice).container);
                        requiredContainer = kv_source.second.at(slice).container;
                        if (!absolute && required_pos < offset) {
                            // This is the first slice with an action alignment constraint.  Check
                            // that the constraint is >= the bits seen so far. If this check fails,
                            // then set can_place to false so that we may try the next container.
                            LOG5("    ...action constraint: " << slice << " must be placed at bit "
                                 << required_pos << " but is " << offset << "b deep in a slice " <<
                                 "list");
                            can_place = false;
                            break;
                        } else if (!absolute) {
                            absolute = true;
                            offset = required_pos + slice.range().size();
                        } else if (offset != required_pos) {
                            // If the alignment due to the conditional constraint is not the same as
                            // the alignment inherent in the slice list structure, then this
                            // placement is not possible. So set can_place to false so that we may
                            // try the next container.
                            LOG5("    ...action constraint: " << slice << " must be placed at bit "
                                 << required_pos << " which conflicts with another action-induced "
                                 "constraint for another slice in the slice list");
                            can_place = false;
                            break;
                        } else {
                            offset += slice.range().size();
                        }
                    }

                    if (requiredContainer) {
                        for (auto& slice : **slice_list) {
                            if (kv_source.second.find(slice) != kv_source.second.end()) continue;
                            BUG_CHECK(bitPositions.count(slice),
                                    "Cannot calculate offset for slice %1%", slice);
                            (*action_constraints)[kv_source.first][slice] =
                                PHV::Allocation::ConditionalConstraintData(bitPositions.at(slice),
                                        *requiredContainer);
                        }
                    } else {
                        // If we've reached here, then all the slices that have conditional
                        // constraints are in slice_list at the right required alignment. Therefore,
                        // we can mark this source for erasure from the conditional constraints map.
                        conditionalConstraintsToErase.insert(kv_source.first);
                    }
                }
            }
        } else {
            LOG5("        ...action constraint: can pack into container " << c);
            if (initNodes)
                num_bitmasks = actions_i.count_bitmasked_set_instructions(candidate_slices,
                        *initNodes);
            else
                num_bitmasks = actions_i.count_bitmasked_set_instructions(candidate_slices,
                        initActions);
        }

        if (!can_place) continue;
        // alloc_attempt.commit(perContainerAlloc);

        if (conditionalConstraintsToErase.size() > 0) {
            for (auto i : conditionalConstraintsToErase) {
                LOG5("\t\tErasing conditional constraint associated with source #" << i);
                (*action_constraints).erase(i);
            }
        }

        // Create this alloc for calculating score.
        // auto this_alloc = alloc_attempt.makeTransaction();
        auto this_alloc = perContainerAlloc.makeTransaction();
        for (auto& slice : candidate_slices) {
            bool is_referenced = uses_i.is_referenced(slice.field());
            bool is_allocated =
                previous_allocations.find(PHV::FieldSlice(slice.field(), slice.field_slice()))
                    != previous_allocations.end();
            if ((is_referenced || slice.field()->isGhostField()) && !is_allocated) {
                if (initNodes && initNodes->count(slice.field())) {
                    // For overlay enabled by live range shrinking, we also need to store
                    // initialization information as a member of the allocated slice.
                    this_alloc.allocate(slice, initNodes, singleGressParserGroups);
                    LOG5("\t\tFound initialization point for metadata field " <<
                            slice.field()->name);
                } else {
                    this_alloc.allocate(slice, boost::none, singleGressParserGroups); }
            } else if (!is_referenced && !slice.field()->isGhostField()) {
                LOG5("NOT ALLOCATING unreferenced field: " << slice); } }

        // Add metadata initialization information for previous allocated slices. As more and more
        // slices get allocated, the initialization actions for already allocated slices in the
        // container may change. So, update the initialization information in these already
        // allocated slices based on the latest initialization plan.
        if (initNodes && allocedSlices) {
            for (auto& slice : *allocedSlices) {
                if (initNodes->count(slice.field())) {
                    LOG5("        Initialization noted corresponding to already allocated slice: "
                            << slice);
                    this_alloc.addMetadataInitialization(slice, *initNodes); } } }

        // Recursively try to allocate slices according to conditional
        // constraints induced by actions.  NB: By allocating the current slice
        // list first, we guarantee that recursion terminates, because each
        // invocation allocates fields or fails before recursion, and there are
        // finitely many fields.
        bool conditional_constraints_satisfied = true;
        for (auto kv : *action_constraints) {
            if (kv.second.size() > 0) {
                auto action_alloc =
                    tryAllocSliceList(
                        this_alloc, group, super_cluster, kv.second, score_ctx);
                if (!action_alloc) {
                    LOG5("    ...but slice list has conditional constraints that cannot be "
                         "satisfied");
                    conditional_constraints_satisfied = false;
                    break; }
                LOG5("    ...and conditional constraints are satisfied");
                this_alloc.commit(*action_alloc); } }

        if (!conditional_constraints_satisfied)
            continue;

        // If this is a wide arithmetic lo operation, make sure
        // the most significant slices can be allocated in the directly
        // adjacent container -- either the container is free or can overlay.
        // Do this here, after lo slice has been committed to transaction.
        if (wide_arith_lo) {
            std::vector<PHV::AllocSlice> hi_candidate_slices;
            bool can_alloc_hi = false;
            for (const auto& next_container : group) {
                if ((c.index() + 1) != next_container.index()) {
                    continue;
                }
                LOG5("Checking adjacent container " << next_container);
                const std::vector<PHV::Container> one_container = {next_container};
                // so confusing, parameter size here means bit width,
                // but group.size() returns the number of containers.
                auto small_grp = PHV::ContainerGroup(group.width(), one_container);

                auto hi_alignments = build_slicelist_alignment(
                    small_grp, super_cluster, hi_slice);
                if (hi_alignments.empty()) {
                    LOG6("Couldn't build hi alignments");
                    can_alloc_hi = false;
                    break;
                }

                for (const auto& alloc_align : hi_alignments) {
                    auto try_hi = tryAllocSliceList(
                        this_alloc, small_grp, super_cluster, *hi_slice,
                        alloc_align.slice_alignment, score_ctx);
                    if (try_hi != boost::none) {
                        LOG5("Wide arith hi slice could be allocated in " << next_container);
                        LOG5("" << hi_slice);
                        can_alloc_hi = true;
                        // XXX(yumin): try_hi is not commited???
                        break;
                    }
                }
                break;
            }
            if (!can_alloc_hi) {
              LOG5("Wide arithmetic hi slice could not be allocated.");
              continue;
            } else {
              LOG5("Wide arithmetic hi slice could be allocated.");
            }
        }
        perContainerAlloc.commit(this_alloc);

        // auto score = AllocScore(this_alloc, phv_i, clot_i, uses_i,
        auto score = score_ctx.make_score(
            perContainerAlloc, phv_i, clot_i, uses_i,
            field_to_parser_states_i, parser_critical_path_i, num_bitmasks);
        LOG5("    ...SLICE LIST score for container " << c << ": " << score);

        // update the best
        if ((!best_candidate || score_ctx.is_better(score, best_score))) {
            LOG5("       ...Best score for container " << c);
            best_score = score;
            // best_candidate = std::move(this_alloc); }
            best_candidate = std::move(perContainerAlloc);
        }
    }  // end of for containers

    if (!best_candidate) {
        LOG5("    ...hence there is no suitable candidate");
        return boost::none; }

    alloc_attempt.commit(*best_candidate);
    return alloc_attempt;
}  // NOLINT(readability/fn_size)


// Used for dark overlays - Replaces original slice allocation with
// new slice allocation and spilled slice allocation in dark and normal
// ---
bool CoreAllocation::generateNewAllocSlices(
        const PHV::AllocSlice& origSlice,
        const ordered_set<PHV::AllocSlice>& alloced_slices,
        PHV::DarkInitMap& slices,
        std::vector<PHV::AllocSlice>& new_candidate_slices,
        PHV::Transaction& alloc_attempt,
        const PHV::Allocation::MutuallyLiveSlices& container_state) const {
    std::vector<PHV::AllocSlice> initializedAllocSlices;
    for (auto& entry : slices) {  // Iterate over the initialization of the new field and the dark
                                                  // allocated field (spill + write-back)
        LOG5("\t\t\tDarkInitEntry: " << entry);
        auto dest = entry.getDestinationSlice();
        LOG5("\t\t\tAdding dest: " << dest);
        dest.setInitPrimitive(&(entry.getInitPrimitive()));

        // Also update the lifetime of prior/post prims related to the source slice
        for (auto *prim : dest.getInitPrimitive()->getARApostPrims()) {
            bool sameEarly = (dest.getEarliestLiveness() ==
                              prim->getDestinationSlice().getEarliestLiveness());
            bool sameLate  = (dest.getLatestLiveness() ==
                              prim->getDestinationSlice().getLatestLiveness());
            BUG_CHECK(sameEarly || sameLate, "A.None of the liverange bounds is the same ...?");

            if (sameEarly && !sameLate) {
                LOG4("\t\tA.Updating latest liveness for: " << prim->getDestinationSlice());
                LOG4("\t\t\t to " << dest.getLatestLiveness());
                prim->setDestinationLatestLiveness(dest.getLatestLiveness());
            }

            if (!sameEarly && sameLate) {
                LOG4("\t\tA.Updating earliest liveness for: " << prim->getDestinationSlice());
                LOG4("\t\t\t to " << dest.getEarliestLiveness());
                prim->setDestinationEarliestLiveness(dest.getEarliestLiveness());
            }
        }

        for (auto *prim : dest.getInitPrimitive()->getARApriorPrims()) {
            bool sameEarly = (dest.getEarliestLiveness() ==
                              prim->getDestinationSlice().getEarliestLiveness());
            bool sameLate  = (dest.getLatestLiveness() ==
                              prim->getDestinationSlice().getLatestLiveness());
            BUG_CHECK(sameEarly || sameLate, "B.None of the liverange bounds is the same ...?");

            if (sameEarly && !sameLate) {
                LOG4("\t\tB.Updating latest liveness for: " << prim->getDestinationSlice());
                LOG4("\t\t\t to " << dest.getLatestLiveness());
                prim->setDestinationLatestLiveness(dest.getLatestLiveness());
            }

            if (!sameEarly && sameLate) {
                LOG4("\t\tB.Updating earliest liveness for: " << prim->getDestinationSlice());
                LOG4("\t\t\t to " << dest.getEarliestLiveness());
                prim->setDestinationEarliestLiveness(dest.getEarliestLiveness());
            }
        }

        initializedAllocSlices.push_back(dest);
    }
    std::vector<PHV::AllocSlice> rv;
    LOG5("\t\t\tOriginal candidate slice: " << origSlice);
    bool foundAnyNewSliceForThisOrigSlice = false;
    PHV::Container dstCntr = origSlice.container();
    // Create mapping from sources of writes to bitranges for each stage
    std::map<int, std::map<PHV::Container, bitvec> > perStageSources2Ranges;
    for (auto& newSlice : initializedAllocSlices) {
        // Init stage of newSlice
        int initStg = newSlice.getEarliestLiveness().first;
        // srcCntr is not set for zeroInits and NOPs
        PHV::Container srcCntr = PHV::Container();

        BUG_CHECK(newSlice.getInitPrimitive(), "DarkInitPrimitive does not exist?");

        if (newSlice.getInitPrimitive()->getSourceSlice())
            srcCntr = newSlice.getInitPrimitive()->getSourceSlice()->container();

        le_bitrange cBits = newSlice.container_slice();

        if (newSlice.container() == dstCntr && !newSlice.getInitPrimitive()->isNOP()) {
            perStageSources2Ranges[initStg][srcCntr].setrange(cBits.lo, cBits.size());

        if (srcCntr == PHV::Container())
            LOG6("\t\tAdding bits "  << cBits << " for stage " << initStg << " from zero init");
        else
            LOG6("\t\tAdding bits "  << cBits << " for stage " << initStg <<
                 " from source container " << srcCntr);
        }

        if (!origSlice.representsSameFieldSlice(newSlice)) continue;
        LOG5("\t\t\t  Found new slice: " << newSlice);

        if (container_state.size() > 1) {
            for (auto mls : container_state) {
                le_bitrange mlsBits = mls.container_slice();

                // If mls is overlaid with origSlice then skip mls
                // because this is the slice prior to overlay
                if (mlsBits.intersectWith(cBits).size() > 0) continue;

                PHV::Container mlsCntr = PHV::Container();
                bool hasPrim = mls.hasInitPrimitive();
                LOG5("\t\t Checking slice " << mls << " for common init stages (has Dark prim:" <<
                     hasPrim << ")");
                if (hasPrim && mls.getInitPrimitive()->getSourceSlice()) {
                    LOG6("\t\t\t with source " << mls.getInitPrimitive()->getSourceSlice());
                } else if (hasPrim) {
                    LOG6("\t\t\t isNop: " << mls.getInitPrimitive()->isNOP() <<
                         " zeroInit: " << mls.getInitPrimitive()->destAssignedToZero());
                } else {
                    bool disjoint_lr = isLiveRangeDisjoint(newSlice.getEarliestLiveness(),
                                                           newSlice.getEarliestLiveness(),
                                                           mls.getEarliestLiveness(),
                                                           mls.getLatestLiveness());
                    LOG6("\t\t\t disjoint liveranges " << disjoint_lr);
                    LOG6("\t\t\t empty: " << mls.getInitPrimitive()->isEmpty());
                }

                // Account for bits from source container
                if (hasPrim && mls.getInitPrimitive()->getSourceSlice() &&
                    mls.getEarliestLiveness().second.isWrite() &&
                    newSlice.getEarliestLiveness().second.isWrite() &&
                    (mls.getEarliestLiveness().first == initStg)) {
                    mlsCntr = mls.getInitPrimitive()->getSourceSlice()->container();
                    LOG6("\t\t\tA. mls container: " << mlsCntr << "\n Prim: " <<
                         mls.getInitPrimitive());
                // Else account for previously allocated alive bits in destination container
                } else if (!hasPrim &&
                           !isLiveRangeDisjoint(newSlice.getEarliestLiveness(),
                                                newSlice.getEarliestLiveness(),
                                                mls.getEarliestLiveness(),
                                                mls.getLatestLiveness())) {
                    mlsCntr = mls.container();
                    LOG6("\t\t\tB. mls container: " << mlsCntr);
                }

                if (!(hasPrim && mls.getInitPrimitive()->isNOP())) {
                    // Update per stage sources unless dark prim is NOP
                    perStageSources2Ranges[initStg][mlsCntr].setrange(mlsBits.lo,
                                                                  mlsBits.size());
                    if (mlsCntr == PHV::Container()) {
                        LOG6("\t\tAdding bits "  << mlsBits << " for stage " << initStg <<
                             " from zero init");
                    } else {
                        LOG6("\t\tAdding bits "  << mlsBits << " for stage " << initStg <<
                             " from container" << mlsCntr);
                    }
                }

                if (perStageSources2Ranges[initStg].size() > 2) {
                    LOG5("\t\t\tToo many sources : " << perStageSources2Ranges[initStg].size());
                    return false;
                }
            }
        }

        if (newSlice.extends_live_range(origSlice)) {
            LOG5("\t\tNew dark primitive " << newSlice << " extend original slice liverange" <<
                 origSlice << ";  thus skipping container " << newSlice.container());
            return false;
        }

        foundAnyNewSliceForThisOrigSlice = true;
        rv.push_back(newSlice);
    }
    // Check for contiguity in init slices from the same source
    // container (AlwaysRun actions can not use bitmask-set)
    for (auto stgEntry : perStageSources2Ranges) {
        if (stgEntry.second.size() == 1) continue;

        for (auto srcEntry : stgEntry.second) {
            if (!srcEntry.second.is_contiguous()) {
                std::stringstream cntrSS;
                if (srcEntry.first == PHV::Container())
                    cntrSS << "zeroInit";
                else
                    cntrSS << srcEntry.first;

                LOG5("\t\t\tNon contiguous bits from source " << cntrSS.str()  <<
                     " (" << srcEntry.second << ") in stage " << stgEntry.first);
                return false;
            }
        }
    }

    if (!foundAnyNewSliceForThisOrigSlice) rv.push_back(origSlice);
    for (auto& slice : rv) new_candidate_slices.push_back(slice);
    LOG5("\t\t\tNew candidate slices:");
    for (auto& slice : new_candidate_slices) LOG5("\t\t\t  " << slice);
    ordered_set<PHV::AllocSlice> toBeRemovedFromAlloc;
    ordered_set<PHV::AllocSlice> toBeAddedToAlloc;
    for (auto& alreadyAllocatedSlice : alloced_slices) {
        LOG5("\t\t\tAlready allocated slice: " << alreadyAllocatedSlice);
        bool foundAnyNewSliceForThisAllocatedSlice = false;
        for (auto& newSlice : initializedAllocSlices) {
            if (!alreadyAllocatedSlice.representsSameFieldSlice(newSlice)) continue;
            LOG5("\t\t\t  Found new slice: " << newSlice);
            if (newSlice.extends_live_range(alreadyAllocatedSlice)) {
                LOG5("\t\tNew dark primitive " << newSlice << " extend original slice liverange" <<
                 alreadyAllocatedSlice << ";  thus skipping container " << newSlice.container());
                return false;
            }
            foundAnyNewSliceForThisAllocatedSlice = true;
            toBeRemovedFromAlloc.insert(alreadyAllocatedSlice);
            toBeAddedToAlloc.insert(newSlice);
        }
        if (!foundAnyNewSliceForThisAllocatedSlice)
            LOG5("\t\t\t  Did not find any new slice. So stick with the existing one.");
    }
    alloc_attempt.removeAllocatedSlice(toBeRemovedFromAlloc);
    for (auto& slice : toBeAddedToAlloc) {
        alloc_attempt.allocate(slice, boost::none, singleGressParserGroups);
        LOG5("\t\t\t  Allocating slice " << slice);
    }
    PHV::Container c = origSlice.container();
    LOG5("\t\t\tState of allocation object now:");
    for (auto& slice : alloc_attempt.slices(c)) LOG5("\t\t\t  Slice: " << slice);
    return true;
}

static bool isClotSuperCluster(const ClotInfo& clots, const PHV::SuperCluster& sc) {
    // If the device doesn't support CLOTs, then don't bother checking.
    if (Device::numClots() == 0) return false;

    // In JBay, a clot-candidate field may sometimes be allocated to a PHV
    // container, eg. if it is adjacent to a field that must be packed into a
    // larger container, in which case the clot candidate would be used as
    // padding.

    // Check slice lists.
    bool needPhvAllocation = std::any_of(sc.slice_lists().begin(), sc.slice_lists().end(),
        [&](const PHV::SuperCluster::SliceList* slices) {
            return std::any_of(slices->begin(), slices->end(),
                [&](const PHV::FieldSlice& slice) { return !clots.fully_allocated(slice); });
        });

    // Check rotational clusters.
    needPhvAllocation |= std::any_of(sc.clusters().begin(), sc.clusters().end(),
        [&](const PHV::RotationalCluster* cluster) {
            return std::any_of(cluster->slices().begin(), cluster->slices().end(),
                [&](const PHV::FieldSlice& slice) { return !clots.fully_allocated(slice); });
        });

    return !needPhvAllocation;
}

std::vector<AllocAlignment> CoreAllocation::build_alignments(
    int max_n,
    const PHV::ContainerGroup& container_group,
    PHV::SuperCluster& super_cluster) const {
    // collect all possible alignments for each slice_list
    std::vector<std::vector<AllocAlignment>> all_alignments;
    for (const PHV::SuperCluster::SliceList* slice_list : super_cluster.slice_lists()) {
        auto curr_sl_alignment = build_slicelist_alignment(
            container_group, super_cluster, slice_list);
        if (curr_sl_alignment.size() == 0) {
            LOG5("cannot build alignment for " << slice_list);
            break;
        }
        all_alignments.push_back(curr_sl_alignment);
    }
    // not all slice list has valid alignment, simply skip.
    if (all_alignments.size() < super_cluster.slice_lists().size()) {
        return {};
    }

    // find max_n alignments which is a 'intersection' of one allocAlignemnt for
    // each slice list that is not conflict with others.
    std::vector<AllocAlignment> rst;
    std::function<void(int depth, AllocAlignment curr)> dfs =
        [&] (int depth, AllocAlignment curr) -> void {
            if (depth == int(all_alignments.size())) {
                rst.push_back(curr);
                return;
            }
            for (const auto& align_choice : all_alignments[depth]) {
                auto next = alloc_alignment_merge(curr, align_choice);
                if (next) {
                    dfs(depth + 1, *next);
                }
                if (int(rst.size()) == max_n) {
                    return;
                }
            }
        };
    dfs(0, AllocAlignment());
    return rst;
}

std::vector<AllocAlignment> CoreAllocation::build_slicelist_alignment(
  const PHV::ContainerGroup& container_group,
  const PHV::SuperCluster& super_cluster,
  const PHV::SuperCluster::SliceList* slice_list) const {
    std::vector<AllocAlignment> rst;
    auto valid_list_starts = super_cluster.aligned_cluster(slice_list->front())
                                 .validContainerStart(container_group.width());
    for (const int le_offset_start : valid_list_starts) {
        int le_offset = le_offset_start;
        AllocAlignment curr;
        bool success = true;
        for (auto& slice : *slice_list) {
            const PHV::AlignedCluster& cluster = super_cluster.aligned_cluster(slice);
            auto valid_start_options = cluster.validContainerStart(container_group.width());

            // if the slice 's cluster cannot be placed at the current offset.
            if (!valid_start_options.getbit(le_offset)) {
                LOG6("    ...but slice list requires slice to start at " << le_offset <<
                     " which its cluster cannot support: " << slice <<
                     " with list starts with " << le_offset_start);
                success = false;
                break;
            }

            // Return if the slice is part of another slice list but was previously
            // placed at a different start location.
            // XXX(cole): We may need to be smarter about coordinating all
            // valid starting ranges for all slice lists.
            if (curr.cluster_alignment.count(&cluster) &&
                curr.cluster_alignment.at(&cluster) != le_offset) {
                LOG6("    ...but two slice lists have conflicting alignment requirements for "
                     "field slice %1%" << slice);
                success = false;
                break;
            }

            // Otherwise, update the alignment for this slice's cluster.
            curr.cluster_alignment[&cluster] = le_offset;
            curr.slice_alignment[slice] = le_offset;
            le_offset += slice.size();
        }
        if (success) {
            rst.push_back(curr);
        }
    }
    return rst;
}


boost::optional<PHV::Transaction> CoreAllocation::alloc_super_cluster_with_alignment(
    const PHV::Allocation& alloc,
    const PHV::ContainerGroup& container_group,
    PHV::SuperCluster& super_cluster,
    const AllocAlignment& alignment,
    const AllocContext& score_ctx) const {
    // Make a new transaction.
    PHV::Transaction alloc_attempt = alloc.makeTransaction();

    // Sort slice lists according to the number of times they
    // have been written to and read from in various actions.
    // This helps simplify constraints by placing destinations before sources
    std::list<const PHV::SuperCluster::SliceList*> slice_lists;
    for (const PHV::SuperCluster::SliceList* slice_list : super_cluster.slice_lists()) {
        slice_lists.push_back(slice_list);
    }
    actions_i.sort(slice_lists);

    ordered_set<PHV::FieldSlice> allocated;
    for (const PHV::SuperCluster::SliceList* slice_list : slice_lists) {
        // Try allocating the slice list.
        auto partial_alloc_result = tryAllocSliceList(
            alloc_attempt, container_group, super_cluster, *slice_list,
            alignment.slice_alignment, score_ctx);
        if (!partial_alloc_result) {
            LOG5("failed to allocate list ");
            return boost::none;
        }
        alloc_attempt.commit(*partial_alloc_result);

        // Track allocated slices in order to skip them when allocating their clusters.
        for (auto& slice : *slice_list) {
            allocated.insert(slice);
        }
    }

    // After allocating each slice list, use the alignment for each slice in
    // each list to place its cluster.
    for (auto* rotational_cluster : super_cluster.clusters()) {
        for (auto* aligned_cluster : rotational_cluster->clusters()) {
            // Sort all field slices in an aligned cluster based on the
            // number of times they are written to or read from in different actions
            std::vector<PHV::FieldSlice> slice_list;
            for (PHV::FieldSlice slice : aligned_cluster->slices()) {
                slice_list.push_back(slice);
            }
            actions_i.sort(slice_list);

            // Forall fields in an aligned cluster, they must share a same start position.
            // Compute possible starts.
            bitvec starts;
            if (alignment.cluster_alignment.count(aligned_cluster)) {
                starts = bitvec(alignment.cluster_alignment.at(aligned_cluster), 1);
            } else {
                auto optStarts = aligned_cluster->validContainerStart(container_group.width());
                if (optStarts.empty()) {
                    // Other constraints satisfied, but alignment constraints
                    // cannot be satisfied.
                    LOG5("    ...but no valid start positions");
                    return boost::none;
                }
                // Constraints satisfied so long as aligned_cluster is placed
                // starting at a bit position in `starts`.
                starts = optStarts;
            }

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
                        tryAllocSliceList(
                            this_alloc, container_group, super_cluster,
                            PHV::SuperCluster::SliceList{slice}, start_map, score_ctx);
                    if (partial_alloc_result) {
                        this_alloc.commit(*partial_alloc_result);
                    } else {
                        failed = true;
                        break; }
                }  // for slices

                if (failed) continue;
                auto score = score_ctx.make_score(
                    this_alloc, phv_i, clot_i, uses_i,
                    field_to_parser_states_i, parser_critical_path_i);
                if (!best_alloc || score_ctx.is_better(score, best_score)) {
                    best_alloc = std::move(this_alloc);
                    best_score = score;
                }
            }

            if (!best_alloc) {
                return boost::none;
            }
            alloc_attempt.commit(*best_alloc);
        }
    }
    return alloc_attempt;
}
boost::optional<const PHV::SuperCluster::SliceList*>
CoreAllocation::find_first_unallocated_slicelist(
    const PHV::Allocation& alloc, const std::list<PHV::ContainerGroup*>& container_groups,
    PHV::SuperCluster& sc, const AllocContext& score_ctx) const {
    ordered_set<const PHV::SuperCluster::SliceList*> never_allocated;
    for (const PHV::SuperCluster::SliceList* slice_list : sc.slice_lists()) {
        never_allocated.insert(slice_list);
    }
    // Sort slice lists according to the number of times they
    // have been written to and read from in various actions.
    // This helps simplify constraints by placing destinations before sources
    std::list<const PHV::SuperCluster::SliceList*> slice_lists(
            sc.slice_lists().begin(), sc.slice_lists().end());
    actions_i.sort(slice_lists);

    for (const auto& container_group : container_groups) {
        // Check container group/cluster group constraints.
        if (!satisfies_constraints(*container_group, sc)) continue;
        std::vector<AllocAlignment> alignments = build_alignments(1, *container_group, sc);
        if (alignments.empty()) {
            continue;
        }
        const auto& alignment = alignments[0];

        PHV::Transaction alloc_attempt = alloc.makeTransaction();
        for (const PHV::SuperCluster::SliceList* slice_list : slice_lists) {
            // Try allocating the slice list.
            auto partial_alloc_result =
                tryAllocSliceList(alloc_attempt, *container_group, sc, *slice_list,
                                  alignment.slice_alignment, score_ctx);
            if (!partial_alloc_result) {
                break;
            } else {
                never_allocated.erase(slice_list);
                alloc_attempt.commit(*partial_alloc_result);
            }
        }
    }
    if (never_allocated.size() > 0) {
        // must return the first unallocatable sl in the action-sorted order.
        for (const auto& sl : slice_lists) {
            if (never_allocated.count(sl)) {
                return sl;
            }
        }
    }
    return boost::none;
}

// SUPERCLUSTER <--> CONTAINER GROUP allocation.
boost::optional<PHV::Transaction> CoreAllocation::tryAlloc(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& container_group,
        PHV::SuperCluster& super_cluster,
        int max_alignment_tries,
        const AllocContext& score_ctx) const {
    if (isClotSuperCluster(clot_i, super_cluster)) {
        LOG5("Skipping CLOT-allocated super cluster: " << super_cluster);
        return alloc.makeTransaction(); }

    // Check container group/cluster group constraints.
    if (!satisfies_constraints(container_group, super_cluster))
        return boost::none;

    LOG5("build alignments");
    std::vector<AllocAlignment> alignments = build_alignments(
        max_alignment_tries, container_group, super_cluster);
    LOG5("found " << alignments.size() << " valid alignemtns");
    if (alignments.empty()) {
        LOG5("SuperCluster is not allocate-able due to alignment: " << super_cluster);
        return boost::none;
    }

    // try different alignments.
    boost::optional<PHV::Transaction> best_alloc = boost::none;
    AllocScore best_score = AllocScore::make_lowest();
    for (const auto& alignment : alignments) {
        LOG6("try alloc with alignment, " <<
             str_supercluster_alignments(super_cluster, alignment));
        auto this_alloc = alloc_super_cluster_with_alignment(
            alloc, container_group, super_cluster, alignment, score_ctx);
        if (this_alloc) {
            auto score = score_ctx.make_score(*this_alloc, phv_i, clot_i, uses_i,
                field_to_parser_states_i, parser_critical_path_i);
            if (!best_alloc || score_ctx.is_better(score, best_score)) {
                best_alloc = std::move(this_alloc);
                best_score = score;
                // XXX(yumin): currently we stop at the first valid alignmnt
                // and avoid search too much which might slow down compilation.
                break;
            }
        } else {
            LOG5("alloc with the above alignment failed");
        }
    }
    return best_alloc;
}

/* static */
std::list<PHV::ContainerGroup *> AllocatePHV::makeDeviceContainerGroups() {
    const PhvSpec& phvSpec = Device::phvSpec();
    std::list<PHV::ContainerGroup *> rv;

    // Build MAU groups
    for (const PHV::Size s : phvSpec.containerSizes()) {
        for (auto group : phvSpec.mauGroups(s)) {
            // Get type of group
            if (group.empty()) continue;
            // Create group.
            rv.emplace_back(new PHV::ContainerGroup(s, group)); } }

    // Build TPHV collections
    for (auto collection : phvSpec.tagalongCollections()) {
        // Each PHV_MAU_Group holds containers of the same size.  Hence, TPHV
        // collections are split into three groups, by size.
        ordered_map<PHV::Type, bitvec> groups_by_type;

        // Add containers to groups by size
        for (auto cid : collection) {
            auto type = phvSpec.idToContainer(cid).type();
            groups_by_type[type].setbit(cid); }

        for (auto kv : groups_by_type)
            rv.emplace_back(new PHV::ContainerGroup(kv.first.size(), kv.second)); }

    return rv;
}

void AllocatePHV::clearSlices(PhvInfo& phv) {
    phv.clear_container_to_fields();
    for (auto& f : phv)
        f.clear_alloc();
}

/* static */
void AllocatePHV::bindSlices(const PHV::ConcreteAllocation& alloc, PhvInfo& phv) {
    for (auto container_and_slices : alloc) {
        // TODO: Do we need to ensure that the live ranges of the constituent slices, put together,
        // completely cover the entire pipeline (plus parser and deparser).

        for (PHV::AllocSlice slice : container_and_slices.second.slices) {
            PHV::Field* f = const_cast<PHV::Field*>(slice.field());
            auto init_points = alloc.getInitPoints(slice);
            static ordered_set<const IR::MAU::Action*> emptySet;
            slice.setInitPoints(init_points ? *init_points : emptySet);
            if (init_points) {
                slice.setMetaInit();
                LOG5("\tAdding " << init_points->size() << " initialization points for field "
                     "slice: " << slice.field()->name << " " << slice);
                for (const auto* a : *init_points)
                    LOG4("    Action: " << a->name); }
            f->add_alloc(slice);
            phv.add_container_to_field_entry(slice.container(), f);
        }
    }

    // later passes assume that phv alloc info is sorted in field bit order,
    // msb first
    for (auto& f : phv)
        f.sort_alloc();

    // Merge adjacent field slices that have been allocated adjacently in the
    // same container.  This can happen when the field is involved in a set
    // instruction with another field that has been split---it needs to be
    // "split" to match the invariants on rotational clusters, but in practice
    // to the two slices remain adjacent.
    for (auto& f : phv) {
        boost::optional<PHV::AllocSlice> last = boost::none;
        safe_vector<PHV::AllocSlice> merged_alloc;
        for (auto& slice : f.get_alloc()) {
            if (last == boost::none) {
                last = slice;
                continue; }
            if (last->container() == slice.container()
                    && last->field_slice().lo == slice.field_slice().hi + 1
                    && last->container_slice().lo == slice.container_slice().hi + 1
                    && last->getEarliestLiveness() == slice.getEarliestLiveness()
                    && last->getLatestLiveness() == slice.getLatestLiveness()
                    && *last->getInitPrimitive() == *slice.getInitPrimitive()) {
                int new_width = last->width() + slice.width();
                ordered_set<const IR::MAU::Action*> new_init_points;
                if (last->hasMetaInit())
                    new_init_points.insert(last->getInitPoints().begin(),
                                           last->getInitPoints().end());
                if (slice.hasMetaInit())
                    new_init_points.insert(slice.getInitPoints().begin(),
                                           slice.getInitPoints().end());
                if (new_init_points.size() > 0)
                    LOG5("Merged slice contains " << new_init_points.size() << " initialization "
                         "points.");
                PHV::AllocSlice new_slice(slice.field(),
                                          slice.container(),
                                          slice.field_slice().lo,
                                          slice.container_slice().lo,
                                          new_width, new_init_points);
                new_slice.setLiveness(slice.getEarliestLiveness(), slice.getLatestLiveness());
                if (last->hasMetaInit() || slice.hasMetaInit())
                    new_slice.setMetaInit();
                new_slice.setInitPrimitive(slice.getInitPrimitive());
                BUG_CHECK(new_slice.field_slice().contains(last->field_slice()),
                          "Merged alloc slice %1% does not contain hi slice %2%",
                          cstring::to_cstring(new_slice), cstring::to_cstring(*last));
                BUG_CHECK(new_slice.field_slice().contains(slice.field_slice()),
                          "Merged alloc slice %1% does not contain lo slice %2%",
                          cstring::to_cstring(new_slice), cstring::to_cstring(slice));
                LOG4("MERGING " << last->field() << ": " << *last << " and " << slice <<
                     " into " << new_slice);
                last = new_slice;
            } else {
                merged_alloc.push_back(*last);
                last = slice; } }
        if (last)
            merged_alloc.push_back(*last);
        f.set_alloc(merged_alloc); }
}

/// Log (at LOGGING(3)) the device-specific PHV resources.
static void log_device_stats() {
    if (!LOGGING(3))
        return;

    const PhvSpec& phvSpec = Device::phvSpec();
    int numContainers = 0;
    int numIngress = 0;
    int numEgress = 0;
    for (auto id : phvSpec.physicalContainers()) {
        numContainers++;
        if (phvSpec.ingressOnly().getbit(id))
            numIngress++;
        if (phvSpec.egressOnly().getbit(id))
            numEgress++; }
    LOG3("There are " << numContainers << " containers.");
    LOG3("Ingress only: " << numIngress);
    LOG3("Egress  only: " << numEgress);
}

// Create callback for creating FileLog objects
// Those can locally redirect LOG* macros to another file which
// will share path and suffix number with phv_allocation_*.log
// To restore original logging behaviour, call Logging::FileLog::close on the object.
static Logging::FileLog *createFileLog(int pipeId, const cstring &prefix, int loglevel) {
    if (!LOGGING(loglevel)) return nullptr;

    auto filename = Logging::PassManager::getNewLogFileName(prefix);
    return new Logging::FileLog(pipeId, filename, Logging::Mode::AUTO);
}

const IR::Node *AllocatePHV::apply_visitor(const IR::Node* root_, const char *) {
    LOG1("--- BEGIN PHV ALLOCATION ----------------------------------------------------");
    root = root_->to<IR::BFN::Pipe>();
    BUG_CHECK(root, "IR root is not a BFN::Pipe: %s", root_);
    Device::phvSpec().applyGlobalPragmas(root->global_pragmas);
    log_device_stats();

    // Check if pragma pa_parser_group_monogress is contained in the p4 program
    //   and set singleGressParserGroups in CoreAllocation
    for (auto* anno : root->global_pragmas) {
        if (anno->name.name == PragmaParserGroupMonogress::name) {
            core_alloc_i.set_single_gress_parser_group();
            LOG4("\tFOUND pa_parser_group_monogress pragma");
        }
    }

    int pipeId = root->id;

    // Make sure that fields are not marked as mutex with itself.
    for (const auto& field : phv_i) {
        BUG_CHECK(!mutex_i(field.id, field.id),
                  "Field %1% can be overlaid with itself.", field.name); }

    LOG1(pragmas_i.pa_container_sizes());
    LOG1(pragmas_i.pa_atomic());

    // clear allocation result to create an empty concrete allocation.
    clearSlices(phv_i);
    LOG1("clear allocation result");
    PHV::ConcreteAllocation alloc = make_concrete_allocation(phv_i, uses_i);
    PHV::ConcreteAllocation empty_alloc = alloc;
    auto container_groups = makeDeviceContainerGroups();
    std::list<PHV::SuperCluster*> cluster_groups = make_cluster_groups();

    // Remove super clusters that are entirely allocated to CLOTs.
    ordered_set<PHV::SuperCluster*> to_remove;
    for (auto* sc : cluster_groups)
        if (isClotSuperCluster(clot_i, *sc))
            to_remove.insert(sc);
    for (auto* sc : to_remove) {
        cluster_groups.remove(sc);
        LOG4("  ...Skipping CLOT-allocated super cluster: " << sc);
    }

    BruteForceStrategyConfig default_config {
        /*.name:*/                   "default_alloc_config",
        /*.is_better:*/              default_alloc_score_is_better,
        /*.max_failure_retry:*/      0,
        /*.max_slicing:*/            128,
        /*.max_sl_alignment_try:*/   1,
        /*.unsupported_devices:*/    boost::none,
        /*.pre_slicing_validation:*/ false,
        /*.enable_ara_in_overlays:*/ PhvInfo::darkSpillARA
    };
    BruteForceStrategyConfig less_fragment_backup_config {
        /*.name:*/                   "less_fragment_alloc_config",
        /*.is_better:*/              less_fragment_alloc_score_is_better,
        /*.max_failure_retry:*/      0,
        /*.max_slicing:*/            256,
        /*.max_sl_alignment_try:*/   5,
        /*.unsupported_devices:*/    boost::none,
        /*.pre_slicing_validation:*/ false,
        /*.enable_ara_in_overlays:*/ PhvInfo::darkSpillARA
    };
    std::vector<BruteForceStrategyConfig> configs = {
        default_config,
        less_fragment_backup_config,
    };
    if (PhvInfo::darkSpillARA && Device::currentDevice() != Device::TOFINO) {
        BruteForceStrategyConfig no_ara_config {
            /*.name:*/                   "disable_ara_alloc_config",
            /*.is_better:*/              default_alloc_score_is_better,
            /*.max_failure_retry:*/      0,
            /*.max_slicing:*/            128,
            /*.max_sl_alignment_try:*/   1,
            /*.unsupported_devices:*/    std::unordered_set<Device::Device_t>{Device::TOFINO},
            /*.pre_slicing_validation:*/ false,
            /*.enable_ara_in_overlays:*/ false
        };
        configs.push_back(no_ara_config);
    }

    AllocResult result(
        AllocResultCode::UNKNOWN, alloc.makeTransaction(), {});
    std::vector<const PHV::SuperCluster::SliceList*> unallocatable_lists;
    for (const auto& config : configs) {
        if (config.unsupported_devices &&
            config.unsupported_devices.get().count(Device::currentDevice())) {
            continue;
        }
        PhvInfo::darkSpillARA = PhvInfo::darkSpillARA && config.enable_ara_in_overlays;

        BruteForceAllocationStrategy* strategy = new BruteForceAllocationStrategy(
            empty_alloc, config.name, core_alloc_i, parser_critical_path_i,
            critical_path_clusters_i, clot_i, strided_headers_i, uses_i, clustering_i, config,
            pipeId);
        result = strategy->tryAllocation(alloc, cluster_groups, container_groups);
        if (result.status == AllocResultCode::SUCCESS) {
            break;
        } else if (result.status == AllocResultCode::FAIL_UNSAT_SLICING) {
            LOG1("unsat constraints, stopped");
            break;
        } else {
            LOG1("phv allocation with " << config.name << " config failed.");
            if (strategy->get_unallocatable_list()) {
                unallocatable_lists.push_back(*(strategy->get_unallocatable_list()));
                LOG1("possibly unallocatable slice list: " << unallocatable_lists.back());
            }
        }
    }
    if (result.status == AllocResultCode::FAIL && unallocatable_lists.size() > 0) {
        // It's possible that the algorithm created unallocatable clusters during preslicings.
        // We can't detect them upfront because currently action phv constraints is not able to
        // print out packing limitations like TWO_SOURCES_AND_CONSTANT.
        // Until we can print a complete list of packing constraints from action phv constraints,
        // we run a allocation algorithm again with pre_slicing validation - try to allocate
        // all sliced clusters to a empty PHV while pre_slicing. It will ensure that all sliced
        // clusters are allocatable.
        // It's not enabled by default because it will make allocation X2 slower.
        bool all_same = unallocatable_lists.size() == 1 ||
                        std::all_of(unallocatable_lists.begin() + 1, unallocatable_lists.end(),
                                    [&](const PHV::SuperCluster::SliceList* sl) {
                                        return *sl == *(unallocatable_lists.front());
                                    });
        if (all_same) {
            LOG1("pre-slicing validation is enabled for " << unallocatable_lists.front());
            // create a config that validate pre_slicing results.
            BruteForceStrategyConfig config{
                /*.name:*/                   "less_fragment_validate_pre_slicing",
                /*.is_better:*/              less_fragment_alloc_score_is_better,
                /*.max_failure_retry:*/      0,
                /*.max_slicing:*/            256,
                /*.max_sl_alignment_try:*/   5,
                /*.tofino_only:*/            boost::none,
                /*.pre_slicing_validation:*/ true,
                /*.enable_ara_in_overlays:*/ false
            };
            BruteForceAllocationStrategy* strategy = new BruteForceAllocationStrategy(
                empty_alloc, config.name, core_alloc_i, parser_critical_path_i,
                critical_path_clusters_i, clot_i, strided_headers_i, uses_i, clustering_i, config,
                pipeId);
            auto new_result = strategy->tryAllocation(alloc, cluster_groups, container_groups);
            if (new_result.status == AllocResultCode::SUCCESS) {
                result = new_result;
            } else {
                ::warning("found a unallocatable slice list: %1%",
                          cstring::to_cstring(unallocatable_lists.front()));
            }
        }
    }
    alloc.commit(result.transaction);

    // If only privatized fields are unallocated, mark allocation as done.
    // The rollback of unallocated privatized fields will happen in ValidateAllocation.
    bool allocationDone = (result.status == AllocResultCode::SUCCESS) ||
        onlyPrivatizedFieldsUnallocated(result.remaining_clusters);
    if (allocationDone) {
        bindSlices(alloc, phv_i);
        phv_i.set_done();
    } else {
        bool firstRoundFit = alloc_i.didFirstRoundFit();
        if (firstRoundFit) {
            // Empty table allocation to be sent because the first round of PHV allocation should be
            // redone.
            ordered_map<cstring, ordered_set<int>> tables;
            LOG1("This round of PHV Allocation did not fit. However, the first round of PHV "
                 "allocation did. Therefore, falling back onto the first round of PHV allocation.");
            throw PHVTrigger::failure(tables, tables, firstRoundFit, true /* ignorePackConflicts */,
                                      false /* metaInitDisable */);
        }
        bindSlices(alloc, phv_i);
    }

    // Redirect all following LOG*s into summary file
    // Print summaries
    auto logfile = createFileLog(pipeId, "phv_allocation_summary_", 1);
    if (result.status == AllocResultCode::SUCCESS) {
        LOG1("PHV ALLOCATION SUCCESSFUL");
        LOG1(alloc);
    } else if (onlyPrivatizedFieldsUnallocated(result.remaining_clusters)) {
        LOG1("PHV ALLOCATION SUCCESSFUL FOR NON-PRIVATIZED FIELDS");
        LOG1("SuperClusters with Privatized Fields unallocated: ");
        for (auto* sc : result.remaining_clusters)
            LOG1(sc);
        LOG1(alloc);
    } else {
        bool failure_diagnosed = (result.remaining_clusters.size() == 0) ? false :
            diagnoseFailures(result.remaining_clusters);

        if (result.status == AllocResultCode::FAIL_UNSAT_SLICING) {
            formatAndThrowError(alloc, result.remaining_clusters);
            formatAndThrowUnsat(result.remaining_clusters);
        } else if (!failure_diagnosed) {
            formatAndThrowError(alloc, result.remaining_clusters);
        }
    }
    Logging::FileLog::close(logfile);

    return root;
}

bool AllocatePHV::diagnoseFailures(const std::list<PHV::SuperCluster *>& unallocated) const {
    bool rv = false;
    // Prefer actionable error message if we can precisely identify failures for any supercluster.
    for (auto& sc : unallocated)
        rv |= diagnoseSuperCluster(sc);
    return rv;
}

bool AllocatePHV::diagnoseSuperCluster(const PHV::SuperCluster* sc) const {
    auto& slice_lists = sc->slice_lists();
    // Cannot diagnose superclusters without slice lists yet.
    if (slice_lists.size() == 0) return false;
    // Identify if this is the minimal slice for this supercluster.
    // Conditions:
    // 1. The width of deparsed exact_containers slice lists in the supercluster is already 8b; or
    // 2. At least one deparsed exact_containers slice list is made up of no_split fields.
    bool scCannotBeSplitFurther = false;
    // Note down the offsets of the field slices within the slice list; the offset represents the
    // slices' alignments within their respective containers.
    ordered_map<PHV::FieldSlice, unsigned> fieldAlignments;
    // Only slice lists of interest are the ones with exact containers requirements
    ordered_set<const PHV::SuperCluster::SliceList*> sliceListsOfInterest;

    for (const auto* list : slice_lists) {
        bool sliceListExact = false;
        int sliceListSize = 0;
        for (auto& slice : *list) {
            if (slice.field()->no_split()) scCannotBeSplitFurther = true;
            if (slice.field()->exact_containers()) sliceListExact = true;
            fieldAlignments[slice] = sliceListSize;
            sliceListSize += slice.size();
        }
        if (sliceListExact) {
            scCannotBeSplitFurther = true;
            sliceListsOfInterest.insert(list);
        }
    }
    if (!scCannotBeSplitFurther) return false;

    LOG3("The following supercluster fails allocation and cannot be split further:\n" << sc);
    LOG3("Printing alignments of slice list fields within their containers:");
    for (auto kv : fieldAlignments)
        LOG3("  " << kv.second << " : " << kv.first);
    std::stringstream ss;
    bool diagnosed = core_alloc_i.actionConstraints().diagnoseSuperCluster(sliceListsOfInterest,
            fieldAlignments, ss);
    if (diagnosed) ::error("%1%", ss.str());
    return diagnosed;
}

bool AllocatePHV::onlyPrivatizedFieldsUnallocated(
        std::list<PHV::SuperCluster*>& unallocated) const {
    for (auto* super_cluster : unallocated)
        for (auto* rotational_cluster : super_cluster->clusters())
            for (auto* cluster : rotational_cluster->clusters())
                for (auto& slice : cluster->slices())
                    if (!slice.field()->privatized())
                        return false;
    return true;
}

namespace PHV {
namespace Diagnostics {

static std::string printField(const PHV::Field* f) {
    return f->externalName() + "<" + std::to_string(f->size) + "b>";
}

static std::string printSlice(const PHV::FieldSlice& slice) {
    auto* f = slice.field();
    if (slice.size() == f->size)
        return printField(f);
    else
        return printField(f) + "[" + std::to_string(slice.range().hi)
                             + ":" + std::to_string(slice.range().lo) + "]";
}

static std::string printSliceConstraints(const PHV::FieldSlice& slice) {
    auto f = slice.field();
    return printSlice(slice) + ": "
            + (f->is_solitary() ? "solitary " : "")
            + (f->no_split() ? "no_split " : "")
            + (f->no_holes() ? "no_holes " : "")
            + (f->used_in_wide_arith() ? "wide_arith " : "")
            + (f->exact_containers() ? "exact_containers" : "");
}

/// @returns a sorted list of explanations, one for each set of conflicting
/// constraints in @sc, or the empty vector if there are no conflicting
/// constraints.
static std::string diagnoseSuperCluster(const PHV::SuperCluster& sc) {
    std::stringstream msg;

    // Dump constraints.
    std::set<const PHV::Field*> fields;
    for (auto* rc : sc.clusters())
        for (auto* ac : rc->clusters())
            for (auto slice : *ac)
                fields.insert(slice.field());
    std::vector<const PHV::Field*> sortedFields(fields.begin(), fields.end());
    std::sort(sortedFields.begin(), sortedFields.end(),
              [](const PHV::Field* f1, const PHV::Field* f2) {
                  return f1->name < f2->name; });
    msg << "These fields have the following field-level constraints:" << std::endl;
    for (auto* f : fields)
        msg << "    " << printSliceConstraints(PHV::FieldSlice(f, StartLen(0, f->size)))
            << std::endl;
    msg << std::endl;

    msg << "These slices must be in the same PHV container group:" << std::endl;
    for (auto* rc : sc.clusters()) {
        for (auto* ac : rc->clusters()) {
            if (!ac->slices().size()) continue;

            // Print singleton aligned cluster.
            if (ac->slices().size() == 1) {
                msg << "    " << PHV::Diagnostics::printSlice(*ac->begin()) << std::endl;
                continue; }

            msg << "    These slices must also be aligned within their respective containers:"
                << std::endl;
            for (auto slice : *ac)
                msg << "        " << PHV::Diagnostics::printSlice(slice) << std::endl; } }
    msg << std::endl;

    // Print slice lists (adjacency constraints).
    for (auto* slist : sc.slice_lists()) {
        if (slist->size() <= 1) continue;
        msg << "These fields can (optionally) be packed adjacently in the same container to "
            << "satisfy exact_containers requirements:"
            << std::endl;
        for (auto slice : *slist)
            msg << "    " << PHV::Diagnostics::printSlice(slice) << std::endl;
        msg << std::endl; }

    // Highlight specific conflicts that are easy to identify.
    ordered_set<std::string> conflicts;
    for (auto* rc : sc.clusters()) {
        const auto& slices = rc->slices();
        if (!slices.size()) continue;

        // If two slices have different sizes but must go in the same container
        // group, then either (a) the larger one must be split, (b) the smaller
        // one must be packed with adjacent slices of its slice list, or (c)
        // the smaller one must not have the exact_containers requirement.
        for (auto s1 : slices) {
            for (auto s2 : slices) {
                if (s1 == s2) continue;
                ordered_set<const PHV::SuperCluster::SliceList*> s1lists;
                ordered_set<const PHV::SuperCluster::SliceList*> s2lists;
                for (auto* list : sc.slice_list(s1))
                    s1lists.insert(mergeContiguousSlices(list));
                for (auto* list : sc.slice_list(s2))
                    s2lists.insert(mergeContiguousSlices(list));

                if (s1.field()->no_split())
                    s1 = PHV::FieldSlice(s1.field(), StartLen(0, s1.field()->size));
                if (s2.field()->no_split())
                    s2 = PHV::FieldSlice(s2.field(), StartLen(0, s2.field()->size));

                auto& larger = s1.size() > s2.size() ? s1 : s2;
                auto largerLists = s1.size() > s2.size() ? s1lists : s2lists;
                auto& smaller = s1.size() < s2.size() ? s1 : s2;
                auto smallerLists = s1.size() < s2.size() ? s1lists : s2lists;

                // Skip same-sized slices.
                if (larger.size() == smaller.size()) continue;
                // Skip if larger field can be split.
                if (!larger.field()->no_split()) continue;
                // Skip if smaller field doesn't have exact_containers.
                if (!smaller.field()->exact_containers()) continue;

                // If the smaller field can't be packed or doesn't have
                // adjacent slices, that's a problem.
                std::string sm = printSlice(smaller);
                std::string lg = printSlice(larger);
                if (smaller.field()->is_solitary() && smaller.field()->size != larger.size()) {
                    std::stringstream ss;
                    ss << "Constraint conflict: ";
                    ss << "Field slices " << sm << " and " << lg << " must be in the same PHV "
                          "container group, but " << lg << " cannot be split, and " << sm <<
                          " (a) must fill an entire container, (b) cannot be packed with "
                          "adjacent fields, and (c) is not the same size as " << lg << ".";
                    conflicts.insert(ss.str());
                } else {
                    for (auto* sliceList : smallerLists) {
                        int listSize = PHV::SuperCluster::slice_list_total_bits(*sliceList);
                        if (listSize < larger.size()) {
                            std::stringstream ss;
                            ss << "Constraint conflict: ";
                            ss << "Field slices " << sm << " and " << lg << " must be in the "
                                  "same PHV container group, but " << lg << " cannot be split, "
                                  "and " << sm << " (a) must fill an entire container with its "
                                  "adjacent fields, but (b) it and its adjacent fields are "
                                  "smaller than " << lg << ".";
                            conflicts.insert(ss.str());
                            break; } } } } } }
    for (auto& conflict : conflicts)
        msg << conflict << std::endl << std::endl;
    return msg.str();
}

}  // namespace Diagnostics
}  // namespace PHV

void AllocatePHV::formatAndThrowError(
        const PHV::Allocation& alloc,
        const std::list<PHV::SuperCluster *>& unallocated) {
    int unallocated_slices = 0;
    int unallocated_bits = 0;
    int ingress_phv_bits = 0;
    int egress_phv_bits = 0;
    int ingress_t_phv_bits = 0;
    int egress_t_phv_bits = 0;
    std::stringstream msg;
    std::stringstream errorMessage;

    msg << std::endl << "The following fields were not allocated: " << std::endl;
    for (auto* sc : unallocated)
        sc->forall_fieldslices([&](const PHV::FieldSlice& s) {
            msg << "    " << PHV::Diagnostics::printSlice(s) << std::endl;
            unallocated_slices++; });
    msg << std::endl;
    errorMessage << msg.str();

    bool have_tagalong = Device::phvSpec().hasContainerKind(PHV::Kind::tagalong);

    if (LOGGING(1)) {
        msg << "Fields successfully allocated: " << std::endl;
        msg << alloc << std::endl; }
    for (auto* super_cluster : unallocated) {
        for (auto* rotational_cluster : super_cluster->clusters()) {
            for (auto* cluster : rotational_cluster->clusters()) {
                for (auto& slice : cluster->slices()) {
                    bool can_be_tphv = have_tagalong && cluster->okIn(PHV::Kind::tagalong);
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

    if (LOGGING(1)) {
        msg << std::endl
            << "..........Unallocated bits = " << unallocated_bits << std::endl;
        msg << "..........ingress phv bits = " << ingress_phv_bits << std::endl;
        msg << "..........egress phv bits = " << egress_phv_bits << std::endl;
        if (have_tagalong) {
            msg << "..........ingress t_phv bits = " << ingress_t_phv_bits << std::endl;
            msg << "..........egress t_phv bits = " << egress_t_phv_bits << std::endl;
        }
        msg << std::endl; }

    PHV::AllocationReport report(alloc, true);
    msg << report.printSummary() << std::endl;
    msg << "PHV allocation was not successful "
        << "(" << unallocated_slices << " field slices remaining)" << std::endl;
    LOG1(msg.str());
    ::error("PHV allocation was not successful\n"
            "%1% field slices remain unallocated\n"
            "%2%", unallocated_slices, errorMessage.str());
}

void AllocatePHV::formatAndThrowUnsat(const std::list<PHV::SuperCluster*>& unsat) const {
    std::stringstream msg;
    msg << "Some fields cannot be allocated because of unsatisfiable constraints."
       << std::endl << std::endl;

    // Pretty-print the kinds of constraints.
    /*
    msg << R"(Constraints:
    solitary:   The field cannot be allocated in the same PHV container(s) as any
                other fields.  Fields that are shifted or are the destination of
                arithmetic operations have this constraint.

    no_split:   The field must be entirely allocated to a single PHV container.
                Fields that are shifted or are a source or destination of an
                arithmetic operation have this constraint.

    exact_containers:
                If any field slice in a PHV container has this constraint, then
                the container must be completely filled, and if it contains more
                than one slice, all slices must also have adjaceny constraints.
                All header fields have this constraint.

    adjacency:  If two or more fields are marked as adjacent, then they must be
                placed contiguously (in order) if placed in the same PHV
                container.  Fields in the same header are marked as adjacent.

    aligned:    If two or more fields are marked with an alignment constraint,
                then they must be placed starting at the same least-significant
                bit in their respective PHV containers.

    grouped:    Fields involved in the same instructions must be placed in the
                same PHV container group.  Note that the 'aligned' constraint
                implies 'grouped'.)"
                << std::endl
                << std::endl;
    */

    // Pretty-print the supercluster constraints.
    msg << "The following constraints are mutually unsatisfiable." << std::endl << std::endl;
    for (auto* sc : unsat)
        msg << PHV::Diagnostics::diagnoseSuperCluster(*sc);

    msg << "PHV allocation was not successful "
        << "(" << unsat.size() << " set" << (unsat.size() == 1 ? "" : "s")
        << " of unsatisfiable constraints remaining)" << std::endl;
    LOG3(msg.str());
    ::error("%1%", msg.str());
}

BruteForceAllocationStrategy::BruteForceAllocationStrategy(
    const PHV::Allocation& empty_alloc, const cstring name, const CoreAllocation& alloc,
    const CalcParserCriticalPath& ccp, const CalcCriticalPathClusters& cpc, const ClotInfo& clot,
    const CollectStridedHeaders& hs, const PhvUse& uses, const Clustering& clustering,
    const BruteForceStrategyConfig& config, int pipeId)
    : AllocationStrategy(name, alloc),
      empty_alloc_i(empty_alloc),
      parser_critical_path_i(ccp),
      critical_path_clusters_i(cpc),
      clot_i(clot),
      strided_headers_i(hs),
      uses_i(uses),
      clustering_i(clustering),
      config_i(config),
      pipe_id_i(pipeId) {
    has_pack_conflict_i = [&](const PHV::Field* f1, const PHV::Field* f2) {
        if (f1 == f2) return false;
        if (core_alloc_i.mutex()(f1->id, f2->id)) return false;
        return clustering_i.no_pack(f1, f2) ||
               core_alloc_i.actionConstraints().hasPackConflict(f1, f2);
    };
    is_referenced_i = [&](const PHV::Field* f) { return uses_i.is_referenced(f); };
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::remove_unreferenced_clusters(
        const std::list<PHV::SuperCluster*>& cluster_groups_input) const {
    std::set<PHV::SuperCluster*> un_ref_singleton;
    for (auto* super_cluster : cluster_groups_input) {
        bool should_skip = false;
        for (const auto* slice_list : super_cluster->slice_lists()) {
            bool has_referenced = false;
            bool has_unreferenced = false;
            for (const auto& slice : *slice_list) {
                if (core_alloc_i.uses().is_referenced(slice.field()) &&
                    !slice.field()->isGhostField()) {
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
                    if (!core_alloc_i.uses().is_referenced(slice.field()) &&
                        !slice.field()->isGhostField()) {
                        un_ref_singleton.insert(super_cluster);
                        break; } } } }
    }

    for (auto* super_cluster : cluster_groups_input) {
        bool all_field_slices_ignore_padding = super_cluster->all_of_fieldslices(
                [](const PHV::FieldSlice& slice) {
                return slice.field()->is_ignore_alloc();
                });
        if (all_field_slices_ignore_padding)
            un_ref_singleton.insert(super_cluster);
    }

    std::list<PHV::SuperCluster*> cluster_groups_filtered;
    for (const auto& c : cluster_groups_input) {
        if (un_ref_singleton.count(c)) continue;
        cluster_groups_filtered.push_back(c); }

    return cluster_groups_filtered;
}

ordered_set<bitvec> BruteForceAllocationStrategy::calc_slicing_schemas(
        const PHV::SuperCluster* sc,
        const std::set<PHV::ConcreteAllocation::AvailableSpot>& spots) {
    ordered_set<bitvec> rst;
    const std::vector<int> chunk_sizes = {7, 6, 5, 4, 3, 2, 1};

    auto gress = sc->gress();
    int size = sc->max_width();
    bool hasDeparsed = sc->deparsed();

    // available spots suggested slicing
    bitvec suggested_slice_schema;
    int covered_size = 0;
    for (const auto& spot : boost::adaptors::reverse(spots)) {
        if (spot.gress && spot.gress != gress) continue;
        if (hasDeparsed && spot.deparserGroupGress && spot.deparserGroupGress != gress) continue;
        if (spot.n_bits >= size) continue;
        if (!sc->okIn(spot.container.type().kind())) continue;
        covered_size += spot.n_bits;
        if (covered_size >= size) break;
        suggested_slice_schema.setbit(covered_size); }
    if (covered_size >= size  && !(suggested_slice_schema.empty())) {
        LOG5("Adding schema: covered_size = " << covered_size << ", size = " << size <<
             ", schema = " << suggested_slice_schema);
        rst.insert(suggested_slice_schema); }

    // slice them to n-bit chunks.
    for (int sz : chunk_sizes) {
        bitvec slice_schema;
        for (int i = sz; i < sc->max_width(); i += sz) {
            slice_schema.setbit(i); }
        if (!(slice_schema.empty())) {
            LOG5("Adding schema:  sz = " << sz << ", schema = " << slice_schema);
            rst.insert(slice_schema); }
    }
    return rst;
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::allocDeparserZeroSuperclusters(
        PHV::Transaction& rst,
        std::list<PHV::SuperCluster*>& cluster_groups) {
    LOG4("Allocating Deparser Zero Superclusters");
    std::list<PHV::SuperCluster*> allocated_sc;
    for (auto* sc : cluster_groups) {
        LOG4(sc);
        if (auto partial_alloc = core_alloc_i.tryDeparserZeroAlloc(rst, *sc)) {
            allocated_sc.push_back(sc);
            LOG4("  ...Committing allocation for deparser zero supercluster.");
            rst.commit(*partial_alloc);
        } else {
            LOG4("  ...Unable to allocated deparser zero supercluster."); } }
    // Remove allocated deparser zero superclusters.
    for (auto* sc : allocated_sc)
        cluster_groups.remove(sc);
    return cluster_groups;
}

boost::optional<PHV::Transaction> CoreAllocation::tryDeparserZeroAlloc(
        const PHV::Allocation& alloc,
        PHV::SuperCluster& cluster) const {
    auto alloc_attempt = alloc.makeTransaction();
    if (isClotSuperCluster(clot_i, cluster)) {
        LOG4("  ...Skipping CLOT-allocated super cluster: " << cluster);
        return alloc_attempt; }
    for (auto* sl : cluster.slice_lists()) {
        int slice_list_offset = 0;
        for (auto slice : *sl) {
            LOG5("Slice in slice list: " << slice);
            std::map<gress_t, PHV::Container> zero = { { INGRESS, PHV::Container("B0") },
                                                       { EGRESS, PHV::Container("B16") }};
            std::vector<PHV::AllocSlice> candidate_slices;
            int slice_width = slice.size();
            // Allocate bytewise chunks of this field to B0 and B16.
            for (int i = 0; i < slice_width; i += 8) {
                int alloc_slice_width = std::min(8, slice_width - i);
                LOG5("  Alloc Slice width: " << alloc_slice_width);
                LOG5("  Slice list offset: " << slice_list_offset);
                le_bitrange container_slice = StartLen(slice_list_offset % 8, alloc_slice_width);
                le_bitrange field_slice = StartLen(i + slice.range().lo, alloc_slice_width);
                LOG4("  Container slice: " << container_slice << ", field slice: " << field_slice);
                BUG_CHECK(slice.gress() == INGRESS || slice.gress() == EGRESS,
                          "Found a field slice for %1% that is neither ingress nor egress",
                          slice.field()->name);
                candidate_slices.push_back(PHV::AllocSlice(phv_i.field(slice.field()->id),
                            zero[slice.gress()], field_slice, container_slice));
                phv_i.addZeroContainer(slice.gress(), zero[slice.gress()]);
                slice_list_offset += alloc_slice_width; }
            for (auto& alloc_slice : candidate_slices)
                alloc_attempt.allocate(alloc_slice, boost::none, singleGressParserGroups); } }
    return alloc_attempt;
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
    if (Device::currentDevice() != Device::TOFINO) {
        return { }; }

    auto score_ctx = AllocContext(name, config_i.is_better);
    std::list<PHV::SuperCluster*> allocated_sc;
    for (auto* sc : cluster_groups) {
        // clusters with slice lists are not considered.
        if (sc->slice_lists().size()) {
            continue; }

        bool has_checksummed = sc->any_of_fieldslices(
                [&] (const PHV::FieldSlice& fs) { return fs.field()->is_checksummed(); });
        if (has_checksummed) {
            continue; }

        auto available_spots = rst.available_spots();
        ordered_set<bitvec> slice_schemas = calc_slicing_schemas(sc, available_spots);
        // Try different slicing, from large to small
        for (const auto& slice_schema : slice_schemas) {
            LOG5("Splitting supercluster" << sc << "using schema " << slice_schema);
            auto slice_rst = PHV::Slicing::split_rotational_cluster(sc, slice_schema);
            if (!slice_rst) continue;

            if (LOGGING(5)) {
                LOG5("Pounder slicing: " << sc << " to ");
                for (auto* new_sc : *slice_rst) {
                    LOG5(new_sc); } }

            std::list<PHV::SuperCluster*> sliced_sc = *slice_rst;
            auto try_this_slicing = rst.makeTransaction();
            allocLoop(try_this_slicing, sliced_sc, container_groups, score_ctx);
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

boost::optional<const PHV::SuperCluster::SliceList*>
BruteForceAllocationStrategy::preslice_validation(
    const std::list<PHV::SuperCluster*>& clusters,
    const std::list<PHV::ContainerGroup*>& container_groups) const {
    for (PHV::SuperCluster* cluster : clusters) {
        int n_tried = 0;
        auto& pa_container_sizes = core_alloc_i.pragmas().pa_container_sizes();
        bool succ = false;
        auto itr_ctx = PHV::Slicing::ItrContext(cluster, pa_container_sizes.field_to_layout(),
                                                has_pack_conflict_i, is_referenced_i);
        boost::optional<const PHV::SuperCluster::SliceList*> last_invald;
        itr_ctx.iterate([&](std::list<PHV::SuperCluster*> sliced) {
            ++n_tried;
            if (n_tried > config_i.max_slicing) {
                return false;
            }
            // if (pa_container_sizes.unsatisfiable_fields(sliced).size() > 0) {
            //     // LOG4("Container size unsatisfiable slicing, continue ...");
            //     return true;
            // }
            for (auto* sc : sliced) {
                // we don't validate stridedAlloc cluster.
                if (!sc->needsStridedAlloc()) {
                    if (auto unallocatable = diagnose_slicing(sliced, container_groups)) {
                        itr_ctx.invalidate(*unallocatable);
                        last_invald = *unallocatable;
                        return true;
                    }
                }
            }
            // all allocated
            succ = true;
            return false;
        });
        if (!succ) {
            if (last_invald) {
                return last_invald;
            } else {
                LOG1("preslice_validation cannot allocate "
                     << cluster << "but no unallocatable slice list was found");
                return boost::none;
            }
        }
    }
    return boost::none;
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::preslice_clusters(
        const std::list<PHV::SuperCluster*>& cluster_groups,
        const std::list<PHV::ContainerGroup *>& container_groups,
        std::list<PHV::SuperCluster*>& unsliceable) {
    auto& pa_container_sizes = core_alloc_i.pragmas().pa_container_sizes();
    auto& meter_color_dests = core_alloc_i.actionConstraints().meter_color_dests();
    auto throw_failure = [&](PHV::SuperCluster* sc, int n_tried) {
        unsliceable.push_back(sc);
        ordered_set<const PHV::Field*> unsat_fields;
        sc->forall_fieldslices([&](const PHV::FieldSlice& fs) {
            const auto* f = fs.field();
            if (!unsat_fields.count(f) && pa_container_sizes.field_to_layout().count(f)) {
                unsat_fields.insert(f);
                if (meter_color_dests.count(f)) {
                    if (f->size > 8) {
                        P4C_UNIMPLEMENTED(
                            "Currently the compiler only supports allocation "
                            "of meter color destination field %1% to an 8-bit container. "
                            "However, meter color destination %1% with size %2% bits "
                            "cannot be split based on its use. Therefore, it cannot be "
                            "allocated to an 8-bit container. Suggest using a meter color "
                            "destination that is less than or equal to 8b in size.",
                            f->name, f->size);
                    } else {
                        P4C_UNIMPLEMENTED(
                            "Currently the compiler only supports allocation of "
                            "meter color destination field %1% to an 8-bit container. "
                            "However, %1% cannot be allocated to an 8-bit container.",
                            f->name);
                    }
                }
            }
        });
        if (LOGGING(5)) {
            if (unsat_fields.size() > 0) {
                LOG5("Found " << unsat_fields.size() << " unsatisfiable fields.");
            }
            for (const auto* f : unsat_fields) {
                LOG5("\t" << f);
            }
        }
        if (unsat_fields.size() > 0) {
            std::stringstream ss;
            ss << "Cannot find a slicing to satisfy @pa_container_size pragma(s): ";
            std::string sep = "";
            for (const auto* f : unsat_fields) {
                ss << sep << f->name;
                sep = ", ";
            }
            ss << "\n" << sc;
            ::error("%1%", ss.str());
        } else if (n_tried == 0) {
            BUG("invalid SuperCluster was formed");
        }
    };

    LOG5("===================  Pre-Slicing ===================");
    std::list<PHV::SuperCluster*> rst;
    for (auto* sc : cluster_groups) {
        LOG5("PRESLICING " << sc);
        try {
            // Try until we find one (1) satisfies pa_container_size pragmas
            // (2) allocatable, because we do not take action constraints into account
            // in slicing iterator, we need to do a virtual allocation test to see whether
            // the presliced clusters can be allocated. It is enabled if
            // config.pre_slicing_validation is true.
            bool found = false;
            int n_tried = 0;
            std::list<PHV::SuperCluster*> sliced;

            auto itr_ctx = PHV::Slicing::ItrContext(
                sc, core_alloc_i.pragmas().pa_container_sizes().field_to_layout(),
                has_pack_conflict_i, is_referenced_i);
            itr_ctx.iterate([&](std::list<PHV::SuperCluster*> sliced_clusters) {
                n_tried++;
                if (n_tried > config_i.max_slicing) {
                    return false;
                }
                // pa_container_sizes.adjust_requirements(sliced_clusters);
                // auto unsatisfiable_fields =
                //     pa_container_sizes.unsatisfiable_fields(sliced_clusters);
                // if (unsatisfiable_fields.size() > 0) {
                //     LOG5("Found " << unsatisfiable_fields.size() << " unsatisfiable fields.");
                //     for (const auto* f : unsatisfiable_fields) LOG5("\t" << f);
                // }
                // if (unsatisfiable_fields.size() == 0) {
                    if (config_i.pre_slicing_validation) {
                        // validation did not pass
                        if (auto unallocatable =
                                preslice_validation(sliced_clusters, container_groups)) {
                            itr_ctx.invalidate(*unallocatable);
                            return true;
                        }
                    }
                    found = true;
                    sliced = sliced_clusters;
                    return false;
                // }
                // return true;
            });
            if (found) {
                LOG5("--- into new slices -->");
                for (auto* new_sc : sliced) {
                    LOG5(new_sc);
                    rst.push_back(new_sc);
                }
            } else {
                LOG5("slicing tried " << n_tried << " but still failed");
                throw_failure(sc, n_tried);
            }
        } catch (const Util::CompilerBug& e) {
            BUG("The compiler failed in slicing the following group of fields related by "
                "parser alignment and MAU constraints\n%1%, %2%\n", sc, e.what());
        }
    }
    return rst;
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::remove_deparser_zero_superclusters(
        const std::list<PHV::SuperCluster*>& cluster_groups,
        std::list<PHV::SuperCluster*>& deparser_zero_superclusters) const {
    std::list<PHV::SuperCluster*> rst;
    for (auto* sc : cluster_groups) {
        bool has_deparser_zero_fields = sc->all_of_fieldslices(
                [&] (const PHV::FieldSlice& fs) { return fs.field()->is_deparser_zero_candidate();
                });
        if (has_deparser_zero_fields) {
            LOG4("    ...removing deparser zero supercluster from unallocated superclusters.");
            deparser_zero_superclusters.push_back(sc);
            continue; }
        rst.push_back(sc); }
    return rst;
}

/// Check if the supercluster has field slice that requires strided
/// allocation. Merge all related stride superclusters.
std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::create_strided_clusters(
        const std::list<PHV::SuperCluster*>& cluster_groups) const {
    std::list<PHV::SuperCluster*> rst;

    for (auto g : cluster_groups) {
        const ordered_set<const PHV::Field*>* strided_group = nullptr;
        auto g_slices = g->slices();

        for (auto sl : g_slices) {
            strided_group = strided_headers_i.get_strided_group(sl.field());

            if (strided_group) {
                if (g_slices.size() != 1) {
                    ::error("Field %1% requires strided allocation"
                            " but has conflicting constraints on it.", sl.field()->name);
                }
                break;
            }
        }

        if (strided_group) {
            bool merged = false;

            for (auto r : rst) {
                auto r_slices = r->slices();
                for (auto sl : r_slices) {
                    if (strided_group->count(sl.field())) {
                        if (r_slices.begin()->range() == g_slices.begin()->range()) {
                            rst.remove(r);
                            auto m = r->merge(g);
                            m->needsStridedAlloc(true);
                            rst.push_back(m);
                            merged = true;
                            break;
                        }
                    }
                }

                if (merged)
                    break;
            }

            if (!merged)
                rst.push_back(g);
        } else {
            rst.push_back(g);
        }
    }

    return rst;
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::remove_singleton_slicelist_metadata(
        const std::list<PHV::SuperCluster*>& cluster_groups) const {
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
            || fs.field()->exact_containers()
            || fs.field()->pov
            || fs.field()->is_checksummed()
            || fs.field()->deparsed_bottom_bits()
            || fs.field()->is_marshaled()) {
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
BruteForceAllocationStrategy::tryAllocationFailuresFirst(
    const PHV::Allocation &alloc,
    const std::list<PHV::SuperCluster*>& cluster_groups_input,
    const std::list<PHV::ContainerGroup*>& container_groups,
    const ordered_set<const PHV::Field*>& failures) {
    // remove singleton un_referenced fields
    std::list<PHV::SuperCluster*> cluster_groups =
        remove_unreferenced_clusters(cluster_groups_input);

    // remove singleton metadata slice list
    // TODO(yumin): This was introduced because some metadata fields are placed
    // in supercluster but it should not. If this does not happen anymore, we should
    // remove this.
    cluster_groups = remove_singleton_slicelist_metadata(cluster_groups);

    // slice and then sort clusters.
    std::list<PHV::SuperCluster*> unsliceable;
    cluster_groups = preslice_clusters(cluster_groups, container_groups, unsliceable);

    // fail early if some clusters have unsatisfiable constraints.
    if (unsliceable.size()) {
        return AllocResult(AllocResultCode::FAIL_UNSAT_SLICING,
                           alloc.makeTransaction(),
                           std::move(unsliceable)); }

    // remove deparser zero superclusters.
    std::list<PHV::SuperCluster*> deparser_zero_superclusters;
    cluster_groups = remove_deparser_zero_superclusters(
        cluster_groups, deparser_zero_superclusters);

    cluster_groups = create_strided_clusters(cluster_groups);

    // Sorting clusters must happen after the deparser zero superclusters are removed.
    sortClusters(cluster_groups);

    // prioritize previously failed clusters
    const auto priority = [&] (PHV::SuperCluster *sc) -> int {
        for (const auto& f : failures) {
            if (sc->contains(f)) {
                return 1;
            }
        }
        return 0;
    };
    cluster_groups.sort([&] (PHV::SuperCluster *l, PHV::SuperCluster * r) {
        return priority(l) > priority(r);
    });

    auto rst = alloc.makeTransaction();

    // Allocate deparser zero fields first.
    auto allocated_dep_zero_clusters = allocDeparserZeroSuperclusters(
        rst, deparser_zero_superclusters);

    if (deparser_zero_superclusters.size() > 0) {
        LOG1("Deparser Zero field allocation failed: " << deparser_zero_superclusters.size());
    }

    // Packing opportunities for each field, if allocated in @p cluster_groups order.
    auto* packing_opportunities = new FieldPackingOpportunity(
            cluster_groups, core_alloc_i.actionConstraints(),
            core_alloc_i.uses(), core_alloc_i.defuse(), core_alloc_i.mutex());
    log_packing_opportunities(packing_opportunities, cluster_groups);

    auto score_ctx = AllocContext(name, config_i.is_better);
    score_ctx = score_ctx.with(packing_opportunities);
    auto allocated_clusters = allocLoop(rst, cluster_groups, container_groups, score_ctx);

    // Pounder Round
    if (cluster_groups.size() > 0) {
        LOG5(cluster_groups.size()
             << " supercluster are unallocated before Pounder Round, they are:");
        for (auto* sc : cluster_groups) {
            LOG5(sc); }

        LOG5("Pounder Round");
        auto allocated_cluster_powders =
            pounderRoundAllocLoop(rst, cluster_groups, container_groups); }

    if (cluster_groups.size() > 0 || deparser_zero_superclusters.size() > 0) {
        return AllocResult(AllocResultCode::FAIL, std::move(rst), std::move(cluster_groups));
    }

    return AllocResult(AllocResultCode::SUCCESS, std::move(rst), std::move(cluster_groups));
}


AllocResult
BruteForceAllocationStrategy::tryAllocation(
    const PHV::Allocation &alloc,
    const std::list<PHV::SuperCluster*>& cluster_groups_input,
    const std::list<PHV::ContainerGroup *>& container_groups) {
    ordered_set<const PHV::Field*> failed;
    AllocResult rst(
        AllocResultCode::UNKNOWN, alloc.makeTransaction(), {});
    cstring log_prefix = "allocation(" + name + "): ";
    bool succ = false;
    int max_try = config_i.max_failure_retry + 1;
    for (int i = 0; i < max_try; i++) {
        LOG1(log_prefix << " try allocation for the " << i + 1 << "th time");
        if (failed.size() > 0) {
            LOG1(log_prefix << "Try again with failures prioritized");
            for (const auto& fs : failed) {
                LOG1("\t.. " << fs);
            }
        }
        rst = tryAllocationFailuresFirst(
            alloc, cluster_groups_input, container_groups, failed);
        if (rst.status != AllocResultCode::SUCCESS) {
            if (rst.status == AllocResultCode::FAIL) {
                for (const auto& sc : rst.remaining_clusters) {
                    sc->forall_fieldslices(
                        [&] (const PHV::FieldSlice& fs) {
                            failed.insert(fs.field());
                        });
                }
            } else {
                break;
            }
        } else {
            LOG1(log_prefix << "succeeded");
            succ = true;
            break;
        }
    }
    if (!succ) {
        LOG1(log_prefix << "failed after " << max_try << " tries, "
             << "failure code " << int(rst.status));
    }
    return rst;
}

void
BruteForceAllocationStrategy::sortClusters(std::list<PHV::SuperCluster*>& cluster_groups) {
    // Critical Path result are not used.
    // auto critical_clusters = critical_path_clusters_i.calc_critical_clusters(cluster_groups);
    std::set<const PHV::SuperCluster*> has_solitary;
    std::set<const PHV::SuperCluster*> has_no_split;
    std::map<const PHV::SuperCluster*, int> n_valid_starts;
    std::map<const PHV::SuperCluster*, int> n_required_length;
    std::set<const PHV::SuperCluster*> pounder_clusters;
    std::set<const PHV::SuperCluster*> non_sliceable;
    std::set<const PHV::SuperCluster*> has_pov;
    std::map<const PHV::SuperCluster*, int> n_extracted_uninitialized;
    std::map<const PHV::SuperCluster*, size_t> n_container_size_pragma;
    std::set<const PHV::SuperCluster*> has_container_type_pragma;

    // calc whether the cluster has pov bits.
    for (auto* cluster : cluster_groups) {
        cluster->forall_fieldslices([&] (const PHV::FieldSlice& fs) {
            if (fs.field()->pov)
                has_pov.insert(cluster);
        });
    }

    // calc whether the cluster has container type pragma. Only for JBay.
    if (Device::currentDevice() != Device::TOFINO) {
        for (auto* cluster : cluster_groups) {
            cluster->forall_fieldslices([&] (const PHV::FieldSlice& fs) {
                if (core_alloc_i.pragmas().pa_container_type().required_kind(fs.field()))
                    has_container_type_pragma.insert(cluster);
            });
        }
    }

    // calc n_container_size_pragma.
    const auto& container_sizes = core_alloc_i.pragmas().pa_container_sizes();
    for (auto* cluster : cluster_groups) {
        ordered_set<const PHV::Field*> fields;
        cluster->forall_fieldslices([&] (const PHV::FieldSlice& fs) {
            if (container_sizes.is_specified(fs.field()))
                fields.insert(fs.field());
        });
        n_container_size_pragma[cluster] = fields.size();
    }

    // calc num_pack_conflicts
    for (auto* super_cluster : cluster_groups)
        super_cluster->calc_pack_conflicts();

    // calc n_extracted_uninitialized
    for (auto* cluster : cluster_groups) {
        n_extracted_uninitialized[cluster] = 0;
        cluster->forall_fieldslices([&] (const PHV::FieldSlice& fs) {
            auto* f = fs.field();
            if (core_alloc_i.uses().is_extracted(f) ||
                core_alloc_i.defuse().hasUninitializedRead(f->id)) {
                n_extracted_uninitialized[cluster]++;
            }
        });
    }

    // calc has_solitary and no_split.
    for (const auto* super_cluster : cluster_groups) {
        n_valid_starts[super_cluster] = (std::numeric_limits<int>::max)();
        for (const auto* rot : super_cluster->clusters()) {
            for (const auto* ali : rot->clusters()) {
                bitvec starts = ali->validContainerStart(PHV::Size::b32);
                int n_starts = std::accumulate(starts.begin(), starts.end(), 0,
                                               [] (int a, int) { return a + 1; });
                n_valid_starts[super_cluster] =
                    std::min(n_valid_starts[super_cluster], n_starts);
                n_valid_starts[super_cluster] = std::min(n_valid_starts[super_cluster], 5);

                for (const auto& slice : ali->slices()) {
                    if (slice.field()->is_solitary()) {
                        has_solitary.insert(super_cluster); }
                    if (slice.field()->no_split() || slice.field()->has_no_split_at_pos()) {
                        has_no_split.insert(super_cluster); } }
            } } }

    // calc pounder-able clusters.
    for (const auto* super_cluster : cluster_groups) {
        if (has_no_split.count(super_cluster) || has_solitary.count(super_cluster)) continue;
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

    // calc non_sliceable clusters
    // i.e. 8-bit and exact container required.
    for (const auto* super_cluster : cluster_groups)
        if (!super_cluster->isSliceable())
            non_sliceable.insert(super_cluster);

    // calc required_length, i.e. max(max{fieldslice.size()}, {slicelist.size()}).
    for (const auto* super_cluster : cluster_groups) {
        n_required_length[super_cluster] = super_cluster->max_width();
        for (const auto* slice_list : super_cluster->slice_lists()) {
            BUG_CHECK(slice_list->size() > 0, "empty slice list");
            int length = PHV::SuperCluster::slice_list_total_bits(*slice_list);
            n_required_length[super_cluster] =
                std::max(n_required_length[super_cluster], length);
        } }

    // Other heuristics:
    // if (has_pov.count(l) != has_pov.count(r)) {
    //     return has_pov.count(l) > has_pov.count(r); }
    // if (pounder_clusters.count(l) != pounder_clusters.count(r)) {
    //     return pounder_clusters.count(l) < pounder_clusters.count(r); }
    // if (critical_clusters.count(l) != critical_clusters.count(r)) {
    //     return critical_clusters.count(l) > critical_clusters.count(r); }
    // if (l->max_width() != r->max_width()) {
    //     return l->max_width() > r->max_width(); }

    auto ClusterGroupComparator = [&] (PHV::SuperCluster* l, PHV::SuperCluster* r) {
        if (Device::currentDevice() != Device::TOFINO) {
            // if (has_container_type_pragma.count(l) != has_container_type_pragma.count(r)) {
            //     return has_container_type_pragma.count(l) > has_container_type_pragma.count(r); }
            if (n_container_size_pragma.at(l) != n_container_size_pragma.at(r))
                return n_container_size_pragma.at(l) > n_container_size_pragma.at(r);
            if (has_pov.count(l) != has_pov.count(r))
                return has_pov.count(l) > has_pov.count(r);
        }
        if (has_solitary.count(l) != has_solitary.count(r)) {
            return has_solitary.count(l) > has_solitary.count(r); }
        if (has_no_split.count(l) != has_no_split.count(r)) {
            return has_no_split.count(l) > has_no_split.count(r); }
        if (non_sliceable.count(l) != non_sliceable.count(r)) {
            return non_sliceable.count(l) > non_sliceable.count(r); }
        if (bool(l->exact_containers()) != bool(r->exact_containers())) {
            return bool(l->exact_containers()) > bool(r->exact_containers()); }
        // if it's header fields
        if (bool(l->exact_containers())) {
            if (n_required_length[l] != n_required_length[r]) {
                return n_required_length[l] > n_required_length[r]; }
            if (l->slice_lists().size() != r->slice_lists().size()) {
                return l->slice_lists().size() > r->slice_lists().size(); }
        } else {
            if  (Device::currentDevice() == Device::TOFINO)
               if (has_pov.count(l) != has_pov.count(r))
                   return has_pov.count(l) > has_pov.count(r);
            // for non header field, aggregate size matters
            if (n_valid_starts.at(l) != n_valid_starts.at(r)) {
                return n_valid_starts.at(l) < n_valid_starts.at(r); }
            if (n_extracted_uninitialized[l] != n_extracted_uninitialized[r]) {
                return n_extracted_uninitialized[l] > n_extracted_uninitialized[r]; }
            if (l->num_pack_conflicts() != r->num_pack_conflicts()) {
                return l->num_pack_conflicts() > r->num_pack_conflicts(); }
            if (l->aggregate_size() != r->aggregate_size()) {
                return l->aggregate_size() > r->aggregate_size(); }
            if (n_required_length[l] != n_required_length[r]) {
                return n_required_length[l] > n_required_length[r]; }
        }
        if (l->num_constraints() != r->num_constraints()) {
            return l->num_constraints() > r->num_constraints(); }
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
            logs << "is_solitary: "           << has_solitary.count(v) << ", ";
            logs << "is_no_split: "           << has_no_split.count(v) << ", ";
            logs << "is_non_sliceable: "      << non_sliceable.count(v) << ", ";
            logs << "is_exact_container: "    << v->exact_containers() << ", ";
            logs << "is_pounderable: "        << pounder_clusters.count(v) << ", ";
            logs << "required_length: "       << n_required_length[v] << ", ";
            logs << "n_valid_starts: "        << n_valid_starts[v] << ", ";
            logs << "n_pack_conflicts: "        << v->num_pack_conflicts() << ", ";
            logs << "n_extracted_uninitialized: "  << n_extracted_uninitialized[v] << ", ";
            logs << "]\n";
            logs << v; }
        LOG5(logs.str());
        LOG5("========== end Sorted SuperClusters ============="); }
}

/// Check if the giving slicing is valid for strided allocation.
/// To be valid for strided allocation, all fields within cluster
/// must have same slicing.
bool is_valid_stride_slicing(std::list<PHV::SuperCluster*>& slicing) {
    // XXX(zma) somehow for the singleton case, the slicing iterator
    // does not slice further, manually break each slice into its own
    // supercluster here ... yuck!
    if (slicing.size() == 1)  {
        auto sc = slicing.front();

        std::list<PHV::SuperCluster*> sliced;

        BUG_CHECK(sc->clusters().size() == sc->slice_lists().size(),
                  "malformed supercluster? %1%", sc);

        auto cit = sc->clusters().begin();
        auto sit = sc->slice_lists().begin();

        while (cit != sc->clusters().end()) {
            auto scc = new PHV::SuperCluster({*cit}, {*sit});
            sliced.push_back(scc);
            cit++;
            sit++;
        }

        slicing = sliced;

        return true;
    }

    for (auto x : slicing) {
        bool found_equiv = false;

        for (auto y : slicing) {
            if (x == y)
                continue;

            if (x->slices().begin()->range() == y->slices().begin()->range()) {
                found_equiv = true;
                break;
            }
        }

        if (!found_equiv)
            return false;
    }

    return true;
}

boost::optional<const PHV::SuperCluster::SliceList*> BruteForceAllocationStrategy::diagnose_slicing(
    const std::list<PHV::SuperCluster*>& slicing,
    const std::list<PHV::ContainerGroup*>& container_groups) const {
    AllocContext score_ctx("dummy", [](const AllocScore, const AllocScore){ return false; });
    LOG3("diagnose_slicing starts");
    auto tx = empty_alloc_i.makeTransaction();
    for (auto* sc : slicing) {
        // cannot diagnose fields with wide_arithmetic.
        if (sc->any_of_fieldslices([](const PHV::FieldSlice& fs) {
                return fs.field()->used_in_wide_arith();
            })) {
            continue;
        }
        bool allocated = false;
        for (const PHV::ContainerGroup* container_group : container_groups) {
            auto partial_alloc = core_alloc_i.tryAlloc(tx, *container_group, *sc, 1, score_ctx);
            if (partial_alloc) {
                allocated = true;
                tx.commit(*partial_alloc);
                break;
            }
        }
        if (!allocated) {
            LOG3("diagnose_slicing found a unallocatable super cluster: " << sc->uid);
            auto failing_sl = core_alloc_i.find_first_unallocated_slicelist(
                    tx, container_groups, *sc, score_ctx);
            if (failing_sl) {
                LOG3("diagnose_slicing found a unallocatable sl: " << *failing_sl);
            }
            return failing_sl;
        }
    }
    return boost::none;
}

bool
BruteForceAllocationStrategy::tryAllocSlicing(
    const std::list<PHV::SuperCluster*>& slicing,
    const std::list<PHV::ContainerGroup*>& container_groups,
    PHV::Transaction& slicing_alloc,
    const AllocContext& score_ctx) {
    LOG4("Try alloc slicing:");

    // Place all slices, then get score for that placement.
    bool succeeded = true;

    for (auto* sc : slicing) {
        // Find best container group for this slice.
        auto best_slice_score = AllocScore::make_lowest();
        boost::optional<PHV::Transaction> best_slice_alloc = boost::none;

        for (PHV::ContainerGroup* container_group : container_groups) {
            LOG4("Try to allocate to container group: " << container_group);

            if (auto partial_alloc =
                core_alloc_i.tryAlloc(slicing_alloc, *container_group, *sc,
                                      config_i.max_sl_alignment, score_ctx)) {
                AllocScore score = score_ctx.make_score(*partial_alloc,
                        core_alloc_i.phv(), clot_i, core_alloc_i.uses(),
                        core_alloc_i.field_to_parser_states(),
                        core_alloc_i.parser_critical_path());
                LOG4("    ...SUPERCLUSTER score: " << score);
                if (!best_slice_alloc || score_ctx.is_better(score, best_slice_score)) {
                    best_slice_score = score;
                    best_slice_alloc = partial_alloc;
                }
            } else {
                LOG4("Failed to allocate to " << container_group);
            }
        }

        // Break if this slice couldn't be placed.
        if (best_slice_alloc == boost::none) {
            LOG4("...but these SUPERCLUSTER Uid: " << sc->uid
                << " slices could not be placed.");
            succeeded = false;
            break;
        }

        // Otherwise, update the score.
        slicing_alloc.commit(*best_slice_alloc);
    }

    return succeeded;
}

std::vector<std::list<PHV::SuperCluster*>>
reorder_slicing_as_strides(unsigned num_strides,
                           const std::list<PHV::SuperCluster*>& slicing) {
    std::vector<PHV::SuperCluster*> vec;
    for (auto sl : slicing)
        vec.push_back(sl);

    std::vector<std::list<PHV::SuperCluster*>> strides;

    for (unsigned i = 0; i < num_strides; i++) {
        std::list<PHV::SuperCluster*> stride;
        for (unsigned j = 0; j < slicing.size() / num_strides; j++) {
            stride.push_back(vec[j * num_strides + i]);
        }
        strides.push_back(stride);
    }

    if (LOGGING(4)) {
        LOG4("After strided reordering:");
        for (auto& stride : strides) {
            int i = 0;
            LOG4("stride " << i++ << " :");
            for (auto* sc : stride)
                LOG4(sc);
        }
    }

    return strides;
}

bool
BruteForceAllocationStrategy::tryAllocStride(
    const std::list<PHV::SuperCluster*>& stride,
    const std::list<PHV::ContainerGroup *>& container_groups,
    PHV::Transaction& stride_alloc,
    const AllocContext& score_ctx) {
    LOG4("Try alloc slicing stride");

    auto best_score = AllocScore::make_lowest();
    boost::optional<PHV::Transaction> best_alloc = boost::none;

    auto leader = stride.front();

    for (PHV::ContainerGroup* container_group : container_groups) {
        LOG4("Try container group: " << container_group);

        auto leader_alloc = core_alloc_i.tryAlloc(
            stride_alloc, *container_group, *leader, config_i.max_sl_alignment, score_ctx);
        if (leader_alloc) {
            // alloc rest
            if (tryAllocStrideWithLeaderAllocated(stride, *leader_alloc, score_ctx)) {
                AllocScore score = score_ctx.make_score(*leader_alloc,
                        core_alloc_i.phv(), clot_i, core_alloc_i.uses(),
                        core_alloc_i.field_to_parser_states(),
                        core_alloc_i.parser_critical_path());

                if (!best_alloc || score_ctx.is_better(score, best_score)) {
                    best_score = score;
                    best_alloc = leader_alloc;
                }
            }
        }
    }

    if (best_alloc == boost::none) {
        LOG4("Failed to allocate slicing stride");
        return false;
    }

    stride_alloc.commit(*best_alloc);
    return true;
}

bool
BruteForceAllocationStrategy::tryAllocStrideWithLeaderAllocated(
        const std::list<PHV::SuperCluster*>& stride,
        PHV::Transaction& leader_alloc,
        const AllocContext& score_ctx
    ) {
    auto leader = stride.front();
    auto slices = leader->slices();
    auto status = leader_alloc.getTransactionStatus();

    PHV::Container prev;

    for (auto& kv : status) {
        for (auto sl : kv.second.slices) {
            if (sl.field() == slices.begin()->field() &&
                sl.field_slice() == slices.begin()->range()) {
                if (prev)
                    BUG("strided slice gets allocated into multiple containers? %1%", sl);

                prev = sl.container();
            }
        }
    }

    for (auto* sc : stride) {
        if (sc == leader)
            continue;

        PHV::Container curr(prev.type(), prev.index() + 1);

        if (leader_alloc.getStatus(curr) == boost::none) {
            LOG4("falling off the cliff with " << curr);
            return false;
        }

        PHV::ContainerGroup cg(curr.type().size(), {curr});

        auto sc_alloc = core_alloc_i.tryAlloc(leader_alloc, cg, *sc,
                                              config_i.max_sl_alignment, score_ctx);

        if (!sc_alloc) {
            LOG4("failed to alloc next stride slice in " << curr);
            return false;
        }

        LOG4("allocated next stride slice in " << curr);
        leader_alloc.commit(*sc_alloc);
        prev = curr;
    }

    return true;
}

bool
BruteForceAllocationStrategy::tryAllocSlicingStrided(
    unsigned num_strides,
    const std::list<PHV::SuperCluster*>& slicing,
    const std::list<PHV::ContainerGroup *>& container_groups,
    PHV::Transaction& slicing_alloc,
    const AllocContext& score_ctx) {
    LOG4("Try alloc slicing strided: (num_stride = " << num_strides << ")");

    auto strides = reorder_slicing_as_strides(num_strides, slicing);

    int i = 0;
    for (auto& stride : strides) {
        auto stride_alloc = slicing_alloc.makeTransaction();
        bool succeeded = tryAllocStride(stride, container_groups, stride_alloc, score_ctx);

        if (succeeded) {
            slicing_alloc.commit(stride_alloc);
            LOG4("alloc stride " << i << " ok");
        } else {
            LOG4("Failed to alloc stride " << i);
            return false;
        }
        i++;
    }

    LOG4("All strides allocated!");

    return true;
}

boost::optional<PHV::Transaction>
BruteForceAllocationStrategy::tryVariousSlicing(
    PHV::Transaction& rst,
    PHV::SuperCluster* cluster_group,
    const std::list<PHV::ContainerGroup *>& container_groups,
    const AllocContext& score_ctx,
    std::stringstream& alloc_history) {
    auto best_score = AllocScore::make_lowest();
    boost::optional<PHV::Transaction> best_alloc = boost::none;
    boost::optional<std::list<PHV::SuperCluster*>> best_slicing = boost::none;
    std::vector<const PHV::SuperCluster::SliceList*> diagnosed_unallocatables;
    int MAX_SLICING_TRY = config_i.max_slicing;

    /// XXX(zma) strided cluster can have many slices in the supercluster
    /// and the number of slicing can blow up (need a better way to stop
    /// than this crude heuristic).
    if (cluster_group->needsStridedAlloc() || BackendOptions().quick_phv_alloc)
        MAX_SLICING_TRY = 128;

    int n_tried = 0;

    // Try all possible slicings.
    auto& pa_container_sizes = core_alloc_i.pragmas().pa_container_sizes();
    auto itr_ctx = PHV::Slicing::ItrContext(
        cluster_group, pa_container_sizes.field_to_layout(),
        has_pack_conflict_i, is_referenced_i);
    itr_ctx.iterate([&](std::list<PHV::SuperCluster*> slicing) {
        ++n_tried;
        if (n_tried > MAX_SLICING_TRY) {
            return false;
        }
        if (LOGGING(4)) {
            LOG4("Slicing attempt: " << n_tried);
            for (auto* sc : slicing)
                LOG4(sc);
        }

        if (cluster_group->needsStridedAlloc()) {
            if (!is_valid_stride_slicing(slicing)) {
                LOG4("Invalid stride slicing, continue ...");
                return true;
            }
        }

        LOG4("Valid slicing, try to place all slices in slicing:");

        // Place all slices, then get score for that placement.
        auto slicing_alloc = rst.makeTransaction();
        bool succeeded = false;

        if (cluster_group->needsStridedAlloc()) {
            LOG5("invoke strided allocation");
            unsigned num_strides = slicing.size() / cluster_group->slices().size();
            succeeded = tryAllocSlicingStrided(
                num_strides, slicing, container_groups, slicing_alloc, score_ctx);
        } else {
            LOG5("invoke normal allocation");
            succeeded = tryAllocSlicing(
                slicing, container_groups, slicing_alloc, score_ctx);
        }

        if (!succeeded) {
            LOG5("Failed to allocate with this slicing");
            if (cluster_group->slice_lists().size() > 0) {
                LOG5("Check impossible slicelist");
                if (auto impossible_slicelist =
                        diagnose_slicing(slicing, container_groups)) {
                    LOG5("found slicelist that is impossible to allocate: "
                            << *impossible_slicelist);
                    itr_ctx.invalidate(*impossible_slicelist);
                    diagnosed_unallocatables.push_back(*impossible_slicelist);
                }
            }
            return true;
        } else {
            LOG5("Successfully allocate @sc with this slicing");
        }

        // If allocation succeeded, check the score.
        auto slicing_score = score_ctx.make_score(
            slicing_alloc,
            core_alloc_i.phv(), clot_i, core_alloc_i.uses(),
            core_alloc_i.field_to_parser_states(),
            core_alloc_i.parser_critical_path());
        if (LOGGING(4)) {
            LOG4("Best SUPERCLUSTER score for this slicing: " << slicing_score);
            LOG4("For the following SUPERCLUSTER slices: ");
            for (auto* sc : slicing)
                LOG4(sc);
        }
        if (!best_alloc || score_ctx.is_better(slicing_score, best_score)) {
            best_score = slicing_score;
            best_alloc = slicing_alloc;
            best_slicing = slicing;
            LOG4("...and this is the best score seen so far.");
        }
        return true;
    });

    // Fill the log before the transaction is merged
    if (best_alloc) {
        LOG4("SUCCESSFULLY allocated " << cluster_group);
        std::set<PHV::FieldSlice> fs_allocated;
        for (auto* sc : *best_slicing) {
            for (const auto& fs : sc->slices()) {
                fs_allocated.insert(fs);
            }
        }
        alloc_history << "Successfully Allocated\n";
        alloc_history << "By slicing into the following superclusters:\n";
        for (auto* sc : *best_slicing) {
            alloc_history << sc << "\n";
        }
        alloc_history << "Best Score: " << best_score << "\n";
        alloc_history << "Allocation Decisions:" << "\n";
        for (const auto& container_status : (*best_alloc).getTransactionStatus()) {
            // const auto& c = container_status.first;
            const auto& status = container_status.second;
            if (status.slices.empty()) {
                continue;
            }
            for (const auto& a : status.slices) {
                auto fs = PHV::FieldSlice(a.field(), a.field_slice());
                if (fs_allocated.count(fs)) {
                    alloc_history << "allocate: " << a.container() <<
                        "[" << a.container_slice().lo << ":"
                                    << a.container_slice().hi <<"] <- "
                                    << fs << "\n";
                }
            }
        }
    } else {
        LOG4("FAILED to allocate " << cluster_group);
        alloc_history << "FAILED to allocate " << cluster_group << "\n";
        alloc_history << "when the things are like: " << "\n";
        alloc_history << rst.getTransactionSummary() << "\n";
        // XXX(yumin): if a slice is unallocatable, then it must be unallocatable in
        // all different slicings, so that diagnosed_unallocatables.size() must be
        // equal or larger to n_tried.
        if (int(diagnosed_unallocatables.size()) > n_tried) {
            bool all_same = diagnosed_unallocatables.size() == 1 ||
                            std::all_of(diagnosed_unallocatables.begin() + 1,
                                        diagnosed_unallocatables.end(),
                                        [&](const PHV::SuperCluster::SliceList* sl) {
                                            return *sl == *(diagnosed_unallocatables.front());
                                        });
            if (all_same) {
                LOG1("found possible unallocatable slice list: "
                        << diagnosed_unallocatables.front());
                if (!unallocatable_list_i) {
                    unallocatable_list_i = diagnosed_unallocatables.front();
                }
            }
        }
    }
    return best_alloc;
}

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::allocLoop(
    PHV::Transaction& rst,
    std::list<PHV::SuperCluster*>& cluster_groups,
    const std::list<PHV::ContainerGroup *>& container_groups,
    const AllocContext& score_ctx) {
    // allocation history
    std::stringstream alloc_history;
    int n = 0;
    std::list<PHV::SuperCluster*> allocated;

    BruteForceOptimizationStrategy opt_strategy(*this, container_groups, score_ctx);
    PHV::Transaction try_alloc = rst.makeTransaction();
    for (PHV::SuperCluster* cluster_group : cluster_groups) {
        n++;
        alloc_history << n << ": " << "TRYING to allocate " << cluster_group;
        LOG4("TRYING to allocate " << cluster_group);

        boost::optional<PHV::Transaction> best_alloc = tryVariousSlicing(try_alloc,
                                                                         cluster_group,
                                                                         container_groups,
                                                                         score_ctx,
                                                                         alloc_history);

        // If any allocation was found, commit it.
        if (best_alloc) {
            PHV::Transaction* clone = (*best_alloc).clone(try_alloc);
            opt_strategy.addTransaction(*clone, *cluster_group);
            try_alloc.commit(*best_alloc);
            allocated.push_back(cluster_group);
        }
    }

    // XXX(cole): There must be a better way to remove elements from a list
    // while iterating, but `it = clusters_i.erase(it)` skips elements.
    for (auto cluster_group : allocated)
        cluster_groups.remove(cluster_group);

    auto logfile = createFileLog(pipe_id_i, "phv_allocation_history_", 4);
    LOG4("Allocation history of config " << config_i.name);
    LOG4(alloc_history.str());
    Logging::FileLog::close(logfile);

    if (cluster_groups.empty()) {
        // PHV Allocation succeed, no need to do any more steps
        rst.commit(try_alloc);
    } else {
        // PHV Allocation was not able to insert one or more superclusters. Try to move
        // transactions such that some of the actually unassigned supercluster would be able to
        // fit.
        opt_strategy.printContDependency();
        std::list<PHV::SuperCluster*> alloc_by_opt;
        alloc_by_opt = opt_strategy.optimize(cluster_groups, rst);
        for (auto cluster_group : alloc_by_opt)
            allocated.push_back(cluster_group);
    }

    return allocated;
}

std::vector<const PHV::Field*>
FieldPackingOpportunity::fieldsInOrder(
        const std::list<PHV::SuperCluster*>& sorted_clusters) const {
    std::set<const PHV::Field*> showed;
    std::vector<const PHV::Field*> rst;
    for (const auto* cluster : sorted_clusters) {
        cluster->forall_fieldslices([&] (const PHV::FieldSlice& fs) {
            if (!showed.count(fs.field())) {
                showed.insert(fs.field());
                rst.push_back(fs.field()); }
        });
    }
    return rst;
}

bool FieldPackingOpportunity::isExtractedOrUninitialized(const PHV::Field* f) const {
    return uses.is_extracted(f) || defuse.hasUninitializedRead(f->id);
}

bool FieldPackingOpportunity::canPack(const PHV::Field* f1, const PHV::Field* f2) const {
    // Being mutex is considered as no pack.
    if (mutex(f1->id, f2->id))
        return false;
    // Same stage packing conflits.
    if (actions.hasPackConflict(f1, f2))
        return false;
    // Extracted Uninitilized packing conflits
    if (isExtractedOrUninitialized(f1) && isExtractedOrUninitialized(f2))
        return false;
    return true;
}

FieldPackingOpportunity::FieldPackingOpportunity(
        const std::list<PHV::SuperCluster*>& sorted_clusters,
        const ActionPhvConstraints& actions,
        const PhvUse& uses,
        const FieldDefUse& defuse,
        const SymBitMatrix& mutex)
    : actions(actions), uses(uses), defuse(defuse), mutex(mutex) {
    std::vector<const PHV::Field*> fields = fieldsInOrder(sorted_clusters);
    for (auto i = fields.begin(); i != fields.end(); ++i) {
        opportunities[*i] = 0;
        for (auto j = i + 1; j != fields.end(); ++j) {
            if (canPack(*i, *j)) {
                opportunities[*i]++;
            }
        }
    }

    for (auto i = fields.begin(); i != fields.end(); ++i) {
        int sum = 0;
        for (auto j = i + 1; j != fields.end(); ++j) {
            if (canPack(*i, *j))
                sum++;
            opportunities_after[{*i, *j}] = opportunities[*i] - sum;
        }
    }
}

int FieldPackingOpportunity::nOpportunitiesAfter(
        const PHV::Field* f1, const PHV::Field* f2) const {
    if (opportunities_after.count({f1, f2})) {
        return opportunities_after.at({f1, f2});
    } else {
        LOG4("FieldPackingOpportunity for " << f1->name << " " << f2->name
             << " has not benn calculated.");
        return 0;
    }
}

const IR::Node* IncrementalPHVAllocation::apply_visitor(const IR::Node* root, const char *) {
    PHV::ConcreteAllocation alloc = make_concrete_allocation(phv_i, uses_i);
    auto container_groups = AllocatePHV::makeDeviceContainerGroups();
    std::list<PHV::SuperCluster*> cluster_groups;
    const int pipeId = root->id;
    for (const auto& f : temp_vars_i) {
        cluster_groups.push_back(new PHV::SuperCluster(
            {new PHV::RotationalCluster({new PHV::AlignedCluster(
                PHV::Kind::normal, std::vector<PHV::FieldSlice>{PHV::FieldSlice(f)})})},
            {}));
    }
    BruteForceStrategyConfig config {
        /*.name:*/                   "default_incremental_alloc",
        /*.is_better:*/              default_alloc_score_is_better,
        /*.max_failure_retry:*/      0,
        /*.max_slicing:*/            1,
        /*.max_sl_alignment_try:*/   1,
        /*.tofino_only:*/            boost::none,
        /*.pre_slicing_validation:*/ false,
        /*.enable_ara_in_overlays:*/ false,
    };
    AllocResult result(
        AllocResultCode::UNKNOWN, alloc.makeTransaction(), {});

    BruteForceAllocationStrategy* strategy = new BruteForceAllocationStrategy(
            alloc, config.name, core_alloc_i, parser_critical_path_i,
            critical_path_clusters_i, clot_i, strided_headers_i, uses_i, clustering_i, config,
            pipeId);
    result = strategy->tryAllocation(alloc, cluster_groups, container_groups);
    alloc.commit(result.transaction);
    if (result.status == AllocResultCode::FAIL) {
        LOG1("cannot allocate all temp vars");
    } else {
        AllocatePHV::clearSlices(phv_i);
        AllocatePHV::bindSlices(alloc, phv_i);
    }

    auto logfile = createFileLog(pipeId, "phv_allocation_incremental_summary_", 1);
    if (result.status == AllocResultCode::SUCCESS) {
        LOG1("PHV ALLOCATION SUCCESSFUL");
        LOG2(alloc);
    } else {
        ::error("failed to allocate temp vars created by table placement");
        for (const auto* sc : result.remaining_clusters) {
            sc->forall_fieldslices([](const PHV::FieldSlice& fs) {
                ::error("unallocated: %1%", cstring::to_cstring(fs));
            });
        }
    }
    Logging::FileLog::close(logfile);

    return root;
}
