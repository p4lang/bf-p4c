#include <algorithm>
#include <iterator>
#include <sstream>

#include "lib/log.h"
#include "ir/ir.h"
#include "bf-p4c/device.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/validate_allocation.h"
#include "bf-p4c/mau/action_analysis.h"

#include "lib/cstring.h"

// Currently we fail a lot of these checks, so to prevent mass XFAIL'ing a lot
// of the tests, we treat the checks as warning instead of errors. This macro
// indicates cases that *should* use ERROR_CHECK but are currently downgraded to
// a warning.
#define ERROR_WARN_ WARN_CHECK

namespace PHV {

bool ValidateAllocation::preorder(const IR::BFN::Pipe* pipe) {
    BUG_CHECK(phv.alloc_done(),
              "Calling ValidateAllocation without performing PHV allocation");

    const auto& phvSpec = Device::phvSpec();

    // A mapping from PHV containers to the field slices that they contain.
    using Slice = PHV::Field::alloc_slice;
    std::map<PHV::Container, std::vector<Slice>> allocations;

    // The set of reserved container ids for each thread.
    bitvec threadAssignments[2] = {
        phvSpec.ingressOnly(), phvSpec.egressOnly()
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
            ERROR_CHECK(!assignedContainers[phvSpec.containerToId(slice.container)],
                        "Multiple slices in the same container are allocated "
                        "to field %1%", cstring::to_cstring(field));

            assignedContainers[phvSpec.containerToId(slice.container)] = true;
            allocations[slice.container].emplace_back(slice);
            threadAssignments[field.gress] |=
                phvSpec.deparserGroup(phvSpec.containerToId(slice.container));

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
        for (auto id : assignedContainers - phvSpec.physicalContainers())
            ERROR_WARN_(false, "Allocated overflow (non-physical) container %1% to field %2%",
                        phvSpec.idToContainer(id), cstring::to_cstring(field));

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
        auto container = phvSpec.idToContainer(id);

        std::set<const PHV::Field*> fields[2];
        if (allocations.count(container))
            for (auto& slice : allocations[container])
                fields[slice.field->gress].insert(slice.field);

        std::stringstream message;
        for (gress_t gress : { INGRESS, EGRESS }) {
            if (!fields[gress].empty()) {
                message << gress << " fields: " << fields[gress] << ". ";
            } else {
                auto group = phvSpec.deparserGroup(phvSpec.containerToId(container));
                message << "Part of container deparser group assigned to "
                        << gress << ": " << phvSpec.containerSetToString(group)
                        << ". ";
            }
        }

        ::error("Container %1% is assigned to both INGRESS and EGRESS. %2%",
                container, message.str());
    }

    std::vector<const PHV::Field*> deparseSequence;
    std::map<const PHV::Field*, std::vector<size_t>> deparseOccurrences;

    // Verify that we allocate PHV space for all fields which are emitted or
    // used as POV bits in the deparser, and that POV bits don't end up in TPHV.
    // We also check that each byte in a container used in a computed checksum
    // consists either entirely of checksummed fields or entirely of ignored
    // fields.
    forAllMatching<IR::BFN::DeparserPrimitive>(pipe,
                  [&](const IR::BFN::DeparserPrimitive* prim) {
        const IR::Expression* povFieldSource;

        if (auto* emit = prim->to<IR::BFN::Emit>()) {
            auto* sourceField = phv.field(emit->source, nullptr);
            ERROR_CHECK(sourceField != nullptr, "No PHV allocation for field "
                        "emitted by the deparser: %1%", emit->source);
            povFieldSource = emit->povBit;

            if (sourceField) {
                deparseSequence.push_back(sourceField);
                deparseOccurrences[sourceField].push_back(deparseSequence.size());
            }
        } else if (auto* emitChecksum = prim->to<IR::BFN::EmitChecksum>()) {
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
                             [&](const PHV::Field::alloc_slice& alloc) {
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
                  [&](const PHV::Field::alloc_slice& alloc) {
            ERROR_CHECK(!alloc.container.is(PHV::Kind::tagalong), "POV bit field was placed "
                        "in TPHV: %1%", cstring::to_cstring(povField));
        });
    });

    // XXX(seth): There are some additional deparser constraints that we aren't
    // checking yet. Some known examples:
    //   - Special fields used by the deparser hardware (e.g. egress_spec) must
    //     not be in TPHV.
    //   - Fields in digests may only be packed with other fields in the same
    //     digest.

    auto isDeparsed = [](const PHV::Field* f) { return f->deparsed_i; };
    auto isBridged = [](const PHV::Field* f) { return f->bridged; };
    auto isMetadata = [](const PHV::Field* f) { return f->metadata || f->pov; };
    auto hasOverlay = [](const PHV::Field* f) {
        // XXX(cole): This misses the substratum fields themselves, as
        // `f->overlay_substratum()` is a property of an overlaid field that
        // points to the field it overlays.
        return !f->field_overlay_map().empty() || f->overlay_substratum() != nullptr;
    };
    auto checkValidOverlay = [&](const PHV::Field* f) {
        // If this field is overlaid, check that every overlaid field is in
        // fact mutually exclusive.
        for (auto overlaid_by_container : f->field_overlay_map()) {
            for (auto* f_overlay : *overlaid_by_container.second) {
                if (f == f_overlay) continue;
                ERROR_CHECK(mutually_exclusive_field_ids(f->id, f_overlay->id),
                    "Field %1% contains %2% in its overlay map, "
                    "but they are not mutually exclusive.",
                    cstring::to_cstring(f), cstring::to_cstring(f_overlay)); } }
        if (auto* substratum = f->overlay_substratum())
            ERROR_CHECK(mutually_exclusive_field_ids(f->id, substratum->id),
                "Field %1% is overlaid atop substratum field %2% but is not mutually exclusive.",
                cstring::to_cstring(f), cstring::to_cstring(substratum));
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
        std::set<const PHV::Field*> fields;
        for (auto& slice : slices) fields.insert(slice.field);

        // Since TPHV containers can't be accessed in the MAU, and metadata is
        // not normally deparsed, it generally doesn't make sense to put
        // metadata fields in TPHV. There are some exceptional cases, though:
        // both bridged metadata and mirrored metadata effectively get turned
        // into compiler-synthesized headers that are prepended to the packet,
        // and hence must be deparsed.
        // XXX(seth): We'll have to add a check for mirrored metadata below when
        // that feature is implemented.
        if (container.is(PHV::Kind::tagalong)) {
            for (auto field : fields)
                ERROR_CHECK(!isMetadata(field) || field->bridged,
                            "Tagalong container %1% contains non-bridged metadata "
                            "field %2%", container, cstring::to_cstring(field));
        }

        // Check that every overlaid field is mutually exclusive with every
        // other overlaid field.
        std::for_each(fields.begin(), fields.end(), checkValidOverlay);

        // XXX(cole): Some of the deparser constraints, such as field ordering
        // within a container, are still too difficult to check in the presence
        // of overlaid fields.  Hopefully we can make this more precise in the
        // future.  For now, skip those checks if fields are overlaid.
        bool any_field_has_overlay = std::any_of(fields.begin(), fields.end(), hasOverlay);

        // Test combinations of fields that are live at the same time.
        std::set<std::set<const PHV::Field*>> live_field_sets;
        for (auto* f1 : fields) {
            std::set<const PHV::Field*> live_with_f1;
            for (auto* f2 : fields) {
                if (!mutually_exclusive_field_ids(f1->id, f2->id))
                    live_with_f1.insert(f2); }
            live_field_sets.emplace(std::move(live_with_f1));
        }

        for (auto& live_fields : live_field_sets) {
            // Only consider sets of slices that may be live at the same time
            // in this container.
            std::vector<Slice> live_slices;
            for (auto s : slices) {
                if (live_fields.count(s.field))
                    live_slices.push_back(s);
            }

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

            for (auto& slice : live_slices) {
                auto* field = slice.field;
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
                ERROR_CHECK(std::all_of(live_fields.begin(), live_fields.end(), isDeparsed),
                            "Deparsed container %1% mixes deparsed header "
                            "fields with non-deparsed fields: %2%", container,
                            cstring::to_cstring(fields));
            }

            if (hasDeparsedMetadataFields) {
                ERROR_CHECK(std::any_of(live_fields.begin(), live_fields.end(), isBridged),
                            "Deparsed container %1% contains deparsed metadata "
                            "fields, but none of them are bridged: %2%",
                            container, cstring::to_cstring(fields));
            }

            // Verify that the allocations for each field don't overlap. (Note that
            // this is checking overlapping with respect to the *container*; we
            // check overlapping with respect to the *field* above.)
            bitvec allocatedBitsForContainer;
            for (auto field : live_fields) {
                std::vector<Slice> slicesForField;
                for (auto& slice : live_slices)
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

                // header stack pov ccgfs will have overlap
                // if all overlapped fields point to owner header stack pov ccgf then ok
                //
                if (field->ccgf() && field->ccgf()->header_stack_pov_ccgf()) {
                    ERROR_WARN_(!allocatedBitsForField.intersects(allocatedBitsForContainer),
                                "Container %1% contains fields which overlap: %2%",
                                container, cstring::to_cstring(live_fields));
                } else {
                    ERROR_CHECK(!allocatedBitsForField.intersects(allocatedBitsForContainer),
                                "Container %1% contains fields which overlap: %2%",
                                container, cstring::to_cstring(live_fields));
                }
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
                            cstring::to_cstring(live_fields));
            }

            // XXX(cole): Checking that deparsed fields adjacent in the
            // container are adjacent in the deparser is still too complex to
            // check directly, because the check is really over adjacent
            // *valid* fields in the deparser, which we don't have a good way
            // to determine precisely here.
            if (any_field_has_overlay) continue;

            const PHV::Field* previousField;
            std::vector<size_t> previousFieldOccurrences;

            // Because we want to check that the fields in this container are
            // placed in the order in which they're emitted in the deparser, we
            // need to walk over them in network order.
            std::vector<Slice> slicesInNetworkOrder(live_slices.begin(), live_slices.end());
            std::sort(slicesInNetworkOrder.begin(), slicesInNetworkOrder.end(),
                      [](const Slice& a, const Slice& b) {
                return a.container_bits().toOrder<Endian::Network>(a.container.size()).lo
                     < b.container_bits().toOrder<Endian::Network>(b.container.size()).lo;
            });

            for (auto& slice : slicesInNetworkOrder) {
                auto* field = slice.field;
                if (!isDeparsed(field)) continue;

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
    }

    // Check that the allocation respects parser alignment limitations.
    forAllMatching<IR::BFN::ExtractBuffer>(pipe,
                  [&](const IR::BFN::ExtractBuffer* extract) {
        int requiredAlignment = extract->extractedBits().lo % 8;
        bitrange bits;
        auto* field = phv.field(extract->dest, &bits);
        if (!field) {
            ::error("No PHV allocation for field extracted by the "
                    "parser: %1%", extract->dest);
            return;
        }

        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice& alloc) {
            nw_bitrange fieldSlice =
              alloc.field_bits().toOrder<Endian::Network>(field->size);
            nw_bitrange containerSlice =
              alloc.container_bits().toOrder<Endian::Network>(alloc.container.size());

            // The first bit of the field must have the same alignment in the
            // container as it does in the input buffer.
            if (fieldSlice.lo == 0) {
                ERROR_CHECK(containerSlice.lo % 8 == requiredAlignment,
                            "Field is extracted in the parser, but its "
                            "first container slice has an incompatible "
                            "alignment: %1%", cstring::to_cstring(field));
                return;
            }

            // Other slices (which represent a continuation of the same field
            // into other containers) must be byte aligned, since container
            // boundaries must always correspond with input buffer byte
            // boundaries.
            ERROR_CHECK(containerSlice.isLoAligned(),
                        "Field is extracted in the parser into multiple "
                        "containers, but the container slices after the first "
                        "aren't byte aligned: %1%", cstring::to_cstring(field));
        });
    });

    return false;
}


bool ValidateActions::preorder(const IR::MAU::Action *act) {
    auto tbl = findContext<IR::MAU::Table>();
    ActionAnalysis::FieldActionsMap field_actions_map;
    ActionAnalysis::ContainerActionsMap container_actions_map;
    ActionAnalysis aa(phv, phv_alloc, ad_alloc, tbl);
    if (phv_alloc)
        aa.set_container_actions_map(&container_actions_map);
    else
        aa.set_field_actions_map(&field_actions_map);
    aa.set_error_verbose();
    act->apply(aa);
    warning_found |= aa.warning_found();
    return false;
}

void ValidateActions::end_apply() {
    cstring error_message;
    if (phv_alloc)
        error_message = "PHV allocation creates a container action impossible within a Tofino ALU";
    else
        error_message = "Instruction selection creates an instruction that the rest of the "
                        "compiler cannot correctly interpret";
    if (warning_found) {
        if (stop_compiler)
            ::error(error_message);
        else
            ::warning(error_message);
    }
}


}  // namespace PHV
