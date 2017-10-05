#include <map>
#include <vector>
#include <utility>
#include "gtest/gtest.h"

#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "ir/ir.h"
#include "ir/json_loader.h"

namespace Test {

/// A fixture for testing properties that apply to all HalfOpenRange types.
template <typename T>
class TofinoHalfOpenRange : public TofinoBackendTest { };
typedef ::testing::Types<nw_bitinterval, nw_byteinterval,
                         le_bitinterval, le_byteinterval> HalfOpenRangeTypes;
TYPED_TEST_CASE(TofinoHalfOpenRange, HalfOpenRangeTypes);

/// A fixture for testing properties that apply to all ClosedRange types.
template <typename T>
class TofinoClosedRange : public TofinoBackendTest { };
typedef ::testing::Types<nw_bitrange, nw_byterange,
                         le_bitrange, le_byterange> ClosedRangeTypes;
TYPED_TEST_CASE(TofinoClosedRange, ClosedRangeTypes);

/// A fixture for testing properties that apply to all ranges with bit units.
template <typename T>
class TofinoBitRange : public TofinoBackendTest { };
typedef ::testing::Types<nw_bitinterval, le_bitinterval,
                         nw_bitrange, le_bitrange> BitRangeTypes;
TYPED_TEST_CASE(TofinoBitRange, BitRangeTypes);

/// A fixture for testing properties that apply to all ranges with byte units.
template <typename T>
class TofinoByteRange : public TofinoBackendTest { };
typedef ::testing::Types<nw_byteinterval, le_byteinterval,
                         nw_byterange, le_byterange> ByteRangeTypes;
TYPED_TEST_CASE(TofinoByteRange, ByteRangeTypes);

/// A fixture for testing properties that apply to all ranges of any type.
template <typename T>
class TofinoAnyRange : public TofinoBackendTest { };
typedef ::testing::Types<nw_bitinterval, le_bitinterval,
                         nw_bitrange, le_bitrange,
                         nw_byteinterval, le_byteinterval,
                         nw_byterange, le_byterange> AnyRangeTypes;
TYPED_TEST_CASE(TofinoAnyRange, AnyRangeTypes);

TYPED_TEST(TofinoHalfOpenRange, EmptyRange) {
    using HalfOpenRangeType = TypeParam;
    const HalfOpenRangeType range;

    // There are multiple ways to express an empty range, so we'll want to make
    // sure that they all behave the same.
    const std::map<int, HalfOpenRangeType> emptyRanges = {
        { 0, HalfOpenRangeType() },
        { 1, HalfOpenRangeType(0, 0) },
        { 2, HalfOpenRangeType(36, 36) },
    };

    for (auto& emptyRange : emptyRanges) {
        SCOPED_TRACE(emptyRange.first);
        auto range = emptyRange.second;

        // Make sure that this type of empty range is equal to all the other
        // kinds of empty ranges.
        for (auto& otherEmptyRange : emptyRanges) {
            SCOPED_TRACE(otherEmptyRange.first);
            EXPECT_EQ(otherEmptyRange.second, range);
        }

        // Check that it's not equal to a non-empty range.
        EXPECT_NE(HalfOpenRangeType(0, 1), range);

        // Check that "emptiness" has the properties we expect.
        EXPECT_EQ(range.lo, range.hi);
        EXPECT_TRUE(range.empty());
        EXPECT_EQ(0, range.size());
        EXPECT_EQ(0, range.loByte());
        EXPECT_EQ(0, range.hiByte());
        EXPECT_EQ(0, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());

        // Check that resizing an empty range results in a range of the
        // appropriate length with the low endpoint at 0.
        EXPECT_EQ(0, range.resizedToBits(0).lo);
        EXPECT_EQ(0, range.resizedToBits(0).size());
        EXPECT_EQ(0, range.resizedToBits(3).lo);
        EXPECT_EQ(3, range.resizedToBits(3).size());
        EXPECT_EQ(0, range.resizedToBytes(0).lo);
        EXPECT_EQ(0, range.resizedToBytes(0).size());
        EXPECT_EQ(0, range.resizedToBytes(3).lo);
        if (HalfOpenRangeType::unit == RangeUnit::Bit)
            EXPECT_EQ(3 * 8, range.resizedToBytes(3).size());
        else
            EXPECT_EQ(3, range.resizedToBytes(3).size());

        // Check that a shifted empty range remains empty.
        EXPECT_TRUE(range.shiftedByBits(10).empty());
        EXPECT_TRUE(range.shiftedByBytes(10).empty());

        // Check that an empty range doesn't contain any bits.
        for (int bit : { -2, -1, 0, 1, 2 }) {
            SCOPED_TRACE(bit);
            EXPECT_FALSE(range.contains(bit));
        }

        // Check that an empty range doesn't overlap anything.
        EXPECT_FALSE(range.overlaps(HalfOpenRangeType()));
        EXPECT_FALSE(range.overlaps(HalfOpenRangeType(0, 1)));
        EXPECT_FALSE(range.overlaps(HalfOpenRangeType(-2, 2)));
        EXPECT_FALSE(range.overlaps(HalfOpenRangeType(8, 16)));

        // Check that the intersection of an empty range with any other range is
        // always empty.
        EXPECT_EQ(HalfOpenRangeType(), range.intersectWith(HalfOpenRangeType()));
        EXPECT_EQ(HalfOpenRangeType(), range.intersectWith(HalfOpenRangeType(0, 1)));
        EXPECT_EQ(HalfOpenRangeType(), range.intersectWith(HalfOpenRangeType(-2, 2)));
        EXPECT_EQ(HalfOpenRangeType(), range.intersectWith(HalfOpenRangeType(8, 16)));

        // Check that the union of an empty range with any other range is the
        // identity function.
        EXPECT_EQ(HalfOpenRangeType(), range.unionWith(HalfOpenRangeType()));
        EXPECT_EQ(HalfOpenRangeType(0, 1), range.unionWith(HalfOpenRangeType(0, 1)));
        EXPECT_EQ(HalfOpenRangeType(-2, 2), range.unionWith(HalfOpenRangeType(-2, 2)));
        EXPECT_EQ(HalfOpenRangeType(8, 16), range.unionWith(HalfOpenRangeType(8, 16)));

        // Check that empty ranges remain empty when their endianness changes.
        // (The `template` business here is just grossness caused by the fact
        // that this test is *itself* a template; you wouldn't ordinarily need
        // that.)
        EXPECT_TRUE(range.template toOrder<Endian::Big>(10).empty());
        EXPECT_TRUE(range.template toOrder<Endian::Little>(10).empty());
        EXPECT_TRUE(range.template toOrder<Endian::Network>(10).empty());
        EXPECT_TRUE(range.template toOrder<Endian::Host>(10).empty());

        // Check that empty ranges remain empty when their unit changes.
        EXPECT_TRUE(range.template toUnit<RangeUnit::Bit>().empty());
        EXPECT_TRUE(range.template toUnit<RangeUnit::Byte>().empty());

        // Check that canonicalizing any empty range results in the same form.
        EXPECT_EQ(HalfOpenRangeType(0, 0), range.canonicalize());
    }
}

TYPED_TEST(TofinoHalfOpenRange, Constructors) {
    using HalfOpenRangeType = TypeParam;

    {
        HalfOpenRangeType range(5, 15);
        EXPECT_FALSE(range.empty());
        EXPECT_EQ(5, range.lo);
        EXPECT_EQ(15, range.hi);
        EXPECT_EQ(10, range.size());
    }

    {
        HalfOpenRangeType range(FromTo(5, 15));
        EXPECT_FALSE(range.empty());
        EXPECT_EQ(5, range.lo);
        EXPECT_EQ(16, range.hi);
        EXPECT_EQ(11, range.size());
    }

    {
        HalfOpenRangeType range(FromTo(-9, 9));
        EXPECT_FALSE(range.empty());
        EXPECT_EQ(-9, range.lo);
        EXPECT_EQ(10, range.hi);
        EXPECT_EQ(19, range.size());
    }

    {
        HalfOpenRangeType range(StartLen(5, 15));
        EXPECT_FALSE(range.empty());
        EXPECT_EQ(5, range.lo);
        EXPECT_EQ(20, range.hi);
        EXPECT_EQ(15, range.size());
    }

    {
        HalfOpenRangeType range(StartLen(-5, 3));
        EXPECT_FALSE(range.empty());
        EXPECT_EQ(-5, range.lo);
        EXPECT_EQ(-2, range.hi);
        EXPECT_EQ(3, range.size());
    }

    {
        HalfOpenRangeType range(std::make_pair(5, 15));
        EXPECT_FALSE(range.empty());
        EXPECT_EQ(5, range.lo);
        EXPECT_EQ(15, range.hi);
        EXPECT_EQ(10, range.size());
    }

    // Check FromTo/StartLen equivalences.
    EXPECT_EQ(HalfOpenRangeType(FromTo(-7, -3)),
              HalfOpenRangeType(StartLen(-7, 5)));
    EXPECT_EQ(HalfOpenRangeType(FromTo(-8, 0)),
              HalfOpenRangeType(StartLen(-8, 9)));
    EXPECT_EQ(HalfOpenRangeType(FromTo(-5, 5)),
              HalfOpenRangeType(StartLen(-5, 11)));
    EXPECT_EQ(HalfOpenRangeType(FromTo(3, 19)),
              HalfOpenRangeType(StartLen(3, 17)));
}

TYPED_TEST(TofinoClosedRange, Constructors) {
    using ClosedRangeType = TypeParam;

    {
        ClosedRangeType range(5, 15);
        EXPECT_EQ(5, range.lo);
        EXPECT_EQ(15, range.hi);
        EXPECT_EQ(11, range.size());
    }

    {
        ClosedRangeType range(FromTo(5, 15));
        EXPECT_EQ(5, range.lo);
        EXPECT_EQ(15, range.hi);
        EXPECT_EQ(11, range.size());
    }

    {
        ClosedRangeType range(FromTo(-9, 9));
        EXPECT_EQ(-9, range.lo);
        EXPECT_EQ(9, range.hi);
        EXPECT_EQ(19, range.size());
    }

    {
        ClosedRangeType range(StartLen(5, 15));
        EXPECT_EQ(5, range.lo);
        EXPECT_EQ(19, range.hi);
        EXPECT_EQ(15, range.size());
    }

    {
        ClosedRangeType range(StartLen(-5, 3));
        EXPECT_EQ(-5, range.lo);
        EXPECT_EQ(-3, range.hi);
        EXPECT_EQ(3, range.size());
    }

    {
        ClosedRangeType range(std::make_pair(5, 15));
        EXPECT_EQ(5, range.lo);
        EXPECT_EQ(15, range.hi);
        EXPECT_EQ(11, range.size());
    }

    // Check FromTo/StartLen equivalences.
    EXPECT_EQ(ClosedRangeType(FromTo(-7, -3)),
              ClosedRangeType(StartLen(-7, 5)));
    EXPECT_EQ(ClosedRangeType(FromTo(-8, 0)),
              ClosedRangeType(StartLen(-8, 9)));
    EXPECT_EQ(ClosedRangeType(FromTo(-5, 5)),
              ClosedRangeType(StartLen(-5, 11)));
    EXPECT_EQ(ClosedRangeType(FromTo(3, 19)),
              ClosedRangeType(StartLen(3, 17)));
}

TYPED_TEST(TofinoBitRange, Resize) {
    using BitRangeType = TypeParam;

    // Check basic functionality.
    {
        BitRangeType range(StartLen(5, 11));
        EXPECT_EQ(BitRangeType(StartLen(5, 4)), range.resizedToBits(4));
        EXPECT_EQ(BitRangeType(StartLen(5, 16)), range.resizedToBytes(2));
    }

    // Check that negative endpoints are handled correctly.
    {
        BitRangeType range(FromTo(-11, -2));
        EXPECT_EQ(BitRangeType(FromTo(-11, -8)), range.resizedToBits(4));
        EXPECT_EQ(BitRangeType(FromTo(-11, 3)), range.resizedToBits(15));
        EXPECT_EQ(BitRangeType(FromTo(-11, -4)), range.resizedToBytes(1));
        EXPECT_EQ(BitRangeType(FromTo(-11, 4)), range.resizedToBytes(2));
    }

    // Resizing to the original size should leave the range unchanged.
    {
        BitRangeType range(StartLen(3, 7));
        EXPECT_EQ(range, range.resizedToBits(7));
    }
    {
        BitRangeType range(StartLen(3, 16));
        EXPECT_EQ(range, range.resizedToBytes(2));
    }
}

TYPED_TEST(TofinoByteRange, Resize) {
    using ByteRangeType = TypeParam;

    // `resizedToBits()` always produces a range in bit units, even if the
    // original range was in byte units.
    using BitRangeType = decltype(ByteRangeType().resizedToBits(1));

    // Check basic functionality.
    {
        ByteRangeType range(StartLen(5, 11));
        EXPECT_EQ(BitRangeType(StartLen(40, 4)), range.resizedToBits(4));
        EXPECT_EQ(ByteRangeType(StartLen(5, 2)), range.resizedToBytes(2));
    }

    // Check that negative endpoints are handled correctly.
    {
        ByteRangeType range(FromTo(-11, -2));
        EXPECT_EQ(BitRangeType(FromTo(-88, -85)), range.resizedToBits(4));
        EXPECT_EQ(BitRangeType(FromTo(-88, 26)), range.resizedToBits(115));
        EXPECT_EQ(ByteRangeType(FromTo(-11, -11)), range.resizedToBytes(1));
        EXPECT_EQ(ByteRangeType(FromTo(-11, 18)), range.resizedToBytes(30));
    }

    // Resizing to the original size should leave the range unchanged.
    {
        ByteRangeType range(StartLen(3, 7));
        EXPECT_EQ(range, range.resizedToBits(56)
                              .template toUnit<RangeUnit::Byte>());
    }
    {
        ByteRangeType range(StartLen(3, 16));
        EXPECT_EQ(range, range.resizedToBytes(16));
    }
}

TYPED_TEST(TofinoBitRange, Shift) {
    using BitRangeType = TypeParam;

    // Check basic functionality.
    {
        BitRangeType range(StartLen(5, 11));
        EXPECT_EQ(BitRangeType(StartLen(9, 11)), range.shiftedByBits(4));
        EXPECT_EQ(BitRangeType(StartLen(1, 11)), range.shiftedByBits(-4));
        EXPECT_EQ(BitRangeType(StartLen(-3, 11)), range.shiftedByBits(-8));
        EXPECT_EQ(BitRangeType(StartLen(21, 11)), range.shiftedByBytes(2));
        EXPECT_EQ(BitRangeType(StartLen(-11, 11)), range.shiftedByBytes(-2));
    }

    // Shifting by zero should have no effect.
    {
        BitRangeType range(StartLen(3, 7));
        EXPECT_EQ(range, range.shiftedByBits(0));
        EXPECT_EQ(range, range.shiftedByBytes(0));
    }
}

TYPED_TEST(TofinoByteRange, Shift) {
    using ByteRangeType = TypeParam;

    // `shiftedByBits()` always produces a range in bit units, even if the
    // original range was in byte units.
    using BitRangeType = decltype(ByteRangeType().shiftedByBits(1));

    // Check basic functionality.
    {
        ByteRangeType range(FromTo(5, 14));
        EXPECT_EQ(BitRangeType(FromTo(44, 123)), range.shiftedByBits(4));
        EXPECT_EQ(BitRangeType(FromTo(36, 115)), range.shiftedByBits(-4));
        EXPECT_EQ(BitRangeType(FromTo(-79, 0)), range.shiftedByBits(-119));
        EXPECT_EQ(ByteRangeType(FromTo(7, 16)), range.shiftedByBytes(2));
        EXPECT_EQ(ByteRangeType(FromTo(-2, 7)), range.shiftedByBytes(-7));
    }

    // Shifting by zero should have no effect.
    {
        ByteRangeType range(StartLen(3, 7));
        EXPECT_EQ(range, range.shiftedByBits(0)
                              .template toUnit<RangeUnit::Byte>());
        EXPECT_EQ(range, range.shiftedByBytes(0));
    }
}


TYPED_TEST(TofinoBitRange, ByteAlignment) {
    using BitRangeType = TypeParam;

    {
        BitRangeType range(StartLen(0, 7));
        EXPECT_EQ(0, range.loByte());
        EXPECT_EQ(0, range.hiByte());
        EXPECT_EQ(1, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_FALSE(range.isHiAligned());
    }

    {
        BitRangeType range(FromTo(0, 7));
        EXPECT_EQ(0, range.loByte());
        EXPECT_EQ(0, range.hiByte());
        EXPECT_EQ(1, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        BitRangeType range(StartLen(0, 8));
        EXPECT_EQ(0, range.loByte());
        EXPECT_EQ(0, range.hiByte());
        EXPECT_EQ(1, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        BitRangeType range(FromTo(5, 6));
        EXPECT_EQ(0, range.loByte());
        EXPECT_EQ(0, range.hiByte());
        EXPECT_EQ(1, range.nextByte());
        EXPECT_FALSE(range.isLoAligned());
        EXPECT_FALSE(range.isHiAligned());
    }

    {
        BitRangeType range(StartLen(5, 6));
        EXPECT_EQ(0, range.loByte());
        EXPECT_EQ(1, range.hiByte());
        EXPECT_EQ(2, range.nextByte());
        EXPECT_FALSE(range.isLoAligned());
        EXPECT_FALSE(range.isHiAligned());
    }

    {
        BitRangeType range(StartLen(11, 33));
        EXPECT_EQ(1, range.loByte());
        EXPECT_EQ(5, range.hiByte());
        EXPECT_EQ(6, range.nextByte());
        EXPECT_FALSE(range.isLoAligned());
        EXPECT_FALSE(range.isHiAligned());
    }

    {
        BitRangeType range(StartLen(16, 128));
        EXPECT_EQ(2, range.loByte());
        EXPECT_EQ(17, range.hiByte());
        EXPECT_EQ(18, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        BitRangeType range(StartLen(-16, 8));
        EXPECT_EQ(-2, range.loByte());
        EXPECT_EQ(-2, range.hiByte());
        EXPECT_EQ(-1, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        BitRangeType range(StartLen(-11, 4));
        EXPECT_EQ(-2, range.loByte());
        EXPECT_EQ(-1, range.hiByte());
        EXPECT_EQ(0, range.nextByte());
        EXPECT_FALSE(range.isLoAligned());
        EXPECT_FALSE(range.isHiAligned());
    }

    {
        BitRangeType range(StartLen(-3, 16));
        EXPECT_EQ(-1, range.loByte());
        EXPECT_EQ(1, range.hiByte());
        EXPECT_EQ(2, range.nextByte());
        EXPECT_FALSE(range.isLoAligned());
        EXPECT_FALSE(range.isHiAligned());
    }

    {
        BitRangeType range(FromTo(-6, -1));
        EXPECT_EQ(-1, range.loByte());
        EXPECT_EQ(-1, range.hiByte());
        EXPECT_EQ(0, range.nextByte());
        EXPECT_FALSE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        BitRangeType range(FromTo(-15, 0));
        EXPECT_EQ(-2, range.loByte());
        EXPECT_EQ(0, range.hiByte());
        EXPECT_EQ(1, range.nextByte());
        EXPECT_FALSE(range.isLoAligned());
        EXPECT_FALSE(range.isHiAligned());
    }
}

TYPED_TEST(TofinoByteRange, ByteAlignment) {
    using ByteRangeType = TypeParam;

    {
        ByteRangeType range(StartLen(0, 7));
        EXPECT_EQ(0, range.loByte());
        EXPECT_EQ(6, range.hiByte());
        EXPECT_EQ(7, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        ByteRangeType range(FromTo(0, 7));
        EXPECT_EQ(0, range.loByte());
        EXPECT_EQ(7, range.hiByte());
        EXPECT_EQ(8, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        ByteRangeType range(StartLen(0, 8));
        EXPECT_EQ(0, range.loByte());
        EXPECT_EQ(7, range.hiByte());
        EXPECT_EQ(8, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        ByteRangeType range(FromTo(5, 6));
        EXPECT_EQ(5, range.loByte());
        EXPECT_EQ(6, range.hiByte());
        EXPECT_EQ(7, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        ByteRangeType range(StartLen(5, 6));
        EXPECT_EQ(5, range.loByte());
        EXPECT_EQ(10, range.hiByte());
        EXPECT_EQ(11, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        ByteRangeType range(StartLen(11, 33));
        EXPECT_EQ(11, range.loByte());
        EXPECT_EQ(43, range.hiByte());
        EXPECT_EQ(44, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        ByteRangeType range(StartLen(16, 128));
        EXPECT_EQ(16, range.loByte());
        EXPECT_EQ(143, range.hiByte());
        EXPECT_EQ(144, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        ByteRangeType range(StartLen(-16, 8));
        EXPECT_EQ(-16, range.loByte());
        EXPECT_EQ(-9, range.hiByte());
        EXPECT_EQ(-8, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        ByteRangeType range(StartLen(-11, 4));
        EXPECT_EQ(-11, range.loByte());
        EXPECT_EQ(-8, range.hiByte());
        EXPECT_EQ(-7, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        ByteRangeType range(StartLen(-3, 16));
        EXPECT_EQ(-3, range.loByte());
        EXPECT_EQ(12, range.hiByte());
        EXPECT_EQ(13, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        ByteRangeType range(FromTo(-6, -1));
        EXPECT_EQ(-6, range.loByte());
        EXPECT_EQ(-1, range.hiByte());
        EXPECT_EQ(0, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }

    {
        ByteRangeType range(FromTo(-15, 0));
        EXPECT_EQ(-15, range.loByte());
        EXPECT_EQ(0, range.hiByte());
        EXPECT_EQ(1, range.nextByte());
        EXPECT_TRUE(range.isLoAligned());
        EXPECT_TRUE(range.isHiAligned());
    }
}

TYPED_TEST(TofinoAnyRange, Contains) {
    using AnyRangeType = TypeParam;

    AnyRangeType range(FromTo(-11, 5));
    for (auto i = -15; i < -11; i++) {
        SCOPED_TRACE(i);
        EXPECT_FALSE(range.contains(i));
    }
    for (auto i = -11; i <= 5; i++) {
        SCOPED_TRACE(i);
        EXPECT_TRUE(range.contains(i));
    }
    for (auto i = 6; i <= 10; i++) {
        SCOPED_TRACE(i);
        EXPECT_FALSE(range.contains(i));
    }
}

TYPED_TEST(TofinoAnyRange, Overlaps) {
    using AnyRangeType = TypeParam;

    {
        AnyRangeType range(FromTo(0, 7));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(-1, 0))));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(-11, 5))));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(-22, 37))));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(0, 1))));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(0, 18))));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(5, 6))));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(7, 43))));
        EXPECT_FALSE(range.overlaps(AnyRangeType(FromTo(-18, -1))));
        EXPECT_FALSE(range.overlaps(AnyRangeType(FromTo(8, 44))));
    }

    {
        AnyRangeType range(FromTo(-18, -3));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(-18, -17))));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(-18, 1))));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(-3, 3))));
        EXPECT_FALSE(range.overlaps(AnyRangeType(FromTo(-2, -1))));
        EXPECT_FALSE(range.overlaps(AnyRangeType(FromTo(-2, 13))));
        EXPECT_FALSE(range.overlaps(AnyRangeType(FromTo(0, 3))));
        EXPECT_FALSE(range.overlaps(AnyRangeType(FromTo(5, 13))));
    }

    {
        AnyRangeType range(FromTo(5, 5));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(5, 5))));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(3, 5))));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(3, 8))));
        EXPECT_TRUE(range.overlaps(AnyRangeType(FromTo(5, 16))));
        EXPECT_FALSE(range.overlaps(AnyRangeType(FromTo(6, 13))));
        EXPECT_FALSE(range.overlaps(AnyRangeType(FromTo(-5, -5))));
    }
}

