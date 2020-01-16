#include "gtest/gtest.h"

#include "ir/ir.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "test/gtest/helpers.h"

namespace Test {

namespace {

static IR::Constant *zero = new IR::Constant(0);
static IR::Constant *one = new IR::Constant(1);
static IR::Constant *two = new IR::Constant(2);
static IR::This *thisVal = new IR::This();

class TestRead : public Inspector, TofinoWriteContext {
    bool preorder(const IR::Expression *p) {
        if (findContext<IR::BFN::Select>()) {
            EXPECT_TRUE(isRead());
            EXPECT_FALSE(isWrite());
            return true; }
        if ((findContext<IR::MAU::Instruction>() && p == one) ||
            (findContext<IR::MAU::TypedPrimitive>() && p == zero)) {
            EXPECT_TRUE(isRead());
            EXPECT_FALSE(isWrite());
            return true; }
        if (findContext<IR::MAU::TypedPrimitive>() && p == two) {
            EXPECT_TRUE(isRead());
            EXPECT_TRUE(isWrite());
            return true; }
        return true; }

 public:
    TestRead() { }
};

}  // namespace

TEST(TofinoWriteContext, Read) {
    auto* zeroLVal = new IR::Member(zero, "zero");
    auto* oneLVal = new IR::Member(one, "one");

    IR::Vector<IR::BFN::ParserPrimitive> statements = {
        new IR::BFN::Extract(zeroLVal, new IR::BFN::PacketRVal(StartLen(0, 1))),
        new IR::BFN::Extract(oneLVal, new IR::BFN::PacketRVal(StartLen(1, 2))),
        new IR::BFN::Extract(zeroLVal, new IR::BFN::MetadataRVal(StartLen(256, 1)))
    };
    auto *state = new IR::BFN::ParserState("foo", INGRESS, statements, { }, { });

    state->apply(TestRead());

    auto prim = new IR::MAU::TypedPrimitive("foo_prim");
    prim->operands = IR::Vector<IR::Expression>({thisVal, zero, one, two});
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
    prim->operands = IR::Vector<IR::Expression>({thisVal, zero, one, two});
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

    auto* deparser = new IR::BFN::Deparser(EGRESS);
    deparser->emits.push_back(new IR::BFN::EmitField(field, povBit));

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
    auto* csum = new IR::Member(new IR::ConcreteHeaderRef(header), "csum");
    auto* povBit = new IR::Member(new IR::ConcreteHeaderRef(header), "$valid");

    auto* deparser = new IR::BFN::Deparser(EGRESS);
    deparser->emits.push_back(new IR::BFN::EmitChecksum(
          new IR::BFN::FieldLVal(povBit),
        { new IR::BFN::ChecksumEntry(new IR::BFN::FieldLVal(field),
                                     new IR::BFN::FieldLVal(povBit),
                                     field->type->width_bits())},
          new IR::BFN::ChecksumLVal(csum)));

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
