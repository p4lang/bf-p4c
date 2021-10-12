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

/**
 * \ingroup stateful_alu
 * \brief The pass replaces the Register.read/write() calls with register actions.
 *
 *  The pass must be invoked prefereably towards the end of mid-end to account for
 *  any mid-end optimizations like constant folding, propogation, etc.
 */
class RegisterReadWrite : public PassManager {
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

    RegisterCallsByAction action_register_calls;
    RegisterExecuteCallByAction action_register_exec_calls;
    RegisterActionsByControl control_register_actions;

    /**
     * \ingroup stateful_alu
     * \brief Using maps built in BFN::RegisterReadWrite::CollectRegisterReadsWrites
     * and BFN::RegisterReadWrite::AnalyzeActionWithRegisterCalls passes, it adds newly
     * created register actions to the IR and replaces Register.read/write() calls with
     * RegisterAction.execute() calls.
     */
    class UpdateRegisterActionsAndExecuteCalls: public Transform {
        RegisterReadWrite &self;
        std::map<const IR::P4Control*, IR::Declaration_Instance*> register_actions;
        IR::Node *preorder(IR::P4Action*) override;
        IR::Node *postorder(IR::P4Control* ctrl) override;

     public:
        explicit UpdateRegisterActionsAndExecuteCalls(RegisterReadWrite &self) :
             self(self) {}
    };

    /**
     * \ingroup stateful_alu
     * \brief Using the map built in the BFN::RegisterReadWrite::CollectRegisterReadsWrites
     * pass, this pass prepares corresponding register actions and Register.execute() calls.
     *
     * The pass builds two maps:
     * 1. BFN::RegisterReadWrite::control_register_actions, which contains info about
     *    which newly created register actions will be placed in which control block.
     * 2. BFN::RegisterReadWrite::action_register_exec_calls, which contains info about
     *    which newly created RegisterAction.execute() calls will be placed in which
     *    actions.
     */
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

    /**
     * \ingroup stateful_alu
     * \brief The pass builds the BFN::RegisterReadWrite::action_register_calls map that
     * contains info about which action contains which statements with Register.read/write()
     * calls.
     */
    class CollectRegisterReadsWrites : public Inspector {
        RegisterReadWrite &self;
        bool preorder(const IR::MethodCallExpression*) override;

     public:
        explicit CollectRegisterReadsWrites(RegisterReadWrite &self) :
             self(self) {}
    };

    /**
     * \ingroup stateful_alu
     * \brief An auxiliary pass that moves declarations of register parameters
     * to the very beginning of corresponding control block.
     *
     * If not done, the following passes would place register actions
     * (which might use the register parameters) in front of the declarations
     * of the register parameters, which would cause missing Declaration_Instance error.
     *
     * @pre This sub-pass needs to be run before all other sub-passes
     * of the BFN::RegisterReadWrite pass.
     */
    class MoveRegisterParameters : public Modifier {
        RegisterReadWrite &self;
        bool preorder(IR::P4Control *c) override;

     public:
        explicit MoveRegisterParameters(RegisterReadWrite &self) :
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
            new MoveRegisterParameters(*this),
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
