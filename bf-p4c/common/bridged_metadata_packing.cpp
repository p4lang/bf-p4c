#include "bf-p4c/common/bridged_metadata_packing.h"
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

cstring PackBridgedMetadata::getEgressFieldName(cstring ingressName) {
    if (!ingressName.startsWith(INGRESS_FIELD_PREFIX)) {
        BUG("Called getEgressFieldName on ingress fieldname %1%", ingressName);
        return cstring(); }
    // ingress::foo.bar -> egress::foo.bar
    return (EGRESS_FIELD_PREFIX + ingressName.substr(9));
}

cstring PackBridgedMetadata::getFieldName(const IR::Header* hdr, const IR::StructField* field) {
    return hdr->name + "." + field->name;
}

Visitor::profile_t PackBridgedMetadata::init_apply(const IR::Node* root) {
    ingressBridgedHeader = nullptr;
    egressBridgedHeader = nullptr;
    egressBridgedMap.clear();
    fieldAlignmentMap.clear();
    for (auto kv : fields.bridged_to_orig)
        egressBridgedMap[getEgressFieldName(kv.second->name)] = getEgressFieldName(kv.first->name);

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
            LOG1(kv.first << "\t" << kv.second); }

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
    LOG1("Number of bits in header: " << rv);
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
    LOG4("\t" << errorMessage << ": " << f1->name << " (" << f1->size << "b), " << f2->name << " ("
         << f2->size << "b)");
}

