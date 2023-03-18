#ifndef BF_ASM_ERROR_MODE_H_
#define BF_ASM_ERROR_MODE_H_

#include "sections.h"

class Stage;

class ErrorMode {
 public:
    typedef enum { NO_CONFIG = 0, PROPAGATE, MAP_TO_IMMEDIATE, DISABLE_ALL_TABLES,
                   PROPAGATE_AND_MAP, PROPAGATE_AND_DISABLE } mode_t;
    typedef enum { TCAM_MATCH, TIND_ECC, GFM_PARITY, EMM_ECC, PREV_ERROR,
                   ACTIONDATA_ERROR, IMEM_PARITY_ERROR, NUM_TYPE_T,
                   LATE_ERROR = ACTIONDATA_ERROR,  // this (and after) is limited
                 } type_t;

    mode_t mode[NUM_TYPE_T] = { NO_CONFIG };
    mode_t &operator[](type_t t) { return mode[t]; }
    static mode_t str2mode(const value_t &);
    static const char *mode2str(mode_t m);
    static type_t str2type(const value_t &);
    static const char *type2str(type_t t);

    void input(value_t data);
    template<class REGS> void write_regs(REGS &, const Stage *, gress_t);
};

class DefaultErrorMode : public Section, public ErrorMode {
    DefaultErrorMode() : Section("error_mode") {
        // This code sets the default error mode when the assembler is used with an older
        // compiler.  Current compiler should always set or override this in the .bfa file
        for (auto &m : mode) m = PROPAGATE_AND_DISABLE; }
    static DefaultErrorMode singleton;
 public:
    void input(VECTOR(value_t) args, value_t data) override { ErrorMode::input(data); }
    void output(json::map &) override {}
    static ErrorMode get() { return singleton; }
};

#endif  /* BF_ASM_ERROR_MODE_H_ */
