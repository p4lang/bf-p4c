#ifndef BACKENDS_TOFINO_PHV_H_
#define BACKENDS_TOFINO_PHV_H_
#include <vector>
#include <iostream>

class Phv {
 public:
  static constexpr int kNumGroups = 14;
  static constexpr int kNumContainersPerPhvGroup = 24;
  static const std::vector<int> k8bPhvGroups;
  static const std::vector<int> k16bPhvGroups;
  static const std::vector<int> k32bPhvGroups;
};
#endif
