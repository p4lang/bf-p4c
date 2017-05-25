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

#include <boost/optional.hpp>
#include "gtest/gtest.h"

#include "frontends/common/parseInput.h"
#include "frontends/p4/frontend.h"
#include "ir/ir.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "tofino/common/extract_maupipe.h"
#include "tofino/midend.h"
#include "tofino/phv/create_thread_local_instances.h"
#include "tofino/phv/phv_fields.h"
#include "tofino/phv/trivial_alloc.h"
#include "tofino/tofinoOptions.h"

namespace Test {

/// A utility class that handles the boilerplate of creating PHV-related test cases.
struct PhvTestCase {
    /**
     * Create a PhvTestCase from P4 @source by parsing it and running the
     * frontend, midend, and MAU pipe extraction passes over it.  Triggers a
     * test failure if errors are encountered.
     */
    static boost::optional<PhvTestCase>
    create(const std::string& source) {
        auto program =
          P4::parseP4String(source, CompilerOptions::FrontendVersion::P4_16);
        EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
        if (program == nullptr) {
            ADD_FAILURE() << "Couldn't parse test case source";
            return boost::none;
        }

        Tofino_Options options;
        options.langVersion = CompilerOptions::FrontendVersion::P4_16;
        program = P4::FrontEnd().run(options, program, true);
        EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
        if (program == nullptr) {
            ADD_FAILURE() << "Frontend failed";
            return boost::none;
        }

        Tofino::MidEnd midend(options);
        auto midendProgram = program->apply(midend);
        EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
        if (midendProgram == nullptr) {
            ADD_FAILURE() << "Midend failed";
            return boost::none;
        }

        auto pipe = extract_maupipe(midendProgram, options);
        EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
        if (pipe == nullptr) {
            ADD_FAILURE() << "Pipe extraction failed";
            return boost::none;
        }

        PassManager passes = {
            new CreateThreadLocalInstances(INGRESS),
            new CreateThreadLocalInstances(EGRESS),
        };
        pipe = pipe->apply(passes);
        EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
        if (pipe == nullptr) {
            ADD_FAILURE() << "Inserting thread local instances failed";
            return boost::none;
        }

        return PhvTestCase{program, pipe};
    }

    /// The test program, as represented in the frontend IR.
    const IR::P4Program* program;

    /// A Tofino Pipe containing the Tofino IR version of the program.
    const IR::Tofino::Pipe* pipe;

private:
    PhvTestCase(const IR::P4Program* program, const IR::Tofino::Pipe* pipe)
        : program(program), pipe(pipe)
    { }
};

namespace SharedPhvTestCases {

/// A simple P4 program with a variety of header fields.
static boost::optional<PhvTestCase> trivialAlloc() {
    SCOPED_TRACE("PhvTestCase::trivialAlloc()");
    return PhvTestCase::create(P4_SOURCE(P4Headers::CORE, R"(
        header H1 { bit<8> field; }
        header H2 { bit<1> field1; bit<6> field2; bit<9> field3; }
        header H3 { bit<72> field; }
        header H4 { bit<16> field; }
        header H5 { bit<32> field; }
        struct H { H1 h1; H2 h2; H3 h3; H4 h4; H5 h5; }

        parser p(packet_in packet, out H headers) {
            state start {
                packet.extract(headers.h1);
                packet.extract(headers.h2);
                packet.extract(headers.h3);
                packet.extract(headers.h4);
                transition accept;
            }
        }

        control mau(inout H headers) {
            action noop() { }
            table t {
                key = {
                    headers.h1.field : ternary;
                    headers.h2.field1 : exact;
                    headers.h3.field : ternary;
                }
                actions = { noop; }
                default_action = noop;
            }
            apply { t.apply(); }
        }

        control dep(packet_out b, in H headers) {
            apply {
                b.emit(headers.h1);
                b.emit(headers.h2);
                b.emit(headers.h3);
                b.emit(headers.h4);
            }
        }

        parser Parser<T>(packet_in b, out T parsedHdr);
        control MAU<T>(inout T hdr);
        control Deparser<T>(packet_out b, in T hdr);
        package Switch<T>(Parser<T> p, MAU<T> ig, MAU<T> eg, Deparser<T> dep);
        Switch(p(), mau(), mau(), dep()) main;
    )"));
}

}  // namespace SharedTrivialAllocTestCases

template <typename T>
class TofinoPHVTrivialAllocators : public ::testing::Test {
 protected:
    // This class is a friend of PhvInfo::Field, so it has access to
    // Field::alloc_i; this helper makes that member available to subclasses.
    static const vector<PhvInfo::Field::alloc_slice>&
        alloc(const PhvInfo::Field* field) { return field->alloc_i; }
};

typedef ::testing::Types<PHV::TrivialAlloc, PHV::ManualAlloc> TrivialAllocators;
TYPED_TEST_CASE(TofinoPHVTrivialAllocators, TrivialAllocators);

// Test that the automatic allocations performed by TrivialAlloc and ManualAlloc
// produce the expected results. (And, implicitly, that they both produce the
// *same* results.)
TYPED_TEST(TofinoPHVTrivialAllocators, AutomaticAllocation) {
    auto testcase = SharedPhvTestCases::trivialAlloc();
    ASSERT_TRUE(testcase != boost::none);

    // Perform PHV analysis and run the allocator.
    PhvInfo phv;
    PassManager passes = {
        &phv,
        new VisitFunctor([&]{ phv.allocatePOV(HeaderStackInfo()); }),
        new TypeParam(phv)  // TypeParam is either TrivialAlloc or ManualAlloc.
    };
    auto program = testcase->pipe->apply(passes);
    ASSERT_TRUE(program != nullptr);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());

