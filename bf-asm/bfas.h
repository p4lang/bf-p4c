#ifndef _bfas_h_
#define _bfas_h_

enum config_version_t { CONFIG_OLD=1, CONFIG_NEW=2, CONFIG_BOTH=3 };
enum target_t { TOFINO=1, JBAY=2, TARGET_INDEX_LIMIT };
extern struct option_t {
    config_version_t    version;
    target_t            target;
    bool                match_compiler;
    bool                condense_json;
    bool                new_ctx_json;
    bool                debug_info;
    bool                werror;
} options;

extern unsigned unique_action_handle;

#include <string>
extern std::string asmfile_name;

#include "stdarg.h"
#include "stdio.h"
#include <iostream>
#include <memory>

int asm_parse_file(const char *name, FILE *in);

extern int error_count, warn_count;
extern void error(int lineno, const char *fmt, va_list);
void error(int lineno, const char *fmt, ...) __attribute__((format(printf, 2, 3)));
inline void error(int lineno, const char *fmt, ...) {
    va_list     args;
    va_start(args, fmt);
    error(lineno, fmt, args);
    va_end(args); }
extern void warning(int lineno, const char *fmt, va_list);
void warning(int lineno, const char *fmt, ...) __attribute__((format(printf, 2, 3)));
inline void warning(int lineno, const char *fmt, ...) {
    va_list     args;
    va_start(args, fmt);
    warning(lineno, fmt, args);
    va_end(args); }

extern std::unique_ptr<std::ostream> open_output(const char *, ...) __attribute__((format(printf, 1, 2)));

class VersionIter {
    unsigned    left, bit;
    void check() { while (left && !(left & 1)) { ++bit; left >>= 1; } }
    VersionIter() : left(0), bit(0) {}
public:
    VersionIter(config_version_t v) : left(v), bit(0) { check(); }
    VersionIter begin() { return *this; }
    VersionIter end() { return VersionIter(); }
    int operator*() const { return bit; }
    bool operator==(VersionIter &a) { return (left << bit) == (a.left << a.bit); }
    VersionIter &operator++() { left &= ~1; check(); return *this; }
};

#endif /* _bfas_h_ */
