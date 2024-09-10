#include <sstream>

#include "gtest/gtest.h"
#include "backends/tofino/device.h"
#include "lib/bitvec.h"
#include "test/gtest/helpers.h"
#include "backends/tofino/test/gtest/tofino_gtest_utils.h"
#include "backends/tofino/phv/phv_fields.h"

namespace Test {

class TofinoPhvSlicingIterator : public TofinoBackendTest {
 public:
    const PhvSpec& phvSpec = Device::phvSpec();
};

TEST_F(TofinoPhvSlicingIterator, make_split_meta) {
    const PhvSpec& phvSpec = Device::phvSpec();
    std::vector<PHV::AllocSlice> expected_slices;
    int count;

    std::map<PHV::Type, std::vector<PHV::Container>> containers;
    for (auto cid : phvSpec.physicalContainers()) {
        if (phvSpec.ingressOnly()[cid] || phvSpec.egressOnly()[cid])
            continue;
        auto c = phvSpec.idToContainer(cid);
        containers[c.type()].push_back(c); }

    PHV::Container c8 = containers[PHV::Type::B][0];
    PHV::Container c16 = containers[PHV::Type::H][0];

    // Make a field.
    auto* f = new PHV::Field();
    std::stringstream ss;
    f->id = 16;
    f->size = 16;
    ss << "f" << f->id;
    f->name = ss.str();
    f->gress = INGRESS;
    f->validContainerRange_i = ZeroToMax();
    f->alignment = std::nullopt;
    f->set_exact_containers(true);

    // Simple allocation to one container.
    f->set_alloc({
        // Field MSB-->LSB.
        PHV::AllocSlice(f, c16, 0, 0, 16) });

    expected_slices = {
        // Field LSB-->MSB (opposite alloc_i).
        PHV::AllocSlice(f, c16, 0, 0, 8),
        PHV::AllocSlice(f, c16, 8, 8, 8) };

    count = 0;
    f->foreach_byte(StartLen(0, 16), [&](const PHV::AllocSlice& slice) {
        EXPECT_EQ(expected_slices[count], slice);
        count++;
    });

    // Simple allocation to one container with limited range.
    f->set_alloc({
        // Field MSB-->LSB.
        PHV::AllocSlice(f, c16, 0, 0, 16) });

    expected_slices = {
        // Field LSB-->MSB (opposite alloc_i).
        PHV::AllocSlice(f, c16, 1, 1, 7),
        PHV::AllocSlice(f, c16, 8, 8, 7) };

    count = 0;
    f->foreach_byte(FromTo(1, 14), [&](const PHV::AllocSlice& slice) {
        EXPECT_EQ(expected_slices[count], slice);
        count++;
    });

    // Simple allocation to two containers.
    f->set_alloc({
        // Field MSB-->LSB.
        PHV::AllocSlice(f, c8, 8, 0, 8),
        PHV::AllocSlice(f, c16, 0, 0, 8), });

    expected_slices = {
        // Field LSB-->MSB (opposite alloc_i).
        PHV::AllocSlice(f, c16, 0, 0, 8),
        PHV::AllocSlice(f, c8, 8, 0, 8) };

    count = 0;
    f->foreach_byte(StartLen(0, 16), [&](const PHV::AllocSlice& slice) {
        EXPECT_EQ(expected_slices[count], slice);
        count++;
    });

    // Simple allocation to two containers, but the allocation to c16 spans two
    // container bytes.
    f->set_alloc({
        // Field MSB-->LSB.
        PHV::AllocSlice(f, c8, 8, 0, 8),
        PHV::AllocSlice(f, c16, 0, 4, 8), });

    expected_slices = {
        // Field LSB-->MSB (opposite alloc_i).
        PHV::AllocSlice(f, c16, 0, 4, 4),
        PHV::AllocSlice(f, c16, 4, 8, 4),
        PHV::AllocSlice(f, c8, 8, 0, 8) };

    count = 0;
    f->foreach_byte(StartLen(0, 16), [&](const PHV::AllocSlice& slice) {
        EXPECT_EQ(expected_slices[count], slice);
        count++;
    });

    // Test a corner case that triggered a bug in foreach_byte on switch_dc_basic.
    f->set_alloc({
        // Field MSB-->LSB.
        PHV::AllocSlice(f, c8,  11, 0, 5),
        PHV::AllocSlice(f, c8,  10, 7, 1),
        PHV::AllocSlice(f, c16, 0, 0, 10) });

    expected_slices = {
        // Field LSB-->MSB (opposite alloc_i).
        PHV::AllocSlice(f, c16, 1, 1, 7),
        PHV::AllocSlice(f, c16, 8, 8, 2),
        PHV::AllocSlice(f, c8, 10, 7, 1),
        PHV::AllocSlice(f, c8, 11, 0, 4),
    };

    count = 0;
    f->foreach_byte(FromTo(1, 14), [&](const PHV::AllocSlice& slice) {
        EXPECT_EQ(expected_slices[count], slice);
        count++;
    });
}

}  // namespace Test
