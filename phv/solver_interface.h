#ifndef _TOFINO_PHV_SOLVER_INTERFACE_H_
#define _TOFINO_PHV_SOLVER_INTERFACE_H_
#include "phv.h"
#include <functional>
#include <set>
class SolverInterface {
 public:
  virtual void SetByte(const PHV::Byte &byte) = 0;
  virtual void
  SetOffset(const PHV::Bit &pbit, const int &min, const int &max) = 0;
  virtual void
  SetContiguousBits(const PHV::Bit &pbit1, const PHV::Bit &pbit2) = 0;
  virtual void SetEqualMauGroup(const std::set<PHV::Bit> &bits) = 0;
  virtual void SetEqualContainer(const std::set<PHV::Bit> &bits) = 0;
  virtual void SetEqualOffset(const std::set<PHV::Bit> &bits) = 0;

  virtual void SetFirstDeparsedHeaderByte(const PHV::Byte &byte) = 0;
  // Set constraints for deparsed bytes. This function must be called for every
  // consecutive pair of bytes in the header. For example, if the header has N
  // bytes, this function must be called N-1 times.
  virtual void SetDeparsedHeader(const PHV::Byte &byte1,
                                 const PHV::Byte &byte2) = 0;
  // This function must be called just once (for the last byte) per deparsed
  // header.
  virtual void SetLastDeparsedHeaderByte(const PHV::Byte &last_byte) = 0;
  virtual void SetDeparserGroups(const PHV::Byte &i_hdr_byte,
                                 const PHV::Byte &e_hdr_byte) = 0;
  // This function specifies the match bits used for exact/TCAM matches.
  // FIXME: We must send the container conflict matrix too. Bits which cannot
  // exist in the same container can never share the same match xbar byte.
  virtual void SetMatchXbarWidth(const std::vector<PHV::Bit> &bits,
                                 const std::array<int, 4> &width) = 0;
  // This function must prevent the bit from being allocated to T-PHV.
  virtual void SetNoTPhv(const PHV::Bit &bit) = 0;
  // Function for getting the allocation that a bit that satisfies all
  // constraints.
  virtual void
  allocation(const PHV::Bit &bit, PHV::Container *c, int *container_bit) = 0;

  typedef std::function<void(const std::set<PHV::Bit> &)> SetEqual;
};
#endif