TYPED_TEST(TofinoAnyRange, IntersectWith) {
    using AnyRangeType = TypeParam;

    // Intersection always produces a half-open range, even if the original
    // range was closed.
    using IntersectionType =
      HalfOpenRange<AnyRangeType::unit, AnyRangeType::order>;

    {
        AnyRangeType range(FromTo(0, 4));
        EXPECT_TRUE(range.intersectWith(AnyRangeType(FromTo(-15, -1))).empty());
        EXPECT_TRUE(range.intersectWith(AnyRangeType(FromTo(5, 7))).empty());
        EXPECT_EQ(IntersectionType(FromTo(0, 0)),
                  range.intersectWith(AnyRangeType(FromTo(-11, 0))));
        EXPECT_EQ(IntersectionType(FromTo(0, 1)),
                  range.intersectWith(AnyRangeType(FromTo(-5, 1))));
        EXPECT_EQ(IntersectionType(FromTo(0, 4)),
                  range.intersectWith(AnyRangeType(FromTo(-300, 500))));
        EXPECT_EQ(IntersectionType(FromTo(2, 4)),
                  range.intersectWith(AnyRangeType(FromTo(2, 19))));
        EXPECT_EQ(IntersectionType(FromTo(4, 4)),
                  range.intersectWith(AnyRangeType(FromTo(4, 49))));
    }

    {
        AnyRangeType range(FromTo(-7, -2));
        EXPECT_TRUE(range.intersectWith(AnyRangeType(FromTo(-33, -8))).empty());
        EXPECT_TRUE(range.intersectWith(AnyRangeType(FromTo(-1, 9))).empty());
        EXPECT_TRUE(range.intersectWith(AnyRangeType(FromTo(0, 97))).empty());
        EXPECT_EQ(IntersectionType(FromTo(-7, -7)),
                  range.intersectWith(AnyRangeType(FromTo(-16, -7))));
        EXPECT_EQ(IntersectionType(FromTo(-7, -6)),
                  range.intersectWith(AnyRangeType(FromTo(-7, -6))));
        EXPECT_EQ(IntersectionType(FromTo(-7, -2)),
                  range.intersectWith(AnyRangeType(FromTo(-99, 43))));
        EXPECT_EQ(IntersectionType(FromTo(-3, -2)),
                  range.intersectWith(AnyRangeType(FromTo(-3, 8000))));
        EXPECT_EQ(IntersectionType(FromTo(-2, -2)),
                  range.intersectWith(AnyRangeType(FromTo(-2, 0))));
    }

    {
        AnyRangeType range(FromTo(-1, 1));
        EXPECT_TRUE(range.intersectWith(AnyRangeType(FromTo(-7, -2))).empty());
        EXPECT_TRUE(range.intersectWith(AnyRangeType(FromTo(2, 76))).empty());
        EXPECT_EQ(IntersectionType(FromTo(-1, -1)),
                  range.intersectWith(AnyRangeType(FromTo(-5, -1))));
        EXPECT_EQ(IntersectionType(FromTo(-1, 0)),
                  range.intersectWith(AnyRangeType(FromTo(-11, 0))));
        EXPECT_EQ(IntersectionType(FromTo(0, 0)),
                  range.intersectWith(AnyRangeType(FromTo(0, 0))));
        EXPECT_EQ(IntersectionType(FromTo(0, 1)),
                  range.intersectWith(AnyRangeType(FromTo(0, 500))));
    }

    {
        AnyRangeType range(FromTo(0, 0));
        EXPECT_TRUE(range.intersectWith(AnyRangeType(FromTo(-22, -1))).empty());
        EXPECT_TRUE(range.intersectWith(AnyRangeType(FromTo(1, 63))).empty());
        EXPECT_EQ(IntersectionType(FromTo(0, 0)),
                  range.intersectWith(AnyRangeType(FromTo(-500, 500))));
        EXPECT_EQ(IntersectionType(FromTo(0, 0)),
                  range.intersectWith(AnyRangeType(FromTo(0, 0))));
    }
}

