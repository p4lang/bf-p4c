#ifndef EXTENSIONS_BF_P4C_MIDEND_COPY_HEADER_H_
#define EXTENSIONS_BF_P4C_MIDEND_COPY_HEADER_H_

#include "ir/ir.h"
#include "frontends/p4/typeChecking/typeChecker.h"

// Whilst the original PR consolidated code, moving it out of the back-end and
// canonicalising the IR sooner, it caused ripples that caused issue to the PHV allocator.
// JIRA-DOC: See P4C-3379 & P4C-3158 for the regression is causes.
// For now, we only partially implement the PR by setting `ENABLE_P4C3251 0`.
#define ENABLE_P4C3251 0

namespace BFN {

class CopyHeaders : public PassRepeated {
 public:
    CopyHeaders(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                P4::TypeChecking* typeChecking);
};

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_MIDEND_COPY_HEADER_H_ */
