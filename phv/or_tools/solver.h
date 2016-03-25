#ifndef _TOFINO_PHV_ORTOOLS_SOLVER_H_
#define _TOFINO_PHV_ORTOOLS_SOLVER_H_
#include "bit.h"
#include "backends/tofino/phv/solver_interface.h"
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
  operations_research::Solver solver_;
  std::map<PHV::Bit, ORTools::Bit> bits_;

  // Variable for generating unique names for IntVar objects.
  int unique_id() { return ++unique_id_; }
  static int unique_id_;
};
}
#endif
