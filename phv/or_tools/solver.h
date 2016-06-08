#ifndef TOFINO_PHV_OR_TOOLS_SOLVER_H_
#define TOFINO_PHV_OR_TOOLS_SOLVER_H_
#include <constraint_solver/constraint_solver.h>
#include <set>
#include <vector>
#include "tofino/phv/solver_interface.h"
#include "bit.h"
#include "byte.h"
#include "tofino/phv/phv.h"
#include "ir/ir.h"
namespace or_tools {
class Solver : public SolverInterface {
 public:
  Solver() : solver_("phv-allocator") { }
  // Creates variables/constraints to allocate all members of bits to the same
  // container.
  void SetEqualContainer(const std::set<PHV::Bit> &bits) override;
  // Creates variables/constraints to allocate all members of bits to the same
  // MAU group.
  void SetEqualMauGroup(const std::set<PHV::Bit> &bits,
                        const bool &is_t_phv) override;
  // Creates variables/constraints for offset of bit in a PHV container.
  void SetOffset(const PHV::Bit &pbit, const std::vector<int> &values) override;
  // Creates variables/constraints for offset of bit in a PHV container.
  void SetOffset(const PHV::Bit &pbit, const int &min, const int &max) override;
  // Creates variables/constraints to allocate bits to contiguous bits offsets.
  // This function does not constrain them to be allocated to contiguous bit
  // offsets in the same PHV container. However, all bits are *usually*
  // allocated to the same PHV container because they appear in a set passed to
  // SetEqualContainer.
  void SetBitDistance(const PHV::Bit &pbit1, const PHV::Bit &pbit2,
                      const int &distance) override;
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
  void SetDeparserGroups(const PHV::Byte &i_pbyte, const PHV::Byte &e_pbyte) override;
  void SetDeparserGroups(const PHV::Bit &i_pbit, const PHV::Bit &e_pbit) override;
  // Creates constraints for the match xbar width. match_phv_bits is a set of
  // PHV::Bit objects that are used as keys for match tables in the same stage.
  // match_phv_bits must be byte de-duplicated. For example, if a table does a
  // lookup on IPv4 destination address (4B wide), match_phv_bits must contain
  // only 4 bits (each from a different byte) of the IPv4 destination address.
  void SetMatchXbarWidth(const std::vector<PHV::Bit> &match_phv_bits,
                         const std::array<int, 4> &width) override;
  // Creates constraints to prevent allocating bit to T-PHV.
  void SetNoTPhv(const PHV::Bit &bit) override;
  // Creates a constraints to prevent allocating the two bits into the same PHV
  // container.
  void SetContainerConflict(const PHV::Bit &pb1, const PHV::Bit &pb2) override;
  void SetBitConflict(const PHV::Bit &pb1, const PHV::Bit &pb2) override;
  // Retrieve the allocation for bit. This function can be called only after a
  // solution has been found.
  void allocation(const PHV::Bit &bit, PHV::Container *c, int *container_bit) override;

  virtual bool Solve() = 0;
 protected:
  bool
  Solve1(operations_research::Solver::IntValueStrategy int_val,
         const bool &is_luby_restart = true);

 private:
  std::vector<operations_research::IntVar*> GetIntVars() const;
  std::vector<operations_research::IntVar*> GetMauGroups() const;
  std::vector<operations_research::IntVar*>
  containers_and_offsets(operations_research::IntVar *mau_group) const;
  // Creates variables/constraints to allocate all members of bits to the same
  // byte within a PHV container.
  or_tools::Byte *SetByte(const PHV::Byte &byte);
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
  MakeMauGroup(const cstring &name, const int &max = PHV::kNumMauGroups - 1);
  operations_research::IntVar *MakeContainerInGroup(const cstring &name);
  operations_research::IntExpr *
  MakeContainer(operations_research::IntVar *group,
                operations_research::IntVar *container_in_group);
  operations_research::IntVar *
  MakeOffset(const cstring &name, const std::vector<int> &values);
  operations_research::IntVar *
  MakeOffset(const cstring &name, const int &min = 0, const int &max = 31);
  operations_research::IntExpr *MakeDeparserGroupFlag(
    const int &group_num, operations_research::IntExpr *container);
  // Creates (if needed) and returns a pointer to an object of or_tools::Bit.
  Bit *MakeBit(const PHV::Bit &phv_bit);
  // Returns an array of Bit* objects for a PHV::Byte.
  std::array<or_tools::Bit *, 8> get_bits(const PHV::Byte &byte) {
    std::array<or_tools::Bit *, 8> bits;
    std::transform(byte.begin(), byte.end(), bits.begin(),
                   [this](const PHV::Bit &b) -> Bit * {
                     return &bits_.at(b); });
    return bits;
  }
  operations_research::Solver solver_;
  std::map<PHV::Bit, or_tools::Bit> bits_;

  // Variable for generating unique names for IntVar objects.
  std::string unique_id() { return std::to_string(++unique_id_); }
  static int unique_id_;
};
}  // namespace or_tools
#endif /* TOFINO_PHV_OR_TOOLS_SOLVER_H_ */
