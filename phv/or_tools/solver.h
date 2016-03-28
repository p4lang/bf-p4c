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
  void SetEqualMauGroup(const std::set<PHV::Bit> &bits) override;
  void SetEqualContainer(const std::set<PHV::Bit> &bits) override;
  void SetByte(const PHV::Byte &byte) override;
  void SetEqualOffset(const std::set<PHV::Bit> &bits) override;
  void SetFirstDeparsedHeaderByte(const PHV::Byte &byte) override;
  void SetDeparsedHeader(const PHV::Byte &byte1,
                         const PHV::Byte &byte2) override;
  void SetLastDeparsedHeaderByte(const PHV::Byte &last_byte) override;
  void SetDeparserGroups(const PHV::Byte &i_hdr_byte,
                         const PHV::Byte &e_hdr_byte) override;
  void SetMatchXbarWidth(const std::vector<PHV::Bit> &bits,
                         const std::array<int, 4> &width) override;
  void SetNoTPhv(const PHV::Bit &bit) override;

  void allocation(const PHV::Bit &bit, PHV::Container *c, int *container_bit);
 protected:
  bool Solve1(operations_research::Solver::IntValueStrategy int_val);
 private:
  std::vector<operations_research::IntVar*> GetIntVars() const;
  std::vector<operations_research::IntVar*> mau_groups() const;
  std::vector<operations_research::IntVar*>
  containers_and_offsets(operations_research::IntVar *mau_group) const;
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
  operations_research::IntExpr *MakeByte(operations_research::IntVar *offset);
  operations_research::IntExpr *MakeDeparserGroupFlag(
    const int &group_num, operations_research::IntExpr *container);
  // Get the Bit * objects for a PHV::Byte.
  std::array<ORTools::Bit *, 8> get_bits(const PHV::Byte &byte) {
    std::array<ORTools::Bit *, 8> bits;
    std::transform(byte.begin(), byte.end(), bits.begin(),
                   [this](const PHV::Bit &b) -> Bit * {
                     return &bits_.at(b); });
    return bits;
  }
  operations_research::Solver solver_;
  std::map<PHV::Bit, ORTools::Bit> bits_;
  std::map<PHV::Byte, ORTools::Byte> bytes_;

  // Variable for generating unique names for IntVar objects.
  int unique_id() { return ++unique_id_; }
  static int unique_id_;
};
}
#endif