    // Used to check that no container is shared between fields unexpectedly.
    std::set<PHV::Container> uniqueContainers;

    for (gress_t gress : { INGRESS, EGRESS }) {
        SCOPED_TRACE(gress);
        auto prefix = cstring::to_cstring(gress) + "::";

        // Check that the provided container index is valid for this thread.
        auto indexOK = [=](unsigned index) {
            return gress == INGRESS ? (index < 16 || index >= 32)
                                    : (index >= 16);
        };

        // header H1 { bit<8> field; }
        auto h1_field = phv.field(prefix + "h1.field");
        ASSERT_TRUE(h1_field != nullptr);
        auto h1_field_alloc = this->alloc(h1_field);
        ASSERT_EQ(1u, h1_field_alloc.size());
        EXPECT_EQ(0, h1_field_alloc[0].container_bit);
        EXPECT_EQ(0, h1_field_alloc[0].field_bit);
        EXPECT_EQ(8, h1_field_alloc[0].width);
        auto h1_field_container = h1_field_alloc[0].container;
        EXPECT_EQ(PHV::Container::Kind::B, h1_field_container.kind());
        EXPECT_PRED1(indexOK, h1_field_container.index());
        EXPECT_TRUE(uniqueContainers.insert(h1_field_container).second);

        // header H2 { bit<1> field1; bit<6> field2; bit<9> field3; }
        auto h2_field1 = phv.field(prefix + "h2.field1");
        ASSERT_TRUE(h2_field1 != nullptr);
        auto h2_field1_alloc = this->alloc(h2_field1);
        ASSERT_EQ(1u, h2_field1_alloc.size());
        EXPECT_EQ(15, h2_field1_alloc[0].container_bit);
        EXPECT_EQ(0, h2_field1_alloc[0].field_bit);
        EXPECT_EQ(1, h2_field1_alloc[0].width);
        auto h2_field2 = phv.field(prefix + "h2.field2");
        ASSERT_TRUE(h2_field2 != nullptr);
        auto h2_field2_alloc = this->alloc(h2_field2);
        ASSERT_EQ(1u, h2_field2_alloc.size());
        EXPECT_EQ(9, h2_field2_alloc[0].container_bit);
        EXPECT_EQ(0, h2_field2_alloc[0].field_bit);
        EXPECT_EQ(6, h2_field2_alloc[0].width);
        auto h2_field3 = phv.field(prefix + "h2.field3");
        ASSERT_TRUE(h2_field3 != nullptr);
        auto h2_field3_alloc = this->alloc(h2_field3);
        ASSERT_EQ(1u, h2_field3_alloc.size());
        EXPECT_EQ(0, h2_field3_alloc[0].container_bit);
        EXPECT_EQ(0, h2_field3_alloc[0].field_bit);
        EXPECT_EQ(9, h2_field3_alloc[0].width);
        auto h2_field_container = h2_field1_alloc[0].container;
        EXPECT_EQ(h2_field_container, h2_field2_alloc[0].container);
        EXPECT_EQ(h2_field_container, h2_field3_alloc[0].container);
        EXPECT_EQ(PHV::Container::Kind::H, h2_field_container.kind());
        EXPECT_PRED1(indexOK, h2_field_container.index());
        EXPECT_TRUE(uniqueContainers.insert(h2_field_container).second);

        // header H3 { bit<72> field; }
        auto h3_field = phv.field(prefix + "h3.field");
        ASSERT_TRUE(h3_field != nullptr);
        auto h3_field_alloc = this->alloc(h3_field);
        ASSERT_EQ(3u, h3_field_alloc.size());
        EXPECT_EQ(0, h3_field_alloc[0].container_bit);
        EXPECT_EQ(40, h3_field_alloc[0].field_bit);
        EXPECT_EQ(32, h3_field_alloc[0].width);
        auto h3_field_container_0 = h3_field_alloc[0].container;
        EXPECT_EQ(PHV::Container::Kind::W, h3_field_container_0.kind());
        EXPECT_PRED1(indexOK, h3_field_container_0.index());
        EXPECT_TRUE(uniqueContainers.insert(h3_field_container_0).second);
        EXPECT_EQ(0, h3_field_alloc[1].container_bit);
        EXPECT_EQ(8, h3_field_alloc[1].field_bit);
        EXPECT_EQ(32, h3_field_alloc[1].width);
        auto h3_field_container_1 = h3_field_alloc[1].container;
        EXPECT_EQ(PHV::Container::Kind::W, h3_field_container_1.kind());
        EXPECT_PRED1(indexOK, h3_field_container_1.index());
        EXPECT_TRUE(uniqueContainers.insert(h3_field_container_1).second);
        EXPECT_EQ(0, h3_field_alloc[2].container_bit);
        EXPECT_EQ(0, h3_field_alloc[2].field_bit);
        EXPECT_EQ(8, h3_field_alloc[2].width);
        auto h3_field_container_2 = h3_field_alloc[2].container;
        EXPECT_EQ(PHV::Container::Kind::B, h3_field_container_2.kind());
        EXPECT_PRED1(indexOK, h3_field_container_2.index());
        EXPECT_TRUE(uniqueContainers.insert(h3_field_container_2).second);

        // header H4 { bit<16> field; }
        // (This field isn't used in the MAU, so we check that it gets assigned
        // to a tagalong container below.)
        auto h4_field = phv.field(prefix + "h4.field");
        ASSERT_TRUE(h4_field != nullptr);
        auto h4_field_alloc = this->alloc(h4_field);
        ASSERT_EQ(1u, h4_field_alloc.size());
        EXPECT_EQ(0, h4_field_alloc[0].container_bit);
        EXPECT_EQ(0, h4_field_alloc[0].field_bit);
        EXPECT_EQ(16, h4_field_alloc[0].width);
        auto h4_field_container = h4_field_alloc[0].container;
        EXPECT_EQ(PHV::Container::Kind::TH, h4_field_container.kind());
        EXPECT_TRUE(uniqueContainers.insert(h4_field_container).second);

        // header H5 { bit<32> field; }
        // (This field isn't used at all, so we don't expect it to get any
        // alloc_iation whatsoever.)
        EXPECT_TRUE(phv.field(prefix + "h5.field") == nullptr);
        EXPECT_TRUE(phv.field(prefix + "h5.$valid") == nullptr);

        // Check the POV bits.
        // XXX(seth): The values here will need to change when the special $POV
        // fields are removed.
        auto h1_valid = phv.field(prefix + "h1.$valid");
        ASSERT_TRUE(h1_valid != nullptr);
        auto h1_valid_alloc = this->alloc(h1_valid);
        ASSERT_EQ(1u, h1_valid_alloc.size());
        EXPECT_EQ(3, h1_valid_alloc[0].container_bit);
        EXPECT_EQ(0, h1_valid_alloc[0].field_bit);
        EXPECT_EQ(1, h1_valid_alloc[0].width);
        auto h2_valid = phv.field(prefix + "h2.$valid");
        ASSERT_TRUE(h2_valid != nullptr);
        auto h2_valid_alloc = this->alloc(h2_valid);
        ASSERT_EQ(1u, h2_valid_alloc.size());
        EXPECT_EQ(2, h2_valid_alloc[0].container_bit);
        EXPECT_EQ(0, h2_valid_alloc[0].field_bit);
        EXPECT_EQ(1, h2_valid_alloc[0].width);
        auto h3_valid = phv.field(prefix + "h3.$valid");
        ASSERT_TRUE(h3_valid != nullptr);
        auto h3_valid_alloc = this->alloc(h3_valid);
        ASSERT_EQ(1u, h3_valid_alloc.size());
        EXPECT_EQ(1, h3_valid_alloc[0].container_bit);
        EXPECT_EQ(0, h3_valid_alloc[0].field_bit);
        EXPECT_EQ(1, h3_valid_alloc[0].width);
        auto h4_valid = phv.field(prefix + "h4.$valid");
        ASSERT_TRUE(h4_valid != nullptr);
        auto h4_valid_alloc = this->alloc(h4_valid);
        ASSERT_EQ(1u, h4_valid_alloc.size());
        EXPECT_EQ(0, h4_valid_alloc[0].container_bit);
        EXPECT_EQ(0, h4_valid_alloc[0].field_bit);
        EXPECT_EQ(1, h4_valid_alloc[0].width);
        auto h1_valid_container = h1_valid_alloc[0].container;
        EXPECT_EQ(PHV::Container::Kind::B, h1_field_container.kind());
        EXPECT_EQ(h1_valid_container, h2_valid_alloc[0].container);
        EXPECT_EQ(h1_valid_container, h3_valid_alloc[0].container);
        EXPECT_EQ(h1_valid_container, h4_valid_alloc[0].container);
    }
}

class TofinoPHVManualAlloc : public ::testing::Test {
 protected:
    static void
    runManualAllocTest(const PHV::ManualAlloc::AssignmentMap& assignments) {
        auto testcase = SharedPhvTestCases::trivialAlloc();
        ASSERT_TRUE(testcase != boost::none);

        // Perform PHV analysis and run the allocator.
        PhvInfo phv;
        PassManager passes = {
            &phv,
            new VisitFunctor([&]{ phv.allocatePOV(HeaderStackInfo()); }),
            new PHV::ManualAlloc(phv, assignments)
        };
        auto program = testcase->pipe->apply(passes);
        ASSERT_TRUE(program != nullptr);
        EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());

