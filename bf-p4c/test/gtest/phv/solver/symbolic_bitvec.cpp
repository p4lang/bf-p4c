#include "bf-p4c/phv/solver/symbolic_bitvec.h"
#include "gtest/gtest.h"

namespace Test {

using namespace solver::symbolic_bitvec;

TEST(symbolic_bitvec_tests, basic) {
    auto ctx = BvContext();
    const int sz = 8;
    bitvec bv;
    bv.setrange(0, 4);
    auto four_zeros = ctx.new_bv_const(4, bitvec());
    auto four_ones = ctx.new_bv_const(4, bv);
    auto mask = ctx.new_bv_const(8, bv);
    auto a = ctx.new_bv(sz);
    auto b = ctx.new_bv(sz);

    // and
    EXPECT_TRUE((a & mask).slice(0, 4) == a.slice(0, 4));
    EXPECT_TRUE((a & mask).slice(4, 4) == four_zeros);
    EXPECT_TRUE((a & (~mask)).slice(0, 4) == four_zeros);
    EXPECT_TRUE((a & (~mask)).slice(4, 4) == a.slice(4, 4));

    // or
    EXPECT_TRUE((a | mask).slice(0, 4) == four_ones);
    EXPECT_TRUE((a | mask).slice(4, 4) == a.slice(4, 4));
    EXPECT_TRUE((a | (~mask)).slice(0, 4) == a.slice(0, 4));
    EXPECT_TRUE((a | (~mask)).slice(4, 4) == four_ones);

    // left rotate
    auto a_left_rotated = a << 3;
    for (int i = 0; i < 8; i++) {
        EXPECT_TRUE(a.get(i)->eq(a_left_rotated.get((i + 3) % sz)));
    }

    // right rorate
    auto a_right_rotated = a >> 3;
    for (int i = 0; i < 8; i++) {
        EXPECT_TRUE(a.get(i)->eq(a_right_rotated.get((i + sz - 3) % sz)));
    }

    // eq
    EXPECT_TRUE(And(a.get(0), b.get(0)).eq(new And(a.get(0), b.get(0))));
    EXPECT_TRUE(And(a.get(0), b.get(0)).eq(new And(b.get(0), a.get(0))));
    EXPECT_FALSE(And(a.get(0), b.get(0)).eq(new Or(a.get(0), b.get(0))));
    EXPECT_FALSE(And(a.get(0), b.get(0)).eq(new Or(b.get(0), a.get(0))));
    EXPECT_TRUE(And(new Neg(a.get(0)), b.get(0)).eq(new And(b.get(0), new Neg(a.get(0)))));
    EXPECT_TRUE(And(new And(a.get(0), a.get(1)), b.get(0)).eq(
                        new And(b.get(0), new And(a.get(0), a.get(1)))));

    // example of the limitation on the equality for this library. Logically it's true,
    // but for this library, we treat them as false.
    EXPECT_FALSE(And(new And(a.get(0), a.get(1)), b.get(0)).eq(
                        new And(a.get(0), new And(b.get(0), a.get(1)))));
}

}  // namespace Test
