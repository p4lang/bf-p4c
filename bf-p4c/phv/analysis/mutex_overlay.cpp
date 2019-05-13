#include <sstream>
#include <typeinfo>
#include "ir/ir.h"
#include "lib/log.h"
#include "bf-p4c/phv/analysis/mutex_overlay.h"

Visitor::profile_t BuildMutex::init_apply(const IR::Node* root) {
    auto rv = Inspector::init_apply(root);
    mutually_inclusive.clear();
    fields_encountered.clear();
    return rv;
}

Visitor::profile_t BuildParserOverlay::init_apply(const IR::Node* root) {
    auto rv = BuildMutex::init_apply(root);
    LOG4("Beginning BuildParserOverlay");
    return rv;
}

Visitor::profile_t BuildMetadataOverlay::init_apply(const IR::Node* root) {
    auto rv = BuildMutex::init_apply(root);
    LOG4("Beginning BuildMetadataOverlay");
    return rv;
}

void BuildMutex::mark(const PHV::Field* f) {
    if (!f)
        return;
    if (IgnoreField(f)) {
        LOG5("Ignoring field    " << f);
        return;
    } else {
        LOG5("Considering field " << f << " ( "
             << (f->pov ? "pov " : "")
             << (f->metadata ? "metadata " : "")
             << (!f->pov && !f->metadata ? "header " : "") << ")");
    }
    int new_field = f->id;
    fields_encountered[new_field] = true;
    mutually_inclusive[new_field] |= fields_encountered;
}

bool BuildMutex::preorder(const IR::Expression *e) {
    if (auto *f = phv.field(e)) {
        mark(f);
        return false; }
    return true;
}

void BuildMutex::flow_merge(Visitor& other_) {
    BuildMutex &other = dynamic_cast<BuildMutex &>(other_);
    fields_encountered |= other.fields_encountered;
    mutually_inclusive |= other.mutually_inclusive;
}

void BuildMutex::end_apply() {
    LOG4("mutually exclusive fields:");
    for (auto it1 = fields_encountered.begin();
         it1 != fields_encountered.end();
         ++it1 ) {
        const PHV::Field* f1 = phv.field(*it1);
        if (neverOverlay[*it1]) {
            if (f1->overlayablePadding) {
                ::warning("Ignoring pa_no_overlay for padding field %1%", f1->name);
            } else {
                LOG5("Excluding field from overlay: " << *it1);
                continue;
            }
        }
        for (auto it2 = it1; it2 != fields_encountered.end(); ++it2) {
            if (*it1 == *it2) continue;

            // Consider fields marked neverOverlay to always be mutually inclusive.
            const PHV::Field* f2 = phv.field(*it2);
            if (neverOverlay[*it2]) {
                if (f2->overlayablePadding) {
                    ::warning("Ignoring pa_no_overlay for padding field %1%", f2->name);
                } else {
                    LOG5("Excluding field from overlay: " << *it2);
                    continue;
                }
            }

            if (mutually_inclusive(*it1, *it2)) continue;

            mutually_exclusive(*it1, *it2) = true;
            LOG4("(" << f1->name << ", " << f2->name << ")"); } }
}

void ExcludeAliasedHeaderFields::excludeAliasedField(const IR::Expression* alias) {
    // According to PragmaAlias::postorder, header fields can only be aliased with metadata fields,
    // and for these aliases, the header fields are chosen as the alias destination.
    const PHV::Field* aliasDestination = nullptr;
    if (auto aliasMem = alias->to<IR::BFN::AliasMember>()) {
        aliasDestination = phv.field(aliasMem);
    } else if (auto aliasSlice = alias->to<IR::BFN::AliasSlice>()) {
        aliasDestination = phv.field(aliasSlice);
    }
    BUG_CHECK(aliasDestination, "Reference to alias field %1% not found", alias);

    if (aliasDestination->isPacketField()) {
        LOG1("Marking field as never overlaid due to aliasing: " << aliasDestination);
        neverOverlay.setbit(aliasDestination->id);
    }
}

