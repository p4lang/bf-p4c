#ifndef _TOFINO_PHV_ORTOOLS_BYTE_H_
#define _TOFINO_PHV_ORTOOLS_BYTE_H_
#include "lib/cstring.h"
#include "backends/tofino/phv/phv.h"
#include <cassert>
namespace operations_research {
class IntExpr;
class IntVar;
}
namespace ORTools {
typedef std::array<operations_research::IntExpr*,
                   PHV::kNumDeparserGroups> DeparserFlags;
class Byte {
 public:
  Byte() : deparser_flags_(), offset_(nullptr), is_last_byte_(nullptr) { }
  //cstring name() const { return phv_byte_.name(); }
  void set_deparser_flag(const size_t &i, operations_research::IntExpr *e) {
    assert(deparser_flags_.at(i) == nullptr);
    deparser_flags_[i] = e; }
  operations_research::IntExpr *deparser_flag(const size_t &i) const {
    return deparser_flags_.at(i); }
  void set_offset(operations_research::IntExpr *offset) { offset_ = offset; }
  operations_research::IntExpr *offset() const { return offset_; }
  void set_flags(const std::array<operations_research::IntVar*, 4> &v) {
    flags_ = v; }
  std::array<operations_research::IntVar*, 4>
  flags() const { return flags_; }
  void set_last_byte(operations_research::IntVar *l) { is_last_byte_ = l; }
  operations_research::IntVar *is_last_byte() const { return is_last_byte_; }
 private:
  DeparserFlags deparser_flags_;
  // An expression that uniquely identifies the PHV byte where this variable is
  // allocated. It is computed as (container_ * 4) + byte_inside_container.
  operations_research::IntExpr *offset_;
  // These flags indicate the byte offset within a PHV container where this
  // byte was allocated. For example, flags_[1] is 1 iff this byte is allocated
  // to the second byte of a PHV container.
  std::array<operations_research::IntVar*, 4> flags_;
  // Flag to indicate if this bit has been allocated to the last byte of the
  // container.
  operations_research::IntVar *is_last_byte_;
};
}
#endif
