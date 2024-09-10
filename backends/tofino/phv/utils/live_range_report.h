#ifndef BF_P4C_PHV_UTILS_LIVE_RANGE_REPORT_H_
#define BF_P4C_PHV_UTILS_LIVE_RANGE_REPORT_H_

#include "lib/log.h"
#include "ir/ir.h"
#include "backends/tofino/common/field_defuse.h"
#include "backends/tofino/mau/table_summary.h"
#include "backends/tofino/phv/phv.h"
#include "backends/tofino/phv/phv_fields.h"

class LiveRangeReport : public Inspector {
 private:
    static constexpr unsigned READ = PHV::FieldUse::READ;
    static constexpr unsigned WRITE = PHV::FieldUse::WRITE;
    static constexpr unsigned LIVE = PHV::FieldUse::LIVE;

    const PhvInfo&          phv;
    const TableSummary&     alloc;
    const FieldDefUse&      defuse;

    std::map<int, int> stageToReadBits;
    std::map<int, int> stageToWriteBits;
    std::map<int, int> stageToAccessBits;
    std::map<int, int> stageToLiveBits;

    int maxStages = -1;

    typedef ordered_map<const PHV::Field*, std::map<int, PHV::FieldUse>> LiveMap;
    LiveMap livemap;

    std::map<const PHV::Field*, const PHV::Field*> aliases;

    profile_t init_apply(const IR::Node* root) override;

    std::map<int, PHV::FieldUse> processUseDefSet(
            const FieldDefUse::LocPairSet& defuseSet,
            PHV::FieldUse useDef) const;

    void setFieldLiveMap(const PHV::Field* f);


    std::vector<std::string> createStatRow(
            std::string title,
            const std::map<int, int>& data) const;

    cstring printFieldLiveness();
    cstring printBitStats() const;
    cstring printAliases() const;

 public:
    explicit LiveRangeReport(
            const PhvInfo& p,
            const TableSummary& t,
            const FieldDefUse& d)
        : phv(p), alloc(t), defuse(d) { }

    const LiveMap& get_livemap() const { return livemap; }
    int get_max_stages() const { return maxStages; }
};

#endif  /*  BF_P4C_PHV_UTILS_LIVE_RANGE_REPORT_H_  */
