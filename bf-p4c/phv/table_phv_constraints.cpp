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
    size_t totalRoundedUpBytes = 0;
    size_t totalMetadataBytesUsed = 0;
    size_t totalBitsUsed = 0;

    // *ALEX*: Commenting *OFF* code used for constraining alignment
    // of ternary match fields. The imposed alignment constraints may
    // lead to erroneous PHV allocation fails due to preventing packing
    // of 1bit or narrow fields into PHV containers (See P4C-2538)

    // *OFF* ordered_set<PHV::Field*> fields;

    // Calculate total rounded up (to nearest byte) size of all match key fields
    // Also calculate total rounded up (to nearest byte) size of all match key metadata fields
    for (const IR::MAU::TableKey* matchKey : tbl->match_key) {
        LOG5("\t\t" << matchKey->expr);
        le_bitrange bits;
        PHV::Field* f = phv.field(matchKey->expr, &bits);
        size_t roundedUpSize = (f->size % BITS_IN_BYTE == 0) ? (f->size / BITS_IN_BYTE) :
            ((f->size / BITS_IN_BYTE) + 1);
        totalBitsUsed += bits.size();
        totalRoundedUpBytes += roundedUpSize;
        if (f->metadata && !f->deparsed_to_tm()) {
            totalMetadataBytesUsed += roundedUpSize;
            // *OFF*      fields.insert(f);
        }
    }
    LOG4("\tTotal bits used for match key by ternary table : " << totalBitsUsed);
    LOG4("\tTotal bytes used for match key by ternary table : " <<
         (((totalBitsUsed % BITS_IN_BYTE) == 0) ? (totalBitsUsed / BITS_IN_BYTE) :
          ((totalBitsUsed / BITS_IN_BYTE) + 1)));

    if (totalBitsUsed > MAX_TERNARY_MATCH_KEY_BITS) {
        ::error("Ternary table %1% uses %2%b as ternary match key. Maximum number of bits "
                "allowed is %3%b.\nRewrite your program to use fewer ternary match key bits."
                "\nTable %1% cannot fit within a single input crossbar in an MAU stage.",
                tbl->name, totalBitsUsed, MAX_TERNARY_MATCH_KEY_BITS);
        return;
    }

    LOG4("\tTotal rounded up bytes used for match key by ternary table: " << totalRoundedUpBytes);
    LOG4("\tTotal bytes used for match key by metadata     : " << totalMetadataBytesUsed);
    // xxx(Deep): Can we calculate a better threshold?
    // If the total size then exceeds the match key size threshold defined for ternary tables,
    // introduce a bit in byte alignment for all metadata fields
    return;
}

bool CollectForceImmediateFields::preorder(const IR::MAU::Action* action) {
    const auto* tbl = findContext<IR::MAU::Table>();
    if (!tbl) return true;
    if (!tbl->is_force_immediate()) return true;
    LOG3("\t  Action " << action->name << " belongs to force_immediate table " << tbl->name);
    auto writtenFields = actions.actionWrites(action);
    ordered_set<const PHV::Field*> fields;
    for (const auto* f : writtenFields) {
        if (actions.written_by_ad_constant(f, action)) {
            fields.insert(f);
            if (!f->metadata) continue;
            PHV::Field* field = phv.field(f->id);
            field->set_written_in_force_immediate(true);
            LOG3("\t\tSetting written in force immediate property for " << f->name);
        }
    }
    if (fields.size() == 0) return true;
    LOG3("\t\tListing fields written by action data/constant in this action:");
    for (auto* f : fields)
        LOG3("\t\t  " << f);
    for (const auto* f1 : fields) {
        for (const auto* f2 : writtenFields) {
            if (f1 == f2) continue;
            if (pack.hasPackConflict(f1, f2)) continue;
            LOG3("\t\tAdding pack conflict between " << f1->name << " and " << f2->name);
            pack.addPackConflict(f1, f2);
        }
    }
    return true;
}

