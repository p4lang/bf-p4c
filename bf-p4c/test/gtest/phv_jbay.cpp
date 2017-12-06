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

    EXPECT_ANY_THROW(PHV::Container("X1"));
    EXPECT_ANY_THROW(PHV::Container("B"));  // XXX(seth)
    EXPECT_ANY_THROW(PHV::Container("W-1"));
}

void CheckJBayPhvContainerResources() {
    const auto& phvSpec = Device::phvSpec();

    // MAU containers should be subsets of the physical containers.
    for (auto t : phvSpec.containerTypes()) {
        for (auto mau_group : phvSpec.mauGroups(t)) {
            EXPECT_NE(bitvec(), mau_group & phvSpec.physicalContainers()); } }

    // MAU groups should have the type used to retrieve them.
    for (auto t : phvSpec.containerTypes()) {
        for (auto mau_group : phvSpec.mauGroups(t)) {
            for (auto cid : mau_group) {
                EXPECT_EQ(t, phvSpec.idToContainer(cid).type()); } } }
}

// Test that we can serialize PHV::Container objects to JSON.
void CheckPhvContainerJSON() {
    std::vector<PHV::Container> inputs = {
        PHV::Container("B0"),
        PHV::Container("H33"),
        PHV::Container("W55"),
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

class JBayPhvContainer : public JBayBackendTest {};

TEST_F(JBayPhvContainer, Types) {
    EXPECT_EQ(cstring("JBay"), Device::currentDevice());
    CheckPhvContainerTypes();
}

TEST_F(JBayPhvContainer, Resources) {
    EXPECT_EQ(cstring("JBay"), Device::currentDevice());
    CheckJBayPhvContainerResources();
}

TEST_F(JBayPhvContainer, JSON) {
    EXPECT_EQ(cstring("JBay"), Device::currentDevice());
    CheckPhvContainerJSON();
}

}  // namespace Test
