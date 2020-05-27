#include "frontends/p4/methodInstance.h"
#include "register_read_write.h"

namespace BFN {

IR::Node *RegisterReadWrite::UpdateRegisterActionsAndExecuteCalls::preorder(IR::P4Action* act) {
    LOG1(" P4 Action: " << act);

    auto orig_act = getOriginal<IR::P4Action>();
    if (self.action_register_calls.count(orig_act) == 0) return act;

    auto calls = self.action_register_calls[orig_act];
    auto body = new IR::BlockStatement();

    const IR::AssignmentStatement *assign_stmt = nullptr;
    // Remove register read & write calls in action
    int reg_action_index = 0;
    for (auto inst : orig_act->body->components) {
        LOG1(" P4 Action Statement: " << inst);
        if (assign_stmt) break;
        reg_action_index++;
        if (calls.count(inst->to<IR::Statement>()) > 0) {
            if (!assign_stmt)
                assign_stmt = inst->to<IR::AssignmentStatement>();
            continue;
        }
        body->push_back(inst);
    }

    // Add register exec call to action at index
    BUG_CHECK(self.action_register_exec_calls.count(orig_act) > 0,
                " No register execution call generated for register read/write in action %1%"
                , orig_act);
    auto reg_exec_call = self.action_register_exec_calls[orig_act];
    IR::Statement *stmt = nullptr;
    if (assign_stmt)
        stmt = new IR::AssignmentStatement(assign_stmt->left, reg_exec_call);
    else
        stmt = new IR::MethodCallStatement(reg_exec_call);
    body->push_back(stmt);

    // Update action body with remaining non register read/write instructions if
    // any
    auto orig_act_body_itr = orig_act->body->components.begin() + reg_action_index;
    for (; orig_act_body_itr != orig_act->body->components.end(); orig_act_body_itr++) {
        auto inst = *orig_act_body_itr;
        if (calls.count(inst->to<IR::Statement>()) > 0) continue;
        body->push_back(inst);
    }

    auto new_act = new IR::P4Action(act->srcInfo, act->name, act->annotations,
                                    act->parameters, body);
    return new_act;
}

IR::Node *RegisterReadWrite::UpdateRegisterActionsAndExecuteCalls::postorder(IR::P4Control* ctrl) {
    LOG1(" TNA Control: " << ctrl);
    auto orig_ctrl = getOriginal<IR::P4Control>();
    if (self.control_register_actions.count(orig_ctrl) == 0) return ctrl;

    // Add register actions to control block
    auto register_actions = self.control_register_actions[orig_ctrl];
    for (auto register_action : register_actions) {
        int count = 0;
        for (auto local : ctrl->controlLocals) {
            count++;
            auto reg_arg = register_action->arguments->at(0);
            auto reg_name = reg_arg->expression->to<IR::PathExpression>()->path->name;
            if (local->getName() == reg_name)
                break;
        }
        ctrl->controlLocals.insert(ctrl->controlLocals.begin() + count, register_action);
    }
    return ctrl;
}

// REGISTER READ EXAMPLE
// FROM :
//   @name(".accum") register<bit<16>, bit<10>>(32w1024) accum;
//   @name(".addb1") action addb1(bit<9> port, bit<10> idx) {
//      ig_intr_md_for_tm.ucast_egress_port = port;
//      hdr.data.h1 = accum.read(idx);
//   }
//
// TO :
//   @name(".accum") register<bit<16>, bit<10>>(32w1024) accum;
//   @name(".sful") RegisterAction<bit<16>, bit<32>, bit<16>>(accum) sful_0 = {
//       void apply(inout bit<16> value, out bit<16> rv) {
//           bit<16> in_value_0;
//           in_value_0 = value;
//           rv = in_value_0;
//       }
//   }
//   @name(".addb1") action addb1(bit<9> port, bit<10> idx) {
//      ig_intr_md_for_tm.ucast_egress_port = port;
//      hdr.data.h1 = sful.execute(idx);
//   };
//
// REGISTER WRITE EXAMPLE
// FROM :
//   @name(".accum") register<bit<16>, bit<10>>(32w1024) accum;
//   @name(".addb1") action addb1(bit<9> port, bit<10> idx) {
//      ig_intr_md_for_tm.ucast_egress_port = port;
//      accum.write(idx, hdr.data.h1 + 16w1);
//   }
//
// TO :
//   @name(".accum") register<bit<16>, bit<10>>(32w1024) accum;
//   @name(".accum_register_action")
//   RegisterAction<bit<16>, bit<10>, bit<16>>(accum) accum_register_action = {
//       void apply(inout bit<16> value) {
//           value = hdr.data.h1 + 16w1;
//       }
//   };
//   @name(".addb1") action addb1(bit<9> port, bit<10> idx) {
//      ig_intr_md_for_tm.ucast_egress_port = port;
//      accum_register_action.execute(idx);
//   }
IR::MethodCallExpression*
RegisterReadWrite::AnalyzeActionWithRegisterCalls::createRegisterExecute(
                                        IR::MethodCallExpression *reg_execute,
                                        const IR::Statement *reg_stmt,
                                        const IR::P4Action *act) {
    BUG_CHECK(reg_stmt, "No register call statment present to analyze in action - %1%", act);

    const IR::MethodCallExpression *call = nullptr;
    if (auto reg_mcall_stmt = reg_stmt->to<IR::MethodCallStatement>())
        call = reg_mcall_stmt->methodCall;
    else if (auto reg_assign_stmt = reg_stmt->to<IR::AssignmentStatement>())
        call = reg_assign_stmt->right->to<IR::MethodCallExpression>();

    BUG_CHECK(call, "Invalid register call statement, must be an assignment "
                    "or a method call - %1% in action - %2%",
                    reg_stmt, act);

    LOG1(" MethodCallExpression: " << call);

    // Create Register Action - Add to declaration
    auto member = call->method->to<IR::Member>();
    auto reg_path = member->expr->to<IR::PathExpression>()->path;
    auto reg_decl = self.refMap->getDeclaration(reg_path)->to<IR::Declaration_Instance>();

    // Register read/write calls don not have an index argument for direct
    // registers. This is currently unsupported.
    if (call->arguments->size() == 0) {
        P4C_UNIMPLEMENTED("%s: The method call of read and write on a Register "
                "does not currently support for direct registers.  Please use "
                "DirectRegisterAction to describe direct register programming.",
                call);
    }

    bool is_read = (member->member.name == "read");
    bool is_write = (member->member.name == "write");
    int num_call_args = call->arguments->size();
    BUG_CHECK(is_read || is_write,
            " Invalid indirect register call. Only 'read' or 'write' calls are supported, "
            " but %1% specified", member->member.name);
    if (is_read) {
        BUG_CHECK(num_call_args == 1,
                " Invalid indirect register read call. Needs 1 argument for register index "
                " but %1% specified", num_call_args);
    }
    if (is_write) {
        BUG_CHECK(num_call_args == 2,
                " Invalid indirect register write call. Needs 2 arguments for register index "
                " and write expression only %1% specified", num_call_args);
    }

    auto reg_args = reg_decl->type->to<IR::Type_Specialized>()->arguments;
    auto rtype = reg_args->at(0);
    auto utype = call->type->to<IR::Type_Void>() ? rtype : call->type;

    auto apply_name = reg_path->name + "_register_action";

    if (!reg_execute) {
        // Create Execute Method Call Expression
        auto reg_execute_method = new IR::Member(member->type,
                                        new IR::PathExpression(IR::ID(apply_name)), "execute");

        // Use first argument which is the indirect index
        auto reg_execute_args = new IR::Vector<IR::Argument>({ call->arguments->at(0) });
        reg_execute = new IR::MethodCallExpression(utype, reg_execute_method, reg_execute_args);
    }

    return reg_execute;
}

RegisterReadWrite::AnalyzeActionWithRegisterCalls::RegInfo
RegisterReadWrite::AnalyzeActionWithRegisterCalls::createRegisterAction(
                                            RegInfo reg_info,
                                            const IR::Statement *reg_stmt,
                                            const IR::P4Action *act) {
    BUG_CHECK(reg_stmt, "No register call statment present to analyze in action - ", act);

    const IR::MethodCallExpression *call = nullptr;
    if (auto reg_mcall_stmt = reg_stmt->to<IR::MethodCallStatement>()) {
        call = reg_mcall_stmt->methodCall;
    } else if (auto reg_assign_stmt = reg_stmt->to<IR::AssignmentStatement>()) {
        call = reg_assign_stmt->right->to<IR::MethodCallExpression>();
        reg_info.read_expr = reg_assign_stmt->left;
    }

    BUG_CHECK(call, "Invalid register call statement, must be an assignment "
                    "or a method call - %1% in action - %2%",
                    reg_stmt, act);

    LOG1(" MethodCallExpression: " << call);

    // Register read/write calls don not have an index argument for direct
    // registers. This is currently unsupported.
    if (call->arguments->size() == 0) {
        P4C_UNIMPLEMENTED("%s: The method call of read and write on a Register "
                "does not currently support for direct registers.  Please use "
                "DirectRegisterAction to describe direct register programming.",
                call);
    }

    // Create Register Action - Add to declaration
    auto member = call->method->to<IR::Member>();
    auto reg_path = member->expr->to<IR::PathExpression>()->path;
    auto reg_decl = self.refMap->getDeclaration(reg_path)->to<IR::Declaration_Instance>();

    bool is_read = (member->member.name == "read");
    bool is_write = (member->member.name == "write");
    int num_call_args = call->arguments->size();
    BUG_CHECK(is_read || is_write,
            " Invalid indirect register call. Only 'read' or 'write' calls are supported, "
            " but %1% specified", member->member.name);
    if (is_read) {
        BUG_CHECK(num_call_args == 1,
                " Invalid indirect register read call. Needs 1 argument for register index "
                " but %1% specified", num_call_args);
    }
    if (is_write) {
        BUG_CHECK(num_call_args == 2,
                " Invalid indirect register write call. Needs 2 arguments for register index "
                " and write expression only %1% specified", num_call_args);
    }

    auto reg_args = reg_decl->type->to<IR::Type_Specialized>()->arguments;
    auto rtype = reg_args->at(0);
    auto itype = reg_args->at(1);
    auto utype = call->type->to<IR::Type_Void>() ? rtype : call->type;
    auto ratype = new IR::Type_Specialized(
        new IR::Type_Name("RegisterAction"),
        new IR::Vector<IR::Type>({rtype, itype, utype}));

    // Create Register Apply block
    auto *ctor_args = new IR::Vector<IR::Argument>({
            new IR::Argument(new IR::PathExpression(new IR::Path(reg_path->name)))});

    auto apply_params = new IR::ParameterList({
                     new IR::Parameter("value", IR::Direction::InOut, rtype) });

    auto body = new IR::BlockStatement();
    // For register reads, add a return value
    auto in_value = new IR::PathExpression("in_value");
    auto value = new IR::PathExpression("value");
    if (is_read) {
        auto rv = new IR::PathExpression("rv");
        apply_params->push_back(new IR::Parameter("rv", IR::Direction::Out, utype));
        body->components.insert(body->components.end(),
            new IR::Declaration_Variable("in_value", rtype));
        body->components.insert(body->components.end(),
            new IR::AssignmentStatement(in_value, value));
        body->components.insert(body->components.end(),
            new IR::AssignmentStatement(rv, in_value));
    } else {
        // For register writes, use second method call argument to update the
        // register value
        auto write_expr = call->arguments->at(1)->expression;
        auto new_assign = new IR::AssignmentStatement(value, write_expr);
        // If write_expr contains a previous register read expression, replace with
        // in_value which is where the read value is stored inside the register
        // action
        if (reg_info.read_expr) {
            auto *sar = new SearchAndReplaceExpr(in_value, reg_info.read_expr);
            new_assign = new IR::AssignmentStatement(value, write_expr->apply(*sar));
        }
        body->components.insert(body->components.end(), new_assign);
    }

    auto apply_name = reg_path->name + "_register_action";
    auto* externalName = new IR::StringLiteral(IR::ID("." + apply_name));
    auto *annots = new IR::Annotations();
    annots->addAnnotation(IR::ID("name"), externalName);

    if (!reg_info.reg_action) {
        auto apply = new IR::Function("apply",
                                 new IR::Type_Method(IR::Type_Void::get(), apply_params), body);
        auto *apply_block = new IR::BlockStatement({ apply });
        reg_info.reg_action = new IR::Declaration_Instance(IR::ID(apply_name),
                            annots, ratype, ctor_args, apply_block);
    } else {
        // Find the apply function
        auto reg_action_components = reg_info.reg_action->initializer->components;
        for (auto comp : reg_action_components) {
            auto apply_function = comp->to<IR::Function>();
            if (!apply_function) continue;
            if (apply_function->name != "apply") continue;
            auto apply_body = apply_function->body;
            body->components.insert(body->components.begin(), apply_body->components.begin(),
                                                              apply_body->components.end());
            auto apply = new IR::Function("apply", apply_function->type, body);
            auto *apply_block = new IR::BlockStatement({ apply });
            reg_info.reg_action = new IR::Declaration_Instance(reg_info.reg_action->name,
                                reg_info.reg_action->annotations, reg_info.reg_action->type,
                                reg_info.reg_action->arguments, apply_block);
            break;
        }
    }
    return reg_info;
}

bool RegisterReadWrite::AnalyzeActionWithRegisterCalls::preorder(const IR::P4Action * act) {
    LOG1(" P4 Action : " << act);

    if (self.action_register_calls.count(act) == 0) return false;

    RegInfo reg_info;
    for (auto call : self.action_register_calls[act]) {
        reg_info = createRegisterAction(reg_info, call, act);
        reg_info.reg_execute = createRegisterExecute(reg_info.reg_execute, call, act);
    }

    auto reg_action = reg_info.reg_action;
    auto reg_execute = reg_info.reg_execute;
    BUG_CHECK(reg_action, "Cannot create register action for register reads or "
                          "writes within P4 Action %1%", act);
    BUG_CHECK(reg_execute, "Cannot create register execute call for register reads or "
                          "writes within P4 Action %1%", act);

    auto control = findContext<IR::P4Control>();
    BUG_CHECK(control, "No control found for P4 Action ", act);

    self.control_register_actions[control].push_back(reg_action);

    self.action_register_exec_calls[act] = reg_execute;

    return false;
}

bool RegisterReadWrite::CollectRegisterReadsWrites::preorder(
                                        const IR::MethodCallExpression* call) {
    LOG1(" MethodCallExpression: " << call);

    // Check for register read/write extern calls
    auto act = findContext<IR::P4Action>();
    if (!act) return false;

    auto method = P4::MethodInstance::resolve(call, self.refMap, self.typeMap);
    if (!method) return false;

    auto member = call->method->to<IR::Member>();
    if (!member) return false;

    auto path = member->expr->to<IR::PathExpression>();
    if (!path) return false;

    const IR::Type_Extern* typeEx = nullptr;
    auto type = path->type->to<IR::Type_SpecializedCanonical>();

    typeEx = type ? type->baseType->to<IR::Type_Extern>()
                  : path->type->to<IR::Type_Extern>();

    if (!typeEx) return false;

    if (typeEx->name != "Register") return false;

    auto stmt = findContext<IR::Statement>();
    if (member->member == "read") {
        LOG1(" Register extern found: " << member << " in action : " << act->name);
        self.action_register_calls[act].insert(stmt);
    }
    if (member->member == "write") {
        LOG1(" Register extern found: " << member << " in action : " << act->name);
        self.action_register_calls[act].insert(stmt);
    }
    return false;
}

}  // namespace BFN
