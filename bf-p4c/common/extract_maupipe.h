#ifndef _TOFINO_COMMON_EXTRACT_MAUPIPE_H_
#define _TOFINO_COMMON_EXTRACT_MAUPIPE_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"

class Tofino_Options;

const IR::Tofino::Pipe *extract_maupipe(const IR::V1Program *, Tofino_Options &);
const IR::Tofino::Pipe *extract_maupipe(const IR::P4Program *, Tofino_Options &);

#endif /* _TOFINO_COMMON_EXTRACT_MAUPIPE_H_ */
