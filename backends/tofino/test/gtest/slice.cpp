#include "backends/tofino/common/slice.h"
#include "gtest/gtest.h"

namespace Test {

TEST(slice, MakeSlice) {
    // original bug: bit<128> tmp = ((bit<128>)(h.h.a) | 128w1551532840);
    // which becomes: 0[0..63] ++ h.h.a[0..63] | 1551532840[0..127];
    // and then bits[0..63] are sliced.
    auto field = new IR::Constant(IR::Type::Bits::get(64), 0xdeadbeefdeadbeef);
    auto before = new IR::BOr(
            new IR::Concat(IR::Type::Bits::get(128),
                    new IR::Constant(IR::Type::Bits::get(64), 0),
                    new IR::Member(IR::Type::Bits::get(64), field, "field")),
            new IR::Constant(IR::Type::Bits::get(128), 1551532840));

    auto after = MakeSlice(before, 0, 63);

    auto expected  = new IR::BOr(
            new IR::Member(IR::Type::Bits::get(64), field, "field"),
            new IR::Constant(IR::Type::Bits::get(64), 1551532840));

    ASSERT_FALSE(before->equiv(*expected));
    ASSERT_TRUE(after->equiv(*expected));
}

}  // namespace Test
