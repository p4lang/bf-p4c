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

#include "gtest/gtest.h"

#include "lib/bitvec.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/phv/phv.h"

namespace Test {

// Test that each kind of PHV::Container has the expected properties.
TEST(TofinoPhvContainer, Kinds) {
    using Kind = PHV::Container::Kind;

    auto checkRange = [](PHV::Container c) {
        SCOPED_TRACE(c);
        auto begin = c.index() / 2;
        auto length = std::max(c.index() * 2, 128u);
        for (unsigned kindId = 0; kindId < PHV::Container::NumKinds; ++kindId) {
            auto range = PHV::Container::range(Kind(kindId), begin, length);
            if (kindId == unsigned(c.kind()))
                EXPECT_TRUE(range.getbit(c.id()));
            else
                EXPECT_FALSE(range.getbit(c.id()));
        }

        auto rangeBefore = PHV::Container::range(c.kind(), 0, c.index());
        EXPECT_FALSE(rangeBefore.getbit(c.id()));
        auto rangeAfter = PHV::Container::range(c.kind(), c.index() + 1, 64);
        EXPECT_FALSE(rangeAfter.getbit(c.id()));
    };

    PHV::Container c;
    EXPECT_FALSE(static_cast<bool>(c));

    c = "B0";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Kind::B, c.kind());
    EXPECT_EQ(0u, c.log2sz());
    EXPECT_EQ(0u, c.index());
    EXPECT_FALSE(c.tagalong());
    EXPECT_EQ(c, PHV::Container(Kind::B, 0));
    EXPECT_EQ(c, PHV::Container::fromId(c.id()));
    EXPECT_TRUE(PHV::Container::range(Kind::B, 0, 16).getbit(c.id()));
    EXPECT_TRUE(PHV::Container::range(Kind::B, 0, 16).getbit(c.id()));
    checkRange(c);

    c = "H15";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Kind::H, c.kind());
    EXPECT_EQ(1u, c.log2sz());
    EXPECT_EQ(15u, c.index());
    EXPECT_FALSE(c.tagalong());
    EXPECT_EQ(c, PHV::Container(Kind::H, 15));
    EXPECT_EQ(c, PHV::Container::fromId(c.id()));
    checkRange(c);

    c = "W3157";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Kind::W, c.kind());
    EXPECT_EQ(2u, c.log2sz());
    EXPECT_EQ(3157u, c.index());
    EXPECT_FALSE(c.tagalong());
    EXPECT_EQ(c, PHV::Container(Kind::W, 3157));
    EXPECT_EQ(c, PHV::Container::fromId(c.id()));
    checkRange(c);

    c = "TB0";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Kind::TB, c.kind());
    EXPECT_EQ(0u, c.log2sz());
    EXPECT_EQ(0u, c.index());
    EXPECT_TRUE(c.tagalong());
    EXPECT_EQ(c, PHV::Container(Kind::TB, 0));
    EXPECT_EQ(c, PHV::Container::fromId(c.id()));
    checkRange(c);

    c = "TH15";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Kind::TH, c.kind());
    EXPECT_EQ(1u, c.log2sz());
    EXPECT_EQ(15u, c.index());
    EXPECT_TRUE(c.tagalong());
    EXPECT_EQ(c, PHV::Container(Kind::TH, 15));
    EXPECT_EQ(c, PHV::Container::fromId(c.id()));
    checkRange(c);

    c = "TW3157";
    EXPECT_TRUE(static_cast<bool>(c));
    EXPECT_EQ(Kind::TW, c.kind());
    EXPECT_EQ(2u, c.log2sz());
    EXPECT_EQ(3157u, c.index());
    EXPECT_TRUE(c.tagalong());
    EXPECT_EQ(c, PHV::Container(Kind::TW, 3157));
    EXPECT_EQ(c, PHV::Container::fromId(c.id()));
    checkRange(c);

    EXPECT_ANY_THROW(PHV::Container("X1"));
    EXPECT_ANY_THROW(PHV::Container("B"));  // XXX(seth)
    EXPECT_ANY_THROW(PHV::Container("W-1"));
}

}  // namespace Test
