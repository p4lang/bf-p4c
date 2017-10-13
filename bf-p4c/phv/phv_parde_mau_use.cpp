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
    return rv;
}

bool Phv_Parde_Mau_Use::preorder(const IR::BFN::Parser *p) {
    in_mau = false;
    in_dep = false;
    thread = p->gress;
    revisit_visited();
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
            deparser_i[thread][id] = in_dep;
        }
    }
    if (auto info = phv.field(e)) {
        LOG5("use " << info->name << " in " << thread << (in_mau ? " mau" : ""));
        use_i[in_mau][thread][info->id] = true;
        LOG5("dep " << info->name << " in " << thread << (in_dep ? " dep" : ""));
        deparser_i[thread][info->id] = in_dep;
        return false;
    } else if (e->is<IR::Member>()) {  // prevent descent into IR::Member objects
        return false;
    }
    return true;
}

//
// Phv_Parde_Mau_Use routines that check use_i[]
//

bool Phv_Parde_Mau_Use::is_referenced(const PHV::Field *f) const {      // use in mau or parde
    assert(f);
    if (f->bridged) {
        // bridge metadata
        return true;
    }
    return is_used_mau(f) || is_used_parde(f);
}

bool Phv_Parde_Mau_Use::is_deparsed(const PHV::Field *f) const {      // use in deparser
    assert(f);
    bool use_deparser = deparser_i[f->gress][f->id];
    return use_deparser;
}

bool Phv_Parde_Mau_Use::is_used_mau(const PHV::Field *f) const {      // use in mau
    assert(f);
    bool use_mau = use_i[1][f->gress][f->id];
    return use_mau;
}

bool Phv_Parde_Mau_Use::is_used_parde(const PHV::Field *f) const {    // use in parser/deparser
    assert(f);
    bool use_pd = use_i[0][f->gress][f->id];
    return use_pd;
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
    in_mau = true;  // treat metadata and digests as in mau as they can't go in TPHV
    in_dep = true;
    revisit_visited();
    visit(d->metadata, "metadata");
    visit(d->digests, "digests");
    in_mau = false;
    revisit_visited();
    visit(d->emits, "emits");
    return false;
}
