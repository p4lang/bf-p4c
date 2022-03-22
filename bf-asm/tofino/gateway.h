#ifndef BF_ASM_TOFINO_GATEWAY_H_
#define BF_ASM_TOFINO_GATEWAY_H_

#include <tables.h>

template<class REGS> void enable_gateway_payload_exact_shift_ovr(REGS &regs, int bus);
template<> void enable_gateway_payload_exact_shift_ovr(Target::Tofino::mau_regs &regs, int bus);
template<> void GatewayTable::write_next_table_regs(Target::Tofino::mau_regs &regs);

#endif /* BF_ASM_TOFINO_GATEWAY_H_ */
