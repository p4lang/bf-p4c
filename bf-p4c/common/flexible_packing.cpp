#include <cstring>
#include <algorithm>
#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/lib/pad_alignment.h"
#include "bf-p4c/phv/phv_fields.h"

// XXX(Deep): BRIG-333
// We can do better with these IR::BFN::DeparserParameters in terms of packing. This IR type is only
// used to represent intrinsic metadata in ingress and egress at the moment. As noted in the
// comments in line 698 in phv_fields.cpp, the constraints on bottom_bit for some of these TM
// metadata is not necessary. We can theoretically place certain TM metadata field, such as
// bypass_egress to any bit in a byte. The implication for bridge metadata packing is that
// bypass_egress could be packed with any field anywhere. There are a few other TM metadata with the
// same property: ct_disable, ct_mcast, qid, icos, meter_color, deflect_on_drop, copy_to_cpu_cos.
// BRIG-333 is tracking this issue.
bool GatherDeparserParameters::preorder(const IR::BFN::DeparserParameter* p) {
    const PHV::Field* f = phv.field(p->source->field);
    BUG_CHECK(f, "Field %1% not found while gathering deparser parameters", p->source->field);
    LOG5("    Deparser parameter identified: " << f);
    params.insert(f);
    return true;
}

// TODO: Remove reliance on phase0 parser state name by visiting Phase0 node in
// IR::BFN::Parser and use phase0->fields to gather Phase0 fields. The fields
// must be converted from an IR::StructField to a PHV::Field.
// TODO: Another chance for optimization is by allowing flexible packing of
// fields. Right now, the fields are packed to Phase0 bit width (Tofino = 64 and
// JBAY = 128) with padding inserted. This does not allow flexibility while
// packing fields into containers. The packing is specified in tna.cpp &
// arch/phase0.cpp - canPackDataIntoPhase0() method. The packing code can be
// removed and we can work with only the fields in Phase0. Packing width can be
// determined by Device::pardeSpec().bitPhase0Width()
bool GatherPhase0Fields::preorder(const IR::BFN::ParserState* p) {
    // Not a phase 0 parser state
    if (p->name != PHASE0_PARSER_STATE_NAME)
        return true;
    // For phase 0 parser state, detect the fields written to.
    for (auto s : p->statements) {
        auto* e = s->to<IR::BFN::Extract>();
        if (!e) continue;
        auto* dest = e->dest->to<IR::BFN::FieldLVal>();
        if (!dest) continue;
        const auto* f = phv.field(dest->field);
        if (!f) continue;
        noPackFields.insert(f); }
    return true;
}

// TODO: if a field is used in both bridging and mirror/resubmit/digest, we do
// not pack these fields with other fields. The compiler should be able to do
// better.
bool GatherPhase0Fields::preorder(const IR::BFN::DigestFieldList* d) {
    for (auto source : d->sources) {
        const auto* field = phv.field(source->field);
        if (!field) continue;
        noPackFields.insert(field);
    }
    return false;
}

bool GatherParserExtracts::preorder(const IR::BFN::Extract* e) {
    auto* fieldLVal = e->dest->to<IR::BFN::FieldLVal>();
    if (!fieldLVal) return true;
    auto* f = phv.field(fieldLVal->field);
    if (!f) return true;
    auto* source = e->source->to<IR::BFN::SavedRVal>();
    if (!source) return true;
    auto* sourceField = phv.field(source->source);
    if (!sourceField) return true;
    parserAlignedFields[f].insert(sourceField);
    LOG5("    Initialization due to SavedRVal in parser: " << f);
    return true;
}

/**
 * repackedTypes is shared between RepackDigestFieldList and RepackFlexHeaders.
 * It is cleared here, and maintained when running RepackFlexHeaders.
 * XXX(hanw): assumes RepackDigestFieldList is before RepackFlexHeaders.
 */
Visitor::profile_t RepackDigestFieldList::init_apply(const IR::Node* root) {
    repackedTypes.clear();
    return Transform::init_apply(root);
}

Visitor::profile_t RepackFlexHeaders::init_apply(const IR::Node* root) {
    egressBridgedMap.clear();
    reverseEgressBridgedMap.clear();
    extractedTogether.clear();
    fieldAlignmentMap.clear();
    ingressFlexibleTypes.clear();
    headerToFlexibleStructsMap.clear();
    repackedHeaders.clear();
    originalHeaders.clear();
    paddingFieldNames.clear();

    if (LOGGING(1))
        LOG1("\tNumber of bridged fields: " << fields.bridged_to_orig.size());
    for (auto kv : fields.bridged_to_orig) {
        cstring origName = getEgressFieldName(kv.second);
        cstring bridgedName = getEgressFieldName(kv.first);
        egressBridgedMap[origName] = bridgedName;
        reverseEgressBridgedMap[bridgedName] = origName;
    }

    if (LOGGING(5)) {
        if (fields.orig_to_bridged.size() > 0) {
            LOG5("\n\tPrinting orig to bridged");
            for (auto kv : fields.orig_to_bridged)
                LOG5("\t  " << kv.first << " : " << kv.second);
        }
        if (fields.bridged_to_orig.size() > 0) {
            LOG5("\n\tPrinting bridged to orig");
            for (auto kv : fields.bridged_to_orig)
                LOG5("\t  " << kv.first << " : " << kv.second);
        }
        if (fields.bridged_to_external_name.size() > 0) {
            LOG5("\n\tPrinting bridged to external");
            for (auto kv : fields.bridged_to_external_name)
                LOG5("\t  " << kv.first << " : " << kv.second);
        }
        if (fields.orig_to_bridged_name.size() > 0) {
            LOG5("\n\tPrinting orig to bridged");
            for (auto kv : fields.orig_to_bridged_name)
                LOG5("\t  " << kv.first << " : " << kv.second);
        }
    }
    if (LOGGING(3) && egressBridgedMap.size() > 0) {
        LOG3("\n\tPrinting egress bridged to external");
        for (auto kv : egressBridgedMap)
            LOG3("\t  " << kv.first << "\t" << kv.second); }

    return Transform::init_apply(root);
}

cstring RepackFlexHeaders::getNonBridgedEgressFieldName(cstring fName) const {
    cstring egressBridgedName;
    if (fName.startsWith(EGRESS_FIELD_PREFIX))
        egressBridgedName = fName;
    else
        egressBridgedName = getEgressFieldName(fName);
    for (auto kv : egressBridgedMap) {
        if (kv.second == egressBridgedName)
            return kv.first;
    }
    return egressBridgedName;
}

int RepackFlexHeaders::getHeaderBits(const IR::HeaderOrMetadata* h) const {
    int rv = 0;
    for (auto f : h->type->fields)
        rv += f->type->width_bits();
    return rv;
}

int RepackFlexHeaders::getHeaderBits(const IR::BFN::DigestFieldList* d) const {
    int rv = 0;
    for (auto f : d->type->fields)
        rv += f->type->width_bits();
    return rv;
}

int RepackFlexHeaders::getHeaderBytes(const IR::HeaderOrMetadata* h) const {
    int bits = getHeaderBits(h);
    BUG_CHECK(bits % 8 == 0, "Serializer packing produces a nonbyte-aligned header %1%", h->name);
    return (bits / 8);
}

void RepackFlexHeaders::printNoPackConstraint(
        cstring errorMessage,
        const PHV::Field* f1,
        const PHV::Field* f2) const {
    LOG4("\t" << errorMessage << ": " << f1->name << " (" << f1->id << ") (" << f1->size << "b), "
              << f2->name << " (" << f2->id << ") (" << f2->size << "b)");
}

ordered_set<const IR::MAU::Action*> RepackFlexHeaders::fieldsAccessedSameAction(
        const PHV::Field* field1,
        const PHV::Field* field2,
        const ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Action*>>& acts,
        bool written) const {
    ordered_set<const IR::MAU::Action*> rs;
    if (!acts.count(field1))
        return rs;
    if (!acts.count(field2))
        return rs;
    if (acts.at(field1).size() == 0 || acts.at(field2).size() == 0)
        return rs;
    for (const IR::MAU::Action* a1 : acts.at(field1)) {
        if (!written && a1->name == "act") continue;
        for (const IR::MAU::Action* a2 : acts.at(field2)) {
            if (!written && a2->name == "act") continue;
            if (a1 == a2) {
                LOG5("\t\t" << field1->name << " and " << field2->name << " are " <<
                            (written ?  "written" : "read") << " in the same action " << a1->name);
                rs.insert(a1); } } }
    return rs;
}

