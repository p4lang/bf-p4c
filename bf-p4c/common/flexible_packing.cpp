#include <cstring>
#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/lib/pad_alignment.h"

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
        phase0Fields.insert(f); }
    return true;
}

bool GatherParserExtracts::preorder(const IR::BFN::Extract* e) {
    auto* fieldLVal = e->dest->to<IR::BFN::FieldLVal>();
    if (!fieldLVal) return true;
    auto* f = phv.field(fieldLVal->field);
    if (!f) return true;
    if (!f->name.startsWith(FIELD_PREFIX)) return true;
    auto* source = e->source->to<IR::BFN::ComputedRVal>();
    if (!source) return true;
    auto* sourceField = phv.field(source->source);
    if (!sourceField) return true;
    parserAlignedFields[f] = sourceField;
    LOG5("    Initialization due to ComputedRVal in parser: " << f);
    return true;
}

Visitor::profile_t RepackFlexHeaders::init_apply(const IR::Node* root) {
    egressBridgedMap.clear();
    reverseEgressBridgedMap.clear();
    extractedTogether.clear();
    fieldAlignmentMap.clear();
    ingressFlexibleTypes.clear();
    headerToFlexibleStructsMap.clear();
    repackedHeaders.clear();
    paddingFieldNames.clear();
    flexibleStructs.clear();

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

cstring RepackFlexHeaders::getNonBridgedEgressFieldName(cstring ingressName) const {
    if (!ingressName.startsWith(INGRESS_FIELD_PREFIX)) {
        BUG("Called getNonBridgedEgressFieldName on ingress fieldname %1%", ingressName);
        return cstring();
    }
    cstring egressBridgedName = getEgressFieldName(ingressName);
    for (auto kv : egressBridgedMap) {
        if (kv.second == egressBridgedName)
            return kv.first;
    }
    return egressBridgedName;
}

int RepackFlexHeaders::getHeaderBits(const IR::Header* h) const {
    int rv = 0;
    for (auto f : h->type->fields)
        rv += f->type->width_bits();
    return rv;
}

int RepackFlexHeaders::getHeaderBytes(const IR::Header* h) const {
    int bits = getHeaderBits(h);
    BUG_CHECK(bits % 8 == 0, "Serializer packing produces a nonbyte-aligned header %1%", h->name);
    return (bits / 8);
}

unsigned RepackFlexHeaders::getFlexTypeBits(const IR::BFN::Type_StructFlexible* flexType) const {
    int rv = 0;
    for (auto f : flexType->fields) {
        if (f->is<IR::BFN::Type_StructFlexible>())
            ::error("Nested flexible structs are not supported.");
        rv += f->type->width_bits();
    }
    return rv;
}

bool RepackFlexHeaders::hasCommonAction(
        ordered_set<const IR::MAU::Action*>& set1,
        ordered_set<const IR::MAU::Action*>& set2) const {
    // Ignore the action BRIDGED_INIT_ACTION_NAME added for bridged metadata initialization.
    for (const auto* a : set1) {
        if (a->name == BRIDGED_INIT_ACTION_NAME) continue;
        for (const auto* b : set2) {
            if (b->name == BRIDGED_INIT_ACTION_NAME) continue;
            if (a == b)
                return true; } }
    return false;
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
        egressFields.insert(egressField);
        otherGressMapping[egressField] = f;
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

SymBitMatrix RepackFlexHeaders::bridgedActionAnalysis(
        cstring hdrName,
        std::vector<const IR::StructField*>& nonByteAlignedFields) {
    ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Action*>> fieldToActionWrites;
    ordered_set<const PHV::Field*> fields;
    for (auto f : nonByteAlignedFields) {
        cstring fieldName = getFieldName(hdrName, f);
        const auto* field = phv.field(fieldName);
        BUG_CHECK(field, "Field corresponding to name %1% not found", fieldName);
        fields.insert(field);
        fieldToActionWrites[field] = actionConstraints.actions_writing_fields(field); }

    SymBitMatrix mustPackMatrix = mustPack(fields);

    // Conservatively, mark fields that are written in the same action as do not pack. Also,
    for (const auto* field1 : fields) {
        bool isSpecialityDest1 = actionConstraints.hasSpecialityReads(field1);
        bool isMoveOnlyDest1 = actionConstraints.move_only_operations(field1);
        bool hasNoPack1 = alloc.isNoPackField(field1->name);
        BUG_CHECK(fieldToActionWrites.count(field1), "Did not find actions writing to field %1%",
                  field1->name);
        for (const auto* field2 : fields) {
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
            } else if (phase0Fields.count(field1) || phase0Fields.count(field2)) {
                // Do not pack fields together if one or more of them is initialized in phase 0.
                doNotPack(field1->id, field2->id) = true;
                printNoPackConstraint("Phase 0 conflict", field1, field2); } } }
    return mustPackMatrix;
}

ordered_map<const IR::StructField*, int> RepackFlexHeaders::packWithField(
        const int alignment,
        cstring hdrName,
        const IR::StructField* f,
        const std::vector<const IR::StructField*>& candidates,
        const ordered_set<const PHV::Field*>& alreadyPackedFields,
        const ordered_map<const IR::StructField*, le_bitrange>& alignmentConstraints,
        const ordered_map<const IR::StructField*, std::set<int>>& conflictingAlignmentConstraints,
        const SymBitMatrix& mustPack) const {
    static ordered_map<const IR::StructField*, int> emptyMap;
    ordered_map<const IR::StructField*, int> rv;
    ordered_set<const IR::StructField*> potentiallyPackableFields;
    const PHV::Field* field1 = phv.field(getFieldName(hdrName, f));
    potentiallyPackableFields.insert(f);
    LOG4("\tPack with field: " << field1->name << " alignment: " << alignment);

    ordered_map<const PHV::Field*, const IR::StructField*> mustPackFields;
    for (auto f2 : candidates) {
        const PHV::Field* field2 = phv.field(getFieldName(hdrName, f2));
        if (field1 == field2) continue;
        if (mustPack(field1->id, field2->id)) {
            LOG4("\t\tDetected must pack field " << field2->name);
            mustPackFields[field2] = f2;
        }
    }

    int totalMustPackSize = field1->size;
    for (auto kv : mustPackFields)
        totalMustPackSize += kv.first->size;
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
    for (auto f2 : candidates) {
        const PHV::Field* field2 = phv.field(getFieldName(hdrName, f2));
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
        if (conflictingAlignmentConstraints.count(f2)) {
            LOG5("\t\tG. Detected field with conflicting alignment requirements " << field2->name);
            continue; }
        bool packingOkay = true;
        // Ensure that the field under consideration can be packed with every other field in the
        // potentiallyPackableFields set.
        for (auto kv : potentiallyPackableFields) {
            const PHV::Field* field3 = phv.field(getFieldName(hdrName, kv));
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
            packing.insert(phv.field(getFieldName(hdrName, f)));
        packing.insert(field2);
        if (!actionConstraints.checkBridgedPackingConstraints(packing)) {
            LOG4("\t\tE. Packing violates action constraints " << field2->name);
            continue; }
        LOG4("\t\tF. Potentially packable field " << field2->name);
        potentiallyPackableFields.insert(f2); }

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
            for (auto kv : mustPackFields)
                LOG4("\t\t" << kv.first->name);
        }
    }

    // Check if any of the potentially packable fields have mutually conflicting alignment
    // requirements. For instance, field A may be required at bit position 2, which field B may be
    // required at bit positions 1-3 (3 bit field). In that case, A and B can never be packed in the
    // same byte. After a call to checkPotentialPackAlignmentReqs(), alignmentConflicts represents
    // the set of fields that have conflicting alignment requirements.
    ordered_set<const IR::StructField*> alignmentConflicts =
        checkPotentialPackAlignmentReqs(alignmentConstraints, potentiallyPackableFields, f);
    ordered_set<const IR::StructField*> packedFields;
    // Pack the base field f first, if it has an alignment constraint.
    if (alignmentConstraints.count(f)) {
        int lo = alignmentConstraints.at(f).lo;
        for (int i = lo; i < lo + field1->size; i++)
            unOccupied.erase(i);
        LOG4("\t\t  Allocating base field " << f << " to bit " << lo);
        rv[f] = lo;
        packedFields.insert(f);
    }
    // Pack must pack fields next.
    if (mustPackFields.size() > 0) {
        LOG4("\t\tAttempting to pack must pack fields next.");
        for (auto kv : mustPackFields) {
            LOG4("\t\t  Checking packing for must pack field " << kv.first->name);
            LOG4("\t\t\tUnoccupied bits: " << unOccupied);
            if (unOccupied.size() == 0 || kv.first->size > static_cast<int>(unOccupied.size()))
                return rv;
            int lo = alignmentConstraints.at(kv.second).lo;
            LOG4("\t\t\tMust be aligned at bit: " << lo);
            for (int i = lo; i < lo + kv.first->size; i++) {
                if (!(unOccupied.count(i))) {
                    // throw error here?
                    LOG4("\t\t  Cannot pack must pack fields together. Therefore, not packing "
                         "anything with candidate field");
                    return rv;
                }
                unOccupied.erase(i);
            }
            rv[kv.second] = lo;
            LOG4("\t\t  Allocating must pack field " << kv.first->name << " to bit " << lo);
            packedFields.insert(kv.second);
        }
    }
    // Pack fields without alignment constraints next.
    for (const IR::StructField* candidate : potentiallyPackableFields) {
        if (packedFields.count(candidate)) continue;
        LOG4("\t\t  Checking packing for " << candidate);
        LOG4("\t\t\tUnoccupied bits: " << unOccupied);
        if (unOccupied.size() == 0 || candidate->type->width_bits() >
                static_cast<int>(unOccupied.size()))
            return rv;
        if (!alignmentConstraints.count(candidate)) {
            for (int b : unOccupied) {
                bool noIssues = true;
                // Make sure all bits can be allocated consecutively.
                for (int i = 0; i < candidate->type->width_bits(); i++) {
                    if (!unOccupied.count(b+i)) {
                        LOG4("\t\t\tCannot allocate field " << candidate << " to position " <<
                                (b+i));
                        noIssues = false;
                        break; } }
                if (noIssues) {
                    rv[candidate] = b;
                    for (int i = 0; i < candidate->type->width_bits(); i++) {
                        LOG4("\t\t\tErasing bit " << (b+i));
                        unOccupied.erase(b+i); }
                    break; } }
        } else {
            LOG4("\t\t\tIgnoring field " << candidate << " because it has an alignment "
                 "constraint.");
        }
    }
    return rv;
}

