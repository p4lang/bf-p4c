
#include "bf-p4c/common/ir_utils.h"

#include "gtest/gtest.h"
#include "gmock/gmock.h"

namespace Test {

TEST(IRUtils, bitMask_good) {
    ASSERT_EQ(bitMask(0),  uint64_t(0));
    ASSERT_EQ(bitMask(1),  uint64_t(1));
    ASSERT_EQ(bitMask(2),  uint64_t(3));
    ASSERT_EQ(bitMask(63), uint64_t(0x7fffffffffffffff));
    ASSERT_EQ(bitMask(64), uint64_t(0xffffffffffffffff));
}

TEST(IRUtils, bitMask_negative) {
    try {
        bitMask(-1);
    } catch(const Util::CompilerBug& bug) {
        ASSERT_THAT(bug.what(), testing::HasSubstr("bitMask(4294967295), maximum size is 64"));
    }
}

TEST(IRUtils, bitMask_too_big) {
     try {
        bitMask(65);
    } catch(const Util::CompilerBug& bug) {
        ASSERT_THAT(bug.what(), testing::HasSubstr("bitMask(65), maximum size is 64"));
    }
}

TEST(IRUtils, bigBitMask_good) {
    ASSERT_EQ(bigBitMask(0), 0);
    ASSERT_EQ(bigBitMask(1), 1);
    ASSERT_EQ(bigBitMask(2), big_int("3"));
    ASSERT_EQ(bigBitMask(63), 0x7fffffffffffffff);
    ASSERT_EQ(bigBitMask(64), 0xffffffffffffffff);
    ASSERT_EQ(bigBitMask(65), big_int("0x1ffffffffffffffff"));
    ASSERT_EQ(bigBitMask(129), big_int("0x1ffffffffffffffffffffffffffffffff"));
}

TEST(IRUtils, bigBitMask_negative) {
    try {
        bigBitMask(-1);
    } catch(const Util::CompilerBug& bug) {
        ASSERT_THAT(bug.what(), testing::HasSubstr("bigBitMask negative size"));
    }
}

}  // namespace Test