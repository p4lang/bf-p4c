#include "bf-p4c/ir/bitrange.h"

#include <iostream>
#include <utility>

#include "ir/ir.h"
#include "ir/json_generator.h"
#include "ir/json_loader.h"

void rangeToJSON(P4::JSONGenerator& json, int lo, int hi) {
    json.toJSON(std::make_pair(lo, hi));
}

std::pair<int, int> rangeFromJSON(P4::JSONLoader& json) {
    std::pair<int, int> endpoints;
    json >> endpoints;
    return endpoints;
}
