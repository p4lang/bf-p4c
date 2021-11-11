#ifndef BF_P4C_MIDEND_TYPE_CHECKER_H_
#define BF_P4C_MIDEND_TYPE_CHECKER_H_

#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/common/resolveReferences/resolveReferences.h"

namespace BFN {

/**
 * \class TypeInference
 * \ingroup midend
 * \brief Extended type inference pass from p4c used in barefoot's midend.
 * @sa P4::TypeInference
 */
class TypeInference : public P4::TypeInference {
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

 public:
    TypeInference(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                  bool readOnly = false) :
            P4::TypeInference(refMap, typeMap, readOnly),
            refMap(refMap), typeMap(typeMap) { }

    const IR::Node* postorder(IR::BFN::ReinterpretCast*) override;
    const IR::Node* postorder(IR::BFN::SignExtend*) override;
    const IR::Node* postorder(IR::Member*) override;
    TypeInference* clone() const override;

 protected:
    const IR::Type* setTypeType(const IR::Type* type, bool learn = true) override;
};

/**
 * \class TypeChecking
 * \ingroup midend
 * \brief A TypeChecking pass in BFN namespace that uses the extended
 *        TypeInference pass. This should be used in our midend.
 * @sa P4::TypeChecking
 */
class TypeChecking : public P4::TypeChecking {
 public:
    TypeChecking(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                 bool updateExpressions = false);
};

/**
 * \class EvaluatorPass
 * \ingroup midend
 * \brief A modified version of P4::EvaluatorPass that uses BFN::TypeChecking.
 * @sa P4::EvaluatorPass
 * @sa P4::Evaluator
 */
class EvaluatorPass final : public PassManager, public P4::IHasBlock {
    P4::Evaluator* evaluator;

 public:
    IR::ToplevelBlock* getToplevelBlock() override { return evaluator->getToplevelBlock(); }
    EvaluatorPass(P4::ReferenceMap* refMap, P4::TypeMap* typeMap, bool doListConv = false);
};

}  // namespace BFN

#endif  /* BF_P4C_MIDEND_TYPE_CHECKER_H_ */