// If the fields @f1 and @f2 are to be packed together, this returns a map of the field and its
// corresponding required alignment.
boost::optional<ordered_map<const PHV::Field*, int>> RepackFlexHeaders::mustBePackedTogether(
        const PHV::Field* f1,
        const PHV::Field* f2,
        const ordered_set<const IR::MAU::Action*>& actions) const {
    ordered_map<const PHV::Field*, int> reqAlignment;
    for (const auto* a : actions) {
        auto dest1 = actionConstraints.field_destination(f1, a);
        auto dest2 = actionConstraints.field_destination(f2, a);
        BUG_CHECK(dest1 && dest2, "One of fields %1% and %2% not written in %3%", f1->name,
                  f2->name, a->name);
        LOG5("\t\t" << f1->name << " written by " << (*dest1)->name << " in " << a->name);
        LOG5("\t\t" << f2->name << " written by " << (*dest2)->name << " in " << a->name);
        int totalSize = (*dest1)->size + (*dest2)->size;
        bool packFieldsTogether = false;
        // If the destinations are in the same byte and there are other fields in the same byte.
        if (((*dest1)->header() == (*dest2)->header()) && (((*dest1)->offset / 8) ==
                                                           ((*dest2)->offset / 8))) {
            if (totalSize % 8 != 0)
                packFieldsTogether = true;
        }
        if (!packFieldsTogether) continue;
        LOG4("\t\tMust pack fields " << f1->name << " and " << f2->name << " together.");
        int minOffset = ((*dest1)->offset < (*dest2)->offset) ? (*dest1)->offset : (*dest2)->offset;
        int leftLimit = (minOffset / 8) * 8;
        LOG5("\t\t\tminOffset: " << minOffset << ", Left limit: " << leftLimit);
        LOG5("\t\t\tOffset of " << (*dest1)->name << " : " << (*dest1)->offset);
        LOG5("\t\t\tOffset of " << (*dest2)->name << " : " << (*dest2)->offset);
        int f1Alignment = (*dest1)->offset - leftLimit;
        int f2Alignment = (*dest2)->offset - leftLimit;
        if (reqAlignment.count(f1) && reqAlignment.at(f1) != f1Alignment) {
            LOG5("\t\t\tConflicting alignment requirements detected for field " << f1->name);
            return boost::none;
        }
        if (reqAlignment.count(f2) && reqAlignment.at(f2) != f2Alignment) {
            LOG5("\t\t\tConflicting alignment requirements detected for field " << f2->name);
            return boost::none;
        }
        reqAlignment[f1] = f1Alignment;
        reqAlignment[f2] = f2Alignment;
        LOG5("\t\tRequired alignment for " << f1->name << " : " << f1Alignment);
        LOG5("\t\tRequired alignment for " << f2->name << " : " << f2Alignment);
    }
    if (reqAlignment.size() == 0) return boost::none;
    return reqAlignment;
}

SymBitMatrix RepackFlexHeaders::mustPack(const ordered_set<const PHV::Field*>& fields) const {
    ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Action*>> reads;
    ordered_map<const PHV::Field*, const PHV::Field*> otherGressMapping;
    SymBitMatrix mustPackMatrix;
    ordered_map<const PHV::Field*, int> alignment;
    // Populate set of egress fields.
    ordered_set<const PHV::Field*> egressFields;
    for (const auto* f : fields) {
        cstring egressFieldName = getNonBridgedEgressFieldName(f->name);
        BUG_CHECK(egressFieldName, "No egress version of the field %1%", f->name);
        const auto* egressField = phv.field(egressFieldName);
        if (egressField) {
            egressFields.insert(egressField);
            otherGressMapping[egressField] = f;
        } else {
            LOG4("Did not find field " << egressFieldName);
        }
    }

    // Figure out the actions reading each bridged metadata field.
    for (const auto* f : fields)
        reads[f] = actionConstraints.actions_reading_fields(f);
    for (const auto* f : egressFields)
        reads[f] = actionConstraints.actions_reading_fields(f);

    // Figure out must pack for bridged fields that are read in the same action.
    for (const auto* f1 : fields) {
        for (const auto* f2 : fields) {
            if (f1 == f2) continue;
            auto commonActions = fieldsAccessedSameAction(f1, f2, reads, false /* reads */);
            if (commonActions.size() == 0) continue;
            LOG5("\t" << f1->name << " and " << f2->name << " are read in the same action.");
            auto packReq = mustBePackedTogether(f1, f2, commonActions);
            if (!packReq) continue;
            LOG5("\t" << f1->name << " and " << f2->name << " must be packed together.");
            mustPackMatrix(f1->id, f2->id) = true;
            for (auto kv : *packReq)
                alignment[kv.first] = kv.second;
        }
    }
    if (alignment.size() > 0) {
        LOG4("\tPrinting alignment map");
        for (auto kv : alignment)
            LOG4("\t  " << kv.first->name << " : " << kv.second);
    }

    // Figure out must pack for bridged fields that are read in the same action (for the other
    // gress).
    for (const auto* f1 : egressFields) {
        for (const auto* f2 : egressFields) {
            if (f1 == f2) continue;
            auto commonActions = fieldsAccessedSameAction(f1, f2, reads, false /* reads */);
            if (commonActions.size() == 0) continue;
            LOG5("\t" << otherGressMapping.at(f1)->name << " and " << otherGressMapping.at(f2)->name
                      << " are read in the same action.");
            auto packReq = mustBePackedTogether(f1, f2, commonActions);
            if (!packReq) continue;
            LOG5("\t" << otherGressMapping.at(f1)->name << " and " << otherGressMapping.at(f2)->name
                      << " must be packed together.");
            const auto* ingressField1 = otherGressMapping.at(f1);
            const auto* ingressField2 = otherGressMapping.at(f2);
            bool mustPackValue = true;
            for (auto kv : *packReq) {
                const auto* ingressField = otherGressMapping.at(kv.first);
                LOG5("\t\tConsidering field " << ingressField->name);
                if (alignment.count(ingressField)) {
                    LOG5("\t\t" << alignment.at(ingressField) << ", " << kv.second);
                    if (alignment.at(ingressField) != kv.second) {
                        alignment.erase(ingressField1);
                        alignment.erase(ingressField2);
                        mustPackValue = false;
                    }
                }
                alignment[ingressField] = kv.second;
                LOG5("\t\tSetting alignment for " << ingressField->name << " to " << kv.second);
            }
            LOG4("\tmustPackMatrix(" << ingressField1->name << ", " << ingressField2->name << ") :"
                                     << mustPackValue);
            mustPackMatrix(ingressField1->id, ingressField2->id) = mustPackValue;
        }
    }
    return mustPackMatrix;
}

SymBitMatrix
RepackFlexHeaders::bridgedActionAnalysis(std::vector<const PHV::Field*>& nonByteAlignedFields) {
    ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Action*>> fieldToActionWrites;
    ordered_set<const PHV::Field*> fieldsToBePacked;
    for (auto f : nonByteAlignedFields) {
        fieldsToBePacked.insert(f);
        fieldToActionWrites[f] = actionConstraints.actions_writing_fields(f); }

    SymBitMatrix mustPackMatrix = mustPack(fieldsToBePacked);

    // Conservatively, mark fields that are written in the same action as do not pack. Also,
    for (const auto* field1 : nonByteAlignedFields) {
        bool isSpecialityDest1 = actionConstraints.hasSpecialityReads(field1);
        bool isMoveOnlyDest1 = actionConstraints.move_only_operations(field1);
        bool hasNoPack1 = alloc.isNoPackField(field1->name);
        BUG_CHECK(fieldToActionWrites.count(field1), "Did not find actions writing to field %1%",
                  field1->name);
        for (const auto* field2 : nonByteAlignedFields) {
            BUG_CHECK(fieldToActionWrites.count(field2), "Did not find actions writing to field "
                                                         "%1%", field2->name);
            bool isSpecialityDest2 = actionConstraints.hasSpecialityReads(field2);
            bool isMoveOnlyDest2 = actionConstraints.move_only_operations(field2);
            bool hasNoPack2 = alloc.isNoPackField(field2->name);
            if (field1 == field2) {
                continue;
            } else if (mustPackMatrix(field1->id, field2->id)) {
                doNotPack(field1->id, field2->id) = true;
                printNoPackConstraint("MUST PACK", field1, field2);
            } else if (hasNoPack1 || hasNoPack2) {
                // Do not pack fields together if one or both of them is specified as no-pack
                // because of backtracking to bridged metadata packing.
                doNotPack(field1->id, field2->id) = true;
                printNoPackConstraint("Backtracking NO-PACK", field1, field2);
            } else if (field1->is_marshaled() || field2->is_marshaled()) {
                // Do not pack fields together if one or both of them is mirrored/resubmitted.
                doNotPack(field1->id, field2->id) = true;
                printNoPackConstraint("Marshaled", field1, field2);
            } else if (isSpecialityDest1 || isSpecialityDest2) {
                // Do not pack fields together if one or both of them is the result of a speciality
                // operation (HASH_DIST, METER_ALU, METER_COLOR, or RANDOM) and they are written in
                // the same action.
                auto commonActions = fieldsAccessedSameAction(field1, field2, fieldToActionWrites);
                if (commonActions.size() != 0) {
                    doNotPack(field1->id, field2->id) = true;
                    printNoPackConstraint("Speciality Destination written in the same action(s)",
                                          field1, field2);
                }
            } else if (!isMoveOnlyDest1 || !isMoveOnlyDest2) {
                // Do not pack fields together if one or both of them is written by a non-MOVE
                // operation.
                doNotPack(field1->id, field2->id) = true;
                printNoPackConstraint("Non-move operation", field1, field2);
            } else if (actionConstraints.hasPackConflict(field1, field2)) {
                // Do not pack fields together if the pair has a pack conflict, as reported by the
                // PackConflicts pass.
                doNotPack(field1->id, field2->id) = true;
                printNoPackConstraint("Pack conflict", field1, field2);
            } else if (noPackFields.count(field1) || noPackFields.count(field2)) {
                // Do not pack fields together if one or more of them is initialized in phase 0.
                doNotPack(field1->id, field2->id) = true;
                printNoPackConstraint("Phase 0 conflict", field1, field2); } } }
    return mustPackMatrix;
}

