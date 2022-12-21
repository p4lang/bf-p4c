#include "common.h"
#include "parde.h"

void report_invalid_directive(const char *message, value_t key) {
    std::string key_name(": ");
    if (key.type == tSTR) {
        key_name += key.s;
    } else if (key.type == tCMD && key.vec.size > 0 && key[0].type == tSTR) {
        key_name += key[0].s;
    } else {
        key_name = "";
    }
    error(key.lineno, "%s%s", message, key_name.c_str());
}
