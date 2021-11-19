#ifndef BF_P4C_PHV_UTILS_SLICE_ALLOC_H_
#define BF_P4C_PHV_UTILS_SLICE_ALLOC_H_

#include <boost/optional.hpp>
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/phv/phv.h"
#include "lib/bitvec.h"
#include "lib/symbitmatrix.h"
#include "ir/ir.h"

namespace PHV {

using ActionSet = ordered_set<const IR::MAU::Action*>;

class DarkInitPrimitive;
class DarkInitEntry;
class Field;
class AllocContext;

class AllocSlice {
    const PHV::Field* field_i;
    PHV::Container container_i;
    int field_bit_lo_i;
    int container_bit_lo_i;
    int width_i;
    ActionSet init_points_i;
    PHV::StageAndAccess min_stage_i;
    PHV::StageAndAccess max_stage_i;
    std::unique_ptr<DarkInitPrimitive> init_i;

    // true if the alloc is copied from an alias destination alloc that requires an always run
    // in the final stage.
    bool shadow_always_run_i = false;

    bool has_meta_init_i = false;

    // true if all stageAndAccess vars are generated from physical_live_range, i.e.,
    // min_stage_i and max_stage_i are based on physical stage info instead of min_stages.
    bool is_physical_stage_based_i = false;

    // After FinalizeStageAllocation set to true for assembly generation
    bool physical_deparser_stage_i = false;

 public:
    AllocSlice(const PHV::Field* f, PHV::Container c, int f_bit_lo, int container_bit_lo,
               int width);
    AllocSlice(const PHV::Field* f, PHV::Container c, int f_bit_lo, int container_bit_lo, int width,
               ActionSet action);
    AllocSlice(const PHV::Field* f, PHV::Container c, le_bitrange f_slice,
               le_bitrange container_slice);

    AllocSlice(const AllocSlice& a);
    AllocSlice& operator=(const AllocSlice& a);
    AllocSlice(AllocSlice&&) = default;
    AllocSlice& operator=(AllocSlice&&) = default;

    bool operator==(const AllocSlice& other) const;
    bool operator!=(const AllocSlice& other) const;
    bool operator<(const AllocSlice& other) const;

    // returns a cloned AllocSlice split by field[start:start+ len - 1].
    // by_field indicates that @p start and @p len are applied on field.
    // e.g.
    // alloc_slice: container[5:28] <= f1[0:23]
    // ^^^.sub_alloc_by_field(3,6) returns
    // alloc_slice: container[8:13] <= f1[3:8]
    boost::optional<AllocSlice> sub_alloc_by_field(int start, int len) const;

    const PHV::Field* field() const         { return field_i; }
    PHV::Container container() const        { return container_i; }
    le_bitrange field_slice() const         { return StartLen(field_bit_lo_i, width_i); }
    le_bitrange container_slice() const     { return StartLen(container_bit_lo_i, width_i); }
    int width() const                       { return width_i; }
    const DarkInitPrimitive* getInitPrimitive() const { return init_i.get(); }
    DarkInitPrimitive* getInitPrimitive() { return init_i.get(); }
    const PHV::StageAndAccess& getEarliestLiveness() const { return min_stage_i; }
    const PHV::StageAndAccess& getLatestLiveness() const { return max_stage_i; }

    bool hasInitPrimitive() const;

    // @returns true is this alloc slice is live at @p stage for @p use.
    bool isLiveAt(int stage, const PHV::FieldUse& use) const;

    // @returns true if @p other and this AllocSlice have disjoint live ranges.
    bool isLiveRangeDisjoint(const AllocSlice& other) const;

    bool representsSameFieldSlice(const AllocSlice& other) const {
        if (field_i != other.field()) return false;
        if (field_slice() != other.field_slice()) return false;
        if (width_i != other.width()) return false;
        return true;
    }

