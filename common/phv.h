#ifndef TOFINO_COMMON_PHV_H_
#define TOFINO_COMMON_PHV_H_
#include <vector>
#include <iostream>

class Phv {
 public:
  static constexpr int kNumGroups = 14;
  // T-PHV is modeled differently from actual hardware. In each PHV group,
  // containers >= 16 are T-PHV containers.
  static constexpr int kNumContainersPerPhvGroup = 24;
  static constexpr int kTPhvContainerOffset = 16;
  static const std::vector<std::pair<int, int>> kPhvDeparserGroups;
  static const std::vector<int> kTPhvDeparserGroups;
  static const std::vector<int> k8bPhvGroups;
  static const std::vector<int> k16bPhvGroups;
  static const std::vector<int> k32bPhvGroups;
};
#endif /* TOFINO_COMMON_PHV_H_ */
