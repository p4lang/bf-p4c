#include "bf-p4c/phv/fieldslice_live_range.h"

#include <boost/algorithm/string/split.hpp>
#include "gtest/gtest.h"

#include "lib/exceptions.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

namespace {

PHV::LiveRangeInfo::OpInfo parse_info(const std::string& s) {
    if (s == "R") {
        return PHV::LiveRangeInfo::OpInfo::READ;
    } else if (s == "W") {
        return PHV::LiveRangeInfo::OpInfo::WRITE;
    } else if (s == "RW") {
        return PHV::LiveRangeInfo::OpInfo::READ_WRITE;
    } else if (s == "L") {
        return PHV::LiveRangeInfo::OpInfo::LIVE;
    } else if (s == "D") {
        return PHV::LiveRangeInfo::OpInfo::DEAD;
    } else {
        BUG("unknown liverange info: %1%", s);
    }
}

PHV::LiveRangeInfo make(const std::string& str) {
    std::list<std::string> ops;
    boost::split(ops, str, boost::is_any_of(" "), boost::token_compress_on);
    BUG_CHECK(ops.size() <= 14,
              "LiveRangeInfo on Tofino can have at most 14 elements: Parser stage0..11 Deparser");

    PHV::LiveRangeInfo rst;
    if (ops.size() == 0) {
        return rst;
    }
    rst.parser() = parse_info(ops.front());
    ops.pop_front();
    if (ops.size() > 12) {
        rst.deparser() = parse_info(ops.back());
        ops.pop_back();
    }
    int i = 0;
    for (const auto& v : ops) {
        rst.stage(i) = parse_info(v);
        i++;
    }
    return rst;
}

}  // helpers to make field live range

// require TofinoBackendTest to initialize Device::*.
class FieldSliceLiveRangeTest : public TofinoBackendTest {};

TEST_F(FieldSliceLiveRangeTest, can_overlay) {
    struct testcase {
        std::string a;
        std::string b;
        bool can_overlay;
    };
    std::vector<testcase> cases = {
        {"W L L  L R",
         "W L RW L D", false},
        {"D D W L R",
         "W R D D D", true},
        {"D D W L R",
         "W R R D D", true},
        {"D D W  L R",
         "W R RW R D", false},
        {"D D W L R",
         "W R R L R", false},
        {"D D W L R",
         "W R R R D", false},
        {"W L L R D D D",
         "D D D W L L R", true},
        {"W L L R D D D",
         "D D W RW L L R", false},
        {"W R D D D D",
         "W R D D D D", false},
        {"W L L L R D",
         "D D W L R D", false},
        {"D W L L L R",
         "W L RW L D", false},
        {"W R L L L R D D D W L L R",
         "D D D D D W L L L R D D D", true},
        {"D W L L L R D D  D D D D D D",
         "D D D D D W L RW L L R L L R", true},
        {"W W L L L R D D  D D D D D D",
         "D D D D D W L RW L L R L L R", true},
    };
    for (const auto& tc : cases) {
        EXPECT_EQ(tc.can_overlay, make(tc.a).can_overlay(make(tc.b)))
            << tc.a << " and " << tc.b << " can_be_overlaid should be: " << tc.can_overlay;
    }
}

