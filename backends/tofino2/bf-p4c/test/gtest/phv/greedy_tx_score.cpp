#include "bf-p4c/phv/v2/greedy_tx_score.h"

#include "bf-p4c/phv/phv.h"
#include "gtest/gtest.h"

namespace P4::Test {

//      ixbar bytes layout
//   0       1     2       3
//                W6@2    W6@3
TEST(ixbar_imbalanced_alignment, case0) {
    ordered_set<PHV::v2::ContainerByte> tc1;
    tc1.insert({PHV::Container("W6"), 2});
    tc1.insert({PHV::Container("W6"), 3});
    EXPECT_EQ(0, PHV::v2::GreedyTxScoreMaker::ixbar_imbalanced_alignment(tc1));
}

//      ixbar bytes layout
//   0       1     2       3
//  H2@0   MH5@1  W6@2    W6@3
//  H9@0          MH5@0
TEST(ixbar_imbalanced_alignment, case1) {
    ordered_set<PHV::v2::ContainerByte> tc1;
    tc1.insert({PHV::Container("W6"), 2});
    tc1.insert({PHV::Container("W6"), 3});
    tc1.insert({PHV::Container("H2"), 0});
    tc1.insert({PHV::Container("H9"), 0});
    tc1.insert({PHV::Container("MH5"), 0});
    tc1.insert({PHV::Container("MH5"), 1});
    EXPECT_EQ(2, PHV::v2::GreedyTxScoreMaker::ixbar_imbalanced_alignment(tc1));
}

}  // namespace P4::Test