void ExcludeDeparsedIntrinsicMetadata::end_apply() {
    for (auto& f : phv) {
        if (f.pov || f.deparsed_to_tm()) {
            LOG1("Marking field as never overlaid: " << f);
            neverOverlay.setbit(f.id); } }
}

void ExcludePragmaNoOverlayFields::end_apply() {
    for (auto* f : pragma.getFields()) {
        LOG1("Marking field as never overlaid because of pa_no_overlay: " << f);
        neverOverlay.setbit(f->id); }
}

bool ExcludeMAUOverlays::preorder(const IR::MAU::Table* tbl) {
    LOG5("\tTable: " << tbl->name);
    ordered_set<PHV::Field*> keyFields;
    for (auto* key : tbl->match_key) {
        PHV::Field* field = phv.field(key->expr);
        if (!field) continue;
        keyFields.insert(field);
    }
    for (auto* f1 : keyFields) {
        for (auto* f2 : keyFields) {
            if (f1 == f2) continue;
            phv.removeFieldMutex(f1, f2);
            LOG5("\t  Mark key fields for table " << tbl->name << " as non mutually exclusive: "
                 << f1->name << ", " << f2->name);
        }
    }
    return true;
}

bool ExcludeMAUOverlays::preorder(const IR::MAU::Instruction* inst) {
    LOG5("\t\tInstruction: " << inst);
    const IR::MAU::Action* act = findContext<IR::MAU::Action>();
    if (!act) return true;
    if (inst->operands.empty()) return true;
    PHV::Field* field = phv.field(inst->operands[0]);
    if (!field) return true;
    LOG5("\t\tWrite: " << field);
    actionToWrites[act].insert(field);
    for (int idx = 1; idx < int(inst->operands.size()); ++idx) {
        PHV::Field* readField = phv.field(inst->operands[idx]);
        if (!readField) continue;
        LOG5("\t\tRead: " << readField);
        actionToReads[act].insert(readField);
    }
    return true;
}

void ExcludeMAUOverlays::markNonMutex(const ActionToFieldsMap& arg) {
    for (auto& kv : arg) {
        LOG3("\tAction: " << kv.first->name);
        for (auto* f1 : kv.second) {
            for (auto* f2 : kv.second) {
                if (f1 == f2) continue;
                LOG3("\t  Mark as non mutually exclusive: " << f1->name << ", " << f2->name);
                phv.removeFieldMutex(f1, f2); } } }
}

void ExcludeMAUOverlays::end_apply() {
    LOG3("\tMarking all writes in the same action non mutually exclusive");
    markNonMutex(actionToWrites);
    LOG3("\tMarking all reads in the same action non mutually exclusive");
    markNonMutex(actionToReads);
}

Visitor::profile_t MarkMutexPragmaFields::init_apply(const IR::Node* root) {
    // Mark fields specified by pa_mutually_exclusive pragmas
    const ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>>& parsedPragma =
        pragma.mutex_fields();
    for (auto fieldSet : parsedPragma) {
        auto* field1 = fieldSet.first;
        for (auto* field2 : fieldSet.second) {
            if (field1->id == field2->id) continue;
            phv.addFieldMutex(field1, field2);
            LOG1("set " << field1 << " and " << field2
                    << " to be mutually_exclusive because of @pragma pa_mutually_exclusive");
        }
    }
    return Inspector::init_apply(root);
}

bool FindAddedHeaderFields::preorder(const IR::Primitive* prim) {
    // If this is a well-formed field modification...
    if (prim->name == "set" && prim->operands.size() > 1) {
        // that writes a non-zero value to `hdrRef.$valid`...
        auto* m = prim->operands[0]->to<IR::Member>();
        auto* c = prim->operands[1]->to<IR::Constant>();
        if (m && m->member == "$valid" && c && c->asInt() != 0) {
            if (auto* hr = m->expr->to<IR::HeaderRef>()) {
                // then add all fields of the header (not including $valid) to
                // the set of fields that are part of added headers
                LOG1("Found added header.  Conservatively assuming it is not "
                     "mutually exclusive with any other header:" << hr);
                PhvInfo::StructInfo info = phv.struct_info(hr);
                for (int id : info.field_ids()) {
                    rv[id] = true; } } } }
    return false;
}
