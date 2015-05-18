#include "gen/memories.pipe_top_level.h"
#include "gen/memories.pipe_addrmap.h"
#include "gen/regs.tofino.h"
#include "gen/regs.pipe_addrmap.h"

class TopLevel {
public:
    memories_top        mem_top;
    memories_pipe       mem_pipe;
    regs_top            reg_top;
    regs_pipe           reg_pipe;
private:
    TopLevel();
    ~TopLevel();
public:
    static TopLevel     all;
    void output();
    static void output_all() { all.output(); }
};
