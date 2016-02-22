#ifndef _TOFINO_COMMON_EXTRACT_MAUPIPE_H_
#define _TOFINO_COMMON_EXTRACT_MAUPIPE_H_

#include "ir/ir.h"

const IR::Tofino::Pipe *extract_maupipe(const IR::Global *);
const IR::Tofino::Pipe *extract_maupipe(const IR::P4V12Program *);

#endif /* _TOFINO_COMMON_EXTRACT_MAUPIPE_H_ */
