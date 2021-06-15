#ifndef BF_P4C_PHV_SOLVER_SYMBOLIC_BITVEC_H_
#define BF_P4C_PHV_SOLVER_SYMBOLIC_BITVEC_H_

#include <sstream>
#include <vector>
#include "lib/bitvec.h"
#include "lib/cstring.h"

namespace solver {

namespace symbolic_bitvec {

/// BitID encodes a symbolic bit
/// < 0  illegal
///   0  represents the const zero.
///   1  represents the const one.
/// > 1  represents a boolean variable.
using BitID = int;

/// base class for bit expression.
class Expr {
 public:
    // The returned expression will not have any constant value.
    virtual const Expr* eval() const = 0;
    // eq returns true ONLY when two expressions have the exact
    // same construct or are commutatively same.
    // For example
    // (A & B) & C == A & (B & C) is False,
    // (B & A) & C == (A & B) & C is True,
    // B & (A & C) == (C & A) & B is True,
    // The reason is because that we do not convert expression to
    // CNF or DNF as the worst case complexity is O(2^n), the same
    // as trying all combination of possible values for all variables.
    // This limited version of equality, with O(n) time complexity,
    // is enough for Tofino as we have at most two sources and we
    // know the order of evaluation.
    virtual bool eq(const Expr* other) const = 0;
    virtual cstring to_cstring() const = 0;
};

/// Bit can be: 0, 1 or a variable.
class Bit : public Expr {
 public:
    BitID id;
    explicit Bit(int id) : id(id) {}
    const Expr* eval() const override { return this; };
    bool eq(const Expr* other) const override;
    cstring to_cstring() const override;
};

// Logical And
class And : public Expr {
 public:
    const Expr* left;
    const Expr* right;
    And(const Expr* l, const Expr* r) : left(l), right(r) {}
    const Expr* eval() const override;
    bool eq(const Expr* other) const override;
    cstring to_cstring() const override;
};

// Logical Or
class Or : public Expr {
 public:
    const Expr* left;
    const Expr* right;
    Or(const Expr* l, const Expr* r) : left(l), right(r) {}
    const Expr* eval() const override;
    bool eq(const Expr* other) const override;
    cstring to_cstring() const override;
};

// Logical Neg
class Neg : public Expr {
 public:
    const Expr* term;
    explicit Neg(const Expr* e): term(e) {}
    const Expr* eval() const override;
    bool eq(const Expr* other) const override;
    cstring to_cstring() const override;
};

// Bitvec is a vector of Bits. The size is fixed after construction.
class BitVec {
 private:
    std::vector<const Expr*> bits;

 private:
    void size_check(const BitVec& other) const;

    template <typename T>
    BitVec bin_op(const BitVec& other) const;

 public:
    explicit BitVec(const std::vector<const Expr*>& bits) : bits(bits) {}
    void set(int i, bool value) { bits[i] = new Bit(int(value)); }
    const Expr* get(int i) const { return bits[i]; }
    BitVec slice(int start, int sz) const;
    bool eq(const BitVec& other) const;
    cstring to_cstring() const;
    BitVec bv_and(const BitVec& other) const;
    BitVec bv_or(const BitVec& other) const;
    BitVec bv_neg() const;
    BitVec rotate_right(int amount) const;
    BitVec rotate_left(int amount) const;
    bool operator==(const BitVec& other) const { return eq(other); }
    bool operator!=(const BitVec& other) const { return !eq(other); }
    BitVec operator<<(int v) const { return rotate_left(v); }
    BitVec operator>>(int v) const { return rotate_right(v); }
    BitVec operator~() const { return bv_neg(); }
    BitVec operator&(const BitVec& other) const { return bv_and(other); }
    BitVec operator|(const BitVec& other) const { return bv_or(other); }
};

// BvContext maintains a context for symbolic bit vectors and bit expressions created.
// Expressions and BitVecs are comparable only if they were created by the same context.
class BvContext {
 private:
    BitID uid = 1;  // 0 and 1 are reserved for const zero and one.
    BitID new_uid() { return ++uid; };

 public:
    BitVec new_bv(int sz);
    BitVec new_bv_const(int sz, bitvec val);
};

}  // namespace symbolic_bitvec

}  // namespace solver

#endif /* BF_P4C_PHV_SOLVER_SYMBOLIC_BITVEC_H_ */
