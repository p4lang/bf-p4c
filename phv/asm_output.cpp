#include "asm_output.h"

static void emit_phv_field(std::ostream &out, const PhvInfo::Info &field) {
    for (auto &alloc : field.alloc) {
        out << "  " << canon_name(field.name);
        if (alloc.field_bit > 0 || alloc.width != field.size)
            out << '.' << alloc.field_bit << '-' << alloc.field_hi();
        out << ": " << alloc.container;
        if (alloc.container_bit > 0 || alloc.container.size() != static_cast<size_t>(alloc.width)) {
            out << '(' << alloc.container_bit;
            if (alloc.width > 1)
                out << ".." << alloc.container_hi();
            out << ')'; }
        out << std::endl; }
}

std::ostream &operator<<(std::ostream &out, const PhvAsmOutput &phvasm) {
    out << "phv ingress:" << std::endl;
    for (auto &f : phvasm.phv)
        if (f.gress == INGRESS && f.referenced)
            emit_phv_field(out, f);
    out << "phv egress:" << std::endl;
    for (auto &f : phvasm.phv)
        if (f.gress == EGRESS && f.referenced)
            emit_phv_field(out, f);
    return out;
}