ordered_map<const PHV::Field*, int> RepackFlexHeaders::packWithField(
        const int alignment,
        const PHV::Field* field1,
        const ordered_set<const PHV::Field*>& candidates,
        const ordered_set<const PHV::Field*>& alreadyPackedFields,
        const ordered_map<const PHV::Field*, le_bitrange>& alignmentConstraints,
        const ordered_map<const PHV::Field*, std::set<int>>&
        conflictingAlignmentConstraints,
        const SymBitMatrix& mustPack) const {
    static ordered_map<const PHV::Field*, int> emptyMap;
    ordered_map<const PHV::Field*, int> rv;
    ordered_set<const PHV::Field*> potentiallyPackableFields;
    potentiallyPackableFields.insert(field1);
    LOG4("\tPack with field: " << field1->name << " alignment: " << alignment);

    ordered_set<const PHV::Field*> mustPackFields;
    for (auto field2 : candidates) {
        if (field1 == field2) continue;
        if (mustPack(field1->id, field2->id)) {
            LOG4("\t\tDetected must pack field " << field2->name);
            mustPackFields.insert(field2);
        }
    }

    int totalMustPackSize = field1->size;
    for (auto f : mustPackFields)
        totalMustPackSize += f->size;
    if (alignment == 0) return emptyMap;
    // trying to pack to the nearest byte boundary. In case there are must pack fields, try to pack
    // to the nearest byte boundary for the total size of the must pack set.
    int bitsize = 0;
    if (mustPackFields.size() == 0)
        bitsize = alignment + field1->size;
    else
        bitsize = 8 * ROUNDUP(totalMustPackSize, 8);
    // represents set of bits that have not yet been assigned to fields.
    std::set<int> unOccupied;
    for (int i = 0; i < bitsize; i++)
        unOccupied.insert(i);

    // Check packing possibility of every candidate field. By the end of this loop, all fields that
    // can potentially be packed with the given field @f.
    for (auto field2 : candidates) {
        if (field1 == field2) continue;
        // If the field under consideration has already been packed, then ignore it.
        if (alreadyPackedFields.count(field2)) {
            LOG4("\t\tB. Already packed " << field2->name);
            continue; }
        if (field2->size > alignment) {
            LOG4("\t\tC. Cannot pack " << field2->name << " within the same byte.");
            continue; }
        if (doNotPack(field1->id, field2->id)) {
            LOG4("\t\tD. Detected no pack condition for " << field1->name << " and " <<
                                                          field2->name);
            continue; }
        if (conflictingAlignmentConstraints.count(field2)) {
            LOG5("\t\tG. Detected field with conflicting alignment requirements " << field2->name);
            continue; }
        bool packingOkay = true;
        // Ensure that the field under consideration can be packed with every other field in the
        // potentiallyPackableFields set.
        for (auto field3 : potentiallyPackableFields) {
            if (doNotPack(field2->id, field3->id)) {
                LOG4("\t\tD. Detected no pack condition for " << field1->name << " and " <<
                                                              field2->name);
                packingOkay = false;
                break; } }
        // packingOkay is false if the field under consideration cannot be packed with at least one
        // of the potentially packable fields.
        if (!packingOkay)
            continue;
        // Check the action analysis constraints corresponding to bridged fields packing. However,
        // since the checkBridgedPackingConstraints() method expects a set of PHV::Field* objects,
        // we need to construct the set out of all the StructField* objects first.
        ordered_set<const PHV::Field*> packing;
        packing.insert(field1);
        for (auto* f : potentiallyPackableFields)
            packing.insert(f);
        packing.insert(field2);
        if (!actionConstraints.checkBridgedPackingConstraints(packing)) {
            LOG4("\t\tE. Packing violates action constraints " << field2->name);
            continue; }
        LOG4("\t\tF. Potentially packable field " << field2->name);
        potentiallyPackableFields.insert(field2); }

    // Print all fields that can be potentially packed with the given field f.
    if (LOGGING(4)) {
        LOG4("\t  Found " << potentiallyPackableFields.size() << " potentially packable fields.");
        LOG4("\t  Attempting to packing within " << bitsize << " bits.");
        for (auto* f : potentiallyPackableFields) {
            std::stringstream ss;
            ss << "\t\t";
            if (alignmentConstraints.count(f))
                ss << "* ";
            ss << f;
            LOG4(ss.str()); }
        if (mustPackFields.size() > 0) {
            LOG4("\t  Must pack fields are:");
            for (auto f : mustPackFields)
                LOG4("\t\t" << f->name);
        }
    }

    // Check if any of the potentially packable fields have mutually conflicting alignment
    // requirements. For instance, field A may be required at bit position 2, which field B may be
    // required at bit positions 1-3 (3 bit field). In that case, A and B can never be packed in the
    // same byte. After a call to checkPotentialPackAlignmentReqs(), alignmentConflicts represents
    // the set of fields that have conflicting alignment requirements.
    ordered_set<const PHV::Field*> alignmentConflicts =
        checkPotentialPackAlignmentReqs(alignmentConstraints, potentiallyPackableFields, field1);
    ordered_set<const PHV::Field*> packedFields;
    // Pack the base field f first, if it has an alignment constraint.
    if (alignmentConstraints.count(field1)) {
        int lo = alignmentConstraints.at(field1).lo;
        for (int i = lo; i < lo + field1->size; i++)
            unOccupied.erase(i);
        LOG4("\t\t  Allocating base field " << field1->name << " to bit " << lo);
        rv[field1] = lo;
        packedFields.insert(field1);
    }
    // Pack must pack fields next.
    if (mustPackFields.size() > 0) {
        LOG4("\t\tAttempting to pack must pack fields next.");
        for (auto f : mustPackFields) {
            LOG4("\t\t  Checking packing for must pack field " << f->name);
            LOG4("\t\t\tUnoccupied bits: " << unOccupied);
            if (unOccupied.size() == 0 || f->size > static_cast<int>(unOccupied.size()))
                return rv;
            int lo = alignmentConstraints.at(f).lo;
            LOG4("\t\t\tMust be aligned at bit: " << lo);
            for (int i = lo; i < lo + f->size; i++) {
                if (!(unOccupied.count(i))) {
                    // throw error here?
                    LOG4("\t\t  Cannot pack must pack fields together. Therefore, not packing "
                         "anything with candidate field");
                    return rv;
                }
                unOccupied.erase(i);
            }
            rv[f] = lo;
            LOG4("\t\t  Allocating must pack field " << f->name << " to bit " << lo);
            packedFields.insert(f);
        }
    }
    // Pack fields without alignment constraints next.
    for (const PHV::Field* candidate : potentiallyPackableFields) {
        if (packedFields.count(candidate)) continue;
        LOG4("\t\t  Checking packing for " << candidate);
        LOG4("\t\t\tUnoccupied bits: " << unOccupied);
        if (unOccupied.size() == 0 || candidate->size >
                                      static_cast<int>(unOccupied.size()))
            return rv;
        if (!alignmentConstraints.count(candidate)) {
            for (int b : unOccupied) {
                bool noIssues = true;
                // Make sure all bits can be allocated consecutively.
                for (int i = 0; i < candidate->size; i++) {
                    if (!unOccupied.count(b+i)) {
                        LOG4("\t\t\tCannot allocate field " << candidate->name << " to position " <<
                                                            (b+i));
                        noIssues = false;
                        break; } }
                if (noIssues) {
                    rv[candidate] = b;
                    for (int i = 0; i < candidate->size; i++) {
                        LOG4("\t\t\tErasing bit " << (b+i));
                        unOccupied.erase(b+i); }
                    break; } }
        } else {
            LOG4("\t\t\tIgnoring field " << candidate->name << " because it has an alignment "
                                                         "constraint.");
        }
    }
    return rv;
}

ordered_set<const PHV::Field*> RepackFlexHeaders::checkPotentialPackAlignmentReqs(
        const ordered_map<const PHV::Field*, le_bitrange>& alignmentConstraints,
        ordered_set<const PHV::Field*>& potentiallyPackableFields,
        const PHV::Field* field) const {
    // Extract fields with alignment constraints.
    ordered_set<const PHV::Field*> alignedFields;
    if (alignmentConstraints.count(field))
        alignedFields.insert(field);
    for (auto* f : potentiallyPackableFields)
        if (alignmentConstraints.count(f))
            alignedFields.insert(f);
    // Check mutual alignment constraints for alignedFields.
    ordered_set<const PHV::Field*> conflictingFields;
    for (auto* f1 : alignedFields) {
        le_bitrange f1_alignment = alignmentConstraints.at(f1);
        for (auto* f2 : alignedFields) {
            le_bitrange f2_alignment = alignmentConstraints.at(f2);
            if (f1 == f2) continue;
            if (conflictingFields.count(f1) || conflictingFields.count(f2))
                continue;
            if (!f1_alignment.overlaps(f2_alignment))
                continue;
            // Always choose the smaller field as having introduced the alignment conflicts.
            if (f1->size < f2->size)
                conflictingFields.insert(f1);
            else
                conflictingFields.insert(f2); } }
    if (conflictingFields.size() > 0) {
        LOG4("\t  Found the following fields with conflicting alignment: ");
        for (auto* f : conflictingFields) {
            LOG4("\t\t" << f);
            potentiallyPackableFields.erase(f); }
    }
    return conflictingFields;
}

