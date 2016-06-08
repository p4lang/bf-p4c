#ifndef TOFINO_PHV_PHV_ALLOCATOR_H_
#define TOFINO_PHV_PHV_ALLOCATOR_H_
#include <vector>
#include "constraints.h"
#include "lib/symbitmatrix.h"

class PhvInfo;
namespace IR {
namespace Tofino {
class Pipe;
}
}
class PhvAllocator {
  PhvInfo               &phv;
  const SymBitMatrix    &conflict;
 public:
  PhvAllocator(PhvInfo &phv, const IR::Tofino::Pipe *pipe, const SymBitMatrix &c)
  : phv(phv), conflict(c) { SetConstraints(pipe); }
  bool Solve(const IR::Tofino::Pipe *pipe, PhvInfo *phv_info, StringRef opt);

 private:
  void SetConstraints(const IR::Tofino::Pipe *pipe);
  Constraints constraints_;
};
#endif /* TOFINO_PHV_PHV_ALLOCATOR_H_ */
