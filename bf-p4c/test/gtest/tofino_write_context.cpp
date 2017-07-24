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

#include "ir/ir.h"
#include "tofino/ir/tofino_write_context.h"
#include "test/gtest/helpers.h"

namespace Test {
static IR::Constant *zero = new IR::Constant(0);
static IR::Constant *one = new IR::Constant(1);
static IR::Constant *two = new IR::Constant(2);

class TestRead : public Inspector, TofinoWriteContext {
    bool preorder(const IR::Expression *p) {
        if (findContext<IR::Tofino::ParserState>() ||
           (findContext<IR::MAU::Instruction>() && p == one) ||
           (findContext<IR::MAU::TypedPrimitive>() && p == zero)) {
            EXPECT_TRUE(isRead());
            EXPECT_FALSE(isWrite()); }
        if (findContext<IR::MAU::TypedPrimitive>() && p == two) {
            EXPECT_TRUE(isRead());
            EXPECT_TRUE(isWrite()); }
        return true; }

 public:
    TestRead() { }
};

TEST(TofinoWriteContext, Read) {
    match_t m = match_t(0, 0, 0);

    auto *match = new IR::Tofino::ParserMatch(m, {});
    auto *state = new IR::Tofino::ParserState("foo", INGRESS, {zero, one}, {match});

    state->apply(TestRead());

    auto prim = new IR::MAU::TypedPrimitive("foo_prim");
    prim->operands = IR::Vector<IR::Expression>({zero, one, two});
    prim->method_type =
      new IR::Type_Method(
        new IR::ParameterList(
          IR::IndexedVector<IR::Parameter>({
            new IR::Parameter(IR::ID("zero"), IR::Direction::In, new IR::Type_Bits(8, false)),
            new IR::Parameter(IR::ID("one"), IR::Direction::Out, new IR::Type_Bits(8, false)),
            new IR::Parameter(IR::ID("two"), IR::Direction::InOut, new IR::Type_Bits(8, false))})));
    prim->apply(TestRead());

    auto *inst = new IR::MAU::Instruction("foo_inst");
    inst->operands = IR::Vector<IR::Expression>({zero, one});
    inst->apply(TestRead());
}

class TestWrite : public Inspector, TofinoWriteContext {
    bool preorder(const IR::Expression *p) {
        if ((findContext<IR::MAU::SaluAction>() && p == one) ||
           (findContext<IR::MAU::Instruction>() && p == zero) ||
           (findContext<IR::MAU::TypedPrimitive>() && p == one)) {
            EXPECT_FALSE(isRead());
            EXPECT_TRUE(isWrite()); }
        if (findContext<IR::MAU::TypedPrimitive>() && p == two) {
            EXPECT_TRUE(isRead());
            EXPECT_TRUE(isWrite()); }
        return true; }

 public:
    TestWrite() { }
};

TEST(TofinoWriteContext, Write) {
    auto *salu = new IR::MAU::SaluAction(IR::ID("foo"));
    salu->output_dst = one;

    salu->apply(TestWrite());

    auto prim = new IR::MAU::TypedPrimitive("foo_prim");
    prim->operands = IR::Vector<IR::Expression>({zero, one, two});
    prim->method_type =
      new IR::Type_Method(
        new IR::ParameterList(
          IR::IndexedVector<IR::Parameter>({
            new IR::Parameter(IR::ID("zero"), IR::Direction::In, new IR::Type_Bits(8, false)),
            new IR::Parameter(IR::ID("one"), IR::Direction::Out, new IR::Type_Bits(8, false)),
            new IR::Parameter(IR::ID("two"), IR::Direction::InOut, new IR::Type_Bits(8, false))})));
    prim->apply(TestWrite());

    auto *inst = new IR::MAU::Instruction("foo_inst");
    inst->operands = IR::Vector<IR::Expression>({zero, one});
    inst->apply(TestWrite());
}


}  // namespace Test