    bool extends_live_range(const AllocSlice& other) const {
        if ((min_stage_i.first < other.getEarliestLiveness().first) ||
            (max_stage_i.first > other.getLatestLiveness().first) ||
            ((min_stage_i.first == other.getEarliestLiveness().first) &&
             (min_stage_i.second < other.getEarliestLiveness().second)) ||
            ((max_stage_i.first == other.getLatestLiveness().first) &&
             (max_stage_i.second > other.getLatestLiveness().second)))
            return true;
        return false;
    }

    void setLiveness(const StageAndAccess& min, const StageAndAccess& max) {
        min_stage_i = std::make_pair(min.first, min.second);
        max_stage_i = std::make_pair(max.first, max.second);
    }

    void setLatestLiveness(const StageAndAccess& max) {
        max_stage_i = std::make_pair(max.first, max.second);
    }

    void setEarliestLiveness(const StageAndAccess& min) {
        min_stage_i = std::make_pair(min.first, min.second);
    }

    void setInitPrimitive(DarkInitPrimitive* prim);

    bool hasMetaInit() const { return has_meta_init_i; }
    void setMetaInit() { has_meta_init_i = true; }
    const ActionSet& getInitPoints() const { return init_points_i; }
    void setInitPoints(const ActionSet init_points) { init_points_i = init_points; }
    void setShadowAlwaysRun(bool val) { shadow_always_run_i = val; }
    bool getShadowAlwaysRun() const { return shadow_always_run_i; }

    bool isUsedDeparser() const;
    bool isUsedParser() const;

    bool isPhysicalStageBased() const { return is_physical_stage_based_i; }
    void setIsPhysicalStageBased(bool v) { is_physical_stage_based_i = v; }

    bool isPhysicalDeparserStage() const { return physical_deparser_stage_i; }
    void setPhysicalDeparserStage(bool v) { physical_deparser_stage_i = v; }

    // @returns true if this alloc slice is referenced within @p ctxt for @p use.
    bool isReferenced(const PHV::AllocContext* ctxt, const PHV::FieldUse* use) const;

 private:
    // helpers to get id of parde units for StageAndAccess. Depending on is_physical_live_i,
    // stage indexes of parser and deparser are different.
    int parser_stage_idx() const;
    int deparser_stage_idx() const;
};

class DarkInitPrimitive {
 private:
     bool assignZeroToDestination;
     bool nop;
     boost::optional<AllocSlice> sourceSlice;
     bool alwaysInitInLastMAUStage;
     bool alwaysRunActionPrim;
     ActionSet actions;
     ordered_set<const IR::BFN::Unit*> priorUnits;   // Hold units of prior overlay slice
     ordered_set<const IR::BFN::Unit*> postUnits;   // Hold units of post overlay slice
     std::vector<PHV::DarkInitEntry*> priorPrims;  // Hold prior ARA prims
     std::vector<PHV::DarkInitEntry*> postPrims;  // Hold post ARA prims

 public:
     DarkInitPrimitive(void)
         : assignZeroToDestination(false), nop(false), sourceSlice(boost::none),
         alwaysInitInLastMAUStage(false), alwaysRunActionPrim(false) { }

     explicit DarkInitPrimitive(ActionSet initPoints)
         : assignZeroToDestination(true), nop(false), sourceSlice(boost::none),
         alwaysInitInLastMAUStage(false), alwaysRunActionPrim(false), actions(initPoints) { }

     explicit DarkInitPrimitive(PHV::AllocSlice& src)
         : assignZeroToDestination(false), nop(false), sourceSlice(src),
         alwaysInitInLastMAUStage(false), alwaysRunActionPrim(false) { }

    explicit DarkInitPrimitive(PHV::AllocSlice& src, ActionSet initPoints)
         : assignZeroToDestination(false), nop(false), sourceSlice(src),
         alwaysInitInLastMAUStage(false), alwaysRunActionPrim(false), actions(initPoints) { }

