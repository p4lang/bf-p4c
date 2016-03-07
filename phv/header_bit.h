#ifndef _TOFINO_PHV_HEADER_BIT_H_
#define _TOFINO_PHV_HEADER_BIT_H_
#include "ir/ir.h"
#include "lib/cstring.h"
#include <map>
#include <vector>
namespace operations_research {
  class IntExpr;
  class IntVar;
  class Solver;
}
class HeaderBit {
 public:
  HeaderBit(const cstring &name) :
    mau_group_(nullptr), container_in_group_(nullptr), container_(nullptr),
    byte_(nullptr), name_(name) { }
  cstring name() const { return name_; }
  bool set_group(operations_research::IntVar *const group,
                 const std::array<operations_research::IntVar*, 3> &is_xb) {
    auto old_group = mau_group_;
    mau_group_ = group;
    is_8b_ = is_xb[0];
    is_16b_ = is_xb[1];
    is_32b_ = is_xb[2];
    return old_group != mau_group_; }
  operations_research::IntVar *group() const { return mau_group_; }

  void set_container(operations_research::IntVar *const container_in_group,
                     operations_research::IntExpr *const container);
  operations_research::IntVar *
  container_in_group() const { return container_in_group_; }
  template<class T=operations_research::IntExpr*> T container() const;

  void set_offset(operations_research::IntVar *const base_offset,
                  const int &relative_offset = 0,
                  operations_research::Solver *solver = nullptr);
  void set_offset(const HeaderBit &prev_bit, const int &relative_offset,
                  operations_research::Solver &solver);
  operations_research::IntExpr *offset() const { return offset_; }
  operations_research::IntVar *base_offset() const { return base_offset_; }
  operations_research::IntExpr *byte() const { return byte_; }
  std::array<operations_research::IntVar*, 4>
  byte_offset_flags() const { return byte_offset_flags_; }
  int relative_offset() const { return relative_offset_; }

  void set_is_8b(operations_research::IntVar *is_8b) { is_8b_ = is_8b; }
  operations_research::IntVar *is_8b() const { return is_8b_; }
  void set_is_16b(operations_research::IntVar *is_16b) { is_16b_ = is_16b; }
  operations_research::IntVar *is_16b() const { return is_16b_; }
  void set_is_32b(operations_research::IntVar *is_32b) { is_32b_ = is_32b; }
  operations_research::IntVar *is_32b() const { return is_32b_; }
  std::array<operations_research::IntVar*, 3> width_flags() const {
    return std::array<operations_research::IntVar*, 3>{{is_8b_, is_16b_,
                                                        is_32b_}}; }
  void set_is_last_byte(operations_research::IntVar *is_last_byte) {
    is_last_byte_ = is_last_byte; }
  operations_research::IntVar *is_last_byte() const { return is_last_byte_; }

  // Functions for setting constraints between variables.
  void CopyMauGroup(const HeaderBit *header_bit);
  void CopyContainer(const HeaderBit *header_bit);
  void SetGroupFlag(operations_research::Solver &s,
                    const std::vector<int> &groups,
                    operations_research::IntVar *v) const;
  void SetContainerWidthConstraints(operations_research::Solver &solver) const;
  void SetLastDeparsedHeaderByteConstraint(operations_research::Solver &solver);
  void SetDeparserConstraints(const HeaderBit *prev_bit,
                              const gress_t &gress,
                              operations_research::Solver &solver);
 private:
  // PHV group of this byte.
  operations_research::IntVar *mau_group_;
  // Container in PHV group of this byte. For Tofino, this has range [0, 15].
  operations_research::IntVar *container_in_group_;
  // Offset within a PHV container.
  operations_research::IntExpr *offset_;
  // Offset within a PHV container of first bit of the byte where this bit
  // resides.
  operations_research::IntVar *base_offset_;
  // Offset from base_offset_. For packet header bits, it has to be in range
  // [0, 7].
  int relative_offset_;
  operations_research::IntExpr *container_;
  // These are flags to indicate if the bit has been allocated to a 8b, 16b
  // or 32b container.
  operations_research::IntVar *is_8b_, *is_16b_, *is_32b_;
  // Flag to indicate if this bit has been allocated to the last byte of the
  // container.
  operations_research::IntVar *is_last_byte_;
  // This flags was introduced for expressing the deparser constraint. It
  // indicates if this bit is allocated in the first byte of a container. If
  // this flag is true (== 1), offset_ must be in range [0, 7].
  operations_research::IntVar *is_first_byte_;
  std::array<operations_research::IntVar*, 4> byte_offset_flags_;
  // An expression that uniquely identifies the PHV byte where this variable is
  // allocated. It is computed as (container_ * 4) + byte_inside_container.
  operations_research::IntExpr *byte_;

  const cstring name_;
};
#endif
