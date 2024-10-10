#include "gtest/gtest.h"

#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "bf-p4c/common/scc_toposort.h"

namespace Test {

class TofinoSccToposort : public TofinoBackendTest { };

TEST_F(TofinoSccToposort, empty) {
    SccTopoSorter sorter;
    auto rst = sorter.scc_topo_sort();
    EXPECT_TRUE(rst.empty());
}

TEST_F(TofinoSccToposort, single_node) {
    /**
       1
     */
    SccTopoSorter sorter;
    sorter.new_node();

    auto rst = sorter.scc_topo_sort();
    EXPECT_EQ(rst.at(1), 1);
}

TEST_F(TofinoSccToposort, circular_single_node) {
    /**
       1 <- 1
     */
    SccTopoSorter sorter;
    sorter.new_node();
    sorter.add_dep(1, 1);

    auto rst = sorter.scc_topo_sort();
    EXPECT_EQ(rst.at(1), 1);
}

TEST_F(TofinoSccToposort, circular_nodes) {
    /**
       1 <- 2 <- 3
       ---------->
     */
    SccTopoSorter sorter;
    for (int i = 1; i <= 3; i++) {
        sorter.new_node();
    }
    sorter.add_dep(2, 1);
    sorter.add_dep(3, 2);
    sorter.add_dep(1, 3);

    auto rst = sorter.scc_topo_sort();
    EXPECT_EQ(rst.at(1), 1);
    EXPECT_EQ(rst.at(2), 1);
    EXPECT_EQ(rst.at(3), 1);
}

TEST_F(TofinoSccToposort, basic_4_nodes) {
    /**
       1 <- 2 <- 3 <-> 4
     */
    SccTopoSorter sorter;
    for (int i = 1; i <= 4; i++) {
        sorter.new_node();
    }
    sorter.add_dep(2, 1);
    sorter.add_dep(3, 2);
    sorter.add_dep(3, 4);
    sorter.add_dep(4, 3);

    auto rst = sorter.scc_topo_sort();
    EXPECT_EQ(rst.at(3), 1);
    EXPECT_EQ(rst.at(4), 1);
    EXPECT_EQ(rst.at(2), 2);
    EXPECT_EQ(rst.at(1), 3);
}

}  // namespace Test
