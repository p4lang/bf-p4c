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
#include "tofino/phv/phv_parde_mau_use.h"
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

    // Before we do anything else, we check if the program failed to fit - i.e.,
    // if the PHV allocator ran out of real containers and had to allocate
    // overflow containers. If so, we normally just report the error and skip
    // all further checks, because the PHV allocator isn't guaranteed to satisfy
    // its constraints when that happens. (There's a flag to disable this for
    // debugging purposes.)
    {
        bitvec allContainersInProgram;
        for (auto& field : phv)
            for (auto& slice : field.alloc_i)
                allContainersInProgram[slice.container.id()] = true;


        auto overflowContainers =
          allContainersInProgram - PHV::Container::physicalContainers();
        if (!overflowContainers.empty()) {
            ::warning("Couldn't fit program in the available PHV space!");

            std::map<PHV::Container::Kind, size_t> overflowCountByKind;
            for (auto id : overflowContainers)
                overflowCountByKind[PHV::Container::fromId(id).kind()]++;

            auto physicalContainers =
              allContainersInProgram & PHV::Container::physicalContainers();
            std::map<PHV::Container::Kind, size_t> physicalCountByKind;
            for (auto id : physicalContainers)
                physicalCountByKind[PHV::Container::fromId(id).kind()]++;

            for (unsigned kind = 0; kind < PHV::Container::NumKinds; kind++) {
                ::warning("Used %1% physical and %2% overflow %3% containers",
                          physicalCountByKind[PHV::Container::Kind(kind)],
                          overflowCountByKind[PHV::Container::Kind(kind)],
                          cstring::to_cstring(PHV::Container::Kind(kind)));
            }

            if (!ignorePHVOverflow) {
                ::error("PHV allocation was not successful.");
                return false;  // Don't perform any more checks.
            }
        }
    }

    // A mapping from PHV containers to the field slices that they contain.
    using Slice = PhvInfo::Field::alloc_slice;
    std::map<PHV::Container, std::vector<Slice>> allocations;

    // The set of reserved container ids for each thread.
    bitvec threadAssignments[2] = {
        PHV::Container::ingressOnly(), PHV::Container::egressOnly()
    };

    // Collect information about which fields are referenced in the program.
    Phv_Parde_Mau_Use uses(phv);
    pipe->apply(uses);

    // Check that every bit in each field is allocated without overlap, and
    // collect information that we'll use to check container properties.
    for (auto& field : phv) {
        if (!uses.is_referenced(&field)) {
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
            // XXX(seth): For fields which are parsed or deparsed, this can
            // never work, but there are some odd situations in which it could
            // in theory be useful (e.g. we can rotate containers in the MAU in
            // some scenarios, so we could allocate the field to both the top
            // and the bottom of the container, with something else in the
            // middle, and then rotate it into place when needed). However,
            // until we make the PHV allocator more sophisticated, this is
            // probably just a bug.
            ERROR_CHECK(!assignedContainers[slice.container.id()],
                        "Multiple slices in the same container are allocated "
                        "to field %1%", cstring::to_cstring(field));

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

    std::vector<const PhvInfo::Field*> deparseSequence;
    std::map<const PhvInfo::Field*, std::vector<size_t>> deparseOccurrences;

    // Verify that we allocate PHV space for all fields which are emitted or
    // used as POV bits in the deparser, and that POV bits don't end up in TPHV.
    // We also check that each byte in a container used in a computed checksum
    // consists either entirely of checksummed fields or entirely of ignored
    // fields.
    forAllMatching<IR::Tofino::DeparserPrimitive>(pipe,
                  [&](const IR::Tofino::DeparserPrimitive* prim) {
        const IR::Expression* povFieldSource;

        if (auto* emit = prim->to<IR::Tofino::Emit>()) {
            auto* sourceField = phv.field(emit->source, nullptr);
            ERROR_CHECK(sourceField != nullptr, "No PHV allocation for field "
                        "emitted by the deparser: %1%", emit->source);
            povFieldSource = emit->povBit;

            if (sourceField) {
                deparseSequence.push_back(sourceField);
                deparseOccurrences[sourceField].push_back(deparseSequence.size());
            }
        } else if (auto* emitChecksum = prim->to<IR::Tofino::EmitChecksum>()) {
            // Verify that every source field for this computed checksum is
            // allocated, and collect all of the allocations used in this
            // computed checksum.
            std::map<PHV::Container, std::vector<Slice>> checksumAllocations;
            for (auto* source : emitChecksum->sources) {
                bitrange sourceFieldBits;
                auto* sourceField = phv.field(source, &sourceFieldBits);
                if (!sourceField) {
                    ::error("No PHV allocation for field used in computed "
                            "checksum: %1%", source);
                    continue;
                }

                sourceField->foreach_alloc(sourceFieldBits,
                             [&](const PhvInfo::Field::alloc_slice& alloc) {
                    checksumAllocations[alloc.container].push_back(alloc);
                });
            }

            // Verify that for every container which contributes to this
            // computed checksum, each byte either contains *only* fields which
            // contribute to the checksum (and no empty space) or contains *no*
            // fields which contribute to the checksum.
            for (auto& allocation : checksumAllocations) {
                auto& slices = allocation.second;

                bitvec allocatedBits;
                for (auto& slice : slices)
                    allocatedBits.setrange(slice.container_bit, slice.width);

                for (auto byte : { 0, 1, 2, 3}) {
                    auto bitsInByte = allocatedBits.getslice(byte * 8, 8);
                    auto numSetBits = bitsInByte.popcount();
                    ERROR_WARN_(numSetBits == 0 || numSetBits == 8,
                                "Byte %1% of container contains a mix of "
                                "checksum fields and non-checksum fields or "
                                "empty space: %2%", byte,
                                cstring::to_cstring(slices));
                }
            }

            povFieldSource = emitChecksum->povBit;
        } else {
            BUG("Unexpected deparser primitive");
        }

        BUG_CHECK(povFieldSource != nullptr, "No POV bit field for %1%", prim);

        bitrange povFieldBits;
        auto* povField = phv.field(povFieldSource, &povFieldBits);
        if (!povField) {
            ::error("No PHV allocation for field used as a POV bit in the "
                    "deparser: %1%", povFieldSource);
            return;
        }

        ERROR_CHECK(povFieldBits.size() == 1, "Allocated %1% bits for POV bit "
                    "field, which should use only one bit: %2%",
                    povFieldBits.size(), cstring::to_cstring(povField));


        // Verify that POV bit are not be placed in TPHV.
        povField->foreach_alloc(povFieldBits,
                  [&](const PhvInfo::Field::alloc_slice& alloc) {
            ERROR_CHECK(!alloc.container.tagalong(), "POV bit field was placed "
                        "in TPHV: %1%", cstring::to_cstring(povField));
        });
    });

    // XXX(seth): There are some additional deparser constraints that we aren't
    // checking yet. Some known examples:
    //   - Special fields used by the deparser hardware (e.g. egress_spec) must
    //     not be in TPHV.
    //   - Fields in digests may only be packed with other fields in the same
    //     digest.

    auto isDeparsed = [](const PhvInfo::Field* f) { return f->deparsed_i; };
    auto isBridged = [](const PhvInfo::Field* f) { return f->bridged; };
    auto isMetadata = [](const PhvInfo::Field* f) { return f->metadata || f->pov; };
    auto hasOverlay = [](const PhvInfo::Field* f) {
        return !f->field_overlay_map().empty();
    };

    // Check that we've marked a field as deparsed if and only if it's actually
    // emitted in the deparser.
    for (auto& field : phv) {
        if (isDeparsed(&field))
            ERROR_CHECK(deparseOccurrences.find(&field) != deparseOccurrences.end(),
                        "Field is marked as deparsed, but the deparser doesn't "
                        "emit it: %1%", cstring::to_cstring(field));
        else
            ERROR_CHECK(deparseOccurrences.find(&field) == deparseOccurrences.end(),
                        "Field is not marked as deparsed, but the deparser "
                        "emits it: %1%", cstring::to_cstring(field));
    }

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
        {
            const PhvInfo::Field* previousField;
            std::vector<size_t> previousFieldOccurrences;

            // Because we want to check that the fields in this container are
            // placed in the order in which they're emitted in the deparser, we
            // need to walk over them in network order.
            std::vector<Slice> slicesInNetworkOrder(slices.begin(), slices.end());
            std::sort(slicesInNetworkOrder.begin(), slicesInNetworkOrder.end(),
                      [](const Slice& a, const Slice& b) {
                return a.container_bits().toSpace<Endian::Network>(a.container.size()).lo
                     < b.container_bits().toSpace<Endian::Network>(b.container.size()).lo;
            });

            for (auto& slice : slicesInNetworkOrder) {
                auto* field = slice.field;
                if (!isDeparsed(field)) continue;
                if (isMetadata(field))
                    hasDeparsedMetadataFields = true;
                else
                    hasDeparsedHeaderFields = true;

                // Validate that the ordering of these fields in the container
                // matches their ordering in the deparser everywhere that they
                // appear.
                bool orderingIsCorrect = true;
                auto& fieldOccurrences = deparseOccurrences[field];
                for (auto previousFieldOccurrence : previousFieldOccurrences) {
                    auto expectedOccurrence = previousFieldOccurrence + 1;
                    if (std::find(fieldOccurrences.begin(), fieldOccurrences.end(),
                                  expectedOccurrence) == fieldOccurrences.end())
                        orderingIsCorrect = false;
                }

                ERROR_CHECK(orderingIsCorrect,
                            "Field %1% and field %2% are adjacent in container "
                            "%3% but aren't adjacent in the deparser",
                            cstring::to_cstring(previousField),
                            cstring::to_cstring(field),
                            cstring::to_cstring(container));

                previousField = field;
                previousFieldOccurrences = fieldOccurrences;
            }
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
        int requiredAlignment = extract->bitOffset % 8;
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
