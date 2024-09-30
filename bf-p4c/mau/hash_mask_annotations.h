#ifndef EXTENSIONS_BF_P4C_MAU_HASH_MASK_ANNOTATIONS_H_
#define EXTENSIONS_BF_P4C_MAU_HASH_MASK_ANNOTATIONS_H_

#include "ir/ir.h"
#include "lib/bitvec.h"
#include "bf-p4c/phv/phv_fields.h"

/// Helper class to handle the @hash_mask() annotation.
class HashMaskAnnotations {
 public:
    HashMaskAnnotations(const P4::IR::MAU::Table *tbl, const PhvInfo &phv) {
        key_hash_bits_masked = 0;
        for (auto &table_key : tbl->match_key) {
            for (auto &a : table_key->annotations->annotations) {
                if (a->name == "hash_mask") {
                    bitvec hash_mask = getBitvec(a);

                    le_bitrange bits = { 0, 0 };
                    const PHV::Field *field = phv.field(table_key->expr, &bits);
                    if (field) {
                        int masked = hash_mask.popcount();
                        if (masked > bits.size())
                            masked = bits.size();
                        key_hash_bits_masked += (bits.size() - masked);
                    }

                    const P4::IR::Member *m = table_key->expr->to<P4::IR::Member>();
                    if (m != nullptr)
                        key_hash_masks[m->toString()] = hash_mask;
                    break;
                }
            }
        }
        if (LOGGING(5)) {
            LOG5("Hash mask annotations for table " << tbl->name << ":");
            for (auto &m : key_hash_masks)
                LOG5("  " << m.first << " : 0x" << std::hex << m.second);
        }
    }

    std::map<cstring, bitvec> hash_masks() { return key_hash_masks; }

    int hash_bits_masked() { return key_hash_bits_masked; }

 private:
    bitvec getBitvec(const P4::IR::Annotation* annotation) {
        bitvec rv;
        if (annotation->expr.size() != 1) {
            ::P4::error("%1% should contain a constant", annotation);
            return rv;
        }
        auto constant = annotation->expr[0]->to<P4::IR::Constant>();
        if (constant == nullptr) {
            ::P4::error("%1% should contain a constant", annotation);
            return rv;
        }
        int64_t c = constant->asUint64();
        rv.setraw(c);
        return rv;
    }

    // Vector of match keys annotated with @hash_mask()
    // along with their associated mask.
    std::map<cstring, bitvec> key_hash_masks;

    // Number of bits masked out with @hash_mask() throughout
    // all match keys in the table.
    int key_hash_bits_masked;
};

#endif /* EXTENSIONS_BF_P4C_MAU_HASH_MASK_ANNOTATIONS_H_ */
