#include "asm_output.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/stringref.h"

PhvAsmOutput::PhvAsmOutput(const PhvInfo &p, const FieldDefUse& defuse) : phv(p), defuse(defuse) {
    liveRanges.clear();
    getLiveRanges();
}

PhvAsmOutput::LiveRange PhvAsmOutput::LiveRange::operator|=(const PhvAsmOutput::LiveRange& other) {
    if (first && other.first)
        first = first->stage() < other.first->stage() ? first : other.first;
    else if (!first)
        first = other.first;

    if (last && other.last)
        last = last->stage() < other.last->stage() ? other.last : last;
    else if (!last)
        last = other.last;

    return *this;
}

void PhvAsmOutput::getLiveRanges() {
    for (auto& f : phv)
        for (auto& def : defuse.getAllDefs(f.id))
            for (auto& use : defuse.getUses(def))
                liveRanges[&f] |= { .first = def.first, .last = use.first };
}

void emit_alloc(std::ostream& out, const PHV::Field::alloc_slice& alloc, PHV::Field& f) {
    out << "  " << canon_name(f.externalName());
    if (alloc.field_bit > 0 || alloc.width < f.size)
        out << '.' << alloc.field_bit << '-' << alloc.field_hi();
    out << ": " << alloc.container;
    if (alloc.container_bit > 0 || alloc.container.size() != static_cast<size_t>(alloc.width)) {
        out << '(' << alloc.container_bit;
        if (alloc.width > 1)
            out << ".." << alloc.container_hi();
        out << ')'; }
    out << std::endl;
}

void emit_phv_field(std::ostream& out, PHV::Field& field) {
    field.foreach_alloc([&](const PHV::Field::alloc_slice& slice) {
        emit_alloc(out, slice, field); });
}

void PhvAsmOutput::emit_phv_field_info(std::ostream& out, PHV::Field& f) const {
    out << "    " << canon_name(f.externalName()) << ":" << std::endl;

    // Print live range info.
    auto PrintStage = [](const IR::BFN::Unit* u) {
        if (u->is<IR::BFN::AbstractParser>() || u->is<IR::BFN::ParserState>())
            return std::string("parser");
        else if (auto* t = u->to<IR::MAU::Table>())
            return std::to_string(int(t->logical_id/16));
        else if (u->is<IR::BFN::AbstractDeparser>())
            return std::string("deparser");
        BUG("Unit is not parser, table, or deparser: %1%", cstring::to_cstring(u));
    };

    if (liveRanges.count(&f)) {
        auto& range = liveRanges.at(&f);
        out << "      " << "live_start: " << PrintStage(range.first) << std::endl;
        out << "      " << "live_end: " << PrintStage(range.last) << std::endl; }

    // Print mutual exclusion information.
    out << "      " << "mutually_exclusive_with: [ ";
    std::string sep = "";
    for (auto& f2 : phv) {
        if (phv.mutex()(f.id, f2.id)) {
            out << sep << canon_name(f2.externalName());
            if (sep == "") sep = ", "; } }
    out << " ]" << std::endl;
}

std::ostream &operator<<(std::ostream &out, const PhvAsmOutput& phvasm) {
    bool dumpCtxt = BFNContext::get().options().debugInfo;

    out << "phv ingress:\n";
    for (auto &f : phvasm.phv) {
        if (f.gress == INGRESS) {
            emit_phv_field(out, f); } }

    if (dumpCtxt) {
        out << "  " << "context_json:\n";
        for (auto &f : phvasm.phv) {
            if (f.gress == INGRESS && !f.is_unallocated()) {
                phvasm.emit_phv_field_info(out, f); } } }

    out << "phv egress:\n";
    for (auto &f : phvasm.phv) {
        if (f.gress == EGRESS) {
            emit_phv_field(out, f); } }

    if (dumpCtxt) {
        out << "  " << "context_json:\n";
        for (auto &f : phvasm.phv) {
            if (f.gress == EGRESS && !f.is_unallocated()) {
                phvasm.emit_phv_field_info(out, f); } } }

    return out;
}
