#include "asm_output.h"

static void emit_phv_field(std::ostream &out, gress_t thread, const PhvInfo::Info &field) {
    for (auto &alloc : field.alloc[thread]) {
        out << "  " << canon_name(field.name);
        if (alloc.field_bit > 0 || alloc.width != field.size)
            out << '.' << alloc.field_bit << '-' << (alloc.field_bit+alloc.width-1);
        out << ": " << alloc.container;
        if (alloc.container_bit > 0 || alloc.container.size() != static_cast<size_t>(alloc.width)) {
            out << '(' << alloc.container_bit;
            if (alloc.width > 1)
                out << ".." << (alloc.container_bit + alloc.width - 1);
            out << ')'; }
        out << std::endl; }
}

std::ostream &operator<<(std::ostream &out, const PhvAsmOutput &phvasm) {
    out << "phv ingress:" << std::endl;
    for (auto &f : phvasm.phv)
        emit_phv_field(out, INGRESS, f);
    out << "phv egress:" << std::endl;
    for (auto &f : phvasm.phv)
        emit_phv_field(out, EGRESS, f);
    return out;
}
