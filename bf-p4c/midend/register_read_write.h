/**
 *  Convert register.read & register.write calls to Register Actions to be
 *  processed later by the midend.
 *
 *  All P4-14 register_read() and register_write() calls are converted to p4-16
 *  register read & write calls when this pass is invoked.
 *
 *  Pass must be invoked prefereably towards the end of midend to account for
 *  any midend optimizations like constant folding/propogation etc.
 */
#ifndef EXTENSIONS_BF_P4C_MIDEND_REGISTER_READ_WRITE_H_
#define EXTENSIONS_BF_P4C_MIDEND_REGISTER_READ_WRITE_H_

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "bf-p4c/midend/type_checker.h"
#include "ir/ir.h"

namespace BFN {

class SearchAndReplaceExpr: public Transform {
    IR::Expression *replace;
    const IR::Expression *search;

    IR::Node *preorder(IR::Expression *expr) {
        if (expr->toString() == search->toString()) return replace;
        return expr;
    }

 public:
    SearchAndReplaceExpr(IR::Expression *replace, const IR::Expression *search) :
        replace(replace), search(search) {}
};

typedef ordered_set<const IR::MethodCallExpression *> RegisterCalls;
typedef std::unordered_map<const IR::P4Action *,
        ordered_set<const IR::Statement*>> RegisterCallsByAction;
typedef std::unordered_map<const IR::P4Action *,
        IR::MethodCallExpression*> RegisterExecuteCallByAction;
typedef std::unordered_map<const IR::P4Control*,
        ordered_set<IR::Declaration_Instance *>> RegisterActionsByControl;


class RegisterReadWrite : public PassManager {
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

    RegisterCallsByAction action_register_calls;
    RegisterExecuteCallByAction action_register_exec_calls;
    RegisterActionsByControl control_register_actions;

    class UpdateRegisterActionsAndExecuteCalls: public Transform {
        RegisterReadWrite &self;
        std::map<const IR::P4Control*, IR::Declaration_Instance*> register_actions;
        IR::Node *preorder(IR::P4Action*) override;
        IR::Node *postorder(IR::P4Control* ctrl) override;

     public:
        explicit UpdateRegisterActionsAndExecuteCalls(RegisterReadWrite &self) :
             self(self) {}
    };

    class AnalyzeActionWithRegisterCalls: public Inspector {
        RegisterReadWrite &self;
        struct RegInfo {
            IR::Declaration_Instance *reg_action = nullptr;
            IR::MethodCallExpression *reg_execute = nullptr;
            const IR::Expression *read_expr = nullptr;
        };
        bool preorder(const IR::P4Action*) override;

        IR::MethodCallExpression*
        createRegisterExecute(IR::MethodCallExpression *reg_execute,
                              const IR::Statement *reg_stmt, const IR::P4Action *act);
        RegInfo
        createRegisterAction(RegInfo reg_info,
                              const IR::Statement *reg_stmt, const IR::P4Action *act);
     public:
        explicit AnalyzeActionWithRegisterCalls(RegisterReadWrite &self) :
             self(self) {}
    };

    class CollectRegisterReadsWrites : public Inspector {
        RegisterReadWrite &self;
        bool preorder(const IR::MethodCallExpression*) override;

     public:
        explicit CollectRegisterReadsWrites(RegisterReadWrite &self) :
             self(self) {}
    };

 public:
    RegisterReadWrite(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
            BFN::TypeChecking* typeChecking = nullptr) :
                refMap(refMap), typeMap(typeMap) {
        if (!typeChecking)
            typeChecking = new BFN::TypeChecking(refMap, typeMap);
        addPasses({
            typeChecking,
            new CollectRegisterReadsWrites(*this),
            new AnalyzeActionWithRegisterCalls(*this),
            new UpdateRegisterActionsAndExecuteCalls(*this),
            new P4::ClearTypeMap(typeMap)
        });
    }

    static
    std::pair<const IR::MethodCallExpression * /*call*/, const IR::Expression * /*read_expr*/>
    checkSupportedReadWriteForm(const IR::Statement *reg_stmt);
};

}  // namespace BFN

#endif  // EXTENSIONS_BF_P4C_MIDEND_REGISTER_READ_WRITE_H_