void PackBridgedMetadata::bridgedActionAnalysis(
        const IR::Header* h,
        std::vector<const IR::StructField*>& nonByteAlignedFields) {
    ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Action*>> fieldToActionWrites;
    for (auto f : nonByteAlignedFields) {
        cstring fieldName = getFieldName(h, f);
        const auto* field = phv.field(fieldName);
        BUG_CHECK(field, "Field corresponding to name %1% not found", fieldName);
        fieldToActionWrites[field] = actionConstraints.actions_writing_fields(field); }

    // Conservatively, mark fields that are written in the same action as do not pack. Also,
    for (auto f1 : nonByteAlignedFields) {
        cstring fieldName1 = getFieldName(h, f1);
        const auto* field1 = phv.field(fieldName1);
        bool isSpecialityDest1 = actionConstraints.hasSpecialityReads(field1);
        bool isMoveOnlyDest1 = actionConstraints.move_only_operations(field1);
        BUG_CHECK(fieldToActionWrites.count(field1), "Did not find actions writing to field %1%",
                fieldName1);
        for (auto f2 : nonByteAlignedFields) {
            cstring fieldName2 = getFieldName(h, f2);
            const auto* field2 = phv.field(fieldName2);
            BUG_CHECK(fieldToActionWrites.count(field2), "Did not find actions writing to field "
                    "%1%", fieldName2);
            bool isSpecialityDest2 = actionConstraints.hasSpecialityReads(field2);
            bool isMoveOnlyDest2 = actionConstraints.move_only_operations(field2);
            if (field1 == field2) {
                continue;
            } else if (field1->is_marshaled() || field2->is_marshaled()) {
                // Do not pack fields together if one or both of them is mirrored/resubmitted.
                doNotPack(field1->id, field2->id) = true;
                printNoPackConstraint("Marshaled", field1, field2);
            } else if (isSpecialityDest1 || isSpecialityDest2) {
                // Do not pack fields together if one or both of them is the result of a speciality
                // operation (HASH_DIST, METER_ALU, METER_COLOR, or RANDOM).
                doNotPack(field1->id, field2->id) = true;
                printNoPackConstraint("Speciality Destination", field1, field2);
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
}

void PackBridgedMetadata::determineAlignmentConstraints(
        const IR::Header* h,
        const std::vector<const IR::StructField*>& nonByteAlignedFields,
        ordered_set<const IR::StructField*>& alignmentConstraints) {
    for (auto structField : nonByteAlignedFields) {
        ordered_set<const PHV::Field*> relatedFields;
        std::queue<const PHV::Field*> fieldsNotVisited;
        cstring fieldName = getFieldName(h, structField);
        const auto* field = phv.field(fieldName);
        BUG_CHECK(field, "No field named %1% found", fieldName);
        // Also summarize the egress version of this field, as alignment constraints may be induced
        // by uses of the egress version of the bridged field.
        cstring egressFieldName = getNonBridgedEgressFieldName(fieldName);
        BUG_CHECK(egressFieldName, "No egress version of the field %1%", fieldName);
        const auto* egressField = phv.field(egressFieldName);
        BUG_CHECK(egressField, "No egress field %1%", egressFieldName);
        // Add the ingress field and its egress version to visit.
        fieldsNotVisited.push(field);
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
                if (fieldAlignmentMap.count(field)) {
                    // alignSource is where the alignment constraint originates from.
                    const PHV::Field* alignSource = fieldAlignmentMap[field];
                    BUG_CHECK(alignSource->alignment, "No alignment for field %1%",
                              alignSource->name);
                    LOG5("\t\t  Old alignment: " << *(alignSource->alignment));
                    // Only compare the little endian alignments because the network endian
                    // alignments differ for some fields of different sizes.
                    // XXX(Deep): Figure out why we get conflicting alignment constraints for
                    // related fields and how to reconcile it. Until then, don't pack these fields
                    // with anything else.
                    WARN_CHECK(f->alignment->littleEndian == alignSource->alignment->littleEndian,
                               "Conflicting alignment constraints detected for bridged field %1%"
                               ": %2%, %3%", field->name, f->alignment->littleEndian,
                               alignSource->alignment->littleEndian);
                    continue; }
                fieldAlignmentMap[field] = f;
                alignmentConstraints.insert(structField); } } }
    if (LOGGING(4)) {
        LOG4("\tPrinting bridged fields with alignment constraints:");
        for (auto f : alignmentConstraints)
            LOG4("\t  " << f); }
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
        auto* layoutKind = new IR::StringLiteral(IR::ID("flexible"));
        auto* egressBridgedHeaderType = new IR::Type_Header(h->type->name,
            new IR::Annotations({ new IR::Annotation(IR::ID("layout"), {layoutKind}) }),
            ingressBridgedHeader->type->fields);
        LOG1("Egress Bridged header: " << egressBridgedHeaderType);
        egressBridgedHeader = new IR::Header(h->name, egressBridgedHeaderType);
        return egressBridgedHeader; }

    // Ingress bridged metadata header, if it comes here.
    LOG1("Original Ingress header layout: " << h->type);
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
    bridgedActionAnalysis(h, nonByteAlignedFields);

    // Determine nonbyte-aligned bridged fields with alignment constraints.
    ordered_set<const IR::StructField*> alignmentConstraints;
    determineAlignmentConstraints(h, nonByteAlignedFields, alignmentConstraints);

    unsigned padFieldId = 0;
    ordered_set<const IR::StructField*> alreadyPackedFields;
    for (auto f1 : nonByteAlignedFields) {
        if (alreadyPackedFields.count(f1)) {
            LOG4("\t  A. Already packed " << f1->name);
            continue; }
        bool hasDeparserParam = false;
        std::vector<const IR::StructField*> fieldsPackedTogether;
        fieldsPackedTogether.push_back(f1);
        alreadyPackedFields.insert(f1);
        const PHV::Field* tempField = phv.field(getFieldName(h, f1));
        LOG3("\t  Trying to pack fields with " << tempField->name);
        if (deparserParams.count(tempField))
            hasDeparserParam = true;

        int alignment = getAlignment(f1->type->width_bits());
        // Find other fields to be packed together with field @f1.
        // As nonByteAlignedFields is sorted in increasing order of width, we start looking from the
        // end of the vector to find the largest field that could fit within that byte.
        // If there are alignment constraints, we don't pack anything with this field.
        // XXX(Deep): A future iteration could pack fields that have alignment constraints into the
        // correct offset within a byte.
        // XXX(Deep): A future iteration could look at 32-bit chunks for packing instead of 8-bit
        // chunks.
        if (!alignmentConstraints.count(f1) && alignment > 0) {
            for (auto it = nonByteAlignedFields.rbegin(); it != nonByteAlignedFields.rend(); ++it) {
                const IR::StructField* candidate = *it;
                if (f1 == candidate) continue;
                if (alreadyPackedFields.count(candidate)) {
                    LOG4("\t\tB. Already packed " << candidate->name);
                    continue; }
                if (candidate->type->width_bits() > alignment) {
                    LOG4("\t\tC. Cannot pack " << candidate->name << " within the same byte");
                    continue; }
                if (alignmentConstraints.count(candidate)) {
                    LOG4("\t\tC. Cannot pack " << candidate->name << " because alignment"
                         " constraints are present");
                    continue; }
                cstring candidateName = getFieldName(h, candidate);
                const auto* candidateField = phv.field(candidateName);
                // If packing of these fields possible, then pack is set to true.
                bool pack = true;
                // Only one deparser parameter field can be packed into a single byte of the bridged
                // metadata header.
                if (hasDeparserParam && deparserParams.count(candidateField))
                    pack = false;
                if (deparserParams.count(candidateField))
                    hasDeparserParam = true;
                // Check against all fields already packed together
                for (auto* candidate2 : fieldsPackedTogether) {
                    cstring candidateName2 = getFieldName(h, candidate2);
                    const auto* candidateField2 = phv.field(candidateName2);
                    if (doNotPack(candidateField->id, candidateField2->id))
                        pack = false; }

                if (!pack) continue;
                LOG3("\t  fieldsPackedTogether: Now contains " << candidate->name);
                fieldsPackedTogether.push_back(candidate);
                alreadyPackedFields.insert(candidate);
                alignment -= candidate->type->width_bits(); } }

        int bitSize = 0;
        for (auto f : fieldsPackedTogether)
            bitSize += f->type->width_bits();
        alignment = getAlignment(bitSize);
        if (alignment != 0) {
            cstring padFieldName = "__pad_" + cstring::to_cstring(padFieldId++);
            auto* fieldAnnotations = new IR::Annotations({new IR::Annotation(IR::ID("hidden"), { })
                                                        });
            const IR::StructField* padding = new IR::StructField(padFieldName, fieldAnnotations,
                                                                 IR::Type::Bits::get(alignment));
            fields.push_back(padding);
            LOG4("Pushing padding field " << padding->name << " of type " <<
                 padding->type->width_bits() << "b."); }

        // Ensure that any bridged field used as a deparser parameter will be packed accordingly.
        // Note that there is only one such field in every fieldsPackedTogether set.
        std::sort(fieldsPackedTogether.begin(), fieldsPackedTogether.end(),
            [&](const IR::StructField* a, const IR::StructField* b) {
                cstring aName = getFieldName(h, a);
                cstring bName = getFieldName(h, b);
                const PHV::Field* fieldA = phv.field(aName);
                const PHV::Field* fieldB = phv.field(bName);
                if (deparserParams.count(fieldA) && !deparserParams.count(fieldB))
                    return false;
                if (!deparserParams.count(fieldA) && deparserParams.count(fieldB))
                    return true;
                return aName < bName;
        });

        for (auto it = fieldsPackedTogether.begin(); it != fieldsPackedTogether.end(); ++it) {
            const PHV::Field* fld = phv.field(getFieldName(h, *it));
            LOG4("Pushing field " << fld << " of type " << (*it)->type->width_bits() <<
                 "b.");
            fields.push_back(*it); } }

    auto* layoutKind = new IR::StringLiteral(IR::ID("flexible"));
    auto* ingressBridgedHeaderType = new IR::Type_Header(h->type->name,
            new IR::Annotations({ new IR::Annotation(IR::ID("layout"), {layoutKind}) }),
            fields);
    LOG1("Ingress Bridged header : " << ingressBridgedHeaderType);
    ingressBridgedHeader = new IR::Header(h->name, ingressBridgedHeaderType);
    return ingressBridgedHeader;
}