TYPED_TEST(TofinoAnyRange, UnionWith) {
    using AnyRangeType = TypeParam;

    {
        AnyRangeType range(FromTo(0, 4));
        EXPECT_EQ(AnyRangeType(FromTo(0, 4)),
                  range.unionWith(AnyRangeType(FromTo(1, 2))));
        EXPECT_EQ(AnyRangeType(FromTo(-5, 4)),
                  range.unionWith(AnyRangeType(FromTo(-5, -1))));
        EXPECT_EQ(AnyRangeType(FromTo(-5, 4)),
                  range.unionWith(AnyRangeType(FromTo(-5, -4))));
        EXPECT_EQ(AnyRangeType(FromTo(-5, 4)),
                  range.unionWith(AnyRangeType(FromTo(-5, 2))));
        EXPECT_EQ(AnyRangeType(FromTo(-5, 4)),
                  range.unionWith(AnyRangeType(FromTo(-5, 4))));
        EXPECT_EQ(AnyRangeType(FromTo(0, 7)),
                  range.unionWith(AnyRangeType(FromTo(0, 7))));
        EXPECT_EQ(AnyRangeType(FromTo(0, 7)),
                  range.unionWith(AnyRangeType(FromTo(3, 7))));
        EXPECT_EQ(AnyRangeType(FromTo(0, 7)),
                  range.unionWith(AnyRangeType(FromTo(5, 7))));
        EXPECT_EQ(AnyRangeType(FromTo(0, 7)),
                  range.unionWith(AnyRangeType(FromTo(7, 7))));
        EXPECT_EQ(AnyRangeType(FromTo(-100, 100)),
                  range.unionWith(AnyRangeType(FromTo(-100, 100))));
    }

    {
        AnyRangeType range(FromTo(-9, -3));
        EXPECT_EQ(AnyRangeType(FromTo(-11, -3)),
                  range.unionWith(AnyRangeType(FromTo(-11, -11))));
        EXPECT_EQ(AnyRangeType(FromTo(-11, -3)),
                  range.unionWith(AnyRangeType(FromTo(-11, -10))));
        EXPECT_EQ(AnyRangeType(FromTo(-11, -3)),
                  range.unionWith(AnyRangeType(FromTo(-11, -4))));
        EXPECT_EQ(AnyRangeType(FromTo(-9, -3)),
                  range.unionWith(AnyRangeType(FromTo(-6, -5))));
        EXPECT_EQ(AnyRangeType(FromTo(-9, 0)),
                  range.unionWith(AnyRangeType(FromTo(-5, 0))));
        EXPECT_EQ(AnyRangeType(FromTo(-9, 0)),
                  range.unionWith(AnyRangeType(FromTo(-1, 0))));
        EXPECT_EQ(AnyRangeType(FromTo(-9, 50)),
                  range.unionWith(AnyRangeType(FromTo(35, 50))));
        EXPECT_EQ(AnyRangeType(FromTo(-100, 100)),
                  range.unionWith(AnyRangeType(FromTo(-100, 100))));
    }

    {
        AnyRangeType range(FromTo(3, 3));
        EXPECT_EQ(AnyRangeType(FromTo(3, 3)),
                  range.unionWith(AnyRangeType(FromTo(3, 3))));
        EXPECT_EQ(AnyRangeType(FromTo(0, 3)),
                  range.unionWith(AnyRangeType(FromTo(0, 1))));
        EXPECT_EQ(AnyRangeType(FromTo(3, 13)),
                  range.unionWith(AnyRangeType(FromTo(3, 13))));
        EXPECT_EQ(AnyRangeType(FromTo(-27, 3)),
                  range.unionWith(AnyRangeType(FromTo(-27, -26))));
        EXPECT_EQ(AnyRangeType(FromTo(-100, 100)),
                  range.unionWith(AnyRangeType(FromTo(-100, 100))));
    }
}

