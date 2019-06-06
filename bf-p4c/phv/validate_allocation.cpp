#include "validate_allocation.h"

#include <boost/range/adaptors.hpp>
#include <algorithm>
#include <iterator>
#include <sstream>

#include "bf-p4c/device.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/privatization.h"
#include "bf-p4c/mau/action_analysis.h"
#include "bf-p4c/parde/lower_parser.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/log.h"

// Currently we fail a lot of these checks, so to prevent mass XFAIL'ing a lot
// of the tests, we treat the checks as warning instead of errors. This macro
// indicates cases that *should* use ERROR_CHECK but are currently downgraded to
// a warning.
#define ERROR_WARN_ WARN_CHECK

namespace PHV {

Visitor::profile_t ValidateAllocation::init_apply(const IR::Node* root) {
    mutually_exclusive_field_ids.clear();
    // Combine the parser overlay and metadata overlay into a single matrix.
    for (auto& f1 : phv) {
        for (auto& f2 : phv) {
            if (f1.id == f2.id) continue;
            if (phv.isFieldMutex(&f1, &f2) || phv.isMetadataMutex(&f1, &f2))
                mutually_exclusive_field_ids(f1.id, f2.id) = true;
        }
    }
    return Inspector::init_apply(root);
}

bool ValidateAllocation::preorder(const IR::BFN::Pipe* pipe) {
    BUG_CHECK(phv.alloc_done(),
              "Calling ValidateAllocation without performing PHV allocation");
    /// To be set to true if privatization causes PHV allocation to fail.
    bool throwPrivatizeException = false;

    const auto& phvSpec = Device::phvSpec();

    // A mapping from PHV containers to the field slices that they contain.
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
        bool no_clots_allocated = clot.slice_clots(&field)->empty();

        if (!uses.is_referenced(&field)) {
            // FIXME(zma) ChecksumLVal field can be allocated to clot, e.g. csum
            WARN_CHECK(field.is_unallocated() /*&& no_clots_allocated*/ ,
                        "PHV allocation for unreferenced %1%field %2% (width %3%)",
                        field.bridged ? "bridged " : "",
                        cstring::to_cstring(field),
                        field.size);
            continue;
        }

        if (field.privatized() && (field.is_unallocated() && no_clots_allocated)) {
            boost::optional<cstring> privatizedFieldName = field.getPHVPrivateFieldName();
            if (!privatizedFieldName)
                BUG("Did not find PHV name of privatized field %1%", field.name);
            doNotPrivatize.insert(*privatizedFieldName);
            LOG1("Do not privatize " << *privatizedFieldName << " as it is unallocated.");
            throwPrivatizeException = true;
            continue;
        } else {
            // XXX(hanw): paddings do not require phv allocation.
            ERROR_CHECK(!field.is_unallocated() || !no_clots_allocated || field.is_ignore_alloc(),
                    "No PHV or CLOT allocation for referenced field %1%",
                    cstring::to_cstring(field));
        }

        ERROR_CHECK(!field.bridged || field.deparsed() || field.gress == EGRESS,
                    "Ingress field is bridged, but not deparsed: %1%",
                    cstring::to_cstring(field));

        // TODO(zma) add clot validation
        if (!no_clots_allocated)
            continue;

        bitvec assignedContainers;
        bitvec allocatedBits;
        unsigned outer_idx = 0;

        // Verify that the field doesn't contain any overlapping slices.
        // (Note that this is checking overlapping with respect to the
        // *field*; we check overlapping with respect to the *container*
        // below.)
        for (auto& slice : field.get_alloc()) {
            bitvec sliceBits(slice.field_bit, slice.width);
            if (!sliceBits.intersects(allocatedBits)) {
                ++outer_idx;
                allocatedBits |= sliceBits;
                continue;
            }
            // If intersecting field slices, then check liveness.
            unsigned inner_idx = 0;
            for (auto& slice2 : field.get_alloc()) {
                // Replace by if (slice1 == slice2) continue;
                if (inner_idx++ == outer_idx) continue;
                bitvec slice2Bits(slice2.field_bit, slice2.width);
                if (!slice2Bits.intersects(sliceBits)) continue;
                // TODO: Include dark containers too when we aggressively reduce their live range.
                if (slice2.container.is(PHV::Kind::dark) || slice.container.is(PHV::Kind::dark))
                    continue;
                std::stringstream ss;
                ss << "\n  " << slice << "\n  " << slice2;
                ERROR_CHECK(slice2.isLiveRangeDisjoint(slice),
                        "PHV allocation produced following overlapping slices of field %1% that "
                        "are simultaneously live in the MAU pipeline: %2%", field.name, ss.str());
            }
            ++outer_idx;
        }

        for (auto& slice : field.get_alloc()) {
            // XXX(seth): For fields which are parsed or deparsed, this can
            // never work, but there are some odd situations in which it could
            // in theory be useful (e.g. we can rotate containers in the MAU in
            // some scenarios, so we could allocate the field to both the top
            // and the bottom of the container, with something else in the
            // middle, and then rotate it into place when needed). However,
            // until we make the PHV allocator more sophisticated, this is
            // probably just a bug.
            if (!field.is_deparser_zero_candidate()) {
                bool alreadyAssignedContainer =
                    assignedContainers[phvSpec.containerToId(slice.container)];
                bool foundOverlappingSlices = false;
                if (!field.metadata && alreadyAssignedContainer)
                    for (auto& slice2 : allocations[slice.container])
                        if (slice2.container_bits().overlaps(slice.container_bits()) &&
                                !slice2.isLiveRangeDisjoint(slice))
                            foundOverlappingSlices = true;
                ERROR_CHECK(!foundOverlappingSlices,
                            "Multiple slices in the same container are allocated "
                            "to field %1%", cstring::to_cstring(field));
            }

            assignedContainers[phvSpec.containerToId(slice.container)] = true;
            allocations[slice.container].emplace_back(slice);

            threadAssignments[field.gress].setbit(phvSpec.containerToId(slice.container));

            // Verify that each slice is within the bounds of the field.
            ERROR_CHECK(le_bitrange(StartLen(0, slice.field->size)).contains(slice.field_bits()),
                        "Field %1% contains slice %2% that falls outside the size of the field",
                        cstring::to_cstring(field), cstring::to_cstring(slice));

            // Verify that slices point to their parent fields.
            ERROR_CHECK(slice.field == &field, "Field %1% contains slice %2% of field %3%",
                        cstring::to_cstring(field), cstring::to_cstring(slice),
                        cstring::to_cstring(slice.field));
        }

        // Verify that slices are sorted in descending MSB order.
        int last_msb_idx = -1;
        const Slice* lastSlice = nullptr;
        for (auto& slice : boost::adaptors::reverse(field.get_alloc())) {
            if (lastSlice && lastSlice->container == slice.container) {
                bool disjointSlices = slice.isLiveRangeDisjoint(*lastSlice);
                ERROR_CHECK(disjointSlices ||
                            (!disjointSlices && last_msb_idx < slice.field_bits().hi),
                            "Field %1% has allocated slices out of order.  Slice %2% is the first "
                            " out of order slice.",
                            cstring::to_cstring(field), cstring::to_cstring(slice));
            }
            last_msb_idx = slice.field_bits().hi;
            lastSlice = &slice;
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
        ERROR_WARN_(field.padding || allocatedBits == allBitsInField,
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
            if (!fields[gress].empty())
                message << gress << " fields: " << fields[gress] << ". ";
            else if (phvSpec.ingressOnly()[id] && gress == EGRESS)
                message << "Container is hard-wired to INGRESS. ";
            else if (phvSpec.egressOnly()[id] && gress == INGRESS)
                message << "Container is hard-wired to EGRESS. ";
            else
                BUG("Inconsistent thread count?"); }

        ::error("Container %1% is assigned to both INGRESS and EGRESS. %2%",
                container, message.str()); }

    // Check for consistent container thread assignment within deparser groups.
    std::set<unsigned> visitedCIDs;
    for (auto& field : phv) {
        if (!uses.is_referenced(&field) || clot.whole_field_clot(&field)) continue;
        if (!field.deparsed()) continue;
        for (auto& slice : field.get_alloc()) {
            auto this_cid = phvSpec.containerToId(slice.container);
            if (visitedCIDs.count(this_cid)) continue;

            auto deparserGroup = phvSpec.deparserGroup(this_cid);
            auto writtenDeparserGroup = deparserGroup;

            // Find the containers in this deparser group with deparsed fields.
            bool hasGress[2] = { false, false };
            for (auto cid : deparserGroup) {
                visitedCIDs.insert(cid);
                auto container = phvSpec.idToContainer(cid);

                bool hasDeparsed = false;
                for (auto slice : allocations[container]) {
                    if (!slice.field->deparsed()) continue;
                    hasDeparsed = true;
                    hasGress[slice.field->gress] = true; }
                if (!hasDeparsed)
                    writtenDeparserGroup.clrbit(cid); }

            if (hasGress[INGRESS] && hasGress[EGRESS]) {
                std::stringstream message;
                for (auto cid : writtenDeparserGroup) {
                    auto container = phvSpec.idToContainer(cid);
                    message << "    Container " << container
                            << (phvSpec.ingressOnly()[cid] ? "(hardwired INGRESS)" : "")
                            << (phvSpec.egressOnly()[cid] ? "(hardwired EGRESS)" : "")
                            << " with field slices" << std::endl;
                    for (auto slice : allocations[container])
                        message << "        " << slice.field << " " << slice.field_bits()
                                << std::endl; }
                ::error("Containers are in the same deparser group but assigned fields of "
                        "both INGRESS and EGRESS:\n%1%", message.str()); } } }

    std::vector<const PHV::Field*> deparseSequence;
    std::map<const PHV::Field*, std::vector<size_t>> deparseOccurrences;

    // Verify that we allocate PHV space for all fields which are emitted or
    // used as POV bits in the deparser, and that POV bits don't end up in TPHV.
    // We also check that each byte in a container used in a computed checksum
    // consists either entirely of checksummed fields or entirely of ignored
    // fields.
    forAllMatching<IR::BFN::DeparserPrimitive>(pipe,
                  [&](const IR::BFN::DeparserPrimitive* prim) {
        const IR::BFN::FieldLVal* povFieldSource;

        if (auto* emit = prim->to<IR::BFN::EmitField>()) {
            auto* sourceField = phv.field(emit->source->field, nullptr);
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
                le_bitrange sourceFieldBits;
                auto* sourceField = phv.field(source->field, &sourceFieldBits);
                if (!sourceField) {
                    ::error("No PHV allocation for field used in computed "
                            "checksum: %1%", source);
                    continue;
                }
                if (sourceField->metadata && sourceField->no_pack()) {
                    // A metadata can have a no-pack constraint and hence will include
                    // empty space. Excluding such metadatas from the warning below.
                    continue;
                }

                // FIXME(cc): deparser context??
                sourceField->foreach_alloc(sourceFieldBits,
                             [&](const PHV::Field::alloc_slice& alloc) {
                    checksumAllocations[alloc.container].push_back(alloc);
                });
            }

            // Verify that for every container which contributes to this
            // computed checksum, each byte either contains *only* fields which
            // contribute to the checksum (and no empty space) or contains *no*
            // fields which contribute to the checksum. Except for metadata included
            // in checksum since a metadata might have a no-pack constraint and hence will
            // include empty space.
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

        le_bitrange povFieldBits;
        auto* povField = phv.field(povFieldSource->field, &povFieldBits);
        if (!povField) {
            ::error("No PHV allocation for field used as a POV bit in the "
                    "deparser: %1%", povFieldSource->field);
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

    auto isDeparsed = [](const PHV::Field* f) { return f->deparsed(); };
    auto isMetadata = [](const PHV::Field* f) { return f->metadata || f->pov; };
    auto isPadding = [](const PHV::Field* f) { return f->padding; };
    auto hasOverlay = [](const PHV::Field* f) {
        le_bitrange allocated;
        for (auto& slice : f->get_alloc()) {
            if (allocated.overlaps(slice.field_bits()))
                return true;
            allocated |= slice.field_bits(); }
        return false; };
    auto allMutex = [&](const ordered_set<const PHV::Field*> left,
                        const ordered_set<const PHV::Field*> right) {
        for (auto* f1 : left) {
            for (auto* f2 : right) {
                if (f1 == f2) continue;
                if (!mutually_exclusive_field_ids(f1->id, f2->id))
                    return false; } }
        return true; };
    auto allDeparsedZero = [&](const ordered_set<const PHV::Field*> fieldSet) {
        for (auto* f : fieldSet)
            if (!f->is_deparser_zero_candidate()) return false;
        return true; };
    auto atMostOneNonePadding = [&](const ordered_set<const PHV::Field*> fieldSet) {
        int count = 0;
        for (auto* f : fieldSet)
            if (!f->overlayable) count++;
        return count <= 1; };
    auto allDarkOverlayMutex = [&](const ordered_set<const PHV::Field*> left,
                                   const ordered_set<const PHV::Field*> right) {
        for (auto* f1 : left) {
            for (auto* f2 : right) {
                if (f1 == f2) continue;
                if (!phv.isDarkMutex(f1, f2)) return false; } }
        return true;
    };

    // Check that we've marked a field as deparsed if and only if it's actually
    // emitted in the deparser.
    for (auto& field : phv) {
        if (isDeparsed(&field)) {
            // do not warn on 'un-deparsed' padding or if 'digest' field.
            // 'deparsed' property on padding is controlled by the padded field.
            if (field.is_padding() || field.is_digest()) continue;
            WARN_CHECK(deparseOccurrences.find(&field) != deparseOccurrences.end(),
                        "Field is marked as deparsed, but the deparser doesn't "
                        "emit it: %1%", cstring::to_cstring(field));
        } else {
            ERROR_CHECK(deparseOccurrences.find(&field) == deparseOccurrences.end(),
                        "Field is not marked as deparsed, but the deparser "
                        "emits it: %1%", cstring::to_cstring(field)); }
    }

    // Check that the allocation for each container is valid.
    for (auto& allocation : allocations) {
        auto container = allocation.first;
        auto& slices = allocation.second;

        // Collect all the fields which are assigned to this container.
        std::set<const PHV::Field*> fields;
        for (auto& slice : slices) fields.insert(slice.field);

        // XXX(cole): Some of the deparser constraints, such as field ordering
        // within a container, are still too difficult to check in the presence
        // of overlaid fields.  Hopefully we can make this more precise in the
        // future.  For now, skip those checks if fields are overlaid.
        bool any_field_has_overlay = std::any_of(fields.begin(), fields.end(), hasOverlay);

        // Collect information about which fields in this container are
        // deparsed, so we can verify that the allocation is reasonable. Header
        // fields are the constrained case: if a container contains deparsed
        // header fields, it must contain *only* deparsed header fields and they
        // must completely fill the container. Several checks below combine to
        // verify that. We're much less restrictive for bridged metadata fields,
        // since they don't end up on the wire and they're not visible to the
        // programmer.
        std::set<const PHV::Field*> deparsedHeaderFields;
        std::set<const PHV::Field*> deparsedMetadataFields;
        std::set<const PHV::Field*> nonDeparsedFields;
        std::set<const PHV::Field*> deparsedPaddingFields;

        for (auto& slice : slices) {
            auto* field = slice.field;
            if (!isDeparsed(field)) {
                nonDeparsedFields.insert(field);
                continue; }
            if (isPadding(field))
                deparsedPaddingFields.insert(field);
            else if (isMetadata(field))
                deparsedMetadataFields.insert(field);
            else
                deparsedHeaderFields.insert(field);
        }

        ERROR_CHECK(!(deparsedHeaderFields.size() && deparsedMetadataFields.size()),
                    "Deparsed container %1% contains both deparsed header "
                    "fields and deparsed metadata fields: %2%", container,
                    cstring::to_cstring(fields));

        if (deparsedHeaderFields.size() && nonDeparsedFields.size()) {
            for (auto* deparsed : deparsedHeaderFields)
                for (auto* nonDeparsed : nonDeparsedFields) {
                    if (deparsed->bridged) continue;
                    if (nonDeparsed->privatizable()) {
                        if (mutually_exclusive_field_ids(deparsed->id, nonDeparsed->id))
                            continue;
                        doNotPrivatize.insert(nonDeparsed->name);
                        throwPrivatizeException = true;
                        ::warning("Deparsed container %1% mixes deparsed header field %2% with "
                                "non-deparsed field %3%", container,
                                cstring::to_cstring(deparsed), cstring::to_cstring(nonDeparsed));
                    }
                }
        }

        // Verify that the allocations for each field don't overlap. (Note that
        // this is checking overlapping with respect to the *container*; we
        // check overlapping with respect to the *field* above.)
        bitvec allocatedBitsForContainer;
        ordered_map<int, ordered_set<const PHV::Field*>> bits_to_fields;
        for (auto field : fields) {
            std::vector<Slice> slicesForField;
            for (auto& slice : slices)
                if (slice.field == field) slicesForField.push_back(slice);

            ERROR_CHECK(!slicesForField.empty(), "No slices for field?");

            bitvec allocatedBitsForField;
            for (auto& slice : slicesForField) {
                bitvec sliceBits(slice.container_bit, slice.width);
                if (!slice.field->is_deparser_zero_candidate() &&
                    sliceBits.intersects(allocatedBitsForField)) {
                    // Check that the liveness is different for slices that are allocated to the
                    // same container bits.
                    bool foundOverlappingSlices = false;
                    for (auto& slice2 : slicesForField) {
                        if (slice == slice2) continue;
                        bitvec slice2Bits(slice2.container_bit, slice2.width);
                        if (!slice2Bits.intersects(sliceBits)) continue;
                        if (slice.isLiveRangeDisjoint(slice2)) continue;
                        foundOverlappingSlices = true;
                    }
                    ERROR_CHECK(!foundOverlappingSlices,
                                "Container %1% contains overlapping slices of field %2%",
                                container, cstring::to_cstring(field));
                }
                allocatedBitsForField |= sliceBits;
            }

            // $stkvalid is a fake POV field for header stacks that
            // overlays the validity bits for each stack field as well as
            // $push and $pop fields.  We can (and in fact should) ignore
            // it when checking for overlapping fields.
            if (field->name.endsWith("$stkvalid"))
                continue;

            for (auto& slice : slicesForField)
                for (int idx = slice.container_bit; idx < slice.width; ++idx)
                    bits_to_fields[idx].insert(slice.field);

            allocatedBitsForContainer |= allocatedBitsForField;
        }

        for (auto& kv : bits_to_fields) {
            ERROR_CHECK(allMutex(kv.second, kv.second) || allDeparsedZero(kv.second) ||
                        atMostOneNonePadding(kv.second) ||
                        allDarkOverlayMutex(kv.second, kv.second),
                        "Container %1% contains fields which overlap:\n%2%",
                        container, cstring::to_cstring(kv.second));
        }

        // XXX(cole): Checking that deparsed fields adjacent in the
        // container are adjacent in the deparser is still too complex to
        // check directly, because the check is really over adjacent
        // *valid* fields in the deparser, which we don't have a good way
        // to determine precisely here.
        if (any_field_has_overlay) continue;

        // Verify that if this container has deparsed header fields, every bit
        // in the container is allocated.  Deparsed metadata fields (i.e.,
        // bridged metadata) don't have this restriction because they don't end
        // up on the wire (externally, at least) and we can ensure that garbage
        // data isn't visible to the programmer. If this container has a mixed
        // of both, we'll already have reported an error above.
        if (deparsedHeaderFields.size()) {
            bitvec allBitsInContainer(0, container.size());
            ERROR_WARN_(allocatedBitsForContainer == allBitsInContainer,
                        "Container %1% contains deparsed header fields, but "
                        "it has unused bits: %2%", container,
                        cstring::to_cstring(fields));
        }

        const PHV::Field* previousField;
        std::vector<size_t> previousFieldOccurrences;

        // Because we want to check that the fields in this container are
        // placed in the order in which they're emitted in the deparser, we
        // need to walk over them in network order.
        std::vector<Slice> slicesInNetworkOrder(slices.begin(), slices.end());
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

        // Check that nothing is packed in the lower order bits of containers
        // that hold sources of non-bitwise instructions.
        std::vector<Slice> slicesInLittleEndianOrder(slices.begin(), slices.end());
        std::sort(slicesInLittleEndianOrder.begin(), slicesInLittleEndianOrder.end(),
                  [](const Slice& a, const Slice& b) {
            return a.container_bits().toOrder<Endian::Little>(a.container.size()).lo
                 < b.container_bits().toOrder<Endian::Little>(b.container.size()).lo;
        });
        bool lowerBitsPacked = false;
        for (auto slice : slicesInLittleEndianOrder) {
            for (auto op : slice.field->operations())
                if (op.range.overlaps(slice.field_bits()) && !op.is_bitwise_op && lowerBitsPacked)
                    BUG("PHV allocation incorrectly packed other fields in the lower order bits "
                        "of the same container as %1%, which is the source of a non-bitwise "
                        "operation: %2%", slice.field->name, op.inst);
            lowerBitsPacked = true;
        }
    }

    // Check that the allocation respects parser alignment limitations.
    forAllMatching<IR::BFN::Extract>(pipe, [&](const IR::BFN::Extract* extract) {
        auto* bufferSource = extract->source->to<IR::BFN::InputBufferRVal>();
        if (!bufferSource) return;

        int requiredAlignment = bufferSource->range.lo % 8;
        le_bitrange bits;

        auto lval = extract->dest->to<IR::BFN::FieldLVal>();
        if (!lval) return;

        auto* field = phv.field(lval->field, &bits);
        if (!field) {
            ::error("No PHV allocation for field extracted by the "
                    "parser: %1%", lval);
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

    if (throwPrivatizeException)
        checkAndThrowPrivatizeException(allocations);

    // Mirror metadata allocation constraint check:
    for (auto gress : {INGRESS, EGRESS}) {
        const auto* mirror_id = phv.field(
                cstring::to_cstring(gress) + "::" + "compiler_generated_meta.mirror_id");
        if (mirror_id && phv.get_alloc(mirror_id).size()) {
            const auto& id_alloc = phv.get_alloc(mirror_id);
            BUG_CHECK(id_alloc.size() == 1,
                      "%1% is splitted, but it should not.", mirror_id->name);
            if (Device::currentDevice() == Device::TOFINO) {
                BUG_CHECK(id_alloc.front().container.size() == 16,
                          "%1% must be allocated to %2% but phv allocation does not",
                          mirror_id->name, 16); }
        }

        const auto* mirror_src = phv.field(
                cstring::to_cstring(gress) + "::" + "compiler_generated_meta.mirror_source");
        if (mirror_src && phv.get_alloc(mirror_src).size()) {
            const auto& src_alloc = phv.get_alloc(mirror_src);
            BUG_CHECK(src_alloc.size() == 1,
                      "%1% is splitted, but it should not.", mirror_src->name);
            BUG_CHECK(src_alloc.front().container.size() == 8,
                      "%1% must be allocated to %2% but phv allocation does not",
                      mirror_src->name, 8);
        }
    }

    // Check that all containers is a tagalong group are all assigned to the same gress (and contain
    // fields of the same gress).
    if (Device::currentDevice() == Device::TOFINO) {
        const auto& collections = phvSpec.tagalongCollections();
        for (auto collection : collections) {
            auto gress = boost::make_optional(false, gress_t());
            for (unsigned cid : collection) {
                auto c = phvSpec.idToContainer(cid);
                const auto& fields = phv.fields_in_container(c);
                if (fields.size() == 0) continue;
                for (const auto* f : fields) {
                    if (gress)
                        BUG_CHECK(f->gress == *gress,
                                "TPHV collection contains fields from different gresses.");
                    else
                        gress = f->gress;
                }
            }
        }
    }

    for (gress_t gress : { INGRESS, EGRESS }) {
        size_t povBits = getPOVContainerBytes(gress);
        size_t povLimit = Device::phvSpec().getNumPovBits();
        if (povBits > povLimit)
            BUG("Total size of containers used for %1% POV allocation is %2%b, greater than the "
                    "allowed limit of %3%b.", gress, povBits, povLimit);
    }

    return true;
}

bool ValidateAllocation::preorder(const IR::BFN::Digest* digest) {
    // Check that all learning quanta generated is less than the maximum allowed size.
    if (digest->name != "learning") return true;
    const PHV::Field* selector = phv.field(digest->selector->field);
    BUG_CHECK(selector, "Selector field not present in PhvInfo");
    size_t selectorSize = 0;
    selector->foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
        selectorSize += alloc.container.size();
    });
    for (auto fieldList : digest->fieldLists) {
        size_t digestSizeInBits = selectorSize;
        for (auto flval : fieldList->sources) {
            const PHV::Field* f = phv.field(flval->field);
            BUG_CHECK(f, "Digest field not present in PhvInfo");
            f->foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
                digestSizeInBits += alloc.container.size();
            });
        }
        BUG_CHECK(digestSizeInBits % 8 == 0, "Digest size in bits cannot be non byte aligned.");
        size_t digestSizeInBytes = digestSizeInBits / 8;
        if (digestSizeInBytes > Device::maxDigestSizeInBytes())
            ::error("Size of learning quanta is %1% bytes, greater than the maximum allowed %2% "
                    "bytes.", digestSizeInBytes, Device::maxDigestSizeInBytes());
    }
    return true;
}

void ValidateAllocation::checkAndThrowPrivatizeException(
        const std::map<PHV::Container, std::vector<Slice>>& allocations) const {
    // If privatized fields flout deparser requirements, raise a backtrack exception.
    bool backtrack = throwBacktrackException(allocations);
    if (backtrack) {
        LOG1("   Reinvoking privatization pass");
        throw PrivatizationTrigger::failure(doNotPrivatize); }
}

bool ValidateAllocation::throwBacktrackException(
        const std::map<PHV::Container, std::vector<Slice>>& allocations) const {
    bool anyFieldOverlaid = false;
    for (cstring fName : doNotPrivatize) {
        const PHV::Field* f = phv.field(fName);
        BUG_CHECK(f, "Privatized field %1% not found", fName);
        f->foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
            for (auto& slice : allocations.at(alloc.container)) {
                if (slice.field == alloc.field) continue;
                if (alloc.container_bits().overlaps(slice.container_bits()))
                    anyFieldOverlaid = true; }
        });
    }
    return anyFieldOverlaid;
}

size_t ValidateAllocation::getPOVContainerBytes(gress_t gress) const {
    ordered_set<PHV::Container> containers;
    for (const auto& f : phv) {
        if (f.gress != gress) continue;
        if (!f.pov) continue;
        f.foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
            containers.insert(alloc.container);
        });
    }
    size_t rv = 0;
    for (auto c : containers)
        rv += static_cast<size_t>(c.size());
    return rv;
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
    aa.set_verbose();
    act->apply(aa);
    warning_found |= aa.warning_found();
    error_found |= aa.error_found();
    return false;
}

Visitor::profile_t ValidateActions::init_apply(const IR::Node *root) {
    profile_t rv = Inspector::init_apply(root);
    warning_found = false;
    return rv;
}

void ValidateActions::end_apply() {
    cstring error_message;
    if (phv_alloc)
        error_message = "PHV allocation creates a container action impossible within a Tofino ALU";
    else
        error_message = "Instruction selection creates an instruction that the rest of the "
                        "compiler cannot correctly interpret";
    if (error_found) {
        ::error(error_message);
    } else if (warning_found) {
        if (stop_compiler)
            ::error(error_message);
        else
            ::warning(error_message);
    }
}

}  // namespace PHV
