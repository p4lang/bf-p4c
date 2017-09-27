#include "gtest/gtest.h"

#include "ir/ir.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "test/gtest/helpers.h"

namespace Test {
static IR::Constant *zero = new IR::Constant(0);
static IR::Constant *one = new IR::Constant(1);
static IR::Constant *two = new IR::Constant(2);

class TestRead : public Inspector, TofinoWriteContext {
    bool preorder(const IR::Expression *p) {
        if (findContext<IR::BFN::ParserState>() ||
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

    auto *match = new IR::BFN::ParserMatch(m, 0, {
        new IR::BFN::ExtractBuffer(zero, 0, 1),
        new IR::BFN::ExtractBuffer(one, 1, 2),
        new IR::BFN::ExtractComputed(zero, zero),
        new IR::BFN::ExtractComputed(one, one)
    });
    auto *state = new IR::BFN::ParserState("foo", INGRESS, {
        new IR::BFN::SelectComputed(zero),
        new IR::BFN::SelectComputed(one)
    }, {match});

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

TEST(TofinoWriteContext, DeparserEmit) {
    auto* header = new IR::Header("foo", new IR::Type_Header("foo_t"));
    auto* field = new IR::Member(new IR::ConcreteHeaderRef(header), "bar");
    auto* povBit = new IR::Member(new IR::ConcreteHeaderRef(header), "$valid");

    auto* deparserControlType = new IR::Type_Control("dp", new IR::ParameterList);
    auto* deparserControl =
      new IR::P4Control("dp", deparserControlType, new IR::BlockStatement);
    auto* deparser = new IR::BFN::Deparser(INGRESS, deparserControl);
    deparser->emits.push_back(new IR::BFN::Emit(field, povBit));

    struct CheckEmit : public Inspector, TofinoWriteContext {
        bool preorder(const IR::Member*) override {
            EXPECT_TRUE(isRead());
            EXPECT_FALSE(isWrite());
            return true;
        }
    };
    deparser->apply(CheckEmit());
}

TEST(TofinoWriteContext, DeparserEmitChecksum) {
    auto* header = new IR::Header("foo", new IR::Type_Header("foo_t"));
    auto* field = new IR::Member(new IR::ConcreteHeaderRef(header), "bar");
    auto* povBit = new IR::Member(new IR::ConcreteHeaderRef(header), "$valid");

    auto* deparserControlType = new IR::Type_Control("dp", new IR::ParameterList);
    auto* deparserControl =
      new IR::P4Control("dp", deparserControlType, new IR::BlockStatement);
    auto* deparser = new IR::BFN::Deparser(INGRESS, deparserControl);
    deparser->emits.push_back(new IR::BFN::EmitChecksum({ field }, povBit));

    struct CheckEmitChecksum : public Inspector, TofinoWriteContext {
        bool preorder(const IR::Member*) override {
            EXPECT_TRUE(isRead());
            EXPECT_FALSE(isWrite());
            return true;
        }
    };
    deparser->apply(CheckEmitChecksum());
}

}  // namespace Test
