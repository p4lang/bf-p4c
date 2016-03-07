#ifndef _TOFINO_PHV_CONTAINER_VAR_CREATOR_H_
#define _TOFINO_PHV_CONTAINER_VAR_CREATOR_H_
#include "ir/ir.h"
#include "lib/cstring.h"
#include <map>
#include <set>
namespace IR {
namespace Tofino {
  class Pipe;
}
class HeaderRef;
class HeaderSliceRef;
}
class HeaderBits;
class ContainerVarCreator {
 public:
  explicit ContainerVarCreator(HeaderBits &header_bits) :
    header_bits_(header_bits) { }
  void CreateContainerVars(const IR::Tofino::Pipe *maupipe);
  std::set<std::pair<const IR::HeaderSliceRef*, gress_t>>
  deparsed_header_slices() const {
    std::set<std::pair<const IR::HeaderSliceRef*, gress_t>> hdr_slices;
    for (auto &item : deparsed_header_slices_)
      hdr_slices.insert(item.second);
    return hdr_slices; }
 private:
  void SetParserConstraint(const IR::HeaderRef *header_ref, const int &offset,
                           const int &width_bits);
  HeaderBits &header_bits_;
  std::map<cstring, std::pair<const IR::HeaderSliceRef*, gress_t>>
    deparsed_header_slices_;
  std::map<cstring, const IR::HeaderSliceRef*> parsed_header_slices_;
};
#endif
