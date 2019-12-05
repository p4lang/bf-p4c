#include <boost/format.hpp>
#include <boost/optional/optional_io.hpp>
#include <boost/range/adaptor/reversed.hpp>
#include <numeric>
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/device.h"
#include "bf-p4c/phv/allocate_phv.h"
#include "bf-p4c/phv/utils/slicing_iterator.h"
#include "bf-p4c/phv/utils/report.h"
#include "bf-p4c/phv/parser_extract_balance_score.h"
#include "lib/log.h"

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

/* AllocScore state variables. */
FieldPackingOpportunity* AllocScore::g_packing_opportunities = nullptr;

/** Metrics are prioritized by
 * 1. is_tphv.
 * 2. n_wasted_bits, to avoid solitary slice allocated to large containers.
 * 3. n_packing_bits
 * 4. n_overlay_bits
 * 5. use new container.
 * 6. set gress.
 */
bool AllocScore::operator>(const AllocScore& other) const {
    // Less TPHV over PHV. Less dark over PHV. Less mocha over dark. Less dark over mocha.
    // This is not redundent even if we have weight_factor for TPHV/PHV score,
    // because we want to avoid the case that placing TPHV candidates to PHV containers
    // so that the score is higher, because scores are calculated based on
    // container type, not field type.
    int delta_tphv_on_phv_bits = n_tphv_on_phv_bits - other.n_tphv_on_phv_bits;
    int delta_dark_on_phv_bits = n_dark_on_phv_bits - other.n_dark_on_phv_bits;
    int delta_mocha_on_phv_bits = n_mocha_on_phv_bits - other.n_mocha_on_phv_bits;
    int delta_dark_on_mocha_bits = n_dark_on_mocha_bits - other.n_dark_on_mocha_bits;

    int delta_parser_extractor_balance = parser_extractor_balance - other.parser_extractor_balance;
    int delta_inc_tphv_collections = n_inc_tphv_collections - other.n_inc_tphv_collections;
    int delta_pov_bits_wasted = n_pov_bits_wasted - other.n_pov_bits_wasted;

    int container_type_score = delta_tphv_on_phv_bits + DARK_TO_PHV_DISTANCE *
        delta_dark_on_phv_bits + delta_mocha_on_phv_bits + delta_dark_on_mocha_bits;

    int weight_factor = 2;
    int delta_clot_bits = 0;
    int delta_wasted_bits = 0;
    int delta_packing_bits = 0;
    int delta_packing_priority = 0;
    int delta_overlay_bits = 0;
    int delta_inc_containers = 0;
    int delta_set_gress = 0;
    int delta_set_parser_group_gress = 0;
    int delta_set_deparser_group_gress = 0;

    // The number of deparser group containers assigned to a gress different
    // than their deparser group (because they only container non-deparsed
    // fields).  More is better.
    int delta_mismatched_gress = 0;

    for (auto kind : Device::phvSpec().containerKinds()) {
        // Exclude dark PHVs from score because we want to use them as a spill space.
        if (kind == PHV::Kind::dark) continue;

        int penalty = (kind == PHV::Kind::normal || kind == PHV::Kind::mocha) ? weight_factor : 1;
        int bonus = kind == PHV::Kind::tagalong ? weight_factor : 1;

        // Add this score.
        if (score.find(kind) != score.end()) {
            delta_clot_bits += penalty * score.at(kind).n_clot_bits;
            delta_wasted_bits += penalty * score.at(kind).n_wasted_bits;
            delta_packing_bits += bonus * score.at(kind).n_packing_bits;
            delta_packing_priority += penalty * score.at(kind).n_packing_priority;
            delta_overlay_bits += bonus * score.at(kind).n_overlay_bits;
            delta_inc_containers += penalty * score.at(kind).n_inc_containers;
            delta_set_gress += penalty * score.at(kind).n_set_gress;
            delta_set_parser_group_gress += penalty * score.at(kind).n_set_parser_group_gress;
            delta_set_deparser_group_gress += penalty * score.at(kind).n_set_deparser_group_gress;
            delta_mismatched_gress += bonus * score.at(kind).n_mismatched_deparser_gress; }

        // Subtract other score.
        if (other.score.find(kind) != other.score.end()) {
            delta_clot_bits -= penalty * other.score.at(kind).n_clot_bits;
            delta_wasted_bits -= penalty * other.score.at(kind).n_wasted_bits;
            delta_packing_bits -= bonus * other.score.at(kind).n_packing_bits;
            delta_packing_priority -= penalty * other.score.at(kind).n_packing_priority;
            delta_overlay_bits -= bonus * other.score.at(kind).n_overlay_bits;
            delta_inc_containers -= penalty * other.score.at(kind).n_inc_containers;
            delta_set_gress -= penalty * other.score.at(kind).n_set_gress;
            delta_set_parser_group_gress -=
                penalty * other.score.at(kind).n_set_parser_group_gress;
            delta_set_deparser_group_gress -=
                penalty * other.score.at(kind).n_set_deparser_group_gress;
            delta_mismatched_gress -= bonus * other.score.at(kind).n_mismatched_deparser_gress; }
    }

    // An AllocScore has several metrics, some are positive while some are negative.
    // The delta is `other - mine`, so that:
    //   if delta == 0, then the metic is the same.
    //   if delta >  0, then the metic is higher than other's.
    //   if delta <  0, then the metric is lower than other's.
    // For positive metrics (overlay_bits, packing_bits...), higher is better.
    // For negative metrics (wasted_bits, inc_container...), lower is better.
    // Operator> return true if this score is better.

    if (delta_parser_extractor_balance != 0) {
        return delta_parser_extractor_balance > 0; }

    if (delta_clot_bits != 0) {
        // This score is better if it has fewer clot bits.
        return delta_clot_bits < 0; }
    if (Device::currentDevice() == Device::JBAY)
        if (delta_overlay_bits != 0)
            return delta_overlay_bits > 0;
    if (container_type_score != 0) {
        if (Device::currentDevice() == Device::TOFINO)
            return container_type_score < 0;
        else if (delta_inc_containers == 0)
            return container_type_score < 0;
    }
    if (Device::currentDevice() == Device::JBAY)
        if (delta_pov_bits_wasted != 0)
            return delta_pov_bits_wasted < 0;
    if (delta_inc_tphv_collections != 0) {
        return delta_inc_tphv_collections < 0; }
    // Opt for the AllocScore, which minimizes the number of bitmasked-set instructions. This helps
    // with action data packing and gives table placement a better shot at fitting within the number
    // of stages available on the device.
    if (n_num_bitmasked_set != other.n_num_bitmasked_set)
        return n_num_bitmasked_set < other.n_num_bitmasked_set;
    if (delta_inc_containers != 0) {
        // This score requires more new containers.
        return delta_inc_containers < 0; }
    if (Device::currentDevice() == Device::TOFINO)
        if (delta_overlay_bits != 0) {
            // This score has more overlay bits.
            return delta_overlay_bits > 0; }
    if (delta_wasted_bits != 0) {
        // This score has fewer wasted bits.
        return delta_wasted_bits < 0; }
    if (delta_packing_bits != 0) {
        // This score has more packing bits.
        return delta_packing_bits > 0; }
    if (delta_packing_priority != 0) {
        // This score is better if it make a more prioritized packing.
        return delta_packing_priority < 0; }
    if (delta_set_gress != 0) {
        // This score pins fewer containers to a new gress.
        return delta_set_gress < 0; }
    if (delta_set_deparser_group_gress != 0) {
        // This score pins less containers to a new deparser group gress.
        return delta_set_deparser_group_gress < 0; }
    if (delta_set_parser_group_gress != 0) {
        // This score pins fewer containers to a new parser group gress.
        return delta_set_parser_group_gress < 0; }
    if (delta_mismatched_gress != 0) {
        // This score allocates more non-deparsed fields to deparser groups of
        // a different gress.
        return delta_mismatched_gress > 0; }

    return false;
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
        const int bitmasks) {
    using ContainerAllocStatus = PHV::Allocation::ContainerAllocStatus;
    const auto* parent = alloc.getParent();

    n_num_bitmasked_set = bitmasks;

    // Forall allocated slices group by container.
    for (const auto kv : alloc.getTransactionStatus()) {
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
            n_pov_bits_wasted += (container.size() - n_pov_bits);

        // calc n_wasted_bits and n_clot_bits
        for (const auto& slice : slices) {
            if (slice.field()->is_solitary())
                score[kind].n_wasted_bits += (container.size() - slice.width());
            if (clot.fully_allocated(slice.field()))
                score[kind].n_clot_bits += slice.width(); }

        if (kind == PHV::Kind::normal) {
            for (const auto& slice : slices) {
                PHV::FieldSlice fieldSlice(slice.field(), slice.field_slice());
                if (fieldSlice.is_tphv_candidate(uses))
                    n_tphv_on_phv_bits += (slice.width());
                else if (slice.field()->is_mocha_candidate())
                    n_mocha_on_phv_bits += (slice.width());
                else if (slice.field()->is_dark_candidate())
                    n_dark_on_phv_bits += (slice.width()); } }

        if (kind == PHV::Kind::mocha)
            for (const auto& slice : slices)
                if (slice.field()->is_dark_candidate())
                    n_dark_on_mocha_bits += (slice.width());

        // calc_n_inc_containers
        auto merged_status = alloc.alloc_status(container);
        auto parent_status = parent->alloc_status(container);
        if (parent_status == ContainerAllocStatus::EMPTY
            && merged_status != ContainerAllocStatus::EMPTY) {
            score[kind].n_inc_containers++; }

        if (parent_status == ContainerAllocStatus::PARTIAL) {
            // calc n_packing_bits
            for (auto i = container.lsb(); i <= container.msb(); ++i) {
                if (parent_alloc_vec[i]) continue;
                for (const auto& slice : slices) {
                    if (slice.container_slice().contains(i)) {
                        score[kind].n_packing_bits++;
                        break; }
                }
            }

            // calc n_packing_priority.
            if (score[kind].n_packing_bits) {
                BUG_CHECK(g_packing_opportunities, "packing opportunities not set?");
                int n_packing_priority = 100000;  // do not use max because it might overflow.
                for (auto i = container.lsb(); i <= container.msb(); ++i) {
                    for (const auto& p_slice : parent->slices(container)) {
                        for (const auto& slice : slices) {
                            if (p_slice.container_slice().contains(i)
                                && slice.container_slice().contains(i)) {
                                auto* f1 = p_slice.field();
                                auto* f2 = slice.field();
                                n_packing_priority = std::min(
                                        n_packing_priority,
                                        g_packing_opportunities->nOpportunitiesAfter(f1, f2));
                            }
                        }
                    }
                }
                score[kind].n_packing_priority = n_packing_priority;
            }
        }

        // calc n_overlay_bits
        for (const int i : parent_alloc_vec) {
            for (const auto slice : slices) {
                if (slice.container_slice().contains(i)) {
                    score[kind].n_overlay_bits++; } } }
        // If overlay is between multiple fields in the same transaction, then that value needs to
        // be calculated separately.
        int overlay_bits = 0;
        for (const auto slice1 : slices) {
            for (const auto slice2 : slices) {
                if (slice1 == slice2) continue;
                for (unsigned int i = 0; i < container.size(); i++) {
                    if (slice1.container_slice().contains(i) &&
                            slice2.container_slice().contains(i))
                        overlay_bits++; } } }
        // Slices are counted twice in the above loop, so divide by 2.
        score[kind].n_overlay_bits += (overlay_bits / 2);

        // gress
        if (!parent->gress(container) && gress) {
            score[kind].n_set_gress++;
            if (gress != deparserGroupGress)
                score[kind].n_mismatched_deparser_gress++; }

        // Parser group gress
        if (!parent->parserGroupGress(container) && parserGroupGress) {
            score[kind].n_set_parser_group_gress++; }

        // Deparser group gress
        if (!parent->deparserGroupGress(container) && deparserGroupGress) {
            score[kind].n_set_deparser_group_gress++; }
    }

    // calc_n_inc_tphv_collections
    if (Device::currentDevice() == Device::TOFINO) {
        auto my_tphv_collections = alloc.getTagalongCollectionsUsed();
        auto parent_tphv_collections = parent->getTagalongCollectionsUsed();
        for (auto col : my_tphv_collections) {
            if (!parent_tphv_collections.count(col))
                n_inc_tphv_collections++;
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
        parser_extractor_balance += ParserExtractScore::get_score(use);
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

    if (score.n_inc_tphv_collections != 0)
        s << "inc_tphv_collections: " << score.n_inc_tphv_collections << ", ";
    if (score.parser_extractor_balance != 0)
        s << "extract balance: " << score.parser_extractor_balance << ", ";
    if (Device::currentDevice() == Device::JBAY && score.n_pov_bits_wasted != 0)
        s << "pov-wastage: " << score.n_pov_bits_wasted << ", ";
    if (score.n_num_bitmasked_set != 0)
        s << "bitmasked-set: " << score.n_num_bitmasked_set;

    for (auto kind : Device::phvSpec().containerKinds()) {
        if (score.score.find(kind) == score.score.end())
            continue;
        any_positive_score = true;
        s << kind << " [";
        if (Device::currentDevice() == Device::TOFINO)
            s << "tphv: " << (kind == PHV::Kind::tagalong) << ", ";
        else if (Device::currentDevice() == Device::JBAY)
            s << "clot_bits: " << score.score.at(kind).n_clot_bits << ", ";
        s << "wasted_bits: " << score.score.at(kind).n_wasted_bits << ", ";
        s << "overlay_bits: " << score.score.at(kind).n_overlay_bits << ", ";
        s << "packing_bits: " << score.score.at(kind).n_packing_bits << ", ";
        s << "packing_prio: " << score.score.at(kind).n_packing_priority << ", ";
        s << "inc_containers: " << score.score.at(kind).n_inc_containers << ", ";
        s << "set_gress: " << score.score.at(kind).n_set_gress << ", ";
        s << "]"; }

    if (!any_positive_score)
        s << "[ score: 0 ]";

    return s;
}

/* static */
bool CoreAllocation::can_overlay(
        const SymBitMatrix& mutex,
        const PHV::Field* f,
        const ordered_set<PHV::AllocSlice>& slices) {
    for (auto slice : slices)
        if (!PHV::Allocation::mutually_exclusive(mutex, f, slice.field()))
            return false;
    return true;
}

boost::optional<bitvec> CoreAllocation::satisfies_constraints(
        const PHV::ContainerGroup& group, const PHV::AlignedCluster& cluster) const {
    // Check that these containers support the operations required by fields in
    // this cluster.
    bool isOkIn = false;
    for (auto t : group.types()) {
        if (cluster.okIn(t.kind()))
            isOkIn = true; }
    if (!isOkIn) {
        LOG5("    ...but cluster cannot be placed in " << group.width() << " containers");
        return boost::none; }

    // Check that a valid start alignment exists for containers of this size.
    // An empty bitvec indicates no valid starting positions.
    return cluster.validContainerStart(group.width());
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
    auto req = pragmas_i.pa_container_sizes().field_slice_req(slice);
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

    // Check gress.
    auto containerGress = alloc.gress(c);
    if (containerGress && *containerGress != f->gress) {
        LOG5("        constraint: container " << c << " is " << *containerGress <<
                    " but slice needs " << f->gress);
        return false; }

    // Check parser group gress.
    auto parserGroupGress = alloc.parserGroupGress(c);
    bool isExtracted = uses_i.is_extracted(f);
    if (isExtracted && parserGroupGress && *parserGroupGress != f->gress) {
        LOG5("        constraint: container " << c << " has parser group gress " <<
             *parserGroupGress << " but slice needs " << f->gress);
        return false; }

    // Check deparser group gress.
    auto deparserGroupGress = alloc.deparserGroupGress(c);
    bool isDeparsed = uses_i.is_deparsed(f);
    if (isDeparsed && deparserGroupGress && *deparserGroupGress != f->gress) {
        LOG5("        constraint: container " << c << " has deparser group gress " <<
             *deparserGroupGress << " but slice needs " << f->gress);
        return false; }

    // Check no pack for this field.
    const auto& slices = alloc.slicesByLiveness(c, slice);
    std::vector<PHV::FieldSlice> liveFieldSlices;
    ordered_set<PHV::FieldSlice> initFieldSlices;
    for (auto& sl : slices)
        liveFieldSlices.push_back(PHV::FieldSlice(sl.field(), sl.field_slice()));
    for (auto& initSlice : initFields)
        initFieldSlices.insert(PHV::FieldSlice(initSlice.field(), initSlice.field_slice()));
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
    bool hasUninitializedRead = std::any_of(
            liveFieldSlices.begin(), liveFieldSlices.end(), [&] (const PHV::FieldSlice& s) {
        return s.field()->pov
            || (defuse_i.hasUninitializedRead(s.field()->id) && !initFieldSlices.count(s));
    });

    bool hasExtracted = std::any_of(liveFieldSlices.begin(), liveFieldSlices.end(), [&] (const
                PHV::FieldSlice& s) {
        return !s.field()->pov && uses_i.is_extracted(s.field());
    });

    bool isThisSliceExtracted = !slice.field()->pov && uses_i.is_extracted(slice.field());
    bool isThisSliceUninitialized = (slice.field()->pov
            || (defuse_i.hasUninitializedRead(slice.field()->id) && !initFields.count(slice) &&
                !pragmas_i.pa_no_init().getFields().count(slice.field())));

    bool hasExtractedTogether = std::all_of(
            liveFieldSlices.begin(), liveFieldSlices.end(), [&] (const PHV::FieldSlice& s) {
        return phv_i.are_bridged_extracted_together(slice.field(), s.field());
    });

    if (hasExtracted && !hasExtractedTogether &&
        (isThisSliceUninitialized || isThisSliceExtracted)) {
        LOG5("        constraint: container already contains extracted slices, "
             "can not be packed, because: this slice is "
             << (isThisSliceExtracted ? "extracted" : "uninitialized"));
        return false; }

    // Account for metadata initialization and ensure that initialized fields are not considered
    // uninitialized any more.
    if (isThisSliceExtracted && (hasUninitializedRead || hasExtracted)) {
        if (!hasExtractedTogether || !hasUninitializedRead) {
            LOG5("        constraint: this slice is extracted, "
                    "can not be packed, because allocated fields has "
                    << (hasExtracted ? "extracted" : "uninitialized"));
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

    return true;
}

boost::optional<PHV::Transaction>
CoreAllocation::tryAllocSliceList(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const PHV::SuperCluster& super_cluster,
        const ordered_map<PHV::FieldSlice, int>& start_positions) const {
    PHV::Allocation::ConditionalConstraint start_pos;
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
        const PHV::Allocation::ConditionalConstraint& start_positions) const {
    PHV::SuperCluster::SliceList slices;
    for (auto& kv : start_positions)
        slices.push_back(kv.first);

    PHV::Transaction alloc_attempt = alloc.makeTransaction();
    int container_size = int(group.width());

    // Set previous_container to the container returned as part of start_positions
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
    for (const PHV::Container c : group) {
        int num_bitmasks = 0;
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
                LOG5("    ...and can overlay " << slice.field() << " on " << alloced_slices);
                new_candidate_slices.push_back(slice);
            } else if (alloced_slices.size() > 0) {
                // If there are slices already allocated for these container bits, then check if
                // overlay is enabled by live shrinking is possible. If yes, then note down
                // information about the initialization required and allocated slices for later
                // constraint verification.
                bool is_mocha_or_dark = c.is(PHV::Kind::dark) || c.is(PHV::Kind::mocha);
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

                    LOG5("    ...and can overlay " << slice.field() << " on " << alloced_slices <<
                         " with metadata initialization.");
                    PHV::Allocation::MutuallyLiveSlices container_state =
                        perContainerAlloc.slicesByLiveness(c, candidate_slices);
                    // Actual slices in the container, after accounting for metadata overlay.
                    PHV::Allocation::MutuallyLiveSlices actual_container_state;
                    for (auto& field_slice : container_state) {
                        bool sliceOverlaysAllCandidates = true;
                        for (auto& candidate_slice : candidate_slices) {
                            if (!PHV::Allocation::mutually_exclusive(phv_i.metadata_mutex(),
                                        field_slice.field(), candidate_slice.field()))
                                sliceOverlaysAllCandidates = false;
                        }
                        if (sliceOverlaysAllCandidates) continue;
                        actual_container_state.insert(field_slice);
                    }

                    initNodes = meta_init_i.findInitializationNodes(alloced_slices, slice,
                            perContainerAlloc, actual_container_state);
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
                            if (kv.first == slice.field()) {
                                LOG5("\t\tA. Inserting " << slice << " into metaInitSlices");
                                metaInitSlices.insert(slice);
                                continue; }
                            for (const auto& sl : alloced_slices) {
                                if (kv.first == sl.field()) {
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
                    PHV::Allocation::MutuallyLiveSlices container_state =
                        perContainerAlloc.slicesByLiveness(c, candidate_slices);
                    auto darkInitNodes = dark_init_i.findInitializationNodes(group, alloced_slices,
                            slice, perContainerAlloc);
                    if (!darkInitNodes) {
                        LOG5("       ...but cannot find initialization points for dark "
                             "containers.");
                        can_place = false;
                        break;
                    } else {
                        can_place = true;
                        LOG5("    ...found " << darkInitNodes->size() <<
                             " initialization points for dark containers.");
                        unsigned primNum = 0;
                        for (auto& prim : *darkInitNodes) {
                            LOG5("\t\t" << prim);
                            if (primNum++ == 0) continue;
                            metaInitSlices.insert(prim.getDestinationSlice());
                        }
                        // Create initialization points for the dark container.
                        generateNewAllocSlices(slice, alloced_slices, *darkInitNodes,
                                new_candidate_slices, perContainerAlloc);
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

        if (new_candidate_slices.size() > 0) {
            candidate_slices.clear();
            for (auto& sl : new_candidate_slices)
                candidate_slices.push_back(sl);
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
        if (initNodes)
            for (auto kv : *initNodes)
                initActions[kv.first].insert(kv.second.begin(), kv.second.end());
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
                if (!PHV::Allocation::mutually_exclusive(phv_i.metadata_mutex(),
                            field_slice.field(), candidate_slice.field()))
                    sliceLiveRangeDisjointWithAllCandidates = false;
            }
            // If the current slice overlays with at least one candidate slice AND its live range
            // does not overlap with the candidate slices, we do not consider the existing slice to
            // be part of the live container state.
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

        action_constraints = actions_i.can_pack(perContainerAlloc, candidate_slices,
                actual_container_state, initActions, super_cluster);
        bool creates_new_container_conflicts =
            actions_i.creates_container_conflicts(actual_container_state, initActions,
                    meta_init_i.getTableActionsMap());
        // If metadata initialization causes container conflicts to be created, then do not use this
        // allocation.
        if (action_constraints && initActions.size() > 0 && creates_new_container_conflicts) {
            LOG5("\t\t...action constraint: creates new container conflicts for this packing."
                 " cannot pack into container " << c);

            continue;
        }

        if (!action_constraints) {
            LOG5("        ...action constraint: cannot pack into container " << c);
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

                    // Disregard slices that aren't in slice lists.
                    if (!slice_list && slice_lists.size() == 0) continue;
                    if (slice_list && slice_lists.size() == 0) {
                        LOG5("    ...but slice " << slice_and_pos.first << " is not in a "
                             "slice list, while other slices in the same conditional constraint "
                             "is in a slice list.");
                        can_place = false;
                        break;
                    }

                    // If a slice is in multiple slice lists, abort.
                    // XXX(cole): This is overly constrained.
                    if (slice_lists.size() > 1) {
                        LOG5("    ...but a conditional placement is in multiple slice lists");
                        can_place = false;
                        break;
                    }

                    // If another slice in these action constraints is in a
                    // different slice list, abort.
                    // XXX(cole): This is also overly constrained.
                    if (slice_list && *slice_list != *slice_lists.begin()) {
                        LOG5("    ...but two conditional placements are in two different slice "
                             "lists");
                        can_place = false;
                        break;
                    }

                    slice_list = *slice_lists.begin(); }
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
                    boost::optional<PHV::Container> requiredContainer;
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
                            offset += slice.range().size(); } }

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
                (*action_constraints).erase(i); } }

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
                    this_alloc.allocate(slice, initNodes);
                    LOG5("\t\tFound initialization point for metadata field " <<
                            slice.field()->name);
                } else {
                    this_alloc.allocate(slice); }
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
                    tryAllocSliceList(this_alloc, group, super_cluster, kv.second);
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
            for (const auto next_container : group) {
                if ((c.index() + 1) == next_container.index()) {
                    LOG5("Checking adjacent container " << next_container);
                    const std::vector<PHV::Container> one_container = {next_container};
                    // so confusing, parameter size here means bit width,
                    // but group.size() returns the number of containers.
                    auto small_grp = PHV::ContainerGroup(group.width(), one_container);

                    ordered_map<PHV::FieldSlice, int> hi_slice_alignment;
                    ordered_map<const PHV::AlignedCluster*, int> hi_cluster_alignment;
                    ordered_set<cstring> tmpBridgedConflicts;
                    bool buildHiSetup = buildAlignmentMaps(small_grp,
                                                           super_cluster,
                                                           hi_slice,
                                                           hi_slice_alignment,
                                                           hi_cluster_alignment,
                                                           tmpBridgedConflicts);
                    if (!buildHiSetup) {
                        LOG6("Couldn't build hi setup?");
                        can_alloc_hi = false;
                        break; }

                    auto try_hi = tryAllocSliceList(this_alloc, small_grp,
                                                    super_cluster, hi_slice_alignment);
                    if (try_hi != boost::none) {
                        LOG5("Wide arith hi slice could be allocated in " << next_container);
                        LOG5("" << hi_slice);
                        can_alloc_hi = true; }
                    break; } }
            if (!can_alloc_hi) {
              LOG5("Wide arithmetic hi slice could not be allocated.");
              continue;
            } else {
              LOG5("Wide arithmetic hi slice could be allocated."); }
        }
        perContainerAlloc.commit(this_alloc);

        // auto score = AllocScore(this_alloc, phv_i, clot_i, uses_i,
        auto score = AllocScore(perContainerAlloc, phv_i, clot_i, uses_i,
                                field_to_parser_states_i, parser_critical_path_i,
                                num_bitmasks);
        LOG5("    ...SLICE LIST score for container " << c << ": " << score);

        // update the best
        if ((!best_candidate || score > best_score)) {
            LOG5("       ...Best score for container " << c);
            best_score = score;
            // best_candidate = std::move(this_alloc); }
            best_candidate = std::move(perContainerAlloc); }
    }  // end of for containers

    if (!best_candidate) {
        LOG5("    ...hence there is no suitable candidate");
        return boost::none; }

    alloc_attempt.commit(*best_candidate);
    return alloc_attempt;
}

void CoreAllocation::generateNewAllocSlices(
        const PHV::AllocSlice& origSlice,
        const ordered_set<PHV::AllocSlice>& alloced_slices,
        PHV::DarkInitMap& slices,
        std::vector<PHV::AllocSlice>& new_candidate_slices,
        PHV::Transaction& alloc_attempt) const {
    std::vector<PHV::AllocSlice> initializedAllocSlices;
    for (auto& entry : slices) {
        auto dest = entry.getDestinationSlice();
        LOG5("\t\t\tAdding dest: " << dest);
        dest.setInitPrimitive(&(entry.getInitPrimitive()));
        initializedAllocSlices.push_back(dest);
    }
    std::vector<PHV::AllocSlice> rv;
    LOG5("\t\t\tOriginal candidate slice: " << origSlice);
    bool foundAnyNewSliceForThisOrigSlice = false;
    for (auto& newSlice : initializedAllocSlices) {
        if (!origSlice.representsSameFieldSlice(newSlice)) continue;
        LOG5("\t\t\t  Found new slice: " << newSlice);
        foundAnyNewSliceForThisOrigSlice = true;
        rv.push_back(newSlice);
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
            foundAnyNewSliceForThisAllocatedSlice = true;
            toBeRemovedFromAlloc.insert(alreadyAllocatedSlice);
            toBeAddedToAlloc.insert(newSlice);
        }
        if (!foundAnyNewSliceForThisAllocatedSlice)
            LOG5("\t\t\t  Did not found any new slice. So stick with the existing one.");
    }
    alloc_attempt.removeAllocatedSlice(toBeRemovedFromAlloc);
    for (auto& slice : toBeAddedToAlloc) {
        alloc_attempt.allocate(slice, boost::none);
        LOG5("\t\t\t  Allocating slice " << slice);
    }
    PHV::Container c = origSlice.container();
    LOG5("\t\t\tState of allocation object now:");
    for (auto& slice : alloc_attempt.slices(c)) LOG5("\t\t\t  Slice: " << slice);
}

