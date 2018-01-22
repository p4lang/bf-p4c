#include "gtest/gtest.h"

#include <sstream>

#include "bf-p4c/device.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/phv/allocate_phv.h"
#include "bf-p4c/phv/field_alignment.h"
#include "bf-p4c/phv/utils.h"
#include "lib/bitvec.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class TofinoBitvec : public TofinoBackendTest {};

TEST_F(TofinoBitvec, inc) {
    bitvec bv;
    EXPECT_EQ(-1, *bv.min());
    EXPECT_EQ(-1, *bv.max());

    // 1
    PHV::inc(bv);
    EXPECT_EQ(0, *bv.min());
    EXPECT_EQ(1, bv.getbit(0));
    EXPECT_EQ(0, *bv.max());

    // 10
    PHV::inc(bv);
    EXPECT_EQ(1, *bv.min());
    EXPECT_EQ(0, bv[0]);
    EXPECT_EQ(1, bv[1]);
    EXPECT_EQ(1, *bv.max());

    // 11
    PHV::inc(bv);
    EXPECT_EQ(0, *bv.min());
    EXPECT_EQ(1, bv[0]);
    EXPECT_EQ(1, bv[1]);
    EXPECT_EQ(1, *bv.max());

    // 100 (special)
    PHV::inc(bv);
    EXPECT_EQ(2, *bv.min());
    EXPECT_EQ(0, bv[0]);
    EXPECT_EQ(0, bv[1]);
    EXPECT_EQ(1, bv[2]);
    EXPECT_EQ(2, *bv.max());
}

class TofinoPhvCrush : public TofinoBackendTest {};

TEST_F(TofinoPhvCrush, clusterAlignment) {
    // XXX(cole): This just tests the first bit of the valid bits, not all
    // valid bits.
    using FieldData = struct {
        int field_size;
        boost::optional<int> relativeAlignment;     // little Endian
        nw_bitrange validContainerRange;
    };
    using TestData = struct {
        // boost::none implies result is an empty bitvec
        boost::optional<int> result;
        PHV::Size container_size;
        std::vector<FieldData> fields;
    };

    std::vector<TestData> tests = {
        // No constraints
        { 0, PHV::Size::b8, { { 8, boost::none, ZeroToMax() } } },
        { 0, PHV::Size::b8, { { 8, boost::none, ZeroToMax() },
                              { 8, boost::none, ZeroToMax() } } },

        // Relative alignment only
        { 0, PHV::Size::b8,  { { 8, 0, ZeroToMax() } } },
        { 0, PHV::Size::b8,  { { 8, 0, ZeroToMax() },
                               { 8, 0, ZeroToMax() } } },
        { 4, PHV::Size::b16, { { 8, 4, ZeroToMax() } } },
        { 4, PHV::Size::b16, { { 8, 4, ZeroToMax() },
                               { 8, 4, ZeroToMax() } } },
        { 4, PHV::Size::b16, { { 8, boost::none, ZeroToMax() },
                               { 8, 4, ZeroToMax() } } },
        
        // validContainerStartRange only
        { 0, PHV::Size::b16, { { 8, boost::none, StartLen(0, 16) } } },
        { 0, PHV::Size::b16, { { 8, boost::none, StartLen(0, 16) },
                               { 8, boost::none, StartLen(0, 16) } } },
        { 0, PHV::Size::b16, { { 8, boost::none, StartLen(0, 32) } } },
        { 0, PHV::Size::b16, { { 8, boost::none, StartLen(0, 32) },
                               { 8, boost::none, StartLen(0, 32) } } },
        { 4, PHV::Size::b16, { { 8, boost::none, StartLen(0, 12) } } },
        { 4, PHV::Size::b16, { { 8, boost::none, StartLen(0, 12) },
                               { 8, boost::none, StartLen(0, 13) } } },

        // Both relative alignment and validContainerStartRange
        { 0, PHV::Size::b16, { { 8, 0, StartLen(0, 16) } } },
        { 0, PHV::Size::b16, { { 8, 0, StartLen(0, 16) },
                               { 8, 0, StartLen(0, 16) } } },
        { 4, PHV::Size::b16, { { 8, 4, StartLen(0, 12) } } },
        { 4, PHV::Size::b16, { { 8, 4, StartLen(0, 12) },
                               { 8, 4, StartLen(0, 13) } } },
    };

    int field_id = 0;
    for (auto& test : tests) {
        std::vector<PHV::FieldSlice> slices;
        for (auto& fdata : test.fields) {
            auto* f = new PHV::Field();
            std::stringstream ss;
            f->id = field_id++;
            f->size = int(fdata.field_size);
            ss << "f" << f->id;
            f->name = ss.str();
            f->gress = INGRESS;
            f->offset = 0;
            f->metadata = true;
            f->bridged = false;
            f->pov = false;
            f->validContainerRange_i = fdata.validContainerRange;
            if (fdata.relativeAlignment)
                f->alignment =
                    FieldAlignment(le_bitrange(StartLen(*fdata.relativeAlignment, int(test.container_size))));
            else
                f->alignment = boost::none;
            slices.push_back(PHV::FieldSlice(f));
        }

        PHV::AlignedCluster cl(PHV::Kind::normal, slices);
        if (test.result)
            EXPECT_EQ(*test.result, *(cl.validContainerStart(test.container_size).min()));
        else
            EXPECT_TRUE(cl.validContainerStart(test.container_size).empty());
    }

}

