#include <iostream>
#include <sstream>
#include <list>

#include "gtest/gtest.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "bf-p4c/test/utils/super_cluster_builder.h"
#include "bf-p4c/logging/constrained_fields.h"

namespace Test {

class ConstrainedFieldMapBuilderTest : public TofinoBackendTest {
 protected:
    using AR = Constraints::AlignmentConstraint::AlignmentReason;

    std::istringstream SUPERCLUSTER = std::istringstream(R"(SUPERCLUSTER Uid: 41
    slice lists:
        [ ingress::hdr.test<32> ^0 [0:19]
          ingress::hdr.test<32> ^4 [20:31]
          egress::hdr.test<32> ^0 [0:31] ]
    rotational clusters:
        [[ingress::hdr.test<32> ^0 [0:19]], [ingress::hdr.test<32> ^4 [20:31]], [egress::hdr.test<32> ^0 [0:31]]]
)");

    PhvInfo phv;
    std::list<PHV::SuperCluster*> superclusters;
    ConstrainedFieldMap fields;
    SuperClusterBuilder scb;

    void SetUp() override {
        // Setup fields
        phv.add("ingress::hdr.test", INGRESS, 32, 0, false, false);
        phv.add("egress::hdr.test", EGRESS, 32, 0, false, false);
    }
};

TEST_F(ConstrainedFieldMapBuilderTest, ShouldInitializeFields) {
    // Compute map
    fields = ConstrainedFieldMapBuilder::buildMap(phv, superclusters);

    // Assertions
    ASSERT_FALSE(fields.find("ingress::hdr.test") == fields.end());
    ASSERT_FALSE(fields.find("egress::hdr.test") == fields.end());
}

TEST_F(ConstrainedFieldMapBuilderTest, ShouldInitializeSlices) {
    // Setup superclusters
    boost::optional<PHV::SuperCluster*> sc1 = scb.build_super_cluster(SUPERCLUSTER);
    if (!sc1) FAIL() << "Failed to build the supercluster!";
    superclusters.push_back(sc1.get());

    // Compute map
    fields = ConstrainedFieldMapBuilder::buildMap(phv, superclusters);

    // Assertions
    auto slices1 = fields["ingress::hdr.test"].getSlices();
    auto slices2 = fields["egress::hdr.test"].getSlices();

    ASSERT_EQ(slices1.size(), 2U);
    ASSERT_EQ(slices2.size(), 1U);

    auto &slice0 = *slices1.begin();
    auto &slice1 = *(++slices1.begin());
    auto &slice2 = *slices2.begin();

    EXPECT_EQ(slice0.getParent().getName(), "ingress::hdr.test");
    EXPECT_EQ(slice0.getRange().lo, 0);
    EXPECT_EQ(slice0.getRange().hi, 19);
    EXPECT_EQ(slice1.getParent().getName(), "ingress::hdr.test");
    EXPECT_EQ(slice1.getRange().lo, 20);
    EXPECT_EQ(slice1.getRange().hi, 31);
    EXPECT_EQ(slice2.getParent().getName(), "egress::hdr.test");
    EXPECT_EQ(slice2.getRange().lo, 0);
    EXPECT_EQ(slice2.getRange().hi, 31);
}

TEST_F(ConstrainedFieldMapBuilderTest, ShouldInitializeFieldConstraints) {
    // Additional setup
    auto field = phv.field("ingress::hdr.test");
    field->set_solitary(1);
    field->updateAlignment(AR::PARSER, FieldAlignment(le_bitrange(4, 4)), Util::SourceInfo());

    // Compute map
    fields = ConstrainedFieldMapBuilder::buildMap(phv, superclusters);

    // Assertions
    auto &cf = fields.at("ingress::hdr.test");
    EXPECT_TRUE(cf.getSolitary().hasConstraint());
    EXPECT_TRUE(cf.getAlignment().hasConstraint());
    EXPECT_EQ(cf.getAlignment().getAlignment(), 4u);
}

TEST_F(ConstrainedFieldMapBuilderTest, ShouldInitializeSliceConstraints) {
    // Setup superclusters
    boost::optional<PHV::SuperCluster*> sc1 = scb.build_super_cluster(SUPERCLUSTER);
    if (!sc1) FAIL() << "Failed to build the supercluster!";
    superclusters.push_back(sc1.get());

    // Additional setup
    auto field = phv.field("ingress::hdr.test");
    field->updateAlignment(AR::PARSER, FieldAlignment(le_bitrange(4, 4)), Util::SourceInfo());

    // Compute map
    fields = ConstrainedFieldMapBuilder::buildMap(phv, superclusters);

    // Assertions
    auto slices = fields["ingress::hdr.test"].getSlices();

    auto slice = *(++slices.begin());
    EXPECT_TRUE(slice.getAlignment().hasConstraint());
    EXPECT_EQ(slice.getAlignment().getAlignment(), 4U);
}

}  // namespace Test
