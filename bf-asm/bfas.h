#ifndef _bfas_h_
#define _bfas_h_

#include <string>
#include "stdarg.h"
#include "stdio.h"
#include <iostream>
#include <memory>


enum config_version_t { CONFIG_OLD=1, CONFIG_NEW=2, CONFIG_BOTH=3 };
enum target_t { NO_TARGET=0, TOFINO, TOFINO2, JBAY=TOFINO2, TOFINO2H, TOFINO2U, TOFINO2M,
                TARGET_INDEX_LIMIT };
enum binary_type_t { NO_BINARY,
    FOUR_PIPE,  // binary replicating to all 4 pipes
    ONE_PIPE,   // binary for one pipe with pipe offset addresses
    PIPE0,      // binary with data just in pipe 0
    PIPE1,      // binary with data just in pipe 1
    PIPE2,      // binary with data just in pipe 2
    PIPE3,      // binary with data just in pipe 3
};
extern struct option_t {
    binary_type_t       binary;
    bool                condense_json;
    bool                debug_info;
    bool                disable_egress_latency_padding;
    bool                disable_power_gating;
    bool                gen_json;
    bool                hash_parity_enabled;
    bool                high_availability_enabled;
    bool                match_compiler;
    bool                singlewrite;
    bool                multi_parsers;
    std::string         stage_dependency_pattern;
    target_t            target;
    config_version_t    version;
    bool                werror;
    bool                nowarn;

    bool isJBayTarget();
} options;

extern unsigned unique_action_handle;
struct value_t;

extern std::string asmfile_name;

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
#ifdef BAREFOOT_INTERNAL
    if (!options.nowarn) {
        va_list     args;
        va_start(args, fmt);
        warning(lineno, fmt, args);
        va_end(args);
    }
#endif
}

inline void bug(const char* fname, int lineno) {
#ifdef NDEBUG
    fprintf(stderr, "Assembler BUG");
#else
    fprintf(stderr, "%s:%d: Assembler BUG: ", fname, lineno);
#endif
    fprintf(stderr, "\n");
    fflush(stderr);
    std::terminate(); }

extern std::unique_ptr<std::ostream> open_output(const char *, ...) __attribute__((format(printf, 1, 2)));

#define BUG() do { bug(__FILE__, __LINE__); } while (0)
#define BUG_CHECK(e) do { if (!(e)) BUG(); } while (0)

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

extern unsigned unique_table_offset;

#endif /* _bfas_h_ */