TYPED_TEST(TofinoAnyRange, ToOrder) {
    using FromEndianRangeType = TypeParam;

    // Concoct the range type which is the same as FromEndianRangeType except
    // that it has the opposite endianness.
    constexpr auto fromEndian = FromEndianRangeType::order;
    constexpr auto toEndian = fromEndian == Endian::Network
                            ? Endian::Little
                            : Endian::Network;
    using ToEndianRangeType =
      decltype(FromEndianRangeType().template toOrder<toEndian>(1));

    struct ExpectedOrderMapping {
        int index;
        const FromEndianRangeType from;
        const ToEndianRangeType to;
        int spaceSize;
    };

    const std::vector<ExpectedOrderMapping> orderMappings = {
        // A range that fills the space it's defined in looks the same in either
        // endianess.
        { 0, StartLen(0, 5), StartLen(0, 5), 5 },
        { 1, StartLen(0, 10), StartLen(0, 10), 10 },
        { 2, StartLen(0, 16), StartLen(0, 16), 16 },

        // Simple endian changes within a single byte.
        { 3, FromTo(0, 0), FromTo(7, 7), 8 },
        { 4, FromTo(1, 2), FromTo(5, 6), 8 },
        { 5, FromTo(3, 6), FromTo(1, 4), 8 },
        { 6, FromTo(4, 7), FromTo(0, 3), 8 },
        { 7, FromTo(7, 7), FromTo(0, 0), 8 },

        // Irregularly sized spaces.
        { 8, FromTo(25, 63), FromTo(23, 61), 87 },
        { 9, FromTo(1, 12), FromTo(0, 11), 13 },
        { 10, FromTo(0, 0), FromTo(1, 1), 2 },

        // Indices outside the space.
        { 11, FromTo(1, 1), FromTo(-1, -1), 1 },
        { 12, FromTo(22, 45), FromTo(-37, -14), 9 },
        { 13, FromTo(-17, 5), FromTo(4, 26), 10 },
        { 14, FromTo(3, 4), FromTo(-1, 0), 4 },
        { 15, FromTo(-6, 0), FromTo(15, 21), 16 },
        { 16, FromTo(-6, -3), FromTo(18, 21), 16 },
        { 17, FromTo(-1000, 1000), FromTo(-1000, 1000), 1 },
    };

    // Check that converting between different orders yields the results we
    // expect above. We check both directions because endian changes should
    // always be invertible.
    // (The `template` business below is just grossness caused by the fact that
    // this test is *itself* a template; you wouldn't ordinarily need that.)
    for (auto& mapping : orderMappings) {
        SCOPED_TRACE(mapping.index);
        EXPECT_EQ(mapping.to,
                  mapping.from.template toOrder<toEndian>(mapping.spaceSize));
        EXPECT_EQ(mapping.from,
                  mapping.to.template toOrder<fromEndian>(mapping.spaceSize));
    }
}

