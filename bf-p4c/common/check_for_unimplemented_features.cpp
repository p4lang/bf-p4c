#include "bf-p4c/common/check_for_unimplemented_features.h"
#include "lib/error_reporter.h"

boost::optional<const IR::Operation_Binary*>
CheckOperations::getSrcBinop(const IR::MAU::Primitive* prim) const {
    prim = prim->apply(RemoveCasts());
    if (prim->name != "modify_field") return boost::none;
    if (prim->operands.size() < 2) return boost::none;
    if (auto* binop = prim->operands[1]->to<IR::Operation_Binary>())
        return binop;
    return boost::none;
}

bool CheckOperations::isFunnelShift(const IR::MAU::Primitive* prim) const {
    auto* binop = getSrcBinop(prim).get_value_or(nullptr);
    if (!binop) return false;
    bool isShift = binop->getStringOp() == "<<" || binop->getStringOp() == ">>";
    return isShift && binop->left->is<IR::Concat>();
}

bool CheckOperations::isModBitMask(const IR::MAU::Primitive* prim) const {
    auto* binop = getSrcBinop(prim).get_value_or(nullptr);
    if (!binop || binop->getStringOp() != "|") return false;
    auto leftBinop = binop->left->to<IR::Operation_Binary>();
    auto rightBinop = binop->right->to<IR::Operation_Binary>();
    if (!leftBinop || !rightBinop) return false;
    return leftBinop->getStringOp() == "&" && rightBinop->getStringOp() == "&";
}

bool CheckOperations::preorder(const IR::MAU::Primitive* prim) {
    if (isFunnelShift(prim) || isModBitMask(prim))
        ::error("The following operation is not yet supported: %1%", prim->srcInfo);
    return true;
}
