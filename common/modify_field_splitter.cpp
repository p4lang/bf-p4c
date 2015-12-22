#include "modify_field_splitter.h"
#include <iostream>
const IR::Node *
ModifyFieldSplitter::preorder(IR::Primitive *primitive) {
  // This if-block normalize modify_field primitives.
  // We want each modify_field primitive to have the following format:
  // Specify a mask
  // Operate on at most 8b wide operands
  // Operate on src and dst of the same width
  if (primitive->name == "modify_field" &&
      (primitive->operands.size() != 3 ||
       primitive->operands[0]->type->width_bits() > 8 ||
       primitive->operands[0]->type->width_bits() !=
       primitive->operands[1]->type->width_bits())) {
    auto rv = new IR::Vector<IR::Primitive>;
    int offset = 0;
    int width = std::min(primitive->operands[0]->type->width_bits(),
                         primitive->operands[1]->type->width_bits());
    IR::Constant mask = IR::Constant::GetMask(width);
    if (primitive->operands.size() == 3) {
      mask.value =
        dynamic_cast<const IR::Constant*>(primitive->operands[2])->value;
    }
    while ((width - offset) > 0) {
      // The new modify_field primitive will operate on cur_width bit fields.
      auto cur_width = std::min(8, width - offset);
      auto cur_width_mask = IR::Constant::GetMask(cur_width);
      IR::Constant new_mask = (mask >> offset) & cur_width_mask;
      const IR::Expression *dst_operand = primitive->operands[0];
      auto dst_fragment_ref =
        dynamic_cast<const IR::FragmentRef*>(primitive->operands[0]);
      assert(dst_fragment_ref != nullptr);
      dst_operand = new IR::FragmentRef(
                      dst_fragment_ref->srcInfo, dst_fragment_ref->base,
                      offset + dst_fragment_ref->offset_bits(),
                      cur_width);
      // The source operand can be of 3 types.
      const IR::Expression *src_operand = primitive->operands[1];
      if (auto src_fragment_ref =
            dynamic_cast<const IR::FragmentRef*>(src_operand)) {
        src_operand = new IR::FragmentRef(
                        src_fragment_ref->srcInfo, src_fragment_ref->base,
                        offset + src_fragment_ref->offset_bits(),
                        cur_width);
      } else if (auto src_constant = dynamic_cast<const IR::Constant*>(src_operand)) {
        src_operand = new IR::Constant(src_constant->srcInfo,
                                       IR::Type::Bits::get(primitive->srcInfo, cur_width),
                                       (((*src_constant) >> offset) &
                                         cur_width_mask).value);
      } else {
        auto src_action_arg = dynamic_cast<const IR::ActionArg*>(src_operand);
        assert(nullptr != src_action_arg);
        src_operand = new IR::Slice(src_action_arg->srcInfo,
                                    IR::Type_Bits::get(src_action_arg->srcInfo,
                                                       cur_width),
                                    src_action_arg,
                                    new IR::Constant(offset + cur_width),
                                    new IR::Constant(offset));
      }
      // Create the new modify_field primitive.
      rv->push_back(
        new IR::Primitive(primitive->srcInfo, "modify_field", dst_operand,
                          src_operand, new IR::Constant(new_mask.value)));
      offset += cur_width;
    }

    // Return a vector of modify_field primitives.
    return rv;
  }

  return primitive;
}