TYPED_TEST(TofinoBitRange, ToUnit) {
    using BitRangeType = TypeParam;

    // Concoct the range type which is the same as BitRangeType except that it's
    // in byte units.
    using ByteRangeType =
      decltype(BitRangeType().template toUnit<RangeUnit::Byte>());

    struct ExpectedByteRange {
        int index;
        const BitRangeType from;
        const ByteRangeType to;
    };

    const std::vector<ExpectedByteRange> unitMappings = {
        // Byte-aligned bit ranges.
        { 0, StartLen(0, 8), StartLen(0, 1) },
        { 1, StartLen(16, 16), StartLen(2, 2) },
        { 2, StartLen(24, 32), StartLen(3, 4) },
        { 3, StartLen(72, 264), StartLen(9, 33) },

        // Non-byte-aligned bit ranges.
        { 4, FromTo(0, 0), FromTo(0, 0) },
        { 5, FromTo(1, 2), FromTo(0, 0) },
        { 6, FromTo(0, 9), FromTo(0, 1) },
        { 7, FromTo(16, 36), FromTo(2, 4) },
        { 8, FromTo(15, 15), FromTo(1, 1) },
        { 9, FromTo(67, 321), FromTo(8, 40) },

        // Negative indices.
        { 10, FromTo(-1, 0), FromTo(-1, 0) },
        { 11, FromTo(-1, -1), FromTo(-1, -1) },
        { 12, FromTo(-8, 1), FromTo(-1, 0) },
        { 13, FromTo(-9, 1), FromTo(-2, 0) },
        { 14, FromTo(-27, -23), FromTo(-4, -3) },
        { 15, FromTo(-31, -9), FromTo(-4, -2) },
        { 16, FromTo(-11, 7), FromTo(-2, 0) },
        { 17, FromTo(-76, 112), FromTo(-10, 14) },
    };

    // Check that converting from bit units to byte units yields the results we
    // expect above.
    // (The `template` business below is just grossness caused by the fact that
    // this test is *itself* a template; you wouldn't ordinarily need that.)
    for (auto& mapping : unitMappings) {
        SCOPED_TRACE(mapping.index);
        EXPECT_EQ(mapping.to,
                  mapping.from.template toUnit<RangeUnit::Byte>());
    }
}

