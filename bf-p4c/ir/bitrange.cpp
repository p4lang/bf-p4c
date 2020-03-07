#include "bf-p4c/ir/bitrange.h"

#include <iostream>
#include <utility>

#include "ir/ir.h"
#include "ir/json_generator.h"
#include "ir/json_loader.h"

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
    if (unit == RangeUnit::Bit) out << "bit";
    else if (unit == RangeUnit::Byte) out << "byte";
    else
        BUG("unknown range unit");

    out << (!closed && order == Endian::Little ? "(" : "[");

    if (order == Endian::Little) std::swap(lo, hi);

    out << std::dec << lo;
    if (lo != hi) out << ".." << hi;

    out << (!closed && order == Endian::Network ? ")" : "]");

    return out;
}
