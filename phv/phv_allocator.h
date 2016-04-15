#ifndef TOFINO_PHV_PHV_ALLOCATOR_H_
#define TOFINO_PHV_PHV_ALLOCATOR_H_
#include <vector>
#include "constraints.h"
class PhvInfo;
namespace IR {
namespace Tofino {
class Pipe;
}
}
class PhvAllocator {
 public:
  explicit PhvAllocator(const IR::Tofino::Pipe *pipe) { SetConstraints(pipe); }
  bool Solve(const IR::Tofino::Pipe *pipe, PhvInfo *phv_info);

 private:
  void SetConstraints(const IR::Tofino::Pipe *pipe);
  Constraints constraints_;
};
#endif /* TOFINO_PHV_PHV_ALLOCATOR_H_ */
