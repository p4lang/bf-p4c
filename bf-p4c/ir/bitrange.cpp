#include "bf-p4c/ir/bitrange.h"

#include <iostream>
#include <utility>

#include "ir/json_loader.h"

namespace {

void writeRangeToStream(std::ostream& out, const char* prefix, int lo, int hi,
                        const char* suffix) {
    out << std::dec << prefix << lo;
    if (hi != lo) out << ".." << hi;
    out << suffix;
}

}  // namespace

void rangeToJSON(JSONGenerator& json, int lo, int hi) {
    json.toJSON(std::make_pair(lo, hi));
}

std::pair<int, int> rangeFromJSON(JSONLoader& json) {
    std::pair<int, int> endpoints;
    json >> endpoints;
    return endpoints;
}

std::ostream& toStream(std::ostream& out, RangeUnit unit,
                       Endian order, int lo, int hi, bool closed) {
    const char* prefix = "?[";
    switch (order) {
        case Endian::Network: prefix = "N["; break;
        case Endian::Little: prefix = "L["; break;
    }
    const char* suffix = closed ? "]?" : ")?";
    switch (unit) {
        case RangeUnit::Bit: suffix = closed ? "]b" : ")b"; break;
        case RangeUnit::Byte: suffix = closed ? "]B" : ")B"; break;
    }
    writeRangeToStream(out, prefix, lo, hi, suffix);
    return out;
}
