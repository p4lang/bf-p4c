#include "gen/tofino/memories.pipe_top_level.h"
#include "gen/tofino/memories.pipe_addrmap.h"
#include "gen/tofino/regs.tofino.h"
#include "gen/tofino/regs.pipe_addrmap.h"
#include "gen/jbay/memories.jbay_mem.h"
#include "gen/jbay/memories.pipe_addrmap.h"
#include "gen/jbay/regs.jbay_reg.h"
#include "gen/jbay/regs.pipe_addrmap.h"
#include "json.h"

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
