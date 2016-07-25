#ifndef TOFINO_PHV_OR_TOOLS_BIT_H_
#define TOFINO_PHV_OR_TOOLS_BIT_H_
#include <array>
#include "lib/cstring.h"
namespace operations_research {
class IntExpr;
class IntVar;
}
namespace or_tools {
class Byte;
class Container;
class MauGroup;
class Bit {
 public:
    explicit Bit(const cstring &name)
    : container_(nullptr), base_offset_(nullptr), offset_(nullptr),
      byte_(nullptr), bit_(nullptr), name_(name) { }
    cstring name() const { return name_; }
    void set_container(Container *container);
    Container *container() const { return container_; }
    MauGroup *mau_group() const;
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
    // Sets conflicts between 2 bits from the bit-conflict matrix.
    void SetConflict(Bit &bit);
    // Compare two bit objects.
    bool operator!=(const Bit &bit) const { return bit.name() != name(); }

 private:
    void CreateByte(const std::array<Bit *, 8> &bits);
    // Container-specific constraint variables. Bits that are constrained to the
    // same container must point to the same or_tools::Container object.
    or_tools::Container *container_;
    // Offset within a PHV container of first bit of the byte where this bit
    // resides.
    operations_research::IntVar *base_offset_;
    // This is derived from base_offset:
    // offset_ = base_offset_ + relative_offset_.
    operations_research::IntExpr *offset_;
    // Offset from base_offset_. For packet header bits, it has to be in range
    // [0, 7].
    int relative_offset_;
    // Pointer to or_tools::Byte object for this bit.
    Byte *byte_;
    // This is a value in the range [0, MaxContainerNumber * 32). It is unique
    // for every bit in every PHV container.
    operations_research::IntExpr *bit_;
    // Returns bit_. If bit_ was nullptr, it creates an IntExpr object.
    operations_research::IntExpr *MakeBit();

    const cstring name_;
};
}  // namespace or_tools
#endif /* TOFINO_PHV_OR_TOOLS_BIT_H_ */