TYPED_TEST(TofinoByteRange, ToUnit) {
    using ByteRangeType = TypeParam;

    // Concoct the range type which is the same as ByteRangeType except that
    // it's in bit units.
    using BitRangeType =
      decltype(ByteRangeType().template toUnit<RangeUnit::Bit>());

    struct ExpectedBitRange {
        int index;
        const ByteRangeType from;
        const BitRangeType to;
    };

    const std::vector<ExpectedBitRange> unitMappings = {
        // Basic byte ranges.
        { 0, FromTo(0, 0), FromTo(0, 7) },
        { 1, FromTo(0, 5), FromTo(0, 47) },
        { 2, FromTo(7, 22), FromTo(56, 183) },
        { 3, FromTo(12, 12), StartLen(96, 8) },

        // Byte ranges with negative indices.
        { 4, FromTo(-5, 3), FromTo(-40, 31) },
        { 5, FromTo(-2, -1), StartLen(-16, 16) },
        { 6, FromTo(-30, 0), FromTo(-240, 7) },
        { 7, FromTo(-84, 7), FromTo(-672, 63) },
    };

    // Check that converting from byte ranges to bit ranges yields the results
    // we expect above. We check both directions because converts from bytes to
    // bits should always be invertible. The same is not true for converting bit
    // ranges to byte ranges, since non-byte-aligned bit ranges will lose
    // information in the conversion.
    // (The `template` business below is just grossness caused by the fact that
    // this test is *itself* a template; you wouldn't ordinarily need that.)
    for (auto& mapping : unitMappings) {
        SCOPED_TRACE(mapping.index);
        EXPECT_EQ(mapping.to,
                  mapping.from.template toUnit<RangeUnit::Bit>());
        EXPECT_EQ(mapping.from,
                  mapping.to.template toUnit<RangeUnit::Byte>());
    }
}

