#include "bf-p4c/phv/v2/greedy_tx_score.h"

#include <sstream>
#include <utility>

#include <boost/optional/optional.hpp>

#include "bf-p4c/device.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/phv/v2/kind_size_indexed_map.h"
#include "bf-p4c/phv/v2/sort_macros.h"

namespace PHV {
namespace v2 {

using ContGress = Vision::ContGress;

namespace {

/// convert slices to a bitvec where 1 represents an occupied bit.
bitvec make_allocated_bitvec(const ordered_set<PHV::AllocSlice>& slices) {
    bitvec allocated;
    for (const auto& slice : slices) {
        allocated.setrange(slice.container_slice().lo, slice.container_slice().size());
    }
    return allocated;
}

ContGress from(const gress_t& t) {
    switch (t) {
        case INGRESS: {
            return ContGress::ingress;
        }
        case EGRESS: {
            return ContGress::egress;
        }
        case GHOST: {
            return ContGress::ingress;
        }
        default:
            BUG("unknown gress: ", t);
    }
}

// ContGress from(const PHV::Allocation::GressAssignment& t) {
//     if (!t) return ContGress::unassigned;
//     return from(*t);
// }

ContGress device_gress(const Container& c) {
    const auto& phv_spec = Device::phvSpec();
    if (phv_spec.ingressOnly()[phv_spec.containerToId(c)]) {
        return ContGress::ingress;
    } else if (phv_spec.egressOnly()[phv_spec.containerToId(c)]) {
        return ContGress::egress;
    } else {
        return ContGress::unassigned;
    }
}

/// call @p f with AllocSlice(s) that slices of the same field slices with different live ranges
/// will be passed to @p f only once (de-duplicate by {field, range} pair).
template <typename T>
void deduped_iterate(const T& alloc_slices,
                     const std::function<void(const AllocSlice&)>& f) {
    ordered_set<std::pair<const PHV::Field*, le_bitrange>> seen;
    for (const auto& slice : alloc_slices) {
        auto fs = std::make_pair(slice.field(), slice.field_slice());
        if (seen.count(fs)) continue;
        seen.insert(fs);
        f(slice);
    }
}

}  // namespace


int Vision::bits_demand(const PHV::Kind& k) const {
    int rv = 0;
    for (const auto& db : Values(cont_required)) {
        for (const auto& ks_n : db.m) {
            if (ks_n.first.first != k) continue;
            rv += static_cast<int>(ks_n.first.second) * ks_n.second;
        }
    }
    return rv;
}

int Vision::bits_supply(const PHV::Kind& k) const {
    int rv = 0;
    for (const auto& db : Values(cont_available)) {
        for (const auto& ks_n : db.m) {
            if (ks_n.first.first != k) continue;
            rv += static_cast<int>(ks_n.first.second) * ks_n.second;
        }
    }
    return rv;
}

GreedyTxScoreMaker::GreedyTxScoreMaker(
    const PhvKit& kit,
    const std::list<ContainerGroup*>& container_groups,
    const std::list<SuperCluster*>& sorted_clusters,
    const ordered_map<const SuperCluster*, KindSizeIndexedMap>& baseline)
    : kit_i(kit) {
    ///// compute container kind and size indexed availability and demand.
    // initialization
    for (const auto& gress : {INGRESS, EGRESS}) {
        vision_i.cont_available[from(gress)] = KindSizeIndexedMap();
        vision_i.cont_required[gress] = KindSizeIndexedMap();
    }
    vision_i.cont_available[ContGress::unassigned] = KindSizeIndexedMap();

    // container size pressure.
    for (auto* sc : sorted_clusters) {
        vision_i.sc_cont_required[sc] = baseline.at(sc);
        auto gress = sc->slices().front().field()->gress;
        for (const auto& kv : vision_i.sc_cont_required[sc].m) {
            vision_i.cont_required[gress][kv.first] += kv.second;
        }
    }
    // container availability
    for (const auto& group : container_groups) {
        for (const auto& c : *group) {
            auto kind_sz = std::make_pair(c.type().kind(), c.type().size());
            vision_i.cont_available[device_gress(c)].m[kind_sz]++;
        }
    }
}

void GreedyTxScoreMaker::record_commit(const Transaction& tx, const SuperCluster* sc) {
    using AllocStatus = Allocation::ContainerAllocStatus;
    auto* parent = tx.getParent();
    for (const auto& container_status : tx.get_actual_diff()) {
        const auto& c = container_status.first;
        auto slices = container_status.second.slices;
        auto parent_c_status = AllocStatus::EMPTY;
        if (auto parent_status = parent->getStatus(c)) {
            parent_c_status = parent_status->alloc_status;
        }
        if (parent_c_status == AllocStatus::EMPTY && !slices.empty()) {
            vision_i.cont_available[device_gress(c)][{c.type().kind(), c.type().size()}]--;
        }
    }

    // skip special clusters: deparser-zero, strided...
    if (!vision_i.sc_cont_required.count(sc)) {
        return;
    }
    // update cont required.
    for (const auto& kindsize_n : vision_i.sc_cont_required.at(sc).m) {
        vision_i.cont_required[sc->gress()][kindsize_n.first] -= kindsize_n.second;
    }
}

TxScore* GreedyTxScoreMaker::make(const Transaction& tx) const {
    auto* rv = new GreedyTxScore(&vision_i);
    const auto* parent = tx.getParent();
    boost::optional<gress_t> tx_gress = boost::make_optional(false, INGRESS);
    ordered_map<Vision::ContGress, KindSizeIndexedMap> newly_used;
    for (const auto& kv : tx.get_actual_diff()) {
        const auto& c = kv.first;
        const auto& slices = kv.second.slices;
        const auto& parent_slices = parent->slices(c);
        if (slices.size() == 0) continue;
        tx_gress = slices.front().field()->gress;

        const auto c_kind = c.type().kind();
        const auto c_size = c.type().size();
        const auto c_kind_size = std::make_pair(c_kind, c_size);
        const bool has_solitary =
            std::any_of(slices.begin(), slices.end(),
                        [&](const AllocSlice& sl) { return sl.field()->is_solitary(); });
        const bool no_more_packing =
            has_solitary || c_kind == PHV::Kind::mocha || c_kind == PHV::Kind::dark;

        // compute newly used_bits: (1) if no more packing, then all unused bits in parent tx are
        // counted as used, else (2) count if the bit is used.
        const bitvec parent_bv = make_allocated_bitvec(parent_slices);
        const bitvec tx_bv = make_allocated_bitvec(tx.slices(c));
        for (size_t i = c.lsb(); i <= c.msb(); i++) {
            if (!parent_bv.getbit(i)) {
                rv->used_bits[c_kind_size] += no_more_packing ? 1 : tx_bv.getbit(i);
            }
        }

        // compute newly used container.
        if (parent_bv.empty()) {
            rv->used_containers[c_kind_size]++;
            newly_used[device_gress(c)][{c.type().kind(), c.type().size()}]++;
        }

        const auto& gress = kv.second.gress;
        const auto& parser_group_gress = kv.second.parserGroupGress;
        const auto& deparser_group_gress = kv.second.deparserGroupGress;

        // gress deparser gress mismatch.
        if (!parent->gress(c) && gress) {
            rv->n_set_gress[c_kind_size]++;
            // creating a mismatch by assigning different container gress.
            if (deparser_group_gress && gress != deparser_group_gress) {
                rv->n_mismatched_deparser_gress[c_kind_size]++;
            }
        }

        // Parser group gress
        if (!parent->parserGroupGress(c) && parser_group_gress) {
            rv->n_set_parser_gress[c_kind_size]++;
        }

        // deparser group gress
        if (!parent->deparserGroupGress(c) && deparser_group_gress) {
            rv->n_set_deparser_gress[c_kind_size]++;
            const auto& phv_spec = Device::phvSpec();
            // count mismatches of assigning different gress to a deparser group of containers.
            for (unsigned other_id : phv_spec.deparserGroup(phv_spec.containerToId(c))) {
                auto other_cont = phv_spec.idToContainer(other_id);
                if (other_cont == c) continue;
                if (tx.gress(other_cont) && tx.gress(other_cont) != deparser_group_gress) {
                    rv->n_mismatched_deparser_gress[c_kind_size]++;
                }
            }
        }

        // tphv_on_phv_bits
        if (Device::phvSpec().hasContainerKind(PHV::Kind::tagalong) && c_kind != Kind::tagalong) {
            deduped_iterate(slices, [&](const AllocSlice& slice) {
                if (slice.field()->is_tphv_candidate(kit_i.uses)) {
                    rv->n_tphv_on_phv_bits += slices.size();
                }
            });
        }

        // n_delta_pov_deparser_read_bits
        const bool has_pov = std::any_of(
                slices.begin(), slices.end(),
                [&](const AllocSlice& sl) { return sl.field()->pov; });
        const bool parent_has_pov = std::any_of(
                parent_slices.begin(), parent_slices.end(),
                [&](const AllocSlice& sl) { return sl.field()->pov; });
        if (!parent_has_pov && has_pov) {
            rv->n_pov_deparser_read_bits += c.size();
        }

        // n_deparser_read_digest_fields_bytes
        // XXX(yumin): must use this uses.is_learning because it includes selector field.
        const bool has_learning = std::any_of(
            slices.begin(), slices.end(),
            [&](const AllocSlice& sl) { return kit_i.uses.is_learning(sl.field()); });
        if (has_learning) {
            rv->n_deparser_read_learning_bytes += c.size() / 8;
        }
    }

    // empty tx.
    if (!tx_gress) return rv;

    // compute how many more containers is required than available, grouped by container size.
    rv->n_size_overflow = 0;
    rv->n_max_overflowed = 0;
    for (const auto s : Device::phvSpec().containerSizes()) {
        int this_size_total_overflow = 0;
        for (const auto& gress : {INGRESS, EGRESS}) {
            // we do not count size overflow Kind::tagalong, Kind::dark and because they are
            // usually more than required. Especially for TPHV, there are many headers that
            // can be overlaid.
            int required_carry_over = 0;
            for (const auto k : {Kind::mocha, Kind::normal}) {
                const int required =
                    vision_i.cont_required.at(gress).get_or(k, s, 0) + required_carry_over;
                const int this_gress_available =
                    vision_i.cont_available.at(from(gress)).get_or(k, s, 0) -
                    newly_used[from(gress)].get_or(k, s, 0);
                const int unassigned_available =
                    vision_i.cont_available.at(ContGress::unassigned).get_or(k, s, 0) -
                    newly_used[ContGress::unassigned].get_or(k, s, 0);
                // can all be allocated by gress specified containers.
                if (required <= this_gress_available) {
                    continue;
                }
                // can be allocated by using some unassigned containers.
                if (required <= this_gress_available + unassigned_available) {
                    newly_used[ContGress::unassigned][{k, s}] += (required - this_gress_available);
                    continue;
                }
                // overflowed!
                newly_used[ContGress::unassigned][{k, s}] += unassigned_available;
                const int delta = required - (this_gress_available + unassigned_available);
                if (k == Kind::normal) {
                    rv->n_size_overflow += delta;
                    this_size_total_overflow += delta;
                    rv->n_max_overflowed = std::max(rv->n_max_overflowed, this_size_total_overflow);
                } else {
                    required_carry_over += delta;
                }
            }
        }
    }

    // calc_n_inc_tphv_collections
    if (Device::currentDevice() == Device::TOFINO) {
        const auto tx_used = tx.getTagalongCollectionsUsed();
        const auto parent_used = parent->getTagalongCollectionsUsed();
        for (const auto& col : tx_used) {
            if (!parent_used.count(col))
                rv->n_inc_used_tphv_collection++;
        }
    }

    return rv;
}

cstring GreedyTxScoreMaker::status() const {
    std::stringstream ss;
    ss << vision_i;
    return ss.str();
}

int GreedyTxScore::used_L1_bits() const {
    int total_used_bits = 0;
    total_used_bits += used_bits.sum(Kind::normal);
    if (!vision_i->has_more_than_enough(Kind::mocha)) {
        total_used_bits += used_bits.sum(Kind::mocha);
    }
    return total_used_bits;
}

int GreedyTxScore::used_L2_bits() const {
    int total_used_bits = 0;
    // only when we have enough mocha availability, mocha is considered to be
    // L2 bits, otherwise, it would have been counted as L1.
    if (vision_i->has_more_than_enough(Kind::mocha)) {
        total_used_bits += used_bits.sum(Kind::mocha);
    }
    if (!vision_i->has_more_than_enough(Kind::tagalong)) {
        total_used_bits += used_bits.sum(Kind::tagalong);
    }
    return total_used_bits;
}

bool GreedyTxScore::better_than(const TxScore* other_score) const {
    if (other_score == nullptr) return true;
    const GreedyTxScore* other = dynamic_cast<const GreedyTxScore*>(other_score);
    BUG_CHECK(other, "comparing GreedyTxScore with score of different type: %1%",
              other_score->str());
    BUG_CHECK(vision_i == other->vision_i, "comparing with different maker vision");

    // For tofino1 only, generally prefer to place things to tphv as long as we have
    // enough tphv container available.
    IF_NEQ_RETURN_IS_LESS(n_tphv_on_phv_bits, other->n_tphv_on_phv_bits);

    // TODO(yumin): The priority of these two metric can be flexible.
    // For now we just set it to be the highest to avoid exceeding deparser limit.
    IF_NEQ_RETURN_IS_LESS(n_pov_deparser_read_bits, other->n_pov_deparser_read_bits);
    IF_NEQ_RETURN_IS_LESS(n_deparser_read_learning_bytes, other->n_deparser_read_learning_bytes);

    // container balance has the highest priority.
    IF_NEQ_RETURN_IS_LESS(n_size_overflow, other->n_size_overflow);
    IF_NEQ_RETURN_IS_LESS(n_max_overflowed, other->n_max_overflowed);

    // compare l1 bits usage.
    const int l1_bits = used_L1_bits();
    const int other_l1_bits = other->used_L1_bits();
    IF_NEQ_RETURN_IS_LESS(l1_bits, other_l1_bits);

    // compare l2 bits usage.
    const int l2_bits = used_L2_bits();
    const int other_l2_bits = other->used_L2_bits();
    IF_NEQ_RETURN_IS_LESS(l2_bits, other_l2_bits);

    // compare newly used containers, less means more packing.
    IF_NEQ_RETURN_IS_LESS(used_containers.sum(Kind::normal),
                          other->used_containers.sum(Kind::normal));

    // less gress setting is preferred.
    IF_NEQ_RETURN_IS_LESS(n_set_gress.sum(Kind::normal),
                          other->n_set_gress.sum(Kind::normal));
    IF_NEQ_RETURN_IS_LESS(n_set_deparser_gress.sum(Kind::normal),
                          other->n_set_deparser_gress.sum(Kind::normal));
    IF_NEQ_RETURN_IS_LESS(n_mismatched_deparser_gress.sum(Kind::normal),
                          other->n_mismatched_deparser_gress.sum(Kind::normal));
    IF_NEQ_RETURN_IS_LESS(n_set_parser_gress.sum(Kind::normal),
                          other->n_set_parser_gress.sum(Kind::normal));

    // less tphv collection use (same as gress setting).
    IF_NEQ_RETURN_IS_LESS(n_inc_used_tphv_collection, other->n_inc_used_tphv_collection);

    return false;
}

std::string GreedyTxScore::str() const {
    std::stringstream ss;
    ss << "greedy{ ";
    if (n_tphv_on_phv_bits) {
        ss << "tphv_on_phv: " << n_tphv_on_phv_bits << " ";
    }
    if (n_pov_deparser_read_bits) {
        ss << "pov_read: " << n_pov_deparser_read_bits << " ";
    }
    if (n_deparser_read_learning_bytes) {
        ss << "learning_read: " << n_deparser_read_learning_bytes << " ";
    }
    ss << "ovf: " << n_size_overflow << " ";
    ss << "ovf_max: " << n_max_overflowed << " ";
    ss << "L1: " << used_L1_bits() << " ";
    ss << "L2: " << used_L2_bits() << " ";
    ss << "inc_cont: " << used_containers.sum(Kind::normal) << " ";
    if (auto set_gress = n_set_gress.sum(Kind::normal)) {
        ss << "set_gress: " << set_gress << " ";
    }
    if (n_inc_used_tphv_collection) {
        ss << "tphv_col_inc: " << n_inc_used_tphv_collection << " ";
    }
    if (auto mismatch = n_mismatched_deparser_gress.sum(Kind::normal)) {
        ss << "mismatch_gress: " << mismatch << " ";
    }
    ss << "}";
    return ss.str();
}

std::ostream& operator<<(std::ostream& out, const KindSizeIndexedMap& m) {
    out << "{";
    cstring sep = "";
    for (const auto& kv : m.m) {
        out << sep << kv.first.first << kv.first.second << ": " << kv.second;
        sep = ", ";
    }
    out << "}";
    return out;
}

std::ostream& operator<<(std::ostream& out, const Vision& v) {
    out << "Vision {\n";
    out << " overall container bits status: " << "\n";
    auto kinds = {Kind::mocha};
    if (Device::currentDevice() == Device::TOFINO) {
        kinds = {Kind::tagalong};
    }
    for (const auto& k : kinds) {
        out << "  " << k << "'s demand v.s. supply: " << v.bits_demand(k)
            << "/" << v.bits_supply(k) << "\n";
    }
    out << " container demand v.s. supply: \n";
    for (const auto& gress : {gress_t::INGRESS, gress_t::EGRESS}) {
        for (const auto k : {Kind::tagalong, Kind::dark, Kind::mocha, Kind::normal}) {
            for (const auto s : {PHV::Size::b8, PHV::Size::b16, PHV::Size::b32}) {
                if (auto n_req = v.cont_required.at(gress).get(k, s)) {
                    out << "  " << gress << "-" << k << s << ": " << *n_req << "/("
                        << v.cont_available.at(from(gress)).get_or(k, s, 0) << " + "
                        << v.cont_available.at(ContGress::unassigned).get_or(k, s, 0) << ")\n";
                }
            }
        }
    }
    out << "}";
    return out;
}

}  // namespace v2
}  // namespace PHV
