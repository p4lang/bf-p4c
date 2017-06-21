#ifndef _TOFINO_COMMON_EXTRACT_MAUPIPE_H_
#define _TOFINO_COMMON_EXTRACT_MAUPIPE_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"

class Tofino_Options;

const IR::Tofino::Pipe *extract_maupipe(const IR::P4Program *, Tofino_Options &);
const IR::Tofino::Pipe *extract_v1model_arch(P4::ReferenceMap* refMap, P4::TypeMap* type,
                                             const IR::PackageBlock* top);
const IR::Tofino::Pipe *extract_native_arch(P4::ReferenceMap* refMap, P4::TypeMap* type,
                                            const IR::PackageBlock* top);

#endif /* _TOFINO_COMMON_EXTRACT_MAUPIPE_H_ */
