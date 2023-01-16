#ifndef BF_P4C_MAU_FLATROCK_TABLE_FORMAT_H_
#define BF_P4C_MAU_FLATROCK_TABLE_FORMAT_H_

#include "bf-p4c/mau/table_format.h"

namespace Flatrock {
struct TableFormat : ::TableFormat {
    static constexpr int LOCAL_TIND_OVERHEAD_BITS = 32;

    void classify_match_bits() override;
    bool allocate_sram_match() override;
    bool allocate_overhead(bool alloc_match = false) override;
    bool allocate_match_byte(const ByteInfo &info, safe_vector<ByteInfo> &alloced, int width_sect,
        bitvec &byte_attempt, bitvec &bit_attempt) override;
    bool allocate_match_with_algorithm(int group);
    void find_bytes_to_allocate(int width_sect, safe_vector<ByteInfo> &unalloced) override;
    bool requires_versioning() const override { return false; }
    bool requires_valid_bit() const override {
        return !layout_option.layout.ternary && !layout_option.layout.hash_action; }
    bool analyze_layout_option() override;
    void choose_ghost_bits(safe_vector<IXBar::Use::Byte> &potential_ghost) override;
    void allocate_full_fits(int width_sect, int group) override;
    void fill_out_use(int group, const safe_vector<ByteInfo> &alloced);
 public:
    TableFormat(const LayoutOption &l, const IXBar::Use *mi, const IXBar::Use *phi,
                const IR::MAU::Table *t, const bitvec im, bool gl, FindPayloadCandidates &fpc)
        : ::TableFormat(l, mi, phi, t, im, gl, fpc) {}
};

}  // namespace Flatrock

#endif /* BF_P4C_MAU_FLATROCK_TABLE_FORMAT_H_ */
