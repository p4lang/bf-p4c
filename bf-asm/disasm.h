#ifndef DISASM_H_
#define DISASM_H_

#include "target.h"

class Disasm {
 public:
    FOR_ALL_TARGETS(DECLARE_TARGET_CLASS)
    virtual void input_binary(uint64_t addr, char tag, uint32_t *data, size_t len) = 0;
    static Disasm *create(std::string target);
};

#define DECLARE_DISASM_TARGET(TARGET, ...)      \
class Disasm::TARGET : public Disasm {          \
 public:                                        \
    typedef ::Target::TARGET      Target;       \
    Target::top_level_regs regs;                \
    TARGET() { declare_registers(&regs); }      \
    ~TARGET() { undeclare_registers(&regs); }   \
    TARGET(const TARGET &) = delete;            \
    __VA_ARGS__                                 \
};

FOR_ALL_TARGETS(DECLARE_DISASM_TARGET,
    void input_binary(uint64_t addr, char tag, uint32_t *data, size_t len) {
        if (tag == 'D') {
            regs.mem_top.input_binary(addr, tag, data, len);
        } else {
            regs.reg_top.input_binary(addr, tag, data, len);
        }
    }
)

#endif  /* DISASM_H_ */
