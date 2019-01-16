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
    use_i.clear();
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
    auto lval = e->dest->to<IR::BFN::FieldLVal>();
    if (!lval) return true;
    auto* f = phv.field(lval->field);
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
    // FIXME -- treat GHOST thread as ingress for PHV allocation
    if ((thread = VisitingThread(this)) == GHOST)
        thread = INGRESS;
    in_mau = true;
    in_dep = false;
    revisit_visited();
    return true;
}

bool Phv_Parde_Mau_Use::preorder(const IR::Expression *e) {
    if (auto *hr = e->to<IR::HeaderRef>()) {
        for (auto id : phv.struct_info(hr).field_ids()) {
            auto* field = phv.field(id);
            use_i[field][in_mau].insert(StartLen(0, field->size));
            deparser_i[thread][id] = in_dep; } }

    le_bitrange bits;
    if (auto* info = phv.field(e, &bits)) {
        // Used in MAU.
        LOG5("use " << info->name << " in " << thread << (in_mau ? " mau" : ""));
        use_i[info][in_mau].insert(bits);

        // Used in ALU instruction.
        if (findContext<IR::MAU::Instruction>() != nullptr) {
            LOG5("use " << info->name << " in ALU instruction");
            used_alu_i[info].insert(bits);
        }

        // Used in deparser.
        LOG5("dep " << info->name << " in " << thread << (in_dep ? " dep" : ""));
        deparser_i[thread][info->id] = in_dep;

        if (isWrite() && in_mau)
            written_i[info].insert(bits);
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
    if (!use_i.count(f)) return false;
    return use_i.at(f).count(MAU);
}

bool Phv_Parde_Mau_Use::is_used_mau(const PHV::Field* f, le_bitrange range) const {
    BUG_CHECK(f, "Null field");
    if (!use_i.count(f)) return false;
    if (!use_i.at(f).count(MAU)) return false;
    for (auto r : use_i.at(f).at(MAU)) {
        if (range.overlaps(r))
            return true;
    }
    return false;
}

bool Phv_Parde_Mau_Use::is_used_alu(const PHV::Field *f) const {      // use in alu
    BUG_CHECK(f, "Null field");
    return used_alu_i.count(f);
}

bool Phv_Parde_Mau_Use::is_written_mau(const PHV::Field *f) const {
    BUG_CHECK(f, "Null field");
    return written_i.count(f);;
}

bool Phv_Parde_Mau_Use::is_used_parde(const PHV::Field *f) const {    // use in parser/deparser
    BUG_CHECK(f, "Null field");
    bool use_i_pd;
    if (!use_i.count(f))
        use_i_pd = false;
    else
        use_i_pd = use_i.at(f).count(PARDE);
    bool use_pd = use_i_pd || extracted_i[f->gress][f->id];
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
    in_mau = false;

    revisit_visited();
    visit(d->digests, "digests");
    visit(d->params, "params");

    revisit_visited();
    visit(d->emits, "emits");

    return false;
}

bool PhvUse::preorder(const IR::BFN::DeparserParameter*) {
    // Treat fields which are used to set intrinsic deparser parameters as if
    // they're used in the MAU, because they can't go in TPHV or CLOT.
    in_mau = true;
    return true;
}

void PhvUse::postorder(const IR::BFN::DeparserParameter*) {
    in_mau = false;
}

bool PhvUse::preorder(const IR::BFN::Digest*) {
    // Treat fields which are used in digests as if they're used in the MAU,
    // because they can't go in TPHV or CLOT.
    in_mau = true;
    return true;
}

void PhvUse::postorder(const IR::BFN::Digest*) {
    in_mau = false;
}
