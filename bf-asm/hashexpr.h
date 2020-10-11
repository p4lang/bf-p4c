#ifndef BF_ASM_HASHEXPR_H_
#define BF_ASM_HASHEXPR_H_

#include "phv.h"
#include "dynamic_hash/dynamic_hash.h"

class InputXbar;

class HashExpr {
    class PhvRef;
    class Random;
    class Crc;
    class Xor;
    class Mask;
    class Stripe;
    class Slice;
    class SExtend;
 protected:
    explicit HashExpr(int l) : lineno(l) {}

 public:
    int lineno;
    bfn_hash_algorithm_t hash_algorithm;
    static HashExpr *create(gress_t, int stage, const value_t &);
    virtual void build_algorithm() = 0;
    virtual bool check_ixbar(InputXbar *ix, int grp) = 0;
    virtual void gen_data(bitvec &data, int bit, InputXbar *ix, int grp);
    void gen_ixbar_init(ixbar_init_t *ixbar_init, std::vector<ixbar_input_t> &inputs,
        std::vector<hash_matrix_output_t> &outputs, int logical_hash_bit, InputXbar *ix,
        int hash_table);
    virtual void gen_ixbar_inputs(std::vector<ixbar_input_t> &inputs, InputXbar *ix,
        int hash_table) = 0;
    virtual int width() = 0;
    virtual int input_size() = 0;
    virtual bool match_phvref(Phv::Ref &ref) { return false; }
    virtual bool operator==(const HashExpr &) const = 0;
    void find_input(Phv::Ref what, std::vector<ixbar_input_t> &inputs, InputXbar *ix,
        int hash_table);
    bool operator!=(const HashExpr &a) const { return !operator==(a); }
    virtual void dbprint(std::ostream & out) const {}
    virtual Phv::Ref *get_ghost_slice() { return nullptr; }
    virtual ~HashExpr() {}
};

#endif /* BF_ASM_HASHEXPR_H_ */
