#ifndef BF_P4C_MAU_HASH_FUNCTION_H_
#define BF_P4C_MAU_HASH_FUNCTION_H_

struct bfn_hash_algorithm_;

namespace IR {
namespace MAU {

struct HashFunction {
    Util::SourceInfo    srcInfo;
    enum { IDENTITY, CSUM, XOR, CRC, RANDOM }
                        type = IDENTITY;
    bool                msb = false;      // pull msbs for slice
    bool                extend = false;
    bool                reverse = false;  // crc reverse bits
    int                 size = 0;
    uint64_t            poly = 0;         // crc polynomial in koopman form (poly-1)/2
    uint64_t            init = 0;
    uint64_t            final_xor = 0;
    bool                ordered = false;

    bool operator==(const HashFunction &a) const {
        return type == a.type && size == a.size && msb == a.msb && reverse == a.reverse &&
               poly == a.poly && init == a.init && final_xor == a.final_xor; }
    bool operator!=(const HashFunction &a) const { return !(*this == a); }
    void toJSON(JSONGenerator &json) const;
    static HashFunction *fromJSON(JSONLoader &);
    bool setup(const IR::Expression *exp);
    bool convertPolynomialExtern(const IR::GlobalRef *);
    static HashFunction identity() {
        HashFunction rv;
        rv.type = IDENTITY;
        return rv; }
    static HashFunction random() {
        HashFunction rv;
        rv.type = RANDOM;
        return rv; }
    bool size_from_algorithm() const {
        if (type == CRC)
            return true;
        return false;
    }

    std::string name() const {
        std::string algo_name = "";
        if (type == IDENTITY) {
            algo_name = "identity";
        } else if (type == CRC) {
            algo_name = "crc_" + std::to_string(size);
        } else if (type == RANDOM) {
            algo_name = "random";
        } else if (type == XOR) {
            algo_name = "xor";
        }
        return algo_name;
    }

    std::string algo_type() const {
        std::string algo_type = "";
        if (type == IDENTITY) {
            algo_type = "identity";
        } else if (type == CRC) {
            algo_type = "crc";
        } else if (type == RANDOM) {
            algo_type = "random";
        } else if (type == XOR) {
            algo_type = "xor";
        }
        return algo_type;
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

std::ostream &operator<<(std::ostream &, const IR::MAU::HashFunction &);

#endif /* BF_P4C_MAU_HASH_FUNCTION_H_ */
