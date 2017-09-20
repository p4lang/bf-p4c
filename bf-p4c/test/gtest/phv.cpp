/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "bf-p4c/phv/phv.h"
#include "gtest/gtest.h"

#include "lib/bitvec.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "tofino_gtest_utils.h"

namespace Test {

class TofinoPhvContainer : public TofinoBackendTest {};

// Test that each type of PHV::Container has the expected properties.
TEST_F(TofinoPhvContainer, Types) {
    using Type = PHV::Type;

    auto checkRange = [](PHV::Container c) {
        SCOPED_TRACE(c);
        auto begin = c.index() / 2;
        auto length = std::max(c.index() * 2, 128u);
        for (unsigned typeId = 0; typeId < Device::phvSpec().numTypes(); ++typeId) {
            auto range = Device::phvSpec().range(Type(typeId), begin, length);
            if (typeId == c.type().id())
                EXPECT_TRUE(range.getbit(c.id()));
            else
                EXPECT_FALSE(range.getbit(c.id()));
        }

        auto rangeBefore = Device::phvSpec().range(c.type(), 0, c.index());
        EXPECT_FALSE(rangeBefore.getbit(c.id()));
        auto rangeAfter = Device::phvSpec().range(c.type(), c.index() + 1, 64);
        EXPECT_FALSE(rangeAfter.getbit(c.id()));
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
    EXPECT_EQ(c, PHV::Container::fromId(c.id()));
    EXPECT_TRUE(Device::phvSpec().range(Type("B"), 0, 16).getbit(c.id()));
    EXPECT_TRUE(Device::phvSpec().range(Type("B"), 0, 16).getbit(c.id()));
    checkRange(c);

    c = "H15";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Type("H"), c.type());
    EXPECT_EQ(1u, c.log2sz());
    EXPECT_EQ(15u, c.index());
    EXPECT_FALSE(c.is(PHV::Kind::tagalong));
    EXPECT_EQ(c, PHV::Container(Type("H"), 15));
    EXPECT_EQ(c, PHV::Container::fromId(c.id()));
    checkRange(c);

    c = "W3157";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Type("W"), c.type());
    EXPECT_EQ(2u, c.log2sz());
    EXPECT_EQ(3157u, c.index());
    EXPECT_FALSE(c.is(PHV::Kind::tagalong));
    EXPECT_EQ(c, PHV::Container(Type("W"), 3157));
    EXPECT_EQ(c, PHV::Container::fromId(c.id()));
    checkRange(c);

    c = "TB0";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Type("TB"), c.type());
    EXPECT_EQ(0u, c.log2sz());
    EXPECT_EQ(0u, c.index());
    EXPECT_TRUE(c.is(PHV::Kind::tagalong));
    EXPECT_EQ(c, PHV::Container(Type("TB"), 0));
    EXPECT_EQ(c, PHV::Container::fromId(c.id()));
    checkRange(c);

    c = "TH15";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Type("TH"), c.type());
    EXPECT_EQ(1u, c.log2sz());
    EXPECT_EQ(15u, c.index());
    EXPECT_TRUE(c.is(PHV::Kind::tagalong));
    EXPECT_EQ(c, PHV::Container(Type("TH"), 15));
    EXPECT_EQ(c, PHV::Container::fromId(c.id()));
    checkRange(c);

    c = "TW3157";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Type("TW"), c.type());
    EXPECT_EQ(2u, c.log2sz());
    EXPECT_EQ(3157u, c.index());
    EXPECT_TRUE(c.is(PHV::Kind::tagalong));
    EXPECT_EQ(c, PHV::Container(Type("TW"), 3157));
    EXPECT_EQ(c, PHV::Container::fromId(c.id()));
    checkRange(c);

    EXPECT_ANY_THROW(PHV::Container("X1"));
    EXPECT_ANY_THROW(PHV::Container("B"));  // XXX(seth)
    EXPECT_ANY_THROW(PHV::Container("W-1"));
}

}  // namespace Test
