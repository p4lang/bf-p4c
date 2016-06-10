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
class PhvAllocator : public PassManager {
  PhvInfo               &phv;
  const SymBitMatrix    &conflict;
 public:
  PhvAllocator(PhvInfo &phv, const SymBitMatrix &c);
  bool Solve(StringRef opt);

 private:
  Constraints constraints_;
};
#endif /* TOFINO_PHV_PHV_ALLOCATOR_H_ */