void RepackFlexHeaders::determineAlignmentConstraints(
        const std::vector<const PHV::Field*>& fieldsToBePacked,
        ordered_map<const PHV::Field*, le_bitrange>& alignmentConstraints,
        ordered_map<const PHV::Field*, std::set<int>>& conflictingAlignmentConstraints,
        ordered_set<const PHV::Field*>& mustAlignFields) {
    for (auto field : fieldsToBePacked) {
        ordered_set<const PHV::Field*> relatedFields;
        std::queue<const PHV::Field*> fieldsNotVisited;
        LOG4("\tDetermining alignment constraint for " << field->name);

        // If this field is initialized by a SavedRVal expression in the parser, then consider it
        // as having alignment constraints.
        if (parserAlignedFields.count(field) && field->alignment) {
            alignmentConstraints[field] = le_bitrange(StartLen(field->alignment->align,
                        field->size));
            LOG4("\t\tDetected bit in byte alignment " << alignmentConstraints[field] <<
                                                       " for field " << field->name); }

        // DeparserParams must be in the bottom bits.
        if (deparserParams.count(field)) {
            if (alignmentConstraints.count(field)) {
                ::warning("Alignment constraint already present for field %1%: %2%", field->name,
                          alignmentConstraints.at(field).lo);
                conflictingAlignmentConstraints[field].insert(
                        alignmentConstraints.at(field).lo);
            } else {
                alignmentConstraints[field] = le_bitrange(StartLen(0, field->size));
                LOG4("\t\tDetected deparser parameter alignment: "  <<
                    alignmentConstraints[field] << " for field " << field->name); } }

        // Also summarize the egress version of this field, as alignment
        // constraints may be induced by uses of the egress version of the
        // bridged field.
        cstring egressFieldName = getNonBridgedEgressFieldName(field->name);
        cstring bridgedFieldName = (field->gress == INGRESS) ?
             getEgressFieldName(field->name) : field->name;
        BUG_CHECK(egressFieldName, "No egress version of the field %1%", field->name);
        const auto* egressField = phv.field(egressFieldName);
        // Add the ingress field and its egress version to visit.
        fieldsNotVisited.push(field);
        if (egressField)
             fieldsNotVisited.push(egressField);

        while (!fieldsNotVisited.empty()) {
            const PHV::Field* currentField = fieldsNotVisited.front();
            relatedFields.insert(currentField);
            fieldsNotVisited.pop();
            LOG6("\t\tVisiting new field: " << currentField);
            auto operands = actionConstraints.field_sources(currentField);
            // Add all unvisited operands to fieldsNotVisited.
            for (const PHV::Field* f : operands) {
                if (!relatedFields.count(f))
                    fieldsNotVisited.push(f); }
            auto destinations = actionConstraints.field_destinations(currentField);
            // Add all unvisited destinations to fieldsNotVisited.
            for (const PHV::Field* f : destinations) {
                if (!relatedFields.count(f))
                    fieldsNotVisited.push(f); }
            if (parserAlignedFields.count(currentField))
                for (const auto* f : parserAlignedFields.at(currentField))
                    if (!relatedFields.count(f))
                        fieldsNotVisited.push(f);
            LOG6("\t\t  Now, we have " << fieldsNotVisited.size() << " fields unvisited"); }

        if (LOGGING(4) && relatedFields.count(field) == 0) {
            LOG4("\t  No related fields");
            continue; }

        for (const PHV::Field* f : relatedFields) {
            if (field->gress == INGRESS && f->name == bridgedFieldName) continue;
            // ignore the alignment on the current field
            if (f->name == field->name) continue;
            LOG5("\t  Related field: " << f);
            if (f->alignment) {
                LOG5("\t\t  New alignment: " << *(f->alignment));
                // If the field must be aligned at this bit position (instead of not being aligned
                // and instead satisfying constraints because of deposit-field operations),
                if (mustAlign(f)) {
                    LOG5("\t\t  Field " << field->name << " must be placed at the given "
                                                                "alignment " << *(f->alignment));
                    mustAlignFields.insert(field); }
                if (fieldAlignmentMap.count(field)) {
                    // alignSource is where the alignment constraint originates from.
                    const PHV::Field* alignSource = fieldAlignmentMap[field];
                    BUG_CHECK(alignSource->alignment, "No alignment for field %1%",
                              alignSource->name);
                    LOG5("\t\t  Old alignment: " << *(alignSource->alignment));
                    if (*(f->alignment) == *(alignSource->alignment)) continue;
                    // Only compare the little endian alignments because the network endian
                    // alignments differ for some fields of different sizes.
                    // XXX(Deep): Figure out why we get conflicting alignment constraints for
                    // related fields and how to reconcile it. Until then, don't pack these fields
                    // with anything else.
                    WARN_CHECK(f->alignment->align == alignSource->alignment->align,
                               "Conflicting alignment constraints detected for bridged field %1%"
                               ": %2%, %3%", field->name, f->alignment->align,
                               alignSource->alignment->align);
                    conflictingAlignmentConstraints[field].insert(f->alignment->align);
                    conflictingAlignmentConstraints[field].insert(
                            alignSource->alignment->align);
                    LOG5("\t\t  Conflicting alignment constraint detected for " << field);
                    continue; }
                fieldAlignmentMap[field] = f;
                le_bitrange alignment = StartLen(f->alignment->align, f->size);
                alignmentConstraints[field] = alignment; } } }
    if (LOGGING(4)) {
        if (alignmentConstraints.size() > 0) {
            LOG4("\tPrinting bridged fields with alignment constraints:");
            for (auto kv : alignmentConstraints)
                LOG4("\t  " << kv.first << " : " << kv.second);
        }
        if (conflictingAlignmentConstraints.size() > 0) {
            LOG4("\tPrinting bridged fields with conflicting constraints:");
            for (auto kv : conflictingAlignmentConstraints) {
                std::stringstream ss;
                ss << "\t  " << kv.first->name << " : ";
                for (auto pos : kv.second)
                    ss << pos << " ";
                LOG4(ss.str());
            }
        }
    }
}

bool RepackFlexHeaders::mustAlign(const PHV::Field* field) const {
    auto writeActions = actionConstraints.actions_writing_fields(field);
    if (writeActions.size() == 0) return false;
    for (const auto* a : writeActions) {
        auto fieldsWritten = actionConstraints.actionWrites(a);
        for (const auto* f : fieldsWritten) {
            if (f == field) continue;
            if (f->pov) continue;
            if (f->header() != field->header()) continue;
            if (f->offset / 8 != field->offset / 8) continue;
            if (actionConstraints.written_by_ad_constant(f, a)) return true; } }
    return false;
}

const IR::StructField* RepackFlexHeaders::getPaddingField(int size, int id) const {
    cstring padFieldName = "__pad_" + cstring::to_cstring(id);
    auto* fieldAnnotations = new IR::Annotations({new IR::Annotation(IR::ID("hidden"), { })
                                                 });
    const IR::StructField* padField = new IR::StructField(padFieldName,
                                          fieldAnnotations, IR::Type::Bits::get(size));
    return padField;
}

cstring RepackFlexHeaders::getEgressFieldName(cstring ingressName) {
    if (!ingressName.startsWith(INGRESS_FIELD_PREFIX)) {
        BUG("Called getEgressFieldName on ingress fieldname %1%", ingressName);
        return cstring(); }
    // ingress::foo.bar -> egress::foo.bar
    return (EGRESS_FIELD_PREFIX + ingressName.substr(9));
}

cstring RepackFlexHeaders::getIngressFieldName(cstring egressName) {
    if (!egressName.startsWith(EGRESS_FIELD_PREFIX)) {
        BUG("Called getIngressFieldName on ingress fieldname %1%", egressName);
        return cstring();
    }
    // egress::foo.bar -> ingress::foo.bar
    return (INGRESS_FIELD_PREFIX + egressName.substr(8));
}

cstring RepackFlexHeaders::getFieldName(cstring hdr, const IR::StructField* field) const {
    auto name = hdr + "." + field->name;
    if (auto* fieldInfo = phv.field(name))
        return fieldInfo->name;
    return name;
}

/**
 * packPhvFieldSet : take a set of PHV::Field, pack the set and return the packing.
 */
