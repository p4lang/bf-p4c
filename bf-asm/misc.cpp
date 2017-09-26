#include "misc.h"
#include <sstream>

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

std::string int_to_hex_string(unsigned val, unsigned width) {
    std::stringstream sval;
    sval << std::setfill('0') << std::setw(width) << std::hex << val;
    return sval.str();
}

void add_cfg_reg(json::vector &cfg_cache, std::string full_name,
        std::string name, std::string val) {
   json::map cfg_cache_reg;
   cfg_cache_reg["fully_qualified_name"] = full_name;
   cfg_cache_reg["name"] = name;
   cfg_cache_reg["value"] = val;
   cfg_cache.push_back(std::move(cfg_cache_reg));
}

bool check_zero_string(const std::string& s) {
    char zero = '0';
    return s.find_first_not_of(zero) == std::string::npos; 
}

std::string get_filename(const char* s) {
    std::string fname = s;
    fname = fname.substr(fname.find_last_of("/") + 1);
    fname = fname.substr(0,fname.find_last_of("."));
    return fname;
}

/* Remove augmented names - These dont exist in user program and serve to say 
 * something special about a name to the assembler. The right way to handle this 
 * is to attach attributes to names. We should do that if this list gets longer
 */
bool remove_aug_names(std::string  &name) {
    std::string dollarValid = ".$valid";
    std::size_t found = name.find(dollarValid);
    if (found != std::string::npos) {
        name.erase(found, dollarValid.length());
        return true;
    }
    return false;
}
