#include <iostream>
#include <sstream>
#include <list>

#include "gtest/gtest.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "bf-p4c/test/utils/super_cluster_builder.h"
#include "bf-p4c/logging/constrained_fields.h"
#include "bf-p4c/logging/mau_group_extractor.h"

namespace Test {

class MauGroupExtractorTest : public TofinoBackendTest {
 protected:
    std::istringstream CLUSTER_WITH_SINGLE_SLICE = std::istringstream(R"(SUPERCLUSTER Uid: 1957
    slice lists:  [ ]
    rotational clusters:
        [[egress::eg_intr_md.$valid<1> pov [0:0]]]
)");

    std::istringstream CLUSTER_WITH_WHOLE_SLICES = std::istringstream(R"(SUPERCLUSTER Uid: 1952
    slice lists:
        [ ingress::hdr.arp.$valid<1> pov [0:0]
        ingress::hdr.cpu.$valid<1> pov [0:0]
        ingress::hdr.vn_tag.$valid<1> pov [0:0] ]
    rotational clusters:
        [[ingress::hdr.arp.$valid<1> pov [0:0]]]
        [[ingress::hdr.cpu.$valid<1> pov [0:0]]]
        [[ingress::hdr.vn_tag.$valid<1> pov [0:0]]]
)");

    std::istringstream CLUSTER_WITH_PARTIAL_SLICES = std::istringstream(R"(SUPERCLUSTER Uid: 1954
    slice lists:
        [ ingress::hdr.vlan_tag.$stkvalid<2> meta pov no_split [0:0]
        ingress::hdr.vlan_tag.$stkvalid<2> meta pov no_split [1:1]
        ingress::dummy.dummy<2> [0:1] ]
    rotational clusters:
        [[ingress::hdr.vlan_tag.$stkvalid<2> meta pov no_split [0:0]]]
        [[ingress::hdr.vlan_tag.$stkvalid<2> meta pov no_split [1:1]]]
        [[ingress::dummy.dummy<2> [0:1]]]
)");

    std::istringstream CLUSTER_MULTI_A = std::istringstream(R"(SUPERCLUSTER Uid: 1546
    slice lists:        [ ]
    rotational clusters:
        [[ingress::Millstone.Guion.Wilmore<3> meta [0:0]], [ingress::Millstone.LaMoille.Philbrook<3> meta [0:0]], [ingress::Millstone.Hapeville.Luzerne<1> meta [0:0]], [ingress::Millstone.LaMoille.Skyway<3> meta [0:0]]]
)");

    std::istringstream CLUSTER_MULTI_B = std::istringstream(R"(SUPERCLUSTER Uid: 1547
    slice lists:        [ ]
    rotational clusters:
        [[ingress::Millstone.Guion.Wilmore<3> meta [1:2]], [ingress::Millstone.LaMoille.Philbrook<3> meta [1:2]], [ingress::Millstone.LaMoille.Skyway<3> meta [1:2]]]
)");

    SuperClusterBuilder scb;
    std::list<PHV::SuperCluster*> groups;
    PhvInfo info;

