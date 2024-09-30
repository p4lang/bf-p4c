#ifndef EXTENSIONS_BF_P4C_COMMON_SIZE_OF_H_
#define EXTENSIONS_BF_P4C_COMMON_SIZE_OF_H_

#include "ir/ir.h"
#include "frontends/p4/strengthReduction.h"

namespace BFN {

class CloneConstants : public Transform {
 public:
    CloneConstants() = default;
    const P4::IR::Node* postorder(P4::IR::Constant* constant) override {
        // We clone the constant.  This is necessary because the same
        // the type associated with the constant may participate in
        // type unification, and thus we want to have different type
        // objects for different constant instances.
        const P4::IR::Type* type = constant->type;
        if (type->is<P4::IR::Type_Bits>()) {
            type = constant->type->clone();
        } else if (auto ii = type->to<P4::IR::Type_InfInt>()) {
            // You can't just clone a InfInt value, because
            // you get the same declid.  We want a new declid.
            type = P4::IR::Type_InfInt::get(ii->srcInfo);
        } else {
            BUG("unexpected type %2% for constant %2%", type, constant);
        }
        return new P4::IR::Constant(constant->srcInfo, type, constant->value, constant->base);
    }
    static const P4::IR::Expression* clone(const P4::IR::Expression* expression) {
        return expression->apply(CloneConstants())->to<P4::IR::Expression>();
    }
};

/**
 * This class resolves the value of sizeInBytes and sizeInBits externs into a
 * constant.
 */
class ConvertSizeOfToConstant : public Transform {
 public:
    ConvertSizeOfToConstant() { }
    const P4::IR::Node *preorder(P4::IR::MAU::TypedPrimitive* p) override;
    const P4::IR::Node *preorder(P4::IR::MethodCallExpression* mce) override;
};

/**
 * We cannot reuse the frontend constant folding pass because the frontend pass
 * uses typeMap and refMap which are not available in backend.
 */
class BackendConstantFolding : public Transform {
 public:
    const P4::IR::Expression* getConstant(const P4::IR::Expression* expr) const;
    const P4::IR::Node* postorder(P4::IR::Slice* e) override;
};

class BackendStrengthReduction : public Transform {
    const P4::IR::Node* sub(P4::IR::MAU::Instruction* inst);
    const P4::IR::Node* preorder(P4::IR::MAU::SaluInstruction* inst) override;
    const P4::IR::Node* preorder(P4::IR::MAU::Instruction* inst) override;
};

class ResolveSizeOfOperator : public PassManager {
 public:
    ResolveSizeOfOperator() {
        addPasses({
            new ConvertSizeOfToConstant(),
            new BackendConstantFolding(),
            new BackendStrengthReduction()
        });
    }
};

}  // namespace BFN

#endif  /* EXTENSIONS_BF_P4C_COMMON_SIZE_OF_H_ */
