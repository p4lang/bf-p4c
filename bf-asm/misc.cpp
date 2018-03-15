#include "misc.h"
#include <regex>
#include <sstream>
#include <string>

int remove_name_tail_range(std::string &name, int *size) {
    auto tail = name.rfind('.');
    if (tail == std::string::npos) return 0;
    int lo, hi, len = -1;
    if (sscanf(&name[tail], ".%u-%u%n", &lo, &hi, &len) >= 2 &&
        tail + len == name.size() && hi >= lo) {
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

/* Convert assembler stack field names back to their original P4 name.
 * In P4, fields on header stacks have names like "mpls[2].label".
 * For assembly output, this name is converted to "mpls$2.label".
 * This function is used to go back to the original P4 name, which
 * is the desired value to be output in context.json.
 */
void stack_asm_name_to_p4(std::string& name) {
  std::regex e ("\\$[0-9]+\\.");  //looks for $ followed by number followed by .
  std::smatch m;
  while (std::regex_search (name, m, e)) {
    for (auto x:m) {
      std::size_t found = name.find(x);
      std::string digits(x);
      name.replace(found, x.length(), "");  // delete $, number, .
      std::size_t len = digits.length();
      if (len > 1) {  // figure out stack index
        digits.replace(len - 1, 1, "");  //remove trailing .
        digits.replace(0, 1, "");  //remove $
      }
      std::string new_str = "[";
      new_str.append(digits);
      new_str.append("].");
      name.insert(found, new_str);
    }
  }
}

/* Given a p4 name, split into instance and field names if possible
 *  - else return a copy of the original name */
bool gen_instfield_name(const std::string &fullname, std::string &instname,
                         std::string &field_name) {
    auto dotpos = fullname.rfind('.');
    if (dotpos == std::string::npos) {
        instname = fullname;
        field_name = std::string();
    } else {
        instname = fullname.substr(0, dotpos);
        field_name = fullname.substr(dotpos+1, fullname.size());
    }
    return true;
}
