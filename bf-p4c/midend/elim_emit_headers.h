#ifndef BF_P4C_MIDEND_ELIM_EMIT_HEADERS_H_
#define BF_P4C_MIDEND_ELIM_EMIT_HEADERS_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"

class EliminateEmitHeaders : public Transform {
 public:
    EliminateEmitHeaders(P4::ReferenceMap* refMap, P4::TypeMap* typeMap);

    const IR::Node* preorder(IR::Argument *arg) override;

    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

#endif /* BF_P4C_MIDEND_ELIM_EMIT_HEADERS_H_ */
