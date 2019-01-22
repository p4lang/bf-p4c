#ifndef BF_P4C_MIDEND_ELIM_EMIT_HEADERS_H_
#define BF_P4C_MIDEND_ELIM_EMIT_HEADERS_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/typeChecking/typeChecker.h"

class DoEliminateEmitHeaders : public Transform {
 public:
    DoEliminateEmitHeaders(P4::ReferenceMap* refMap, P4::TypeMap* typeMap);

    const IR::Node* preorder(IR::Argument *arg) override;

    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

class EliminateEmitHeaders : public PassManager {
 public:
    EliminateEmitHeaders(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
        passes.push_back(new P4::TypeChecking(refMap, typeMap, true));
        passes.push_back(new DoEliminateEmitHeaders(refMap, typeMap));
    }
};

#endif /* BF_P4C_MIDEND_ELIM_EMIT_HEADERS_H_ */
