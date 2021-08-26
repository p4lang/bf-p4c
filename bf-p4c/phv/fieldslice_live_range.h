#ifndef EXTENSIONS_BF_P4C_PHV_FIELDSLICE_LIVE_RANGE_H_
#define EXTENSIONS_BF_P4C_PHV_FIELDSLICE_LIVE_RANGE_H_

#include "mau_backtracker.h"
#include "bf-p4c/common/field_defuse.h"
#include "mau/action_analysis.h"
#include "bf-p4c/common/map_tables_to_actions.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

namespace PHV {

struct LiveRangeInfo {
    enum OpInfo {
        DEAD,
        READ,
        WRITE,
        READ_WRITE,
        LIVE
    };
    OpInfo live_on_parser;
    OpInfo live_on_deparser;
    std::vector<OpInfo> live_on_stage;
    PHV::FieldSlice fs;
    bool is_live_at(int stage) const;
    explicit LiveRangeInfo(const PHV::FieldSlice& fs_):
        live_on_stage(Device::numStages(), OpInfo::DEAD) {
        live_on_parser = DEAD;
        live_on_deparser = DEAD;
        fs = fs_;
    }
    LiveRangeInfo() {}
};

LiveRangeInfo::OpInfo operator||(const LiveRangeInfo::OpInfo&, const LiveRangeInfo::OpInfo&);

std::ostream &operator<<(std::ostream &out, const LiveRangeInfo& info);

class IFieldSliceLiveRangeDB {
 public:
    virtual bool is_initialized() const = 0;
    virtual void set_liverange(const PHV::FieldSlice &, const LiveRangeInfo &) = 0;
    virtual boost::optional<LiveRangeInfo> get_liverange(const PHV::FieldSlice &) const = 0;
};

class FieldSliceLiveRangeDB : public IFieldSliceLiveRangeDB, public PassManager  {
    class MapFieldSliceToAction : public Inspector {
        const PhvInfo& phv;
        Visitor::profile_t init_apply(const IR::Node *root) override;

     public:
        /// Any OperandInfo (Field) within the set will have been written in the
        /// key action.
        ordered_map<const IR::MAU::Action *, ordered_set<PHV::FieldSlice>> action_to_writes;

        /// Any OperandInfo (Field) within the set will have been read in the
        /// key action.
        ordered_map<const IR::MAU::Action *, ordered_set<PHV::FieldSlice>> action_to_reads;

        bool preorder(const IR::MAU::Action *act) override;
        explicit MapFieldSliceToAction(const PhvInfo& phv) : phv(phv){}
    };

    class DBSetter : public Inspector {
        struct Location {
            enum unit {
                PARSER,
                TABLE,
                DEPARSER
            };
            unit u;
            ordered_set<int> stages;
        };
        const MauBacktracker *backtracker;
        const FieldDefUse *defuse;
        const MapFieldSliceToAction *fs_action_map;
        FieldSliceLiveRangeDB &self;
        /// List of fields that are marked as not parsed.
        const ordered_set<const PHV::Field*> &notParsedFields;
        /// List of fields that are marked as not deparsed.
        const ordered_set<const PHV::Field*> &notDeparsedFields;
        void update_live_range_info(
            const PHV::FieldSlice&, Location&, Location&, ordered_map<FieldSlice, LiveRangeInfo>&);

     public:
        DBSetter(
            const MauBacktracker *backtracker,
            const FieldDefUse *defuse,
            const MapFieldSliceToAction *fs_action_map,
            FieldSliceLiveRangeDB &self,
            const PHV::Pragmas& pragmas):
            backtracker(backtracker),
            defuse(defuse),
            fs_action_map(fs_action_map),
            self(self),
            notParsedFields(pragmas.pa_deparser_zero().getNotParsedFields()),
            notDeparsedFields(pragmas.pa_deparser_zero().getNotDeparsedFields())
            {}
        // a entry point to calculate the physical live range
        void end_apply() override;
    };

    MapFieldSliceToAction *fs_action_map;
    DBSetter *setter;

    ordered_map<const PHV::Field*, ordered_map<PHV::FieldSlice, LiveRangeInfo>> live_range_map;
    bool initialized = false;
    Visitor::profile_t init_apply(const IR::Node *root) override;

 public:
    FieldSliceLiveRangeDB(
        const MauBacktracker *backtracker,
        const FieldDefUse *defuse,
        const PhvInfo& phv,
        const PHV::Pragmas& pragmas
    ) {
        fs_action_map = new MapFieldSliceToAction(phv);
        setter = new DBSetter(
            backtracker, defuse, fs_action_map, *this, pragmas);
        addPasses({
            fs_action_map,
            setter
        });
        initialized = true;
    }
    void set_liverange(const PHV::FieldSlice&, const LiveRangeInfo&) override;
    boost::optional<LiveRangeInfo> get_liverange(const PHV::FieldSlice&) const;
    bool is_initialized() const { return initialized; }
};

}  // namespace PHV

#endif  /* EXTENSIONS_BF_P4C_PHV_FIELDSLICE_LIVE_RANGE_H_ */