TEST_F(FieldSliceLiveRangeTest, disjoint_ranges) {
    struct testcase {
        std::string info;
        std::vector<std::pair<PHV::StageAndAccess, PHV::StageAndAccess>> expected;
    };

    std::vector<testcase> cases = {
        {"W R",
         {
             {{-1, PHV::FieldUse(PHV::FieldUse::WRITE)}, {0, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        {"W L L R",
         {
             {{-1, PHV::FieldUse(PHV::FieldUse::WRITE)}, {2, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        {"W L L L L RW R",
         {
             {{-1, PHV::FieldUse(PHV::FieldUse::WRITE)}, {4, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{4, PHV::FieldUse(PHV::FieldUse::WRITE)}, {5, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        {"D D D D D D W L L R D D D D",
         {
             {{5, PHV::FieldUse(PHV::FieldUse::WRITE)}, {8, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        {"W L L L L R D D D W L L R",
         {
             {{-1, PHV::FieldUse(PHV::FieldUse::WRITE)}, {4, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{8, PHV::FieldUse(PHV::FieldUse::WRITE)}, {11, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        {"W L L L L RW R D D W L L R",
         {
             {{-1, PHV::FieldUse(PHV::FieldUse::WRITE)}, {4, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{4, PHV::FieldUse(PHV::FieldUse::WRITE)}, {5, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{8, PHV::FieldUse(PHV::FieldUse::WRITE)}, {11, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        {"D R D D D",
         {
             {{0, PHV::FieldUse(PHV::FieldUse::READ)}, {0, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        {"D R W L R D",
         {
             {{0, PHV::FieldUse(PHV::FieldUse::READ)}, {0, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{1, PHV::FieldUse(PHV::FieldUse::WRITE)}, {3, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        {"D RW L L R D",
         {
             {{0, PHV::FieldUse(PHV::FieldUse::READ)}, {0, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{0, PHV::FieldUse(PHV::FieldUse::WRITE)}, {3, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        //  0  1  2  3 4  5  6
        {"D RW RW L R RW RW R D D",
         {
             {{0, PHV::FieldUse(PHV::FieldUse::READ)}, {0, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{0, PHV::FieldUse(PHV::FieldUse::WRITE)}, {1, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{1, PHV::FieldUse(PHV::FieldUse::WRITE)}, {3, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{4, PHV::FieldUse(PHV::FieldUse::READ)}, {4, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{4, PHV::FieldUse(PHV::FieldUse::WRITE)}, {5, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{5, PHV::FieldUse(PHV::FieldUse::WRITE)}, {6, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        //  0  1  2  3 4  5  6
        {"D RW RW RW R RW RW R D D",
         {
             {{0, PHV::FieldUse(PHV::FieldUse::READ)}, {0, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{0, PHV::FieldUse(PHV::FieldUse::WRITE)}, {1, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{1, PHV::FieldUse(PHV::FieldUse::WRITE)}, {2, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{2, PHV::FieldUse(PHV::FieldUse::WRITE)}, {3, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{4, PHV::FieldUse(PHV::FieldUse::READ)}, {4, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{4, PHV::FieldUse(PHV::FieldUse::WRITE)}, {5, PHV::FieldUse(PHV::FieldUse::READ)}},
             {{5, PHV::FieldUse(PHV::FieldUse::WRITE)}, {6, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        // ignore parser read.
        {"RW L L L R D",
         {
             {{-1, PHV::FieldUse(PHV::FieldUse::WRITE)}, {3, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        /// tailing writes
        {"W D D",
         {
             {{-1, PHV::FieldUse(PHV::FieldUse::WRITE)}, {-1, PHV::FieldUse(PHV::FieldUse::WRITE)}},
         }},
        {"W W L L R",
         {
             {{-1, PHV::FieldUse(PHV::FieldUse::WRITE)}, {-1, PHV::FieldUse(PHV::FieldUse::WRITE)}},
             {{0, PHV::FieldUse(PHV::FieldUse::WRITE)}, {3, PHV::FieldUse(PHV::FieldUse::READ)}},
         }},
        {"W D D W",
         {
             {{-1, PHV::FieldUse(PHV::FieldUse::WRITE)}, {-1, PHV::FieldUse(PHV::FieldUse::WRITE)}},

             {{2, PHV::FieldUse(PHV::FieldUse::WRITE)}, {2, PHV::FieldUse(PHV::FieldUse::WRITE)}},
         }},
    };
    for (const auto& tc : cases) {
        auto rst = make(tc.info).disjoint_ranges();
        ASSERT_EQ(tc.expected.size(), rst.size()) << "range unequal length: " << tc.info;
        for (int i = 0; i < int(rst.size()); ++i) {
            EXPECT_EQ(tc.expected[i], rst[i]) << "unequal at " << i << "; case: " << tc.info;
        }
    }
}

}  // namespace Test