        // Verify that we got the assignments we requested.
        for (auto& assignment : assignments) {
            SCOPED_TRACE(assignment.first);
            auto field = phv.field(assignment.first);
            ASSERT_TRUE(field != nullptr);

            auto& requested = assignment.second;
            auto& actual = field->alloc_i;
            ASSERT_EQ(requested.size(), actual.size());
            for (unsigned i = 0; i < requested.size(); ++i) {
                EXPECT_EQ(field, actual[i].field);
                EXPECT_EQ(requested[i].container, actual[i].container);
                EXPECT_EQ(requested[i].field_bit, actual[i].field_bit);
                EXPECT_EQ(requested[i].container_bit, actual[i].container_bit);
                EXPECT_EQ(requested[i].width, actual[i].width);
            }
        }
    }
};

TEST_F(TofinoPHVManualAlloc, SimpleAllocation) {
    runManualAllocTest({
        { "ingress::h1.field", { PHV::ManualAlloc::Slice{"B48", 0, 0, 8} } }
    });
}

TEST_F(TofinoPHVManualAlloc, WidthMismatch) {
    // A set of assignments with mismatches between the width of the container
    // and the width of the field.
    runManualAllocTest({
        // Map h1.field (8 bits) into the upper 8 bits of a 16-bit container.
        { "ingress::h1.field", { PHV::ManualAlloc::Slice{"H1", 0, 8, 8} } },

        // Map the upper 4 bits of h1.field into the upper 4 bits of an 8-bit
        // container.
        { "egress::h1.field", { PHV::ManualAlloc::Slice{"TB16", 4, 4, 4} } },

        // Map h4.field (16 bits) into the middle 16 bits of a 32-bit container.
        { "ingress::h4.field", { PHV::ManualAlloc::Slice{"W32", 0, 8, 16} } },

        // Map the lower 8 bits of h4.field into the upper 8 bits of a 32-bit
        // container.
        { "egress::h4.field", { PHV::ManualAlloc::Slice{"W31", 0, 24, 8} } },
    });
}

