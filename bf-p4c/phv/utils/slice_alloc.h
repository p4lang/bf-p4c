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
class Field;

class AllocSlice {
    const PHV::Field* field_i;
    PHV::Container container_i;
    int field_bit_lo_i;
    int container_bit_lo_i;
    int width_i;
    ActionSet init_points_i;
    PHV::StageAndAccess min_stage_i;
    PHV::StageAndAccess max_stage_i;
    DarkInitPrimitive* init_i;

    // true if the alloc is copied from an alias destination alloc that requires an always run
    // in the final stage.
    bool shadow_always_run_i = false;

    bool has_meta_init_i = false;

 public:
    AllocSlice(const PHV::Field* f, PHV::Container c, int f_bit_lo, int container_bit_lo,
               int width);
    AllocSlice(const PHV::Field* f, PHV::Container c, int f_bit_lo, int container_bit_lo, int width,
               ActionSet action);
    AllocSlice(const PHV::Field* f, PHV::Container c, le_bitrange f_slice,
               le_bitrange container_slice);
    AllocSlice(const AllocSlice& a);

    bool operator==(const AllocSlice& other) const;
    bool operator!=(const AllocSlice& other) const;
    bool operator<(const AllocSlice& other) const;

    const PHV::Field* field() const         { return field_i; }
    PHV::Container container() const        { return container_i; }
    le_bitrange field_slice() const         { return StartLen(field_bit_lo_i, width_i); }
    le_bitrange container_slice() const     { return StartLen(container_bit_lo_i, width_i); }
    int width() const                       { return width_i; }
    const DarkInitPrimitive* getInitPrimitive() const { return init_i; }
    DarkInitPrimitive* getInitPrimitive() { return init_i; }
    const PHV::StageAndAccess& getEarliestLiveness() const { return min_stage_i; }
    const PHV::StageAndAccess& getLatestLiveness() const { return max_stage_i; }

    bool hasInitPrimitive() const;

    bool isLiveAt(int stage, unsigned access) const {
        PHV::FieldUse use(access);
        if (stage > min_stage_i.first && stage < max_stage_i.first)
            return true;
        if (stage == min_stage_i.first && use >= min_stage_i.second)
            return true;
        if (stage == max_stage_i.first && use <= max_stage_i.second)
            return true;
        return false;
    }

    bool isLiveRangeDisjoint(const AllocSlice& other) const;
    bool representsSameFieldSlice(const AllocSlice& other) const {
        if (field_i != other.field()) return false;
        if (field_slice() != other.field_slice()) return false;
        if (width_i != other.width()) return false;
        return true;
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

    void setInitPrimitive(DarkInitPrimitive* prim) {
        init_i = prim;
    }

    bool hasMetaInit() const { return has_meta_init_i; }
    void setMetaInit() { has_meta_init_i = true; }
    const ActionSet& getInitPoints() const { return init_points_i; }
    void setInitPoints(const ActionSet init_points) { init_points_i = init_points; }
    void setShadowAlwaysRun(bool val) { shadow_always_run_i = val; }
    bool getShadowAlwaysRun() const { return shadow_always_run_i; }

    bool isUsedDeparser() const;
    bool isUsedParser() const;
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

 public:
     DarkInitPrimitive(void)
         : assignZeroToDestination(false), nop(false), sourceSlice(boost::none),
         alwaysInitInLastMAUStage(false), alwaysRunActionPrim(false) { }

     explicit DarkInitPrimitive(ActionSet initPoints)
         : assignZeroToDestination(true), nop(false), sourceSlice(boost::none),
         alwaysInitInLastMAUStage(false), alwaysRunActionPrim(false), actions(initPoints) { }

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
         postUnits(other.postUnits) { }

     bool operator==(const DarkInitPrimitive& other) const {
         return assignZeroToDestination == other.assignZeroToDestination &&
                nop == other.nop &&
                sourceSlice == other.sourceSlice &&
                alwaysInitInLastMAUStage == other.alwaysInitInLastMAUStage &&
                alwaysRunActionPrim == other.alwaysRunActionPrim &&
                actions == other.actions;
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
     void setLastStageAlwaysInit() { alwaysInitInLastMAUStage = alwaysRunActionPrim = true; }
     bool isNOP() const { return nop; }
     bool destAssignedToZero() const { return assignZeroToDestination; }
     bool mustInitInLastMAUStage() const { return alwaysInitInLastMAUStage; }
     bool isAlwaysRunActionPrim() const { return alwaysRunActionPrim; }
     boost::optional<AllocSlice> getSourceSlice() const { return sourceSlice; }
     const ActionSet& getInitPoints() const { return actions; }
     const ordered_set<const IR::BFN::Unit*>& getARApriorUnits() const { return priorUnits; }
     const ordered_set<const IR::BFN::Unit*>& getARApostUnits() const { return postUnits; }
};

class DarkInitEntry {
 private:
     AllocSlice destinationSlice;
     DarkInitPrimitive initInfo;

 public:
     explicit DarkInitEntry(AllocSlice& dest) : destinationSlice(dest) { }
     explicit DarkInitEntry(AllocSlice& dest, ActionSet initPoints)
         : destinationSlice(dest), initInfo(initPoints) { }
     explicit DarkInitEntry(AllocSlice& dest, AllocSlice& src, ActionSet init)
         : destinationSlice(dest), initInfo(src, init) { }

     void addSource(AllocSlice sl) { initInfo.addSource(sl); }
     void setNop() { initInfo.setNop(); }
     void setLastStageAlwaysInit() { initInfo.setLastStageAlwaysInit(); }
     bool isNOP() const { return initInfo.isNOP(); }
     bool destAssignedToZero() const { return initInfo.destAssignedToZero(); }
     bool mustInitInLastMAUStage() const { return initInfo.mustInitInLastMAUStage(); }
     boost::optional<AllocSlice> getSourceSlice() { return initInfo.getSourceSlice(); }
     void addPriorUnits(const ordered_set<const IR::BFN::Unit*>& units, bool append = true) {
         initInfo.addPriorUnits(units, append);
     }
     void addPostUnits(const ordered_set<const IR::BFN::Unit*>& units, bool append = true) {
         initInfo.addPostUnits(units, append);
     }
     const ActionSet& getInitPoints() const { return initInfo.getInitPoints(); }
     const AllocSlice getDestinationSlice() const { return destinationSlice; }
     AllocSlice getDestinationSlice() { return destinationSlice; }
     const DarkInitPrimitive& getInitPrimitive() const { return initInfo; }
     DarkInitPrimitive& getInitPrimitive() { return initInfo; }
     void setDestinationLatestLiveness(const PHV::StageAndAccess& max) {
         destinationSlice.setLatestLiveness(max);
     }
     void setDestinationEarliestLiveness(const PHV::StageAndAccess& min) {
         destinationSlice.setEarliestLiveness(min);
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
