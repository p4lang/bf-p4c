#include "phv.h"
const std::vector<std::pair<int, int>> Phv::kPhvDeparserGroups = {
// Enforcing deparser group constraints in PHV slows down compilation. It takes about 2min for switch.p4. Re-enable this after optimizations.
//std::make_pair(0, 3), std::make_pair(4, 7), std::make_pair(8, 11),
//std::make_pair(12, 15), std::make_pair(16, 19), std::make_pair(20, 23),
//std::make_pair(24, 27), std::make_pair(28, 31), std::make_pair(32, 35),
//std::make_pair(36, 39), std::make_pair(40, 43), std::make_pair(44, 47),
//std::make_pair(48, 51), std::make_pair(52, 55), std::make_pair(56, 59),
//std::make_pair(60, 60), std::make_pair(61, 61), std::make_pair(62, 62),
//std::make_pair(63, 63), std::make_pair(96, 103), std::make_pair(104, 111),
//std::make_pair(112, 119), std::make_pair(120, 127), std::make_pair(128, 135),
//std::make_pair(136, 143), std::make_pair(144, 151), std::make_pair(152, 152),
//std::make_pair(153, 153), std::make_pair(154, 154), std::make_pair(155, 155),
//std::make_pair(156, 156), std::make_pair(157, 157), std::make_pair(158, 158),
//std::make_pair(159, 159)
};
//const std::vector<std::pair<int, int>> Phv::kPhvDeparserGroups = {};
const std::vector<int> Phv::kTPhvDeparserGroups = { 16, 17, 18, 19,
                                                    20, 21, 22, 23 };
const std::vector<int> Phv::k8bPhvGroups = { 4, 5, 6, 7 };
const std::vector<int> Phv::k16bPhvGroups = { 8, 9, 10, 11, 12, 13 };
const std::vector<int> Phv::k32bPhvGroups = { 0, 1, 2, 3 };