const std::vector<const PHV::Field*>
RepackFlexHeaders::packPhvFieldSet(const ordered_set<const PHV::Field*>& fieldsToBePacked) {
    std::vector<const PHV::Field*> packedFields;
    std::vector<const PHV::Field*> nonByteAlignedFields;
    for (auto f : fieldsToBePacked) {
        if (f->size % 8 == 0) {
            packedFields.push_back(f);
            continue; }
        nonByteAlignedFields.push_back(f); }

    LOG4("Added " << packedFields.size() << " byte aligned fields.");
    LOG4("Number of non byte aligned fields: " << nonByteAlignedFields.size());
    // Sort the nonbyte aligned fields according to size.
    std::sort(nonByteAlignedFields.begin(), nonByteAlignedFields.end(),
            [&](const PHV::Field* a, const PHV::Field* b) {
            return a->size < b->size;
            });
    // Logging information about nonbyte-aligned fields.
    if (LOGGING(4)) {
        for (auto f : nonByteAlignedFields) {
            LOG4("\tField: " << f->name << " (" << f->size << "b)");
            LOG4("\t  PHV Field: " << f);
            if (f->alignment)
                LOG4("\t  Compute Alignment: " << *(f->alignment));
        }
    }

    auto sliceListAlignment = bridgedActionAnalysis(nonByteAlignedFields);
    // Determine nonbyte-aligned bridged fields with alignment constraints.
    ordered_map<const PHV::Field*, le_bitrange> alignmentConstraints;
    ordered_map<const PHV::Field*, std::set<int>> conflictingAlignmentConstraints;
    ordered_set<const PHV::Field*> mustAlignFields;
    determineAlignmentConstraints(nonByteAlignedFields, alignmentConstraints,
                                  conflictingAlignmentConstraints, mustAlignFields);

    ordered_set<const PHV::Field*> alreadyPackedFields;
    for (auto field : nonByteAlignedFields) {
        if (alreadyPackedFields.count(field)) {
            LOG4("\t  A. Already packed " << field->name);
            continue; }
        std::vector<const PHV::Field*> fieldsPackedTogether;
        LOG3("\tTrying to pack fields with " << field->name);
        // If this has alignment constraints due to the parser, ensure we pad it correctly.
        int alignment = getAlignment(field->size);
        LOG4("\t  Alignment: " << alignment);

        ordered_map<const PHV::Field*, int> packingWithPositions;
        if (parserAlignedFields.count(field)) {
            LOG4("\t\t  F. No other field packed because parser aligned field: " << field);
            for (const auto* source : parserAlignedFields.at(field)) {
                // XXX(Deep): What if alignment from multiple sources conflicts?
                if (source->alignment) {
                    LOG4("\t\tAlignment constraint on " << field << " : " <<
                         *(source->alignment) << " " << source->alignment->align);
                    packingWithPositions[field] = source->alignment->align;
                }
            }
        } else {
            packingWithPositions = packWithField(alignment, field, fieldsToBePacked,
                    alreadyPackedFields, alignmentConstraints, conflictingAlignmentConstraints,
                    sliceListAlignment);

            // For fields that are alone in their byte aligned boundary, and must not be aligned at
            // a given bit position or have conflicting alignment constraints, we choose to align
            // them in the bottom bits and add padding afterwards.
            if (packingWithPositions.size() == 1) {
                for (auto kv : packingWithPositions) {
                    if (conflictingAlignmentConstraints.count(kv.first) ||
                        !mustAlignFields.count(kv.first)) {
                        packingWithPositions[kv.first] = 0;
                        LOG4("\t\t  Okay to pack " << kv.first->name << " in bottom bits."); } } }
        }

        // Total number of bits in this required packing.
        int totalPackSize = 0;
        int totalAllocatedSize = 0;

        for (auto kv : packingWithPositions)
            totalAllocatedSize += kv.first->size;
        totalPackSize = 8 * ROUNDUP(totalAllocatedSize, 8);

        // Fields with conflicting alignment are always packed by themselves.
        if (packingWithPositions.size() == 1) {
            for (auto kv : packingWithPositions) {
                if (!conflictingAlignmentConstraints.count(kv.first)) break;
                LOG4("\t\t  Field " << kv.first->name << " has conflicting alignment.");
                int maxSpaceRequired = -1;
                // For fields with conflicting alignment, check if any of the potential alignments
                // require the field to be packed in a chunk that is larger than the next
                // byte-aligned chunk size. The required size is represented by the maxSpaceRequired
                // variable.
                std::set<int> conflictingPositions = conflictingAlignmentConstraints.at(kv.first);
                for (int pos : conflictingPositions) {
                    int req = pos + kv.first->size;
                    maxSpaceRequired = (maxSpaceRequired < req) ? req : maxSpaceRequired;
                }
                totalPackSize = 8 * ROUNDUP(maxSpaceRequired, 8);
                LOG4("\t\t  Need " << maxSpaceRequired << " bits for field " <<
                     kv.first->name << " with conflicting alignment constraints.");
            }
        }

        LOG3("\t\tTrying to pack " << totalAllocatedSize << " bits within " << totalPackSize <<
                                   " bits.");
        ordered_set<int> freeBits;
        for (int i = 0; i < totalPackSize; i++)
            freeBits.insert(i);
        int largestUnoccupiedPosition = totalPackSize - 1;
        LOG3("\t\t  Setting largest unoccupied position to: " << largestUnoccupiedPosition);
        ordered_set<const PHV::Field*> padFields;
        while (!freeBits.empty()) {
            int largestPosition = -1;
            const PHV::Field* candidate = nullptr;
            for (auto kv : packingWithPositions) {
                if (largestPosition < kv.second) {
                    candidate = kv.first;
                    largestPosition = kv.second;
                }
            }
            LOG6("\t\t\tLargest position: " << largestPosition);
            if (candidate)
                LOG6("\t\t\tCandidate width: " << candidate->size);
            if (!candidate) {
                // Insert padding field as no more candidates left for packing.
                int padSize = freeBits.size();
                if (padSize == 0) break;
                LOG4("\t\t  Need to insert padding of size: " << padSize);
                auto* padField = phv.create_dummy_padding(padSize, INGRESS);   // FIXME
                LOG4("\t\t  Padding field: " << padField);
                padFields.insert(padField);
                fieldsPackedTogether.push_back(padField);
                freeBits.clear();
                largestUnoccupiedPosition = -1;
                break;
            } else {
                int outerLimitForField = largestPosition + candidate->size - 1;
                LOG5("\t\t  outerLimitForField: " << outerLimitForField << ", largestUnocc: " <<
                                                  largestUnoccupiedPosition);
                if (outerLimitForField < largestUnoccupiedPosition) {
                    // Insert padding in the appropriate place for the field first.
                    int padSize = largestUnoccupiedPosition - outerLimitForField;
                    if (padSize != 0) {
                        LOG4("\t\t  Need to insert padding before field of size: " <<
                            (largestUnoccupiedPosition - outerLimitForField));
                        auto* padField = phv.create_dummy_padding(padSize, candidate->gress);
                        LOG4("\t\t  Padding field: " << padField);
                        fieldsPackedTogether.push_back(padField);
                        padFields.insert(padField);
                    }
                }
            }
            for (int i = largestUnoccupiedPosition; i >= largestPosition; i--)
                freeBits.erase(i);
            largestUnoccupiedPosition = largestPosition - 1;
            LOG5("\t\t  Setting largest unoccupied position to: " << largestUnoccupiedPosition);
            fieldsPackedTogether.push_back(candidate);
            packingWithPositions.erase(candidate);
            const PHV::Field* packingField = candidate;
            LOG5("\t\tInserting into already packed field: " << packingField->name);
            alreadyPackedFields.insert(packingField);
            LOG5("\t\tInserting " << packingField->name << " into already packed fields.");
        }

        ordered_set<cstring> fieldsExtractedTogether;
        for (auto it = fieldsPackedTogether.begin(); it != fieldsPackedTogether.end(); ++it) {
            LOG4("\t\tA. Pushing field " << (*it)->name << " of type " << (*it)->size <<
                                         "b.");
            if (padFields.count(*it)) paddingFieldNames.insert((*it)->name);
            fieldsExtractedTogether.insert((*it)->name);
            packedFields.push_back(*it);
        }
        for (auto f1 : fieldsExtractedTogether) {
            for (auto f2 : fieldsExtractedTogether) {
                if (f1 == f2) continue;
                extractedTogether[f1].insert(f2);
                extractedTogether[f2].insert(f1);
            }
        }
    }
    return packedFields;
}

/**
 * check 'repackedTypes' to see if the header type has already been packed.
 *
 * XXX(hanw): This implies if a mirror metadata header is emitted multiple times,
 * the packing on the first emit is going to determine the packing of the rest,
 * which is not correct.
 */
boost::optional<const IR::HeaderOrMetadata*>
RepackFlexHeaders::checkIfAlreadyPacked(const IR::HeaderOrMetadata* h) {
    // If it is an egress header, take its new type from the repacked ingress version.
    if (repackedTypes.count(h->type)) {
        auto* repackedHeaderType = new IR::Type_Header(h->type->name, h->type->annotations,
                repackedTypes.at(h->type)->fields);
        auto* repackedHeader = new IR::Header(h->name, repackedHeaderType);
        repackedHeaders[h->name] = repackedHeader;
        originalHeaders[h->name] = h;
        LOG1("Repacked egress header: " << repackedHeader);
        LOG1("Repacked egress header type: " << repackedHeaderType);
        LOG1("Repacked egress header size: " << getHeaderBytes(repackedHeader) << "B");
        return repackedHeader;
    }
    return boost::none;
}

const ordered_set<const PHV::Field*>
RepackFlexHeaders::mkPhvFieldSet(const IR::HeaderOrMetadata* h) {
    auto isFlexible = [&](const IR::StructField* f) {
        return f->getAnnotation("flexible") != nullptr; };
    ordered_set<const PHV::Field*> fields;
    for (auto f : *h->type->fields.getEnumerator()->where(isFlexible)) {
        cstring fieldName = h->name + "." + f->name;
        const auto* field = phv.field(fieldName);
        LOG3("PHV::Field for " << fieldName << " is " << field);
        fields.insert(field);
    }
    return fields;
}

/**
 * mkPhvFieldSet : take IR::DigestFieldList, generate a set of PHV::Field that must be packed.
 */