static bool isClotSuperCluster(const ClotInfo& clots, const PHV::SuperCluster& sc) {
    // In JBay, a clot-candidate field may sometimes be allocated to a PHV
    // container, eg. if it is adjacent to a field that must be packed into a
    // larger container, in which case the clot candidate would be used as
    // padding.

    // XXX(cole): It's possible that part of a clot-candidate will be allocated
    // to PHV and part to the clot, eg. a 12b field where 4b are in PHV and 8b
    // are drawn from the clot.  This is permissible in theory, but the rest of
    // the compiler doesn't yet support fields partially allocated to the PHV.

    // Clot candidates, by definition, aren't involved in MAU operations
    // and so will only have one slice list.
    if (sc.slice_lists().size() == 1) {
        auto* slices = *sc.slice_lists().begin();
        bool allClotCandidates = std::all_of(slices->begin(), slices->end(),
            [&](const PHV::FieldSlice& slice) { return clots.fully_allocated(slice.field()); });
        if (allClotCandidates)
            return true; }
    return false;
}

bool CoreAllocation::buildAlignmentMaps(
  const PHV::ContainerGroup& container_group,
  const PHV::SuperCluster& super_cluster,
  const PHV::SuperCluster::SliceList* slice_list,
  ordered_map<PHV::FieldSlice, int>& slice_alignment,
  ordered_map<const PHV::AlignedCluster*, int>& cluster_alignment,
  ordered_set<cstring>& bridgedFieldsWithAlignmentConflicts) const {
    int le_offset = 0;
    for (auto& slice : *slice_list) {
        const PHV::AlignedCluster& cluster = super_cluster.aligned_cluster(slice);
        auto valid_start_options = satisfies_constraints(container_group, cluster);
        if (valid_start_options == boost::none)
            return false;

        if (valid_start_options->empty()) {
            LOG5("    ...but there are no valid starting positions for " << slice);
            return false; }

        // If this is the first slice, then its starting alignment can be adjusted.
        if (le_offset == 0)
            le_offset = *valid_start_options->begin();

        // Return if the slice 's cluster cannot be placed at the current
        // starting offset.
        if (!valid_start_options->getbit(le_offset)) {
            LOG5("    ...but slice list requires slice to start at " << le_offset <<
                 " which its cluster cannot support: " << slice);
            // The condition to check if fieldsWithAlignmentConflicts has this
            // field already is essential for convergence.
            if (slice.field()->bridged &&
                    !bridgedFieldsWithAlignmentConflicts.count(slice.field()->name)) {
                LOG5("   ...alignment constraint for bridged field slice " << slice <<
                     ". May backtrack if this slice is not allocated.");
                bridgedFieldsWithAlignmentConflicts.insert(slice.field()->name); }
            return false; }

        // Return if the slice is part of another slice list but was previously
        // placed at a different start location.
        // XXX(cole): We may need to be smarter about coordinating all
        // valid starting ranges for all slice lists.
        if (cluster_alignment.find(&cluster) != cluster_alignment.end() &&
                cluster_alignment.at(&cluster) != le_offset) {
            LOG5("    ...but two slice lists have conflicting alignment requirements for "
                 "field slice %1%" << slice);
            return false; }

        // Otherwise, update the alignment for this slice's cluster.
        cluster_alignment[&cluster] = le_offset;
        slice_alignment[slice] = le_offset;
        le_offset += slice.size(); }
    return true;
}

