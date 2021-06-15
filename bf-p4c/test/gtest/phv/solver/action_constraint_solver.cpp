#include "bf-p4c/phv/solver/action_constraint_solver.h"
#include <exception>
#include "gmock/gmock-matchers.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "lib/exceptions.h"

namespace Test {

using namespace solver;
using ::testing::HasSubstr;

TEST(action_constraint_solver, invalid_missing_container_spec) {
    auto solver = ActionMoveSolver();
    try {
        solver.set_container_spec("H1", 16, bitvec());
        solver.add_assign(make_container_operand("H1", StartLen(0, 3)),
                          make_container_operand("H2", StartLen(0, 3)));
        FAIL();
    } catch (const Util::CompilerBug& e) {
        EXPECT_THAT(e.what(), HasSubstr("container used missing spec: H2"));
    }
}

TEST(action_constraint_solver, invalid_out_of_range_assign) {
    auto solver = ActionMoveSolver();
    try {
        solver.set_container_spec("H1", 16, bitvec(0, 16));
        solver.set_container_spec("H2", 16, bitvec());
        solver.add_assign(make_container_operand("H1", StartLen(0, 17)),
                          make_container_operand("H2", StartLen(0, 16)));
        FAIL();
    } catch (const Util::CompilerBug& e) {
        EXPECT_THAT(e.what(), HasSubstr("out of index range: H1 bit[16..0]"));
    }
}

TEST(action_constraint_solver, invalid_range_not_equal) {
    auto solver = ActionMoveSolver();
    try {
        solver.set_container_spec("H1", 16, bitvec(0, 16));
        solver.set_container_spec("H2", 16, bitvec());
        solver.add_assign(make_container_operand("H1", StartLen(0, 3)),
                          make_container_operand("H2", StartLen(0, 4)));
        FAIL();
    } catch (const Util::CompilerBug& e) {
        EXPECT_THAT(e.what(), HasSubstr("assignment range mismatch: H1 bit[2..0] = H2 bit[3..0]"));
    }
}

TEST(action_constraint_solver, invalid_assign_to_bits_not_live) {
    auto solver = ActionMoveSolver();
    try {
        bitvec h1_live;
        h1_live.setrange(0, 2);
        solver.set_container_spec("H1", 16, h1_live);
        solver.set_container_spec("H2", 16, bitvec());
        solver.add_assign(make_container_operand("H1", StartLen(0, 3)),
                          make_container_operand("H2", StartLen(0, 3)));
        FAIL();
    } catch (const Util::CompilerBug& e) {
        EXPECT_THAT(e.what(),
                    HasSubstr("container H1's 2th bit is not claimed live, but was set by "
                              "H1 bit[2..0] = H2 bit[2..0]"));
    }
}

TEST(action_constraint_solver, one_field_assign) {
    auto solver = ActionMoveSolver();
    solver.set_container_spec("H1", 16, bitvec(0, 16));
    solver.set_container_spec("H2", 16, bitvec());
    solver.add_assign(make_container_operand("H1", StartLen(0, 3)),
                      make_container_operand("H2", StartLen(0, 3)));
    auto err = solver.solve();
    EXPECT_FALSE(err);
}

TEST(action_constraint_solver, one_field_assign_rot_aligned) {
    auto solver = ActionMoveSolver();
    solver.set_container_spec("H1", 16, bitvec(0, 16));
    solver.set_container_spec("H2", 16, bitvec());
    solver.add_assign(make_container_operand("H1", StartLen(0, 3)),
                      make_container_operand("H2", StartLen(11, 3)));
    auto err = solver.solve();
    EXPECT_FALSE(err);
}

TEST(action_constraint_solver, two_field_one_container_assign) {
    // both src1 and src2 are H2, dest do not have other fields, shifted by 1.
    auto solver = ActionMoveSolver();
    bitvec h1_live;
    h1_live.setrange(0, 7);
    solver.set_container_spec("H1", 16, h1_live);
    solver.set_container_spec("H2", 16, bitvec());
    solver.add_assign(make_container_operand("H1", FromTo(0, 3)),
                      make_container_operand("H2", FromTo(0, 3)));
    solver.add_assign(make_container_operand("H1", FromTo(4, 6)),
                      make_container_operand("H2", FromTo(5, 7)));
    auto err = solver.solve();
    EXPECT_FALSE(err);
}

TEST(action_constraint_solver, two_field_assign_src2_ne_dest) {
    // src2 is H2, not same as dest, dest has other fields, shifted by 1.
    auto solver = ActionMoveSolver();
    solver.set_container_spec("H1", 16, bitvec(0, 16));
    solver.set_container_spec("H2", 16, bitvec());
    solver.add_assign(make_container_operand("H1", FromTo(0, 3)),
                      make_container_operand("H2", FromTo(0, 3)));
    solver.add_assign(make_container_operand("H1", FromTo(4, 6)),
                      make_container_operand("H1", FromTo(5, 7)));
    auto err = solver.solve();
    EXPECT_TRUE(err);
    EXPECT_EQ(ErrorCode::deposit_src2_must_be_dest, err->code);
    EXPECT_THAT(err->msg.c_str(),
                HasSubstr("destination H1 will be corrupted because src2 H2 is not equal to dest"));
}

TEST(action_constraint_solver, two_field_assign_dest_no_live_bits) {
    // src2 is H2, not same as dest, dest DOES NOT have other fields, shifted by 1.
    auto solver = ActionMoveSolver();
    bitvec h1_live;
    h1_live.setrange(0, 7);
    solver.set_container_spec("H1", 16, h1_live);
    solver.set_container_spec("H2", 16, bitvec());
    solver.set_container_spec("H3", 16, bitvec());
    solver.add_assign(make_container_operand("H1", FromTo(0, 3)),
                      make_container_operand("H2", FromTo(0, 3)));
    solver.add_assign(make_container_operand("H1", FromTo(4, 6)),
                      make_container_operand("H3", FromTo(5, 7)));
    auto err = solver.solve();
    EXPECT_FALSE(err);
}

TEST(action_constraint_solver, wrap_around_1) {
    // src2 is H1, same as dest, dest has other fields, shifted by -1.
    auto solver = ActionMoveSolver();
    bitvec h1_live;
    h1_live.setrange(0, 7);
    solver.set_container_spec("H1", 16, h1_live);
    solver.set_container_spec("H2", 16, bitvec());
    // [0:3] is used by other field.
    // solver.add_assign(Operand{false, "H1", FromTo(0, 3)}, Operand{false, "H1", FromTo(0, 3)});
    solver.add_assign(make_container_operand("H1", FromTo(4, 6)),
                      make_container_operand("H2", FromTo(3, 5)));
    auto err = solver.solve();
    EXPECT_FALSE(err);
}

TEST(action_constraint_solver, wrap_around_2) {
    // src2 is H1, same as dest, dest has other fields, shifted by -1.
    auto solver = ActionMoveSolver();
    solver.set_container_spec("H1", 16, bitvec(0, 16));
    solver.set_container_spec("H2", 16, bitvec());
    // solver.add_assign(Operand{false, "H1", FromTo(8, 9)}, Operand{false, "H1", FromTo(8, 9)});
    solver.add_assign(make_container_operand("H1", FromTo(13, 14)),
                      make_container_operand("H2", FromTo(0, 1)));
    solver.add_assign(make_container_operand("H1", FromTo(15, 15)),
                      make_container_operand("H2", FromTo(2, 2)));
    solver.add_assign(make_container_operand("H1", FromTo(11, 12)),
                      make_container_operand("H2", FromTo(14, 15)));
    auto err = solver.solve();
    EXPECT_FALSE(err);
}

TEST(action_constraint_solver, wrap_around_3) {
    // src2 is H1, same as dest, dest has other fields, ad, no shift.
    auto solver = ActionMoveSolver();
    solver.set_container_spec("H1", 16, bitvec(0, 16));
    solver.set_container_spec("H2", 16, bitvec());
    // solver.add_assign(Operand{false, "H1", FromTo(8, 9)}, Operand{false, "H1", FromTo(8, 9)});
    solver.add_assign(make_container_operand("H1", FromTo(13, 14)),
                      make_ad_or_const_operand());
    solver.add_assign(make_container_operand("H1", FromTo(15, 15)),
                      make_ad_or_const_operand());
    solver.add_assign(make_container_operand("H1", FromTo(11, 12)),
                      make_ad_or_const_operand());
    auto err = solver.solve();
    EXPECT_FALSE(err);
}

TEST(action_constraint_solver, byte_rotate_merge_byte_reversed) {
    auto solver = ActionMoveSolver();
    solver.set_container_spec("W35", 32, bitvec(0, 32));
    solver.add_assign(make_container_operand("W35", FromTo(0, 7)),
                      make_container_operand("W35", FromTo(24, 31)));
    solver.add_assign(make_container_operand("W35", FromTo(8, 15)),
                      make_container_operand("W35", FromTo(16, 23)));
    solver.add_assign(make_container_operand("W35", FromTo(16, 23)),
                      make_container_operand("W35", FromTo(8, 15)));
    solver.add_assign(make_container_operand("W35", FromTo(24, 31)),
                      make_container_operand("W35", FromTo(0, 7)));
    auto err = solver.solve();
    EXPECT_FALSE(err);
}

TEST(action_constraint_solver, byte_rotate_merge_reversed_from_other_field) {
    auto solver = ActionMoveSolver();
    solver.set_container_spec("W35", 32, bitvec(0, 32));
    solver.set_container_spec("W36", 32, bitvec());
    solver.add_assign(make_container_operand("W35", FromTo(0, 7)),
                      make_container_operand("W36", FromTo(24, 31)));
    solver.add_assign(make_container_operand("W35", FromTo(8, 15)),
                      make_container_operand("W36", FromTo(16, 23)));
    solver.add_assign(make_container_operand("W35", FromTo(16, 23)),
                      make_container_operand("W36", FromTo(8, 15)));
    solver.add_assign(make_container_operand("W35", FromTo(24, 31)),
                      make_container_operand("W36", FromTo(0, 7)));
    auto err = solver.solve();
    EXPECT_FALSE(err);
}

TEST(action_constraint_solver, byte_rotate_merge_half_reversed_1) {
    auto solver = ActionMoveSolver();
    solver.set_container_spec("W35", 32, bitvec(0, 32));
    solver.add_assign(make_container_operand("W35", FromTo(0, 7)),
                      make_container_operand("W35", FromTo(24, 31)));
    solver.add_assign(make_container_operand("W35", FromTo(16, 23)),
                      make_container_operand("W35", FromTo(8, 15)));
    auto err = solver.solve();
    EXPECT_FALSE(err);
}

TEST(action_constraint_solver, byte_rotate_merge_half_reversed_2) {
    auto solver = ActionMoveSolver();
    solver.set_container_spec("W35", 32, bitvec(0, 32));
    solver.set_container_spec("W36", 32, bitvec());
    solver.add_assign(make_container_operand("W35", FromTo(0, 7)),
                      make_container_operand("W36", FromTo(24, 31)));
    solver.add_assign(make_container_operand("W35", FromTo(8, 15)),
                      make_container_operand("W36", FromTo(0, 7)));
    auto err = solver.solve();
    EXPECT_FALSE(err);
}

TEST(action_constraint_solver, byte_rotate_merge_mixed) {
    auto solver = ActionMoveSolver();
    solver.set_container_spec("W35", 32, bitvec());
    solver.set_container_spec("W36", 32, bitvec());
    solver.set_container_spec("W0", 32, bitvec(0, 32));
    solver.add_assign(make_container_operand("W0", FromTo(0, 7)),
                      make_container_operand("W35", FromTo(24, 31)));
    solver.add_assign(make_container_operand("W0", FromTo(8, 15)),
                      make_container_operand("W36", FromTo(16, 23)));
    solver.add_assign(make_container_operand("W0", FromTo(16, 23)),
                      make_container_operand("W35", FromTo(8, 15)));
    solver.add_assign(make_container_operand("W0", FromTo(24, 31)),
                      make_container_operand("W36", FromTo(0, 7)));
    auto err = solver.solve();
    EXPECT_FALSE(err);
}

}  // namespace Test