void ReplaceBridgedMetadataUses::addBridgedFields(const IR::Header* header) {
    // packetIndex stores the offset within the header.
    unsigned packetIndex = 0;
    if (!header) return;
    for (auto f : header->type->fields) {
        cstring fieldName = PackBridgedMetadata::getFieldName(header, f);
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
        LOG1("    New shift calculated: " << shift);
        auto* newTransition =  new IR::BFN::Transition(constValue->value, shift, t->next);
        newTransition->saves = t->saves;
        transitions.push_back(newTransition); }
    IR::BFN::ParserState* newParserState =
        new IR::BFN::ParserState(p->name, p->gress, p->statements, p->selects, transitions);
    LOG1("    New Parser State: " << newParserState);
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
    if (egressBridgedMap.count(f->name))
        return replaceExtract(e, f);
    return e;
}

void ReplaceBridgedMetadataUses::replaceEmit(const IR::BFN::Emit* e) {
    auto* source = e->source;
    auto* povBit = e->povBit;
    auto* fieldSource = phv.field(source->field);
    // At this point, these emits may correspond to old padding fields that will be removed later by
    // dead code elimination. Therefore, no BUG_CHECK here.
    if (!fieldSource || !bridgedFields.count(fieldSource->name))
        return;
    LOG4("\t  Found emit for bridged field " << e);
    const IR::Member* oldMember = source->field->to<IR::Member>();
    BUG_CHECK(oldMember, "Member corresponding to %1% not found", source->field);
    const IR::Type* type = bridgedFields.at(fieldSource->name);
    const IR::Member* newMember = new IR::Member(source->field->srcInfo, type, new
            IR::ConcreteHeaderRef(pack.getIngressBridgedHeader()), oldMember->member);
    IR::BFN::Emit* newEmit = new IR::BFN::Emit(newMember, povBit->field);
    newEmits[fieldSource->name] = newEmit;
    LOG3("\t  New emit: " << newEmit);
}

