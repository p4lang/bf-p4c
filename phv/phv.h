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
constexpr int kNumTPhvContainers = 256;
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
static const int kNumDeparserGroups = 25;
static const std::map<int, int> kContainerToDeparserGroup = {
  // Deparser groups in 32b PHVs.
  {32, 0}, {33, 0}, {34, 0}, {35, 0},
  {36, 1}, {37, 1}, {38, 1}, {39, 1},
  {40, 2}, {41, 2}, {42, 2}, {43, 2},
  {44, 3}, {45, 3}, {46, 3}, {47, 3},
  {48, 4}, {49, 4}, {50, 4}, {51, 4},
  {52, 5}, {53, 5}, {54, 5}, {55, 5},
  {56, 6}, {57, 6}, {58, 6}, {59, 6},
  // Skipping last deparser group in 32b PHV since its members can be
  // assigned to any thread individually.
  // Deparser groups in 8b PHVs.
  {96, 7}, {97, 7}, {98, 7}, {99, 7},
  {100, 7}, {101, 7}, {102, 7}, {103, 7},
  {104, 8}, {105, 8}, {106, 8}, {107, 8},
  {108, 8}, {109, 8}, {110, 8}, {111, 8},
  {112, 9}, {113, 9}, {114, 9}, {115, 9},
  {116, 9}, {117, 9}, {118, 9}, {119, 9},
  // Deparser groups in 16b PHVs.
  {160, 10}, {161, 10}, {162, 10}, {163, 10},
  {164, 10}, {165, 10}, {166, 10}, {167, 10},
  {168, 11}, {169, 11}, {170, 11}, {171, 11},
  {172, 11}, {173, 11}, {174, 11}, {175, 11},
  {176, 12}, {177, 12}, {178, 12}, {179, 12},
  {180, 12}, {181, 12}, {182, 12}, {183, 12},
  {184, 13}, {185, 13}, {186, 13}, {187, 13},
  {188, 13}, {189, 13}, {190, 13}, {191, 13},
  {192, 14}, {193, 14}, {194, 14}, {195, 14},
  {196, 14}, {197, 14}, {198, 14}, {199, 14},
  {200, 15}, {201, 15}, {202, 15}, {203, 15},
  {204, 15}, {205, 15}, {206, 15}, {207, 15},
  {208, 16}, {209, 16}, {210, 16}, {211, 16},
  {212, 16}, {213, 16}, {214, 16}, {215, 16},
  {256, 17}, {257, 17}, {258, 17}, {259, 17},
  {260, 18}, {261, 18}, {262, 18}, {263, 18},
  {264, 19}, {265, 19}, {266, 19}, {267, 19},
  {268, 20}, {269, 20}, {270, 20}, {271, 20},
  {272, 21}, {273, 21}, {274, 21}, {275, 21},
  {276, 22}, {277, 22}, {278, 22}, {279, 22},
  {280, 23}, {281, 23}, {282, 23}, {283, 23},
  {284, 24}, {285, 24}, {286, 24}, {287, 24},
  {288, 17}, {289, 17}, {290, 17}, {291, 17},
  {292, 18}, {293, 18}, {294, 18}, {295, 18},
  {296, 19}, {297, 19}, {298, 19}, {299, 19},
  {300, 20}, {301, 20}, {302, 20}, {303, 20},
  {304, 21}, {305, 21}, {306, 21}, {307, 21},
  {308, 22}, {309, 22}, {310, 22}, {311, 22},
  {312, 23}, {313, 23}, {314, 23}, {315, 23},
  {316, 24}, {317, 24}, {318, 24}, {319, 24},
  // Deparser groups in 16b TPHVs.
  {320, 17}, {321, 17}, {322, 17}, {323, 17}, {324, 17}, {325, 17},
  {326, 18}, {327, 18}, {328, 18}, {329, 18}, {330, 18}, {331, 18},
  {332, 19}, {333, 19}, {334, 19}, {335, 19}, {336, 19}, {337, 19},
  {338, 20}, {339, 20}, {340, 20}, {341, 20}, {342, 20}, {343, 20},
  {344, 21}, {345, 21}, {346, 21}, {347, 21}, {348, 21}, {349, 21},
  {350, 22}, {351, 22}, {352, 22}, {353, 22}, {354, 22}, {355, 22},
  {356, 23}, {357, 23}, {358, 23}, {359, 23}, {360, 23}, {361, 23},
  {362, 24}, {363, 24}, {364, 24}, {365, 24}, {366, 24}, {367, 24}
};

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
};

inline std::ostream &operator<<(std::ostream &out, const PHV::Bit &b) {
  return out << b.first << "[" << b.second << "]";
}

class Bits : public std::vector<PHV::Bit> {
 public:
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
