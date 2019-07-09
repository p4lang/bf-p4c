#ifndef _misc_h_
#define _misc_h_

template<class T>
auto setup_muxctl(T &reg, int val) -> decltype((void)reg.enabled_2bit_muxctl_enable) {
    reg.enabled_2bit_muxctl_select = val;
    reg.enabled_2bit_muxctl_enable = 1; }
template<class T>
auto setup_muxctl(T &reg, int val) -> decltype((void)reg.enabled_3bit_muxctl_enable) {
    reg.enabled_3bit_muxctl_select = val;
    reg.enabled_3bit_muxctl_enable = 1; }
template<class T>
auto setup_muxctl(T &reg, int val) -> decltype((void)reg.enabled_4bit_muxctl_enable) {
    reg.enabled_4bit_muxctl_select = val;
    reg.enabled_4bit_muxctl_enable = 1; }
template<class T>
auto setup_muxctl(T &reg, int val) -> decltype((void)reg.enabled_5bit_muxctl_enable) {
    reg.enabled_5bit_muxctl_select = val;
    reg.enabled_5bit_muxctl_enable = 1; }
template<class T>
auto setup_muxctl(T &reg, int val) -> decltype((void)reg.exactmatch_row_vh_xbar_enable) {
    reg.exactmatch_row_vh_xbar_select = val;
    reg.exactmatch_row_vh_xbar_enable = 1; }

#include <vector>

template<class T, class Alloc>
void append(std::vector<T, Alloc> &a, const std::vector<T, Alloc> &b) {
    for (auto &e : b) a.push_back(e); }

template<class T, class U>
T join(const std::vector<T> &vec, U sep) {
    T rv;
    bool first = true;
    for (auto &el : vec) {
        if (first) first = false; else rv += sep;
        rv += el; }
    return rv; }

#include <string>

extern int remove_name_tail_range(std::string &, int *size = nullptr);

#include <iomanip>

// Convert an integer to hex string of specified width (in bytes)
std::string int_to_hex_string(unsigned val, unsigned width);

// Add a reg to CJSON Configuration Cache
#include "json.h"
void add_cfg_reg(json::vector &cfg_cache, std::string full_name,
        std::string name, std::string val);

bool check_zero_string(const std::string& s);

// Get filename
std::string get_filename(const char *s);

/** Given a p4 name, eg. "inst.field", write "inst" to @instname and "field" to
 * @fieldname.  If @fullname cannot be split, writes @fullname to @instname and
 * "" to @fieldname.
 */
void gen_instfield_name(
        const std::string &fullname,
        std::string &instname,
        std::string &fieldname);

#include <memory>
/// Compare pointers based on the pointed at type
/// For use as a Comparator for map/set types
template<class T> struct ptrless {
    bool operator()(const T *a, const T *b) const
        { return b ? a ? *a < *b : true : false; }
    bool operator()(const std::unique_ptr<T> &a, const std::unique_ptr<T> &b) const
        { return b ? a ? *a < *b : true : false; }
};

#endif /* _misc_h_ */
