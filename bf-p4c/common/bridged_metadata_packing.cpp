#include "bf-p4c/common/bridged_metadata_packing.h"
#include <cstring>
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

cstring PackBridgedMetadata::getEgressFieldName(cstring ingressName) const {
    if (!ingressName.startsWith(INGRESS_FIELD_PREFIX)) {
        BUG("Called getEgressFieldName on ingress fieldname %1%", ingressName);
        return cstring(); }
    // ingress::foo.bar -> egress::foo.bar
    return (EGRESS_FIELD_PREFIX + ingressName.substr(9));
}

cstring
PackBridgedMetadata::getFieldName(const IR::Header* hdr, const IR::StructField* field) const {
    auto name = hdr->name + "." + field->name;
    if (auto* fieldInfo = phv.field(name))
        return fieldInfo->name;
    return name;
}

Visitor::profile_t PackBridgedMetadata::init_apply(const IR::Node* root) {
    ingressBridgedHeader = nullptr;
    egressBridgedHeader = nullptr;
    egressBridgedMap.clear();
    reverseEgressBridgedMap.clear();
    extractedTogether.clear();
    fieldAlignmentMap.clear();
    for (auto kv : fields.bridged_to_orig) {
        cstring origName = getEgressFieldName(kv.second);
        cstring bridgedName = getEgressFieldName(kv.first);
        egressBridgedMap[origName] = bridgedName;
        reverseEgressBridgedMap[bridgedName] = origName;
    }

    if (LOGGING(5)) {
        LOG5("\nPrinting orig to bridged");
        for (auto kv : fields.orig_to_bridged)
            LOG5("\t" << kv.first << " : " << kv.second);
        LOG5("\nPrinting bridged to orig");
        for (auto kv : fields.bridged_to_orig)
            LOG5("\t" << kv.first << " : " << kv.second);
        LOG5("\nPrinting bridged to external");
        for (auto kv : fields.bridged_to_external_name)
            LOG5("\t" << kv.first << " : " << kv.second);
        LOG5("\nPrinting orig to bridged");
        for (auto kv : fields.orig_to_bridged_name)
            LOG5("\t" << kv.first << " : " << kv.second); }
    if (LOGGING(3)) {
        LOG3("\nPrinting egress bridged to external");
        for (auto kv : egressBridgedMap)
            LOG3(kv.first << "\t" << kv.second); }

    return Transform::init_apply(root);
}

cstring PackBridgedMetadata::getNonBridgedEgressFieldName(cstring ingressName) const {
    if (!ingressName.startsWith(INGRESS_FIELD_PREFIX)) {
        BUG("Called getNonBridgedEgressFieldName on ingress fieldname %1%", ingressName);
        return cstring();
    }
    cstring egressBridgedName = getEgressFieldName(ingressName);
    for (auto kv : egressBridgedMap) {
        if (kv.second == egressBridgedName)
            return kv.first;
    }
    return cstring();
}

int PackBridgedMetadata::getHeaderBytes(const IR::Header* h) const {
    int rv = 0;
    for (auto f : h->type->fields)
        rv += f->type->width_bits();
    return (rv / 8);
}

