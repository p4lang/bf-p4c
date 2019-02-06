#ifndef BF_P4C_PHV_UTILS_LIVE_RANGE_REPORT_H_
#define BF_P4C_PHV_UTILS_LIVE_RANGE_REPORT_H_

#include "lib/log.h"
#include "ir/ir.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/phv/phv_fields.h"

class LiveRangeReport : public Inspector {
 public:
    typedef enum use_t { READ = 1, WRITE = 2, LIVE = 4 } USE_T;
    static cstring use_type(unsigned use);

 private:
    const PhvInfo&          phv;
    const TableSummary&     alloc;
    const FieldDefUse&      defuse;

    std::map<int, int> stageToReadBits;
    std::map<int, int> stageToWriteBits;
    std::map<int, int> stageToAccessBits;
    std::map<int, int> stageToLiveBits;

    int maxStages = -1;

    profile_t init_apply(const IR::Node* root) override;

    std::map<int, unsigned> processUseDefSet(
            const FieldDefUse::LocPairSet& defuseSet,
            unsigned useDef) const;

    void setFieldLiveMap(
            const PHV::Field* f,
            ordered_map<const PHV::Field*, std::map<int, unsigned>>& livemap) const;

    cstring printFieldLiveness(
            const ordered_map<const PHV::Field*, std::map<int, unsigned>>& livemap);

    std::vector<std::string> createStatRow(
            std::string title,
            const std::map<int, int>& data) const;

    cstring printBitStats() const;

 public:
    explicit LiveRangeReport(
            const PhvInfo& p,
            const TableSummary& t,
            const FieldDefUse& d)
        : phv(p), alloc(t), defuse(d) { }
};

#endif  /*  BF_P4C_PHV_UTILS_LIVE_RANGE_REPORT_H_  */
