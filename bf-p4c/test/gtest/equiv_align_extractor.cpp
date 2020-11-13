#include <iostream>
#include <sstream>
#include <list>

#include "gtest/gtest.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "bf-p4c/test/utils/super_cluster_builder.h"
#include "bf-p4c/logging/constrained_fields.h"
#include "bf-p4c/logging/group_constraint_extractor.h"

namespace Test {

class EquivalentAlignExtractorTest : public TofinoBackendTest {
 protected:
    std::istringstream CLUSTER_WITHOUT_EQUIV_ALIGN = std::istringstream(R"(SUPERCLUSTER Uid: 1358
    slice lists:        [ ]
    rotational clusters:
        [[egress::eg_md.flags.pfc_wd_drop<1> meta [0:0]]]
    )");

    std::istringstream CLUSTER_WITH_EQUIV_ALIGN = std::istringstream(R"(SUPERCLUSTER Uid: 1957
    slice lists:
        [ egress::hdr.ipv4.total_len<16> ^0 ^bit[0..31] deparsed solitary no_split exact_containers mocha [0:15] ]
        [ egress::hdr.ipv6.payload_len<16> ^0 ^bit[0..47] deparsed solitary no_split exact_containers mocha [0:15] ]
    rotational clusters:
        [[egress::eg_md.checks.mtu<16> meta solitary no_split [0:15], egress::hdr.ipv4.total_len<16> ^0 ^bit[0..31] deparsed solitary no_split exact_containers mocha [0:15], egress::hdr.ipv6.payload_len<16> ^0 ^bit[0..47] deparsed solitary no_split exact_containers mocha [0:15]]]
    )");

    SuperClusterBuilder scb;
    std::list<PHV::SuperCluster*> groups;
    PhvInfo info;

    ConstrainedFieldMap fieldMap;
};

TEST_F(EquivalentAlignExtractorTest, IgnoresAlignedClusterWithSingleItem) {
    // Build supercluster
    boost::optional<PHV::SuperCluster*> sc1 = scb.build_super_cluster(CLUSTER_WITHOUT_EQUIV_ALIGN);
    if (!sc1) FAIL() << "Failed to build the cluster!";
    groups.push_back(sc1.get());

    // Add required fields
    info.add("egress::eg_md.flags.pfc_wd_drop", EGRESS, 1, 0, true, false);

    // Extract groups
    fieldMap = ConstrainedFieldMapBuilder::buildMap(info, groups);
    EquivalentAlignExtractor extractor(groups, fieldMap);

    // Assertions
    EXPECT_FALSE(extractor.isFieldInAnyGroup("egress::eg_md.flags.pfc_wd_drop"));
}

TEST_F(EquivalentAlignExtractorTest, ExtractsAlignedClusterWithMoreItems) {
    // Build supercluster
    boost::optional<PHV::SuperCluster*> sc1 = scb.build_super_cluster(CLUSTER_WITH_EQUIV_ALIGN);
    if (!sc1) FAIL() << "Failed to build the cluster!";
    groups.push_back(sc1.get());

    // Add required fields
    info.add("egress::eg_md.checks.mtu", EGRESS, 16, 0, false, false);
    info.add("egress::hdr.ipv4.total_len", EGRESS, 16, 0, false, false);
    info.add("egress::hdr.ipv6.payload_len", EGRESS, 16, 0, false, false);

    // Extract groups
    fieldMap = ConstrainedFieldMapBuilder::buildMap(info, groups);
    EquivalentAlignExtractor extractor(groups, fieldMap);

    // Assertions
    for (auto &field : info) {
        EXPECT_TRUE(extractor.isFieldInAnyGroup(field.name));

        auto agroups = extractor.getGroups(field.name);
        ASSERT_EQ(agroups.size(), 1u) << "Failed with field: " << field;
        ASSERT_EQ(agroups[0]->size(), 3u) << "Failed with field: " << field;

        auto &group = *agroups[0];
        EXPECT_EQ(group[0].getParent().getName(), "egress::eg_md.checks.mtu");
        EXPECT_EQ(group[1].getParent().getName(), "egress::hdr.ipv4.total_len");
        EXPECT_EQ(group[2].getParent().getName(), "egress::hdr.ipv6.payload_len");
    }
}

}  // namespace Test