TEST_F(TofinoPHVManualAlloc, SplitAllocation) {
    // A set of assignments that split fields between multiple containers or
    // containers between multiple fields.
    runManualAllocTest({
        // Split the two nibbles in h1.field into two different containers.
        { "ingress::h1.field", { PHV::ManualAlloc::Slice{"B1", 4, 0, 4},
                                 PHV::ManualAlloc::Slice{"B0", 0, 0, 4} } },

        // Split the 16 total bits in h2's fields between two 8-bit containers.
        { "ingress::h2.field1", { PHV::ManualAlloc::Slice{"B2", 0, 7, 1} } },
        { "ingress::h2.field2", { PHV::ManualAlloc::Slice{"B2", 0, 1, 6} } },
        { "ingress::h2.field3", { PHV::ManualAlloc::Slice{"B2", 8, 0, 1},
                                  PHV::ManualAlloc::Slice{"B3", 0, 0, 8} } },

        // Split h3.field between four containers of different sizes.
        { "ingress::h3.field", { PHV::ManualAlloc::Slice{"W32", 40, 0, 32},
                                 PHV::ManualAlloc::Slice{"H32", 24, 0, 16},
                                 PHV::ManualAlloc::Slice{"H33", 8, 0, 16},
                                 PHV::ManualAlloc::Slice{"B34", 0, 0, 8} } },

        // Allocate every POV bit to a different container.
        { "ingress::h1.$valid", { PHV::ManualAlloc::Slice{"B32", 0, 0, 1} } },
        { "ingress::h2.$valid", { PHV::ManualAlloc::Slice{"B33", 0, 0, 1} } },
        { "ingress::h3.$valid", { PHV::ManualAlloc::Slice{"B34", 0, 0, 1} } },
        { "ingress::h4.$valid", { PHV::ManualAlloc::Slice{"B35", 0, 0, 1} } },
    });
}

