#ifndef EXTENSIONS_BF_P4C_MIDEND_COPY_HEADER_H_
#define EXTENSIONS_BF_P4C_MIDEND_COPY_HEADER_H_

#include "ir/ir.h"
#include "frontends/p4/typeChecking/typeChecker.h"

namespace BFN {

class CopyHeaders : public PassRepeated {
 public:
    CopyHeaders(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                P4::TypeChecking* typeChecking);
};

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_MIDEND_COPY_HEADER_H_ */
