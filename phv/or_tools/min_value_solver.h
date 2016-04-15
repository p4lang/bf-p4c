#ifndef TOFINO_PHV_OR_TOOLS_MIN_VALUE_SOLVER_H_
#define TOFINO_PHV_OR_TOOLS_MIN_VALUE_SOLVER_H_
#include "solver.h"
class PhvInfo;
namespace or_tools {
class MinValueSolver : public Solver {
 public:
  bool Solve() {
    return Solve1(operations_research::Solver::ASSIGN_MIN_VALUE, false); }
};
}  // namespace or_tools
#endif /* TOFINO_PHV_OR_TOOLS_MIN_VALUE_SOLVER_H_ */
