#ifndef BF_P4C_MAU_FLATROCK_ACTION_DATA_BUS_H_
#define BF_P4C_MAU_FLATROCK_ACTION_DATA_BUS_H_

#include "bf-p4c/mau/action_data_bus.h"
#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/mau/action_format.h"
#include "lib/alloc.h"
#include "lib/autoclone.h"
#include "lib/safe_vector.h"
#include "bf-p4c/common/alloc.h"

namespace Flatrock {

struct ActionDataBus : public ::ActionDataBus {
    static constexpr int ABUS32 = 48;  // Bytes for 32-bit slots in ing/egr ADB
    static constexpr int ABUS8 = 16;   // Bytes for  8-bit slots in ing/egr ADB
    static constexpr int MAX_ADB_BYTES = ABUS8 + ABUS32;  // total number of bytes on ADB
    static constexpr int ACTION_UNITS = 4;
    static constexpr int ALUS_PER_ACTION_UNIT = 2;
    static constexpr int SALU_UNITS = 4;
    static constexpr int METER_UNITS = 2;
    static constexpr int STATS_UNITS = 2;
    static constexpr int XCMP_UNITS = 1;
    static constexpr int IMMEDIATE_BYTES_START = 0;        // Immediate bytes location on byte ADB
    static constexpr int IMMEDIATE_BYTES_END = ABUS8 - 1;
    static constexpr int WORD_BYTES_START = ABUS8;         // Word bytes location on word ADB
    static constexpr int WORD_BYTES_END = (ABUS8 + ABUS32) - 1;

 private:
    BFN::Alloc1D<cstring, MAX_ADB_BYTES> total_use;
    bitvec total_in_use;  // duplicates total_use (1 bit per byte)
    BFN::Alloc2D<cstring, ACTION_UNITS, ALUS_PER_ACTION_UNIT> action_alu_use;

    struct Use : public ::ActionDataBus::Use {
        Use *clone() const override { return new Use(*this); }
        bool emit_adb_asm(std::ostream &, const IR::MAU::Table *, bitvec source) const override;
        int rng_unit() const override { return -1; }

        safe_vector<std::pair<int, int>>        action_alus;
    };

    static Use &getUse(autoclone_ptr<::ActionDataBus::Use> &ac);
    int find_free_words(bitvec bits, size_t align, int *slots);
    int find_free_bytes(const IR::MAU::Table *tbl, const ActionData::ALUPosition *pos,
            safe_vector<Use::ReservedSpace> &action_data_locs, ActionData::Location_t loc);

 public:
    void clear() override;
    bool alloc_action_data_bus(const IR::MAU::Table *tbl,
                               safe_vector<const ActionData::ALUPosition *> &alu_ops,
                               TableResourceAlloc &alloc);
    bool alloc_action_data_bus(const IR::MAU::Table *tbl, const ActionData::Format::Use *use,
                               TableResourceAlloc &alloc) override;
    bool alloc_action_data_bus(const IR::MAU::Table *tbl, const MeterALU::Format::Use *use,
                               TableResourceAlloc &alloc) override;
    void update(cstring name, const ::ActionDataBus::Use &) override;
    void update(cstring name, const Use::ReservedSpace &rs) override;
    void update(const IR::MAU::Table *tbl) override;
    std::string get_total_in_use() const;

    virtual std::unique_ptr<::ActionDataBus> clone() const;
};

}  // end namespace Flatrock

#endif /* BF_P4C_MAU_FLATROCK_ACTION_DATA_BUS_H_*/
