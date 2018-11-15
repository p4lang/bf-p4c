#include "gtest/gtest.h"

#include <boost/optional.hpp>

#include "bf-p4c/device.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/phv/allocate_phv.h"
#include "bf-p4c/phv/constraints.h"
#include "bf-p4c/phv/field_alignment.h"
#include "bf-p4c/phv/utils/utils.h"
#include "lib/bitvec.h"
#include "test/gtest/helpers.h"

// disable these tests for gcc-4.9, which for some reason
// do not link with boost::optional
#if (__GNUC__ > 4) || defined(__clang__)
namespace Test {

using namespace Constraint;

TEST(PHVConstraints, ExtractorSchema) {
    // Empty schema have no fields
    PHV::Field f;
    ExtractorSchema es0(std::vector<PHV::Field*>({}));
    EXPECT_EQ(0U, es0.size());
    EXPECT_EQ(boost::none, es0.offset(&f));

    auto* f1 = new PHV::Field;
    auto* f2 = new PHV::Field;

    f1->id = 1;
    f1->size = 7;
    f1->name = "f1";
    f2->id = 2;
    f2->size = 3;
    f2->name = "f2";

    ExtractorSchema es1({f1, f2});
    EXPECT_EQ(2U, es1.size());
    EXPECT_EQ(0U, es1.offset(f1));
    EXPECT_EQ(7U, es1.offset(f2));
    EXPECT_EQ(f1, *es1.begin());

    ExtractorSchema es2({f2, f1});
    EXPECT_EQ(2U, es2.size());
    EXPECT_EQ(0U, es2.offset(f2));
    EXPECT_EQ(3U, es2.offset(f1));
    EXPECT_EQ(f2, *es2.begin());
}

TEST(PHVConstraints, DeparserSchema) {
    // Empty schema have no fields
    PHV::Field f;
    DeparserSchema es0(std::vector<PHV::Field*>({}));
    EXPECT_EQ(0U, es0.size());
    EXPECT_EQ(boost::none, es0.offset(&f));

    auto* f1 = new PHV::Field;
    auto* f2 = new PHV::Field;

    f1->id = 1;
    f1->size = 7;
    f1->name = "f1";
    f2->id = 2;
    f2->size = 3;
    f2->name = "f2";

    DeparserSchema es1({f1, f2});
    EXPECT_EQ(2U, es1.size());
    EXPECT_EQ(0U, es1.offset(f1));
    EXPECT_EQ(7U, es1.offset(f2));
    EXPECT_EQ(f1, *es1.begin());

    DeparserSchema es2({f2, f1});
    EXPECT_EQ(2U, es2.size());
    EXPECT_EQ(0U, es2.offset(f2));
    EXPECT_EQ(3U, es2.offset(f1));
    EXPECT_EQ(f2, *es2.begin());
}

}   // namespace Test
#endif  // (__GNUC__ > 4) || defined(__clang__)