    ConstrainedFieldMap fieldMap;
};

TEST_F(MauGroupExtractorTest, GetGroupThrowsOnEmpty) {
    MauGroupExtractor extractor(groups, fieldMap);

    EXPECT_THROW({
        extractor.getGroups("dummy");
    }, Util::CompilerBug);
}

TEST_F(MauGroupExtractorTest, IgnoresSuperClustersWithSingleField) {
    // Build all superclusters
    boost::optional<PHV::SuperCluster*> sc1 = scb.build_super_cluster(CLUSTER_WITH_SINGLE_SLICE);
    if (!sc1) FAIL() << "Failed to build the cluster!";
    groups.push_back(sc1.get());

    // Add required fields
    info.add("egress::eg_intr_md.$valid", EGRESS, 1, 0, false, true);

    // Extract groups
    fieldMap = ConstrainedFieldMapBuilder::buildMap(info, groups);
    MauGroupExtractor extractor(groups, fieldMap);

    // Assertions
    EXPECT_FALSE(extractor.isFieldInAnyGroup("egress::eg_intr_md.$valid"));
}

TEST_F(MauGroupExtractorTest, ExtractsWholeSlices) {
    // Build all superclusters
    boost::optional<PHV::SuperCluster*> sc1 = scb.build_super_cluster(CLUSTER_WITH_WHOLE_SLICES);
    if (!sc1) FAIL() << "Failed to build the cluster!";
    groups.push_back(sc1.get());

    // Add required fields
    info.add("ingress::hdr.arp.$valid", INGRESS, 1, 0, false, true);
    info.add("ingress::hdr.cpu.$valid", INGRESS, 1, 0, false, true);
    info.add("ingress::hdr.vn_tag.$valid", INGRESS, 1, 0, false, true);

    // Extract groups
    fieldMap = ConstrainedFieldMapBuilder::buildMap(info, groups);
    MauGroupExtractor extractor(groups, fieldMap);

    // Assertions
    for (auto &field : info) {
        EXPECT_TRUE(extractor.isFieldInAnyGroup(field.name));

        auto mgroups = extractor.getGroups(field.name);
        ASSERT_EQ(mgroups.size(), 1) << "Failed with field: " << field;
        ASSERT_EQ(mgroups[0]->size(), 3) << "Failed with field: " << field;
    }

    auto mgroups = extractor.getGroups("ingress::hdr.vn_tag.$valid");
    auto &group = *mgroups[0];


    EXPECT_EQ(group[0].getParent().getName(), "ingress::hdr.arp.$valid");
    EXPECT_EQ(group[0].getRange(), le_bitrange(0, 0));
    EXPECT_EQ(group[1].getParent().getName(), "ingress::hdr.cpu.$valid");
    EXPECT_EQ(group[1].getRange(), le_bitrange(0, 0));
    EXPECT_EQ(group[2].getParent().getName(), "ingress::hdr.vn_tag.$valid");
    EXPECT_EQ(group[2].getRange(), le_bitrange(0, 0));
}

TEST_F(MauGroupExtractorTest, ExtractsPartialSlices) {
    // Build all superclusters
    boost::optional<PHV::SuperCluster*> sc1 = scb.build_super_cluster(CLUSTER_WITH_PARTIAL_SLICES);
    if (!sc1) FAIL() << "Failed to build the cluster!";
    groups.push_back(sc1.get());

    // Add required fields
    info.add("ingress::hdr.vlan_tag.$stkvalid", INGRESS, 2, 0, true, true);
    info.add("ingress::dummy.dummy", INGRESS, 2, 0, false, false);

    // Extract groups
    fieldMap = ConstrainedFieldMapBuilder::buildMap(info, groups);
    MauGroupExtractor extractor(groups, fieldMap);

    // Assertions
    EXPECT_TRUE(extractor.isFieldInAnyGroup("ingress::hdr.vlan_tag.$stkvalid"));

    auto mgroups = extractor.getGroups("ingress::hdr.vlan_tag.$stkvalid");
    ASSERT_EQ(mgroups.size(), 1);

    auto &group = *mgroups[0];
    ASSERT_EQ(group.size(), 3);  // three items in group (2 slices + dummy)

    EXPECT_EQ(group[0].getParent().getName(), "ingress::hdr.vlan_tag.$stkvalid");
    EXPECT_EQ(group[0].getRange(), le_bitrange(0, 0));
    EXPECT_EQ(group[1].getParent().getName(), "ingress::hdr.vlan_tag.$stkvalid");
    EXPECT_EQ(group[1].getRange(), le_bitrange(1, 1));
    EXPECT_EQ(group[2].getParent().getName(), "ingress::dummy.dummy");
    EXPECT_EQ(group[2].getRange(), le_bitrange(0, 1));
}

TEST_F(MauGroupExtractorTest, ExtractFieldInMultipleGroups) {
    // Build all superclusters
    boost::optional<PHV::SuperCluster*> sc1 = scb.build_super_cluster(CLUSTER_MULTI_A);
    if (!sc1) FAIL() << "Failed to build the cluster!";
    groups.push_back(sc1.get());

    boost::optional<PHV::SuperCluster*> sc2 = scb.build_super_cluster(CLUSTER_MULTI_B);
    if (!sc2) FAIL() << "Failed to build the cluster!";
    groups.push_back(sc2.get());

    // Add required fields
    info.add("ingress::Millstone.Guion.Wilmore", INGRESS, 3, 0, true, false);
    info.add("ingress::Millstone.LaMoille.Philbrook", INGRESS, 3, 0, true, false);
    info.add("ingress::Millstone.Hapeville.Luzerne", INGRESS, 3, 0, true, false);
    info.add("ingress::Millstone.LaMoille.Skyway", INGRESS, 3, 0, true, false);

    // Extract groups
    fieldMap = ConstrainedFieldMapBuilder::buildMap(info, groups);
    MauGroupExtractor extractor(groups, fieldMap);

    // Assertions
    EXPECT_TRUE(extractor.isFieldInAnyGroup("ingress::Millstone.Guion.Wilmore"));

    auto mgroups = extractor.getGroups("ingress::Millstone.Guion.Wilmore");
    ASSERT_EQ(mgroups.size(), 2);

    ASSERT_EQ(mgroups[0]->size(), 4);  // cluster_multi_a
    ASSERT_EQ(mgroups[1]->size(), 3);  // cluster_multi_b

    auto &group0 = *mgroups[0];
    auto &group1 = *mgroups[1];

    EXPECT_EQ(group0[0].getParent().getName(), "ingress::Millstone.Guion.Wilmore");
    EXPECT_EQ(group0[0].getRange(), le_bitrange(0, 0));
    EXPECT_EQ(group0[1].getParent().getName(), "ingress::Millstone.LaMoille.Philbrook");
    EXPECT_EQ(group0[1].getRange(), le_bitrange(0, 0));
    EXPECT_EQ(group0[2].getParent().getName(), "ingress::Millstone.Hapeville.Luzerne");
    EXPECT_EQ(group0[2].getRange(), le_bitrange(0, 0));
    EXPECT_EQ(group0[3].getParent().getName(), "ingress::Millstone.LaMoille.Skyway");
    EXPECT_EQ(group0[3].getRange(), le_bitrange(0, 0));

    EXPECT_EQ(group1[0].getParent().getName(), "ingress::Millstone.Guion.Wilmore");
    EXPECT_EQ(group1[0].getRange(), le_bitrange(1, 2));
    EXPECT_EQ(group1[1].getParent().getName(), "ingress::Millstone.LaMoille.Philbrook");
    EXPECT_EQ(group1[1].getRange(), le_bitrange(1, 2));
    EXPECT_EQ(group1[2].getParent().getName(), "ingress::Millstone.LaMoille.Skyway");
    EXPECT_EQ(group1[2].getRange(), le_bitrange(1, 2));
}

}   // namespace Test