const std::vector<std::tuple<const IR::StructField*, const IR::BFN::FieldLVal*>>
RepackFlexHeaders::zipDigestSourcesAndTypes(const IR::BFN::DigestFieldList* d) {
    std::vector<std::tuple<const IR::StructField*, const IR::BFN::FieldLVal*>> sources;
    // XXX(HanW): mirror digest has 'session_id' in the first element, which is not
    // part of the mirror field list.
    auto digest = findContext<const IR::BFN::Digest>();
    auto iter = d->sources.begin();
    if (digest->name == "mirror") {
        iter++; }
    // zip field type and field list
    std::transform(d->type->fields.begin(), d->type->fields.end(),
            iter, std::back_inserter(sources),
            [](const IR::StructField* aa, const IR::BFN::FieldLVal* bb) {
                return std::make_tuple(aa, bb); });
    return sources;
}

const ordered_set<const PHV::Field*>
RepackFlexHeaders::mkPhvFieldSet(const IR::BFN::DigestFieldList* d) {
    auto sources = zipDigestSourcesAndTypes(d);
    auto isFlexible = [&](const IR::StructField* f) {
        return f->getAnnotation("flexible") != nullptr; };
    ordered_set<const PHV::Field*> fields;
    for (auto f : sources) {
        if (!isFlexible(std::get<0>(f))) continue;
        const auto* field = phv.field(std::get<1>(f)->field);
        fields.insert(field);
    }
    return fields;
}

const std::map<const PHV::Field*, const IR::StructField*>
RepackFlexHeaders::getPhvFieldToStructFieldMap(const IR::BFN::DigestFieldList* d) {
    auto sources = zipDigestSourcesAndTypes(d);
    std::map<const PHV::Field*, const IR::StructField*> map;
    for (auto f : sources) {
        const auto* field = phv.field(std::get<1>(f)->field);
        map.emplace(field, std::get<0>(f));
    }
    return map;
}

bool RepackFlexHeaders::isFlexibleHeader(const IR::HeaderOrMetadata* h) {
    for (auto f : h->type->fields)
        if (f->getAnnotation("flexible"))
            headerToFlexibleStructsMap[h].insert(f);
    return headerToFlexibleStructsMap.count(h);
}

bool RepackFlexHeaders::isFlexibleHeader(const IR::BFN::DigestFieldList* d) {
    /// empty field list does not have a header type.
    if (!d->type) return false;
    for (auto f : d->type->fields)
        if (f->getAnnotation("flexible"))
            digestToFlexibleStructsMap[d].insert(f);
    return digestToFlexibleStructsMap.count(d);
}

const IR::Node* RepackFlexHeaders::preorder(IR::BFN::Pipe* p) {
    // dump(p);
    return p;
}

const IR::Node* RepackFlexHeaders::preorder(IR::HeaderOrMetadata* h) {
    if (!isFlexibleHeader(h)) return h;
    LOG3("Candidate flexible header found: " << h->name);
    LOG3("Candidate header type: " << h->type);
    LOG3("Candidate header size: " << getHeaderBits(h) << "b");
    // Only process bridged metadata headers.
    cstring headerName = h->name;

    if (auto rv = checkIfAlreadyPacked(h))
        return *rv;

    BUG_CHECK(headerToFlexibleStructsMap.count(h),
              "The compiler has detected a header %1% with flexible structs, but "
              "cannot find the associated flexible structs to repack.",
              h->name);
    auto& flexFields = headerToFlexibleStructsMap.at(h);
    LOG3("  " << flexFields.size() << " flexible fields in header " << h->name);
    if (LOGGING(3))
        for (auto* f : flexFields)
            LOG3("\tFlexible header type: " << f->name << "\n\t  " << f->type);

    std::map<const PHV::Field*, const IR::StructField*> phvFieldToStructField;

    for (auto f : flexFields) {
        cstring fieldName = getFieldName(h->name, f);
        const PHV::Field* field = phv.field(fieldName);
        BUG_CHECK(field, "No field object for field %1%", fieldName);
        phvFieldToStructField.emplace(field, f);
    }

    auto& fieldsToBePacked = mkPhvFieldSet(h);

    auto packedFields = packPhvFieldSet(fieldsToBePacked);

    IR::IndexedVector<IR::StructField> fields;
    // Add the non flexible fields from the header.
    for (auto f : h->type->fields) {
        if (!f->getAnnotation("flexible") && !f->getAnnotation("hidden")) {
            fields.push_back(f);
            LOG1("Pushing original field " << f);
            continue;
        }
    }
    // Add the repacked flexible fields.
    unsigned padFieldId = 0;
    for (auto f : packedFields) {
        if (phvFieldToStructField.count(f)) {
            auto field = phvFieldToStructField.at(f);
            fields.push_back(field);
            LOG1("Pushing field " << field);
        } else {
            auto padding = getPaddingField(f->size, padFieldId++);
            fields.push_back(padding);
            LOG1("Pushing field " << padding);
        }
    }

    if (auto fh = h->type->to<IR::BFN::Type_FixedSizeHeader>()) {
        auto bits = getHeaderBits(h);
        auto pad_size = fh->fixed_size - bits;
        if (pad_size != 0) {
            auto padding = getPaddingField(pad_size, padFieldId++);
            fields.push_back(padding);
            LOG1("Pushing field " << padding);
        }
    }

    auto* repackedHeaderType = new IR::Type_Header(h->type->name, h->type->annotations, fields);
    auto* repackedHeader = new IR::Header(h->name, repackedHeaderType);
    repackedHeaders[headerName] = repackedHeader;
    repackedTypes[h->type] = repackedHeaderType;
    originalHeaders[headerName] = h;
    ingressFlexibleTypes[h] = repackedHeader;
    LOG1("Repacked header: " << repackedHeader->name);
    LOG1("Repacked header type: " << repackedHeader->type);
    LOG1("Repacked header size: " << getHeaderBits(repackedHeader) << "b");

    return repackedHeader;
}

/**
 * Repack the field list in emit method call to reflect the new field list packing
 * format. This happens because the packing optimization is a backend optimization.
 * The optimization relies on backend phv analysis which only understands fields,
 * not headers. Further, the midend copy propagation may have replaced some of the
 * fields in the field list with field from another header, so we cannot rely
 * on the field name to find out the original type of the field list.
 *
 * The original type of the field list is thus stored by the midend to the
 * IR::BFN::DigestFieldList object as a cstring during midend conversion.
 *
 */
const IR::BFN::DigestFieldList*
RepackFlexHeaders::repackFieldList(cstring digest,
        std::vector<FieldListEntry> repackedFieldIndices,
        const IR::Type_StructLike* repackedHeaderType,
        const IR::BFN::DigestFieldList* origFieldList) const {
    // map index -> fieldlval in the field list.
    ordered_map<int, const IR::BFN::FieldLVal*> origFieldOrder;
    // repacked field list initializer
    IR::Vector<IR::BFN::FieldLVal> newSources;
    // mirror digest sources contains session_id at the beginning
    // which is not part of the p4 field list.
    auto iter = origFieldList->sources.begin();
    if (digest == "mirror") {
        newSources.push_back(*iter);
        iter++; }

    int index = 0;
    for (; iter != origFieldList->sources.end(); iter++) {
        origFieldOrder.emplace(index++, *iter); }

    // reorder field from the original field list initializer
    // according to the new field list order.
    std::map<int, const IR::BFN::FieldLVal*> repackedFieldOrder;
    index = 0;
    for (auto entry : repackedFieldIndices) {
        if (entry.first == -1) {
            repackedFieldOrder.emplace(index++,
                    new IR::BFN::FieldLVal(new IR::Padding(entry.second)));
            continue; }
        repackedFieldOrder.emplace(index++, origFieldOrder.at(entry.first)); }

    for (auto f : repackedFieldOrder) {
        IR::BFN::FieldLVal* newSource = new IR::BFN::FieldLVal(f.second->field);
        newSources.push_back(newSource);
    }
    IR::BFN::DigestFieldList* repackedFieldList =
        new IR::BFN::DigestFieldList(origFieldList->srcInfo,
                origFieldList->idx, newSources, repackedHeaderType,
                origFieldList->controlPlaneName);
    LOG3("Repacked digest: " << digest << " "  << repackedFieldList);
    return repackedFieldList;
}

