#include "bf-p4c/phv/table_phv_constraints.h"
#include "bf-p4c/mau/table_layout.h"

Visitor::profile_t TernaryMatchKeyConstraints::init_apply(const IR::Node* root) {
    profile_t rv = MauModifier::init_apply(root);
    return rv;
}

bool TernaryMatchKeyConstraints::preorder(IR::MAU::Table* tbl) {
    if (tbl->uses_gateway()) return true;
    if (isATCAM(tbl)) return true;
    if (isTernary(tbl))
        calculateTernaryMatchKeyConstraints(tbl);
    return true;
}

void TernaryMatchKeyConstraints::end_apply() {
    return;
}

bool TernaryMatchKeyConstraints::isATCAM(IR::MAU::Table *tbl) const {
    cstring partition_index;
    IR::MAU::Table::Layout layout;
    DoTableLayout::check_for_atcam(layout, tbl, partition_index, phv);
    return layout.atcam;
}

bool TernaryMatchKeyConstraints::isTernary(IR::MAU::Table *tbl) const {
    if (!tbl->match_table) return false;
    IR::MAU::Table::Layout layout;
    DoTableLayout::check_for_ternary(layout, tbl);
    return layout.ternary;
}

void
TernaryMatchKeyConstraints::calculateTernaryMatchKeyConstraints(const IR::MAU::Table* tbl) const {
    LOG4("\tCalculating ternary match key constraints for " << tbl->name);
    size_t totalBytesUsed = 0;
    size_t totalMetadataBytesUsed = 0;
    ordered_set<PHV::Field*> fields;
    // Calculate total rounded up (to nearest byte) size of all match key fields
    // Also calculate total rounded up (to nearest byte) size of all match key metadata fields
    for (const IR::MAU::InputXBarRead* matchKey : tbl->match_key) {
        LOG5("\t\t" << matchKey->expr);
        PHV::Field* f = phv.field(matchKey->expr);
        size_t roundedUpSize = (f->size % BITS_IN_BYTE == 0) ? (f->size / BITS_IN_BYTE) : (f->size /
                BITS_IN_BYTE + 1);
        totalBytesUsed += roundedUpSize;
        if (f->metadata && !f->deparsed_to_tm()) {
            totalMetadataBytesUsed += roundedUpSize;
            fields.insert(f); } }
    LOG4("\tTotal bytes used for match key by ternary table: " << totalBytesUsed);
    LOG4("\tTotal bytes used for match key by metadata     : " << totalMetadataBytesUsed);
    // xxx(Deep): Can we calculate a better threshold?
    // If the total size then exceeds the match key size threshold defined for ternary tables,
    // introduce a bit in byte alignment for all metadata fields
    if (totalBytesUsed <  TERNARY_MATCH_KEY_BITS_THRESHOLD)
        return;
    for (auto* f : fields) {
        // Extract the non-const version of the field
        le_bitrange range = StartLen(0, f->size - 1);
        FieldAlignment alignment(range);
        f->updateAlignment(alignment);
        LOG4("\tSetting alignment for field " << f->name << " to " << alignment); }
}

Visitor::profile_t HashFieldsContainerSize::init_apply(const IR::Node* root) {
    hashDests.clear();
    hashBitsUsage.clear();
    return Inspector::init_apply(root);
}

bool HashFieldsContainerSize::preorder(const IR::MAU::Instruction* inst) {
    if (inst->name != "set") return false;
    if (inst->operands.size() != 2) return false;
    if (!inst->operands[1]->is<IR::MAU::HashDist>()) return false;
    const IR::MAU::Table* table = findContext<IR::MAU::Table>();
    if (!table) BUG("This hash dist did not appear in a table?");
    le_bitrange fieldBits;
    PHV::Field* field = phv.field(inst->operands[0], &fieldBits);
    if (!field) BUG("No destination for instruction %1%", inst);
    // Note down the PHV slice that is the destination for hash value and the bits required by that
    // destination.
    hashDests[table].push_back(PHV::FieldSlice(field, fieldBits));
    hashBitsUsage[table] += (8 * ROUNDUP(fieldBits.size(), 8));
    LOG2("\tAdding range " << fieldBits << " of field " << field->name << " to hash dest for "
         "table " << table->name);
    return true;
}

void HashFieldsContainerSize::end_apply() {
    for (auto kv : hashDests) {
        if (!hashBitsUsage.count(kv.first))
            BUG("No hash bits usage information for table %1%", kv.first->name);
        if (hashBitsUsage[kv.first] > 32) {
            std::stringstream ss;
            for (const auto& slice : kv.second)
                ss << "\t" << slice.field()->name << " : " << ((8 * ROUNDUP(slice.size(), 8)) / 8)
                   << "B" << std::endl;
            P4C_UNIMPLEMENTED(
            "\nCannot allocate >4 immediate bytes for logical table %1%. Currently require:\n%2%"
            "Try separating the actions using hash output into multiple logical tables.",
            kv.first->name, ss.str());
            continue;
        }
        // If it is a single destination slice, it could be put in any container without violating
        // the packing constraints imposed by the current packing scheme.
        if (kv.second.size() == 1) {
            PHV::FieldSlice& slice = *(kv.second.begin());
            // The slice is actually the entire field.
            if (slice.size() == slice.field()->size) {
                // Get a non-const field object.
                PHV::Field* field = phv.field(slice.field()->name);
                // Set the maximum number of container bytes for this field to be 4.
                // XXX(Deep): Handle this via sum-of constraint.
                // XXX(Deep): Handle case where the single object is a field slice that is part of
                // the field.
                LOG2("\t  Setting maximum container bytes for " << field->name << " to 4.");
                field->setMaxContainerBytes(4);
            }
            continue;
        }
        LOG2("\tLogical table: " << kv.first->name);
        // Impose the constraint that the destination slices be allocated to the nearest
        // natural-sized PHV container.
        for (const auto& slice : kv.second) {
            if (slice.size() != slice.field()->size) {
                ::warning("Cannot impose constraint for immediate pathway to slice [%1%, %2%] for "
                          "%3%", slice.range().lo, slice.range().hi, slice.field()->name);
                continue;
            }
            int reqContainerSize = 8 * ROUNDUP(slice.size(), 8);
            std::vector<PHV::Size> reqSizes;
            cstring sizeReqString;
            if (reqContainerSize <= ONE_BYTE) {
                reqSizes.push_back(PHV::Size::b8);
                sizeReqString = "an 8b container";
                LOG2("\t  Setting " << slice.field()->name << " to 8-bit container.");
            } else if (reqContainerSize <= TWO_BYTES) {
                reqSizes.push_back(PHV::Size::b16);
                sizeReqString = "a 16b container";
                LOG2("\t  Setting " << slice.field()->name << " to 16-bit container.");
            } else if (reqContainerSize <= THREE_BYTES) {
                reqSizes.push_back(PHV::Size::b16);
                reqSizes.push_back(PHV::Size::b8);
                sizeReqString = "a 16b and an 8b container";
                LOG2("\t  Setting " << slice.field()->name << " to 16-bit and an 8-bit container.");
            } else {
                sizeReqString = "a 32b container";
                reqSizes.push_back(PHV::Size::b32);
                LOG2("\t  Setting " << slice.field()->name << " to 32-bit container.");
            }
            if (!containerSize.check_and_add_constraint(slice.field(), reqSizes))
                ::error("To fit hash destinations in less than 4 immediate bytes, we must assign "
                        "field %1% to %2%. However, this conflicts with an existing "
                        "pa_container_size constraint.", slice.field()->name, sizeReqString);
        }
    }
}
