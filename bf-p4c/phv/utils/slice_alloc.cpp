#include <iostream>
#include <boost/optional/optional_io.hpp>
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/slice_alloc.h"

namespace PHV {

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
    *this = other;
}

PHV::AllocSlice& PHV::AllocSlice::operator=(const AllocSlice& other) {
    field_i = other.field();
    container_i = other.container();
    field_bit_lo_i = other.field_slice().lo;
    container_bit_lo_i = other.container_slice().lo;
    width_i = other.width();
    init_points_i = other.getInitPoints();
    shadow_always_run_i = other.getShadowAlwaysRun();
    has_meta_init_i = other.hasMetaInit();
    is_physical_stage_based_i = other.is_physical_stage_based_i;
    physical_deparser_stage_i = other.physical_deparser_stage_i;
    init_i = other.init_i;
    this->setLiveness(other.getEarliestLiveness(), other.getLatestLiveness());
    return *this;
}

void PHV::AllocSlice::setInitPrimitive(DarkInitPrimitive* prim) {
    init_i = *prim;
}

bool PHV::AllocSlice::operator==(const PHV::AllocSlice& other) const {
    return field_i                   == other.field_i
        && container_i               == other.container_i
        && field_bit_lo_i            == other.field_bit_lo_i
        && container_bit_lo_i        == other.container_bit_lo_i
        && width_i                   == other.width_i
        && min_stage_i               == other.min_stage_i
        && max_stage_i               == other.max_stage_i
        && is_physical_stage_based_i == other.is_physical_stage_based_i
        && physical_deparser_stage_i == other.physical_deparser_stage_i;
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
    if (is_physical_stage_based_i != other.is_physical_stage_based_i)
        return is_physical_stage_based_i < other.is_physical_stage_based_i;
    if (physical_deparser_stage_i != other.physical_deparser_stage_i)
        return physical_deparser_stage_i < other.physical_deparser_stage_i;
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

bool PHV::AllocSlice::isLiveAt(int stage, const PHV::FieldUse& use) const {
    if (is_physical_stage_based_i) {
        // physical live range, all AllocSlice live range starts with read or write
        // and must end with read. Also, no AllocSlice will have overlapped live range.
        const int actual_stage = use.isWrite() ? stage + 1 : stage;
        const int start = min_stage_i.second.isWrite() ? min_stage_i.first + 1 : min_stage_i.first;
        return start <= actual_stage && actual_stage <= max_stage_i.first;
    } else {
        // after starting write
        const bool after_start = (min_stage_i.first < stage) ||
                                 (min_stage_i.first == stage && use >= min_stage_i.second);
        // before ending read
        const bool before_end = (stage < max_stage_i.first) ||
                                (stage == max_stage_i.first && use <= max_stage_i.second);
        return after_start && before_end;
    }
}

bool PHV::AllocSlice::isLiveRangeDisjoint(const AllocSlice& other) const {
    return LiveRange(min_stage_i, max_stage_i)
        .is_disjoint(LiveRange(other.min_stage_i, other.max_stage_i));
}

bool PHV::AllocSlice::hasInitPrimitive() const {
    if (init_i.isEmpty()) return false;
    return true;
}

bool PHV::AllocSlice::isUsedParser() const {
    return min_stage_i.first == parser_stage_idx();
}

bool PHV::AllocSlice::isUsedDeparser() const {
    return max_stage_i.first == deparser_stage_idx();
}

bool PHV::AllocSlice::isReferenced(const PHV::AllocContext* ctxt, const PHV::FieldUse* use) const {
    if (ctxt == nullptr) return true;

    // TODO(yumin): it should be safe to remove this guard. Still keeping it here
    // for backward compatibility.
    if (!is_physical_stage_based_i && Device::currentDevice() == Device::TOFINO) return true;

    switch (ctxt->type) {
        // XXX(Yumin): ported from previous implementation.
        // This suspicious condition:
        // min_stage_i.first == 0 && min_stage_i.second.isRead() represents a parser ref.
        // is from legacy codes, only need to check it when not physical-stage-based.
        case AllocContext::Type::PARSER:
            return min_stage_i.first == parser_stage_idx() ||
                   (!is_physical_stage_based_i && min_stage_i.first == 0 &&
                    min_stage_i.second.isRead());

        // deparser can only read, so @p use does not matter here.
        case AllocContext::Type::DEPARSER:
            return max_stage_i.first == deparser_stage_idx();

        case AllocContext::Type::TABLE: {
            std::set<int> stages;
            if (is_physical_stage_based_i) {
                stages = PhvInfo::physicalStages(ctxt->table);
            } else {
                stages = PhvInfo::minStages(ctxt->table);
            }
            for (auto stage : stages) {
                if (use) {
                    if (isLiveAt(stage, *use)) {
                        return true;
                    }
                } else {
                    if (min_stage_i.first <= stage && stage <= max_stage_i.first) {
                        return true;
                    }
                }
            }
            return false;
        }

        default:
            BUG("Unexpected PHV context type");
    }

    return false;
}
int PHV::AllocSlice::parser_stage_idx() const {
    return -1;
}

int PHV::AllocSlice::deparser_stage_idx() const {
    return (is_physical_stage_based_i || physical_deparser_stage_i) ? Device::numStages()
        : PhvInfo::getDeparserStage();
}

DarkInitPrimitive::DarkInitPrimitive(ActionSet initPoints)
    : assignZeroToDestination(true), nop(false),
    alwaysInitInLastMAUStage(false), alwaysRunActionPrim(false), actions(initPoints) {}

DarkInitPrimitive::DarkInitPrimitive(PHV::AllocSlice& src)
     : assignZeroToDestination(false), nop(false), sourceSlice(new PHV::AllocSlice(src)),
     alwaysInitInLastMAUStage(false), alwaysRunActionPrim(false) { }

DarkInitPrimitive::DarkInitPrimitive(PHV::AllocSlice& src, ActionSet initPoints)
     : assignZeroToDestination(false), nop(false), sourceSlice(new PHV::AllocSlice(src)),
     alwaysInitInLastMAUStage(false), alwaysRunActionPrim(false), actions(initPoints) { }

DarkInitPrimitive::DarkInitPrimitive(const DarkInitPrimitive& other)
     : assignZeroToDestination(other.assignZeroToDestination),
     nop(other.nop),
     alwaysInitInLastMAUStage(other.alwaysInitInLastMAUStage),
     alwaysRunActionPrim(other.alwaysRunActionPrim),
     actions(other.actions),
     priorUnits(other.priorUnits),
     postUnits(other.postUnits),
     priorPrims(other.priorPrims),
     postPrims(other.postPrims)
{
     if (other.getSourceSlice()) {
        sourceSlice.reset(new PHV::AllocSlice(*other.getSourceSlice()));
     }
}

void DarkInitPrimitive::addSource(const AllocSlice& sl) {
    assignZeroToDestination = false;
    sourceSlice.reset(new PHV::AllocSlice(sl));
}

bool DarkInitPrimitive::operator==(const PHV::DarkInitPrimitive& other) const {
    bool zero2dest = (assignZeroToDestination == other.assignZeroToDestination);
    bool isNop = (nop == other.nop);
    bool srcSlc = false;
    if (!sourceSlice && !other.sourceSlice)
        srcSlc = true;
    if (sourceSlice && other.sourceSlice)
        srcSlc = (*sourceSlice == *other.sourceSlice);
    bool initLstStg  = (alwaysInitInLastMAUStage == other.alwaysInitInLastMAUStage);
    bool araPrim = (alwaysRunActionPrim == other.alwaysRunActionPrim);
    bool acts = (actions == other.actions);
    bool rslt = zero2dest && isNop && srcSlc && initLstStg && araPrim && acts;

    LOG7("\t op==" << rslt << " <-- " << zero2dest << " " << isNop << " " << srcSlc <<
         " " << initLstStg << " " << araPrim << " " << acts);

    return rslt;
}

DarkInitPrimitive& DarkInitPrimitive::operator=(const DarkInitPrimitive& other) {
    if (this != &other) {
        assignZeroToDestination = other.assignZeroToDestination;
        nop = other.nop;
        if (other.sourceSlice) {
            sourceSlice.reset(new AllocSlice(*other.sourceSlice));
        } else {
            sourceSlice.reset();
        }
        alwaysInitInLastMAUStage = other.alwaysInitInLastMAUStage;
        alwaysRunActionPrim = other.alwaysRunActionPrim;
        actions = other.actions;
        priorUnits = other.priorUnits;
        postUnits = other.postUnits;
        priorPrims = other.priorPrims;
        postPrims = other.postPrims;
    }
    return *this;
}

std::ostream& operator<<(std::ostream& out, const PHV::AllocSlice& slice) {
    out << slice.container() << " " << slice.container_slice() << " <-- "
        << PHV::FieldSlice(slice.field(), slice.field_slice());
    out << " live at " << (slice.isPhysicalStageBased() ? "P" : "") << "[";
    out << slice.getEarliestLiveness() << ", " << slice.getLatestLiveness() << "]";
    if (!slice.getInitPrimitive().isEmpty()) {
        if (slice.getInitPrimitive().isNOP())
            out << " { NOP }";
        else if (slice.getInitPrimitive().mustInitInLastMAUStage())
            out << " { always_run; " << slice.getInitPrimitive().getInitPoints().size()
                << " actions }";
        else if (slice.getInitPrimitive().getInitPoints().size() > 0)
            out << " { " << slice.getInitPrimitive().getInitPoints().size() << " actions }";
    }

    return out;
}

std::ostream& operator<<(std::ostream& out, const PHV::AllocSlice* slice) {
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

std::ostream& operator<<(std::ostream& out, const PHV::DarkInitEntry& entry) {
    out << "\t\t" << entry.getDestinationSlice();
    const PHV::DarkInitPrimitive& prim = entry.getInitPrimitive();
    out << prim;
    return out;
}

std::ostream& operator<<(std::ostream& out, const PHV::DarkInitPrimitive& prim) {
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
