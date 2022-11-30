#ifndef BF_ASM_JBAY_STATEFUL_H_
#define BF_ASM_JBAY_STATEFUL_H_

#include <tables.h>
#include <target.h>

#if HAVE_JBAY || HAVE_CLOUDBREAK || HAVE_FLATROCK

// FIXME -- should be a namespace somwhere?  Or in class StatefulTable
/* for jbay counter mode, we may need both a push and a pop mode, as well as counter_function,
 * so we pack them all into an int with some shifts and masks */
enum {
    PUSHPOP_BITS = 5,
    PUSHPOP_MASK = 0xf,
    PUSHPOP_ANY = 0x10,
    PUSH_MASK = PUSHPOP_MASK,
    PUSH_ANY = PUSHPOP_ANY,
    POP_MASK = PUSHPOP_MASK << PUSHPOP_BITS,
    POP_ANY = PUSHPOP_ANY << PUSHPOP_BITS,
    PUSH_MISS = 1,
    PUSH_HIT = 2,
    PUSH_GATEWAY = 3,
    PUSH_ALL = 4,
    PUSH_GW_ENTRY = 5,
    POP_MISS = PUSH_MISS << PUSHPOP_BITS,
    POP_HIT = PUSH_HIT << PUSHPOP_BITS,
    POP_GATEWAY = PUSH_GATEWAY << PUSHPOP_BITS,
    POP_ALL = PUSH_ALL << PUSHPOP_BITS,
    POP_GW_ENTRY = PUSH_GW_ENTRY << PUSHPOP_BITS,
    FUNCTION_SHIFT = 2 * PUSHPOP_BITS,
    FUNCTION_LOG = 1 << FUNCTION_SHIFT,
    FUNCTION_FIFO = 2 << FUNCTION_SHIFT,
    FUNCTION_STACK = 3 << FUNCTION_SHIFT,
    FUNCTION_FAST_CLEAR = 4 << FUNCTION_SHIFT,
    FUNCTION_MASK = 0xf << FUNCTION_SHIFT,
};

int parse_jbay_counter_mode(const value_t &v);
template<> void StatefulTable::write_logging_regs(Target::JBay::mau_regs &regs);

#endif  /* HAVE_JBAY || HAVE_CLOUDBREAK || HAVE_FLATROCK */
#endif  /* BF_ASM_JBAY_STATEFUL_H_ */
