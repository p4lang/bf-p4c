#ifndef BF_P4C_MIDEND_INLINE_SUBPARSER_H_
#define BF_P4C_MIDEND_INLINE_SUBPARSER_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"

struct InlineSubparserParameter : public PassManager {
    explicit InlineSubparserParameter(P4::ReferenceMap *refMap);
};

#endif /* BF_P4C_MIDEND_INLINE_SUBPARSER_H_ */