IR::Node* ReplaceBridgedMetadataUses::preorder(IR::BFN::Emit* e) {
    const IR::Expression* source = e->source->field;
    const PHV::Field* f = phv.field(source);
    if (!f) return e;
    cstring name = cstring(PackBridgedMetadata::INGRESS_FIELD_PREFIX) +
                   cstring(PackBridgedMetadata::BRIDGED_FIELD_PREFIX);
    if (f->name.startsWith(name)) {
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
        cstring fieldName = PackBridgedMetadata::getFieldName(h, f);
        BUG_CHECK(newEmits.count(fieldName), "New emit corresponding to field name %1% not found",
                fieldName);
        d->emits.insert(d->emits.begin(), newEmits.at(fieldName)); }
    if (LOGGING(3)) {
        for (auto e : d->emits) {
            LOG3("Reprint emit " << ++numEmit << " : " << e); } }
    return d;
}

BridgedMetadataPacking::BridgedMetadataPacking(
            const PhvInfo& p,
            DependencyGraph& dg,
            CollectBridgedFields& b,
            const MauBacktracker& alloc)
    : bridgedFields(b),
      packConflicts(p, dg, tMutex, alloc, aMutex),
      actionConstraints(p, packConflicts),
      packMetadata(p, b, actionConstraints, doNotPack, phase0Fields, deparserParams) {
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
              &packMetadata,
              new ReplaceBridgedMetadataUses(p, packMetadata, bridgedFields)
          });
}
