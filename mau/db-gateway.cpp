#include "gateway.h"
#include "ir/dbprint.h"
#include "lib/indent.h"

using namespace DBPrint;
using namespace IndentCtl;

std::ostream &operator<<(std::ostream &out, const PhvInfo::Field::bitrange &bits) {
    if (bits.lo >= 0) {
        out << '(' << bits.lo;
        if (bits.hi != bits.lo) out << ".." << bits.hi;
        out <<')'; }
    return out;
}

std::ostream &operator<<(std::ostream &out, const CollectGatewayFields &gwf) {
    out << indent;
    for (auto &i : gwf.info) {
        out << endl << i.first->name << i.second.bits;;
        if (i.second.need_range) out << " range";
        if (~i.second.need_mask) out << " mask=0x" << hex(i.second.need_mask);
        if (i.second.xor_with) {
            out << " xor=" << i.second.xor_with->name;
            if (gwf.info.count(i.second.xor_with))
                out << gwf.info.at(i.second.xor_with).bits;
            else
                out << "<invalid>"; } }
    if (!gwf.valid_offsets.empty()) {
        out << endl;
        const char *sep = "";
        for (auto &vb : gwf.valid_offsets) {
            out << sep << vb.first << '=' << vb.second;
            sep = ", "; } }
    out << endl << "bytes=" << gwf.bytes << " bits=" << gwf.bits << unindent;
    return out;
}
