#ifndef BF_ASM_JBAY_GATEWAY_H_
#define BF_ASM_JBAY_GATEWAY_H_

#include <tables.h>

#if HAVE_JBAY
template<> void GatewayTable::write_next_table_regs(Target::JBay::mau_regs &regs);
template<> void GatewayTable::standalone_write_regs(Target::JBay::mau_regs &regs);
#endif /* HAVE_JBAY */

#endif /* BF_ASM_JBAY_GATEWAY_H_ */
