#include "asm_output.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/stringref.h"

void emit_alloc(std::ostream &out, const PHV::Field::alloc_slice& alloc, PHV::Field& f, cstring&
        sectionHeaderInOut) {
    out << sectionHeaderInOut;
    sectionHeaderInOut = "";
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

void emit_phv_field(std::ostream &out, PHV::Field &field, cstring& sectionHeaderInOut) {
    for (auto& alloc : field.alloc_i)
        emit_alloc(out, alloc, field, sectionHeaderInOut);
}

std::ostream &operator<<(std::ostream &out, const PhvAsmOutput &phvasm) {
    cstring ingressSectionHeader = "phv ingress:\n";
    for (auto &f : phvasm.phv) {
        if (f.gress == INGRESS) {
            emit_phv_field(out, f, ingressSectionHeader); } }
    cstring egressSectionHeader = "phv egress:\n";
    for (auto &f : phvasm.phv) {
        if (f.gress == EGRESS) {
            emit_phv_field(out, f, egressSectionHeader); } }
    return out;
}
