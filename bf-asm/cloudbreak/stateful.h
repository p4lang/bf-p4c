#ifndef BF_ASM_CLOUDBREAK_STATEFUL_H_
#define BF_ASM_CLOUDBREAK_STATEFUL_H_

#include <tables.h>
#include <target.h>

#if HAVE_CLOUDBREAK

#include "jbay/stateful.h"

template<> void StatefulTable::write_logging_regs(Target::Cloudbreak::mau_regs &regs);

#endif  /* HAVE_CLOUDBREAK */
#endif  /* BF_ASM_CLOUDBREAK_STATEFUL_H_ */
