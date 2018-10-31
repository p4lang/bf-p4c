#include "table_phv_constraints.h"
#include "bf-p4c/mau/table_layout.h"

Visitor::profile_t TablePhvConstraints::init_apply(const IR::Node* root) {
    profile_t rv = MauModifier::init_apply(root);
    return rv;
}

bool TablePhvConstraints::preorder(IR::MAU::Table* tbl) {
    if (tbl->uses_gateway()) return true;
    if (isATCAM(tbl)) return true;
    if (isTernary(tbl))
        calculateTernaryMatchKeyConstraints(tbl);
    return true;
}

void TablePhvConstraints::end_apply() {
    return;
}

bool TablePhvConstraints::isATCAM(IR::MAU::Table *tbl) const {
    cstring partition_index;
    IR::MAU::Table::Layout layout;
    DoTableLayout::check_for_atcam(layout, tbl, partition_index, phv);
    return layout.atcam;
}

bool TablePhvConstraints::isTernary(IR::MAU::Table *tbl) const {
    if (!tbl->match_table) return false;
    IR::MAU::Table::Layout layout;
    DoTableLayout::check_for_ternary(layout, tbl);
    return layout.ternary;
}

void TablePhvConstraints::calculateTernaryMatchKeyConstraints(const IR::MAU::Table* tbl) const {
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
