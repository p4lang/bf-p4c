#ifndef _TOFINO_PHV_PHV_H_
#define _TOFINO_PHV_PHV_H_

#include <string.h>
#include <iostream>
#include "lib/exceptions.h"
#include <array>

namespace PHV {
constexpr int kPhvMauGroupOffset = 0;
constexpr int kNumPhvMauGroups = 14;
constexpr int kNumMauUnusedGroups = 2;
constexpr int kTPhvMauGroupOffset = kNumPhvMauGroups + kNumMauUnusedGroups;
constexpr int kNumTPhvMauGroups = 7;
constexpr int kNumMauGroups = (kNumPhvMauGroups + kNumMauUnusedGroups +
                               kNumTPhvMauGroups);
constexpr int kTPhvContainerOffset = 256;
constexpr int kNumTPhvContainers = 112;
// This is the highest possible number for a PHV/T-PHV.
constexpr int kMaxContainer = kTPhvContainerOffset + kNumTPhvContainers;
constexpr int kNumContainersPerMauGroup = 16;
static const std::vector<int> kMauGroupSizes({2, 2, 2, 2, 0, 0, 0, 0, 1, 1,
                                              1, 1, 1, 1, 3, 3, 2, 2, 0, 0,
                                              1, 1, 1});
static const std::vector<int> k8bMauGroups({4, 5, 6, 7, 18, 19});
static const std::vector<int> k16bMauGroups({8, 9, 10, 11, 12, 13, 20, 21,
                                             22});
static const std::vector<int> k32bMauGroups({0, 1, 2, 3, 16, 17});
static const std::vector<int> kInvalidMauGroups({14, 15});

// These variables are used for deparser group constraints.
static const std::vector<int> kIngressMauGroups({0, 4, 8});
static const std::vector<int> kEgressMauGroups({1, 5, 9});
static constexpr int kNumDeparserGroups = 23;
static const
std::array<std::vector<int>, kNumDeparserGroups> kDeparserGroups =
  {{{32},
    {36},
    {40},
    {44},
    {48},
    {96},
    {104},
    {112},
    {160},
    {168},
    {176},
    {184},
    {192},
    {200},
    {208},
////{{36, 60, 96, 120, 160, 216, 224}},
////{{40, 60, 96, 120, 160, 216, 224}},
////{{44, 60, 96, 120, 160, 216, 224}},
////{{48, 60, 96, 120, 160, 216, 224}},
////{{52, 60, 96, 120, 160, 216, 224}},
////{{56, 60, 96, 120, 160, 216, 224}},
////{{96, 120, 160, 216, 224}},
////{{104, 120, 160, 216, 224}},
////{{112, 120, 160, 216, 224}},
////{{160, 216, 224}},
////{{168, 216, 224}},
////{{176, 216, 224}},
////{{184, 216, 224}},
////{{192, 216, 224}},
////{{200, 216, 224}},
////{{208, 216, 224}},
    {256},
    {260, 288, 292, 320, 326},
    {264, 288, 296, 320, 332},
    {268, 288, 300, 320, 338},
    {272, 288, 304, 320, 344},
    {276, 288, 308, 320, 350},
    {280, 288, 312, 320, 356},
    {284, 288, 316, 320, 362}}};
const std::array<int, 4> kSharedDeparserGroups = {{0, 5, 8, 15}};
class Container {
    bool        tagalong_ : 1;
    unsigned    log2sz_ : 2;   // 3 (8 byte) means invalid
    unsigned    index_ : 13;
    Container(bool t, unsigned ls, unsigned i) : tagalong_(t), log2sz_(ls), index_(i) {}

