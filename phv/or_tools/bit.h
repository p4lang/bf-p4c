#ifndef _TOFINO_PHV_ORTOOLS_BIT_H_
#define _TOFINO_PHV_ORTOOLS_BIT_H_
#include "lib/cstring.h"
#include <array>
namespace operations_research {
  class IntExpr;
  class IntVar;
}
namespace ORTools {
class Byte;
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
  // These functions create (if needed) and return objects which are member of
  // byte_.
  operations_research::IntExpr *offset_bytes() const;
  std::array<operations_research::IntVar*, 4> byte_flags() const;
  // Setter/getter for byte object.
  void set_byte(Byte *byte) { byte_ = byte; }
  Byte *byte() const { return byte_; }
  // Functions for setting constraints.
  void SetContainerWidthConstraints();
  operations_research::IntVar *SetFirstDeparsedHeaderByte();
  operations_research::IntVar *
  SetDeparsedHeader(const Bit &prev_bit, const Byte &prev_byte);
  // Compare two bit objects.
  bool operator!=(const Bit &bit) const { return bit.name() != name(); }
 private:
  void CreateByte(const std::array<Bit *, 8> &bits);
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
  // Pointer to ORTools::Byte object for this bit.
  Byte *byte_;

  const cstring name_;
};
}
#endif
