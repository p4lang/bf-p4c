#ifndef _TOFINO_PHV_PHV_ALLOCATOR_H_
#define _TOFINO_PHV_PHV_ALLOCATOR_H_
#include "header_bits.h"
#include "header_bit_creator.h"
#include "container_var_creator.h"
#include <constraint_solver/constraint_solver.h>
#include <ir/ir.h>
#include <map>
#include <vector>
class PhvInfo;
class PhvAllocator {
 public:
  PhvAllocator(const IR::Tofino::Pipe *maupipe);
  ~PhvAllocator() { }
  bool Solve();
  bool SolveRandomValueStrategy();
  void GetAllocation(PhvInfo *phv_info);

 private:
  std::vector<operations_research::IntVar*> SetConstraints();

  const IR::Tofino::Pipe *maupipe_;
  operations_research::Solver solver_;
  HeaderBits header_bits_;

  // Pass for creating HeaderBit objects.
  HeaderBitCreator header_bit_creator_;
};
#endif /* !_TOFINO_PHV_PHV_ALLOCATOR_H_ */