TEST_F(TofinoPHVManualAlloc, ReservedContainerAllocation) {
    // Check that ManualAlloc correctly ensures that container groups are never
    // assigned to more than one thread. Ordinarily ManualAlloc ignores errors
    // if they originate in the manual allocations requested by the user; for
    // this test, we explicitly enable error checking for manual allocations by
    // constructing ManualAlloc instances with  `/* checked = */ true`.

    auto testcase = SharedPhvTestCases::trivialAlloc();
    ASSERT_TRUE(testcase != boost::none);

    // Perform PHV analysis.
    PhvInfo phv;
    PassManager passes = {
        &phv,
        new VisitFunctor([&]{ phv.allocatePOV(HeaderStackInfo()); })
    };
    auto program = testcase->pipe->apply(passes);
    ASSERT_TRUE(program != nullptr);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());

    // [B0, B16), [H0, H16), and [W0, W16) are reserved for ingress.
    ASSERT_ANY_THROW(program->apply(PHV::ManualAlloc(phv, /* checked = */ true, {
          { "egress::h1.field", { PHV::ManualAlloc::Slice{"B0", 0, 0, 8} } } })));
    ASSERT_ANY_THROW(program->apply(PHV::ManualAlloc(phv, /* checked = */ true, {
          { "egress::h4.field", { PHV::ManualAlloc::Slice{"H0", 0, 0, 16} } } })));
    ASSERT_ANY_THROW(program->apply(PHV::ManualAlloc(phv, /* checked = */ true, {
          { "egress::h3.field", { PHV::ManualAlloc::Slice{"W0", 0, 0, 32} } } })));

    // [B16, B32), [H16, H32), and [W16, W32) are reserved for egress.
    ASSERT_ANY_THROW(program->apply(PHV::ManualAlloc(phv, /* checked = */ true, {
          { "ingress::h1.field", { PHV::ManualAlloc::Slice{"B16", 0, 0, 8} } } })));
    ASSERT_ANY_THROW(program->apply(PHV::ManualAlloc(phv, /* checked = */ true, {
          { "ingress::h4.field", { PHV::ManualAlloc::Slice{"H16", 0, 0, 8} } } })));
    ASSERT_ANY_THROW(program->apply(PHV::ManualAlloc(phv, /* checked = */ true, {
          { "ingress::h3.field", { PHV::ManualAlloc::Slice{"W16", 0, 0, 8} } } })));

    // Allocating a container to a thread reserves all of the containers in the
    // same group for that thread. B and H containers are assigned to a thread
    // in groups of 8; W containers are assigned in groups of 4. Tagalong
    // containers are assigned in groups that contain all container sizes; each
    // group consists of 4 B containers, 4 W containers, and 6 H containers.
    ASSERT_ANY_THROW(program->apply(PHV::ManualAlloc(phv, /* checked = */ true, {
          { "ingress::h1.field", { PHV::ManualAlloc::Slice{"B48", 0, 0, 8} } },
          { "egress::h1.field", { PHV::ManualAlloc::Slice{"B49", 0, 0, 8} } }
        })));
    ASSERT_ANY_THROW(program->apply(PHV::ManualAlloc(phv, /* checked = */ true, {
          { "ingress::h4.field", { PHV::ManualAlloc::Slice{"H48", 0, 0, 16} } },
          { "egress::h4.field", { PHV::ManualAlloc::Slice{"H49", 0, 0, 16} } }
        })));
    ASSERT_ANY_THROW(program->apply(PHV::ManualAlloc(phv, /* checked = */ true, {
          { "ingress::h3.field", { PHV::ManualAlloc::Slice{"W48", 0, 0, 32} } },
          { "egress::h3.field", { PHV::ManualAlloc::Slice{"W49", 0, 0, 32} } }
        })));
    ASSERT_ANY_THROW(program->apply(PHV::ManualAlloc(phv, /* checked = */ true, {
          { "ingress::h1.field", { PHV::ManualAlloc::Slice{"TB4", 0, 0, 8} } },
          { "egress::h4.field", { PHV::ManualAlloc::Slice{"TH6", 0, 0, 16} } }
        })));
    ASSERT_ANY_THROW(program->apply(PHV::ManualAlloc(phv, /* checked = */ true, {
          { "ingress::h4.field", { PHV::ManualAlloc::Slice{"TH6", 0, 0, 16} } },
          { "egress::h3.field", { PHV::ManualAlloc::Slice{"TW4", 0, 0, 32} } }
        })));

    // [B56, B64), [H88, H96), and [W60, W64) are special containers which can
    // be allocated to threads individually, so no grouping constraint applies
    // to them.
    ASSERT_NO_THROW(program->apply(PHV::ManualAlloc(phv, /* checked = */ true, {
          { "ingress::h1.field", { PHV::ManualAlloc::Slice{"B56", 0, 0, 8} } },
          { "egress::h1.field", { PHV::ManualAlloc::Slice{"B57", 0, 0, 8} } },
          { "ingress::h4.field", { PHV::ManualAlloc::Slice{"H88", 0, 0, 16} } },
          { "egress::h4.field", { PHV::ManualAlloc::Slice{"H89", 0, 0, 16} } },
          { "ingress::h3.field", { PHV::ManualAlloc::Slice{"W60", 0, 0, 32} } },
          { "egress::h3.field", { PHV::ManualAlloc::Slice{"W61", 0, 0, 32} } }
        })));
}

}  // namespace Test
