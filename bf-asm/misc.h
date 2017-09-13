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

#include "checked_array.h"
#include "ubits.h"

void set_power_ctl_reg(checked_array<2, checked_array<16, ubits<8>>> &power_ctl, int reg);

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
#endif /* _misc_h_ */
