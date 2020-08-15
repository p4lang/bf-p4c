#ifndef BF_P4C_PHV_ASM_OUTPUT_H_
#define BF_P4C_PHV_ASM_OUTPUT_H_

#include <iosfwd>
#include "lib/ordered_set.h"

#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/live_range_report.h"

class PhvAsmOutput {
    const PhvInfo     &phv;
    const FieldDefUse &defuse;
    const TableSummary &tbl_summary;
    const LiveRangeReport *live_range_report;
    bool have_ghost;

    struct FieldUse {
        cstring name;
        gress_t gress;
        int live_start;
        int live_end;
        ordered_set<cstring> mutex_fields;
        FieldUse(cstring n, gress_t g, int s, int e, ordered_set<cstring> m)
            : name(n), gress(g), live_start(s), live_end(e), mutex_fields(m) {}
        std::string get_live_stage(int stage, int maxStages) {
            if (stage == -1) return "parser";
            if (stage == maxStages) return "deparser";
            return std::to_string(stage);
        }
        std::string get_live_start(int maxStages) {
            return get_live_stage(live_start, maxStages);
        }
        std::string get_live_end(int maxStages) {
            return get_live_stage(live_end, maxStages);
        }
    };

    /// Populate liveRanges.
    typedef ordered_map<cstring, std::vector<FieldUse>> FieldUses;
    typedef std::map<PHV::Container, FieldUses> LiveRangePerContainer[2];
    void getLiveRanges(LiveRangePerContainer& c) const;

    void emit_gress(std::ostream& out, gress_t gress) const;
    friend std::ostream &operator<<(std::ostream &, const PhvAsmOutput &);

    std::map<int, PHV::FieldUse>
    processUseDefSet(const FieldDefUse::LocPairSet&, PHV::FieldUse) const;

 public:
    explicit PhvAsmOutput(const PhvInfo &p, const FieldDefUse& defuse,
                          const TableSummary& tbl_summary,
                          const LiveRangeReport* live_range_report, bool have_ghost = false);
};

#endif /* BF_P4C_PHV_ASM_OUTPUT_H_ */