TEST_F(TofinoPhvCrush, makeDeviceAllocation) {
    const PhvSpec& phvSpec = Device::phvSpec();
    auto alloc = PHV::ConcreteAllocation(SymBitMatrix());

    // Check that all physical containers are accounted for and unallocated.
    for (auto cid : phvSpec.physicalContainers()) {
        auto c = phvSpec.idToContainer(cid);
        EXPECT_EQ(0U, alloc.slices(c).size()); }

    // Check that ONLY physical containers are present.
    for (auto kv : alloc) {
        auto cid = phvSpec.containerToId(kv.first);
        EXPECT_TRUE(phvSpec.physicalContainers()[cid]); }

    // Check that all hard-wired gress has been set.
    for (auto cid : phvSpec.ingressOnly()) {
        auto c = phvSpec.idToContainer(cid);
        EXPECT_EQ(INGRESS, alloc.gress(c)); }
    for (auto cid : phvSpec.egressOnly()) {
        auto c = phvSpec.idToContainer(cid);
        EXPECT_EQ(EGRESS, alloc.gress(c)); }
}

TEST_F(TofinoPhvCrush, Transaction) {
    const PhvSpec& phvSpec = Device::phvSpec();
    auto alloc = PHV::ConcreteAllocation(SymBitMatrix());

    std::vector<PHV::Container> containers;
    for (auto cid : phvSpec.physicalContainers()) {
        if (phvSpec.ingressOnly()[cid] || phvSpec.egressOnly()[cid])
            continue;
        containers.push_back(phvSpec.idToContainer(cid)); }

    PHV::Container c1 = containers[0];
    PHV::Container c2 = containers[1];
    PHV::Container c3 = containers[34];

    PHV::Field f1;
    f1.id = 1;
    f1.size = 8;
    f1.name = "foo.bar";
    f1.gress = INGRESS;
    f1.offset = 0;
    f1.metadata = true;
    f1.bridged = false;
    f1.pov = false;
    PHV::AllocSlice s1(&f1, c1, 0, 0, 8);

    // Allocation is empty.
    EXPECT_EQ(boost::none, alloc.gress(c3));
    EXPECT_EQ(0U, alloc.slices(c3).size());
    EXPECT_EQ(0U, alloc.slicesByLiveness(c3).size());

    // Allocate one slice, setting INGRESS to deparser group.
    alloc.allocate(s1);

    EXPECT_EQ(INGRESS, alloc.gress(c1));
    EXPECT_EQ(INGRESS, alloc.gress(c2));
    EXPECT_EQ(boost::none, alloc.gress(c3));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s1}), alloc.slices(c1));
    EXPECT_EQ(1U, alloc.slicesByLiveness(c1).size());
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s1}), alloc.slicesByLiveness(c1).back());
    EXPECT_EQ(0U, alloc.slices(c3).size());

    // Make a transaction, which should initially match (but not change) alloc.
    auto alloc_attempt = alloc.makeTransaction();

    EXPECT_EQ(INGRESS, alloc.gress(c1));
    EXPECT_EQ(INGRESS, alloc_attempt.gress(c1));
    EXPECT_EQ(INGRESS, alloc_attempt.gress(c2));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s1}), alloc.slices(c1));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s1}), alloc_attempt.slices(c1));

    // Other containers (out of deparser group range) don't change.
    EXPECT_EQ(boost::none, alloc.gress(c3));
    EXPECT_EQ(boost::none, alloc_attempt.gress(c3));
    EXPECT_EQ(0U, alloc.slices(c3).size());
    EXPECT_EQ(0U, alloc_attempt.slices(c3).size());

    PHV::Field f2;
    f2.id = 2;
    f2.size = 8;
    f2.name = "foo.baz";
    f2.gress = INGRESS;
    f2.offset = 0;
    f2.metadata = true;
    f2.bridged = false;
    f2.pov = false;
    PHV::AllocSlice s2(&f2, c1, 0, 4, 4);
    PHV::AllocSlice s3(&f2, c2, 4, 4, 4);

    // Allocate to c2.  No change to gress, nor to alloc.
    alloc_attempt.allocate(s3);

    EXPECT_EQ(INGRESS, alloc.gress(c1));
    EXPECT_EQ(INGRESS, alloc_attempt.gress(c1));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s1}), alloc.slices(c1));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s1}), alloc_attempt.slices(c1));

    EXPECT_EQ(INGRESS, alloc.gress(c2));
    EXPECT_EQ(INGRESS, alloc_attempt.gress(c2));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({ }), alloc.slices(c2));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s3}), alloc_attempt.slices(c2));

    // Other containers (out of deparser group range) don't change.
    EXPECT_EQ(boost::none, alloc.gress(c3));
    EXPECT_EQ(boost::none, alloc_attempt.gress(c3));
    EXPECT_EQ(0U, alloc.slices(c3).size());
    EXPECT_EQ(0U, alloc_attempt.slices(c3).size());

    // Allocate another slice to c1.  No change to gress, nor to alloc.
    alloc_attempt.allocate(s2);

    EXPECT_EQ(INGRESS, alloc.gress(c1));
    EXPECT_EQ(INGRESS, alloc_attempt.gress(c1));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s1}), alloc.slices(c1));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s1, s2}), alloc_attempt.slices(c1));

    EXPECT_EQ(INGRESS, alloc.gress(c2));
    EXPECT_EQ(INGRESS, alloc_attempt.gress(c2));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({ }), alloc.slices(c2));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s3}), alloc_attempt.slices(c2));

    // Other containers (out of deparser group range) don't change.
    EXPECT_EQ(boost::none, alloc.gress(c3));
    EXPECT_EQ(boost::none, alloc_attempt.gress(c3));
    EXPECT_EQ(0U, alloc.slices(c3).size());
    EXPECT_EQ(0U, alloc_attempt.slices(c3).size());

    // Commit, changing alloc.  Removes slices from alloc_attempt, but as
    // they're placed in alloc, the change is unobservable.
    alloc.commit(alloc_attempt);

    EXPECT_EQ(INGRESS, alloc.gress(c1));
    EXPECT_EQ(INGRESS, alloc_attempt.gress(c1));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s1, s2}), alloc.slices(c1));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s1, s2}), alloc_attempt.slices(c1));

    EXPECT_EQ(1U, alloc.slicesByLiveness(c1).size());
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s1, s2}), alloc.slicesByLiveness(c1).back());

    EXPECT_EQ(INGRESS, alloc.gress(c2));
    EXPECT_EQ(INGRESS, alloc_attempt.gress(c2));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s3}), alloc.slices(c2));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s3}), alloc_attempt.slices(c2));

    // Other containers (out of deparser group range) don't change.
    EXPECT_EQ(boost::none, alloc.gress(c3));
    EXPECT_EQ(boost::none, alloc_attempt.gress(c3));
    EXPECT_EQ(0U, alloc.slices(c3).size());
    EXPECT_EQ(0U, alloc_attempt.slices(c3).size());
}