bool PackBridgedMetadata::hasCommonAction(
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

void PackBridgedMetadata::printNoPackConstraint(
        cstring errorMessage,
        const PHV::Field* f1,
        const PHV::Field* f2) const {
    LOG4("\t" << errorMessage << ": " << f1->name << " (" << f1->id << ") (" << f1->size << "b), "
         << f2->name << " (" << f2->id << ") (" << f2->size << "b)");
}

ordered_set<const IR::MAU::Action*> PackBridgedMetadata::fieldsAccessedSameAction(
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
boost::optional<ordered_map<const PHV::Field*, int>> PackBridgedMetadata::mustBePackedTogether(
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

SymBitMatrix PackBridgedMetadata::mustPack(const ordered_set<const PHV::Field*>& fields) const {
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

SymBitMatrix PackBridgedMetadata::bridgedActionAnalysis(
        const IR::Header* h,
        std::vector<const IR::StructField*>& nonByteAlignedFields) {
    ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Action*>> fieldToActionWrites;
    ordered_set<const PHV::Field*> fields;
    for (auto f : nonByteAlignedFields) {
        cstring fieldName = getFieldName(h, f);
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

ordered_map<const IR::StructField*, int> PackBridgedMetadata::packWithField(
        const int alignment,
        const IR::Header* h,
        const IR::StructField* f,
        const std::vector<const IR::StructField*>& candidates,
        const ordered_set<const PHV::Field*>& alreadyPackedFields,
        const ordered_map<const IR::StructField*, le_bitrange>& alignmentConstraints,
        const ordered_set<const IR::StructField*>& conflictingAlignmentConstraints,
        const SymBitMatrix& mustPack) const {
    static ordered_map<const IR::StructField*, int> emptyMap;
    ordered_map<const IR::StructField*, int> rv;
    ordered_set<const IR::StructField*> potentiallyPackableFields;
    const PHV::Field* field1 = phv.field(getFieldName(h, f));
    potentiallyPackableFields.insert(f);
    LOG4("\tPack with field: " << field1->name);

    ordered_map<const PHV::Field*, const IR::StructField*> mustPackFields;
    for (auto f2 : candidates) {
        const PHV::Field* field2 = phv.field(getFieldName(h, f2));
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
        const PHV::Field* field2 = phv.field(getFieldName(h, f2));
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
            LOG4("\t\tG. Detected field with conflicting alignment requirements " << field2->name);
            continue; }
        bool packingOkay = true;
        // Ensure that the field under consideration can be packed with every other field in the
        // potentiallyPackableFields set.
        for (auto kv : potentiallyPackableFields) {
            const PHV::Field* field3 = phv.field(getFieldName(h, kv));
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
            packing.insert(phv.field(getFieldName(h, f)));
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

ordered_set<const IR::StructField*> PackBridgedMetadata::checkPotentialPackAlignmentReqs(
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

void PackBridgedMetadata::determineAlignmentConstraints(
        const IR::Header* h,
        const std::vector<const IR::StructField*>& nonByteAlignedFields,
        ordered_map<const IR::StructField*, le_bitrange>& alignmentConstraints,
        ordered_set<const IR::StructField*>& conflictingAlignmentConstraints,
        ordered_set<const IR::StructField*>& mustAlignFields) {
    for (auto structField : nonByteAlignedFields) {
        ordered_set<const PHV::Field*> relatedFields;
        std::queue<const PHV::Field*> fieldsNotVisited;
        cstring fieldName = getFieldName(h, structField);
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
                conflictingAlignmentConstraints.insert(structField);
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
                    conflictingAlignmentConstraints.insert(structField);
                    LOG5("\t\t  Conflicting alignment constraint detected for " << structField);
                    continue; }
                fieldAlignmentMap[field] = f;
                le_bitrange alignment = StartLen(f->alignment->littleEndian, f->size);
                alignmentConstraints[structField] = alignment; } } }
    if (LOGGING(4)) {
        LOG4("\tPrinting bridged fields with alignment constraints:");
        for (auto kv : alignmentConstraints)
            LOG4("\t  " << kv.first << " : " << kv.second);
        LOG4("\tPrinting bridged fields with conflicting constraints:");
        for (auto f : conflictingAlignmentConstraints)
            LOG4("\t  " << f);
    }
}

bool PackBridgedMetadata::mustAlign(const PHV::Field* field) const {
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

const IR::StructField* PackBridgedMetadata::getPaddingField(int size, int id) {
    cstring padFieldName = "__pad_" + cstring::to_cstring(id);
    auto* fieldAnnotations = new IR::Annotations({new IR::Annotation(IR::ID("hidden"), { })
            });
    const IR::StructField* padField = new IR::StructField(padFieldName,
            fieldAnnotations, IR::Type::Bits::get(size));
    return padField;
}

IR::Node* PackBridgedMetadata::preorder(IR::Header* h) {
    auto annotations = h->type->getAnnotations();
    // Ignore nonflexible headers.
    if (annotations->getSingle("layout") == nullptr)
        return h;
    LOG3("Candidate bridged metadata header found: " << h->name);
    LOG3("Candidate header types: " << h->type);
    cstring headerName = h->name;
    // Only process bridged metadata headers.
    if (!headerName.endsWith("^bridged_metadata")) return h;

    // If it is the egress bridged metadata header, then use the packed header created for the
    // ingress bridged metadata header.
    // This assumes that the ingress header will always be packed before the egress header.
    if (headerName.startsWith(EGRESS_FIELD_PREFIX)) {
        if (ingressBridgedHeader == nullptr) {
            BUG("Do not have a bridged header in ingress");
            return h; }
        LOG1("Original Egress header layout: " << h->type);
        LOG1("Size of original egress bridged header: " << getHeaderBytes(h));
        auto* layoutKind = new IR::StringLiteral(IR::ID("flexible"));
        auto* egressBridgedHeaderType = new IR::Type_Header(h->type->name,
            new IR::Annotations({ new IR::Annotation(IR::ID("layout"), {layoutKind}) }),
            ingressBridgedHeader->type->fields);
        LOG1("New Egress Bridged header: " << egressBridgedHeaderType);
        egressBridgedHeader = new IR::Header(h->name, egressBridgedHeaderType);
        LOG1("New size of egress bridged header: " << getHeaderBytes(egressBridgedHeader));
        return egressBridgedHeader; }

    // Ingress bridged metadata header, if it comes here.
    LOG1("Original Ingress header layout: " << h->type);
    LOG1("Size of original ingress bridged header: " << getHeaderBytes(h));
    // Fields that will form the basis of the new repacked header.
    IR::IndexedVector<IR::StructField> fields;
    // Non byte aligned fields in the header.
    std::vector<const IR::StructField*> nonByteAlignedFields;
    for (auto f : h->type->fields) {
        // Ignore existing padding fields.
        if (f->getAnnotations()->getSingle("hidden") != nullptr)
            continue;
        if (f->type->width_bits() % 8 == 0) {
            // Add byte aligned bridged metadata field directly into the header.
            fields.push_back(f);
            continue; }
        nonByteAlignedFields.push_back(f); }

    LOG4("Added " << fields.size() << " byte aligned fields");
    LOG4("Number of nonbyte aligned fields: " << nonByteAlignedFields.size());

    // Sort the nonbyte aligned fields according to size.
    std::sort(nonByteAlignedFields.begin(), nonByteAlignedFields.end(),
        [&](const IR::StructField* a, const IR::StructField* b) {
            return a->type->width_bits() < b->type->width_bits();
    });

    // Logging information about nonbyte-aligned bridged metadata fields.
    if (LOGGING(4)) {
        for (auto f : nonByteAlignedFields) {
            const auto* field = phv.field(headerName + "." + f->name);
            LOG4("\tField: " << f->name << " (" << f->type->width_bits() << "b)");
            LOG4("\t  PHV Field: " << field);
            if (field->alignment)
                LOG4("\t  Computed Alignment: " << *(field->alignment)); } }

    // Populate doNotPack matrix based on results of action analysis.
    auto sliceListAlignment = bridgedActionAnalysis(h, nonByteAlignedFields);

    // Determine nonbyte-aligned bridged fields with alignment constraints.
    ordered_map<const IR::StructField*, le_bitrange> alignmentConstraints;
    ordered_set<const IR::StructField*> conflictingAlignmentConstraints;
    ordered_set<const IR::StructField*> mustAlignFields;
    determineAlignmentConstraints(h, nonByteAlignedFields, alignmentConstraints,
            conflictingAlignmentConstraints, mustAlignFields);

    unsigned padFieldId = 0;
    ordered_set<const PHV::Field*> alreadyPackedFields;
    for (auto f1 : nonByteAlignedFields) {
        const PHV::Field* tempField = phv.field(getFieldName(h, f1));
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
            packingWithPositions = packWithField(alignment, h, f1, nonByteAlignedFields,
                    alreadyPackedFields, alignmentConstraints, conflictingAlignmentConstraints,
                    sliceListAlignment);
            LOG3("\t\tResulting packing has " << packingWithPositions.size() << " fields.");
            // Determine fields that must be extracted together on the egress parser.
            for (auto kv : packingWithPositions) {
                cstring fName1 = getEgressFieldName(getFieldName(h, kv.first));
                LOG3("\t\t  " << kv.first << " @ " << kv.second);
                for (auto kv1 : packingWithPositions) {
                    cstring fName2 = getEgressFieldName(getFieldName(h, kv1.first));
                    if (fName1 == fName2) continue;
                    BUG_CHECK(reverseEgressBridgedMap.count(fName1),
                            "No entry in reverse egress bridged map for %1%", fName1);
                    BUG_CHECK(reverseEgressBridgedMap.count(fName2),
                            "No entry in reverse egress bridged map for %1%", fName2);
                    extractedTogether[reverseEgressBridgedMap.at(fName1)].insert(
                            reverseEgressBridgedMap.at(fName2));
                }
            }

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
        LOG3("\t\tTrying to pack " << totalAllocatedSize << " bits within " << totalPackSize <<
                " bits.");
        ordered_set<int> freeBits;
        for (int i = 0; i < totalAllocatedSize; i++)
            freeBits.insert(i);
        int largestUnoccupiedPosition = totalPackSize - 1;
        LOG3("\t\t  Setting largest unoccupied position to: " << largestUnoccupiedPosition);
        std::vector<const IR::StructField*> packing;
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
                        fieldsPackedTogether.push_back(padField);
                    }
                }
            }
            for (int i = largestUnoccupiedPosition; i >= largestPosition; i--)
                freeBits.erase(i);
            largestUnoccupiedPosition = largestPosition - 1;
            LOG5("\t\t  Setting largest unoccupied position to: " << largestUnoccupiedPosition);
            fieldsPackedTogether.push_back(candidate);
            packingWithPositions.erase(candidate);
            const PHV::Field* packingField = phv.field(getFieldName(h, candidate));
            alreadyPackedFields.insert(packingField);
        }

        for (auto it = fieldsPackedTogether.begin(); it != fieldsPackedTogether.end(); ++it) {
            const PHV::Field* fld = phv.field(getFieldName(h, *it));
            LOG4("\t\tPushing field " << fld << " of type " << (*it)->type->width_bits() <<
                    "b.");
            fields.push_back(*it); }
    }

    auto* layoutKind = new IR::StringLiteral(IR::ID("flexible"));
    auto* ingressBridgedHeaderType = new IR::Type_Header(h->type->name,
            new IR::Annotations({ new IR::Annotation(IR::ID("layout"), {layoutKind}) }),
            fields);
    ingressBridgedHeader = new IR::Header(h->name, ingressBridgedHeaderType);
    LOG1("Ingress Bridged header : " << ingressBridgedHeaderType);
    LOG1("New size of ingress bridged header: " << getHeaderBytes(ingressBridgedHeader));

    if (extractedTogether.size() == 0) return ingressBridgedHeader;

    LOG2("  Printing fields that must be extracted together.");
    for (auto kv : extractedTogether) {
        std::stringstream ss;
        ss << "\t" << kv.first << " : ";
        for (auto f : kv.second)
            ss << f << " ";
        LOG2(ss.str());
    }

    return ingressBridgedHeader;
}

void ReplaceBridgedMetadataUses::addBridgedFields(const IR::Header* header) {
    // packetIndex stores the offset within the header.
    unsigned packetIndex = 0;
    if (!header) return;
    for (auto f : header->type->fields) {
        cstring fieldName = pack.getFieldName(header, f);
        LOG3("    Field Name: " << fieldName << " Type: " << f->type << " Offset: " << packetIndex);
        bridgedFields[fieldName] = f->type;
        bridgedOffsets[fieldName] = packetIndex;
        packetIndex += f->type->width_bits(); }
}

Visitor::profile_t ReplaceBridgedMetadataUses::init_apply(const IR::Node* root) {
    newEmits.clear();
    bridgedOffsets.clear();
    bridgedFields.clear();

    LOG3("    Adding bridged fields for ingress");
    addBridgedFields(pack.getIngressBridgedHeader());
    LOG3("    Adding bridged fields for egress");
    addBridgedFields(pack.getEgressBridgedHeader());
    LOG3("    Number of bridged fields: " << bridgedFields.size());

    return Transform::init_apply(root);
}

IR::Node* ReplaceBridgedMetadataUses::preorder(IR::BFN::Pipe* pipe) {
    // If there are no bridged fields, avoid the IR traversal because there are no bridged metadata
    // fields whose uses must be replaced.
    if (bridgedFields.size() == 0)
        prune();
    return pipe;
}

IR::Node* ReplaceBridgedMetadataUses::postorder(IR::BFN::ParserState* p) {
    // Only process the parser state which extracts bridged metadata header in the egress pipeline.
    if (p->name != PackBridgedMetadata::EGRESS_BRIDGED_PARSER_STATE_NAME)
        return p;
    // Update the shift of each transition out of the egress bridged metadata header, taking the new
    // packing into account.
    IR::Vector<IR::BFN::Transition> transitions;
    for (auto t : p->transitions) {
        auto* value = t->value;
        BUG_CHECK(value, "No value attached to transition %1%", t);
        auto* constValue = value->to<IR::BFN::ParserConstMatchValue>();
        BUG_CHECK(constValue, "No constant value attached to transition %1%", t);
        int shift = pack.getHeaderBytes(pack.getEgressBridgedHeader());
        LOG3("    New shift calculated: " << shift);
        auto* newTransition =  new IR::BFN::Transition(constValue->value, shift, t->next);
        newTransition->saves = t->saves;
        transitions.push_back(newTransition); }
    IR::BFN::ParserState* newParserState =
        new IR::BFN::ParserState(p->name, p->gress, p->statements, p->selects, transitions);
    LOG3("    New Parser State: " << newParserState);
    return newParserState;
}

IR::BFN::Extract*
ReplaceBridgedMetadataUses::replaceExtract(const IR::BFN::Extract* e, const PHV::Field* dest) {
    LOG3("\t  Found extract for bridged field " << e);
    auto& egressBridgedMap = pack.getEgressBridgedMap();
    BUG_CHECK(egressBridgedMap.count(dest->name), "No added version of the egress bridged metadata "
              "%1%", dest->name);
    cstring bridgedName = egressBridgedMap.at(dest->name);
    auto bitWidth = bridgedFields.at(bridgedName)->width_bits();
    auto* newSource = new IR::BFN::PacketRVal(StartLen(bridgedOffsets.at(bridgedName), bitWidth));
    auto* newExtract = new IR::BFN::Extract(e->dest, newSource);
    LOG3("\t  Added new extract: " << newExtract);
    return newExtract;
}

IR::Node* ReplaceBridgedMetadataUses::preorder(IR::BFN::Extract* e) {
    auto* state = findContext<IR::BFN::ParserState>();
    if (state->name != PackBridgedMetadata::EGRESS_BRIDGED_PARSER_STATE_NAME)
        return e;
    auto* fieldLVal = e->dest->to<IR::BFN::FieldLVal>();
    if (!fieldLVal) return e;
    auto* f = phv.field(fieldLVal->field);
    if (!f) return e;
    auto& egressBridgedMap = pack.getEgressBridgedMap();
    if (egressBridgedMap.count(f->name)) {
        LOG2("\tReplacing extract for " << f->name);
        return replaceExtract(e, f);
    }
    return e;
}

void ReplaceBridgedMetadataUses::replaceEmit(const IR::BFN::EmitField* e) {
    auto* source = e->source;
    auto* povBit = e->povBit;
    auto* fieldSource = phv.field(source->field);
    // At this point, these emits may correspond to fields that will be removed later by dead code
    // elimination. Therefore, no BUG_CHECK here.
    if (!fieldSource || !bridgedFields.count(fieldSource->name))
        return;
    LOG4("\t  Found emit for bridged field " << e);
    const IR::Member* oldMember = source->field->to<IR::Member>();
    BUG_CHECK(oldMember, "Member corresponding to %1% not found", source->field);
    const IR::Type* type = bridgedFields.at(fieldSource->name);
    const IR::Member* newMember = new IR::Member(source->field->srcInfo, type, new
            IR::ConcreteHeaderRef(pack.getIngressBridgedHeader()), oldMember->member);
    IR::BFN::EmitField* newEmit = new IR::BFN::EmitField(newMember, povBit->field);
    newEmits[fieldSource->name] = newEmit;
    LOG3("\t  New emit: " << newEmit);
}

IR::Node* ReplaceBridgedMetadataUses::preorder(IR::BFN::EmitField* e) {
    const IR::Expression* source = e->source->field;
    const PHV::Field* f = phv.field(source);
    if (!f) return e;
    bool isIngress = f->name.startsWith(PackBridgedMetadata::INGRESS_FIELD_PREFIX);
    bool isBridged = strstr(f->name.c_str(), PackBridgedMetadata::BRIDGED_FIELD_PREFIX);
    if (isIngress && isBridged) {
        replaceEmit(e);
        return nullptr; }
    return e;
}

IR::Node* ReplaceBridgedMetadataUses::postorder(IR::BFN::Deparser* d) {
    if (d->thread() == EGRESS) return d;
    const IR::Header* h = pack.getIngressBridgedHeader();
    unsigned numEmit = 0;
    for (auto it = h->type->fields.rbegin(); it != h->type->fields.rend(); ++it) {
        auto* f = *it;
        cstring fieldName = pack.getFieldName(h, f);
        BUG_CHECK(newEmits.count(fieldName), "New emit corresponding to field name %1% not found",
                fieldName);
        d->emits.insert(d->emits.begin(), newEmits.at(fieldName)); }
    if (LOGGING(3)) {
        for (auto e : d->emits) {
            LOG3("Reprint emit " << ++numEmit << " : " << e); } }
    return d;
}

IR::Node* RemoveUnusedExtracts::preorder(IR::BFN::Extract* e) {
    auto* state = findContext<IR::BFN::ParserState>();
    if (state->name != PackBridgedMetadata::EGRESS_BRIDGED_PARSER_STATE_NAME)
        return e;
    auto* fieldLVal = e->dest->to<IR::BFN::FieldLVal>();
    if (!fieldLVal) return e;
    auto* f = phv.field(fieldLVal->field);
    if (!f) return e;
    bool isEgress = f->name.startsWith(PackBridgedMetadata::EGRESS_FIELD_PREFIX);
    bool isBridged = strstr(f->name.c_str(), PackBridgedMetadata::BRIDGED_FIELD_PREFIX);
    cstring bmIndicator = cstring(PackBridgedMetadata::EGRESS_FIELD_PREFIX) +
                          cstring(BM_INDICATOR);
    if (f->name != bmIndicator && isEgress && isBridged) {
        LOG4("    Removing extract corresponding to egress version of bridged field: " << f);
        return nullptr; }
    return e;
}

BridgedMetadataPacking::BridgedMetadataPacking(
            const PhvInfo& p,
            DependencyGraph& dg,
            CollectBridgedFields& b,
            ordered_map<cstring, ordered_set<cstring>>& e,
            const MauBacktracker& alloc)
    : Logging::PassManager("bridge_metadata_"),
      bridgedFields(b),
      packConflicts(p, dg, tMutex, alloc, aMutex),
      actionConstraints(p, packConflicts),
      packMetadata(p, b, actionConstraints, doNotPack, phase0Fields, deparserParams,
                   parserAlignedFields, e, alloc) {
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
              &packMetadata,
              new ReplaceBridgedMetadataUses(p, packMetadata)
          });
}
