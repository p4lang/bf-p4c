#ifndef EXTENSIONS_BF_P4C_MIDEND_SIMPLIFY_EMIT_ARGS_H_
#define EXTENSIONS_BF_P4C_MIDEND_SIMPLIFY_EMIT_ARGS_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeMap.h"
#include "midend/flattenHeaders.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/common/rewrite_flexible_struct.h"

namespace BFN {

/**
 * This pass expands the reference to a header in emit function
 * to the list of header fields in the header.
 * It enables the backend copy propagation to eliminate assignment
 * statement in deparser.
 */
class FlattenEmitArgs : public Modifier {
    void postorder(IR::MethodCallExpression* mc) override;
    IR::ListExpression* flatten_args(const IR::ListExpression* args);
    void explode(const IR::Expression*, IR::Vector<IR::Expression>*);
};

class DoEliminateEmitHeaders : public Transform {
 public:
    DoEliminateEmitHeaders(P4::ReferenceMap* refMap, P4::TypeMap* typeMap);

    const IR::Node* preorder(IR::Argument *arg) override;

    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

class SimplifyEmitArgs : public PassManager {
 public:
    SimplifyEmitArgs(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
        passes.push_back(new BFN::TypeChecking(refMap, typeMap, true));
        passes.push_back(new DoEliminateEmitHeaders(refMap, typeMap));
        passes.push_back(new FlattenEmitArgs());
    }
};

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_MIDEND_SIMPLIFY_EMIT_ARGS_H_ */
