#include "asm_output.h"

struct regused {
    int         B=0, H=0, W=0;
};

static void emit_phv_field(std::ostream &out, regused &use, const PhvInfo::Info &field) {
    out << "  " << field.name << ": ";
    int size = 0;
    if (field.size <= 8) {
        out << "B" << use.B++;
        size = 8;
    } else if (field.size <= 16) {
        out << "H" << use.H++;
        size = 16;
    } else {
        out << "W" << use.W++;
        size = 32; }
    if (field.size < size)
        out << "(0.." << (field.size-1) << ")";
    out << std::endl;
}

std::ostream &operator<<(std::ostream &out, const PhvAsmOutput &phvasm) {
    regused use;
    out << "phv ingress:" << std::endl;
    for (auto &f : phvasm.phv)
        emit_phv_field(out, use, f);
    out << "phv egress:" << std::endl;
    for (auto &f : phvasm.phv)
        emit_phv_field(out, use, f);
    return out;
}
