#ifndef TOFINO_PHV_OR_TOOLS_RANDOM_VALUE_SOLVER_H_
#define TOFINO_PHV_OR_TOOLS_RANDOM_VALUE_SOLVER_H_
#include "solver.h"

class PhvInfo;
namespace or_tools {
class RandomValueSolver : public Solver {
 public:
    bool Solve() { return Solve1(operations_research::Solver::ASSIGN_RANDOM_VALUE); }
};
}

#endif /* TOFINO_PHV_OR_TOOLS_RANDOM_VALUE_SOLVER_H_ */
