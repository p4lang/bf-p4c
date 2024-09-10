#include "backends/tofino/ir/bitrange.h"

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
