#include <sstream>

#include "gtest/gtest.h"

#include "bf-p4c/ir/gress.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/mau/action_analysis.h"

#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

// Tests in this class are intended to test the correctness of the container action
// part of ActionAnalysis. Namely, given a PHV allocation for all the fields in
// an Action (including all destinations and source operands), is it possible to
// synthesize ALU instructions for it? Or in other words, is the PHV allocation
// correct to be implemented as ALU instructions?

class ContainerAction: public TofinoBackendTest {
 protected:
    ContainerAction() {
        tbl = new IR::MAU::Table("test", INGRESS);
        act = new IR::MAU::Action("act");
        tbl->actions["act"] = act;
    }

    PhvInfo phv;
    IR::MAU::Table* tbl;
    IR::MAU::Action* act;
};

void add_set(IR::MAU::Action* act,
                const PHV::Field* dst,
                const PHV::Field* src) {
    auto set = new IR::MAU::Instruction("set");

    set->operands.push_back(
        new IR::TempVar(IR::Type::Bits::get(dst->size), false, dst->name));
    set->operands.push_back(
        new IR::TempVar(IR::Type::Bits::get(src->size), false, src->name));

    act->action.push_back(set);
}

void add_set(IR::MAU::Action* act,
                const PHV::Field* dst,
                unsigned src) {
    auto set = new IR::MAU::Instruction("set");

    set->operands.push_back(
        new IR::TempVar(IR::Type::Bits::get(dst->size), false, dst->name));
    set->operands.push_back(
        new IR::Constant(IR::Type::Bits::get(dst->size), src));

    act->action.push_back(set);
}

void add_set(IR::MAU::Action* act,
                const PHV::Field* dst,
                cstring param) {
    auto set = new IR::MAU::Instruction("set");

    set->operands.push_back(
        new IR::TempVar(IR::Type::Bits::get(dst->size), false, dst->name));
    set->operands.push_back(
        new IR::MAU::ActionArg(IR::Type::Bits::get(dst->size), "act", param));

    act->action.push_back(set);
}

void add_op(IR::MAU::Action* act,
            const PHV::Field* dst,
            cstring op,
            const PHV::Field* src1,
            const PHV::Field* src2) {
    auto instr = new IR::MAU::Instruction(op);

    instr->operands.push_back(
        new IR::TempVar(IR::Type::Bits::get(dst->size), false, dst->name));
    instr->operands.push_back(
        new IR::TempVar(IR::Type::Bits::get(src1->size), false, src1->name));
    instr->operands.push_back(
        new IR::TempVar(IR::Type::Bits::get(src2->size), false, src2->name));

    act->action.push_back(instr);
}

void add_op(IR::MAU::Action* act,
            const PHV::Field* dst,
            cstring op,
            const PHV::Field* src1,
            cstring src2) {
    auto instr = new IR::MAU::Instruction(op);

    instr->operands.push_back(
        new IR::TempVar(IR::Type::Bits::get(dst->size), false, dst->name));
    instr->operands.push_back(
        new IR::TempVar(IR::Type::Bits::get(src1->size), false, src1->name));
    instr->operands.push_back(
        new IR::MAU::ActionArg(IR::Type::Bits::get(dst->size), "act", src2));

    act->action.push_back(instr);
}

struct Result {
    bool warn = false, error = false;
    Result(bool w, bool e) : warn(w), error(e) {}
};

Result analyze_container_actions(const IR::MAU::Table* tbl, const PhvInfo& phv) {
    ActionAnalysis aa(phv, true, false, tbl);

    ActionAnalysis::ContainerActionsMap container_actions_map;
    aa.set_container_actions_map(&container_actions_map);
    aa.set_error_verbose();
    aa.set_verbose();

    tbl->apply(aa);

    return Result(aa.warning_found(), aa.error_found());
}

