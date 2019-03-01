#include "bf-p4c/mau/action_format_2.h"
#include "lib/log.h"
#include "gtest/gtest.h"

namespace Test {

void BasicRotation_test1(ActionData::RamSection *ad, ActionData::Argument *arg) {
    auto rotate1 = ad->can_rotate(0, 4);
    BUG_CHECK(rotate1 != nullptr, "Rotation should be possible");

    ActionData::ParameterPositions param_positions = rotate1->parameter_positions();

    EXPECT_EQ(param_positions.size(), 1U);
    auto param_pos = param_positions.find(4);
    EXPECT_TRUE(param_pos != param_positions.end());
    if (param_pos != param_positions.end()) {
        EXPECT_TRUE(arg->equiv_value(param_pos->second));
    }

    auto right_rotate1 = rotate1->can_rotate(4, 2);
    param_positions = right_rotate1->parameter_positions();
    EXPECT_EQ(param_positions.size(), 1U);
    param_pos = param_positions.find(2);
    EXPECT_TRUE(param_pos != param_positions.end());
    if (param_pos != param_positions.end()) {
        EXPECT_TRUE(arg->equiv_value(param_pos->second));
    }
}

void BasicRotation_test2(ActionData::RamSection *ad, ActionData::Argument *arg) {
    auto rotate2 = ad->can_rotate(0, 6);
    BUG_CHECK(rotate2 != nullptr, "Rotation should be possible");

    ActionData::ParameterPositions param_positions = rotate2->parameter_positions();
    EXPECT_EQ(param_positions.size(), 2U);
    auto param_pos = param_positions.find(0);
    EXPECT_TRUE(param_pos != param_positions.end());
    if (param_pos != param_positions.end()) {
        EXPECT_TRUE(arg->split(2, 3)->equiv_value(param_pos->second));
    }

    param_pos = param_positions.find(6);
    EXPECT_TRUE(param_pos != param_positions.end());
    if (param_pos != param_positions.end()) {
        EXPECT_TRUE(arg->split(0, 1)->equiv_value(param_pos->second));
    }
}

/**
 * Guarantee that the can_rotate function can work on a single level
 */
TEST(ActionFormatHelper, BasicRotation) {
    int basic_size = 8;
    safe_vector<ActionData::PackingConstraint> pc_vec;
    for (int i = 0; i < 8; i++) {
        pc_vec.emplace_back();
    }
    ActionData::PackingConstraint pc(1, pc_vec);
    ActionData::RamSection *ad = new ActionData::RamSection(basic_size, pc);
    ActionData::Argument *arg = new ActionData::Argument("arg1", {0, 3});
    ad->add_param(0, arg);
    BasicRotation_test1(ad, arg);
    BasicRotation_test2(ad, arg);
}

void LayeredRotation_test1(ActionData::RamSection *ad, ActionData::Argument *arg1,
        ActionData::Argument *arg2, ActionData::Argument *arg3) {
    auto byte_rotate = ad->can_rotate(8, 0);
    BUG_CHECK(byte_rotate != nullptr, "Rotation should be possible");
    ActionData::ParameterPositions param_positions = byte_rotate->parameter_positions();

    EXPECT_EQ(param_positions.size(), 3U);
    auto param_pos = param_positions.find(0);
    EXPECT_TRUE(param_pos != param_positions.end());
    if (param_pos != param_positions.end()) {
        EXPECT_TRUE(arg3->equiv_value(param_pos->second));
    }

    param_pos = param_positions.find(8);
    EXPECT_TRUE(param_pos != param_positions.end());
    if (param_pos != param_positions.end()) {
        EXPECT_TRUE(arg1->equiv_value(param_pos->second));
    }

    param_pos = param_positions.find(12);
    EXPECT_TRUE(param_pos != param_positions.end());
    if (param_pos != param_positions.end()) {
        EXPECT_TRUE(arg2->equiv_value(param_pos->second));
    }
}

void LayeredRotation_test2(ActionData::RamSection *ad, ActionData::Argument *arg1,
        ActionData::Argument *arg2, ActionData::Argument *arg3) {
    auto bit_rotate1 = ad->can_rotate(0, 12);
    BUG_CHECK(bit_rotate1 != nullptr, "Rotation should be possible");
    ActionData::ParameterPositions param_positions = bit_rotate1->parameter_positions();

    EXPECT_EQ(param_positions.size(), 3U);
    auto param_pos = param_positions.find(0);
    EXPECT_TRUE(param_pos != param_positions.end());
    if (param_pos != param_positions.end()) {
        EXPECT_TRUE(arg3->equiv_value(param_pos->second));
    }

    param_pos = param_positions.find(8);
    EXPECT_TRUE(param_pos != param_positions.end());
    if (param_pos != param_positions.end()) {
        EXPECT_TRUE(arg2->equiv_value(param_pos->second));
    }

    param_pos = param_positions.find(12);
    EXPECT_TRUE(param_pos != param_positions.end());
    if (param_pos != param_positions.end()) {
        EXPECT_TRUE(arg1->equiv_value(param_pos->second));
    }

    auto bit_rotate2 = ad->can_rotate(12, 0);
    EXPECT_EQ(bit_rotate2, nullptr);
}

/**
 * Verifies that the can_rotate function can work through multiple levels of RecursiveConstraints
 */
TEST(ActionFormatHelper, LayeredRotation) {
    int first_layer_size = 8;
    safe_vector<ActionData::PackingConstraint> pc_vec;
    for (int i = 0; i < first_layer_size; i++) {
        pc_vec.emplace_back();
    }
    ActionData::PackingConstraint first_pc(1, pc_vec);
    int second_layer_size = 16;
    pc_vec.clear();
    pc_vec.push_back(first_pc);
    pc_vec.emplace_back();
    ActionData::PackingConstraint second_layer_pc(8, pc_vec);

    ActionData::RamSection *ad = new ActionData::RamSection(second_layer_size, second_layer_pc);

    ActionData::Argument *arg1 = new ActionData::Argument("arg1", {0, 3});
    ActionData::Argument *arg2 = new ActionData::Argument("arg2", {0, 3});
    ActionData::Argument *arg3 = new ActionData::Argument("arg3", {0, 7});

    ad->add_param(0, arg1);
    ad->add_param(4, arg2);
    ad->add_param(8, arg3);
    LayeredRotation_test1(ad, arg1, arg2, arg3);
    LayeredRotation_test2(ad, arg1, arg2, arg3);
}

void SimpleMerge_test1(ActionData::RamSection *ad1, ActionData::RamSection *ad2) {
    ActionData::Argument *arg1 = new ActionData::Argument("arg1", {0, 3});
    ActionData::Argument *arg2 = new ActionData::Argument("arg2", {0, 3});

    ad1->add_param(0, arg1);
    ad2->add_param(4, arg2);
    auto merge = ad1->merge(ad2);
    auto pack_info = merge->get_pack_info();
    auto rec_const = pack_info.get_recursive_constraints();

    EXPECT_EQ(rec_const.size(), 8U);
    EXPECT_EQ(pack_info.get_granularity(), 1);
}

TEST(ActionFormatHelper, SimpleMerge) {
    int basic_size = 8;
    safe_vector<ActionData::PackingConstraint> pc_vec;
    for (int i = 0; i < 8; i++) {
        pc_vec.emplace_back();
    }
    ActionData::PackingConstraint pc(1, pc_vec);
    ActionData::RamSection *ad1 = new ActionData::RamSection(basic_size, pc);
    ActionData::RamSection *ad2 = new ActionData::RamSection(basic_size, pc);
    SimpleMerge_test1(ad1, ad2);
}

void OverlapMerge_test1(ActionData::RamSection *ad1, ActionData::RamSection *ad2) {
    ActionData::Argument *arg1 = new ActionData::Argument("arg1", {0, 5});
    ActionData::Argument *arg2 = new ActionData::Argument("arg1", {2, 7});

    ad1->add_param(0, arg1);
    ad2->add_param(2, arg2);
    auto merge = ad1->merge(ad2);

    auto pack_info = merge->get_pack_info();
    auto rec_const = pack_info.get_recursive_constraints();

    EXPECT_EQ(rec_const.size(), 8U);
    EXPECT_EQ(pack_info.get_granularity(), 1);
}


TEST(ActionFormatHelper, OverlapMerge) {
    int basic_size = 8;
    safe_vector<ActionData::PackingConstraint> pc_vec;
    for (int i = 0; i < 8; i++) {
        pc_vec.emplace_back();
    }
    ActionData::PackingConstraint pc(1, pc_vec);
    ActionData::RamSection *ad1 = new ActionData::RamSection(basic_size, pc);
    ActionData::RamSection *ad2 = new ActionData::RamSection(basic_size, pc);
    OverlapMerge_test1(ad1, ad2);
}

void CrossSizeMerge_test1(ActionData::RamSection *ad_8bit, ActionData::RamSection *ad_16bit) {
    ActionData::Argument *arg1 = new ActionData::Argument("arg1", {0, 7});
    ActionData::Argument *arg2 = new ActionData::Argument("arg2", {0, 7});

    ad_16bit->add_param(8, arg1);
    ad_8bit->add_param(0, arg2);
    auto merge = ad_16bit->merge(ad_8bit);

    auto pack_info = merge->get_pack_info();
    auto rec_const_level1 = pack_info.get_recursive_constraints();
    EXPECT_EQ(rec_const_level1.size(), 2U);
    EXPECT_EQ(pack_info.get_granularity(), 8);

    auto pack_info2_1 = rec_const_level1[0];
    auto rec_const_level2_1 = pack_info2_1.get_recursive_constraints();

    EXPECT_EQ(rec_const_level2_1.size(), 8U);
    EXPECT_EQ(pack_info2_1.get_granularity(), 1);

    auto pack_info3_1 = rec_const_level2_1[0];
    auto rec_const_level3_1 = pack_info3_1.get_recursive_constraints();

    EXPECT_EQ(rec_const_level3_1.size(), 0U);
    EXPECT_EQ(pack_info3_1.get_granularity(), -1);

    auto pack_info2_2 = rec_const_level1[1];
    auto rec_const_level2_2 = pack_info2_2.get_recursive_constraints();

    EXPECT_EQ(rec_const_level2_2.size(), 0U);
    EXPECT_EQ(pack_info2_2.get_granularity(), -1);
}

void CrossSizeMerge_test2(ActionData::RamSection *ad_8bit, ActionData::RamSection *ad_16bit) {
    ActionData::Argument *arg1 = new ActionData::Argument("arg1", {0, 5});
    ActionData::Argument *arg2 = new ActionData::Argument("arg2", {0, 5});

    ad_8bit->add_param(0, arg1);
    ad_16bit->add_param(6, arg2);
    auto merge = ad_16bit->merge(ad_8bit);

    auto pack_info = merge->get_pack_info();
    auto rec_const_level1 = pack_info.get_recursive_constraints();
    EXPECT_EQ(rec_const_level1.size(), 2U);
    EXPECT_EQ(pack_info.get_granularity(), 8);

    auto pack_info2_1 = rec_const_level1[0];
    auto rec_const_level2_1 = pack_info2_1.get_recursive_constraints();

    EXPECT_EQ(rec_const_level2_1.size(), 0U);
    EXPECT_FALSE(pack_info2_1.is_rotational());

    auto pack_info2_2 = rec_const_level1[1];
    auto rec_const_level2_2 = pack_info2_2.get_recursive_constraints();

    EXPECT_EQ(rec_const_level2_2.size(), 0U);
    EXPECT_FALSE(pack_info2_2.is_rotational());
}

void CrossSizeMerge_test3(ActionData::RamSection *ad_8bit, ActionData::RamSection *ad_16bit) {
    ActionData::Argument *arg1 = new ActionData::Argument("arg1", {0, 9});
    ActionData::Argument *arg2 = new ActionData::Argument("arg2", {0, 3});

    ad_8bit->add_param(0, arg2);
    ad_16bit->add_param(4, arg1);

    auto merge = ad_16bit->merge(ad_8bit);

    auto pack_info = merge->get_pack_info();
    auto rec_const_level1 = pack_info.get_recursive_constraints();
    EXPECT_EQ(rec_const_level1.size(), 2U);
    EXPECT_EQ(pack_info.get_granularity(), 8);

    auto pack_info2_1 = rec_const_level1[0];
    auto rec_const_level2_1 = pack_info2_1.get_recursive_constraints();

    EXPECT_EQ(rec_const_level2_1.size(), 0U);
    EXPECT_FALSE(pack_info2_1.is_rotational());

    auto pack_info2_2 = rec_const_level1[1];
    auto rec_const_level2_2 = pack_info2_2.get_recursive_constraints();

    EXPECT_EQ(rec_const_level2_2.size(), 0U);
    EXPECT_FALSE(pack_info2_2.is_rotational());
}

/**
 * Validates that the merging of the three examples in the "Action Data Packing Notes" document
 * in the Compilers Google Drive.  After their merge, the PackingConstraints are correct.
 */
TEST(ActionFormatHelper, CrossSizeMerge) {
    int layer_size1 = 8;
    int layer_size2 = 16;
    ActionData::PackingConstraint bit_pc;
    safe_vector<ActionData::PackingConstraint> pc_vec;
    ActionData::PackingConstraint layer_pc1 = bit_pc.expand(1, layer_size1);

    ActionData::PackingConstraint pc_8_bit = layer_pc1.expand(layer_size1, layer_size2);
    ActionData::RamSection *ad_8bit = new ActionData::RamSection(layer_size2, pc_8_bit);

    ActionData::PackingConstraint pc_16_bit = bit_pc.expand(1, layer_size2);
    ActionData::RamSection *ad_16bit = new ActionData::RamSection(layer_size2, pc_16_bit);

    CrossSizeMerge_test1(new ActionData::RamSection(*ad_8bit),
                         new ActionData::RamSection(*ad_16bit));
    CrossSizeMerge_test2(new ActionData::RamSection(*ad_8bit),
                         new ActionData::RamSection(*ad_16bit));
    CrossSizeMerge_test3(new ActionData::RamSection(*ad_8bit),
                         new ActionData::RamSection(*ad_16bit));
}

void RotateIntoRange_test1(ActionData::RamSection *ad, ActionData::Argument *arg) {
    auto rotate1 = ad->rotate_in_range({4, 15});
    BUG_CHECK(rotate1 != nullptr, "Rotation should be allowed");
    ActionData::ParameterPositions param_positions = rotate1->parameter_positions();

    EXPECT_EQ(param_positions.size(), 1U);
    auto param_pos = param_positions.find(4);
    EXPECT_TRUE(param_pos != param_positions.end());
    if (param_pos != param_positions.end()) {
        EXPECT_TRUE(arg->equiv_value(param_pos->second));
    }

    auto rotate2 = ad->rotate_in_range({5, 15});
    BUG_CHECK(rotate2 != nullptr, "Rotation should be allowed");

    param_positions = rotate2->parameter_positions();

    EXPECT_EQ(param_positions.size(), 1U);
    param_pos = param_positions.find(8);
    EXPECT_TRUE(param_pos != param_positions.end());
    if (param_pos != param_positions.end()) {
        EXPECT_TRUE(arg->equiv_value(param_pos->second));
    }

    auto rotate3 = ad->rotate_in_range({5, 10});
    EXPECT_EQ(rotate3, nullptr);
}

TEST(ActionFormatHelper, RotateIntoRange) {
    int first_layer_size = 8;
    safe_vector<ActionData::PackingConstraint> pc_vec;
    for (int i = 0; i < first_layer_size; i++) {
        pc_vec.emplace_back();
    }
    ActionData::PackingConstraint first_pc(1, pc_vec);
    int second_layer_size = 16;
    pc_vec.clear();
    pc_vec.push_back(first_pc);
    pc_vec.emplace_back();
    ActionData::PackingConstraint second_layer_pc(8, pc_vec);

    ActionData::RamSection *ad = new ActionData::RamSection(second_layer_size, second_layer_pc);

    ActionData::Argument *arg1 = new ActionData::Argument("arg1", {0, 3});
    ad->add_param(0, arg1);
    RotateIntoRange_test1(ad, arg1);
}

TEST(ActionFormatHelper, ConstantOverlap) {
    ActionData::PackingConstraint pc;
    pc = pc.expand(1, 8);
    ActionData::RamSection *constant1 = new ActionData::RamSection(8, pc);
    ActionData::RamSection *constant2 = new ActionData::RamSection(8, pc);

    ActionData::Constant *con1 = new ActionData::Constant(0xf0, 8);
    constant1->add_param(0, con1);

    ActionData::Constant *con2 = new ActionData::Constant(0xf, 4);
    constant2->add_param(0, con2);

    safe_vector<ActionData::SharedParameter> shared_params;
    constant1->gather_shared_params(constant2, shared_params, false);
    EXPECT_EQ(shared_params.size(), 1U);
    auto shared_arg = shared_params[0];
    auto con_overlap = shared_arg.param->to<ActionData::Constant>();
    EXPECT_EQ(con_overlap->value().getrange(0, 4), 0xfUL);
    EXPECT_EQ(con_overlap->size(), 4);
    EXPECT_EQ(shared_arg.a_start_bit, 4);
    EXPECT_EQ(shared_arg.b_start_bit, 0);

    ActionData::RamSection *constant3 = new ActionData::RamSection(8, pc);
    ActionData::Constant *con3 = new ActionData::Constant(0x3c, 6);
    constant3->add_param(2, con3);

    shared_params.clear();
    constant1->gather_shared_params(constant3, shared_params, false);
    EXPECT_EQ(shared_params.size(), 1U);
    shared_arg = shared_params[0];
    con_overlap = shared_arg.param->to<ActionData::Constant>();
    EXPECT_EQ(shared_arg.a_start_bit, 2);
    EXPECT_EQ(shared_arg.b_start_bit, 2);
}

TEST(ActionFormatHelper, DataSubset) {
    ActionData::PackingConstraint pc;
    pc = pc.expand(1, 8);
    ActionData::RamSection *ad1 = new ActionData::RamSection(8, pc);
    ActionData::RamSection *ad2 = new ActionData::RamSection(8, pc);

    ActionData::Argument *arg1 = new ActionData::Argument("arg1", {0, 7});
    ActionData::Argument *arg1_mini = new ActionData::Argument ("arg1", {2, 5});
    ad1->add_param(0, arg1);
    ad2->add_param(2, arg1_mini);

    EXPECT_TRUE(ad2->is_data_subset_of(ad1));
    EXPECT_FALSE(ad1->is_data_subset_of(ad2));
}


void Contains_test1(ActionData::RamSection *ad_outside, ActionData::RamSection *ad_inside) {
    ActionData::Argument *arg1 = new ActionData::Argument("arg1", {0, 7});

    ad_outside->add_param(8, arg1);
    ad_inside->add_param(0, arg1);

    int final_bit_pos = 0;
    EXPECT_TRUE(ad_outside->contains(ad_inside, 0, &final_bit_pos));
    EXPECT_EQ(final_bit_pos, 8);
    EXPECT_FALSE(ad_inside->contains(ad_outside, 0, nullptr));
    final_bit_pos = 0;
    EXPECT_TRUE(ad_outside->contains_any_rotation_from_0(ad_inside, 0, &final_bit_pos));
    EXPECT_EQ(final_bit_pos, 8);
}

void Contains_test2(ActionData::RamSection *ad_outside, ActionData::RamSection *ad_inside) {
    ActionData::Argument *arg1 = new ActionData::Argument("arg1", {0, 7});
    ActionData::Argument *arg1_mini1 = new ActionData::Argument("arg1", {0, 3});
    ActionData::Argument *arg1_mini2 = new ActionData::Argument("arg1", {4, 7});

    ad_outside->add_param(8, arg1);
    ad_inside->add_param(0, arg1_mini2);
    ad_inside->add_param(4, arg1_mini1);

    int final_bit_pos = 0;
    EXPECT_TRUE(ad_outside->contains(ad_inside, 0, &final_bit_pos));
    EXPECT_EQ(final_bit_pos, 12);
    final_bit_pos = 16;
    // Try another rotation with a different init_bit
    EXPECT_TRUE(ad_outside->contains(ad_inside, 8, &final_bit_pos));
    final_bit_pos = 0;

    EXPECT_FALSE(ad_inside->contains(ad_outside, 0, nullptr));
    final_bit_pos = 0;
    EXPECT_TRUE(ad_outside->contains_any_rotation_from_0(ad_inside, 0, &final_bit_pos));
    EXPECT_EQ(final_bit_pos, 12);
}

void Contains_test3(ActionData::RamSection *ad_outside, ActionData::RamSection *ad_inside) {
    ActionData::Argument *arg1 = new ActionData::Argument("arg1", {0, 7});

    ad_outside->add_param(8, arg1);
    ad_inside->add_param(4, arg1);

    EXPECT_FALSE(ad_outside->contains(ad_inside, 0, nullptr));
    EXPECT_FALSE(ad_inside->contains(ad_outside, 0, nullptr));
    EXPECT_FALSE(ad_outside->contains_any_rotation_from_0(ad_inside, 0, nullptr));
}

void Contains_test4(ActionData::RamSection *ad_outside, ActionData::RamSection *ad_inside) {
    ActionData::Constant *con1 = new ActionData::Constant(0x55, 8);
    ActionData::Constant *con2 = new ActionData::Constant(0x1, 2);

    ad_outside->add_param(8, con1);
    ad_inside->add_param(0, con2);

    EXPECT_FALSE(ad_outside->contains(ad_inside, 0, nullptr));
    EXPECT_FALSE(ad_inside->contains(ad_outside, 0, nullptr));
    int final_bit_pos = 0;
    EXPECT_TRUE(ad_outside->contains_any_rotation_from_0(ad_inside, 0, &final_bit_pos));
    EXPECT_EQ(final_bit_pos, 8);
}

void Contains_test5(ActionData::RamSection *ad_outside, ActionData::RamSection *ad_inside) {
    ActionData::Constant *con1 = new ActionData::Constant(0x55, 8);
    ActionData::Constant *con2 = new ActionData::Constant(0xfe, 8);

    ad_outside->add_param(8, con1);
    ad_inside->add_param(0, con2);

    EXPECT_FALSE(ad_outside->contains(ad_inside, 0, nullptr));
    EXPECT_FALSE(ad_inside->contains(ad_outside, 0, nullptr));
    EXPECT_FALSE(ad_outside->contains_any_rotation_from_0(ad_inside, 0, nullptr));
}

void Contains_test6(ActionData::RamSection *ad_outside, ActionData::RamSection *ad_inside) {
    ActionData::Constant *con1 = new ActionData::Constant(0x55, 8);
    ActionData::Constant *con2 = new ActionData::Constant(0xaa, 8);

    ad_outside->add_param(8, con1);
    ad_inside->add_param(0, con2);

    EXPECT_FALSE(ad_outside->contains(ad_inside, 0, nullptr));
    EXPECT_FALSE(ad_inside->contains(ad_outside, 0, nullptr));
    int final_bit_pos = 0;
    EXPECT_TRUE(ad_outside->contains_any_rotation_from_0(ad_inside, 0, &final_bit_pos));
    // Multiple possible answers for this, depends on which way the data is rotated
    EXPECT_EQ(final_bit_pos, 9);
}

TEST(ActionFormatHelper, Contains) {
    ActionData::PackingConstraint pc;
    ActionData::PackingConstraint first_layer_pc = pc.expand(1, 8);
    ActionData::PackingConstraint second_layer_pc = first_layer_pc.expand(8, 16);

    ActionData::RamSection ad_outside(16, pc);
    ActionData::RamSection ad_inside(16, second_layer_pc);

    Contains_test1(new ActionData::RamSection(ad_outside), new ActionData::RamSection(ad_inside));
    Contains_test2(new ActionData::RamSection(ad_outside), new ActionData::RamSection(ad_inside));
    Contains_test3(new ActionData::RamSection(ad_outside), new ActionData::RamSection(ad_inside));
    Contains_test4(new ActionData::RamSection(ad_outside), new ActionData::RamSection(ad_inside));
    Contains_test5(new ActionData::RamSection(ad_outside), new ActionData::RamSection(ad_inside));
    Contains_test6(new ActionData::RamSection(ad_outside), new ActionData::RamSection(ad_inside));
}

}  // namespace Test
