#include "bf-p4c/midend/eliminate_tuples.h"

namespace BFN {

bool SaveHashListExpression::preorder(const IR::HashListExpression *hle) {
    auto *mce = findContext<IR::MethodCallExpression>();
    if (mce == nullptr)
        return true;
    // Method stays the same after TupleReplacement
    update_hashes[mce->method] = hle;
    return true;
}

const IR::Node* InsertHashStructExpression::preorder(IR::StructExpression *se) {
    auto *mce = findContext<IR::MethodCallExpression>();
    if (mce == nullptr)
        return se;
    if (!update_hashes->count(mce->method))
        return se;
    auto hle = (*update_hashes)[mce->method];
    auto hse = new IR::HashStructExpression(se->srcInfo,
                                            se->type,
                                            se->structType,
                                            se->components,
                                            hle->fieldListCalcName,
                                            hle->outputWidth);
    hse->fieldListNames = hle->fieldListNames;
    hse->algorithms = hle->algorithms;
    return hse;
}

}  // namespace BFN
