#include "phv/solver/symbolic_bitvec.h"

#include "lib/exceptions.h"

namespace solver {

namespace symbolic_bitvec {

namespace {

// BinOpEq is a helper function to check a strong form of equality of two expression.
// It returns true ONLY when two expressions have the exact same construct or
// are commutatively same
template <typename T>
bool binary_expr_eq(const Expr* self_val, const Expr* other_val) {
    const auto* self = self_val->eval();
    const auto* other = other_val->eval();
    const auto* self_op = dynamic_cast<const T*>(self);
    if (!self_op) {
        return self->eq(other_val);
    }
    const auto* other_op = dynamic_cast<const T*>(other);
    if (!other_op) {
        return false;
    }
    return (self_op->left->eq(other_op->left) && self_op->right->eq(other_op->right)) ||
           (self_op->left->eq(other_op->right) && self_op->right->eq(other_op->left));
}

}  // namespace

bool Bit::eq(const Expr* other) const {
    const auto* other_bit = dynamic_cast<const Bit*>(other->eval());
    if (other_bit) {
        return id == other_bit->id;
    } else {
        return false;
    }
}

cstring Bit::to_cstring() const {
    if (id == 0) {
        return "0";
    } else if (id == 1) {
        return "1";
    } else {
        std::stringstream ss;
        ss << "{" << id << "}";
        return ss.str();
    }
}

const Expr* And::eval() const {
    const auto* l = left->eval();
    const auto* r = right->eval();
    if (const auto* ll = dynamic_cast<const Bit*>(l)) {
        if (ll->id == 0) return new Bit(0);
        if (ll->id == 1) return r;
    }
    if (const auto* rr = dynamic_cast<const Bit*>(r)) {
        if (rr->id == 0) return new Bit(0);
        if (rr->id == 1) return l;
    }
    return new And(l, r);
}

bool And::eq(const Expr* other) const { return binary_expr_eq<And>(this, other); }

cstring And::to_cstring() const {
    std::stringstream ss;
    ss << "(And " << left->to_cstring() << " " << right->to_cstring() << ")";
    return ss.str();
}

const Expr* Or::eval() const {
    const auto* l = left->eval();
    const auto* r = right->eval();
    if (const auto* ll = dynamic_cast<const Bit*>(l)) {
        if (ll->id == 0) return r;
        if (ll->id == 1) return new Bit(1);
    }
    if (const auto* rr = dynamic_cast<const Bit*>(r)) {
        if (rr->id == 0) return l;
        if (rr->id == 1) return new Bit(1);
    }
    return new Or(l, r);
}

bool Or::eq(const Expr* other) const { return binary_expr_eq<Or>(this, other); }

cstring Or::to_cstring() const {
    std::stringstream ss;
    ss << "(Or " << left->to_cstring() << " " << right->to_cstring() << ")";
    return ss.str();
}

const Expr* Neg::eval() const {
    const auto* v = term->eval();
    const auto* bit = dynamic_cast<const Bit*>(v);
    if (bit && bit->id <= 1) {
        return new Bit(!bit->id);
    }
    return v;
}

bool Neg::eq(const Expr* other) const {
    const auto* self = this->eval();
    const auto* other_val = other->eval();
    const auto* self_neg = dynamic_cast<const Neg*>(self);
    if (self_neg) {
        const auto* other_neg_val = dynamic_cast<const Neg*>(other_val);
        return self_neg->term->eq(other_neg_val->term);
    }
    return self->eq(other_val);
}

cstring Neg::to_cstring() const {
    std::stringstream ss;
    ss << "(Neg " << term->to_cstring() << ")";
    return ss.str();
}

void BitVec::size_check(const BitVec& other) const {
    BUG_CHECK(other.bits.size() == bits.size(), "BitVec size mismatch");
}

template <typename T>
BitVec BitVec::bin_op(const BitVec& other) const {
    size_check(other);
    std::vector<const Expr*> rst(bits.size());
    for (size_t i = 0; i < bits.size(); i++) {
        const Expr* new_bit = new T(bits[i], other.bits[i]);
        rst[i] = new_bit->eval();
    }
    return BitVec{rst};
}

cstring BitVec::to_cstring() const {
    std::stringstream ss;
    ss << "[";
    cstring sep = "";
    for (size_t i = 0; i < bits.size(); i++) {
        ss << sep;
        sep = ", ";
        ss << bits[i]->to_cstring() << "@" << i;
    }
    ss << "]";
    return ss.str();
}

BitVec BitVec::slice(int start, int sz) const {
    BUG_CHECK(start >= 0 && start < int(bits.size()), "invalid start: %1%");
    BUG_CHECK(start + sz <= int(bits.size()), "invalid sz: %1%");
    return BitVec{std::vector<const Expr*>(bits.begin() + start, bits.begin() + start + sz)};
}

bool BitVec::eq(const BitVec& other) const {
    BUG_CHECK(bits.size() == other.bits.size(), "BitVec size mismatch: %1% != %2%", bits.size(),
              other.bits.size());
    for (size_t i = 0; i < bits.size(); i++) {
        if (!bits[i]->eq(other.bits[i])) {
            return false;
        }
    }
    return true;
}

BitVec BitVec::bv_and(const BitVec& other) const { return bin_op<And>(other); }

BitVec BitVec::bv_or(const BitVec& other) const { return bin_op<Or>(other); }

BitVec BitVec::bv_neg() const {
    std::vector<const Expr*> rst(bits.size());
    for (size_t i = 0; i < bits.size(); i++) {
        const Expr* new_bit = new Neg(bits[i]);
        rst[i] = new_bit->eval();
    }
    return BitVec{rst};
}

BitVec BitVec::rotate_right(int amount) const {
    // It can work with negative shift amount. Starting from C++11, negative module
    // rounding to 0 is a definied behavior, e.g. (-3) % 7 = -3, different from python.
    if (bits.size() == 0) return *this;
    amount %= bits.size();
    std::vector<const Expr*> rst(bits.size());
    for (size_t i = 0; i < bits.size(); i++) {
        int new_i = i - amount;
        if (new_i >= int(bits.size())) {
            new_i -= bits.size();
        } else if (new_i < 0) {
            new_i += bits.size();
        }
        rst[new_i] = bits[i];
    }
    return BitVec{rst};
}

BitVec BitVec::rotate_left(int amount) const { return rotate_right(-amount); }

BitVec BvContext::new_bv(int sz) {
    std::vector<const Expr*> bits(sz);
    for (int i = 0; i < sz; i++) {
        bits[i] = new Bit(new_uid());
    }
    return BitVec(bits);
}

BitVec BvContext::new_bv_const(int sz, bitvec val) {
    std::vector<const Expr*> bits(sz);
    for (int i = 0; i < sz; i++) {
        int bit_val = int(val.getbit(i));
        bits[i] = new Bit(bit_val);
    }
    return BitVec(bits);
}

}  // namespace symbolic_bitvec

}  // namespace solver
