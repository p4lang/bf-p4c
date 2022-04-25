#ifndef BF_ASM_MISC_H_
#define BF_ASM_MISC_H_

#include <vector>
#include <string>
#include <iomanip>
#include <memory>
#include <limits>

#include "json.h"
#include "asm-types.h"

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

template<class T, class Alloc>
void append(std::vector<T, Alloc> &a, const std::vector<T, Alloc> &b) {
    for (auto &e : b) a.push_back(e); }

template<class T, class U>
T join(const std::vector<T> &vec, U sep) {
    T rv;
    bool first = true;
    for (auto &el : vec) {
        if (first)
            first = false;
        else
            rv += sep;
        rv += el; }
    return rv; }

extern int remove_name_tail_range(std::string &, int *size = nullptr);

// Convert an integer to hex string of specified width (in bytes)
std::string int_to_hex_string(unsigned val, unsigned width);

// Add a reg to CJSON Configuration Cache
void add_cfg_reg(json::vector &cfg_cache, std::string full_name,
        std::string name, std::string val);

bool check_zero_string(const std::string& s);

// Get filename
std::string get_filename(const char *s);
std::string get_directory(const char *s);

/** Given a p4 name, eg. "inst.field", write "inst" to @instname and "field" to
 * @fieldname.  If @fullname cannot be split, writes @fullname to @instname and
 * "" to @fieldname.
 */
void gen_instfield_name(
        const std::string &fullname,
        std::string &instname,
        std::string &fieldname);

/// Compare pointers based on the pointed at type
/// For use as a Comparator for map/set types
template<class T> struct ptrless {
    bool operator()(const T *a, const T *b) const
        { return b ? a ? *a < *b : true : false; }
    bool operator()(const std::unique_ptr<T> &a, const std::unique_ptr<T> &b) const
        { return b ? a ? *a < *b : true : false; }
};

uint64_t bitMask(unsigned size);

int parity(uint32_t v);
int parity_2b(uint32_t v);  // two-bit parity (parity of pairs in the word)

inline void check_value(const value_t value, const decltype(value_t::i) expected) {
    CHECKTYPE(value, tINT);
    if (value.i != expected)
        error(value.lineno, "unexpected value %ld; expected %ld", value.i, expected);
}

inline void check_range(const value_t value,
        const decltype(value_t::i) lo, const decltype(value_t::i) hi) {
    CHECKTYPE(value, tINT);
    if (value.i < lo || value.i > hi)
        error(value.lineno, "value %ld out of allowed range <%ld; %ld>", value.i, lo, hi);
}

inline void check_range_match(const value_t &match,
        const decltype(match_t::word0) mask, int width) {
    CHECKTYPE(match, tMATCH);
    if ((match.m.word0 | match.m.word1) != mask)
        error(match.lineno, "invalid match width; expected %i bits", width);
}

inline void convert_i2m(const decltype(value_t::i) i, match_t &m) {
    m.word0 = ~i;
    m.word1 =  i;
}

/// * is parsed as match_t::word0 == 0 && match_t::word1 == 0.
/// The function converts the match according to the specified with @p mask.
inline void fix_match_star(match_t &match, const decltype(match_t::word0) mask) {
    if (match.word0 == 0 && match.word1 == 0)
        match.word0 = match.word1 = mask;
}

/// The function reads a tINT or tMATCH value, performs range checks, and converts
/// the value to a new tMATCH value.
/// @param value Input value
/// @param match Output value
/// @param width Expected width of the input value used for range checks
/// @pre @p value must be a tINT or tMATCH value.
void input_int_match(const value_t value, match_t &match, int width);

#endif /* BF_ASM_MISC_H_ */
