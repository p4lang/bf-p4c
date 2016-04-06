#ifndef _TOFINO_PHV_MAU_GROUP_H_
#define _TOFINO_PHV_MAU_GROUP_H_
#include <array>
namespace operations_research {
class IntVar;
}
namespace ORTools {
class MauGroup {
 public:
  MauGroup(operations_research::IntVar *mg);
  operations_research::IntVar *mau_group() const { return mau_group_; }
  operations_research::IntVar *is_8b() const { return width_flags_.at(0); }
  operations_research::IntVar *is_16b() const { return width_flags_.at(1); }
  operations_research::IntVar *is_32b() const { return width_flags_.at(2); }
  // This function specifies that the fields allocated to this MAU group will
  // be accessed by the ingress deparser.
  void SetIngressDeparser();
  void SetEgressDeparser();
  // Prevents allocation of this object to a T-PHV MAU group.
  void SetNoTPhv();
  bool is_t_phv() { return is_t_phv_; }
 private:
  // The MAU group of all the containers that have a pointer to this object.
  operations_research::IntVar *const mau_group_;
  // These are flags to indicate if the bit has been allocated to a 8b, 16b
  // or 32b container.
  std::array<operations_research::IntVar*, 3> width_flags_;
  bool is_t_phv_;
};
}
#endif