ordered_set<const IR::StructField*> RepackFlexHeaders::checkPotentialPackAlignmentReqs(
        const ordered_map<const IR::StructField*, le_bitrange>& alignmentConstraints,
        ordered_set<const IR::StructField*>& potentiallyPackableFields,
        const IR::StructField* field) const {
    // Extract fields with alignment constraints.
    ordered_set<const IR::StructField*> alignedFields;
    if (alignmentConstraints.count(field))
        alignedFields.insert(field);
    for (auto* f : potentiallyPackableFields)
        if (alignmentConstraints.count(f))
            alignedFields.insert(f);
    // Check mutual alignment constraints for alignedFields.
    ordered_set<const IR::StructField*> conflictingFields;
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
            if (f1->type->width_bits() < f2->type->width_bits())
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
        cstring hdrName,
        const std::vector<const IR::StructField*>& nonByteAlignedFields,
        ordered_map<const IR::StructField*, le_bitrange>& alignmentConstraints,
        ordered_map<const IR::StructField*, std::set<int>>& conflictingAlignmentConstraints,
        ordered_set<const IR::StructField*>& mustAlignFields) {
    for (auto structField : nonByteAlignedFields) {
        ordered_set<const PHV::Field*> relatedFields;
        std::queue<const PHV::Field*> fieldsNotVisited;
        cstring fieldName = getFieldName(hdrName, structField);
        const auto* field = phv.field(fieldName);
        BUG_CHECK(field, "No field named %1% found", fieldName);
        LOG4("\tDetermining alignment constraint for " << fieldName);

        // If this field is initialized by a ComputedRVal expression in the parser, then consider it
        // as having alignment constraints.
        if (parserAlignedFields.count(field) && field->alignment) {
            alignmentConstraints[structField] = le_bitrange(StartLen(field->alignment->littleEndian,
                        field->size));
            LOG4("\t\tDetected bit in byte alignment " << alignmentConstraints[structField] <<
                 " for field " << field->name); }

        // DeparserParams must be in the bottom bits.
        if (deparserParams.count(field)) {
            if (alignmentConstraints.count(structField)) {
                ::warning("Alignment constraint already present for field %1%: %2%", structField,
                        alignmentConstraints.at(structField).lo);
                conflictingAlignmentConstraints[structField].insert(
                        alignmentConstraints.at(structField).lo);
            } else {
                alignmentConstraints[structField] = le_bitrange(StartLen(0, field->size));
                LOG4("\t\tDetected deparser parameter alignment: "  <<
                     alignmentConstraints[structField] << " for field " << field->name); } }

        // Also summarize the egress version of this field, as alignment constraints may be induced
        // by uses of the egress version of the bridged field.
        cstring egressFieldName = getNonBridgedEgressFieldName(fieldName);
        BUG_CHECK(egressFieldName, "No egress version of the field %1%", fieldName);
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
            LOG6("\t\t  Now, we have " << fieldsNotVisited.size() << " fields unvisited"); }

        if (LOGGING(4) && relatedFields.count(field) == 0) {
            LOG4("\t  No related fields");
            continue; }

        for (const PHV::Field* f : relatedFields) {
            LOG5("\t  Related field: " << f);
            if (f->alignment) {
                LOG5("\t\t  New alignment: " << *(f->alignment));
                // If the field must be aligned at this bit position (instead of not being aligned
                // and instead satisfying constraints because of deposit-field operations),
                if (mustAlign(f)) {
                    LOG5("\t\t  Field " << structField->name << " must be placed at the given "
                            "alignment " << *(f->alignment));
                    mustAlignFields.insert(structField); }
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
                    WARN_CHECK(f->alignment->littleEndian == alignSource->alignment->littleEndian,
                               "Conflicting alignment constraints detected for bridged field %1%"
                               ": %2%, %3%", field->name, f->alignment->littleEndian,
                               alignSource->alignment->littleEndian);
                    conflictingAlignmentConstraints[structField].insert(f->alignment->littleEndian);
                    conflictingAlignmentConstraints[structField].insert(
                            alignSource->alignment->littleEndian);
                    LOG5("\t\t  Conflicting alignment constraint detected for " << structField);
                    continue; }
                fieldAlignmentMap[field] = f;
                le_bitrange alignment = StartLen(f->alignment->littleEndian, f->size);
                alignmentConstraints[structField] = alignment; } } }
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