 public:
    Container() : tagalong_(false), log2sz_(3), index_(0) {}
    Container(const char *name) {       // NOLINT(runtime/explicit)
        const char *n = name;
        if (*name == 'T') {
            tagalong_ = true;
            n++;
        } else {
            tagalong_ = false; }
        switch (*n++) {
        case 'B': log2sz_ = 0; break;
        case 'H': log2sz_ = 1; break;
        case 'W': log2sz_ = 2; break;
        default: BUG("Invalid register '%s'", name); }
        int v = strtol(n, const_cast<char **>(&n), 10);
        index_ = v;
        if (*n || index_ != v)
            BUG("Invalid register '%s'", name); }
    Container(unsigned mau_group, unsigned container_in_group) :
      tagalong_(false), log2sz_(kMauGroupSizes.at(mau_group)), index_(0) {
      index_ = mau_group * kNumContainersPerMauGroup + container_in_group;
      if (index_ >= kTPhvContainerOffset &&
          index_ < kTPhvContainerOffset + kNumTPhvContainers) tagalong_ = true;
    }

    size_t size() const { return 8U << log2sz_; }
    unsigned index() const { return index_; }
    explicit operator bool() const { return log2sz_ != 3; }
    Container operator++() {
        if (index_ != 0x7ff) ++index_;
        return *this; }
    Container operator++(int) { Container rv = *this; ++*this; return rv; }
    bool operator==(Container c) const {
        return tagalong_ == c.tagalong_ && log2sz_ == c.log2sz_ && index_ == c.index_; }
    friend std::ostream &operator<<(std::ostream &out, Container c);
    static Container B(unsigned idx) { return Container(false, 0, idx); }
    static Container H(unsigned idx) { return Container(false, 1, idx); }
    static Container W(unsigned idx) { return Container(false, 2, idx); }
    static Container TB(unsigned idx) { return Container(true, 0, idx); }
    static Container TH(unsigned idx) { return Container(true, 1, idx); }
    static Container TW(unsigned idx) { return Container(true, 2, idx); }
};

inline std::ostream &operator<<(std::ostream &out, PHV::Container c) {
    return out << (c.tagalong_ ? "T" : "") << "BHW?"[c.log2sz_] << c.index_; }

// A pair to uniquely identify every bit in the P4 program. The cstring is the
// name of the header and the int is the offset of the bit within the header.
class Bit : public std::pair<cstring, int> {
 public:
  Bit() : std::pair<cstring, int>("", -1) { } // This creates an invalid bit.
  Bit(const cstring &n, const int &i) : std::pair<cstring, int>(n, i) { }
  std::string name() const {
    return first + "[" + std::to_string(second) + "]"; }
  bool IsValid() const { return (second >= 0) && (first.size() > 0); }
};

inline std::ostream &operator<<(std::ostream &out, const PHV::Bit &b) {
  return out << b.first << "[" << b.second << "]";
}

class Bits : public std::vector<PHV::Bit> {
 public:
  Bits(std::vector<PHV::Bits>::size_type c) : std::vector<PHV::Bit>(c) { }
  template<class T> Bits(T b, T e) : std::vector<PHV::Bit>(b, e) { }
};

inline std::ostream &operator<<(std::ostream &out, const PHV::Bits &b) {
  if (b.size() > 0) {
    // FIXME: This must be fixed to print bit sequence of bits from different
    // headers and non-contiguous bits offsets.
    out << b.front().first << "[" << b.front().second << ":" <<
      b.back().second << "]";
  }
  return out;
}

class Byte : public ::std::array<Bit, 8> {
 public:
  std::string name() const {
    auto last_bit = cfirst();
    while (std::next(last_bit, 1) != end() &&
           std::next(last_bit, 1)->second >= 0) ++last_bit;
    return cfirst()->first + "[" + std::to_string(cfirst()->second) + ":" +
           std::to_string(last_bit->second) + "]"; }
  bool Contains(const Bit &bit) const {
    for (auto b : (*this)) {
      if (b == bit) return true;
    }
    return false;
  }
  iterator first() {
    auto it = begin();
    while (it->second < 0) ++it;
    return it;
  }
  const_iterator cfirst() const {
    auto it = cbegin();
    while (it->second < 0) ++it;
    return it;
  }
  iterator last() {
    auto it = first();
    while (it != end() && it->second >= 0) ++it;
    return it;
  }
  const_iterator clast() const {
    auto it = cfirst();
    while (it != cend() && it->second >= 0) ++it;
    return it;
  }
  Bits valid_bits() const {
    return Bits(cfirst(), clast());
  }
};
}  // namespace PHV
#endif /* _TOFINO_PHV_PHV_H_ */
