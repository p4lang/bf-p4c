#ifndef BF_ASM_CLOUDBREAK_GATEWAY_H_
#define BF_ASM_CLOUDBREAK_GATEWAY_H_

#include <tables.h>
#include <tofino/gateway.h>

#if HAVE_CLOUDBREAK
template<> void GatewayTable::standalone_write_regs(Target::Cloudbreak::mau_regs &regs);
#endif /* HAVE_CLOUDBREAK */

#endif /* BF_ASM_CLOUDBREAK_GATEWAY_H_ */
