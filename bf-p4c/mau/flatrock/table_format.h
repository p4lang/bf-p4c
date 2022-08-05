#ifndef BF_P4C_MAU_FLATROCK_TABLE_FORMAT_H_
#define BF_P4C_MAU_FLATROCK_TABLE_FORMAT_H_

#include "bf-p4c/mau/table_format.h"

namespace Flatrock {
struct TableFormat : ::TableFormat {
    static constexpr int LOCAL_TIND_OVERHEAD_BITS = 32;

    void classify_match_bits() override;
    bool allocate_sram_match() override;
    bool allocate_match_byte(const ByteInfo &info, safe_vector<ByteInfo> &alloced, int width_sect,
        bitvec &byte_attempt, bitvec &bit_attempt) override;
    bool allocate_match_with_algorithm(int group);
    void find_bytes_to_allocate(int width_sect, safe_vector<ByteInfo> &unalloced) override;
 public:
    TableFormat(const LayoutOption &l, const IXBar::Use *mi, const IXBar::Use *phi,
                const IR::MAU::Table *t, const bitvec im, bool gl, FindPayloadCandidates &fpc)
        : ::TableFormat(l, mi, phi, t, im, gl, fpc) {}
};

}  // namespace Flatrock

#endif /* BF_P4C_MAU_FLATROCK_TABLE_FORMAT_H_ */
