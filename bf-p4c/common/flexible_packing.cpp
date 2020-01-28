#include <cstring>
#include <algorithm>
#include <sstream>

#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/lib/pad_alignment.h"
#include "bf-p4c/phv/cluster_phv_operations.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_atomic.h"
#include "bf-p4c/phv/pragma/pa_container_size.h"
#include "bf-p4c/phv/pragma/pa_solitary.h"
#include "bf-p4c/common/table_printer.h"

// included by PackFlexibleHeaders
#include "bf-p4c/common/alias.h"
#include "bf-p4c/common/check_for_unimplemented_features.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/common/multiple_apply.h"
#include "bf-p4c/mau/empty_controls.h"
#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/mau/push_pop.h"
#include "bf-p4c/mau/selector_update.h"
#include "bf-p4c/mau/stateful_alu.h"
#include "bf-p4c/parde/add_jbay_pov.h"
#include "bf-p4c/parde/egress_packet_length.h"
#include "bf-p4c/parde/stack_push_shims.h"
#include "bf-p4c/phv/create_thread_local_instances.h"
#include "bf-p4c/parde/reset_invalidated_checksum_headers.h"
#include "bf-p4c/phv/privatization.h"

// helper function
bool findFlexibleAnnotation(const IR::Type_StructLike* header) {
    for (auto f : header->fields) {
        auto anno = f->getAnnotation("flexible");
        if (anno != nullptr)
            return true; }
    return false;
}

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
    reverseParserAlignMap[sourceField].insert(f);
    LOG5("    Initialization due to SavedRVal in parser: " << f);
    return true;
}

bool GatherAliasConstraintsInEgress::preorder(const IR::BFN::Extract* extract) {
    const IR::BFN::ParserState* state = findContext<IR::BFN::ParserState>();
    BUG_CHECK(extract->dest, "Extract %1% does not have a destination",
            cstring::to_cstring(extract));
    BUG_CHECK(extract->dest->field, "Extract %1% does not have a destination field",
            cstring::to_cstring(extract));
    const PHV::Field* destField = phv.field(extract->dest->field);
    BUG_CHECK(destField, "Could not find destination field for extract %1%",
            cstring::to_cstring(extract));
    // if destination field is used in arithmetic operation, do not add alias constraint
    if (destField->is_solitary())
        return false;
    if (auto rval = extract->source->to<IR::BFN::SavedRVal>()) {
        if (auto mem = rval->source->to<IR::Member>()) {
            if (mem->expr->is<IR::ConcreteHeaderRef>()) {
                auto srcField = phv.field(mem);
                // only aliasing meta = hdr.f where f is a field with flexible annotation
                if (srcField->is_flexible()) {
                    LOG3("candidate field " << destField << " " << srcField);
                    candidateSourcesInParser[destField][srcField].insert(state);
                }
            }
        }
    }
    return true;
}

void GatherAliasConstraintsInEgress::end_apply() {
    for (auto& f : candidateSourcesInParser) {
        std::stringstream ss;
        ss << "\t  " << f.first->name << ", ";
        const PHV::Field* srcField = nullptr;
        if (f.second.size() > 1) continue;
        for (const auto& kv : f.second) {
            srcField = kv.first;
            ss << kv.first->name << ", ";
            for (const auto* state : kv.second)
                ss << state->name << " ";
        }
        if (bridged_to_orig.count(srcField->name))
            continue;
        if (srcField != nullptr) {
            bridged_to_orig[srcField->name] = f.first->name;
        }
    }
}

/**
 * repackedTypes is shared between RepackDigestFieldList and RepackFlexHeaders.
 * It is cleared here, and maintained when running RepackFlexHeaders.
 * XXX(hanw): assumes RepackDigestFieldList is before RepackFlexHeaders.
 */
Visitor::profile_t RepackDigestFieldList::init_apply(const IR::Node* root) {
    repackedTypes.clear();
    resetState();
    return Transform::init_apply(root);
}

void RepackFlexHeaders::resetState() {
    egressBridgedMap.clear();
    reverseEgressBridgedMap.clear();
    fieldAlignmentMap.clear();
    ingressFlexibleTypes.clear();
    headerToFlexibleStructsMap.clear();
    repackedHeaders.clear();
    originalHeaders.clear();
    paddingFieldNames.clear();
    digestFlexFields.clear();
    clusterFields.clear();

    LOG3("\tNumber of bridged fields: " << aliasInEgress.bridged_to_orig.size());
    for (auto kv : aliasInEgress.bridged_to_orig) {
        egressBridgedMap[kv.second] = kv.first;
        reverseEgressBridgedMap[kv.first] = kv.second;
    }
}

Visitor::profile_t RepackFlexHeaders::init_apply(const IR::Node* root) {
    resetState();
    if (LOGGING(5)) {
        LOG5("\n\tPrinting bridged to orig");
        if (fields.bridged_to_orig.size() > 0) {
            for (auto kv : fields.bridged_to_orig)
                LOG5("\t  " << kv.first << " : " << kv.second);
        }
        if (aliasInEgress.bridged_to_orig.size() > 0) {
            for (auto kv : aliasInEgress.bridged_to_orig)
                LOG5("\t  " << kv.first << " : " << kv.second);
        }
    }
    if (LOGGING(3) && egressBridgedMap.size() > 0) {
        LOG3("\n\tPrinting egress bridged to external");
        for (auto kv : egressBridgedMap)
            LOG3("\t  " << kv.first << "\t" << kv.second); }

    LOG3("Printing parser aligned fields");
    for (auto kv : parserAlignedFields.getAlignedMap()) {
        LOG3("\tField: " << kv.first);
        for (auto* f : kv.second)
            LOG3("\t\t" << f);
    }


    return Transform::init_apply(root);
}

