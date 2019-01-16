#include "bf-p4c/mau/action_format_2.h"
#include "lib/log.h"
#include "gtest/gtest.h"

namespace Test {

void BasicRotation_test1(ActionDataRamSection *ad, Argument *arg) {
    auto rotate1 = ad->can_rotate(0, 4);
    BUG_CHECK(rotate1 != nullptr, "Rotation should be possible");

    ActionDataPositions ad_positions = rotate1->action_data_positions();

    EXPECT_EQ(ad_positions.size(), 1);
    auto ad_pos = ad_positions.find(4);
    EXPECT_TRUE(ad_pos != ad_positions.end());
    if (ad_pos != ad_positions.end()) {
        EXPECT_TRUE(arg->equiv_value(ad_pos->second));
    }

    auto right_rotate1 = rotate1->can_rotate(4, 2);
    ad_positions = right_rotate1->action_data_positions();
    EXPECT_EQ(ad_positions.size(), 1);
    ad_pos = ad_positions.find(2);
    EXPECT_TRUE(ad_pos != ad_positions.end());
    if (ad_pos != ad_positions.end()) {
        EXPECT_TRUE(arg->equiv_value(ad_pos->second));
    }
}

void BasicRotation_test2(ActionDataRamSection *ad, Argument *arg) {
    auto rotate2 = ad->can_rotate(0, 6);
    BUG_CHECK(rotate2 != nullptr, "Rotation should be possible");

    ActionDataPositions ad_positions = rotate2->action_data_positions();
    EXPECT_EQ(ad_positions.size(), 2);
    auto ad_pos = ad_positions.find(0);
    EXPECT_TRUE(ad_pos != ad_positions.end());
    if (ad_pos != ad_positions.end()) {
        EXPECT_TRUE(arg->split(2, 3)->equiv_value(ad_pos->second));
    }

    ad_pos = ad_positions.find(6);
    EXPECT_TRUE(ad_pos != ad_positions.end());
    if (ad_pos != ad_positions.end()) {
        EXPECT_TRUE(arg->split(0, 1)->equiv_value(ad_pos->second));
    }
}

/**
 * Guarantee that the can_rotate function can work on a single level
 */
TEST(ActionFormatHelper, BasicRotation) {
    int basic_size = 8;
    safe_vector<PackingConstraint> pc_vec;
    for (int i = 0; i < 8; i++) {
        pc_vec.emplace_back();
    }
    PackingConstraint pc(1, pc_vec);
    ActionDataRamSection *ad = new ActionDataRamSection(basic_size, pc);
    Argument *arg = new Argument("arg1", {0, 3});
    ad->add_param(0, arg);
    BasicRotation_test1(ad, arg);
    BasicRotation_test2(ad, arg);
}

void LayeredRotation_test1(ActionDataRamSection *ad, Argument *arg1, Argument *arg2,
        Argument *arg3) {
    auto byte_rotate = ad->can_rotate(8, 0);
    BUG_CHECK(byte_rotate != nullptr, "Rotation should be possible");
    ActionDataPositions ad_positions = byte_rotate->action_data_positions();

    EXPECT_EQ(ad_positions.size(), 3);
    auto ad_pos = ad_positions.find(0);
    EXPECT_TRUE(ad_pos != ad_positions.end());
    if (ad_pos != ad_positions.end()) {
        EXPECT_TRUE(arg3->equiv_value(ad_pos->second));
    }

    ad_pos = ad_positions.find(8);
    EXPECT_TRUE(ad_pos != ad_positions.end());
    if (ad_pos != ad_positions.end()) {
        EXPECT_TRUE(arg1->equiv_value(ad_pos->second));
    }

    ad_pos = ad_positions.find(12);
    EXPECT_TRUE(ad_pos != ad_positions.end());
    if (ad_pos != ad_positions.end()) {
        EXPECT_TRUE(arg2->equiv_value(ad_pos->second));
    }
}

void LayeredRotation_test2(ActionDataRamSection *ad, Argument *arg1, Argument *arg2,
        Argument *arg3) {
    auto bit_rotate1 = ad->can_rotate(0, 12);
    BUG_CHECK(bit_rotate1 != nullptr, "Rotation should be possible");
    ActionDataPositions ad_positions = bit_rotate1->action_data_positions();

    EXPECT_EQ(ad_positions.size(), 3);
    auto ad_pos = ad_positions.find(0);
    EXPECT_TRUE(ad_pos != ad_positions.end());
    if (ad_pos != ad_positions.end()) {
        EXPECT_TRUE(arg3->equiv_value(ad_pos->second));
    }

    ad_pos = ad_positions.find(8);
    EXPECT_TRUE(ad_pos != ad_positions.end());
    if (ad_pos != ad_positions.end()) {
        EXPECT_TRUE(arg2->equiv_value(ad_pos->second));
    }

    ad_pos = ad_positions.find(12);
    EXPECT_TRUE(ad_pos != ad_positions.end());
    if (ad_pos != ad_positions.end()) {
        EXPECT_TRUE(arg1->equiv_value(ad_pos->second));
    }

    auto bit_rotate2 = ad->can_rotate(12, 0);
    EXPECT_EQ(bit_rotate2, nullptr);
}


/**
 * Verifies that the can_rotate function can work through multiple levels of RecursiveConstraints
 */
TEST(ActionFormatHelper, LayeredRotation) {
    int first_layer_size = 8;
    safe_vector<PackingConstraint> pc_vec;
    for (int i = 0; i < first_layer_size; i++) {
        pc_vec.emplace_back();
    }
    PackingConstraint first_pc(1, pc_vec);
    int second_layer_size = 16;
    pc_vec.clear();
    pc_vec.push_back(first_pc);
    pc_vec.emplace_back();
    PackingConstraint second_layer_pc(8, pc_vec);

    ActionDataRamSection *ad = new ActionDataRamSection(second_layer_size, second_layer_pc);

    Argument *arg1 = new Argument("arg1", {0, 3});
    Argument *arg2 = new Argument("arg2", {0, 3});
    Argument *arg3 = new Argument("arg3", {0, 7});

    ad->add_param(0, arg1);
    ad->add_param(4, arg2);
    ad->add_param(8, arg3);
    LayeredRotation_test1(ad, arg1, arg2, arg3);
    LayeredRotation_test2(ad, arg1, arg2, arg3);
}

void SimpleMerge_test1(ActionDataRamSection *ad1, ActionDataRamSection *ad2) {
    Argument *arg1 = new Argument("arg1", {0, 3});
    Argument *arg2 = new Argument("arg2", {0, 3});

    ad1->add_param(0, arg1);
    ad2->add_param(4, arg2);
    auto merge = ad1->merge(ad2);
    auto pack_info = merge->get_pack_info();
    auto rec_const = pack_info.get_recursive_constraints();

    EXPECT_EQ(rec_const.size(), 8);
    EXPECT_EQ(pack_info.get_granularity(), 1);
}

TEST(ActionFormatHelper, SimpleMerge) {
    int basic_size = 8;
    safe_vector<PackingConstraint> pc_vec;
    for (int i = 0; i < 8; i++) {
        pc_vec.emplace_back();
    }
    PackingConstraint pc(1, pc_vec);
    ActionDataRamSection *ad1 = new ActionDataRamSection(basic_size, pc);
    ActionDataRamSection *ad2 = new ActionDataRamSection(basic_size, pc);
    SimpleMerge_test1(ad1, ad2);
}

void OverlapMerge_test1(ActionDataRamSection *ad1, ActionDataRamSection *ad2) {
    Argument *arg1 = new Argument("arg1", {0, 5});
    Argument *arg2 = new Argument("arg1", {2, 7});

    ad1->add_param(0, arg1);
    ad2->add_param(2, arg2);
    auto merge = ad1->merge(ad2);

    auto pack_info = merge->get_pack_info();
    auto rec_const = pack_info.get_recursive_constraints();

    EXPECT_EQ(rec_const.size(), 8);
    EXPECT_EQ(pack_info.get_granularity(), 1);
}


TEST(ActionFormatHelper, OverlapMerge) {
    int basic_size = 8;
    safe_vector<PackingConstraint> pc_vec;
    for (int i = 0; i < 8; i++) {
        pc_vec.emplace_back();
    }
    PackingConstraint pc(1, pc_vec);
    ActionDataRamSection *ad1 = new ActionDataRamSection(basic_size, pc);
    ActionDataRamSection *ad2 = new ActionDataRamSection(basic_size, pc);
    OverlapMerge_test1(ad1, ad2);
}

void CrossSizeMerge_test1(ActionDataRamSection *ad_8bit, ActionDataRamSection *ad_16bit) {
    Argument *arg1 = new Argument("arg1", {0, 7});
    Argument *arg2 = new Argument("arg2", {0, 7});

    ad_16bit->add_param(8, arg1);
    ad_8bit->add_param(0, arg2);
    auto merge = ad_16bit->merge(ad_8bit);

    auto pack_info = merge->get_pack_info();
    auto rec_const_level1 = pack_info.get_recursive_constraints();
    EXPECT_EQ(rec_const_level1.size(), 2);
    EXPECT_EQ(pack_info.get_granularity(), 8);

    auto pack_info2_1 = rec_const_level1[0];
    auto rec_const_level2_1 = pack_info2_1.get_recursive_constraints();

    EXPECT_EQ(rec_const_level2_1.size(), 8);
    EXPECT_EQ(pack_info2_1.get_granularity(), 1);

    auto pack_info3_1 = rec_const_level2_1[0];
    auto rec_const_level3_1 = pack_info3_1.get_recursive_constraints();

    EXPECT_EQ(rec_const_level3_1.size(), 0);
    EXPECT_EQ(pack_info3_1.get_granularity(), -1);

    auto pack_info2_2 = rec_const_level1[1];
    auto rec_const_level2_2 = pack_info2_2.get_recursive_constraints();

    EXPECT_EQ(rec_const_level2_2.size(), 0);
    EXPECT_EQ(pack_info2_2.get_granularity(), -1);
}

void CrossSizeMerge_test2(ActionDataRamSection *ad_8bit, ActionDataRamSection *ad_16bit) {
    Argument *arg1 = new Argument("arg1", {0, 5});
    Argument *arg2 = new Argument("arg2", {0, 5});

    ad_8bit->add_param(0, arg1);
    ad_16bit->add_param(6, arg2);
    auto merge = ad_16bit->merge(ad_8bit);

    auto pack_info = merge->get_pack_info();
    auto rec_const_level1 = pack_info.get_recursive_constraints();
    EXPECT_EQ(rec_const_level1.size(), 2);
    EXPECT_EQ(pack_info.get_granularity(), 8);

    auto pack_info2_1 = rec_const_level1[0];
    auto rec_const_level2_1 = pack_info2_1.get_recursive_constraints();

    EXPECT_EQ(rec_const_level2_1.size(), 0);
    EXPECT_FALSE(pack_info2_1.is_rotational());

    auto pack_info2_2 = rec_const_level1[1];
    auto rec_const_level2_2 = pack_info2_2.get_recursive_constraints();

    EXPECT_EQ(rec_const_level2_2.size(), 0);
    EXPECT_FALSE(pack_info2_2.is_rotational());
}

void CrossSizeMerge_test3(ActionDataRamSection *ad_8bit, ActionDataRamSection *ad_16bit) {
    Argument *arg1 = new Argument("arg1", {0, 9});
    Argument *arg2 = new Argument("arg2", {0, 3});

    ad_8bit->add_param(0, arg2);
    ad_16bit->add_param(4, arg1);

    auto merge = ad_16bit->merge(ad_8bit);

    auto pack_info = merge->get_pack_info();
    auto rec_const_level1 = pack_info.get_recursive_constraints();
    EXPECT_EQ(rec_const_level1.size(), 2);
    EXPECT_EQ(pack_info.get_granularity(), 8);

    auto pack_info2_1 = rec_const_level1[0];
    auto rec_const_level2_1 = pack_info2_1.get_recursive_constraints();

    EXPECT_EQ(rec_const_level2_1.size(), 0);
    EXPECT_FALSE(pack_info2_1.is_rotational());

    auto pack_info2_2 = rec_const_level1[1];
    auto rec_const_level2_2 = pack_info2_2.get_recursive_constraints();

    EXPECT_EQ(rec_const_level2_2.size(), 0);
    EXPECT_FALSE(pack_info2_2.is_rotational());
}

/**
 * Validates that the merging of the three examples in the "Action Data Packing Notes" document
 * in the Compilers Google Drive.  After their merge, the PackingConstraints are correct.
 */
TEST(ActionFormatHelper, CrossSizeMerge) {
    int layer_size1 = 8;
    int layer_size2 = 16;
    PackingConstraint bit_pc;
    safe_vector<PackingConstraint> pc_vec;
    PackingConstraint layer_pc1 = bit_pc.expand(1, layer_size1);

    PackingConstraint pc_8_bit = layer_pc1.expand(layer_size1, layer_size2);
    ActionDataRamSection *ad_8bit = new ActionDataRamSection(layer_size2, pc_8_bit);

    PackingConstraint pc_16_bit = bit_pc.expand(1, layer_size2);
    ActionDataRamSection *ad_16bit = new ActionDataRamSection(layer_size2, pc_16_bit);

    CrossSizeMerge_test1(new ActionDataRamSection(*ad_8bit),
                         new ActionDataRamSection(*ad_16bit));
    CrossSizeMerge_test2(new ActionDataRamSection(*ad_8bit),
                         new ActionDataRamSection(*ad_16bit));
    CrossSizeMerge_test3(new ActionDataRamSection(*ad_8bit),
                         new ActionDataRamSection(*ad_16bit));
}

void RotateIntoRange_test1(ActionDataRamSection *ad, Argument *arg) {
    auto rotate1 = ad->rotate_in_range({4, 15});
    BUG_CHECK(rotate1 != nullptr, "Rotation should be allowed");
    ActionDataPositions ad_positions = rotate1->action_data_positions();

    EXPECT_EQ(ad_positions.size(), 1);
    auto ad_pos = ad_positions.find(4);
    EXPECT_TRUE(ad_pos != ad_positions.end());
    if (ad_pos != ad_positions.end()) {
        EXPECT_TRUE(arg->equiv_value(ad_pos->second));
    }

    auto rotate2 = ad->rotate_in_range({5, 15});
    BUG_CHECK(rotate2 != nullptr, "Rotation should be allowed");

    ad_positions = rotate2->action_data_positions();

    EXPECT_EQ(ad_positions.size(), 1);
    ad_pos = ad_positions.find(8);
    EXPECT_TRUE(ad_pos != ad_positions.end());
    if (ad_pos != ad_positions.end()) {
        EXPECT_TRUE(arg->equiv_value(ad_pos->second));
    }

    auto rotate3 = ad->rotate_in_range({5, 10});
    EXPECT_EQ(rotate3, nullptr);
}

TEST(ActionFormatHelper, RotateIntoRange) {
    int first_layer_size = 8;
    safe_vector<PackingConstraint> pc_vec;
    for (int i = 0; i < first_layer_size; i++) {
        pc_vec.emplace_back();
    }
    PackingConstraint first_pc(1, pc_vec);
    int second_layer_size = 16;
    pc_vec.clear();
    pc_vec.push_back(first_pc);
    pc_vec.emplace_back();
    PackingConstraint second_layer_pc(8, pc_vec);

    ActionDataRamSection *ad = new ActionDataRamSection(second_layer_size, second_layer_pc);

    Argument *arg1 = new Argument("arg1", {0, 3});
    ad->add_param(0, arg1);
    RotateIntoRange_test1(ad, arg1);
}

}  // namespace Test
