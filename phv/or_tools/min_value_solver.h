#ifndef _TOFINO_PHV_ORTOOLS_MIN_VALUE_SOLVER_H_
#define _TOFINO_PHV_ORTOOLS_MIN_VALUE_SOLVER_H_
#include "solver.h"
class PhvInfo;
namespace ORTools {
class MinValueSolver : public Solver {
 public:
  bool Solve() {
    return Solve1(operations_research::Solver::ASSIGN_MIN_VALUE, false); }
};
}
#endif