cstring RepackFlexHeaders::getFlexStructName(
        const IR::Header* h,
        const IR::BFN::Type_StructFlexible* flexType) {
    cstring rv = h->name;
    for (auto f : h->type->fields) {
        if (!f->type->is<IR::BFN::Type_StructFlexible>()) continue;
        const IR::BFN::Type_StructFlexible* candidate = f->type->to<IR::BFN::Type_StructFlexible>();
        if (flexType != candidate) continue;
        rv += "." + f->name;
        return rv;
    }
    return rv;
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

IR::Type_Struct* RepackFlexHeaders::repackFlexibleStruct(
        const IR::Header* h,
        const IR::StructField* flex) {
    const IR::BFN::Type_StructFlexible* flexType = flex->type->to<IR::BFN::Type_StructFlexible>();
    BUG_CHECK(flexType, "Flexible struct type could not be derived");
    cstring structName = RepackFlexHeaders::getFlexStructName(h, flexType);
    LOG1("Flexible struct name: " << structName);
    if (structName == h->name)
        BUG("Did not get name corresponding to flexible struct in header %1%", h->name);
    if (structName.startsWith(EGRESS_FIELD_PREFIX))
        BUG("Cannot repack egress header %1%", h->name);

    LOG1("Original flexible struct layout: " << flexType);
    LOG1("Size of original flexible struct: " << getFlexTypeBits(flexType));
    // Fields that will form the basis of the new repacked header.
    IR::IndexedVector<IR::StructField> fields;
    // Non byte algined fields in the header.
    std::vector<const IR::StructField*> nonByteAlignedFields;
    for (auto f : flexType->fields) {
        // Ignore existing padding fields.
        if (f->getAnnotations()->getSingle("hidden") != nullptr) continue;
        if (f->type->width_bits() % 8 == 0) {
            // Add byte aligned fields directly into the new type.
            IR::ID newName(flex->name + "." + f->name);
            IR::StructField* newField = new IR::StructField(newName, f->annotations, f->type);
            fields.push_back(newField);
            continue;
        }
        nonByteAlignedFields.push_back(f);
    }
    LOG4("Added " << fields.size() << " byte aligned fields.");
    LOG4("Number of non byte aligned fields: " << nonByteAlignedFields.size());

    // Sort the nonbyte aligned fields according to size.
    std::sort(nonByteAlignedFields.begin(), nonByteAlignedFields.end(),
        [&](const IR::StructField* a, const IR::StructField* b) {
            return a->type->width_bits() < b->type->width_bits();
    });

    // Logging information about nonbyte-aligned fields.
    if (LOGGING(4)) {
        for (auto f : nonByteAlignedFields) {
            const auto* field = phv.field(structName + "." + f->name);
            LOG4("\tField: " << f->name << " (" << f->type->width_bits() << "b)");
            LOG4("\t  PHV Field: " << field);
            if (field->alignment)
                LOG4("\t  Compute Alignment: " << *(field->alignment));
        }
    }

    auto sliceListAlignment = bridgedActionAnalysis(structName, nonByteAlignedFields);
    // Determine nonbyte-aligned bridged fields with alignment constraints.
    ordered_map<const IR::StructField*, le_bitrange> alignmentConstraints;
    ordered_map<const IR::StructField*, std::set<int>> conflictingAlignmentConstraints;
    ordered_set<const IR::StructField*> mustAlignFields;
    determineAlignmentConstraints(structName, nonByteAlignedFields, alignmentConstraints,
            conflictingAlignmentConstraints, mustAlignFields);

    unsigned padFieldId = 0;
    ordered_set<const PHV::Field*> alreadyPackedFields;
    for (auto f1 : nonByteAlignedFields) {
        const PHV::Field* tempField = phv.field(getFieldName(structName, f1));
        if (alreadyPackedFields.count(tempField)) {
            LOG4("\t  A. Already packed " << tempField->name);
            continue; }
        std::vector<const IR::StructField*> fieldsPackedTogether;
        fieldsPackedTogether.push_back(f1);
        LOG3("\tTrying to pack fields with " << tempField->name);
        // If this has alignment constraints due to the parser, ensure we pad it correctly.
        int alignment = getAlignment(f1->type->width_bits());
        LOG4("\t  Alignment: " << alignment);
        ordered_set<const IR::StructField*> addedPadding;
        ordered_map<const IR::StructField*, int> packingWithPositions;
        if (parserAlignedFields.count(tempField)) {
            LOG4("\t\t  F. No other field packed because parser aligned field: " << f1);
            const PHV::Field* source = parserAlignedFields.at(tempField);
            if (source->alignment) {
                LOG4("\t\tAlignment constraint on " << tempField << " : " << *(source->alignment) <<
                     " " << source->alignment->littleEndian);
                packingWithPositions[f1] = source->alignment->littleEndian;
            }
        } else {
            packingWithPositions = packWithField(alignment, structName, f1, nonByteAlignedFields,
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

        fieldsPackedTogether.clear();
        // Total number of bits in this required packing.
        int totalPackSize = 0;
        int totalAllocatedSize = 0;

        for (auto kv : packingWithPositions)
            totalAllocatedSize += kv.first->type->width_bits();
        totalPackSize = 8 * ROUNDUP(totalAllocatedSize, 8);

        // Fields with conflicting alignment are always packed by themselves.
        if (packingWithPositions.size() == 1) {
            for (auto kv : packingWithPositions) {
                if (!conflictingAlignmentConstraints.count(kv.first)) break;
                cstring conflictingName = getFieldName(structName, kv.first);
                const PHV::Field* conflictingField = phv.field(conflictingName);
                BUG_CHECK(conflictingField, "No field object for conflicting field %1%",
                          conflictingName);
                LOG4("\t\t  Field " << conflictingField->name << " has conflicting alignment.");
                int maxSpaceRequired = -1;
                // For fields with conflicting alignment, check if any of the potential alignments
                // require the field to be packed in a chunk that is larger than the next
                // byte-aligned chunk size. The required size is represented by the maxSpaceRequired
                // variable.
                std::set<int> conflictingPositions = conflictingAlignmentConstraints.at(kv.first);
                for (int pos : conflictingPositions) {
                    int req = pos + conflictingField->size;
                    maxSpaceRequired = (maxSpaceRequired < req) ? req : maxSpaceRequired;
                }
                totalPackSize = 8 * ROUNDUP(maxSpaceRequired, 8);
                LOG4("\t\t  Need " << maxSpaceRequired << " bits for field " <<
                     conflictingField->name << " with conflicting alignment constraints.");
            }
        }

        LOG3("\t\tTrying to pack " << totalAllocatedSize << " bits within " << totalPackSize <<
                " bits.");
        ordered_set<int> freeBits;
        for (int i = 0; i < totalPackSize; i++)
            freeBits.insert(i);
        int largestUnoccupiedPosition = totalPackSize - 1;
        LOG3("\t\t  Setting largest unoccupied position to: " << largestUnoccupiedPosition);
        std::vector<const IR::StructField*> packing;
        ordered_set<const IR::StructField*> padFields;
        while (!freeBits.empty()) {
            int largestPosition = -1;
            const IR::StructField* candidate = nullptr;
            for (auto kv : packingWithPositions) {
                if (largestPosition < kv.second) {
                    candidate = kv.first;
                    largestPosition = kv.second;
                }
            }
            LOG6("\t\t\tLargest position: " << largestPosition);
            if (candidate)
                LOG6("\t\t\tCandidate width: " << candidate->type->width_bits());
            if (!candidate) {
                // Insert padding field as no more candidates left for packing.
                int padSize = freeBits.size();
                if (padSize == 0) break;
                LOG4("\t\t  Need to insert padding of size: " << padSize);
                const IR::StructField* padField = getPaddingField(padSize, padFieldId++);
                LOG4("\t\t  Padding field: " << padField);
                padFields.insert(padField);
                fieldsPackedTogether.push_back(padField);
                freeBits.clear();
                largestUnoccupiedPosition = -1;
                break;
            } else {
                int outerLimitForField = largestPosition + candidate->type->width_bits() - 1;
                LOG5("\t\t  outerLimitForField: " << outerLimitForField << ", largestUnocc: " <<
                        largestUnoccupiedPosition);
                if (outerLimitForField < largestUnoccupiedPosition) {
                    // Insert padding in the appropriate place for the field first.
                    int padSize = largestUnoccupiedPosition - outerLimitForField;
                    if (padSize != 0) {
                        LOG4("\t\t  Need to insert padding before field of size: " <<
                                (largestUnoccupiedPosition - outerLimitForField));
                        const IR::StructField* padField = getPaddingField(padSize,
                                padFieldId++);
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
            cstring alreadyPackedFieldName = getFieldName(structName,
                    candidate);
            const PHV::Field* packingField = phv.field(alreadyPackedFieldName);
            LOG5("\t\tInserting into already packed field: " << alreadyPackedFieldName);
            alreadyPackedFields.insert(packingField);
            LOG5("\t\tInserting " << packingField->name << " into already packed fields.");
        }

        ordered_set<cstring> fieldsExtractedTogether;
        for (auto it = fieldsPackedTogether.begin(); it != fieldsPackedTogether.end(); ++it) {
            cstring fieldName = getFieldName(structName, *it);
            LOG4("\t\tA. Pushing field " << fieldName << " of type " << (*it)->type->width_bits() <<
                    "b.");
            if (padFields.count(*it))
                paddingFieldNames.insert(fieldName);
            IR::ID newName(flex->name + "." + (*it)->name);
            IR::StructField* newField = new IR::StructField(newName, (*it)->annotations,
                    (*it)->type);
            fieldsExtractedTogether.insert(newName);
            fields.push_back(newField);
        }
        for (auto f1 : fieldsExtractedTogether) {
            for (auto f2 : fieldsExtractedTogether) {
                if (f1 == f2) continue;
                cstring fName1 = h->name + "." + f1;
                cstring fName2 = h->name + "." + f2;
                extractedTogether[fName1].insert(fName2);
                extractedTogether[fName2].insert(fName1);
            }
        }
    }

    auto* repackedType = new IR::Type_Struct(flexType->name, flexType->annotations, fields);
    return repackedType;
}

bool RepackFlexHeaders::isFlexibleHeader(const IR::Header* h) {
    bool foundFlexibleStruct = false;
    for (auto f : h->type->fields) {
        if (f->type->is<IR::BFN::Type_StructFlexible>()) {
            foundFlexibleStruct = true;
            headerToFlexibleStructsMap[h].insert(f);
            flexibleStructs.insert(f->type);
        }
    }
    return foundFlexibleStruct;
}

IR::Node* RepackFlexHeaders::preorder(IR::Header* h) {
    if (!isFlexibleHeader(h)) return h;
    LOG3("Candidate flexible header found: " << h->name);
    LOG3("Candidate header type: " << h->type);
    LOG3("Candidate header size: " << getHeaderBits(h) << "b");
    // Only process bridged metadata headers.
    cstring headerName = h->name;
    // If it is an egress header, take its new type from the repacked ingress version.
    if (headerName.startsWith(EGRESS_FIELD_PREFIX)) {
        cstring ingressName = getIngressFieldName(headerName);
        if (!repackedHeaders.count(ingressName))
            BUG("Cannot find repacking corresponding to ingress header %1%", ingressName);
        auto* egressHeaderType = new IR::Type_Header(h->type->name, h->type->annotations,
                repackedHeaders.at(ingressName)->type->fields);
        auto* egressRepackedHeader = new IR::Header(headerName, egressHeaderType);
        repackedHeaders[headerName] = egressRepackedHeader;
        LOG1("Repacked egress header: " << egressRepackedHeader);
        LOG1("Repacked egress header type: " << egressHeaderType);
        LOG1("Repacked egress header size: " << getHeaderBytes(egressRepackedHeader) << "B");
        return egressRepackedHeader;
    }

    for (auto kv : headerToFlexibleStructsMap) {
        LOG3("  " << kv.second.size() << " flexible structs in header " << h->name);
        for (auto flex : kv.second) {
            const auto* flexType = flex->type->to<IR::BFN::Type_StructFlexible>();
            ingressFlexibleTypes[flexType] = repackFlexibleStruct(h, flex);
        }
    }

    IR::IndexedVector<IR::StructField> fields;
    for (auto f : h->type->fields) {
        if (!f->type->is<IR::BFN::Type_StructFlexible>()) {
            fields.push_back(f);
            continue;
        }
        const IR::BFN::Type_StructFlexible* flexType = f->type->to<IR::BFN::Type_StructFlexible>();
        if (!ingressFlexibleTypes.count(flexType))
            BUG("Repacking not done for flexible type %1%", f->name);
        for (auto f1 : ingressFlexibleTypes.at(flexType)->fields)
            fields.push_back(f1);
    }
    auto* repackedHeaderType = new IR::Type_Header(h->type->name, h->type->annotations, fields);
    auto* repackedHeader = new IR::Header(h->name, repackedHeaderType);
    repackedHeaders[headerName] = repackedHeader;
    LOG1("Repacked header: " << repackedHeader->name);
    LOG1("Repacked header type: " << repackedHeader->type);
    LOG1("Repacked header size: " << getHeaderBytes(repackedHeader) << "B");
    return repackedHeader;
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

bool ProduceParserMappings::preorder(const IR::Header* h) {
    headerNameToRefMap[h->name] = h;
    // At this point, header is flattened, so safe to do this.
    for (auto f : h->type->fields) {
        cstring name = h->name + "." + f->name;
        IR::Member* mem = gen_fieldref(h, f->name);
        if (!mem) BUG("Could not produce member corresponding to %1%", f->name);
        bridgedToExpressionsMap[name] = mem;
    }
    return false;
}

void ReplaceFlexFieldUses::addBridgedFields(const IR::Header* header) {
    if (!header) return;
    for (auto f : header->type->fields) {
        cstring fieldName = pack.getFieldName(header->name, f);
        bridgedFields[fieldName] = f->type;
    }
}

Visitor::profile_t ReplaceFlexFieldUses::init_apply(const IR::Node* root) {
    bridgedFields.clear();
    repackedHeaders.clear();
    parserStatesToModify.clear();
    emitsToBeReplaced.clear();
    fieldsToReplace.clear();
    egressBridgedMap.clear();
    reverseEgressBridgedMap.clear();
    extractedTogether.clear();

    repackedHeaders = pack.getRepackedHeaders();
    for (const auto* h : repackedHeaders)
        addBridgedFields(h);

    if (bridgedFields.size() > 0) {
        LOG3("\tNumber of flexible fields: " << bridgedFields.size());
        for (auto kv : bridgedFields)
            LOG3("\t  " << kv.first << " (" << kv.second->width_bits() << "b)");
    }

    auto& hdrToFlex = pack.getHeaderToFlexibleStructsMap();
    for (auto kv : hdrToFlex) {
        for (auto flex : kv.second) {
            const auto* flexType = flex->type->to<IR::BFN::Type_StructFlexible>();
            for (auto f : flexType->fields)
                fieldsToReplace.insert(kv.first->name + "." + flex->name + "." + f->name);
        }
    }

    return Transform::init_apply(root);
}

IR::Node* ReplaceFlexFieldUses::preorder(IR::BFN::Pipe* pipe) {
    // If there are no bridged fields, avoid the IR traversal because there are no bridged metadata
    // fields whose uses must be replaced.
    if (bridgedFields.size() == 0) prune();
    return pipe;
}

IR::Node* ReplaceFlexFieldUses::preorder(IR::BFN::ParserState* ps) {
    bool extractToBridgedMetadataFound = false;
    for (auto stmt : ps->statements)
        if (const auto* e = stmt->to<IR::BFN::Extract>())
            extractToBridgedMetadataFound |= processExtract(e);
    if (extractToBridgedMetadataFound) {
        LOG4("\t  Must modify parser state: " << ps->name);
        parserStatesToModify.insert(ps);
    }
    return ps;
}

IR::Node* ReplaceFlexFieldUses::preorder(IR::BFN::Extract* e) {
    const auto* ps = findContext<IR::BFN::ParserState>();
    if (!parserStatesToModify.count(ps)) return e;
    if (!e->source->is<IR::BFN::ComputedRVal>()) return e;
    auto* computedVal = e->source->to<IR::BFN::ComputedRVal>();
    auto* destField = e->dest->to<IR::BFN::FieldLVal>();
    if (!destField) return e;
    const PHV::Field* dest = phv.field(destField->field);
    const PHV::Field* source = phv.field(computedVal->source);
    if (!dest || !source) return e;
    egressBridgedMap[source->name] = dest->name;
    reverseEgressBridgedMap[dest->name] = source->name;
    return e;
}

const std::vector<IR::BFN::Extract*> ReplaceFlexFieldUses::getNewExtracts(
        cstring h,
        unsigned& packetOffset) const {
    std::vector<IR::BFN::Extract*> rv;
    const IR::Header* hdr = info.getHeaderRefForName(h);
    BUG_CHECK(hdr, "No header object corresponding to name %1%", h);
    // At this point, the header type is flattened.
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

bool ReplaceFlexFieldUses::processExtract(const IR::BFN::Extract* e) {
    auto* fieldLVal = e->dest->to<IR::BFN::FieldLVal>();
    if (!fieldLVal) return false;
    if (pack.isFlexibleStruct(fieldLVal->field->type)) {
        LOG4("\t  Found flexible type: " << fieldLVal->field->type);
        return true;
    }
    return false;
}

IR::BFN::Extract* ReplaceFlexFieldUses::getNewComputedVal(const IR::BFN::Extract* e) const {
    const IR::BFN::ComputedRVal* source = e->source->to<IR::BFN::ComputedRVal>();
    BUG_CHECK(source, "Cannot get computed source for ComputedRVal object %1%", e);
    const auto* f = phv.field(source->source);
    auto* newE = new IR::BFN::Extract(e->dest, e->source);
    if (!f) return newE;
    if (!fieldsToReplace.count(f->name)) return newE;
    if (!bridgedFields.count(f->name)) return newE;
    LOG4("\t\tFound field to replace: " << e);
    auto& exprMap = info.getBridgedToExpressionsMap();
    if (exprMap.count(f->name)) {
        IR::Member* mem = exprMap.at(f->name);
        IR::BFN::ComputedRVal* source = new IR::BFN::ComputedRVal(mem);
        IR::BFN::Extract* newExtract = new IR::BFN::Extract(e->dest, source);
        LOG4("\t\t  New computed val extract: " << newExtract);
        return newExtract;
    }
    return newE;
}

IR::Node* ReplaceFlexFieldUses::postorder(IR::BFN::ParserState* p) {
    // Only process the parser state which extracts bridged metadata header in the egress pipeline.
    if (!parserStatesToModify.count(p)) return p;

    LOG4("\tPostorder for parser state " << p->name);
    IR::Vector<IR::BFN::ParserPrimitive> statements;
    unsigned packetOffset = 0;
    auto extractedHeaders = info.getExtractedHeaders(p);
    LOG4("\t  Number of extracted headers: " << extractedHeaders.size());
    for (auto s : extractedHeaders)
        LOG4("\t\tHeader: " << s);
    unsigned headerNum = 0;
    for (auto stmt : p->statements) {
        auto* extract = stmt->to<IR::BFN::Extract>();
        if (!extract) {
            statements.push_back(stmt);
            continue;
        }
        auto* rval = extract->source->to<IR::BFN::PacketRVal>();
        auto* cval = extract->source->to<IR::BFN::ComputedRVal>();
        if (!rval && !cval) {
            statements.push_back(stmt);
            continue;
        }
        if (cval) {
            statements.push_back(getNewComputedVal(extract));
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
            for (auto* e : newExtracts)
                statements.push_back(e);
            ++headerNum;
        }
    }

    BUG_CHECK(packetOffset % 8 == 0, "Non byte aligned packet bits extracted in %1%", p->name);
    unsigned packetOffsetBytes = packetOffset / 8;
    IR::Vector<IR::BFN::Transition> transitions;
    for (auto t : p->transitions) {
        auto* value = t->value;
        BUG_CHECK(value, "No value attached to transition %1%", t);
        auto* constValue = value->to<IR::BFN::ParserConstMatchValue>();
        BUG_CHECK(constValue, "No constant value attached to transition %1%", t);
        auto* newTransition = new IR::BFN::Transition(constValue->value, packetOffsetBytes,
                t->next);
        newTransition->saves = t->saves;
        transitions.push_back(newTransition);
    }
    IR::BFN::ParserState* newParserState = new IR::BFN::ParserState(p->name, p->gress, statements,
            p->selects, transitions);
    LOG3("\tNew parser state:\n" << newParserState);
    return newParserState;
}

IR::Node* ReplaceFlexFieldUses::preorder(IR::BFN::EmitField* e) {
    if (e->source->field->type->is<IR::BFN::Type_StructFlexible>()) {
        const auto* f = phv.field(e->source->field);
        BUG_CHECK(f, "Field object corresponding to %1% not found", e->source->field);
        emitsToBeReplaced.insert(f->header());
        LOG4("\t\tInsert " << f->header() << " to emits to be replaced");
    }
    return e;
}

const std::vector<IR::BFN::EmitField*>
ReplaceFlexFieldUses::getNewEmits(
        const IR::Header* h,
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
            const IR::Header* h = info.getHeaderRefForName(f->header());
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
        cstring key = pack.getEgressFieldName(kv.first);
        if (egressBridgedMap.count(key))
            key = egressBridgedMap.at(key);
        LOG6("\t\tKey: " << key);
        for (auto s : kv.second) {
            if (paddingFieldNames.count(s)) continue;
            cstring value = pack.getEgressFieldName(s);
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
            DependencyGraph& dg,
            CollectBridgedFields& b,
            ordered_map<cstring, ordered_set<cstring>>& e,
            const MauBacktracker& alloc)
    : Logging::PassManager("bridge_metadata_"),
      bridgedFields(b),
      packConflicts(p, dg, tMutex, alloc, aMutex),
      actionConstraints(p, packConflicts),
      packHeaders(p, b, actionConstraints, doNotPack, phase0Fields, deparserParams,
                   parserAlignedFields, alloc),
      parserMappings(p),
      bmUses(p, packHeaders, parserMappings, e) {
          addPasses({
              &bridgedFields,
              new ReplaceOriginalFieldWithBridged(p, bridgedFields),
              new FindDependencyGraph(p, dg),
              &tMutex,
              &aMutex,
              &packConflicts,
              &actionConstraints,
              new GatherDeparserParameters(p, deparserParams),
              new GatherPhase0Fields(p, phase0Fields),
              new GatherParserExtracts(p, parserAlignedFields),
              &packHeaders,
              &parserMappings,
              &bmUses,
              new CollectPhvInfo(p)
          });
}
