#ifndef BF_P4C_MAU_FLATROCK_ACTION_DATA_BUS_H_
#define BF_P4C_MAU_FLATROCK_ACTION_DATA_BUS_H_

#include "bf-p4c/mau/action_data_bus.h"
#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/mau/action_format.h"
#include "lib/alloc.h"
#include "lib/autoclone.h"
#include "lib/safe_vector.h"

namespace Flatrock {

struct ActionDataBus : public ::ActionDataBus {
    static constexpr int IABUS32 = 8;   // number of 32-bit slots in ingress action data bus
    static constexpr int IABUS8 = 32;   // number of 8-bit slots in ingress action data bus
    static constexpr int EABUS32 = 8;   // number of 32-bit slots in egress action data bus
    static constexpr int EABUS8 = 32;   // number of 8-bit slots in egress action data bus
    static int ADB_BYTES(gress_t gress) {
        return gress != EGRESS ? IABUS32*4 + IABUS8 : EABUS32*4 + EABUS8; }
    static constexpr int MAX_ADB_BYTES = 64;    // total number of bytes (max of igr/egr)
    static constexpr int ACTION_UNITS = 4;
    static constexpr int ALUS_PER_ACTION_UNIT = 2;
    static constexpr int SALU_UNITS = 4;
    static constexpr int METER_UNITS = 2;
    static constexpr int STATS_UNITS = 2;
    static constexpr int XCMP_UNITS = 1;

 private:
    Alloc1D<cstring, MAX_ADB_BYTES> adb_use;
    bitvec total_in_use;  // duplicates adb_use (1 bit per byte)
    Alloc2D<cstring, ACTION_UNITS, ALUS_PER_ACTION_UNIT> action_alu_use;

    struct Use : public ::ActionDataBus::Use {
        Use *clone() const override { return new Use(*this); }
        bool emit_adb_asm(std::ostream &, const IR::MAU::Table *, bitvec source) const override;
        int rng_unit() const override { return -1; }

        safe_vector<std::pair<int, int>>        action_alus;
    };

    static Use &getUse(autoclone_ptr<::ActionDataBus::Use> &ac);
    int find_free_words(bitvec bits, size_t align, int *slots);
    int find_free_bytes(bitvec bits, size_t align, int offset, int *slots);

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
};

}  // end namespace Flatrock

#endif /* BF_P4C_MAU_FLATROCK_ACTION_DATA_BUS_H_*/
