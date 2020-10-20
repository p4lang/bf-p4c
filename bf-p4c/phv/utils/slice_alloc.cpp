#include <boost/optional/optional_io.hpp>
#include <iostream>
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/slice_alloc.h"

PHV::AllocSlice::AllocSlice(
        const PHV::Field* f,
        PHV::Container c,
        int field_bit_lo,
        int container_bit_lo,
        int width)
: field_i(f), container_i(c), field_bit_lo_i(field_bit_lo),
  container_bit_lo_i(container_bit_lo), width_i(width) {
    BUG_CHECK(width_i <= 32,
        "Slice larger than largest container: %1%",
        cstring::to_cstring(this));

    le_bitrange field_range = StartLen(0, f->size);
    le_bitrange slice_range = StartLen(field_bit_lo, width);
    BUG_CHECK(field_range.contains(slice_range),
              "Trying to slice field %1% at [%2%:%3%] but it's only %4% bits wide",
              cstring::to_cstring(f), slice_range.lo, slice_range.hi, f->size);
    min_stage_i = std::make_pair(-1, PHV::FieldUse(PHV::FieldUse::READ));
    max_stage_i = std::make_pair(PhvInfo::getDeparserStage(), PHV::FieldUse(PHV::FieldUse::WRITE));
    init_i = new DarkInitPrimitive();
}

PHV::AllocSlice::AllocSlice(
        const PHV::Field* f,
        PHV::Container c,
        int field_bit_lo,
        int container_bit_lo,
        int width,
        ActionSet action)
: AllocSlice(f, c, field_bit_lo, container_bit_lo, width) {
    init_points_i = action;
}

PHV::AllocSlice::AllocSlice(
        const PHV::Field* f,
        PHV::Container c,
        le_bitrange field_slice,
        le_bitrange container_slice)
: AllocSlice(f, c, field_slice.lo, container_slice.lo, field_slice.size()) {
    BUG_CHECK(field_slice.size() == container_slice.size(),
              "Trying to allocate field slice %1% to a container slice %2% of different "
              "size.",
              cstring::to_cstring(field_slice),
              cstring::to_cstring(container_slice));
}

PHV::AllocSlice::AllocSlice(const AllocSlice& other) {
    field_i = other.field();
    container_i = other.container();
    field_bit_lo_i = other.field_slice().lo;
    container_bit_lo_i = other.container_slice().lo;
    width_i = other.width();
    init_points_i = other.getInitPoints();
    shadow_always_run_i = other.getShadowAlwaysRun();
    has_meta_init_i = other.hasMetaInit();
    init_i = new DarkInitPrimitive(*(other.getInitPrimitive()));
    this->setLiveness(other.getEarliestLiveness(), other.getLatestLiveness());
}


bool PHV::AllocSlice::operator==(const PHV::AllocSlice& other) const {
    return field_i             == other.field_i
        && container_i         == other.container_i
        && field_bit_lo_i      == other.field_bit_lo_i
        && container_bit_lo_i  == other.container_bit_lo_i
        && width_i             == other.width_i
        && min_stage_i         == other.min_stage_i
        && max_stage_i         == other.max_stage_i;
}

bool PHV::AllocSlice::operator!=(const PHV::AllocSlice& other) const {
    return !this->operator==(other);
}

bool PHV::AllocSlice::operator<(const PHV::AllocSlice& other) const {
    if (field_i->id != other.field_i->id)
        return field_i->id < other.field_i->id;
    if (container_i != other.container_i)
        return container_i < other.container_i;
    if (field_bit_lo_i != other.field_bit_lo_i)
        return field_bit_lo_i < other.field_bit_lo_i;
    if (container_bit_lo_i != other.container_bit_lo_i)
        return container_bit_lo_i < other.container_bit_lo_i;
    if (width_i != other.width_i)
        return width_i < other.width_i;
    if (min_stage_i.first != other.min_stage_i.first)
        return min_stage_i.first < other.min_stage_i.first;
    if (min_stage_i.second != other.min_stage_i.second)
        return min_stage_i.second < other.min_stage_i.second;
    if (max_stage_i.first != other.max_stage_i.first)
        return max_stage_i.first < other.max_stage_i.first;
    if (max_stage_i.second != other.max_stage_i.second)
        return max_stage_i.second < other.max_stage_i.second;
    return false;
}

boost::optional<PHV::AllocSlice> PHV::AllocSlice::sub_alloc_by_field(int start, int len) const {
    BUG_CHECK(start >= 0 && len > 0,
              "sub_alloc slice with invalid start or len arguments: [%1%:%2%]", start, len);

    le_bitrange sub_slice(start, start + len - 1);
    auto overlap = sub_slice.intersectWith(this->field_slice());

    if (overlap.empty() || overlap.size() != len)
        return boost::none;

    PHV::AllocSlice clone = *this;
    clone.container_bit_lo_i += (start - field_bit_lo_i);
    clone.field_bit_lo_i = start;
    clone.width_i = len;
    return clone;
}

