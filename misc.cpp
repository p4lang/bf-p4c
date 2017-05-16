#include "misc.h"

int remove_name_tail_range(std::string &name, int *size) {
    auto tail = name.rfind('.');
    if (tail == std::string::npos) return 0;
    int lo, hi, len = -1;
    if (sscanf(&name[tail], ".%u-%u%n", &lo, &hi, &len) >= 2 &&
        tail + len == name.size() && hi > lo) {
        name.erase(tail);
        if (size)
            *size = hi - lo + 1;
        return lo; }
    return 0;
}
