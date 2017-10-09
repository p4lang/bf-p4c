#include <iostream>
#include <sstream>

#include "bf-p4c/phv/phv.h"
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "ir/json_loader.h"
#include "lib/bitvec.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "tofino_gtest_utils.h"

namespace Test {

class TofinoPhvContainer : public TofinoBackendTest {};

namespace {

// Test that each type of PHV::Container has the expected properties.
void CheckPhvContainerTypes() {
    using Type = PHV::Type;
    const auto& phvSpec = Device::phvSpec();

    auto checkRange = [&](PHV::Container c) {
        SCOPED_TRACE(c);
        auto begin = c.index() / 2;
        auto length = std::max(c.index() * 2, 128u);
        for (auto type : phvSpec.containerTypes()) {
            auto range = phvSpec.range(type, begin, length);
            if (type == c.type())
                EXPECT_TRUE(range.getbit(phvSpec.containerToId(c)));
            else
                EXPECT_FALSE(range.getbit(phvSpec.containerToId(c)));
        }

        auto rangeBefore = phvSpec.range(c.type(), 0, c.index());
        EXPECT_FALSE(rangeBefore.getbit(phvSpec.containerToId(c)));
        auto rangeAfter = phvSpec.range(c.type(), c.index() + 1, 64);
        EXPECT_FALSE(rangeAfter.getbit(phvSpec.containerToId(c)));
    };

    PHV::Container c;
    EXPECT_FALSE(static_cast<bool>(c));

    c = "B0";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Type("B"), c.type());
    EXPECT_EQ(0u, c.log2sz());
    EXPECT_EQ(0u, c.index());
    EXPECT_FALSE(c.is(PHV::Kind::tagalong));
    EXPECT_EQ(c, PHV::Container(Type("B"), 0));
    EXPECT_EQ(c, phvSpec.idToContainer(phvSpec.containerToId(c)));
    EXPECT_TRUE(phvSpec.range(Type("B"), 0, 16).getbit(phvSpec.containerToId(c)));
    EXPECT_TRUE(phvSpec.range(Type("B"), 0, 16).getbit(phvSpec.containerToId(c)));
    checkRange(c);

    c = "H15";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Type("H"), c.type());
    EXPECT_EQ(1u, c.log2sz());
    EXPECT_EQ(15u, c.index());
    EXPECT_FALSE(c.is(PHV::Kind::tagalong));
    EXPECT_EQ(c, PHV::Container(Type("H"), 15));
    EXPECT_EQ(c, phvSpec.idToContainer(phvSpec.containerToId(c)));
    checkRange(c);

    c = "W3157";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Type("W"), c.type());
    EXPECT_EQ(2u, c.log2sz());
    EXPECT_EQ(3157u, c.index());
    EXPECT_FALSE(c.is(PHV::Kind::tagalong));
    EXPECT_EQ(c, PHV::Container(Type("W"), 3157));
    EXPECT_EQ(c, phvSpec.idToContainer(phvSpec.containerToId(c)));
    checkRange(c);

    c = "TB0";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Type("TB"), c.type());
    EXPECT_EQ(0u, c.log2sz());
    EXPECT_EQ(0u, c.index());
    EXPECT_TRUE(c.is(PHV::Kind::tagalong));
    EXPECT_EQ(c, PHV::Container(Type("TB"), 0));
    EXPECT_EQ(c, phvSpec.idToContainer(phvSpec.containerToId(c)));
    checkRange(c);

    c = "TH15";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Type("TH"), c.type());
    EXPECT_EQ(1u, c.log2sz());
    EXPECT_EQ(15u, c.index());
    EXPECT_TRUE(c.is(PHV::Kind::tagalong));
    EXPECT_EQ(c, PHV::Container(Type("TH"), 15));
    EXPECT_EQ(c, phvSpec.idToContainer(phvSpec.containerToId(c)));
    checkRange(c);

    c = "TW3157";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Type("TW"), c.type());
    EXPECT_EQ(2u, c.log2sz());
    EXPECT_EQ(3157u, c.index());
    EXPECT_TRUE(c.is(PHV::Kind::tagalong));
    EXPECT_EQ(c, PHV::Container(Type("TW"), 3157));
    EXPECT_EQ(c, phvSpec.idToContainer(phvSpec.containerToId(c)));
    checkRange(c);

    EXPECT_ANY_THROW(PHV::Container("X1"));
    EXPECT_ANY_THROW(PHV::Container("B"));  // XXX(seth)
    EXPECT_ANY_THROW(PHV::Container("W-1"));
}

