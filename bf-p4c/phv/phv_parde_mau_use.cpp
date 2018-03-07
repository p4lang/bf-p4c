#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"
#include "lib/stringref.h"

//***********************************************************************************
//
// class Phv_Parde_Mau_Use
//
// preorder walk on IR tree to compute use information
//
//***********************************************************************************

Visitor::profile_t Phv_Parde_Mau_Use::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    in_mau = false;
    in_dep = false;
    for (auto &x : use_i) for (auto &y : x) y.clear();
    for (auto &x : deparser_i) x.clear();
    for (auto &x : extracted_i) x.clear();
    written_i.clear();
    used_alu_i.clear();
    return rv;
}

bool Phv_Parde_Mau_Use::preorder(const IR::BFN::Parser *p) {
    in_mau = false;
    in_dep = false;
    thread = p->gress;
    revisit_visited();
    return true;
}

bool Phv_Parde_Mau_Use::preorder(const IR::BFN::Extract *e) {
    auto* f = phv.field(e->dest->field);
    BUG_CHECK(f, "Extract to non-PHV destination: %1%", e);
    extracted_i[thread][f->id] = true;
    return true;
}

bool Phv_Parde_Mau_Use::preorder(const IR::BFN::Deparser *d) {
    thread = d->gress;
    in_mau = false;
    in_dep = true;
    revisit_visited();
    return true;
}

bool Phv_Parde_Mau_Use::preorder(const IR::MAU::TableSeq *) {
    in_mau = true;
    in_dep = false;
    revisit_visited();
    return true;
}

bool Phv_Parde_Mau_Use::preorder(const IR::Expression *e) {
    if (auto *hr = e->to<IR::HeaderRef>()) {
        for (auto id : phv.struct_info(hr).field_ids()) {
            use_i[in_mau][thread][id] = true;
            deparser_i[thread][id] = in_dep; } }

    if (auto info = phv.field(e)) {
        // Used in MAU.
        LOG5("use " << info->name << " in " << thread << (in_mau ? " mau" : ""));
        use_i[in_mau][thread][info->id] = true;

        // Used in ALU instruction.
        if (findContext<IR::MAU::Instruction>() != nullptr) {
            LOG5("use " << info->name << " in ALU instruction");
            used_alu_i[info->id] = true; }

        // Used in deparser.
        LOG5("dep " << info->name << " in " << thread << (in_dep ? " dep" : ""));
        deparser_i[thread][info->id] = in_dep;

        if (isWrite() && in_mau)
            written_i[info->id] = true;
        return false;
    } else if (e->is<IR::Member>()) {  // prevent descent into IR::Member objects
        return false;
    }
    return true;
}

void Phv_Parde_Mau_Use::end_apply() {
    // Header stacks have two aliases for POV bits: stack.$stkvalid aliases
    // with stack.$push, stack.$pop, and stack[N].$valid for all N.  $stkvalid
    // is used in push/pop operations, whereas $valid is used in the
    // parser/deparser and isValid().  When any $valid field is used, treat
    // $stkvalid as used in the same way.
    for (auto gress : { INGRESS, EGRESS }) {
        for (auto stack : *stacks) {
            PhvInfo::StructInfo info = phv.struct_info(stack.name);
            if (info.gress != gress)
                continue;
            char buffer[16];
            for (int i = 0; i < stack.size; ++i) {
                snprintf(buffer, sizeof(buffer), "[%d]", i);
                auto* valid = phv.field(stack.name + buffer + ".$valid");
                auto* stkvalid = phv.field(stack.name + ".$stkvalid");

                // Sanity check.  These should be added in PhvInfo::allocatePOV.
                BUG_CHECK(valid, "No PHV field for %1%?", stack.name + buffer + ".$valid");
                BUG_CHECK(stkvalid, "No PHV field for %1%?", stack.name + ".$stkvalid");

                // However valid is used, so too is stkvalid.
                // XXX(cole): Define |= for nonconst_bitref.
                use_i[PARDE][gress][stkvalid->id] = use_i[PARDE][gress][stkvalid->id]
                                                  | use_i[PARDE][gress][valid->id];
                use_i[MAU][gress][stkvalid->id]   = use_i[MAU][gress][stkvalid->id]
                                                  | use_i[MAU][gress][valid->id];
                deparser_i[gress][stkvalid->id]   = deparser_i[gress][stkvalid->id]
                                                  | deparser_i[gress][valid->id];
                written_i[stkvalid->id]           = written_i[stkvalid->id]
                                                  | written_i[valid->id];
                used_alu_i[stkvalid->id]          = used_alu_i[stkvalid->id]
                                                  | used_alu_i[valid->id]; } } }
}

//
// Phv_Parde_Mau_Use routines that check use_i[]
//

bool Phv_Parde_Mau_Use::is_referenced(const PHV::Field *f) const {      // use in mau or parde
    BUG_CHECK(f, "Null field");
    if (f->bridged) {
        // bridge metadata
        return true;
    }
    return is_used_mau(f) || is_used_parde(f);
}

bool Phv_Parde_Mau_Use::is_deparsed(const PHV::Field *f) const {      // use in deparser
    BUG_CHECK(f, "Null field");
    bool use_deparser = deparser_i[f->gress][f->id];
    return use_deparser;
}

bool Phv_Parde_Mau_Use::is_used_mau(const PHV::Field *f) const {      // use in mau
    BUG_CHECK(f, "Null field");
    bool use_mau = use_i[1][f->gress][f->id];
    return use_mau;
}

bool Phv_Parde_Mau_Use::is_used_alu(const PHV::Field *f) const {      // use in mau
    BUG_CHECK(f, "Null field");
    bool use_mau = use_i[1][f->gress][f->id];
    return use_mau;
}


bool Phv_Parde_Mau_Use::is_written_mau(const PHV::Field *f) const {
    BUG_CHECK(f, "Null field");
    return written_i[f->id];
}

bool Phv_Parde_Mau_Use::is_used_parde(const PHV::Field *f) const {    // use in parser/deparser
    BUG_CHECK(f, "Null field");
    bool use_pd = use_i[0][f->gress][f->id];
    return use_pd;
}

bool Phv_Parde_Mau_Use::is_extracted(const PHV::Field *f, boost::optional<gress_t> gress) const {
    BUG_CHECK(f, "Null field");
    if (!gress)
        return extracted_i[INGRESS][f->id] || extracted_i[EGRESS][f->id];
    else
        return extracted_i[*gress][f->id];
}

//***********************************************************************************
//
// class PhvUse
//
// preorder walk on IR tree to set compute use information
//
//***********************************************************************************

bool PhvUse::preorder(const IR::BFN::Deparser *d) {
    thread = d->gress;
    in_dep = true;

    revisit_visited();
    visit(d->digests, "digests");
    visit(d->params, "params");

    revisit_visited();
    visit(d->emits, "emits");

    return false;
}

bool PhvUse::preorder(const IR::BFN::DeparserParameter*) {
    // Treat fields which are used to set intrinsic deparser parameters as if
    // they're used in the MAU, because they can't go in TPHV.
    in_mau = true;
    return true;
}

void PhvUse::postorder(const IR::BFN::DeparserParameter*) {
    in_mau = false;
}

bool PhvUse::preorder(const IR::BFN::Digest*) {
    // Treat fields which are used in digests as if they're used in the MAU,
    // because they can't go in TPHV.
    in_mau = true;
    return true;
}

void PhvUse::postorder(const IR::BFN::Digest*) {
    in_mau = false;
}