     explicit DarkInitPrimitive(const DarkInitPrimitive& other)
         : assignZeroToDestination(other.assignZeroToDestination),
         nop(other.nop),
         sourceSlice(other.getSourceSlice()),
         alwaysInitInLastMAUStage(other.alwaysInitInLastMAUStage),
         alwaysRunActionPrim(other.alwaysRunActionPrim),
         actions(other.actions),
         priorUnits(other.priorUnits),
         postUnits(other.postUnits),
         priorPrims(other.priorPrims),
         postPrims(other.postPrims) { }

    bool operator==(const PHV::DarkInitPrimitive& other) const {
        bool zero2dest = (assignZeroToDestination == other.assignZeroToDestination);
        bool isNop = (nop == other.nop);
        bool srcSlc = false;
        if (!sourceSlice && !other.sourceSlice)
            srcSlc = true;
        if (sourceSlice && other.sourceSlice)
            srcSlc = (sourceSlice == other.sourceSlice);
        bool initLstStg  = (alwaysInitInLastMAUStage == other.alwaysInitInLastMAUStage);
        bool araPrim = (alwaysRunActionPrim == other.alwaysRunActionPrim);
        bool acts = (actions == other.actions);
        bool rslt = zero2dest && isNop && srcSlc && initLstStg && araPrim && acts;

        LOG7("\t op==" << rslt << " <-- " << zero2dest << " " << isNop << " " << srcSlc <<
             " " << initLstStg << " " << araPrim << " " << acts);

        return rslt;
     }

     bool isEmpty() const {
         if (!nop && sourceSlice == boost::none && !assignZeroToDestination)
             return true;
         return false;
     }

     void addSource(AllocSlice sl) {
         assignZeroToDestination = false;
         sourceSlice = sl;
     }

     void setNop() {
         nop = true;
         sourceSlice = boost::none;
         assignZeroToDestination = false;
     }

     void addPriorUnits(const ordered_set<const IR::BFN::Unit*>& units, bool append = true)  {
         if (!append) {
             priorUnits.clear();
         }
         priorUnits.insert(units.begin(), units.end());
     }
     void addPostUnits(const ordered_set<const IR::BFN::Unit*>& units, bool append = true) {
         if (!append) {
             postUnits.clear();
         }
         postUnits.insert(units.begin(), units.end());
     }

     void addPriorPrims(PHV::DarkInitEntry* prims, bool append = true) {
         if (!append) {
             priorPrims.clear();
         }
         priorPrims.push_back(prims);
     }
     void addPostPrims(PHV::DarkInitEntry* prims, bool append = true) {
         if (!append) {
             postPrims.clear();
         }
         postPrims.push_back(prims);
     }

     void setLastStageAlwaysInit() { alwaysInitInLastMAUStage = alwaysRunActionPrim = true; }
     void setAlwaysRunActionPrim() { alwaysRunActionPrim = true; }
     bool isNOP() const { return nop; }
     bool destAssignedToZero() const { return assignZeroToDestination; }
     bool mustInitInLastMAUStage() const { return alwaysInitInLastMAUStage; }
     bool isAlwaysRunActionPrim() const { return alwaysRunActionPrim; }
     boost::optional<AllocSlice> getSourceSlice() const { return sourceSlice; }
     const ActionSet& getInitPoints() const { return actions; }
     const ordered_set<const IR::BFN::Unit*>& getARApriorUnits() const { return priorUnits; }
     const ordered_set<const IR::BFN::Unit*>& getARApostUnits() const { return postUnits; }
     const std::vector<PHV::DarkInitEntry*> getARApriorPrims() const { return priorPrims; }
     const std::vector<PHV::DarkInitEntry*> getARApostPrims() const { return postPrims; }
};

class DarkInitEntry {
 private:
     AllocSlice destinationSlice;
     DarkInitPrimitive initInfo;

