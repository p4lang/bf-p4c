/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#ifndef _EXTENSIONS_TOFINO_IR_BITRANGE_H_
#define _EXTENSIONS_TOFINO_IR_BITRANGE_H_

#include <boost/optional.hpp>

#include <algorithm>
#include <iosfwd>
#include <utility>

#include "lib/exceptions.h"

/// An ordering for bits or bytes.
enum class Endian : uint8_t {
    Network = 0,
    Big = 0,      /// Most significant bit/byte first.
    Little = 1    /// Least significant bit/byte first.
};

/// A closed range of bits specified in terms of a specific bit order.
template <Endian Order>
struct bit_range {
    bit_range() : lo(0), hi(0) { }
    bit_range(int lo, int hi) : lo(lo), hi(hi) { }

    int size() const                  { return hi - lo + 1; }
    operator std::pair<int, int>()    { return std::make_pair(lo, hi); }

    /// @return a new range with the same size, but shifted towards the
    /// high-numbered bits by the provided amount. No rotation or clamping
    /// to zero is applied.
    bit_range shiftedBy(int offset) const {
        return bit_range(lo + offset, hi + offset);
    }

    /// @return the byte containing the lowest-numbered bit in this range.
    int loByte() const { return lo / 8U; }

    /// @return the byte containing the highest-numbered bit in this range.
    int hiByte() const { return hi / 8U; }

    /// @return the next byte that starts after the end of this interval.
    int nextByte() const { return hiByte() + 1; }

    /// @return true if the lowest-numbered bit in this range is
    /// byte-aligned.
    bool isLoAligned() const { return lo % 8 == 0; }

    /// @return true if the highest-numbered bit in this range is
    /// byte-aligned (meaning that this range stops right before the
    /// beginning of a new byte).
    bool isHiAligned() const { return hi % 8 == 7; }

    bool operator==(const bit_range& other) const {
        return other.lo == lo && other.hi == hi;
    }
    bool operator!=(const bit_range& other) const { return !(*this == other); }

    bool contains(int bit) const      { return bit >= lo && bit <= hi; }
    bool overlaps(bit_range a) const  { return contains(a.lo) || a.contains(lo); }
    bool overlaps(int l, int h) const { return contains(l) || (lo >= l && lo <= h); }

    /// @return a range which contains all the bits which are included in both
    /// this range and the provided range, or boost::none if there are no
    /// bits in common.
    boost::optional<bit_range> intersectWith(bit_range a) const {
        return intersectWith(a.lo, a.hi);
    }
    boost::optional<bit_range> intersectWith(int l, int h) const {
        bit_range rv = { std::max(lo, l), std::min(hi, h) };
        if (rv.hi <= rv.lo) return boost::none;
        return rv;
    }

    /// @return the smallest range that contains all of the bits in both this
    /// range and the provided range.
    bit_range unionWith(bit_range a) const {
        return unionWith(a.lo, a.hi);
    }
    bit_range unionWith(int l, int h) const {
        bit_range rv = { std::min(lo, l), std::max(hi, h) };
        BUG_CHECK(rv.lo <= rv.hi, "invalid bit_range::unionWith");
        return rv;
    }

    /// @return this range, but reinterpreted as a region within a space of
    /// the provided size and represented in the specified bit order.
    template <Endian DestOrder>
    bit_range<DestOrder> toSpace(int spaceSize) {
        BUG_CHECK(spaceSize > 0, "Can't represent an empty range");
        if (DestOrder == Order) return bit_range<DestOrder>(lo, hi);
        switch (DestOrder) {
            case Endian::Network:
                return bit_range<DestOrder>((spaceSize - 1) - hi,
                                            (spaceSize - 1) - lo);
            case Endian::Little:
                return bit_range<DestOrder>((spaceSize - 1) - hi,
                                            (spaceSize - 1) - lo);
        }
        BUG("Unexpected bit order");
    }

    /// The lowest numbered bit in the range. For Endian::Network, this is the
    /// most significant bit; for Endian::Little, it's the least significant.
    int lo;

    /// The highest numbered bit in the range. For Endian::Network, this is the
    /// least significant bit; for Endian::Little, it's the most significant.
    int hi;
};

/// A half-open range of bits specified in terms of a specific bit order.
template <Endian Order>
struct bit_interval {
    bit_interval() : lo(0), hi(0) { }
    bit_interval(int lo, int hi) : lo(lo), hi(hi) { }