TEST_F(TofinoPhvCrush, slicesByLiveness) {
    const PhvSpec& phvSpec = Device::phvSpec();

    SymBitMatrix mutex;
    mutex[1][2] = true;
    auto alloc = PHV::ConcreteAllocation(mutex);

    std::vector<PHV::Container> containers;
    for (auto cid : phvSpec.physicalContainers()) {
        if (phvSpec.ingressOnly()[cid] || phvSpec.egressOnly()[cid])
            continue;
        containers.push_back(phvSpec.idToContainer(cid)); }

    PHV::Container c1 = containers[0];

    PHV::Field f1;
    f1.id = 1;
    f1.size = 8;
    f1.name = "foo.bar";
    f1.gress = INGRESS;
    PHV::AllocSlice s1(&f1, c1, 0, 0, 8);

    PHV::Field f2;
    f2.id = 2;
    f2.size = 8;
    f2.name = "foo.baz";
    f2.gress = INGRESS;
    PHV::AllocSlice s2(&f2, c1, 0, 0, 8);

    // Allocate one slice, setting INGRESS to deparser group.
    alloc.allocate(s1);
    alloc.allocate(s2);

    EXPECT_NE(ordered_set<PHV::AllocSlice>({ s1, s2 }), ordered_set<PHV::AllocSlice>({ s1 }));
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({ s1, s2 }), alloc.slices(c1));

    EXPECT_EQ(2U, alloc.slicesByLiveness(c1).size());
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s1}), alloc.slicesByLiveness(c1).front());
    EXPECT_EQ(ordered_set<PHV::AllocSlice>({s2}), alloc.slicesByLiveness(c1).back());
    EXPECT_EQ(std::vector<ordered_set<PHV::AllocSlice>>({ { s1 }, { s2 } }),
              alloc.slicesByLiveness(c1));
}

class JBayPhvCrush : public JBayBackendTest {};

TEST_F(JBayPhvCrush, makeDeviceAllocation) {
    const PhvSpec& phvSpec = Device::phvSpec();
    auto alloc = PHV::ConcreteAllocation(SymBitMatrix());

    // Check that all physical containers are accounted for and unallocated.
    for (auto cid : phvSpec.physicalContainers()) {
        auto c = phvSpec.idToContainer(cid);
        EXPECT_EQ(0U, alloc.slices(c).size()); }

    // Check that ONLY physical containers are present.
    for (auto kv : alloc) {
        auto cid = phvSpec.containerToId(kv.first);
        EXPECT_TRUE(phvSpec.physicalContainers()[cid]); }

    // Check that all hard-wired gress has been set.
    for (auto cid : phvSpec.ingressOnly()) {
        auto c = phvSpec.idToContainer(cid);
        EXPECT_EQ(INGRESS, alloc.gress(c)); }
    for (auto cid : phvSpec.egressOnly()) {
        auto c = phvSpec.idToContainer(cid);
        EXPECT_EQ(EGRESS, alloc.gress(c)); }
}

}  // namespace Test
