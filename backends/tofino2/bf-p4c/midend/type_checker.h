#ifndef BF_P4C_MIDEND_TYPE_CHECKER_H_
#define BF_P4C_MIDEND_TYPE_CHECKER_H_

#include "ir/ir.h"
#include "ir/pass_manager.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
namespace BFN {

/**
 * \ingroup midend
 * \brief Extended type inference pass from p4c used in barefoot's midend.
 * @sa P4::TypeInference
 */
class TypeInference : public P4::TypeInference {
    P4::TypeMap *typeMap;

 public:
    TypeInference(P4::TypeMap* typeMap,
                  bool readOnly = false) :
            P4::TypeInference(typeMap, readOnly),
            typeMap(typeMap) { }
/*
    const P4::IR::Node* postorder(P4::IR::BFN::ReinterpretCast*) override;
    const P4::IR::Node* postorder(P4::IR::BFN::SignExtend*) override;
   */
    const P4::IR::Node* postorder(P4::IR::Member*) override;
    TypeInference* clone() const override;

 protected:
    const P4::IR::Type* setTypeType(const P4::IR::Type* type, bool learn = true) override;
};

/**
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
 * \ingroup midend
 * \brief A modified version of P4::EvaluatorPass that uses BFN::TypeChecking.
 * @sa P4::EvaluatorPass
 * @sa P4::Evaluator
 */
class EvaluatorPass final : public P4::PassManager, public P4::IHasBlock {
    P4::Evaluator* evaluator;

 public:
    P4::IR::ToplevelBlock* getToplevelBlock() const override { return evaluator->getToplevelBlock(); }
    EvaluatorPass(P4::ReferenceMap* refMap, P4::TypeMap* typeMap);
};

}  // namespace BFN

#endif  /* BF_P4C_MIDEND_TYPE_CHECKER_H_ */
