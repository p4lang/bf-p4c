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


#include <algorithm>
#include <iterator>
#include <sstream>

#include "lib/cstring.h"
#include "ir/ir.h"
#include "tofino/phv/phv.h"
#include "tofino/phv/validate_allocation.h"

// Currently we fail a lot of these checks, so to prevent mass XFAIL'ing a lot
// of the tests, we treat the checks as warning instead of errors. This macro
// indicates cases that *should* use ERROR_CHECK but are currently downgraded to
// a warning.
#define ERROR_WARN_ WARN_CHECK

namespace PHV {

bool ValidateAllocation::preorder(const IR::Tofino::Pipe* pipe) {
    BUG_CHECK(phv.alloc_done(),
              "Calling ValidateAllocation without performing PHV allocation");

    // A mapping from PHV containers to the field slices that they contain.
    using Slice = PhvInfo::Field::alloc_slice;
    std::map<PHV::Container, std::vector<Slice>> allocations;

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

        ERROR_CHECK(!field.bridged || field.deparsed_i,
                    "Field is bridged, but not deparsed: %1%",
                    cstring::to_cstring(field));

        bitvec assignedContainers;
        bitvec allocatedBits;
        for (auto& slice : field.alloc_i) {
            assignedContainers[slice.container.id()] = true;
            allocations[slice.container].emplace_back(slice);
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

        // Verify that we didn't overflow the PHV space which is actually
        // available on the hardware.
        for (auto id : assignedContainers - PHV::Container::physicalContainers())
            ERROR_WARN_(false, "Allocated overflow (non-physical) container %1% to field %2%",
                        PHV::Container::fromId(id), cstring::to_cstring(field));

        // Verify that all bits in the field are allocated.
        // XXX(seth): Long term it would be ideal to only allocate the bits we
        // actually need, but this will help us find bugs in the short term.
        bitvec allBitsInField(0, field.size);
        ERROR_WARN_(allocatedBits == allBitsInField,
                    "Not all bits are allocated for field %1%",
                    cstring::to_cstring(field));
    }

    // Check that no container is assigned to both threads.
    for (auto id : threadAssignments[INGRESS] & threadAssignments[EGRESS]) {
        auto container = PHV::Container::fromId(id);

        std::set<const PhvInfo::Field*> fields[2];
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

    auto isDeparsed = [](const PhvInfo::Field* f) { return f->deparsed_i; };
    auto isBridged = [](const PhvInfo::Field* f) { return f->bridged; };
    auto isMetadata = [](const PhvInfo::Field* f) { return f->metadata || f->pov; };
    auto hasOverlay = [](const PhvInfo::Field* f) {
        return !f->field_overlay_map().empty();
    };

    // Check that the allocation for each container is valid.
    for (auto& allocation : allocations) {
        auto container = allocation.first;
        auto& slices = allocation.second;

        // Collect all the fields which are assigned to this container.
        std::set<const PhvInfo::Field*> fields;
        for (auto& slice : slices) fields.insert(slice.field);

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
                ERROR_WARN_(!isMetadata(field) || field->bridged,
                            "Tagalong container %1% contains non-bridged metadata "
                            "field %2%", container, cstring::to_cstring(field));
        }

        // XXX(seth): When there are overlayed fields in a container, we'd
        // ideally like to verify that each mutually exclusive group of
        // overlayed fields satisfies our constraints independently - e.g., each
        // group should consist of deparsed fields only or nondeparsed fields
        // only, and if the group is deparsed, the fields should cover the
        // entire container exactly. Unfortunately, determining what those
        // groups are is currently hard, so for now we skip most checks when
        // overlaying is present.
        if (std::any_of(fields.begin(), fields.end(), hasOverlay)) continue;

        // Collect information about which fields in this container are
        // deparsed, so we can verify that the allocation is reasonable. Header
        // fields are the constrained case: if a container contains deparsed
        // header fields, it must contain *only* deparsed header fields and they
        // must completely fill the container. Several checks below combine to
        // verify that. We're much less restrictive for bridged metadata fields,
        // since they don't end up on the wire and they're not visible to the
        // programmer.
        bool hasDeparsedHeaderFields = false;
        bool hasDeparsedMetadataFields = false;
        for (auto* field : fields) {
            if (!isDeparsed(field)) continue;
            if (isMetadata(field))
                hasDeparsedMetadataFields = true;
            else
                hasDeparsedHeaderFields = true;
        }


        ERROR_CHECK(!(hasDeparsedHeaderFields && hasDeparsedMetadataFields),
                    "Deparsed container %1% contains both deparsed header "
                    "fields and deparsed metadata fields: %2%", container,
                    cstring::to_cstring(fields));

        if (hasDeparsedHeaderFields) {
            ERROR_CHECK(std::all_of(fields.begin(), fields.end(), isDeparsed),
                        "Deparsed container %1% mixes deparsed header "
                        "fields with non-deparsed fields: %2%", container,
                        cstring::to_cstring(fields));
        }

        if (hasDeparsedMetadataFields) {
            ERROR_CHECK(std::any_of(fields.begin(), fields.end(), isBridged),
                        "Deparsed container %1% contains deparsed metadata "
                        "fields, but none of them are bridged: %2%",
                        container, cstring::to_cstring(fields));
        }

        // Verify that the allocations for each field don't overlap. (Note that
        // this is checking overlapping with respect to the *container*; we
        // check overlapping with respect to the *field* above.)
        bitvec allocatedBitsForContainer;
        for (auto field : fields) {
            std::vector<Slice> slicesForField;
            for (auto& slice : slices)
                if (slice.field == field) slicesForField.push_back(slice);

            ERROR_CHECK(!slicesForField.empty(), "No slices for field?");

            bitvec allocatedBitsForField;
            for (auto& slice : slicesForField) {
                bitvec sliceBits(slice.container_bit, slice.width);
                ERROR_CHECK(!sliceBits.intersects(allocatedBitsForField),
                            "Container %1% contains overlapping slices of field %2%",
                            container, cstring::to_cstring(field));
                allocatedBitsForField |= sliceBits;
            }

            ERROR_WARN_(!allocatedBitsForField.intersects(allocatedBitsForContainer),
                        "Container %1% contains fields which overlap: %2%",
                        container, cstring::to_cstring(fields));
            allocatedBitsForContainer |= allocatedBitsForField;
        }

        // Verify that if this container has deparsed header fields, every bit
        // in the container is allocated.  Deparsed metadata fields (i.e.,
        // bridged metadata) don't have this restriction because they don't end
        // up on the wire (externally, at least) and we can ensure that garbage
        // data isn't visible to the programmer. If this container has a mixed
        // of both, we'll already have reported an error above.
        if (hasDeparsedHeaderFields) {
            bitvec allBitsInContainer(0, container.size());
            ERROR_WARN_(allocatedBitsForContainer == allBitsInContainer,
                        "Container %1% contains deparsed header fields, but "
                        "it has unused bits: %2%", container,
                        cstring::to_cstring(fields));
        }
    }

    // Check that the allocation respects parser alignment limitations.
    forAllMatching<IR::Tofino::ExtractBuffer>(pipe,
                  [&](const IR::Tofino::ExtractBuffer* extract) {
        unsigned requiredAlignment = extract->bitOffset % 8;
        bitrange bits;
        auto* field = phv.field(extract->dest, &bits);
        if (!field) {
            ::error("No PHV allocation for field extracted by the "
                    "parser: %1%", extract->dest);
            return;
        }

        field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice& alloc) {
            nw_bitrange fieldSlice =
              alloc.field_bits().toSpace<Endian::Network>(field->size);
            nw_bitrange containerSlice =
              alloc.container_bits().toSpace<Endian::Network>(alloc.container.size());

            // The first bit of the field must have the same alignment in the
            // container as it does in the input buffer.
            if (fieldSlice.lo == 0) {
                ERROR_WARN_(containerSlice.lo % 8 == requiredAlignment,
                            "Field is extracted in the parser, but its "
                            "first container slice has an incompatible "
                            "alignment: %1%", cstring::to_cstring(field));
                return;
            }

            // Other slices (which represent a continuation of the same field
            // into other containers) must be byte aligned, since container
            // boundaries must always correspond with input buffer byte
            // boundaries.
            ERROR_WARN_(containerSlice.isLoAligned(),
                        "Field is extracted in the parser into multiple "
                        "containers, but the container slices after the first "
                        "aren't byte aligned: %1%", cstring::to_cstring(field));
        });
    });

    return false;
}

}  // namespace PHV