#define FIELD(field, size)                                \
    field = phv.add(#field, INGRESS, size, 0, true, false);

#define ALLOC(field, container, field_lo, container_lo, width)                             \
    field->add_alloc(PHV::AllocSlice(field, container, field_lo, container_lo, width));    \
    phv.add_container_to_field_entry(container, field);

#define OK                                           \
    auto rv = analyze_container_actions(tbl, phv);   \
    ASSERT_FALSE(rv.error);

#define NOK                                          \
    auto rv = analyze_container_actions(tbl, phv);   \
    ASSERT_TRUE(rv.error);

TEST_F(ContainerAction, sanity) {
    PHV::Field *f1, *f2;

    FIELD(f1, 8);
    FIELD(f2, 8);

    ALLOC(f1, "B0", 0, 0, 8);
    ALLOC(f2, "B2", 0, 0, 8);

    add_set(act, f1, f2);

    OK;
}

// The following two tests are extracted from P4C-2761. Whether we can correctly synthesize
// instructions for the action depends on the allocation of f4.

class P4C_2761 : public ContainerAction {
 protected:
    void SetUp() override {
        FIELD(f1, 8);
        FIELD(f2, 8);
        FIELD(f3, 16);
        FIELD(f4, 8);
        FIELD(f5, 8);

        ALLOC(f1, "W1", 0, 0, 8);
        ALLOC(f2, "W1", 0, 8, 8);
        ALLOC(f3, "W1", 0, 16, 16);
        ALLOC(f5, "W0", 0, 16, 8);

        add_set(act, f1, f4);
        add_set(act, f2, f5);
        add_set(act, f3, 0xbabe);
    }

    PHV::Field *f1, *f2, *f3, *f4, *f5;
};

TEST_F(P4C_2761, test1) {
    ALLOC(f4, "W0", 0, 0, 8);

    NOK;
}

TEST_F(P4C_2761, test2) {
    ALLOC(f4, "W0", 0, 8, 8);

    OK;
}

// The following tests are lifted directly from Evan's MAU onboarding slides.
// see slide 55 and onwards from link below:
// https://intel.sharepoint.com/:p:/r/sites/BXD/_layouts/15/Doc.aspx?sourcedoc=%7B81E2FE32-6FDA-4A39-872E-FCE2329561EB%7D&file=Day4a-Evan-MAU-Introduction.pptx&action=edit&mobileredirect=true

class SlidesExamples : public ContainerAction {
 protected:
    void SetUp() override {
        FIELD(f1, 2);
        FIELD(f2, 2);
        FIELD(f3, 2);
        FIELD(f4, 2);
        FIELD(f5, 2);
        FIELD(f6, 2);
        FIELD(f7, 2);
        FIELD(f8, 2);
        FIELD(f9, 2);
        FIELD(fa, 2);
        FIELD(fb, 2);
        FIELD(fc, 2);

        ALLOC(f1, "B0", 0, 0, 2);
        ALLOC(f2, "B0", 0, 2, 2);
        ALLOC(f3, "B0", 0, 4, 2);
        ALLOC(f4, "B0", 0, 6, 2);
        ALLOC(f5, "B1", 0, 0, 2);
        ALLOC(f6, "B1", 0, 2, 2);
        ALLOC(f7, "B1", 0, 4, 2);
        ALLOC(f8, "B1", 0, 6, 2);
        ALLOC(f9, "B2", 0, 0, 2);
        ALLOC(fa, "B2", 0, 2, 2);
        ALLOC(fb, "B2", 0, 4, 2);
        ALLOC(fc, "B2", 0, 6, 2);
    }

    PHV::Field *f1, *f2, *f3, *f4, *f5, *f6, *f7, *f8, *f9, *fa, *fb, *fc;
};

TEST_F(SlidesExamples, a1) {
    add_set(act, f1, f5);

    OK;
}

TEST_F(SlidesExamples, a2) {
    add_set(act, f1, f8);

    OK;
}

TEST_F(SlidesExamples, a3) {
    add_set(act, f1, f5);
    add_set(act, f2, fa);

    NOK;
}

TEST_F(SlidesExamples, a4) {
    add_set(act, f1, f5);
    add_set(act, f2, fa);
    add_set(act, f3, fb);
    add_set(act, f4, fc);

    OK;
}

TEST_F(SlidesExamples, a5) {
    add_set(act, f1, f5);
    add_set(act, f2, f6);
    add_set(act, f3, f9);
    add_set(act, f4, fa);

    OK;
}

TEST_F(SlidesExamples, a6) {
    add_set(act, f1, f5);
    add_set(act, f2, f6);
    add_set(act, f3, fc);
    add_set(act, f4, f9);

    OK;
}

TEST_F(SlidesExamples, a7) {
    add_set(act, f1, f7);
    add_set(act, f2, f8);
    add_set(act, f3, f9);
    add_set(act, f4, fa);

    NOK;
}

TEST_F(SlidesExamples, a8) {
    add_set(act, f1, f5);
    add_set(act, f2, fa);
    add_set(act, f3, f7);
    add_set(act, f4, fc);

    NOK;
}

TEST_F(SlidesExamples, a9) {
    add_set(act, f1, f5);
    add_set(act, f2, fa);
    add_set(act, f3, f7);
    add_set(act, f4, f8);

    OK;
}

TEST_F(SlidesExamples, a10) {
    add_set(act, f1, f5);
    add_set(act, f2, f6);
    add_set(act, f4, f8);

    OK;
}

TEST_F(SlidesExamples, a11) {
    add_set(act, f1, f6);
    add_set(act, f2, f7);
    add_set(act, f4, f5);

    NOK;
}

TEST_F(SlidesExamples, a12) {
    add_set(act, f1, f5);
    add_set(act, f2, f5);
    add_set(act, f3, f7);
    add_set(act, f4, f8);

    OK;
}

TEST_F(SlidesExamples, b1) {
    add_set(act, f1, "param1");

    OK;
}

TEST_F(SlidesExamples, b2) {
    add_set(act, f1, "param1");
    add_set(act, f2, "param2");

    OK;
}

TEST_F(SlidesExamples, b3) {
    add_set(act, f1, "param1");
    add_set(act, f2, "param2");
    add_set(act, f3, f7);
    add_set(act, f4, f8);

    OK;
}

TEST_F(SlidesExamples, b4) {
    add_set(act, f1, "param1");
    add_set(act, f2, "param2");
    add_set(act, f3, f5);
    add_set(act, f4, f6);

    NOK;
}

TEST_F(SlidesExamples, b5) {
    add_set(act, f1, "param1");
    add_set(act, f3, "param2");

    OK;
}

TEST_F(SlidesExamples, b6) {
    add_set(act, f1, "param1");
    add_set(act, f2, f6);
    add_set(act, f3, "param2");
    add_set(act, f4, f8);

    OK;
}

TEST_F(SlidesExamples, b7) {
    add_set(act, f1, "param1");
    add_set(act, f2, f6);
    add_set(act, f3, "param2");

    NOK;
}

TEST_F(SlidesExamples, b8) {
    add_set(act, f1, "param1");
    add_set(act, f2, "param2");
    add_set(act, f3, f7);
    add_set(act, f4, "param3");

    OK;
}

TEST_F(SlidesExamples, b9) {
    add_set(act, f1, 0x2);

    OK;
}

TEST_F(SlidesExamples, b10) {
    add_set(act, f1, 0x2);
    add_set(act, f2, "param1");

    OK;
}

TEST_F(SlidesExamples, b11) {
    add_set(act, f1, 0x2);
    add_set(act, f2, "param2");
    add_set(act, f3, f7);
    add_set(act, f4, f8);

    OK;
}

TEST_F(SlidesExamples, c1) {
    add_op(act, f1, "bor", f1, f5);

    NOK;
}

TEST_F(SlidesExamples, c2) {
    add_op(act, f1, "bor", f1, f5);
    add_op(act, f2, "bor", f2, f6);
    add_op(act, f3, "bor", f3, f7);
    add_op(act, f4, "bor", f4, f8);

    OK;
}

TEST_F(SlidesExamples, c3) {
    add_op(act, f1, "bor", f5, f9);
    add_op(act, f2, "bor", f6, fa);
    add_op(act, f3, "bor", f7, fb);
    add_op(act, f4, "bor", f8, fc);

    OK;
}

TEST_F(SlidesExamples, c4) {
    add_op(act, f1, "bor", f1, f5);
    add_op(act, f2, "bor", f2, f6);
    add_set(act, f3, f3);
    add_set(act, f4, f4);

    NOK;
}

TEST_F(SlidesExamples, c5) {
    add_op(act, f1, "bor", f1, f5);
    add_op(act, f2, "bor", f2, f6);
    add_op(act, f3, "bor", f3, "param1");
    add_op(act, f4, "bor", f4, "param2");

    NOK;
}

TEST_F(SlidesExamples, c6) {
    add_op(act, f1, "bor", f1, "param1");
    add_op(act, f2, "bor", f2, "param2");

    NOK;
    // XXX(zma) this can be supported if compiler can pad zero param1 and param2
    // to byte alignment on the action RAM
}


}  // namespace Test