// FIXME:
cstring RepackFlexHeaders::getNonBridgedEgressFieldName(cstring fName) const {
    cstring egressBridgedName;
    if (fName.startsWith(EGRESS_FIELD_PREFIX))
        egressBridgedName = fName;
    else
        egressBridgedName = getOppositeGressFieldName(fName);

    if (reverseEgressBridgedMap.count(egressBridgedName))
        return reverseEgressBridgedMap.at(egressBridgedName);
    LOG3("unable to find field in egressBridgedMap " << egressBridgedName);
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

/// @param alignmentConstraints if provided, will be populated with the alignment of must-pack
/// fields.
SymBitMatrix RepackFlexHeaders::mustPack(
        const ordered_set<const PHV::Field*>& fields,
        ordered_map<const PHV::Field*, le_bitrange>& alignmentConstraints) const {
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
    for (const auto* f : fields) {
        reads[f] = actionConstraints.actions_reading_fields(f);
        LOG3("fields " << f);
    }
    for (const auto* f : egressFields) {
        reads[f] = actionConstraints.actions_reading_fields(f);
        LOG3("egress fields " << f);
    }

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

    for (auto& kv : alignment) {
        auto& field = kv.first;
        alignmentConstraints.emplace(field, StartLen(kv.second, field->size));
    }

    return mustPackMatrix;
}

void RepackFlexHeaders::updateNoPackForDigestFields(
        const std::vector<const PHV::Field*>& nonByteAlignedFields,
        const SymBitMatrix& mustPackMatrix) {
    for (const auto* field1 : nonByteAlignedFields) {
        if (!digestFlexFields.count(field1)) continue;
        for (const auto* field2 : nonByteAlignedFields) {
            if (field1 == field2) continue;
            if (mustPackMatrix(field1->id, field2->id)) {
                LOG4("\t\tEncountered must pack for " << field1->name << " and " << field2->name <<
                     " when the former is a digest field");
                continue;
            }
            doNotPack(field1->id, field2->id) = true;
            printNoPackConstraint("Use in digest", field1, field2);
        }
    }
}

/// @param alignmentConstraints will be populated with the alignment of must-pack
/// fields.
SymBitMatrix
RepackFlexHeaders::bridgedActionAnalysis(
        std::vector<const PHV::Field*>& nonByteAlignedFields,
        ordered_map<const PHV::Field*, le_bitrange>& alignmentConstraints) {
    ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Action*>> fieldToActionWrites;
    ordered_set<const PHV::Field*> fieldsToBePacked;
    for (auto f : nonByteAlignedFields) {
        fieldsToBePacked.insert(f);
        fieldToActionWrites[f] = actionConstraints.actions_writing_fields(f); }

    SymBitMatrix mustPackMatrix = mustPack(fieldsToBePacked, alignmentConstraints);

    // Conservatively, mark fields that are written in the same action as do not pack. Also,
    for (const auto* field1 : nonByteAlignedFields) {
        bool isSpecialityDest1 = actionConstraints.hasSpecialityReads(field1);
        bool isMoveOnlyDest1 = actionConstraints.move_only_operations(field1);
        BUG_CHECK(fieldToActionWrites.count(field1), "Did not find actions writing to field %1%",
                  field1->name);
        for (const auto* field2 : nonByteAlignedFields) {
            BUG_CHECK(fieldToActionWrites.count(field2), "Did not find actions writing to field "
                                                         "%1%", field2->name);
            bool isSpecialityDest2 = actionConstraints.hasSpecialityReads(field2);
            bool isMoveOnlyDest2 = actionConstraints.move_only_operations(field2);
            if (field1 == field2) {
                continue;
            } else if (mustPackMatrix(field1->id, field2->id)) {
                doNotPack(field1->id, field2->id) = true;
                printNoPackConstraint("MUST PACK", field1, field2);
            } else if (field1->is_digest() || field2->is_marshaled()) {
                // Do not pack fields together if one or both of them is used in a digest.
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
        const SymBitMatrix& mustPackMatrix) const {
    static ordered_map<const PHV::Field*, int> emptyMap;
    ordered_map<const PHV::Field*, int> rv;
    ordered_set<const PHV::Field*> potentiallyPackableFields;
    potentiallyPackableFields.insert(field1);
    LOG4("\tPack with field: " << field1->name << " alignment: " << alignment);

    ordered_set<const PHV::Field*> mustPackFields;
    for (auto field2 : candidates) {
        if (field1 == field2) continue;
        if (mustPackMatrix(field1->id, field2->id)) {
            LOG4("\t\tDetected must pack field " << field2->name);
            mustPackFields.insert(field2);
        }
    }

    int totalMustPackSize = field1->size;
    for (auto f : mustPackFields)
        totalMustPackSize += f->size;
    if (alignment == 0 && totalMustPackSize == field1->size) {
        rv[field1] = 0;
        return rv;
    }
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

            BUG_CHECK(alignmentConstraints.count(f),
                      "Field %1% unexpectedly has no alignment constraint during flexible packing",
                      f->name);

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
        ordered_map<const PHV::Field*, le_bitrange>& nonNegotiableAlignments,
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
            nonNegotiableAlignments[field] = alignmentConstraints[field];
            LOG4("\t\tDetected non-negotiable bit in byte alignment " << alignmentConstraints[field]
                 << " for field " << field->name << " due to parser initialization"); }

        // DeparserParams must be in the bottom bits.
        if (deparserParams.count(field)) {
            if (alignmentConstraints.count(field)) {
                le_bitrange align = le_bitrange(StartLen(0, field->size));
                if (alignmentConstraints[field] != align) {
                    LOG3("Alignment constraint " << align.lo << " already present for field " <<
                         field->name << " : " << alignmentConstraints.at(field).lo);
                    conflictingAlignmentConstraints[field].insert(
                            alignmentConstraints.at(field).lo);
                }
            } else {
                le_bitrange align = le_bitrange(StartLen(0, field->size));
                alignmentConstraints[field] = align;
                LOG4("\t\tDetected non-negotiable deparser parameter alignment: "  <<
                    alignmentConstraints[field] << " for field " << field->name);
                nonNegotiableAlignments[field] = align;
            }
        }

        if (fields.bridged_to_orig.count(field->name)) {
            const auto* origField = phv.field(fields.bridged_to_orig.at(field->name));
            if (origField) {
                fieldsNotVisited.push(origField);
                LOG5("\t\t\tDetected original bridged field: " << origField);
            }
        }
        // Also summarize the egress version of this field, as alignment
        // constraints may be induced by uses of the egress version of the
        // bridged field.
        cstring egressFieldName = getNonBridgedEgressFieldName(field->name);
        // FIXME
        cstring bridgedFieldName = (field->gress == INGRESS) ?
             getOppositeGressFieldName(field->name) : field->name;
        BUG_CHECK(egressFieldName, "No egress version of the field %1%", field->name);
        const auto* egressField = phv.field(egressFieldName);
        // Add the ingress field and its egress version to visit.
        fieldsNotVisited.push(field);
        if (egressField) {
            fieldsNotVisited.push(egressField);
            LOG5("\t\t\tDetected egress field: " << egressField);
        } else {
            LOG5("\t\t\tDid not detect egress field: " << egressFieldName);
        }

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
            if (parserAlignedFields.revCount(currentField))
                for (const auto* f : parserAlignedFields.revAt(currentField))
                    if (!relatedFields.count(f))
                        fieldsNotVisited.push(f);
            LOG6("\t\t  Now, we have " << fieldsNotVisited.size() << " fields unvisited"); }

        if (LOGGING(4) && relatedFields.count(field) == 0) {
            LOG4("\t  No related fields");
            continue; }

        for (const PHV::Field* f : relatedFields) {
            // FIXME
            if (field->gress == INGRESS && f->name == bridgedFieldName) continue;
            // ignore the alignment on the current field
            if (f->name == field->name) continue;
            LOG5("\t  Related field: " << f);
            if (f->is_digest()) {
                digestFlexFields.insert(field);
                LOG5("\t\tAdding field " << field->name << " as digest use");
            }
            if (f->alignment) {
                LOG5("\t\t  New candidate alignment: " << *(f->alignment));
                // If the field must be aligned at this bit position (instead of not being aligned
                // and instead satisfying constraints because of deposit-field operations),
                if (mustAlign(f)) {
                    LOG5("\t\t  Field " << field->name << " must be placed at the given "
                                                                "alignment " << *(f->alignment));
                    mustAlignFields.insert(field); }

                bool this_non_negotiable_alignment =
                    parserAlignedFields.count(f) || parserAlignedFields.revCount(f) ||
                    uses.is_extracted(f, f->gress) ||
                    (f->isPacketField() && !f->is_flexible() && !f->bridged);
                if (fieldAlignmentMap.count(field)) {
                    // alignSource is where the alignment constraint originates from.
                    const PHV::Field* alignSource = fieldAlignmentMap[field];
                    BUG_CHECK(alignSource->alignment, "No alignment for field %1%",
                              alignSource->name);
                    LOG5("\t\t  Old alignment: " << *(alignSource->alignment));
                    if (*(f->alignment) == *(alignSource->alignment)) continue;
                    // Only compare the little endian alignments because the network endian
                    // alignments differ for some fields of different sizes.
                    // Choose the alignment that emanates from a non-negotiable alignment
                    // constraint (parser initialized field/deparser parameter/header field)
                    LOG5("\t\t  Does this field enforce non-negotiable alignment? " <<
                            (this_non_negotiable_alignment ? "YES" : "NO"));
                    if (this_non_negotiable_alignment && nonNegotiableAlignments.count(field)) {
                        LOG3("Multiple fields enforcing non-negotiable alignment for flexible "
                             "field " << field->name << " : " << f->alignment->align << ", " <<
                             alignSource->alignment->align);
                        conflictingAlignmentConstraints[field].insert(f->alignment->align);
                        conflictingAlignmentConstraints[field].insert(
                               alignSource->alignment->align);
                        continue;
                    }
                }
                if (this_non_negotiable_alignment) {
                    nonNegotiableAlignments[field] = StartLen(f->alignment->align, f->size);
                    LOG3("\t\t Detected non-negotiable alignment constraint " << field
                            << " " << nonNegotiableAlignments[field]);
                }

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
        if (nonNegotiableAlignments.size() > 0) {
            LOG4("\tPrinting bridged fields with conflicting constraints:");
            for (auto kv : nonNegotiableAlignments) {
                std::stringstream ss;
                ss << "\t " << kv.first->name << " : ";
                ss << kv.second << " ";
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

const IR::StructField* RepackFlexHeaders::getPaddingField(int size, int id, bool overlay) const {
    cstring padFieldName = "__pad_" + cstring::to_cstring(id);
    if (overlay) {
        auto* fieldAnnotations = new IR::Annotations(
                { new IR::Annotation(IR::ID("padding"), { }),
                  new IR::Annotation(IR::ID("overlayable"), { }) });
        const IR::StructField* padField = new IR::StructField(padFieldName, fieldAnnotations,
                IR::Type::Bits::get(size));
        return padField;
    } else {
        auto* fieldAnnotations = new IR::Annotations({ new IR::Annotation(IR::ID("padding"), { })
                });
        const IR::StructField* padField = new IR::StructField(padFieldName, fieldAnnotations,
                IR::Type::Bits::get(size));
        return padField;
    }
}

// FIXME
cstring RepackFlexHeaders::getOppositeGressFieldName(cstring name) {
    if (name.startsWith(INGRESS_FIELD_PREFIX)) {
        return (EGRESS_FIELD_PREFIX + name.substr(9));
    } else if (name.startsWith(EGRESS_FIELD_PREFIX)) {
        return (INGRESS_FIELD_PREFIX + name.substr(8));
    } else {
        BUG("Called getOppositeGressFieldName on unknown gress fieldname %1%", name);
        return cstring();
    }
}

cstring RepackFlexHeaders::getFieldName(cstring hdr, const IR::StructField* field) const {
    auto name = hdr + "." + field->name;
    if (auto* fieldInfo = phv.field(name))
        return fieldInfo->name;
    return name;
}

int RepackFlexHeaders::getPackSize(const PHV::Field* f) const {
    bool no_split_found = false;
    int max_split_size = -1;
    if (!clusterFields.count(f)) return max_split_size;
    for (const auto* clusterField : clusterFields.at(f)) {
        LOG5("\t\t\t\tRelated field: " << clusterField);
        if (clusterField->no_split()) {
            no_split_found = true;
            if (max_split_size < clusterField->size)
                max_split_size = clusterField->size;
        }
    }
    if (no_split_found) {
        LOG4("\t\t  Found no-split cluster fields of maximum size " << max_split_size
                << " for field " << f->name);
        if (max_split_size <= 8)
            return 8;
        else if (max_split_size <= 16)
            return 16;
        else if (max_split_size <= 32)
            return 32;
        else
            LOG4("\t\tHow can no split be greater than maximum container size?");
    }
    return -1;
}

/**
 * packPhvFieldSet : take a set of PHV::Field, pack the set and return the packing.
 */
const std::vector<const PHV::Field*>
RepackFlexHeaders::packPhvFieldSet(const ordered_set<const PHV::Field*>& fieldsToBePacked) {
    std::vector<const PHV::Field*> packedFields;
    std::vector<const PHV::Field*> nonByteAlignedFields;
    for (auto f : fieldsToBePacked) {
        determineClusterFields(f);
        int packSize = getPackSize(f);
        if (f->size % 8 == 0 && (packSize == -1 || packSize == f->size)) {
            LOG5("\t\t  Packed field: " << f);
            packedFields.push_back(f);
            continue; }
        LOG5("\t\t  Non byte aligned field: " << f);
        if (f->size % 8 == 0)
            LOG5("\t\t\tpack size: " << packSize << ", field size: " << f->size);
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

    // Determine nonbyte-aligned bridged fields with alignment constraints.
    ordered_map<const PHV::Field*, le_bitrange> alignmentConstraints;
    auto sliceListAlignment = bridgedActionAnalysis(nonByteAlignedFields, alignmentConstraints);
    ordered_map<const PHV::Field*, std::set<int>> conflictingAlignmentConstraints;
    ordered_map<const PHV::Field*, le_bitrange> nonNegotiableAlignments;
    ordered_set<const PHV::Field*> mustAlignFields;
    determineAlignmentConstraints(nonByteAlignedFields, alignmentConstraints,
                                  conflictingAlignmentConstraints,
                                  nonNegotiableAlignments,
                                  mustAlignFields);
    updateNoPackForDigestFields(nonByteAlignedFields, sliceListAlignment);

    ordered_set<const PHV::Field*> alreadyPackedFields;
    for (auto field : nonByteAlignedFields) {
        if (alreadyPackedFields.count(field)) {
            LOG4("\t  A. Already packed " << field->name);
            continue; }
        std::vector<const PHV::Field*> fieldsPackedTogether;
        LOG3("\tTrying to pack fields with " << field->name);
        bool digestField = digestFlexFields.count(field);
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
            // them to the non-negotiable alignment, if none exists, to 0.
            if (packingWithPositions.size() == 1) {
                for (auto kv : packingWithPositions) {
                    if (conflictingAlignmentConstraints.count(kv.first)) {
                        if (nonNegotiableAlignments.count(kv.first)) {
                            packingWithPositions[kv.first] =
                                nonNegotiableAlignments.at(kv.first).lo;
                            LOG4("\t\t  Non-negotiable alignment, pack " << kv.first <<
                                    " at " << nonNegotiableAlignments.at(kv.first));
                        } else {
                            packingWithPositions[kv.first] = 0;
                            LOG4("\t\t  Conflicting alignment, pack " << kv.first <<
                                    " in bottom bits");
                        }
                    }
                }
            }
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

        // If there are no-split fields that will need to go into the same supercluster, we may need
        // to add more padding to this field.
        for (auto kv : packingWithPositions) {
            int max_split_size = getPackSize(kv.first);
            if (max_split_size != -1 && max_split_size > totalPackSize)
                totalPackSize = max_split_size;
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
                auto* padField = phv.create_dummy_padding(padSize, INGRESS, !digestField);
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

        for (auto it = fieldsPackedTogether.begin(); it != fieldsPackedTogether.end(); ++it) {
            LOG4("\t\tA. Pushing field " << (*it)->name << " of type " << (*it)->size <<
                                         "b.");
            if (padFields.count(*it)) paddingFieldNames.insert((*it)->name);
            packedFields.push_back(*it);
        }
    }
    return packedFields;
}

void RepackFlexHeaders::determineClusterFields(const PHV::Field* f) {
    LOG5("\tDetermining cluster fields for " << f->name);
    if (clusterFields.count(f)) return;
    LOG5("\t  New record found");
    std::queue<const PHV::Field*> toProcessFields;
    toProcessFields.push(f);
    // At this point, the original field and the bridged version are separate. So, we need to
    // combine the constraints across both of them.
    if (fields.bridged_to_orig.count(f->name)) {
        const auto* orig = phv.field(fields.bridged_to_orig.at(f->name));
        if (orig) {
            toProcessFields.push(orig);
            LOG5("\t\t  Seeing original field: " << orig->name);
        }
    }
    while (!toProcessFields.empty()) {
        const auto* field = toProcessFields.front();
        toProcessFields.pop();
        LOG5("\t\tProcessing " << field->name);
        for (const auto* source : actionConstraints.field_sources(field)) {
            LOG5("\t\t  Seeing source: " << source->name);
            if (source != f && (!clusterFields.count(f) ||
                        (clusterFields.count(f) && !clusterFields[f].count(source)))) {
                toProcessFields.push(source);
                clusterFields[f].insert(source);
                if (!fields.bridged_to_orig.count(source->name)) continue;
                const auto* orig = phv.field(fields.bridged_to_orig.at(source->name));
                if (!orig) continue;
                if (!clusterFields[f].count(orig)) {
                    toProcessFields.push(orig);
                    clusterFields[f].insert(orig);
                }
            }
        }
        for (const auto* dest : actionConstraints.field_destinations(field)) {
            LOG5("\t\t  Seeing destination: " << dest->name);
            if (dest != f && (!clusterFields.count(f) ||
                        (clusterFields.count(f) && !clusterFields[f].count(dest)))) {
                toProcessFields.push(dest);
                clusterFields[f].insert(dest);
                if (!fields.bridged_to_orig.count(dest->name)) continue;
                const auto* orig = phv.field(fields.bridged_to_orig.at(dest->name));
                if (!orig) continue;
                if (!clusterFields[f].count(orig)) {
                    toProcessFields.push(orig);
                    clusterFields[f].insert(orig);
                }
            }
        }
    }
    if (clusterFields.count(f)) {
        LOG5("\t  Bridged field: " << f->name);
        for (const auto* related : clusterFields.at(f))
            LOG5("\t\t" << related->name);
    }
}

const std::vector<const PHV::Field*>
RepackFlexHeaders::verifyPackingAcrossBytes(const std::vector<const PHV::Field*>& fields) const {
    std::vector<const PHV::Field*> rv;
    for (const auto* f : fields)
        rv.push_back(f);

    // Map of byte number in the header to the set of fields in that byte.
    ordered_map<int, std::vector<const PHV::Field*>> bytesToFields;
    // Map of field to its min and max byte offset within the flexible header.
    ordered_map<const PHV::Field*, std::pair<int, int>> fieldOffsets;
    // SymBitMatrix of bytes that have no pack conflicts between them.
    SymBitMatrix noPack;

    int headerSize = 0;
    for (const auto* f : fields) {
        int lower = headerSize / 8;
        headerSize += f->size;
        int upper = (headerSize % 8 == 0) ? (headerSize / 8 - 1) : (headerSize / 8);
        fieldOffsets[f] = std::make_pair(lower, upper);
        for (int i = lower; i <= upper; ++i)
            bytesToFields[i].push_back(f);
    }
    headerSize /= 8;
    LOG5("\tHeader size: " << headerSize << "B.");
    for (const auto& kv : fieldOffsets)
        LOG5("\t  " << kv.second.first << "\t" << kv.second.second << "\t" << kv.first->name <<
             " <" << kv.first->size << ">");
    for (const auto& kv : bytesToFields) {
        LOG5("\tByte " << kv.first);
        for (const auto* f : kv.second)
            LOG5("\t  " << f->name);
    }
    for (int byte = 3; byte < headerSize; byte++) {
        ordered_set<const PHV::Field*> fieldsIn32b;
        LOG5("\t\t[" << byte - 3 << ", " <<  byte << "]");
        for (int b1 = byte - 3; b1 <= byte; b1++)
            for (const auto* f : bytesToFields.at(b1))
                fieldsIn32b.insert(f);
        bool foundConflict = false;
        for (const auto* f1 : fieldsIn32b) {
            for (const auto* f2 : fieldsIn32b) {
                if (f1 == f2) continue;
                if (actionConstraints.hasPackConflict(f1, f2)) {
                    LOG5("\t\t  " << f1->name << " and " << f2->name << " have pack conflicts");
                    foundConflict = true;
                }
            }
        }
        if (foundConflict) {
            for (const auto* f : fieldsIn32b) {
                if (!clusterFields.count(f)) continue;
                ordered_set<const PHV::Field*> noPackFields;
                ordered_set<const PHV::Field*> noSplitFields;
                for (const auto* related : clusterFields.at(f)) {
                    if (related->is_solitary()) {
                        noPackFields.insert(related);
                        LOG5("\t\t\t" << related->name << " is no-pack.");
                    }
                    if (related->no_split()) {
                        noSplitFields.insert(related);
                        LOG5("\t\t\t" << related->name << " is no-split.");
                    }
                }
            }
        }
    }

    return rv;
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
    if (repackedTypes.count(h->type->name)) {
        auto* repackedHeaderType = new IR::Type_Header(h->type->name, h->type->annotations,
                repackedTypes.at(h->type->name)->fields);
        auto* repackedHeader = new IR::Header(h->name, repackedHeaderType);
        repackedHeaders[h->name] = repackedHeader;
        originalHeaders[h->name] = h;
        LOG3("Repacked egress header: " << repackedHeader);
        LOG3("Repacked egress header type: " << repackedHeaderType);
        LOG3("Repacked egress header size: " << getHeaderBytes(repackedHeader) << "B");
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
    if (h->type->is<IR::BFN::Type_FixedSizeHeader>()) {
        headerToFlexibleStructsMap.emplace(h);
        for (auto f : h->type->fields)
            if (f->getAnnotation("flexible"))
                headerToFlexibleStructsMap[h].insert(f);
        return true;
    }
    for (auto f : h->type->fields)
        if (f->getAnnotation("flexible"))
            headerToFlexibleStructsMap[h].insert(f);
    return headerToFlexibleStructsMap.count(h);
}

bool RepackFlexHeaders::isFlexibleHeader(const IR::BFN::DigestFieldList* d) {
    /// Type_FixedSizeHeader is resubmit or phase0 header.
    if (d->type->is<IR::BFN::Type_FixedSizeHeader>()) {
        digestToFlexibleStructsMap.emplace(d);
        for (auto f : d->type->fields)
            if (f->getAnnotation("flexible"))
                digestToFlexibleStructsMap[d].insert(f);
        return true;
    }
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

    if (auto rv = checkIfAlreadyPacked(h)) {
        return *rv;
    }

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

    packedFields = verifyPackingAcrossBytes(packedFields);

    IR::IndexedVector<IR::StructField> fields;
    // Add the non flexible fields from the header.
    for (auto f : h->type->fields) {
        if (!f->getAnnotation("flexible") && !f->getAnnotation("padding")) {
            fields.push_back(f);
            LOG2("Pushing original field " << f);
            continue;
        }
    }
    // Add the repacked flexible fields.
    unsigned padFieldId = 0;
    for (auto f : packedFields) {
        if (phvFieldToStructField.count(f)) {
            auto field = phvFieldToStructField.at(f);
            fields.push_back(field);
            LOG2("Pushing field " << field);
        } else {
            auto padding = getPaddingField(f->size, padFieldId++, f->overlayable);
            fields.push_back(padding);
            LOG2("Pushing field " << padding << ", overlayable: " << f->overlayable);
        }
    }

    if (auto fh = h->type->to<IR::BFN::Type_FixedSizeHeader>()) {
        size_t bits = static_cast<size_t>(getHeaderBits(h));
        ERROR_CHECK(bits <= Device::pardeSpec().bitResubmitSize(),
                "%1% digest limited to %2% bits", h->type->name,
                Device::pardeSpec().bitResubmitSize());
        auto pad_size = fh->fixed_size - bits;
        if (pad_size != 0) {
            auto padding = getPaddingField(pad_size, padFieldId++);
            fields.push_back(padding);
            LOG2("Pushing field " << padding);
        }
    }

    auto* repackedHeaderType = new IR::Type_Header(h->type->name, h->type->annotations, fields);
    auto* repackedHeader = new IR::Header(h->name, repackedHeaderType);
    repackedHeaders[headerName] = repackedHeader;
    repackedTypes[h->type->name] = repackedHeaderType;
    originalHeaders[headerName] = h;
    ingressFlexibleTypes[h] = repackedHeader;
    LOG3("Repacked header: " << repackedHeader->name);
    LOG3("Repacked header type: " << repackedHeader->type);
    LOG3("Repacked header size: " << getHeaderBits(repackedHeader) << "b");

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
    LOG3("Candidate digest field list found: idx " << d->idx);
    LOG3("Candidate digest type: " << d->type);
    LOG3("Candidate digest size: " << getHeaderBits(d) << "b");
    if (!isFlexibleHeader(d)) return d;
    LOG3("Found header to be repacked");

    BUG_CHECK(digestToFlexibleStructsMap.count(d),
              "The compiler has detected a header %1% with flexible structs, but "
              "cannot find the associated flexible structs to repack.",
              d->type);
    auto& flexFields = digestToFlexibleStructsMap.at(d);
    LOG3("\t" << flexFields.size() << " flexible fields in header " << d->type->name);
    if (LOGGING(3))
        for (auto* f : flexFields)
            LOG3("\tFlexible field type: " << f->name << "\n\t  " << f->type);

    auto phvFieldToStructField = getPhvFieldToStructFieldMap(d);

    auto& fieldsToBePacked = mkPhvFieldSet(d);

    auto packedFields = packPhvFieldSet(fieldsToBePacked);

    IR::IndexedVector<IR::StructField> fields;
    // Add the non flexible fields from the header.
    for (auto f : d->type->fields) {
        if (!f->getAnnotation("flexible") && !f->getAnnotation("padding")) {
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
            auto padding = getPaddingField(f->size, padFieldId++, f->overlayable);
            fields.push_back(padding);
            LOG3("\tPushing padding field " << padding);
        }
    }

    if (auto fh = d->type->to<IR::BFN::Type_FixedSizeHeader>()) {
        size_t bits = static_cast<size_t>(getHeaderBits(d));
        ERROR_CHECK(bits <= Device::pardeSpec().bitResubmitSize(),
                "%1% digest limited to %2% bits", d->type->name,
                Device::pardeSpec().bitResubmitSize());
        auto pad_size = fh->fixed_size - bits;
        if (pad_size != 0) {
            auto padding = getPaddingField(pad_size, padFieldId++);
            fields.push_back(padding);
            LOG2("Pushing field " << padding);
        }
    }

    auto annotations = new IR::Annotations(d->type->annotations->annotations);
    annotations->addAnnotationIfNew("flexible", {});

    auto* repackedHeaderType = new IR::Type_Header(d->type->name, annotations, fields);
    repackedTypes[d->type->name] = repackedHeaderType;

    std::map<cstring, int> original_field_indices;
    int index = 0;
    for (auto f : d->type->fields) {
        original_field_indices.emplace(f->name, index++);
    }

    std::vector<FieldListEntry> repacked_field_indices;
    for (auto f : repackedHeaderType->fields) {
        if (f->getAnnotation("padding")) {
            repacked_field_indices.push_back(std::make_pair(-1, f->type));
            continue; }
        repacked_field_indices.push_back(
                std::make_pair(original_field_indices.at(f->name), f->type));
        LOG2("\tRepacked field " << f->name); }

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

std::string LogRepackedHeaders::strip_prefix(cstring str, std::string pre) {
    std::string s = str + "";
    // Find the first occurence of the prefix
    size_t first = s.find(pre, 0);

    // If it's not at 0, then we haven't found a prefix
    if (first != 0)
        return s;

    // Otherwise, we have a match and can trim it
    return s.substr(pre.length(), std::string::npos);
}

// Collect repacked headers
bool LogRepackedHeaders::preorder(const IR::HeaderOrMetadata* h) {
    // Check if we have visited this header's ingress/egress version before
    cstring hname = h->name;
    std::string h_in = strip_prefix(hname, "ingress::");
    std::string h_out = strip_prefix(hname, "egress::");
    if (hdrs.find(h_in) != hdrs.end() || hdrs.find(h_out) != hdrs.end())
        return false;
    // Otherwise, add the shorter one (the one with the prefix stripped) to our set
    std::string h_strip;
    if (h_in.length() > h_out.length())
        h_strip = h_out;
    else
        h_strip = h_in;
    hdrs.emplace(h_strip);

    // Check if this header may have been repacked by looking for flexible fields
    bool isRepacked = false;
    for (auto f : *h->type->fields.getEnumerator()) {
        if (f->getAnnotation("flexible")) {
            isRepacked = true;
            break;
        }
    }

    // Add it to our vector if it is repacked
    if (isRepacked) {
        std::pair<const IR::HeaderOrMetadata*, std::string> pr(h, h_strip);
        repacked.push_back(pr);
    }

    // Prune this branch because headers won't have headers as children
    return false;
}

// Pretty print all of the headers
void LogRepackedHeaders::end_apply() {
    // Check if we should be logging anything
    if (LOGGING(1))
        // Iterate through the headers and print all of their fields
        for (auto h : repacked)
            LOG1(pretty_print(h.first, h.second));
}

// TODO: Currently outputting backend name for each field. Should be changed to user facing name.
std::string LogRepackedHeaders::getFieldName(std::string hdr, const IR::StructField* f) const {
    auto nm = hdr + "." + f->name;
    auto* fi = phv.field(nm);
    auto name = fi ? fi->name : nm;
    std::string s = name + "";
    return s;
}

std::string LogRepackedHeaders::pretty_print(const IR::HeaderOrMetadata* h, std::string hdr) {
    // Number of bytes we have used
    unsigned byte_ctr = 0;
    // Number of bits in the current byte we have used
    unsigned bits_ctr = 0;

    std::stringstream out;
    out << "Repacked header " << hdr << ":" << std::endl;

    // Create our table printer
    TablePrinter* tp = new TablePrinter(out, {"Byte #", "Bits", "Field name"},
                                       TablePrinter::Align::CENTER);
    tp->addSep();

    // Run through the fields. We divide each field into 3 sections: (1) the portion that goes into
    // the current byte; (2) the portion that goes into byte(s) in the middle; and (3) the portion
    // that goes into the last byte. As we process each field, we may want to change how previous
    // portions were allocated. For example, if we realize (2) will be a range and (1) was a full
    // byte, then (1) should get merged into (2). Thus, we will capture the printing (to
    // TablePrinter) of each portion as a copy-capture lambda. This allows us to do "lazy
    // evaluation" and effectively modify what is printed after in earlier portions.
    for (auto f : h->type->fields) {
        // PORTION(1): This section will always exist, but it may end up getting included into
        // portion 2
        std::function<void(void)> write_beg = [=]() { return; };
        // PORTION(2): This section may be a range (of full bytes), a single full byte or be empty.
        std::function<void(void)> write_mid = [=]() { return; };
        // PORTION(3): This section is necessary when the field doesn't end up completely filling
        // the last byte of the mid.
        std::function<void(void)> write_end = [=]() { return; };

        // Get the field name. If it's a pad, change to *PAD*
        std::string name = getFieldName(hdr, f);
        if (name.find("__pad_", 0) != std::string::npos)
            name = "*PAD*";

        // Need to calculate how many bytes and what bits this field takes up
        unsigned width = f->type->width_bits();
        // Remaining bits in the current byte
        unsigned rem_bits = 8 - bits_ctr;
        // True if this field overflows the current byte
        bool ofByte = width > rem_bits;

        // PORTION (1): First, we add to the current byte.
        // Last bit is the next open bit
        unsigned last_bit = ofByte ? 8 : bits_ctr + width;
        // If this first byte is full, we'll need to print a separator.
        bool first_full = last_bit == 8;
        // If this byte is completely occupied by this field, it may need to be a range
        bool first_occu = first_full && bits_ctr == 0;
        write_beg = [=]() {
                        tp->addRow({std::to_string(byte_ctr),
                                   "[" + std::to_string(bits_ctr) + " : "
                                   + std::to_string(last_bit - 1) + "]",
                                   name});
                        if (first_full) tp->addSep();
                    };

        // Update bits/byte counter and width after finishing 1st byte
        bits_ctr = last_bit % 8;
        byte_ctr = first_full ? byte_ctr + 1 : byte_ctr;
        width = width - rem_bits;

        // PORTION (2)/(3): Only need to handle this portion if we did overflow
        if (ofByte) {
            // See what byte/bit we'll fill up to. The last bit is the next open bit
            unsigned end_byte = byte_ctr + width/8;
            last_bit = width % 8;

            // PORTION(2): Now, we want to handle any bytes that are completely filled by this
            // field. We want to put multiple bytes that are occupied by the same field into a range
            // instead of explicitly printing out each one
            if (end_byte - byte_ctr >= 1) {
                // If we're in this conditional, we know that we have at least 1 full byte, but
                // that's not enough to print a range, so:
                if (end_byte - byte_ctr >= 2 || first_occu) {
                    // Now, we have at least 2 bytes that are full, so we can print a range.
                    unsigned beg_byte = byte_ctr;
                    // If the first was completely occupied by this field, include it in the range
                    // and don't do anything in write_beg
                    if (first_occu) {
                        beg_byte--;
                        write_beg = [=]() { return; };
                    }
                    // Add the range row
                    write_mid = [=]() {
                                    tp->addRow({std::to_string(beg_byte) + " -- "
                                               + std::to_string(end_byte-1),
                                               "[" + std::to_string(0) + " : "
                                               + std::to_string(7) + "]",
                                               name});
                                    tp->addSep();
                                    return;
                                };
                } else {
                    // Here we know our mid portion is going to be just the single full byte we have
                    write_mid = [=]() {
                                    tp->addRow({std::to_string(byte_ctr),
                                               "[" + std::to_string(0) + " : "
                                               + std::to_string(7) + "]",
                                               name});
                                    tp->addSep();
                                    return;
                                };
                }
            }

            // PORTION(3): We now need to handle the partial byte that might be leftover
            if (last_bit != 0) {
                write_end = [=]() {
                                tp->addRow({std::to_string(end_byte),
                                           "[" + std::to_string(0) + " : "
                                           + std::to_string((last_bit-1)) + "]",
                                           name});
                                return;
                            };
            }

            // Now, we update our counters
            byte_ctr = end_byte;
            bits_ctr = last_bit;
        }
        // Finally, write everything to the table printer
        write_beg();
        write_mid();
        write_end();
    }

    // Print the table to the stream out and return it
    tp->print();
    out << std::endl;
    return out.str();
}

FlexiblePacking::FlexiblePacking(
        PhvInfo& p,
        const PhvUse& u,
        DependencyGraph& dg,
        CollectBridgedFields& b) :
          bridgedFields(b),
          aliasInEgress(p),
          table_alloc(p.field_mutex()),
          packConflicts(p, dg, tMutex, table_alloc, aMutex),
          actionConstraints(p, u, packConflicts, tableActionsMap, dg),
          parserAlignedFields(p),
          packDigestFieldLists(p, u, b, aliasInEgress, actionConstraints, doNotPack,
            noPackFields, deparserParams, parserAlignedFields, repackedTypes),
          packHeaders(p, u, b, aliasInEgress, actionConstraints, doNotPack,
            noPackFields, deparserParams, parserAlignedFields, repackedTypes) {
              addPasses({
                      &bridgedFields,
                      &aliasInEgress,
                      new FindDependencyGraph(p, dg),
                      new PHV_Field_Operations(p),
                      new PragmaContainerSize(p),
                      new PragmaAtomic(p),
                      new PragmaSolitary(p),
                      &tMutex,
                      &aMutex,
                      &packConflicts,
                      &tableActionsMap,
                      &actionConstraints,
                      new GatherDeparserParameters(p, deparserParams),
                      new GatherPhase0Fields(p, noPackFields),
                      &parserAlignedFields,
                      &packDigestFieldLists,
                      &packHeaders,
              });
}

// Return a Json representation of flexible headers to be saved in .bfa/context.json
std::string LogRepackedHeaders::asm_output() const {
    if (repacked.empty())
        return std::string("");

    std::ostringstream out;
    bool first_header = true;
    out << "flexible_headers: [\n";  // list of headers
    for (auto h : repacked) {
        if (!first_header) {
            out << ",\n";
        } else {
            out << "\n"; first_header = false;
        }

        out << "  { name: \"" << h.second << "\",\n"
            << "    fields: [\n";  // list of fields

        bool first_field = true;
        for (auto f : h.first->type->fields) {
            auto name = f->name.name;   // getFieldName(h.second, f);
            // for now all the fields are full fields not slices
            unsigned width = f->type->width_bits();
            unsigned start_bit = 0;  // so all fields start at 0.

            if (!first_field) {
                out << ",\n";
            } else {
                out << "\n"; first_field = false;
            }

            out << "      { name: \"" << name << "\", slice: { "
                << "start_bit: " << start_bit << ", bit_width: " << width
                // << ", slice_name:" << "the name of the slice"
                << " } }";
        }
        out << "    ]\n";    // list of fields
        out << "  }";     // header
    }
    out << "]\n";  // list of headers
    return out.str();
}

PackFlexibleHeaders::PackFlexibleHeaders(const BFN_Options& options) :
    phv(mutually_exclusive_field_ids),
    uses(phv),
    defuse(phv),
    bridged_fields(phv) {
    flexiblePacking = new FlexiblePacking(phv, uses, deps, bridged_fields);
    flexiblePacking->addDebugHook(options.getDebugHook(), true);
    addPasses({
        new CreateThreadLocalInstances,
        new CheckForUnimplementedFeatures(),
        new RemoveEmptyControls,
        new MultipleApply,
        new AddSelectorSalu,
        new FixupStatefulAlu,
        new CollectHeaderStackInfo,  // Needed by CollectPhvInfo.
        new CollectPhvInfo(phv),
        &defuse,
        Device::currentDevice() == Device::JBAY ? new AddJBayMetadataPOV(phv) : nullptr,
        Device::currentDevice() == Device::TOFINO ?
            new ResetInvalidatedChecksumHeaders(phv) : nullptr,
        new CollectPhvInfo(phv),
        &defuse,
        new CollectHeaderStackInfo,  // Needs to be rerun after CreateThreadLocalInstances, but
                                     // cannot be run after InstructionSelection.
        new RemovePushInitialization,
        new StackPushShims,
        new CollectPhvInfo(phv),    // Needs to be rerun after CreateThreadLocalInstances.
        new HeaderPushPop,
        new InstructionSelection(options, phv),
        new FindDependencyGraph(phv, deps, "program_graph", "After Instruction Selection"),
        new CollectPhvInfo(phv),
        new Alias(phv),
        new CollectPhvInfo(phv),
        // Repacking of flexible headers (including bridged metadata) in the backend.
        // Needs to be run after InstructionSelection but before deadcode elimination.
        flexiblePacking,
    });
}


