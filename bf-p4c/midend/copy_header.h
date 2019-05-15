#ifndef EXTENSIONS_BF_P4C_MIDEND_COPY_HEADER_H_
#define EXTENSIONS_BF_P4C_MIDEND_COPY_HEADER_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeChecking/typeChecker.h"

namespace BFN {

/**
 * This class converts header assignment into assignment of individual
 * fields of the header and the validity bits. The purpose is to enable
 * local copy prop on the header fields which was not possible until
 * backend.
 *
 * The validity bits are represented with a special '$valid' name.
 */
class DoCopyHeaders : public Transform {
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;

 public:
    explicit DoCopyHeaders(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) :
            refMap(refMap), typeMap(typeMap)
    { CHECK_NULL(refMap); CHECK_NULL(typeMap); setName("DoCopyHeaders"); }
    const IR::Node* postorder(IR::AssignmentStatement* statement) override;
    const IR::Node* postorder(IR::MethodCallStatement* mc) override;
};

class CopyHeaders : public PassRepeated {
 public:
    CopyHeaders(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                P4::TypeChecking* typeChecking = nullptr) :
            PassManager({}) {
        CHECK_NULL(refMap); CHECK_NULL(typeMap); setName("CopyHeaders");
        passes.emplace_back(typeChecking);
        passes.emplace_back(new DoCopyHeaders(refMap, typeMap));
    }
};

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_MIDEND_COPY_HEADER_H_ */
