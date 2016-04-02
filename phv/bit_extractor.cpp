#include "bit_extractor.h"
#include "ir/ir.h"
#include <base/logging.h>
std::set<std::pair<PHV::Bit, PHV::Bit>>
BitExtractor::GetBitPairs(const IR::Expression *e1,
                          const IR::Expression *e2) {
  std::set<std::pair<PHV::Bit, PHV::Bit>> bit_pairs;
  auto hsr1 = e1->to<IR::HeaderSliceRef>();
  auto hsr2 = (nullptr == e2 ? nullptr : e2->to<IR::HeaderSliceRef>());
  if (hsr1 != nullptr && hsr2 != nullptr) {
    int width = std::min(hsr1->type->width_bits(), hsr2->type->width_bits());
    for (int i = 0; i < width; ++i) {
      PHV::Bit bit1 = PHV::Bit(hsr1->header_ref()->toString(),
                               hsr1->offset_bits() + i);
      PHV::Bit bit2 = PHV::Bit(hsr2->header_ref()->toString(),
                               hsr2->offset_bits() + i);
      if (bit_pairs.count(std::make_pair(bit1, bit2)) == 0) {
        bit_pairs.insert(std::make_pair(bit2, bit1));
      }
    }
  }
  return bit_pairs;
}

std::list<PHV::Bit> BitExtractor::GetBits(const IR::Expression *e1) const {
  const IR::HeaderSliceRef *hsr = e1->to<IR::HeaderSliceRef>();
  std::list<PHV::Bit> bits;
  if (nullptr == hsr) return bits;
  for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
    bits.emplace_back(hsr->header_ref()->toString(), i);
  }
  return bits;
}

std::list<PHV::Byte>
BitExtractor::GetBytes(const IR::Expression *e1, const IR::Expression *e2) {
  auto hsr1 = e1->to<IR::HeaderSliceRef>();
  // Exit the function if we do not have a HeaderSliceRef for the source.
  if (nullptr == hsr1) return GetBytes(e1->to<IR::HeaderRef>());
  else return GetBytes(hsr1, e2);
}

std::list<PHV::Byte>
BitExtractor::GetBytes(const IR::HeaderRef *hr) {
  CHECK(nullptr != hr);
  const IR::HeaderSliceRef hsr(hr->srcInfo, hr, hr->type->width_bits() - 1, 0);
  return GetBytes(&hsr);
}

std::list<PHV::Byte>
BitExtractor::GetBytes(const IR::HeaderSliceRef *hsr1,
                       const IR::Expression *e2) {
  auto hsr2 = (nullptr == e2 ? nullptr : e2->to<IR::HeaderSliceRef>());
  int offset = 0;
  if (nullptr != hsr2) offset = (hsr2->offset_bits() % 8);
  std::list<PHV::Byte> bytes;
  for (int i = hsr1->lsb(); i <= hsr1->msb(); offset=0) {
    PHV::Byte new_byte;
    for (int j = 0; j < std::min(8 - offset, hsr1->msb() - i + 1); ++j) {
      new_byte.at(j + offset).first = hsr1->header_ref()->toString();
      new_byte.at(j + offset).second = i + j;
    }
    bytes.push_back(new_byte);
    i += (8 - offset);
  }
  return bytes;
}
