#ifndef _TOFINO_PHV_HEADER_BITS_H_
#define _TOFINO_PHV_HEADER_BITS_H_
#include "ir/ir.h"
#include "lib/cstring.h"
#include <array>
#include <vector>
#include <map>
#include <set>
#include <unordered_map>
namespace operations_research {
  class Solver;
  class IntVar;
  class IntExpr;
}
class HeaderBit;
class HeaderBits {
 public:
  typedef std::pair<cstring, int> BitIdentifier;

  HeaderBits() : solver_(nullptr) { }
  ~HeaderBits();
  void CreateHeader(const cstring &header_name, const int &width_bits);
  HeaderBit *get(const cstring &header_name, const size_t &offset) const;

  // Iterface for creating constraint variables.
  void set_solver(operations_research::Solver &solver) { solver_ = &solver; }
  operations_research::IntVar *MakeGroupVar(
    const cstring &name, std::array<operations_research::IntVar*, 3> *is_xb);
  operations_research::IntVar *MakeContainerInGroupVar(const cstring &name);
  operations_research::IntExpr *
  MakeContainerExpr(operations_research::IntVar *container,
                    operations_research::IntVar *container_in_group);
  operations_research::IntVar *MakeByteAlignedOffsetVar(const cstring &n);
  operations_research::IntVar *MakeOffsetVar(const cstring &n);
  operations_research::IntVar *
  MakeSum(operations_research::IntExpr *e, const int &i);
  template<class T> void SetEqualityConstraint(T v1, T v2);
  void SetNonEqualityConstraint(operations_research::IntExpr *v1,
                                operations_research::IntExpr *v2);
  bool IsEqual(operations_research::IntExpr *v1,
               operations_research::IntExpr *v2) const;
  bool IsNonEqual(operations_research::IntExpr *v1,
                  operations_research::IntExpr *v2) const;
  template<class T> std::set<T> Equals(T v) const;
  void SetContainerWidthConstraints() const;

  // Iterface for retrieving constraint variables.
  std::vector<operations_research::IntVar*> GetGroupVars() const;
  std::vector<operations_research::IntVar*>
  containers_and_offsets(const std::set<operations_research::IntVar*> &groups) const;

  // Used for iterating over all bits.
  typedef std::map<BitIdentifier, HeaderBit*>::iterator iterator;
  iterator begin() { return bits_.begin(); }
  iterator end() { return bits_.end(); }

  // Intended to be used for creating constraint variable names.
  int unique_id() { return ++unique_id_; }
  operations_research::Solver *solver() const { return solver_; }
 private:
  std::map<BitIdentifier, HeaderBit*> bits_;
  operations_research::Solver *solver_;
  static int unique_id_;
  std::unordered_map<operations_research::IntExpr*,
                     std::set<operations_research::IntExpr*>> equals_;
  std::set<std::pair<operations_research::IntExpr*,
                     operations_research::IntExpr*>> non_equals_;
};
#endif
