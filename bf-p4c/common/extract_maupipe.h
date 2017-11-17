#ifndef BF_P4C_COMMON_EXTRACT_MAUPIPE_H_
#define BF_P4C_COMMON_EXTRACT_MAUPIPE_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"

class BFN_Options;

const IR::BFN::Pipe *extract_maupipe(const IR::P4Program *, bool useTna);
const IR::BFN::Pipe *extract_native_arch(P4::ReferenceMap* refMap, P4::TypeMap* type,
                                         const IR::PackageBlock* top, bool useTna);

#endif /* BF_P4C_COMMON_EXTRACT_MAUPIPE_H_ */