TYPED_TEST(TofinoHalfOpenRange, ToClosedRange) {
    using HalfOpenRangeType = TypeParam;

    // Concoct the range type which is the same as HalfOpenRangeType except that
    // it's a closed range.
    using ClosedRangeType =
      ClosedRange<HalfOpenRangeType::unit, HalfOpenRangeType::order>;

    struct ExpectedClosedRange {
        int index;
        const HalfOpenRangeType from;
        const boost::optional<ClosedRangeType> to;
    };

    const std::vector<ExpectedClosedRange> closedRangeMappings = {
        { 0, HalfOpenRangeType(0, 1), ClosedRangeType(0, 0) },
        { 1, HalfOpenRangeType(15, 36), ClosedRangeType(15, 35) },
        { 2, HalfOpenRangeType(-1, 0), ClosedRangeType(-1, -1) },
        { 3, HalfOpenRangeType(-21, -8), ClosedRangeType(-21, -9) },
        { 4, HalfOpenRangeType(0, 0), boost::none },
        { 5, HalfOpenRangeType(-9, -9), boost::none },
        { 6, HalfOpenRangeType(17, 17), boost::none },
    };

    // Check that converting from a half-open range to a closed range yields the
    // results we expect above.
    for (auto& mapping : closedRangeMappings) {
        SCOPED_TRACE(mapping.index);
        EXPECT_EQ(mapping.to, toClosedRange(mapping.from));
    }
}