const IR::Node* RepackDigestFieldList::preorder(IR::BFN::DigestFieldList* d) {
    // empty digest field list has nullptr type.
    if (!d->type) return d;
    if (!isFlexibleHeader(d)) return d;
    LOG3("Candidate digest field list found: idx " << d->idx);
    LOG3("Candidate digest type: " << d->type);
    LOG3("Candidate digest size: " << getHeaderBits(d) << "b");

    BUG_CHECK(digestToFlexibleStructsMap.count(d),
              "The compiler has detected a header %1% with flexible structs, but "
              "cannot find the associated flexible structs to repack.",
              d->type);
    auto& flexFields = digestToFlexibleStructsMap.at(d);
    LOG3("\t" << flexFields.size() << " flexible fields in header " << d->type->name);
    if (LOGGING(3))
        for (auto* f : flexFields)
            LOG3("\tFlexible header type: " << f->name << "\n\t  " << f->type);

    auto phvFieldToStructField = getPhvFieldToStructFieldMap(d);

    auto& fieldsToBePacked = mkPhvFieldSet(d);

    auto packedFields = packPhvFieldSet(fieldsToBePacked);

    IR::IndexedVector<IR::StructField> fields;
    // Add the non flexible fields from the header.
    for (auto f : d->type->fields) {
        if (!f->getAnnotation("flexible") && !f->getAnnotation("hidden")) {
            fields.push_back(f);
            LOG3("\tPushing original field " << f);
            continue;
        }
    }
    // Add the repacked flexible fields.
    unsigned padFieldId = 0;
    for (auto f : packedFields) {
        if (phvFieldToStructField.count(f)) {
            auto field = phvFieldToStructField.at(f);
            fields.push_back(field);
            LOG3("\tPushing field " << field);
        } else {
            auto padding = getPaddingField(f->size, padFieldId++);
            fields.push_back(padding);
            LOG3("\tPushing field " << padding);
        }
    }
    auto* repackedHeaderType = new IR::Type_Header(d->type->name, d->type->annotations, fields);
    repackedTypes[d->type] = repackedHeaderType;

    std::map<cstring, int> original_field_indices;
    int index = 0;
    for (auto f : d->type->fields) {
        original_field_indices.emplace(f->name, index++);
    }

    std::vector<FieldListEntry> repacked_field_indices;
    for (auto f : repackedHeaderType->fields) {
        if (f->getAnnotation("hidden")) {
            repacked_field_indices.push_back(std::make_pair(-1, f->type));
            continue; }
        repacked_field_indices.push_back(
                std::make_pair(original_field_indices.at(f->name), f->type));
        LOG1("\tRepacked field " << f->name); }

    if (LOGGING(3)) {
        for (auto i : repacked_field_indices) {
            LOG3("\t\trepacking " << i.first << " to " << i.second);
        } }

    auto digest = findContext<IR::BFN::Digest>();
    BUG_CHECK(digest != nullptr, "Unable to find digest for %1%", d);
    auto rd = repackFieldList(digest->name, repacked_field_indices,
            repackedHeaderType, d);
    LOG3("Repacked digest type: " << repackedHeaderType);
    LOG3("Repacked digest size: " << getHeaderBits(rd) << "b");
    return rd;
}

Visitor::profile_t ProduceParserMappings::init_apply(const IR::Node* root) {
    parserStateToHeadersMap.clear();
    headerNameToRefMap.clear();
    bridgedToExpressionsMap.clear();
    return Inspector::init_apply(root);
}

bool ProduceParserMappings::preorder(const IR::BFN::ParserState* p) {
    for (auto stmt : p->statements) {
        auto* e = stmt->to<IR::BFN::Extract>();
        if (!e) continue;
        if (!e->source->is<IR::BFN::PacketRVal>()) continue;
        auto* destVal = e->dest->to<IR::BFN::FieldLVal>();
        if (!destVal) BUG("No destination object for extract %1%", e);
        const auto* f = phv.field(destVal->field);
        if (!f) BUG("No field corresponding to destination %1% of extract %2%", destVal->field, e);
        cstring headerName = f->header();
        LOG3("\t\tField " << f->name << ", header " << headerName << " extracted in " << p->name);
        if (!parserStateToHeadersMap.count(p->name)) {
            parserStateToHeadersMap[p->name].push_back(headerName);
            continue;
        }
        auto& existingHeaders = parserStateToHeadersMap.at(p->name);
        bool foundHeader = false;
        for (auto s : existingHeaders) {
            if (s == headerName) {
                foundHeader = true;
                break;
            }
        }
        if (foundHeader) continue;
        parserStateToHeadersMap[p->name].push_back(headerName);
    }
    return true;
}

bool ProduceParserMappings::preorder(const IR::HeaderOrMetadata* h) {
    headerNameToRefMap[h->name] = h;
    LOG4("\t  Adding header ref for header name " << h->name);
    // At this point, header is flattened, so safe to do this.
    for (auto f : h->type->fields) {
        cstring name = h->name + "." + f->name;
        IR::Member* mem = gen_fieldref(h, f->name);
        if (!mem) BUG("Could not produce member corresponding to %1%", f->name);
        bridgedToExpressionsMap[name] = mem;
    }
    return false;
}

Visitor::profile_t GatherParserStateToModify::init_apply(const IR::Node* root) {
    parserStatesToModify.clear();
    return Inspector::init_apply(root);
}

bool GatherParserStateToModify::preorder(const IR::BFN::ParserState* ps) {
    LOG3(" visiting " << ps->name);
    bool extractToBridgedMetadataFound = false;
    for (auto stmt : ps->statements)
        if (const auto* e = stmt->to<IR::BFN::Extract>())
            extractToBridgedMetadataFound |= processExtract(e);
    if (extractToBridgedMetadataFound) {
        LOG4("\t  Must modify parser state: " << ps->name);
        parserStatesToModify.insert(ps->name);
    }
    return true;
}

bool GatherParserStateToModify::processExtract(const IR::BFN::Extract* e) {
    auto* fieldLVal = e->dest->to<IR::BFN::FieldLVal>();
    if (!fieldLVal) return false;
    const PHV::Field* f = phv.field(fieldLVal->field);
    if (!f) BUG("Extract to a non-field type %1%", fieldLVal->field);
    if (f->is_flexible()) {
        // extracting constant to bridge metadata field does not count as a flex
        // field use as it may be introduced by metadata initialization.
        auto* constantRVal = e->source->to<IR::BFN::ConstantRVal>();
        if (constantRVal)
            return false;
        LOG4("\t  Found flexible type: " << f->name);
        return true;
    }
    return false;
}

void ReplaceFlexFieldUses::addBridgedFields(const IR::HeaderOrMetadata* header) {
    if (!header) return;
    for (auto f : header->type->fields) {
        cstring fieldName = pack.getFieldName(header->name, f);
        bridgedFields[fieldName] = f->type;
    }
}

Visitor::profile_t ReplaceFlexFieldUses::init_apply(const IR::Node* root) {
    bridgedFields.clear();
    emitsToBeReplaced.clear();
    fieldsToReplace.clear();
    egressBridgedMap.clear();
    reverseEgressBridgedMap.clear();
    extractedTogether.clear();

    auto repackedHeaders = pack.getRepackedHeaders();
    for (const auto h : repackedHeaders)
        addBridgedFields(h.second);

    if (bridgedFields.size() > 0) {
        LOG3("\tNumber of flexible fields: " << bridgedFields.size());
        for (auto kv : bridgedFields)
            LOG3("\t  " << kv.first << " (" << kv.second->width_bits() << "b)");
    }

    auto& hdrToFlex = pack.getHeaderToFlexibleStructsMap();
    for (auto kv : hdrToFlex)
        for (auto* f : kv.second)
            fieldsToReplace.insert(kv.first->name + "." + f->name);

    return Transform::init_apply(root);
}

IR::Node* ReplaceFlexFieldUses::preorder(IR::BFN::Pipe* pipe) {
    // If there are no bridged fields, avoid the IR traversal because there are no bridged metadata
    // fields whose uses must be replaced.
    if (bridgedFields.size() == 0) prune();
    return pipe;
}

IR::Node* ReplaceFlexFieldUses::preorder(IR::BFN::Extract* e) {
    const auto* ps = findContext<IR::BFN::ParserState>();
    if (!parserStatesToModify.count(ps->name)) return e;
    if (!e->source->is<IR::BFN::SavedRVal>()) return e;
    auto* savedVal = e->source->to<IR::BFN::SavedRVal>();
    auto* destField = e->dest->to<IR::BFN::FieldLVal>();
    if (!destField) return e;
    const PHV::Field* dest = phv.field(destField->field);
    const PHV::Field* source = phv.field(savedVal->source);
    if (!dest || !source) return e;
    egressBridgedMap[source->name] = dest->name;
    reverseEgressBridgedMap[dest->name] = source->name;
    return e;
}

boost::optional<const std::vector<IR::BFN::Extract*>>
ReplaceFlexFieldUses::getNewExtracts(cstring h, unsigned& packetOffset) const {
    std::vector<IR::BFN::Extract*> rv;
    const IR::HeaderOrMetadata* hdr = info.getHeaderRefForName(h);
    if (!hdr) return boost::none;
    // At this point, the header type is flattened.
    LOG3(" generate extract for header " << hdr->type);
    for (auto f : hdr->type->fields) {
        IR::Member* newDest = gen_fieldref(hdr, f->name);
        int width = f->type->width_bits();
        nw_bitrange range = StartLen(packetOffset, width);
        packetOffset += width;
        IR::BFN::PacketRVal* source = new IR::BFN::PacketRVal(range);
        IR::BFN::Extract* newE = new IR::BFN::Extract(newDest, source);
        LOG3("\t\tGenerated new extract: " << newE);
        rv.push_back(newE);
    }
    return rv;
}

IR::BFN::Extract* ReplaceFlexFieldUses::getNewSavedVal(const IR::BFN::Extract* e) const {
    const IR::BFN::SavedRVal* source = e->source->to<IR::BFN::SavedRVal>();
    BUG_CHECK(source, "Cannot get saved source for SavedRVal object %1%", e);
    const auto* f = phv.field(source->source);
    auto* newE = new IR::BFN::Extract(e->dest, e->source);
    if (!f) return newE;
    if (!fieldsToReplace.count(f->name)) return newE;
    if (!bridgedFields.count(f->name)) return newE;
    LOG4("\t\tFound field to replace: " << e);
    auto& exprMap = info.getBridgedToExpressionsMap();
    if (exprMap.count(f->name)) {
        IR::Member* mem = exprMap.at(f->name);
        IR::BFN::SavedRVal* source = new IR::BFN::SavedRVal(mem);
        IR::BFN::Extract* newExtract = new IR::BFN::Extract(e->dest, source);
        LOG4("\t\t  New saved val extract: " << newExtract);
        return newExtract;
    }
    return newE;
}

