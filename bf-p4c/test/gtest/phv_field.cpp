#include "gtest/gtest.h"

#include <sstream>

#include "bf-p4c/device.h"
#include "lib/bitvec.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "bf-p4c/phv/phv_fields.h"

namespace Test {

class TofinoField : public TofinoBackendTest {};

TEST_F(TofinoField, foreach_byte) {
    const PhvSpec& phvSpec = Device::phvSpec();
    std::vector<PHV::Field::alloc_slice> expected_slices;
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
    f->alignment = boost::none;
    f->set_exact_containers(true);

    // Simple allocation to one container.
    f->alloc_i = {
        // Field MSB-->LSB.
        PHV::Field::alloc_slice(f, c16, 0, 0, 16) };

    expected_slices = {
        // Field LSB-->MSB (opposite alloc_i).
        PHV::Field::alloc_slice(f, c16, 0, 0, 8),
        PHV::Field::alloc_slice(f, c16, 8, 8, 8) };

    count = 0;
    f->foreach_byte(StartLen(0, 16), [&](const PHV::Field::alloc_slice& slice) {
        EXPECT_EQ(expected_slices[count++], slice);
    });

    // Simple allocation to one container with limited range.
    f->alloc_i = {
        // Field MSB-->LSB.
        PHV::Field::alloc_slice(f, c16, 0, 0, 16) };

    expected_slices = {
        // Field LSB-->MSB (opposite alloc_i).
        PHV::Field::alloc_slice(f, c16, 1, 1, 7),
        PHV::Field::alloc_slice(f, c16, 8, 8, 7) };

    count = 0;
    f->foreach_byte(FromTo(1, 14), [&](const PHV::Field::alloc_slice& slice) {
        EXPECT_EQ(expected_slices[count++], slice);
    });

    // Simple allocation to two containers.
    f->alloc_i = {
        // Field MSB-->LSB.
        PHV::Field::alloc_slice(f, c8, 8, 0, 8),
        PHV::Field::alloc_slice(f, c16, 0, 0, 8), };

    expected_slices = {
        // Field LSB-->MSB (opposite alloc_i).
        PHV::Field::alloc_slice(f, c16, 0, 0, 8),
        PHV::Field::alloc_slice(f, c8, 8, 0, 8) };

    count = 0;
    f->foreach_byte(StartLen(0, 16), [&](const PHV::Field::alloc_slice& slice) {
        EXPECT_EQ(expected_slices[count++], slice);
    });

    // Simple allocation to two containers, but the allocation to c16 spans two
    // container bytes.
    f->alloc_i = {
        // Field MSB-->LSB.
        PHV::Field::alloc_slice(f, c8, 8, 0, 8),
        PHV::Field::alloc_slice(f, c16, 0, 4, 8), };

    expected_slices = {
        // Field LSB-->MSB (opposite alloc_i).
        PHV::Field::alloc_slice(f, c16, 0, 4, 4),
        PHV::Field::alloc_slice(f, c16, 4, 8, 4),
        PHV::Field::alloc_slice(f, c8, 8, 0, 8) };

    count = 0;
    f->foreach_byte(StartLen(0, 16), [&](const PHV::Field::alloc_slice& slice) {
        EXPECT_EQ(expected_slices[count++], slice);
    });

    // Test a corner case that triggered a bug in foreach_byte on switch_dc_basic.
    f->alloc_i = {
        // Field MSB-->LSB.
        PHV::Field::alloc_slice(f, c8,  11, 0, 5),
        PHV::Field::alloc_slice(f, c8,  10, 7, 1),
        PHV::Field::alloc_slice(f, c16, 0, 0, 10) };

    expected_slices = {
        // Field LSB-->MSB (opposite alloc_i).
        PHV::Field::alloc_slice(f, c16, 1, 1, 7),
        PHV::Field::alloc_slice(f, c16, 8, 8, 2),
        PHV::Field::alloc_slice(f, c8, 10, 7, 1),
        PHV::Field::alloc_slice(f, c8, 11, 0, 4),
    };

    count = 0;
    f->foreach_byte(FromTo(1, 14), [&](const PHV::Field::alloc_slice& slice) {
        EXPECT_EQ(expected_slices[count++], slice);
    });
}

}  // namespace Test
