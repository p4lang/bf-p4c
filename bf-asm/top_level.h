#include "target.h"
#include "json.h"

/* FIXME -- still hard-coded to tofino top-level -- need to use Target top level */

class TopLevel {
public:
    Tofino::memories_top        mem_top;
    Tofino::memories_pipe       mem_pipe;
    Tofino::regs_top            reg_top;
    Tofino::regs_pipe           reg_pipe;
    json::map                   name_lookup;
private:
    TopLevel();
    ~TopLevel();
public:
    static TopLevel     all;
    void output();
    static void output_all() { all.output(); }
};
