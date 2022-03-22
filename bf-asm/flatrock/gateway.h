#ifndef BF_ASM_FLATROCK_GATEWAY_H_
#define BF_ASM_FLATROCK_GATEWAY_H_

#include <tables.h>

#if HAVE_FLATROCK
template<> void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
#endif /* HAVE_FLATROCK */

#endif /* BF_ASM_FLATROCK_GATEWAY_H_ */
