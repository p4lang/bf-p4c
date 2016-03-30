#ifndef _TOFINO_PHV_ORTOOLS_SOLVER_H_
#define _TOFINO_PHV_ORTOOLS_SOLVER_H_
#include "backends/tofino/phv/solver_interface.h"
#include "bit.h"
#include "byte.h"
#include "backends/tofino/phv/phv.h"
#include <constraint_solver/constraint_solver.h>
#include <set>
#include <vector>
namespace ORTools {
class Solver : public SolverInterface {
 public:
  Solver() : solver_("phv-allocator") { }
  // Creates variables/constraints to allocate all members of bits to the same
  // MAU group.
  void SetEqualMauGroup(const std::set<PHV::Bit> &bits) override;
  // Creates variables/constraints to allocate all members of bits to the same
  // container.
  void SetEqualContainer(const std::set<PHV::Bit> &bits) override;
  // Creates variables/constraints to allocate all members of bits to the same
  // byte within a PHV container.
  void SetByte(const PHV::Byte &byte) override;
  // Creates variables/constraints to allocate all members of bits to the same
  // bit offset. The members of bits are probably allocated to different PHV
  // containers (not overlayed).
  void SetEqualOffset(const std::set<PHV::Bit> &bits) override;
  // Creates constraints to allocate byte to the first byte of a PHV container.
  // This function is usually called for the first byte of a deparsed header.
  void SetFirstDeparsedHeaderByte(const PHV::Byte &byte) override;
  // Creates constraints to allocate byte1 and byte2 to consecutive bytes a the
  // PHV container or to the last and first bytes (respectively) of different
  // PHV containers.
  void SetDeparsedHeader(const PHV::Byte &byte1,
                         const PHV::Byte &byte2) override;
  // Creates constraints to allocate last_byte to the last byte of a PHV
  // containers. This function is usually invoked for the last byte of a
  // deparsed header.
  void SetLastDeparsedHeaderByte(const PHV::Byte &last_byte) override;
  // Creates constraints to allocate i_hdr_byte and e_hdr_byte to different
  // deparser groups. It also prevents allocation of both bytes to PHV
  // containers that are statically assigned to the other thread. For example,
  // i_hdr_byte will never be allocated to PHV containers 16-31 because these
  // are assigned to egress thread.
  void SetDeparserGroups(const PHV::Byte &i_hdr_byte,
                         const PHV::Byte &e_hdr_byte) override;
  // Creates constraints for the match xbar width. match_phv_bits is a set of
  // PHV::Bit objects that are used as keys for match tables in the same stage.
  // match_phv_bits must be byte de-duplicated. For example, if a table does a
  // lookup on IPv4 destination address (4B wide), match_phv_bits must contain
  // only 4 bits (each from a different byte) of the IPv4 destination address.
  void SetMatchXbarWidth(const std::vector<PHV::Bit> &match_phv_bits,
                         const std::array<int, 4> &width) override;
  // Creates constraints to prevent allocating bit to T-PHV.
  void SetNoTPhv(const PHV::Bit &bit) override;
  // Retrieve the allocation for bit. This function can be called only after a
  // solution has been found.
  void allocation(const PHV::Bit &bit, PHV::Container *c, int *container_bit);
 protected:
  bool Solve1(operations_research::Solver::IntValueStrategy int_val);
 private:
  std::vector<operations_research::IntVar*> GetIntVars() const;
  std::vector<operations_research::IntVar*> mau_groups() const;
  std::vector<operations_research::IntVar*>
  containers_and_offsets(operations_research::IntVar *mau_group) const;
  void SetUniqueConstraint(
    const std::vector<operations_research::IntVar*> &is_unique_flags,
    const std::vector<Bit*> &bits,
    const std::array<int, 4> &unique_bytes,
    const std::array<std::size_t, 2> &byte_offsets);
  // This function sets constraints on base_offset variables in Bit objects
  // depending on the MAU group. For example, a Bit allocated to a 16b MAU
  // group, then base_offset + relative_offset must be less than 16.
  void SetContainerWidthConstraints();
  // Functions for creating IntVar objects for a bit.
  operations_research::IntVar *
  MakeMauGroup(const cstring &name,
               std::array<operations_research::IntVar*, 3> *flags);
  operations_research::IntVar *
  GetWidthFlag(operations_research::IntVar *mau_group,
               const std::vector<int> &groups);
  operations_research::IntVar *MakeContainerInGroup(const cstring &name);
  operations_research::IntExpr *
  MakeContainer(operations_research::IntVar *group,
                operations_research::IntVar *container_in_group);
  operations_research::IntVar *MakeByteAlignedOffset(const cstring &name);
  operations_research::IntVar *MakeOffset(const cstring &name);
  operations_research::IntExpr *MakeDeparserGroupFlag(
    const int &group_num, operations_research::IntExpr *container);
  // Returns an array of Bit* objects for a PHV::Byte.
  std::array<ORTools::Bit *, 8> get_bits(const PHV::Byte &byte) {
    std::array<ORTools::Bit *, 8> bits;
    std::transform(byte.begin(), byte.end(), bits.begin(),
                   [this](const PHV::Bit &b) -> Bit * {
                     return &bits_.at(b); });
    return bits;
  }
  operations_research::Solver solver_;
  std::map<PHV::Bit, ORTools::Bit> bits_;

  // Variable for generating unique names for IntVar objects.
  int unique_id() { return ++unique_id_; }
  static int unique_id_;
};
}
#endif
