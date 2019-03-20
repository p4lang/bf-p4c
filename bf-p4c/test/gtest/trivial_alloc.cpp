#include <boost/optional.hpp>
#include <type_traits>
#include "gtest/gtest.h"

#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_spec.h"
#include "bf-p4c/phv/trivial_alloc.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "ir/ir.h"
#include "lib/bitvec.h"
#include "lib/error.h"
#include "lib/safe_vector.h"
#include "lib/symbitmatrix.h"
#include "test/gtest/helpers.h"

namespace Test {

namespace SharedPhvTestCases {

/// A simple P4 program with a variety of header fields.
static boost::optional<TofinoPipeTestCase> trivialAlloc() {
    SCOPED_TRACE("PhvTestCase::trivialAlloc()");

    auto& options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";

    return TofinoPipeTestCase::createWithThreadLocalInstances(P4_SOURCE(P4Headers::CORE, R"(
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

}  // namespace SharedPhvTestCases

template <typename T>
class TofinoPHVTrivialAllocators : public TofinoBackendTest {
 protected:
    // This class is a friend of PHV::Field, so it has access to
    // Field::alloc_i; this helper makes that member available to subclasses.
    static const safe_vector<PHV::Field::alloc_slice>&
        alloc(const PHV::Field* field) { return field->get_alloc(); }
};

typedef ::testing::Types<PHV::TrivialAlloc, PHV::ManualAlloc> TrivialAllocators;
TYPED_TEST_CASE(TofinoPHVTrivialAllocators, TrivialAllocators);

// Test that the automatic allocations performed by TrivialAlloc and ManualAlloc
// produce the expected results. (And, implicitly, that they both produce the
// *same* results.)
TYPED_TEST(TofinoPHVTrivialAllocators, DISABLED_AutomaticAllocation) {
    const auto& phvSpec = Device::phvSpec();

    auto testcase = SharedPhvTestCases::trivialAlloc();
    ASSERT_TRUE(testcase);

    // Perform PHV analysis and run the allocator.
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    PassManager passes = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        new TypeParam(phv)  // TypeParam is either TrivialAlloc or ManualAlloc.
    };
    auto program = testcase->pipe->apply(passes);
    ASSERT_TRUE(program != nullptr);
    EXPECT_EQ(0u, ::diagnosticCount());

    // Used to check that no container is shared between fields unexpectedly.
    std::set<PHV::Container> uniqueContainers;

    for (gress_t gress : { INGRESS, EGRESS }) {
        SCOPED_TRACE(gress);
        auto prefix = cstring::to_cstring(gress) + "::";

        using SliceId = std::pair<cstring, unsigned>;
        std::map<SliceId, PHV::Container> containers;

        // Check that the provided container can be allocated to this thread.
        auto okForCurrentThread = [&](PHV::Container container) {
            return gress == INGRESS
                 ? !phvSpec.egressOnly()[phvSpec.containerToId(container)]
                 : !phvSpec.ingressOnly()[phvSpec.containerToId(container)];
        };

        // A helper that checks that the given field's allocation maps the given
        // field bit ranges to the provided container bit ranges.
        auto checkMapping =
          [&](cstring fieldName, const std::vector<le_bitrange>& fieldBits,
                                 const std::vector<le_bitrange>& containerBits) {
            SCOPED_TRACE(fieldName.c_str());

            // Sanity check that the field has an allocation and that it has the
            // right size.
            auto field = phv.field(prefix + fieldName);
            ASSERT_TRUE(field != nullptr);
            auto& fieldAlloc = this->alloc(field);
            ASSERT_EQ(fieldAlloc.size(), fieldBits.size());
            ASSERT_EQ(containerBits.size(), fieldBits.size());

            // Check each slice in the allocation.
            for (unsigned i = 0; i < fieldBits.size(); ++i) {
                auto& slice = fieldAlloc[i];
                EXPECT_EQ(fieldBits[i].lo, slice.field_bits().lo);
                EXPECT_EQ(fieldBits[i].hi, slice.field_bits().hi);
                EXPECT_EQ(containerBits[i].lo, slice.container_bits().lo);
                EXPECT_EQ(containerBits[i].hi, slice.container_bits().hi);
                EXPECT_PRED1(okForCurrentThread, slice.container);

                auto sliceId = std::make_pair(fieldName, i);
                EXPECT_TRUE(containers.find(sliceId) == containers.end())
                            << "Checked slice more than once?";
                containers[sliceId] = slice.container;
            }
        };

        // header H1 { bit<8> field; }
        checkMapping("h1.field", { le_bitrange(0, 7) }, { le_bitrange(0, 7) });
        auto h1Container = containers[SliceId("h1.field", 0)];
        EXPECT_EQ(PHV::Type("B"), h1Container.type());
        EXPECT_TRUE(uniqueContainers.insert(h1Container).second);

        // header H2 { bit<1> field1; bit<6> field2; bit<9> field3; }
        checkMapping("h2.field1", { le_bitrange(0, 0) }, { le_bitrange(15, 15) });
        checkMapping("h2.field2", { le_bitrange(0, 5) }, { le_bitrange(9, 14) });
        checkMapping("h2.field3", { le_bitrange(0, 8) }, { le_bitrange(0, 8) });
        auto h2Container = containers[SliceId("h2.field1", 0)];
        EXPECT_EQ(h2Container, containers[SliceId("h2.field2", 0)]);
        EXPECT_EQ(h2Container, containers[SliceId("h2.field3", 0)]);
        EXPECT_EQ(PHV::Type("H"), h2Container.type());
        EXPECT_TRUE(uniqueContainers.insert(h2Container).second);

        // header H3 { bit<72> field; }
        checkMapping("h3.field",
                     { le_bitrange(40, 71), le_bitrange(8, 39), le_bitrange(0, 7) },
                     { le_bitrange(0, 31), le_bitrange(0, 31), le_bitrange(0, 7) });
        auto h3Slice0Container = containers[SliceId("h3.field", 0)];
        EXPECT_EQ(PHV::Type("W"), h3Slice0Container.type());
        EXPECT_TRUE(uniqueContainers.insert(h3Slice0Container).second);
        auto h3Slice1Container = containers[SliceId("h3.field", 1)];
        EXPECT_EQ(PHV::Type("W"), h3Slice1Container.type());
        EXPECT_TRUE(uniqueContainers.insert(h3Slice1Container).second);
        auto h3Slice2Container = containers[SliceId("h3.field", 2)];
        EXPECT_EQ(PHV::Type("B"), h3Slice2Container.type());
        EXPECT_TRUE(uniqueContainers.insert(h3Slice2Container).second);

        // header H4 { bit<16> field; }
        // (This field isn't used in the MAU, so we check that it gets assigned
        // to a tagalong container below.)
        checkMapping("h4.field", { le_bitrange(0, 15) }, { le_bitrange(0, 15) });
        auto h4Container = containers[SliceId("h4.field", 0)];
        EXPECT_EQ(PHV::Type("TH"), h4Container.type());
        EXPECT_TRUE(uniqueContainers.insert(h4Container).second);

        // header H5 { bit<32> field; }
        // (This field isn't used at all, so we don't expect it to get any
        // allocation whatsoever.)
        EXPECT_TRUE(phv.field(prefix + "h5.field") == nullptr);
        EXPECT_TRUE(phv.field(prefix + "h5.$valid") == nullptr);

        // Check the POV bits.
        {
            // A helper that produces the container range for the next POV bit;
            // helps work around the fact that ingress and egress have different
            // intrinsic metadata that results in a different set of POV bits.
            int nextBitIndex = 7;
            auto nextBit = [&] {
                auto range = le_bitrange(nextBitIndex, nextBitIndex);
                EXPECT_GE(nextBitIndex, 0);
                nextBitIndex--;
                return range;
            };

            if (gress == INGRESS)
                checkMapping("$always_deparse", { le_bitrange(0, 0) }, { nextBit() });
            checkMapping("h1.$valid", { le_bitrange(0, 0) }, { nextBit() });
            checkMapping("h2.$valid", { le_bitrange(0, 0) }, { nextBit() });
            checkMapping("h3.$valid", { le_bitrange(0, 0) }, { nextBit() });

            // XXX(seth): TrivialAlloc and ManualAlloc get different results here
            // because TrivialAlloc places the final field in a container as far to
            // the right as it can, even if it introduces a gap.
            nextBitIndex =
              std::is_same<TypeParam, PHV::TrivialAlloc>::value ? 0 : nextBitIndex;
            checkMapping("h4.$valid", { le_bitrange(0, 0) }, { nextBit() });
        }

        auto povContainer = containers[SliceId("h1.$valid", 0)];
        EXPECT_EQ(povContainer, containers[SliceId("h2.$valid", 0)]);
        EXPECT_EQ(povContainer, containers[SliceId("h3.$valid", 0)]);
        EXPECT_EQ(povContainer, containers[SliceId("h4.$valid", 0)]);
        if (gress == INGRESS) {
            EXPECT_EQ(povContainer, containers[SliceId("$always_deparse", 0)]);
        }
        EXPECT_EQ(PHV::Type("B"), povContainer.type());
        EXPECT_TRUE(uniqueContainers.insert(povContainer).second);
    }
}

class TofinoPHVManualAlloc : public TofinoBackendTest {
 protected:
    static void
    runManualAllocTest(const PHV::ManualAlloc::AssignmentMap& assignments, bool
            isWidthMismatchTest = false) {
        auto testcase = SharedPhvTestCases::trivialAlloc();
        ASSERT_TRUE(testcase);

        // Perform PHV analysis and run the allocator.
        SymBitMatrix mutex;
        PhvInfo phv(mutex);
        PassManager passes = {
            new CollectHeaderStackInfo,
            new CollectPhvInfo(phv),
            new PHV::ManualAlloc(phv, assignments)
        };
        auto program = testcase->pipe->apply(passes);
        ASSERT_TRUE(program != nullptr);
        EXPECT_EQ(0u, ::diagnosticCount());

        // Verify that we got the assignments we requested.
        for (auto& assignment : assignments) {
            SCOPED_TRACE(assignment.first);
            auto field = phv.field(assignment.first);
            ASSERT_TRUE(field != nullptr);

            auto& requested = assignment.second;
            auto& actual = field->get_alloc();
            ASSERT_EQ(requested.size(), actual.size());
            for (unsigned i = 0; i < requested.size(); ++i) {
                EXPECT_EQ(field, actual[i].field);
                EXPECT_EQ(requested[i].container, actual[i].container);
                EXPECT_EQ(requested[i].field_bit, actual[i].field_bit);
                EXPECT_EQ(requested[i].container_bit, actual[i].container_bit);
                EXPECT_EQ(requested[i].width, actual[i].width);

                // Only for the width mismatch test, also check the bits_allocated function, which
                // returns a bitvector with the allocated container bits
                if (!isWidthMismatchTest) continue;
                ordered_set<const PHV::Field*> allocated_fields;
                if (requested[i].container == "H1") {
                    allocated_fields.insert(actual[i].field);
                    auto bitvec_ret = phv.bits_allocated(actual[i].container, allocated_fields);
                    allocated_fields.clear();
                    bitvec real(8, 8);
                    EXPECT_EQ(bitvec_ret, real);
                } else if (requested[i].container == "B2" || requested[i].container == "B3") {
                    allocated_fields.insert(actual[i].field);
                    auto bitvec_ret = phv.bits_allocated(actual[i].container, allocated_fields);
                    allocated_fields.clear();
                    bitvec real(0, 8);
                    EXPECT_EQ(bitvec_ret, real);
                } else if (requested[i].container == "W31") {
                    allocated_fields.insert(actual[i].field);
                    auto bitvec_ret = phv.bits_allocated(actual[i].container, allocated_fields);
                    allocated_fields.clear();
                    bitvec real(24, 8);
                    EXPECT_EQ(bitvec_ret, real); } } } }
};

TEST_F(TofinoPHVManualAlloc, DISABLED_SimpleAllocation) {
    runManualAllocTest({
        { "ingress::h1.field", { PHV::ManualAlloc::Slice{"B48", 0, 0, 8} } }
    });
}

TEST_F(TofinoPHVManualAlloc, DISABLED_WidthMismatch) {
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
    }, /* isWidthMismatchTest */ true);
}

TEST_F(TofinoPHVManualAlloc, DISABLED_SplitAllocation) {
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
    }, /* isWidthMismatchTest */ true);
}

TEST_F(TofinoPHVManualAlloc, DISABLED_ReservedContainerAllocation) {
    // Check that ManualAlloc correctly ensures that container groups are never
    // assigned to more than one thread. Ordinarily ManualAlloc ignores errors
    // if they originate in the manual allocations requested by the user; for
    // this test, we explicitly enable error checking for manual allocations by
    // constructing ManualAlloc instances with  `/* checked = */ true`.

    auto testcase = SharedPhvTestCases::trivialAlloc();
    ASSERT_TRUE(testcase);

    // Perform PHV analysis.
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    PassManager passes = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv)
    };
    auto program = testcase->pipe->apply(passes);
    ASSERT_TRUE(program != nullptr);
    EXPECT_EQ(0u, ::diagnosticCount());

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