TYPED_TEST(TofinoClosedRange, ToHalfOpenRange) {
    using ClosedRangeType = TypeParam;

    // Concoct the range type which is the same as ClosedRangeType except that
    // it's a half-open range.
    using HalfOpenRangeType =
      HalfOpenRange<ClosedRangeType::unit, ClosedRangeType::order>;

    struct ExpectedHalfOpenRange {
        int index;
        const ClosedRangeType from;
        const HalfOpenRangeType to;
    };

    const std::vector<ExpectedHalfOpenRange> halfOpenRangeMappings = {
        { 0, ClosedRangeType(0, 0), HalfOpenRangeType(0, 1) },
        { 1, ClosedRangeType(15, 35), HalfOpenRangeType(15, 36) },
        { 2, ClosedRangeType(-1, -1), HalfOpenRangeType(-1, 0) },
        { 3, ClosedRangeType(-21, -9), HalfOpenRangeType(-21, -8) },
    };

    // Check that converting a closed range to a half-open range yields the
    // results we expect above. Any closed range can be converted to a
    // half-open range and back again without loss of information. The same is
    // not true in the other direction because an empty range cannot be
    // represented as a closed range.
    for (auto& mapping : halfOpenRangeMappings) {
        SCOPED_TRACE(mapping.index);
        EXPECT_EQ(mapping.to, toHalfOpenRange(mapping.from));

        auto backToClosedRange = toClosedRange(toHalfOpenRange(mapping.from));
        EXPECT_TRUE(backToClosedRange != boost::none);
        EXPECT_EQ(mapping.from, *backToClosedRange);
    }
}

class TofinoIntegerMathUtils : public TofinoBackendTest { };

TEST_F(TofinoIntegerMathUtils, DivideFloor) {
    struct ExpectedDivisonResult {
        int index;
        int dividend;
        int divisor;
        int quotient;
    };

    const std::vector<ExpectedDivisonResult> divisionResults = {
        { 0, -17, 8, -3 },
        { 1, -16, 8, -2 },
        { 2, -15, 8, -2 },
        { 3, -9, 8, -2 },
        { 4, -8, 8, -1 },
        { 5, -7, 8, -1 },
        { 6, -1, 8, -1 },
        { 7, 0, 8, 0 },
        { 8, 4, 8, 0 },
        { 9, 7, 8, 0 },
        { 10, 8, 8, 1 },
        { 11, 9, 8, 1 },
        { 12, 15, 8, 1 },
        { 13, 16, 8, 2 },
        { 14, 17, 8, 2 },
        { 15, -4, 3, -2 },
        { 16, -3, 3, -1 },
        { 17, -2, 3, -1 },
        { 18, 0, 3, 0 },
        { 19, 1, 3, 0 },
        { 20, 3, 3, 1 },
        { 21, 4, 3, 1 },
        { 22, -2, 1, -2 },
        { 23, -1, 1, -1 },
        { 24, 0, 1, 0 },
        { 25, 1, 1, 1 },
        { 26, 2, 1, 2 },
    };

    for (auto& result : divisionResults) {
        SCOPED_TRACE(result.index);
        EXPECT_EQ(result.quotient, divideFloor(result.dividend, result.divisor));
    }
}

TEST_F(TofinoIntegerMathUtils, Modulo) {
    struct ExpectedModuloResult {
        int index;
        int dividend;
        int divisor;
        int remainder;
    };

    const std::vector<ExpectedModuloResult> moduloResults = {
        { 0, -17, 8, 1 },
        { 1, -16, 8, 0 },
        { 2, -15, 8, 7 },
        { 3, -9, 8, 1 },
        { 4, -8, 8, 0 },
        { 5, -7, 8, 7 },
        { 6, -1, 8, 1 },
        { 7, 0, 8, 0 },
        { 8, 4, 8, 4 },
        { 9, 7, 8, 7 },
        { 10, 8, 8, 0 },
        { 11, 9, 8, 1 },
        { 12, 15, 8, 7 },
        { 13, 16, 8, 0 },
        { 14, 17, 8, 1 },
        { 15, -4, 3, 1 },
        { 16, -3, 3, 0 },
        { 17, -2, 3, 2 },
        { 18, 0, 3, 0 },
        { 19, 1, 3, 1 },
        { 20, 3, 3, 0 },
        { 21, 4, 3, 1 },
        { 22, -2, 1, 0 },
        { 23, -1, 1, 0 },
        { 24, 0, 1, 0 },
        { 25, 1, 1, 0 },
        { 26, 2, 1, 0 },
    };

    for (auto& result : moduloResults) {
        SCOPED_TRACE(result.index);
        EXPECT_EQ(result.remainder, modulo(result.dividend, result.divisor));
    }
}

TEST_F(TofinoIntegerMathUtils, ModuloFloor) {
    struct ExpectedModuloFloorResult {
        int index;
        int dividend;
        int divisor;
        int remainder;
    };

    const std::vector<ExpectedModuloFloorResult> moduloFloorResults = {
        { 0, -17, 8, 7 },
        { 1, -16, 8, 0 },
        { 2, -15, 8, 1 },
        { 3, -9, 8, 7 },
        { 4, -8, 8, 0 },
        { 5, -7, 8, 1 },
        { 6, -1, 8, 7 },
        { 7, 0, 8, 0 },
        { 8, 4, 8, 4 },
        { 9, 7, 8, 7 },
        { 10, 8, 8, 0 },
        { 11, 9, 8, 1 },
        { 12, 15, 8, 7 },
        { 13, 16, 8, 0 },
        { 14, 17, 8, 1 },
        { 15, -4, 3, 2 },
        { 16, -3, 3, 0 },
        { 17, -2, 3, 1 },
        { 18, 0, 3, 0 },
        { 19, 1, 3, 1 },
        { 20, 3, 3, 0 },
        { 21, 4, 3, 1 },
        { 22, -2, 1, 0 },
        { 23, -1, 1, 0 },
        { 24, 0, 1, 0 },
        { 25, 1, 1, 0 },
        { 26, 2, 1, 0 },
    };

    for (auto& result : moduloFloorResults) {
        SCOPED_TRACE(result.index);
        EXPECT_EQ(result.remainder, moduloFloor(result.dividend, result.divisor));
    }
}

}  // namespace Test
