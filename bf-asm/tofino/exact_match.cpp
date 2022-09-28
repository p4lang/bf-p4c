#include "exact_match.h"

void Target::Tofino::ExactMatchTable::setup_ways() {
    ::ExactMatchTable::setup_ways();
    for (auto &row : layout) {
        int first_way = -1;
        for (auto &ram : row.memunits) {
            int way = way_map.at(ram).way;
            if (first_way < 0) {
                first_way = way;
            } else if (ways[way].group_xme != ways[first_way].group_xme) {
                error(row.lineno, "Ways %d and %d of table %s share address bus on row %d, "
                      "but use different hash groups", first_way, way, name(), row.row);
                break; } } }
}