IR::Node* ReplaceFlexFieldUses::postorder(IR::BFN::ParserState* p) {
    // Only process the parser state which extracts bridged metadata header in the egress pipeline.
    if (!parserStatesToModify.count(p->name)) return p;

    LOG4("\tPostorder for parser state " << p->name);
    IR::Vector<IR::BFN::ParserPrimitive> statements;
    unsigned packetOffset = 0;
    auto extractedHeaders = info.getExtractedHeaders(p);
    LOG4("\t  Number of extracted headers: " << extractedHeaders.size());
    for (auto s : extractedHeaders)
        LOG4("\t\tHeader: " << s);
    unsigned headerNum = 0;
    ordered_set<cstring> seenHeaders;
    for (auto stmt : p->statements) {
        auto* extract = stmt->to<IR::BFN::Extract>();
        if (!extract) {
            statements.push_back(stmt);
            continue;
        }
        auto* rval = extract->source->to<IR::BFN::PacketRVal>();
        auto* cval = extract->source->to<IR::BFN::SavedRVal>();
        if (!rval && !cval) {
            statements.push_back(stmt);
            continue;
        }
        if (cval) {
            statements.push_back(getNewSavedVal(extract));
            continue;
        }
        auto* destVal = extract->dest->to<IR::BFN::FieldLVal>();
        if (!destVal) BUG("No destination object for extract %2%", extract);
        const auto* f = phv.field(destVal->field);
        if (!f) BUG("Cannot find Field object corresponding to %1%", destVal->field);
        cstring hName = f->header();
        if (headerNum < extractedHeaders.size() && extractedHeaders[headerNum] == hName) {
            LOG4("\t\t  Encountered first field of header " << hName);
            auto newExtracts = getNewExtracts(hName, packetOffset);
            if (!newExtracts) {
                // Calculate new source for the extract based on the packet offset (needed if the
                // header size has changed).
                int width = rval->range.size();
                nw_bitrange new_range = StartLen(packetOffset, width);
                packetOffset += width;
                IR::BFN::PacketRVal* new_source = new IR::BFN::PacketRVal(rval->srcInfo, new_range);
                IR::BFN::Extract* new_extract = new IR::BFN::Extract(extract->srcInfo,
                        extract->dest, new_source);
                statements.push_back(new_extract);
                LOG4("\t\t\tPushed non header extract: " << new_extract);
            } else {
                for (auto* e : *newExtracts) statements.push_back(e);
            }
            if (!seenHeaders.count(hName)) ++headerNum;
            seenHeaders.insert(hName);
        }
    }

    BUG_CHECK(packetOffset % 8 == 0, "Non byte aligned packet bits extracted in %1%", p->name);
    unsigned packetOffsetBytes = packetOffset / 8;
    IR::Vector<IR::BFN::Transition> transitions;
    for (auto t : p->transitions) {
        auto* newTransition = new IR::BFN::Transition(t->value, packetOffsetBytes, t->next);
        newTransition->saves = t->saves;
        transitions.push_back(newTransition);
    }
    IR::BFN::ParserState* newParserState = new IR::BFN::ParserState(p->name, p->gress, statements,
                                                                    p->selects, transitions);
    LOG3("\tNew parser state:\n" << newParserState);
    return newParserState;
}

IR::Node* ReplaceFlexFieldUses::preorder(IR::BFN::EmitField* e) {
    const auto* f = phv.field(e->source->field);
    BUG_CHECK(f, "Field object corresponding to %1% not found", e->source->field);
    auto repackedHeaders = pack.getRepackedHeaders();
    if (repackedHeaders.count(f->header())) {
        emitsToBeReplaced.insert(f->header());
        LOG4("\t\tInsert " << f->header() << " to emits to be replaced");
    }
    return e;
}

const std::vector<IR::BFN::EmitField*>
ReplaceFlexFieldUses::getNewEmits(
        const IR::HeaderOrMetadata* h,
        const IR::BFN::FieldLVal* pov) const {
    std::vector<IR::BFN::EmitField*> rv;
    BUG_CHECK(pov, "No POV bit for header %1%", h->name);
    for (auto f : h->type->fields) {
        IR::Member* newDest = gen_fieldref(h, f->name);
        IR::BFN::EmitField* newE = new IR::BFN::EmitField(newDest, pov->field);
        LOG4("\t\tGenerated new emit: " << newE);
        rv.push_back(newE);
    }
    return rv;
}

IR::Node* ReplaceFlexFieldUses::postorder(IR::BFN::Deparser* d) {
    IR::Vector<IR::BFN::Emit> emits;
    ordered_set<cstring> emitsDoneReplacing;
    for (auto* e : d->emits) {
        const auto* emitField = e->to<IR::BFN::EmitField>();
        if (!emitField) {
            emits.push_back(e);
            continue;
        }
        const auto* f = phv.field(emitField->source->field);
        BUG_CHECK(f, "Field object corresponding to %1% not found", emitField->source->field);
        if (emitsDoneReplacing.count(f->header())) continue;
        if (emitsToBeReplaced.count(f->header())) {
            const IR::HeaderOrMetadata* h = info.getHeaderRefForName(f->header());
            BUG_CHECK(h, "No header object corresponding to name %1%", f->header());
            auto newEmits = getNewEmits(h, emitField->povBit);
            for (auto* newE : newEmits)
                emits.push_back(newE);
            emitsDoneReplacing.insert(h->name);
        } else {
            emits.push_back(e);
        }
    }
    // Clear the emits in the deparser and replace with the new ones.
    d->emits.clear();
    for (auto* e : emits)
        d->emits.push_back(e);
    return d;
}

void ReplaceFlexFieldUses::end_apply() {
    auto& extracted = pack.getExtractedTogether();
    if (LOGGING(6)) {
        for (auto kv : egressBridgedMap)
            LOG6("\t\t" << kv.first << " : " << kv.second);
        for (auto kv : extracted) {
            LOG6("\t\t" << kv.first);
            for (auto s : kv.second)
                LOG6("\t\t  " << s);
        }
    }
    auto& paddingFieldNames = pack.getPaddingFieldNames();
    for (auto kv : extracted) {
        LOG6("\t  " << kv.first);
        if (paddingFieldNames.count(kv.first)) continue;
        cstring key = kv.first;
        if (key.startsWith(RepackFlexHeaders::INGRESS_FIELD_PREFIX))
            key = pack.getEgressFieldName(kv.first);
        if (egressBridgedMap.count(key))
            key = egressBridgedMap.at(key);
        LOG6("\t\tKey: " << key);
        for (auto s : kv.second) {
            if (paddingFieldNames.count(s)) continue;
            cstring value = s;
            if (s.startsWith(RepackFlexHeaders::INGRESS_FIELD_PREFIX))
                value = pack.getEgressFieldName(s);
            LOG6("\t\t  Original value: " << value);
            if (egressBridgedMap.count(value))
                value = egressBridgedMap.at(value);
            LOG6("\t\t  Value: " << value);
            extractedTogether[key].insert(value);
            extractedTogether[value].insert(key);
            LOG3("\t  Extracted together: " << key << ", " << value);
        }
    }
}

FlexiblePacking::FlexiblePacking(
        PhvInfo& p,
        PhvUse& u,
        DependencyGraph& dg,
        CollectBridgedFields& b,
        ordered_map<cstring, ordered_set<cstring>>& e,
        const MauBacktracker& alloc)
        : Logging::PassManager("bridge_metadata_"),
          bridgedFields(b),
          packConflicts(p, dg, tMutex, alloc, aMutex),
          actionConstraints(p, u, packConflicts),
          packDigestFieldLists(p, b, actionConstraints, doNotPack, noPackFields, deparserParams,
                      parserAlignedFields, alloc, repackedTypes),
          packHeaders(p, b, actionConstraints, doNotPack, noPackFields, deparserParams,
                      parserAlignedFields, alloc, repackedTypes),
          parserMappings(p),
          bmUses(p, packHeaders, parserMappings, e, parserStatesToModify) {
              addPasses({
                      &bridgedFields,
                      // XXX(hanw): GatherParserStateToModify must run before
                      // ReplaceOriginalFieldWithBridged.
                      new GatherParserStateToModify(p, parserStatesToModify),
                      new ReplaceOriginalFieldWithBridged(p, bridgedFields),
                      new FindDependencyGraph(p, dg),
                      &tMutex,
                      &aMutex,
                      &packConflicts,
                      &actionConstraints,
                      new GatherDeparserParameters(p, deparserParams),
                      new GatherPhase0Fields(p, noPackFields),
                      new GatherParserExtracts(p, parserAlignedFields),
                      &packDigestFieldLists,
                      &packHeaders,
                      &parserMappings,
                      &bmUses,
                      // rerun CollectPhvInfo because repack might have introduced
                      // new tempvars
                      new CollectPhvInfo(p),
              });
}