bool PHV::AllocSlice::isLiveRangeDisjoint(const AllocSlice& other) const {
    return PHV::isLiveRangeDisjoint(min_stage_i, max_stage_i, other.min_stage_i, other.max_stage_i);
}

bool PHV::AllocSlice::hasInitPrimitive() const {
    if (init_i == nullptr) return false;
    if (init_i->isEmpty()) return false;
    return true;
}

bool PHV::AllocSlice::isUsedDeparser() const {
    return (max_stage_i.first == PhvInfo::getDeparserStage());
}

bool PHV::AllocSlice::isUsedParser() const {
    if (container_i.is(PHV::Kind::dark)) return false;
    int minStage = PhvInfo::getDeparserStage();
    const le_bitrange range = field_slice();
    field_i->foreach_alloc(range, [&](const PHV::AllocSlice& alloc) {
        if (alloc.getEarliestLiveness().first < minStage)
            minStage = alloc.getEarliestLiveness().first;
    });
    if (min_stage_i.first == minStage) return true;
    return false;
}

namespace PHV {

    std::ostream &operator<<(std::ostream &out, const PHV::AllocSlice &slice) {
    out << slice.container() << " " << slice.container_slice() << " <-- "
        << PHV::FieldSlice(slice.field(), slice.field_slice());
    out << " live at [" << slice.getEarliestLiveness().first <<
        slice.getEarliestLiveness().second << ", " << slice.getLatestLiveness().first <<
        slice.getLatestLiveness().second << "]";
    if (!slice.getInitPrimitive()->isEmpty()) {
        if (slice.getInitPrimitive()->isNOP())
            out << " { NOP }";
        else if (slice.getInitPrimitive()->mustInitInLastMAUStage())
            out << " { always_run; " << slice.getInitPrimitive()->getInitPoints().size() <<
                   " actions }";
        else if (slice.getInitPrimitive()->getInitPoints().size() > 0)
            out << " { " << slice.getInitPrimitive()->getInitPoints().size() << " actions }";
    }

    return out;
}

    std::ostream &operator<<(std::ostream &out, const PHV::AllocSlice* slice) {
    if (slice)
        out << *slice;
    else
        out << "-null-alloc-slice-";
    return out;
}

std::ostream &operator<<(std::ostream &out,
                         const std::vector<PHV::AllocSlice> &sl_vec) {
    for (auto &sl : sl_vec) out << sl << "\n";
    return out;
}

    std::ostream &operator<<(std::ostream &out, const PHV::DarkInitEntry& entry) {
    out << "\t\t" << entry.getDestinationSlice();
    const PHV::DarkInitPrimitive& prim = entry.getInitPrimitive();
    out << prim;
    return out;
}

    std::ostream &operator<<(std::ostream &out, const PHV::DarkInitPrimitive& prim) {
    if (prim.isNOP()) {
        out << " NOP";
        return out;
    } else if (prim.destAssignedToZero()) {
        out << " = 0";
    } else {
        auto source = prim.getSourceSlice();
        if (!source)
            out << " NO SOURCE SLICE";
        // BUG_CHECK(source, "No source slice specified, even though compiler expects one.");
        else
            out << " = " << *source;
    }
    if (prim.mustInitInLastMAUStage())
        out << "  : always_run last Stage ";
    if (prim.isAlwaysRunActionPrim())
        out << "  : always_run_action prim";

    const auto& actions = prim.getInitPoints();
    out << "  :  " << actions.size() << " actions";

    auto priorUnts = prim.getARApriorUnits();
    auto postUnts  = prim.getARApostUnits();

    if (!priorUnts.size()) {
        out << "  : No prior units";
    } else {
        out << "  Prior units:";
        for (auto node : priorUnts) {
            const auto* tbl = node->to<IR::MAU::Table>();
            if (!tbl) {out << "\t non-table unit"; continue; }
            out << "\t " << tbl->name;
        }
    }

    if (!postUnts.size()) {
        out << "  : No post units";
    } else {
        out << "  Post units:";
        for (auto node : postUnts) {
            const auto* tbl = node->to<IR::MAU::Table>();
            if (!tbl) {out << "\t non-table unit"; continue; }
            out << "\t " << tbl->name;
        }
    }
    return out;
}

}  // namespace PHV

std::ostream &operator<<(std::ostream &out,
                         const safe_vector<PHV::AllocSlice> &sl_vec) {
    for (auto &sl : sl_vec) out << sl << "\n";
    return out;
}