 public:
     explicit DarkInitEntry(AllocSlice& dest) : destinationSlice(dest) { }
     explicit DarkInitEntry(AllocSlice& dest, ActionSet initPoints)
         : destinationSlice(dest), initInfo(initPoints) { }
     explicit DarkInitEntry(AllocSlice& dest, AllocSlice& src)
         : destinationSlice(dest), initInfo(src) { }
     explicit DarkInitEntry(AllocSlice& dest, AllocSlice& src, ActionSet init)
         : destinationSlice(dest), initInfo(src, init) { }
     explicit DarkInitEntry(AllocSlice dest, DarkInitPrimitive &src)
         : destinationSlice(dest), initInfo(src) { }

     void addSource(AllocSlice sl) { initInfo.addSource(sl); }
     void setNop() { initInfo.setNop(); }
     void setLastStageAlwaysInit() { initInfo.setLastStageAlwaysInit(); }
     void setAlwaysRunInit() { initInfo.setAlwaysRunActionPrim(); }
     bool isNOP() const { return initInfo.isNOP(); }
     bool destAssignedToZero() const { return initInfo.destAssignedToZero(); }
     bool mustInitInLastMAUStage() const { return initInfo.mustInitInLastMAUStage(); }
     boost::optional<AllocSlice> getSourceSlice() const { return initInfo.getSourceSlice(); }

     void addPriorUnits(const ordered_set<const IR::BFN::Unit*>& units, bool append = true) {
         initInfo.addPriorUnits(units, append);
     }
     void addPostUnits(const ordered_set<const IR::BFN::Unit*>& units, bool append = true) {
         initInfo.addPostUnits(units, append);
     }

     void addPriorPrims(PHV::DarkInitEntry* prims, bool append = true) {
         initInfo.addPriorPrims(prims, append);
     }
     void addPostPrims(PHV::DarkInitEntry* prims, bool append = true) {
         initInfo.addPostPrims(prims, append);
     }

     const ActionSet& getInitPoints() const { return initInfo.getInitPoints(); }
    const AllocSlice& getDestinationSlice() const { return destinationSlice; }
    AllocSlice getDestinationSlice() { return destinationSlice; }
    const DarkInitPrimitive& getInitPrimitive() const { return initInfo; }
    DarkInitPrimitive& getInitPrimitive() { return initInfo; }
     void setDestinationLatestLiveness(const PHV::StageAndAccess& max) {
         destinationSlice.setLatestLiveness(max);
     }
     void setDestinationEarliestLiveness(const PHV::StageAndAccess& min) {
         destinationSlice.setEarliestLiveness(min);
     }

    bool operator<(const PHV::DarkInitEntry& other) const {
        if (destinationSlice != other.getDestinationSlice())
            return destinationSlice < other.getDestinationSlice();
        if (getSourceSlice() && other.getSourceSlice() &&
            *(getSourceSlice()) != *(other.getSourceSlice()))
            return *(getSourceSlice()) < *(other.getSourceSlice());
        if (getSourceSlice() && !other.getSourceSlice())
            return true;
        return false;
    }

    bool operator==(const PHV::DarkInitEntry& other) const {
        LOG4("DarkInitEntry == : " << &destinationSlice << " <-> ");

        return
            (destinationSlice == other.getDestinationSlice()) &&
            (initInfo == other.getInitPrimitive());
    }

    bool operator!=(const PHV::DarkInitEntry& other) const {
        return !this->operator==(other);
    }
};

std::ostream &operator<<(std::ostream &out, const AllocSlice&);
std::ostream &operator<<(std::ostream &out, const AllocSlice*);
std::ostream &operator<<(std::ostream &out, const std::vector<PHV::AllocSlice>&);
std::ostream &operator<<(std::ostream &out, const DarkInitEntry&);
std::ostream &operator<<(std::ostream &out, const DarkInitPrimitive&);

}   // namespace PHV

std::ostream &operator<<(std::ostream &, const safe_vector<PHV::AllocSlice> &);

#endif  /* BF_P4C_PHV_UTILS_SLICE_ALLOC_H_ */
