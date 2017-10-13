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
    for (auto &off : info.offsets) out << " " << off.first << off.second;
    if (info.xor_with) out << " xor=" << info.xor_with->name;
    return out;
}

std::ostream &operator<<(std::ostream &out, const CollectGatewayFields &gwf) {
    out << indent;
    for (auto &i : gwf.info) {
        out << endl << i.first->name << i.second;
        if (gwf.info.count(i.second.xor_with))
            out << gwf.info.at(i.second.xor_with).bits;
        else if (i.second.xor_with)
            out << "<invalid>"; }
    out << endl << "bytes=" << gwf.bytes << " bits=" << gwf.bits << unindent;
    return out;
}
