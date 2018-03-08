#ifndef BF_P4C_MAU_HASH_FUNCTION_H_
#define BF_P4C_MAU_HASH_FUNCTION_H_

namespace IR {
namespace MAU {

struct hash_function {
    Util::SourceInfo    srcInfo;
    enum { IDENTITY, CSUM, XOR, CRC, RANDOM }
                        type = IDENTITY;
    int                 size = 0;
    bool                msb = false;      // pull msbs for slice
    bool                reverse = false;  // crc reverse bits
    uint64_t            poly = 0;         // crc polynoimal in koopman form (poly-1)/2
    uint64_t            init = 0;
    uint64_t            final_xor = 0;

    bool operator==(const hash_function &a) const {
        return type == a.type && size == a.size && msb == a.msb && reverse == a.reverse &&
               poly == a.poly && init == a.init && final_xor == a.final_xor; }
    void toJSON(JSONGenerator &json) const;
    static hash_function *fromJSON(JSONLoader &);
    bool setup(const IR::Expression *exp);
    static hash_function identity() {
        hash_function rv;
        rv.type = IDENTITY;
        return rv; }
    static hash_function random() {
        hash_function rv;
        rv.type = RANDOM;
        return rv; }
};

}  // end namespace MAU
}  // end namespace IR

std::ostream &operator<<(std::ostream &, const IR::MAU::hash_function &);

#endif /* BF_P4C_MAU_HASH_FUNCTION_H_ */
