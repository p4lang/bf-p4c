#include "backends/tofino/phv/or_tools/byte_constraint.h"
#include "backends/tofino/phv/header_bit.h"
#include "backends/tofino/phv/header_bits.h"
#include <base/logging.h>

void
or_tools::ByteConstraint::EnforceConstraint(
  const PHV::Bit &bit, const int &width, const int &offset) {
  HeaderBit *prev_header_bit = nullptr;
  int start_offset = offset;
  for (int i = bit.second; i < (bit.second + width); ++i, ++start_offset) {
    auto hdr_bit = header_bits_.get(bit.first, i);
    if (start_offset == 8) start_offset = 0;
    if (hdr_bit->container() == nullptr) {
      if ((prev_header_bit == nullptr) || start_offset == 0) {
        LOG2("Create new container for " << hdr_bit->name() <<
               " with start offset " << start_offset);
        CHECK(hdr_bit->container_in_group() == nullptr) <<
          "; Container variable already exists for " << hdr_bit->name();
        std::array<operations_research::IntVar*, 3> is_xb;
        auto group = header_bits_.MakeGroupVar(hdr_bit->name(), &is_xb);
        hdr_bit->set_group(group, is_xb);
        auto container_in_group = header_bits_.MakeContainerInGroupVar(
                                    hdr_bit->name());
        auto container = header_bits_.MakeContainerExpr(group,
                                                        container_in_group);
        hdr_bit->set_container(container_in_group, container);
        hdr_bit->set_offset(
          header_bits_.MakeByteAlignedOffsetVar(hdr_bit->name()),
          start_offset, header_bits_.solver());
      }
      else {
        hdr_bit->CopyContainer(prev_header_bit);
        hdr_bit->set_offset(*prev_header_bit, 1, *(header_bits_.solver()));
      }
      prev_header_bit = hdr_bit;
    }
    else {
      prev_header_bit = nullptr;
    }
  }
}
