#ifndef _TOFINO_PHV_ORTOOLS_RANDOM_VALUE_SOLVER_H_
#define _TOFINO_PHV_ORTOOLS_RANDOM_VALUE_SOLVER_H_
#include "solver.h"
class PhvInfo;
namespace or_tools {
class RandomValueSolver : public Solver {
 public:
  bool Solve() {
    return Solve1(operations_research::Solver::ASSIGN_RANDOM_VALUE); }
};
}
#endif
