#ifndef BF_ASM_JBAY_GATEWAY_H_
#define BF_ASM_JBAY_GATEWAY_H_

#include <tables.h>
#include <tofino/gateway.h>

#if HAVE_JBAY
template<> void GatewayTable::standalone_write_regs(Target::JBay::mau_regs &regs);
#endif /* HAVE_JBAY */

#endif /* BF_ASM_JBAY_GATEWAY_H_ */
