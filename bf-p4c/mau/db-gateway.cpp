#include "gateway.h"
#include "bf-p4c/phv/phv_fields.h"
#include "ir/dbprint.h"
#include "lib/indent.h"

using namespace DBPrint;
using namespace IndentCtl;

std::ostream &operator<<(std::ostream &out, const CollectGatewayFields::info_t &info) {
    out << info.bits;
    if (info.need_range) out << " range";
    if (~info.need_mask) out << " mask=0x" << hex(info.need_mask);
    for (auto &off : info.offsets) out << " " << off.first << ":" << off.second;
    for (auto &off : info.xor_offsets) out << " xor:" << off.first << ":" << off.second;
    return out;
}

std::ostream &operator<<(std::ostream &out, const CollectGatewayFields &gwf) {
    out << indent;
    for (auto &i : gwf.info) {
        out << endl << i.first->name << i.second;
        for (auto *x : i.second.xor_with) {
            out << " xor " << x->name;
            if (gwf.info.count(x))
                out << gwf.info.at(x).bits;
            else
                out << "<invalid>"; } }
    out << endl << "bytes=" << gwf.bytes << " bits=" << gwf.bits << unindent;
    return out;
}