// Test that the device provides the resources we expect.
// XXX(cole): This test is specific to Tofino, but a similar test should be
// added once more JBay resources are defined.
void CheckTofinoPhvContainerResources() {
    const auto& phvSpec = Device::phvSpec();

    // MAU and Tagalong containers should be subsets of the physical
    // containers.
    for (auto t : phvSpec.containerTypes()) {
        for (auto mau_group : phvSpec.mauGroups(t)) {
            EXPECT_NE(bitvec(), mau_group & phvSpec.physicalContainers()); } }
    for (auto tagalong_group : phvSpec.tagalongGroups()) {
        EXPECT_NE(bitvec(), tagalong_group & phvSpec.physicalContainers()); }
    
    // They should also be disjoint.
    for (auto t : phvSpec.containerTypes()) {
        for (auto mau_group : phvSpec.mauGroups(t)) {
            for (auto tagalong_group : phvSpec.tagalongGroups()) {
                EXPECT_EQ(bitvec(), mau_group & tagalong_group); } } }

    // There should be eight tagalong groups of 4x8b containers, 6x16b
    // containers, and 4x32b containers.
    ordered_map<PHV::Size, int> collection_sizes;
    for (auto collection : phvSpec.tagalongGroups()) {
        for (auto cid : collection)
            collection_sizes[phvSpec.idToContainer(cid).type().size()]++;
        EXPECT_EQ(4, collection_sizes[PHV::Size::b8]);
        EXPECT_EQ(6, collection_sizes[PHV::Size::b16]);
        EXPECT_EQ(4, collection_sizes[PHV::Size::b32]);
        collection_sizes.clear(); }
    EXPECT_EQ(unsigned(8), phvSpec.tagalongGroups().size());

    // There should be 4 MAU groups of size b8, 6 of b16, and 4 of b32.
    ordered_map<PHV::Size, int> mau_group_sizes;
    for (auto t : phvSpec.containerTypes()) {
        for (auto containers : phvSpec.mauGroups(t)) {
            // MAU groups should not be empty.
            EXPECT_LE(0, containers.min());

            // Containers in each group should have the same type.
            for (auto cid : containers)
                EXPECT_EQ(t, phvSpec.idToContainer(cid).type());

            mau_group_sizes[t.size()]++; } }

    EXPECT_EQ(4, mau_group_sizes[PHV::Size::b8]);
    EXPECT_EQ(6, mau_group_sizes[PHV::Size::b16]);
    EXPECT_EQ(4, mau_group_sizes[PHV::Size::b32]);
}

// Test that we can serialize PHV::Container objects to JSON.
void CheckPhvContainerJSON() {
    std::vector<PHV::Container> inputs = {
        PHV::Container("B0"),
        PHV::Container("H33"),
        PHV::Container("W55"),
        PHV::Container("TB10"),
        PHV::Container("TH2"),
        PHV::Container("TW90"),
    };

    for (PHV::Container inputContainer : inputs) {
        SCOPED_TRACE(inputContainer);

        // Serialize the container to JSON and deserialize it back again.
        std::stringstream jsonStream;
        JSONGenerator generator(jsonStream);
        generator << inputContainer;
        JSONLoader loader(jsonStream);
        PHV::Container outputContainer;
        loader >> outputContainer;

        // Make sure it survived the round trip unscathed.
        EXPECT_EQ(inputContainer, outputContainer);
    }
}

}  // namespace

TEST_F(TofinoPhvContainer, Types) {
    EXPECT_EQ(cstring("Tofino"), Device::currentDevice());
    CheckPhvContainerTypes();
}

TEST_F(TofinoPhvContainer, Resources) {
    EXPECT_EQ(cstring("Tofino"), Device::currentDevice());
    CheckTofinoPhvContainerResources();
}

TEST_F(TofinoPhvContainer, JSON) {
    EXPECT_EQ(cstring("Tofino"), Device::currentDevice());
    CheckPhvContainerJSON();
}

}  // namespace Test