    int size() const                  { return hi - lo; }
    operator std::pair<int, int>()    { return std::make_pair(lo, hi); }

    /// @return a new interval with the same size, but shifted towards the
    /// high-numbered bits by the provided amount. No rotation or clamping
    /// to zero is applied.
    bit_interval shiftedBy(int offset) const {
        return empty() ? bit_interval() : bit_interval(lo + offset, hi + offset);
    }

    /// @return the byte containing the lowest-numbered bit in this interval.
    int loByte() const { return empty() ? 0 : lo / 8U; }

    /// @return the byte containing the highest-numbered bit in this interval.
    int hiByte() const { return empty() ? 0 : (hi - 1) / 8U; }

    /// @return the next byte that starts after the end of this interval.
    int nextByte() const { return empty() ? 0 : hiByte() + 1; }

    /// @return true if the lowest-numbered bit in this interval is
    /// byte-aligned.
    bool isLoAligned() const { return empty() ? true : lo % 8 == 0; }

    /// @return true if the highest-numbered bit in this interval is
    /// byte-aligned (meaning that this interval stops right before the
    /// beginning of a new byte).
    bool isHiAligned() const { return empty() ? true : hi % 8 == 0; }

    bool operator==(const bit_interval& other) const {
        if (empty()) return other.empty();
        return other.lo == lo && other.hi == hi;
    }
    bool operator!=(const bit_interval& other) const { return !(*this == other); }

    bool empty() const                { return lo == hi; }
    bool contains(int bit) const      { return bit >= lo && bit < hi; }

    // XXX(seth): Do two empty bit_intervals overlap? Right now the answer is no.
    bool overlaps(bit_interval a) const  { return contains(a.lo) || a.contains(lo); }
    bool overlaps(int l, int h) const { return contains(l) || (lo >= l && lo <= h); }

    /// @return an interval which contains all the bits which are included in both
    /// this interval and the provided interval, or an empty interval if there
    /// are no bits in common.
    bit_interval intersectWith(bit_interval a) const {
        return intersectWith(a.lo, a.hi);
    }
    bit_interval intersectWith(int l, int h) const {
        bit_interval rv = { std::max(lo, l), std::min(hi, h) };
        if (rv.hi <= rv.lo) return {0, 0};
        return rv;
    }

    /// @return the smallest interval that contains all of the bits in both this
    /// interval and the provided interval.
    bit_interval unionWith(bit_interval a) const {
        return unionWith(a.lo, a.hi);
    }
    bit_interval unionWith(int l, int h) const {
        if (empty()) return {l, h};
        if (l == h) return *this;
        bit_interval rv = { std::min(lo, l), std::max(hi, h) };
        BUG_CHECK(rv.lo <= rv.hi, "invalid bit_interval::unionWith");
        return rv;
    }

    /// @return this interval, but reinterpreted as a region within a space of
    /// the provided size and represented in the specified bit order.
    template <Endian DestOrder>
    bit_interval<DestOrder> toSpace(int spaceSize) {
        if (DestOrder == Order) return bit_interval<DestOrder>(lo, hi);
        switch (DestOrder) {
            case Endian::Network:
                return bit_interval<DestOrder>(spaceSize - hi, spaceSize - lo);
            case Endian::Little:
                return bit_interval<DestOrder>(spaceSize - hi, spaceSize - lo);
        }
        BUG("Unexpected bit order");
    }

    /// The lowest numbered bit in the range. For Endian::Network, this is the
    /// most significant bit; for Endian::Little, it's the least significant.
    int lo;

    /// The highest numbered bit in the range. For Endian::Network, this is the
    /// least significant bit; for Endian::Little, it's the most significant.
    int hi;
};

/// Convenience typedefs.
using nw_bitrange = bit_range<Endian::Network>;
using le_bitrange = bit_range<Endian::Little>;
using nw_bitinterval = bit_interval<Endian::Network>;
using le_bitinterval = bit_interval<Endian::Little>;

/// A compatibility typedef for old code which didn't specify units explicitly.
using bitrange = bit_range<Endian::Little>;

std::ostream& operator<<(std::ostream&, const bit_range<Endian::Network>&);
std::ostream& operator<<(std::ostream&, const bit_range<Endian::Little>&);
std::ostream& operator<<(std::ostream&, const bit_interval<Endian::Network>&);
std::ostream& operator<<(std::ostream&, const bit_interval<Endian::Little>&);

#endif /* _EXTENSIONS_TOFINO_IR_BITRANGE_H_ */
