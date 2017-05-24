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

#include "tofino/phv/validate_allocation.h"

#include <algorithm>
#include <iterator>
#include <sstream>

#include "lib/cstring.h"
#include "tofino/phv/phv.h"

namespace PHV {

bool ValidateAllocation::preorder(const IR::Tofino::Pipe*) {
    BUG_CHECK(phv.alloc_done(),
              "Calling ValidateAllocation without performing PHV allocation");

    // A mapping from a range of bits in a field to a range of bits in a PHV
    // container. This is the same thing as PHV::Field::alloc_slice, except that
    // it contains the field rather than the container.
    struct FieldSlice {
        PhvInfo::Field* field;
        int field_bit;
        int container_bit;
        int width;
    };

    // A mapping from PHV containers to the field slices that they contain.
    std::map<PHV::Container, std::vector<FieldSlice>> allocations;

    // The set of reserved container ids for each thread.
    bitvec threadAssignments[2] = {
        PHV::Container::ingressOnly(), PHV::Container::egressOnly()
    };

    // Check that every bit in each field is allocated without overlap, and
    // collect information that we'll use to check container properties.
    for (auto& field : phv) {
        if (!field.referenced) {
            WARN_CHECK(field.alloc_i.empty(),
                        "PHV allocation for unreferenced %1%field %2% (width %3%)",
                        field.bridged ? "bridged " : "",
                        cstring::to_cstring(field),
                        field.size);
            continue;
        }

        ERROR_CHECK(!field.alloc_i.empty(),
                    "No PHV allocation for referenced field %1%",
                    cstring::to_cstring(field));

        bitvec allocatedBits;
        for (auto& slice : field.alloc_i) {
            allocations[slice.container].emplace_back(FieldSlice{
                &field,
                slice.field_bit,
                slice.container_bit,
                slice.width
            });

            threadAssignments[field.gress] |= slice.container.group();

            // Verify that the field doesn't contain any overlapping slices.
            // (Note that this is checking overlapping with respect to the
            // *field*; we check overlapping with respect to the *container*
            // below.)
            bitvec sliceBits(slice.field_bit, slice.width);
            ERROR_CHECK(!sliceBits.intersects(allocatedBits),
                        "Overlapping field slices in allocation for field %1%",
                        cstring::to_cstring(field));
            allocatedBits |= sliceBits;
        }

        // Verify that all bits in the field are allocated.
        // XXX(seth): Long term it would be ideal to only allocate the bits we
        // actually need, but this will help us find bugs in the short term.
        bitvec allBitsInField(0, field.size);
        ERROR_CHECK(allocatedBits == allBitsInField,
                    "Not all bits are allocated for field %1%",
                    cstring::to_cstring(field));
    }

    // Check that no container is assigned to both threads.
    for (auto id : threadAssignments[INGRESS] & threadAssignments[EGRESS]) {
        auto container = PHV::Container::fromId(id);

        std::set<PhvInfo::Field*> fields[2];
        if (allocations.count(container))
            for (auto& slice : allocations[container])
                fields[slice.field->gress].insert(slice.field);

        std::stringstream message;
        for (gress_t gress : { INGRESS, EGRESS }) {
            if (!fields[gress].empty())
                message << gress << " fields: " << fields[gress] << ". ";
            else
                message << "Part of container group assigned to " << gress << ": "
                        << PHV::Container::groupToString(container.group()) << ". ";
        }

        ::error("Container %1% is assigned to both INGRESS and EGRESS. %2%",
                container, message.str());
    }

    auto isMetadata = [](PhvInfo::Field* f) { return f->metadata || f->pov; };

    // Check that the allocation for each container is valid.
    for (auto& allocation : allocations) {
        auto container = allocation.first;
        auto& slices = allocation.second;

        // Collect all the fields which are assigned to this container.
        std::set<PhvInfo::Field*> fields;
        std::transform(slices.begin(), slices.end(),
                       std::inserter(fields, fields.begin()),
                       [](const FieldSlice& slice) { return slice.field; });

        // Since TPHV containers can't be accessed in the MAU, and metadata is
        // not normally deparsed, it generally doesn't make sense to put
        // metadata fields in TPHV. There are some exceptional cases, though:
        // both bridged metadata and mirrored metadata effectively get turned
        // into compiler-synthesized headers that are prepended to the packet,
        // and hence must be deparsed.
        // XXX(seth): We'll have to add a check for mirrored metadata below when
        // that feature is implemented.
        if (container.tagalong()) {
            for (auto field : fields)
                ERROR_CHECK(!isMetadata(field) || field->bridged,
                            "Tagalong container %1% contains non-bridged metadata "
                            "field %2%", container, cstring::to_cstring(field));
        }

        // XXX(seth): When there are overlayed fields in a container, we'd
        // ideally like to verify that each mutually exclusive group of
        // overlayed fields satisfies our constraints independently - e.g., each
        // group should consist of deparsed fields only or nondeparsed fields
        // only, and if the group is deparsed, the fields should cover the
        // entire container exactly. Unfortunately, determining what those
        // gruops are is currently hard, so for now we skip most checks when
        // overlaying is present.
        for (auto field : fields)
            if (!field->field_overlay_map().empty()) return false;

        // Verify that the container contains either all metadata fields, or all
        // header fields.
        bool metadata = std::all_of(fields.begin(), fields.end(), isMetadata);
        ERROR_CHECK(metadata || std::none_of(fields.begin(), fields.end(), isMetadata),
                    "Container %1% contains a mix of metadata and non-metadata "
                    "fields: %2%", container, cstring::to_cstring(fields));

        // Verify that the allocations for each field don't overlap. (Note that
        // this is checking overlapping with respect to the *container*; we
        // check overlapping with respect to the *field* above.)
        bitvec allocatedBitsForContainer;
        for (auto field : fields) {
            std::vector<FieldSlice> slicesForField;
            std::copy_if(slices.begin(), slices.end(),
                         std::back_inserter(slicesForField),
                         [&](const FieldSlice& slice) {
                return slice.field == field;
            });
            ERROR_CHECK(!slicesForField.empty(), "No slices for field?");

            bitvec allocatedBitsForField;
            for (auto& slice : slicesForField) {
                bitvec sliceBits(slice.container_bit, slice.width);
                ERROR_CHECK(!sliceBits.intersects(allocatedBitsForField),
                            "Container %1% contains overlapping slices of field %2%",
                            container, cstring::to_cstring(field));
                allocatedBitsForField |= sliceBits;
            }

            ERROR_CHECK(!allocatedBitsForField.intersects(allocatedBitsForContainer),
                        "Container %1% contains fields which overlap: %2%",
                        container, cstring::to_cstring(fields));
            allocatedBitsForContainer |= allocatedBitsForField;
        }

        // Verify that non-metadata fields allocate every bit in the container.
        // XXX(seth): This check isn't quite precise; the actual rule is that
        // *deparsed* fields must allocate every bit in the container.
        bitvec allBitsInContainer(0, container.size());
        ERROR_CHECK(metadata || allocatedBitsForContainer == allBitsInContainer,
                    "Container %1% will be deparsed, but it has unused bits: %2%",
                    container, cstring::to_cstring(fields));
    }

    return false;
}

}  // namespace PHV
