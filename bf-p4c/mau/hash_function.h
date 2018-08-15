#ifndef BF_P4C_MAU_HASH_FUNCTION_H_
#define BF_P4C_MAU_HASH_FUNCTION_H_

struct bfn_hash_algorithm_;

namespace IR {
namespace MAU {

struct hash_function {
    Util::SourceInfo    srcInfo;
    enum { IDENTITY, CSUM, XOR, CRC, RANDOM }
                        type = IDENTITY;
    bool                msb = false;      // pull msbs for slice
    bool                extend = false;
    bool                reverse = false;  // crc reverse bits
    int                 size = 0;
    uint64_t            poly = 0;         // crc polynoimal in koopman form (poly-1)/2
    uint64_t            init = 0;
    uint64_t            final_xor = 0;
    bool                ordered = false;

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
    bool size_from_algorithm() const {
        if (type == CRC)
            return true;
        return false;
    }

 private:
    const IR::MethodCallExpression *hash_to_mce(const IR::Expression *, bool *on_hash_matrix);

 public:
    void build_algorithm_t(bfn_hash_algorithm_ *) const;
    static const IR::Expression *convertHashAlgorithmBFN(Util::SourceInfo srcInfo,
        IR::ID algorithm, bool *on_hash_matrix);
};

}  // end namespace MAU
}  // end namespace IR

std::ostream &operator<<(std::ostream &, const IR::MAU::hash_function &);

#endif /* BF_P4C_MAU_HASH_FUNCTION_H_ */