// SUPERCLUSTER <--> CONTAINER GROUP allocation.
boost::optional<PHV::Transaction> CoreAllocation::tryAlloc(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& container_group,
        PHV::SuperCluster& super_cluster,
        ordered_set<cstring>& bridgedFieldsWithAlignmentConflicts) const {
    // Make a new transaction.
    PHV::Transaction alloc_attempt = alloc.makeTransaction();

    if (isClotSuperCluster(clot_i, super_cluster)) {
        LOG5("Skipping CLOT-allocated super cluster: " << super_cluster);
        return alloc_attempt; }

    // Check container group/cluster group constraints.
    if (!satisfies_constraints(container_group, super_cluster))
        return boost::none;

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
        ordered_map<PHV::FieldSlice, int> slice_alignment;
        bool couldSetup = buildAlignmentMaps(container_group,
                                             super_cluster,
                                             slice_list,
                                             slice_alignment,
                                             cluster_alignment,
                                             bridgedFieldsWithAlignmentConflicts);
        if (!couldSetup)
            return boost::none;

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
                auto score = AllocScore(this_alloc, phv_i, clot_i, uses_i,
                                        field_to_parser_states_i,
                                        parser_critical_path_i);
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
    // Translate AllocSlice to alloc_slice, and attach alloc_slice to
    // PHV::Field.
    for (auto container_and_slices : alloc) {
        std::vector<PHV::AllocSlice> slices;
        for (PHV::AllocSlice slice : container_and_slices.second.slices)
            slices.push_back(slice);
        // Sort the slices vector according to live range of the constituent slices.
        std::sort(slices.begin(), slices.end(),
                [](const PHV::AllocSlice& a, const PHV::AllocSlice& b) {
            auto aMinStage = a.getEarliestLiveness();
            auto bMinStage = b.getEarliestLiveness();
            if (aMinStage.first != bMinStage.first) return aMinStage.first < bMinStage.first;
            if (aMinStage.second != bMinStage.second) return aMinStage.second < bMinStage.second;
            return a < b;
        });
        // TODO: Do we need to ensure that the live ranges of the constituent slices, put together,
        // completely cover the entire pipeline (plus parser and deparser).

        for (PHV::AllocSlice slice : container_and_slices.second.slices) {
            auto* f = slice.field();
            auto init_points = alloc.getInitPoints(slice);
            static ordered_set<const IR::MAU::Action*> emptySet;
            auto* allocated_slice = f->add_and_return_alloc(
                    slice.field(),
                    slice.container(),
                    slice.field_slice().lo,
                    slice.container_slice().lo,
                    slice.field_slice().size(),
                    init_points ? *init_points : emptySet);
            auto minLive = slice.getEarliestLiveness();
            auto maxLive = slice.getLatestLiveness();
            allocated_slice->min_stage = std::make_pair(minLive.first, minLive.second);
            allocated_slice->max_stage = std::make_pair(maxLive.first, maxLive.second);

            if (init_points) {
                allocated_slice->has_meta_init = true;
                LOG5("\tAdding " << init_points->size() << " initialization points for field "
                     "slice: " << slice.field()->name << " " << slice);
                for (const auto* a : *init_points)
                    LOG4("    Action: " << a->name); }
            phv.add_container_to_field_entry(slice.container(), f);
            const auto* initPrimitive = slice.getInitPrimitive();
            if (initPrimitive == nullptr) continue;
            if (initPrimitive->isEmpty()) continue;
            allocated_slice->init_i.empty = false;
            allocated_slice->init_i.nop = initPrimitive->isNOP();
            allocated_slice->init_i.assignZeroToDestination = initPrimitive->destAssignedToZero();
            allocated_slice->init_i.alwaysInitInLastMAUStage =
                initPrimitive->mustInitInLastMAUStage();
            LOG5("\tAllocating slice " << slice);
            LOG5("\t  Setting dark initialization information for " << slice);
            LOG5("\t    Primitive: " << *initPrimitive);
            if (initPrimitive->mustInitInLastMAUStage())
                LOG5("\t\t  Must initialize in the last stage always_run block");
            auto sourceSlice = initPrimitive->getSourceSlice();
            if (sourceSlice) {
                allocated_slice->init_i.source = new PHV::Field::alloc_slice(sourceSlice->field(),
                        sourceSlice->container(), sourceSlice->field_slice().lo,
                        sourceSlice->container_slice().lo, sourceSlice->width());
                auto earlyLiveness = sourceSlice->getEarliestLiveness();
                auto lateLiveness = sourceSlice->getLatestLiveness();
                allocated_slice->init_i.source->min_stage =
                    std::make_pair(earlyLiveness.first, earlyLiveness.second);
                allocated_slice->init_i.source->max_stage =
                    std::make_pair(lateLiveness.first, lateLiveness.second);
            }
            auto darkPrimActions = initPrimitive->getInitPoints();
            allocated_slice->init_i.init_actions.insert(darkPrimActions.begin(),
                    darkPrimActions.end());
            if (initPrimitive->mustInitInLastMAUStage() && sourceSlice)
                LOG5("\t\t  Source slice: " << *(allocated_slice->init_i.source));
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
        boost::optional<PHV::Field::alloc_slice> last = boost::none;
        safe_vector<PHV::Field::alloc_slice> merged_alloc;
        for (auto& slice : f.get_alloc()) {
            if (last == boost::none) {
                last = slice;
                continue; }
            if (last->container == slice.container
                    && last->field_bits().lo == slice.field_bits().hi + 1
                    && last->container_bits().lo == slice.container_bits().hi + 1
                    && last->min_stage == slice.min_stage
                    && last->max_stage == slice.max_stage
                    && last->init_i == slice.init_i) {
                int new_width = last->width + slice.width;
                ordered_set<const IR::MAU::Action*> new_init_points;
                if (last->init_points.size() > 0)
                    new_init_points.insert(last->init_points.begin(), last->init_points.end());
                if (slice.init_points.size() > 0)
                    new_init_points.insert(slice.init_points.begin(), slice.init_points.end());
                if (new_init_points.size() > 0)
                    LOG5("Merged slice contains " << new_init_points.size() << " initialization "
                         "points.");
                PHV::Field::alloc_slice new_slice(slice.field,
                                                  slice.container,
                                                  slice.field_bit,
                                                  slice.container_bit,
                                                  new_width, new_init_points);
                new_slice.has_meta_init = slice.has_meta_init | last->has_meta_init;
                new_slice.min_stage = slice.min_stage;
                new_slice.max_stage = slice.max_stage;
                new_slice.init_i = slice.init_i;
                BUG_CHECK(new_slice.field_bits().contains(last->field_bits()),
                          "Merged alloc slice %1% does not contain hi slice %2%",
                          cstring::to_cstring(new_slice), cstring::to_cstring(*last));
                BUG_CHECK(new_slice.field_bits().contains(slice.field_bits()),
                          "Merged alloc slice %1% does not contain lo slice %2%",
                          cstring::to_cstring(new_slice), cstring::to_cstring(slice));
                last = new_slice;
                LOG4("MERGING " << last->field << ": " << *last << " and " << slice <<
                     " into " << new_slice);
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

Visitor::profile_t AllocatePHV::init_apply(const IR::Node* root) {
    LOG1("--- BEGIN PHV ALLOCATION ----------------------------------------------------");
    log_device_stats();

    // Make sure that fields are not marked as mutex with itself.
    for (const auto& field : phv_i) {
        BUG_CHECK(!mutex_i(field.id, field.id),
                  "Field %1% can be overlaid with itself.", field.name); }

    LOG1(pragmas_i.pa_container_sizes());
    LOG1(pragmas_i.pa_atomic());
    auto alloc = make_concrete_allocation();
    auto container_groups = makeDeviceContainerGroups();
    std::list<PHV::SuperCluster*> cluster_groups = make_cluster_groups();
    std::stringstream report;

    // Remove super clusters that are entirely allocated to CLOTs.
    ordered_set<PHV::SuperCluster*> to_remove;
    for (auto* sc : cluster_groups)
        if (isClotSuperCluster(clot_i, *sc))
            to_remove.insert(sc);
    for (auto* sc : to_remove)
        cluster_groups.remove(sc);

    size_t numBridgedConflicts = bridgedFieldsWithAlignmentConflicts.size();
    AllocationStrategy *strategy =
        new BruteForceAllocationStrategy(core_alloc_i, report, parser_critical_path_i,
                                         critical_path_clusters_i, clot_i,
                                         bridgedFieldsWithAlignmentConflicts,
                                         strided_headers_i);
    auto result = strategy->tryAllocation(alloc, cluster_groups, container_groups);

    // Later we can try different strategies,
    // and commit result only when it reaches our expectation.
    alloc.commit(result.transaction);

    bool failure_diagnosed = (result.remaining_clusters.size() == 0) ? false :
        diagnoseFailures(result.remaining_clusters);

    // If only privatized fields are unallocated, mark allocation as done.
    // The rollback of unallocated privatized fields will happen in ValidateAllocation.
    if (result.status == AllocResultCode::SUCCESS) {
        clearSlices(phv_i);
        bindSlices(alloc, phv_i);
        phv_i.set_done();
        LOG1("PHV ALLOCATION SUCCESSFUL");
        LOG2(alloc);
    } else if (onlyPrivatizedFieldsUnallocated(result.remaining_clusters)) {
        LOG1("PHV ALLOCATION SUCCESSFUL FOR NON-PRIVATIZED FIELDS");
        clearSlices(phv_i);
        bindSlices(alloc, phv_i);
        phv_i.set_done();
        LOG1("SuperClusters with Privatized Fields unallocated: ");
        for (auto* sc : result.remaining_clusters)
            LOG1(sc);
        LOG2(alloc);
    } else {
        auto noPackBridgedFields = throwBacktrackException(numBridgedConflicts,
                result.remaining_clusters);
        if (noPackBridgedFields.size() > 0)
            throw BridgedPackingTrigger::failure(noPackBridgedFields);
        bool firstRoundFit = alloc_i.didFirstRoundFit();
        if (firstRoundFit) {
            // Empty table allocation to be sent because the first round of PHV allocation should be
            // redone.
            ordered_map<cstring, ordered_set<int>> tables;
            LOG1("This round of PHV Allocation did not fit. However, the first round of PHV "
                 "allocation did. Therefore, falling back onto the first round of PHV allocation.");
            throw PHVTrigger::failure(tables, firstRoundFit, true /* ignorePackConflicts */,
                                      false /* metaInitDisable */);
        }
        bindSlices(alloc, phv_i);
        if (result.status == AllocResultCode::FAIL_UNSAT) {
            formatAndThrowError(alloc, result.remaining_clusters);
            formatAndThrowUnsat(result.remaining_clusters);
        } else if (!failure_diagnosed) {
            formatAndThrowError(alloc, result.remaining_clusters);
        }
    }
    return Inspector::init_apply(root);
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
        if (sliceListExact && sliceListSize == 8) scCannotBeSplitFurther = true;
        if (sliceListExact) sliceListsOfInterest.insert(list);
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

ordered_set<cstring> AllocatePHV::throwBacktrackException(
        const size_t numBridgedConflicts,
        const std::list<PHV::SuperCluster*>& unallocated) const {
    ordered_set<cstring> noPackBridgedFields;
    // If numBridgedConflicts and the current size of bridgedFieldsWithAlignmentConflicts is the
    // same, then it means no field was added to this set during this round of PHV allocation.
    // Therefore, there are no changes required to bridged metadata packing.
    if (numBridgedConflicts == bridgedFieldsWithAlignmentConflicts.size())
        return noPackBridgedFields;
    for (auto* sc : unallocated) {
        sc->forall_fieldslices([&](const PHV::FieldSlice& s) {
            if (!s.field()->bridged) return;
            if (!bridgedFieldsWithAlignmentConflicts.count(s.field()->name)) return;
            noPackBridgedFields.insert(s.field()->name);
        }); }
    if (LOGGING(2)) {
        if (noPackBridgedFields.size() != 0)
            LOG2("\tThe following bridged fields must be marked no-pack with other bridged "
                 "fields:");
        for (auto s : noPackBridgedFields)
            LOG2("\t  " << s); }
    return noPackBridgedFields;
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

/// @returns a new slice list where any adjacent slices of the same field with
/// contiguous little Endian ranges are merged into one slice, eg f[0:3], f[4:7]
/// become f[0:7].
static const PHV::SuperCluster::SliceList*
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
                        int listSize = std::accumulate(sliceList->begin(), sliceList->end(), 0,
                            [](int acc, const PHV::FieldSlice& s) { return acc + s.size(); });
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

    if (LOGGING(1)) {
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

    if (LOGGING(1)) {
        msg << std::endl
            << "..........Unallocated bits = " << unallocated_bits << std::endl;
        msg << "..........ingress phv bits = " << ingress_phv_bits << std::endl;
        msg << "..........egress phv bits = " << egress_phv_bits << std::endl;
        msg << "..........ingress t_phv bits = " << ingress_t_phv_bits << std::endl;
        msg << "..........egress t_phv bits = " << egress_t_phv_bits << std::endl;
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
                alloc_attempt.allocate(alloc_slice); } }
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
    if (Device::currentDevice() == Device::JBAY) {
        return { }; }

    std::list<PHV::SuperCluster*> allocated_sc;
    auto& pa_container_sizes = core_alloc_i.pragmas().pa_container_sizes();
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
            auto slice_rst = PHV::SlicingIterator::split_super_cluster(sc, slice_schema);
            if (!slice_rst) continue;

            if (LOGGING(5)) {
                LOG5("Pounder slicing: " << sc << " to ");
                for (auto* new_sc : *slice_rst) {
                    LOG5(new_sc); } }

            // If the pounder slicing does not satisfy pa_container_size requirements, then ignore
            // and go to the next slicing. This is required to ensure that pa_container_size pragma
            // is always respected after preslicing.
            std::set<const PHV::Field*> unsatisfiable_fields =
                pa_container_sizes.unsatisfiable_fields(*slice_rst);
            if (unsatisfiable_fields.size() > 0)
                continue;

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
        const std::list<PHV::SuperCluster*>& cluster_groups,
        std::list<PHV::SuperCluster*>& unsliceable) {
    LOG5("===================  Pre-Slicing ===================");
    std::list<PHV::SuperCluster*> rst;
    auto& meter_color_dests = core_alloc_i.actionConstraints().meter_color_dests();
    for (auto* sc : cluster_groups) {
        LOG5("PRESLICING " << sc);
        try {
            auto it = PHV::SlicingIterator(sc,
                    core_alloc_i.pragmas().pa_container_sizes().field_to_sizes());
            std::set<const PHV::Field*> unsatisfiable_fields;
            auto& pa_container_sizes = core_alloc_i.pragmas().pa_container_sizes();
            if (!it.done()) {
                // Try until we find one satisfies pa_container_size pragmas.
                while (!it.done()) {
                    pa_container_sizes.adjust_requirements(*it);
                    unsatisfiable_fields = pa_container_sizes.unsatisfiable_fields(*it);
                    if (unsatisfiable_fields.size() > 0) {
                        LOG5("Found " << unsatisfiable_fields.size() << " unsatisfiable fields.");
                        for (const auto* f : unsatisfiable_fields) LOG5("\t" << f);
                    }
                    if (unsatisfiable_fields.size() == 0) {
                        break; }
                    ++it; }
                // If failed to find it, use the first slicing as pre-slicing.
                if (it.done()) {
                    unsatisfiable_fields = pa_container_sizes.unsatisfiable_fields(*it);
                    for (const auto* f : unsatisfiable_fields) {
                        if (meter_color_dests.count(f)) {
                            if (f->size > 8)
                                P4C_UNIMPLEMENTED("Currently the compiler only supports allocation "
                                        "of meter color destination field %1% to an 8-bit "
                                        "container. However, meter color destination %1% with size "
                                        "%2% bits cannot be split based on its use. Therefore, it "
                                        "cannot be allocated to an 8-bit container. Suggest using a"
                                        " meter color destination that is less than or equal to 8b "
                                        "in size.", f->name, f->size);
                            else
                                P4C_UNIMPLEMENTED("Currently the compiler only supports allocation "
                                        "of meter color destination field %1% to an 8-bit "
                                        "container. However, %1% cannot be allocated to an 8-bit "
                                        "container.", f->name);
                        }
                    }
                    ::error("Cannot find a slicing to satisfy @pa_container_size for fields in the "
                            "following groups of fields:\n%1%", cstring::to_cstring(sc));
                    it = PHV::SlicingIterator(sc,
                            core_alloc_i.pragmas().pa_container_sizes().field_to_sizes());
                    unsliceable.push_back(sc); }

                LOG5("--- into new slices -->");
                for (auto* new_sc : *it) {
                    LOG5(new_sc);
                    rst.push_back(new_sc); }
            } else {
                unsatisfiable_fields = pa_container_sizes.unsatisfiable_fields({ sc });
                if (unsatisfiable_fields.size() > 0)
                    LOG6("Found " << unsatisfiable_fields.size() << " unsatisfiable fields.");
                for (const auto* f : unsatisfiable_fields) {
                    LOG6("\t" << f);
                    if (meter_color_dests.count(f)) {
                        if (f->size > 8)
                            P4C_UNIMPLEMENTED("Currently the compiler only supports allocation "
                                    "of meter color destination field %1% to an 8-bit container. "
                                    "However, meter color destination %1% with size %2% bits "
                                    "cannot be split based on its use. Therefore, it cannot be "
                                    "allocated to an 8-bit container. Suggest using a meter color "
                                    "destination that is less than or equal to 8b in size.",
                                    f->name, f->size);
                        else
                            P4C_UNIMPLEMENTED("Currently the compiler only supports allocation of "
                                    "meter color destination field %1% to an 8-bit container. "
                                    "However, %1% cannot be allocated to an 8-bit container.",
                                    f->name);
                    }
                }
                if (unsatisfiable_fields.size() > 0)
                    ::error("Cannot find a slicing to satisfy @pa_container_size: \n%1%",
                            cstring::to_cstring(sc));
                LOG5("    ...but preslicing failed");
                unsliceable.push_back(sc);
            }
        } catch (const Util::CompilerBug& e) {
            BUG("The compiler failed in slicing the following group of fields related by "
                "parser alignment and MAU constraints\n%1%", sc);
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
BruteForceAllocationStrategy::tryAllocation(
    const PHV::Allocation &alloc,
    const std::list<PHV::SuperCluster*>& cluster_groups_input,
    std::list<PHV::ContainerGroup *>& container_groups) {
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
    cluster_groups = slice_clusters(cluster_groups, unsliceable);

    // fail early if some clusters have unsatisfiable constraints.
    if (unsliceable.size()) {
        return AllocResult(AllocResultCode::FAIL_UNSAT,
                           alloc.makeTransaction(),
                           std::move(unsliceable)); }

    // remove deparser zero superclusters.
    std::list<PHV::SuperCluster*> deparser_zero_superclusters;
    cluster_groups = remove_deparser_zero_superclusters(cluster_groups,
            deparser_zero_superclusters);

    cluster_groups = create_strided_clusters(cluster_groups);

    // Sorting clusters must happen after the deparser zero superclusters are removed.
    sortClusters(cluster_groups);

    auto rst = alloc.makeTransaction();

    // Allocate deparser zero fields first.
    auto allocated_dep_zero_clusters = allocDeparserZeroSuperclusters(rst,
            deparser_zero_superclusters);

    if (deparser_zero_superclusters.size() > 0) {
        LOG1("Deparser Zero field allocation failed: " << deparser_zero_superclusters.size());
        report_i << "Deparser Zero Field Allocation Failed.\n";
        writeTransactionSummary(rst, allocated_dep_zero_clusters);
    }

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

    if (cluster_groups.size() > 0 || deparser_zero_superclusters.size() > 0) {
        report_i << "BruteForceStrategy Allocation Failed.\n";
        writeTransactionSummary(rst, allocated_clusters);
        return AllocResult(AllocResultCode::FAIL, std::move(rst), std::move(cluster_groups));
    } else {
        report_i << "BruteForceStrategy Allocation Successful.\n";
        return AllocResult(AllocResultCode::SUCCESS, std::move(rst), std::move(cluster_groups));
    }
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
    if (Device::currentDevice() == Device::JBAY) {
        const ordered_map<const PHV::Field*, cstring> container_type_pragmas =
            core_alloc_i.pragmas().pa_container_type().getFields();
        for (auto* cluster : cluster_groups) {
            cluster->forall_fieldslices([&] (const PHV::FieldSlice& fs) {
                if (container_type_pragmas.count(fs.field()))
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
            int length = std::accumulate(
                    slice_list->begin(), slice_list->end(), 0,
                    [] (int a, const PHV::FieldSlice& b) { return a + b.size(); });
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
        if (Device::currentDevice() == Device::JBAY) {
            if (has_container_type_pragma.count(l) != has_container_type_pragma.count(r)) {
                return has_container_type_pragma.count(l) > has_container_type_pragma.count(r); }
            if (n_container_size_pragma.at(l) != n_container_size_pragma.at(r))
                return n_container_size_pragma.at(l) > n_container_size_pragma.at(r);
        }
        if (Device::currentDevice() == Device::JBAY)
            if (has_pov.count(l) != has_pov.count(r))
                return has_pov.count(l) > has_pov.count(r);
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
            if (Device::currentDevice() == Device::JBAY) {
                // for metadata fields, prioritize pa_container size pragmas
                if (n_container_size_pragma.at(l) != n_container_size_pragma.at(r))
                    return n_container_size_pragma.at(l) > n_container_size_pragma.at(r);
            }
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

bool
BruteForceAllocationStrategy::tryAllocSlicing(const std::list<PHV::SuperCluster*>& slicing,
                                          const std::list<PHV::ContainerGroup *>& container_groups,
                                          PHV::Transaction& slicing_alloc) {
    LOG4("Try alloc slicing:");

    // Place all slices, then get score for that placement.
    bool succeeded = true;

    for (auto* sc : slicing) {
        // Find best container group for this slice.
        auto best_slice_score = AllocScore::make_lowest();
        boost::optional<PHV::Transaction> best_slice_alloc = boost::none;

        for (PHV::ContainerGroup* container_group : container_groups) {
            LOG4("Try container group: " << container_group);

            if (auto partial_alloc =
                    core_alloc_i.tryAlloc(slicing_alloc, *container_group, *sc,
                        bridgedFieldsWithAlignmentConflicts)) {
                AllocScore score = AllocScore(*partial_alloc,
                        core_alloc_i.phv(), clot_i, core_alloc_i.uses(),
                        core_alloc_i.field_to_parser_states(),
                        core_alloc_i.parser_critical_path());
                LOG4("    ...SUPERCLUSTER score: " << score);
                if (!best_slice_alloc || score > best_slice_score) {
                    best_slice_score = score;
                    best_slice_alloc = partial_alloc;
                }
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
BruteForceAllocationStrategy::tryAllocStride(const std::list<PHV::SuperCluster*>& stride,
                                          const std::list<PHV::ContainerGroup *>& container_groups,
                                          PHV::Transaction& stride_alloc) {
    LOG4("Try alloc slicing stride");

    auto best_score = AllocScore::make_lowest();
    boost::optional<PHV::Transaction> best_alloc = boost::none;

    auto leader = stride.front();

    for (PHV::ContainerGroup* container_group : container_groups) {
        LOG4("Try container group: " << container_group);

        auto leader_alloc = core_alloc_i.tryAlloc(stride_alloc, *container_group, *leader,
                                                  bridgedFieldsWithAlignmentConflicts);
        if (leader_alloc) {
            // alloc rest
            if (tryAllocStrideWithLeaderAllocated(stride, *leader_alloc)) {
                AllocScore score = AllocScore(*leader_alloc,
                        core_alloc_i.phv(), clot_i, core_alloc_i.uses(),
                        core_alloc_i.field_to_parser_states(),
                        core_alloc_i.parser_critical_path());

                if (!best_alloc || score > best_score) {
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
        PHV::Transaction& leader_alloc) {
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
                                              bridgedFieldsWithAlignmentConflicts);

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
BruteForceAllocationStrategy::tryAllocSlicingStrided(unsigned num_strides,
                                          const std::list<PHV::SuperCluster*>& slicing,
                                          const std::list<PHV::ContainerGroup *>& container_groups,
                                          PHV::Transaction& slicing_alloc) {
    LOG4("Try alloc slicing strided: (num_stride = " << num_strides << ")");

    auto strides = reorder_slicing_as_strides(num_strides, slicing);

    int i = 0;
    for (auto& stride : strides) {
        auto stride_alloc = slicing_alloc.makeTransaction();
        bool succeeded = tryAllocStride(stride, container_groups, stride_alloc);

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

std::list<PHV::SuperCluster*>
BruteForceAllocationStrategy::allocLoop(PHV::Transaction& rst,
                                        std::list<PHV::SuperCluster*>& cluster_groups,
                                        const std::list<PHV::ContainerGroup *>& container_groups) {
    // Packing opportunities for each field, if allocated in @p cluster_groups order.
    AllocScore::g_packing_opportunities = new FieldPackingOpportunity(
            cluster_groups, core_alloc_i.actionConstraints(),
            core_alloc_i.uses(), core_alloc_i.defuse(), core_alloc_i.mutex());
    for (const auto* cluster : cluster_groups) {
        std::set<const PHV::Field*> showed;
        cluster->forall_fieldslices([&] (const PHV::FieldSlice& fs) {
            if (showed.count(fs.field())) return;
            showed.insert(fs.field());
            LOG4("Field " << fs.field() << " has "
                 << AllocScore::g_packing_opportunities->nOpportunities(fs.field()));
        });
    }

    std::stringstream alloc_history;
    std::list<PHV::SuperCluster*> allocated;
    for (PHV::SuperCluster* cluster_group : cluster_groups) {
        alloc_history << "TRYING to allocate " << cluster_group;
        LOG4("TRYING to allocate " << cluster_group);
        auto best_score = AllocScore::make_lowest();
        boost::optional<PHV::Transaction> best_alloc = boost::none;
        boost::optional<std::list<PHV::SuperCluster*>> best_slicing = boost::none;

        // Try all possible slicings.
        auto slice_it = PHV::SlicingIterator(cluster_group,
                core_alloc_i.pragmas().pa_container_sizes().field_to_sizes(), false, false);
        int n_tried = 0;
        if (slice_it.done())
            LOG4("    ...but there are no valid slicings");
        auto& pa_container_sizes = core_alloc_i.pragmas().pa_container_sizes();

        int MAX_SLICING_TRY = 65535;

        /// XXX(zma) strided cluster can have many slices in the supercluster
        /// and the number of slicing can blow up (need a better way to stop
        /// than this crude heuristic).
        if (cluster_group->needsStridedAlloc())
            MAX_SLICING_TRY = 128;

        while (!slice_it.done()) {
            auto slicing = *slice_it;

            if (LOGGING(4)) {
                LOG4("Slicing attempt: " << n_tried);
                for (auto* sc : slicing)
                    LOG4(sc);
            }

            // If the current slicing does not satisfy pa_container_size requirements, then ignore
            // and go to the next slice. This is required to ensure that later slicings (after
            // pre-slicing) respect the pa_container_size pragma.
            std::set<const PHV::Field*> unsatisfiable_fields =
                pa_container_sizes.unsatisfiable_fields(slicing);

            if (unsatisfiable_fields.size() > 0) {
                ++slice_it;
                LOG4("Container size unsatisfiable slicing, continue ...");
                continue;
            }

            if (cluster_group->needsStridedAlloc()) {
                if (!is_valid_stride_slicing(slicing)) {
                    ++slice_it;
                    LOG4("Invalid stride slicing, continue ...");
                    continue;
                }
            }

            LOG4("Valid slicing, try to place all slices in slicing:");

            // Place all slices, then get score for that placement.
            auto slicing_alloc = rst.makeTransaction();
            bool succeeded = false;

            if (cluster_group->needsStridedAlloc()) {
                unsigned num_strides = slicing.size() / cluster_group->slices().size();
                succeeded = tryAllocSlicingStrided(num_strides,
                                                   slicing, container_groups, slicing_alloc);
            } else {
                succeeded = tryAllocSlicing(slicing, container_groups, slicing_alloc);
            }

            // If allocation succeeded, check the score.
            auto slicing_score = AllocScore(slicing_alloc,
                                            core_alloc_i.phv(), clot_i, core_alloc_i.uses(),
                                            core_alloc_i.field_to_parser_states(),
                                            core_alloc_i.parser_critical_path());
            if (LOGGING(4)) {
                LOG4("Best SUPERCLUSTER score for this slicing: " << slicing_score);
                LOG4("For the following SUPERCLUSTER slices: ");
                for (auto* sc : slicing)
                    LOG4(sc);
            }
            if (succeeded && (!best_alloc || slicing_score > best_score)) {
                best_score = slicing_score;
                best_alloc = slicing_alloc;
                best_slicing = slicing;
                LOG4("...and this is the best score seen so far.");
            }

            // Try the next slicing.
            ++slice_it;
            ++n_tried;
            if (n_tried >= MAX_SLICING_TRY) {
                LOG4("Exceeding max slicing attempts " << MAX_SLICING_TRY << ", stop!");
                break;
            }
        }

        // If any allocation was found, commit it.
        if (best_alloc) {
            if (LOGGING(4)) {
                LOG4("SUCCESSFULLY allocated " << cluster_group);
                LOG4("by slicing it into the following superclusters:");
                for (auto* sc : *best_slicing)
                    LOG5(sc);
                LOG4("SCORE: " << best_score);
            }

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
        }
    }

    // XXX(cole): There must be a better way to remove elements from a list
    // while iterating, but `it = clusters_i.erase(it)` skips elements.
    for (auto cluster_group : allocated)
        cluster_groups.remove(cluster_group);
    LOG5("Allocation History");
    LOG5(alloc_history.str());
    return allocated;
}