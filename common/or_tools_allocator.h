#ifndef BACKENDS_TOFINO_OR_TOOLS_ALLOCATOR_H_
#define BACKENDS_TOFINO_OR_TOOLS_ALLOCATOR_H_
#include "ir/ir.h"
#include <constraint_solver/constraint_solver.h>
#include <list>
#include <map>
#include <set>

class HeaderVars;
class HeaderByteVars;
class ORToolsAllocator {
public:
  ORToolsAllocator();
  ~ORToolsAllocator();
  void Solve();
  void AddParserConstraints(const IR::HeaderRef *header_ref, const gress_t &,
                            const std::list<cstring> header_names);
  void AddAssignmentConstraint(HeaderByteVars *hb_vars1,
                               HeaderByteVars *hb_vars2);

  HeaderVars *header_vars(const cstring &header_name) {
    if (header_vars_.find(header_name) == header_vars_.end()) return nullptr;
    else return header_vars_.at(header_name).get();
  }
  Inspector *parde_inspector() { return parde_inspector_.get(); }
  Inspector *mau_inspector() { return mau_inspector_.get(); }
  operations_research::Solver *solver() { return &solver_; }
private:
  operations_research::Solver solver_;
  std::map<cstring, std::unique_ptr<HeaderVars>> header_vars_;

  const std::unique_ptr<Inspector> parde_inspector_;
  const std::unique_ptr<Inspector> mau_inspector_;
};
#endif
