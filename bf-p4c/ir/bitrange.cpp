#include "bf-p4c/ir/bitrange.h"

#include <iostream>
#include <utility>

#include "ir/json_loader.h"

namespace {

void writeRangeToStream(std::ostream& out, const char* prefix, int lo, int hi,
                        const char* suffix) {
    // FIXME(zma) precision?
    out << prefix << lo;
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

std::ostream& writeHalfOpenRangeToStream(std::ostream& out, RangeUnit unit,
                                         Endian order, int lo, int hi) {
    const char* prefix = "?[";
    switch (order) {
        case Endian::Network: prefix = "N["; break;
        case Endian::Little: prefix = "L["; break;
    }
    const char* suffix = ")?";
    switch (unit) {
        case RangeUnit::Bit: suffix = ")b"; break;
        case RangeUnit::Byte: suffix = ")B"; break;
    }
    writeRangeToStream(out, prefix, lo, hi, suffix);
    return out;
}

std::ostream& writeClosedRangeToStream(std::ostream& out, RangeUnit unit,
                                       Endian order, int lo, int hi) {
    const char* prefix = "?[";
    switch (order) {
        case Endian::Network: prefix = "N["; break;
        case Endian::Little: prefix = "L["; break;
    }
    const char* suffix = "]?";
    switch (unit) {
        case RangeUnit::Bit: suffix = "]b"; break;
        case RangeUnit::Byte: suffix = "]B"; break;
    }
    writeRangeToStream(out, prefix, lo, hi, suffix);
    return out;
}
