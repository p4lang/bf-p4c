#ifndef _TOFINO_PHV_ORTOOLS_BIT_H_
#define _TOFINO_PHV_ORTOOLS_BIT_H_
#include "lib/cstring.h"
#include <array>
namespace operations_research {
  class IntExpr;
  class IntVar;
}
namespace ORTools {
class Bit {
 public:
  Bit(const cstring &name) :
    mau_group_(nullptr), container_in_group_(nullptr), base_offset_(nullptr),
    offset_(nullptr), container_(nullptr), byte_(nullptr), name_(name) { }
  cstring name() const { return name_; }
  void set_mau_group(operations_research::IntVar *const group,
                     const std::array<operations_research::IntVar*, 3> &is_xb);
  operations_research::IntVar *mau_group() const { return mau_group_; }
  operations_research::IntVar* is_8b() const { return is_8b_; }
  operations_research::IntVar* is_16b() const { return is_16b_; }
  operations_research::IntVar* is_32b() const { return is_32b_; }

  void set_container(operations_research::IntVar *const container_in_group,
                     operations_research::IntExpr *const container);
  operations_research::IntVar *
  container_in_group() const { return container_in_group_; }
  operations_research::IntExpr *container() const { return container_; }

  // Variables for offset within a container.
  void set_offset(operations_research::IntVar *base_offset,
                  const int &relative_offset);
  void CopyOffset(const Bit &bit);
  operations_research::IntExpr *offset() const { return offset_; }
  operations_research::IntVar *base_offset() const { return base_offset_; }
  int relative_offset() const { return relative_offset_; }
  // Flags to indicate the parent byte in the container for this bit.
  void CopyByte(const Bit &bit) {
    is_last_byte_ = bit.is_last_byte();
    byte_offset_flags_ = byte_offset_flags(); }
  operations_research::IntVar *is_last_byte() const { return is_last_byte_; }
  std::array<operations_research::IntVar*, 4>
  byte_offset_flags() const { return byte_offset_flags_; }

  // Functions for setting constraints.
  void SetContainerWidthConstraints();
  void SetFirstDeparsedHeaderByte(const std::array<Bit *, 8> &byte);
  void SetDeparsedHeader(const Bit &prev_bit,
                         const std::array<Bit *, 8> &byte);
  // Compare two bit objects.
  bool operator!=(const Bit &bit) const { return bit.name() != name(); }
 private:
  // PHV group of this byte.
  operations_research::IntVar *mau_group_;
  // Container in PHV group of this byte. For Tofino, this has range [0, 15].
  operations_research::IntVar *container_in_group_;
  // Offset within a PHV container of first bit of the byte where this bit
  // resides.
  operations_research::IntVar *base_offset_;
  // This is derived from base_offset:
  // offset_ = base_offset_ + relative_offset_.
  operations_research::IntExpr *offset_;
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
//operations_research::IntVar *is_first_byte_;
  std::array<operations_research::IntVar*, 4> byte_offset_flags_;
  // An expression that uniquely identifies the PHV byte where this variable is
  // allocated. It is computed as (container_ * 4) + byte_inside_container.
  operations_research::IntExpr *byte_;

  const cstring name_;
};
}
#endif
