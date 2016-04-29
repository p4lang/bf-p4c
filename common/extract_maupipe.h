#ifndef _TOFINO_COMMON_EXTRACT_MAUPIPE_H_
#define _TOFINO_COMMON_EXTRACT_MAUPIPE_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"

const IR::ActionFunction *createActionFunction(const IR::P4Action *ac,
                                               const IR::Vector<IR::Expression> *args);
const IR::V1Table *createV1Table(const IR::P4Table *tc, const P4::ReferenceMap *refMap);

const IR::Tofino::Pipe *extract_maupipe(const IR::V1Program *);
const IR::Tofino::Pipe *extract_maupipe(const IR::P4Program *);

#endif /* _TOFINO_COMMON_EXTRACT_MAUPIPE_H_ */
