#include "frontends/p4/methodInstance.h"
#include "register_read_write.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/mau/stateful_alu.h"
#include "bf-p4c/device.h"

namespace BFN {

/**
 * The method checks whether the form of the read/write register call is correct,
 * i.e. has one of the forms described in the error message in this function.
 * @param[in] reg_stmt The read/write register statement that is being checked
 * @return A pair of 1. the read/write method call expression contained in the reg_stmt, and
 *                   2. the left-hand side of the assignment statement of the register read method.
 */
std::pair<const IR::MethodCallExpression * /*call*/, const IR::Expression * /*read_expr*/>
RegisterReadWrite::extractRegisterReadWrite(const IR::Statement *reg_stmt) {
    const IR::MethodCallExpression *call = nullptr;
    const IR::Expression *read_expr = nullptr;

    if (auto reg_mcall_stmt = reg_stmt->to<IR::MethodCallStatement>()) {
        // This is a call to .write or .read without assignment, so not assigning to read_expr
        call = reg_mcall_stmt->methodCall;
    } else if (auto reg_assign_stmt = reg_stmt->to<IR::AssignmentStatement>()) {
        // This is a call to .read and we need to store the left-hand side of the assignment
        if (auto *slice = reg_assign_stmt->right->to<IR::Slice>()) {
            call = slice->e0->to<IR::MethodCallExpression>();
        } else {
            call = reg_assign_stmt->right->to<IR::MethodCallExpression>();
        }
        read_expr = reg_assign_stmt->left;
    }

    return std::pair<const IR::MethodCallExpression * /*call*/,
                     const IR::Expression * /*read_expr*/>(call, read_expr);
}

/*
 * The execute call is placed at the position of the read call with assignment or,
 * if only the write call is present, at the end of the action.
 */
IR::Node *RegisterReadWrite::UpdateRegisterActionsAndExecuteCalls::preorder(IR::P4Action* act) {
    LOG1(" P4 Action: " << act);

    auto orig_act = getOriginal<IR::P4Action>();
    if (self.action_register_calls.count(orig_act) == 0) return act;

    // Temporary body being updated; iteratively being updated for each register used in the action
    auto src_body = orig_act->body;

    // Iterate over registers used in the action
    for (auto reg : self.action_register_calls[orig_act]) {
        auto calls = reg.second;
        // Temporary body
        auto body = new IR::BlockStatement();
        // The read assignment statement to be remembered
        // The execute call is placed on its position.
        const IR::AssignmentStatement *assign_stmt = nullptr;

        auto src_body_it = src_body->components.begin();

        // Remove register read & write calls in action and remember the read assignment
        while (src_body_it != src_body->components.end() && assign_stmt == nullptr) {
            auto inst = *src_body_it;
            LOG1(" P4 Action Statement: " << inst);
            if (calls.count(inst->to<IR::Statement>()) == 0) {
                // Add non-read & write statements
                body->push_back(inst);
            } else if (assign_stmt == nullptr) {
                // Skip read & write statements and remember the read assignment
                assign_stmt = inst->to<IR::AssignmentStatement>();
            }
            src_body_it++;
        }

        BUG_CHECK(self.action_register_exec_calls.count(orig_act) > 0
            && self.action_register_exec_calls[orig_act].count(reg.first) > 0,
            "No register execution call generated for register read/write in action %1%", orig_act);

        auto reg_exec_call = self.action_register_exec_calls[orig_act][reg.first];

        // Add register execute call in appropriate form
        IR::Statement *stmt = nullptr;
        if (assign_stmt) {
            if (auto *slice = assign_stmt->right->to<IR::Slice>()) {
                stmt = new IR::AssignmentStatement(assign_stmt->left,
                    new IR::Slice(reg_exec_call, slice->e1, slice->e2));
            } else {
                stmt = new IR::AssignmentStatement(assign_stmt->left, reg_exec_call);
            }
        } else {
            stmt = new IR::MethodCallStatement(reg_exec_call);
        }
        body->push_back(stmt);

        // Update temporary body with remaining non-register read/write instructions
        while (src_body_it != src_body->components.end()) {
            auto inst = *src_body_it;
            if (calls.count(inst->to<IR::Statement>()) == 0)
                body->push_back(inst);
            src_body_it++;
        }

        // Operate on updated body in the next iteration
        src_body = body;
    }

    return new IR::P4Action(act->srcInfo, act->name, act->annotations, act->parameters, src_body);
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
// FIXME -- really should factor out common code between createRegisterAction and
//          createRegisterExecute
IR::MethodCallExpression*
RegisterReadWrite::AnalyzeActionWithRegisterCalls::createRegisterExecute(
                                        IR::MethodCallExpression *reg_execute,
                                        const IR::Statement *reg_stmt,
                                        const IR::P4Action *act) {
    BUG_CHECK(reg_stmt, "No register call statment present to analyze in action - %1%", act);

    auto rv = extractRegisterReadWrite(reg_stmt);
    auto *call = rv.first;
    if (!call) return nullptr;

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
    auto utype = call->type;
    if (utype->is<IR::Type_Void>()) {
        auto tmp = self.typeMap->getType(rtype);
        if (auto tt = tmp->to<IR::Type_Type>())
            tmp = tt->type;
        if (auto stype = tmp->to<IR::Type_StructLike>()) {
            // currently only support structs with 1 or 2 identical fields in registers;
            // backend will flag an error if it is not.
            utype = stype->fields.front()->type;
        } else {
            utype = rtype; } }

    auto apply_name = reg_path->name + "_" + act->name;

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

    auto rv = extractRegisterReadWrite(reg_stmt);
    auto *call = rv.first;
    if (!call) return RegInfo();

    if (!reg_info.read_expr) {
        // Do not overwrite with returned nullptr if the read expression is already stored
        reg_info.read_expr = rv.second;
    }

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
    auto utype = call->type;
    if (utype->is<IR::Type_Void>()) {
        auto tmp = self.typeMap->getType(rtype);
        if (auto tt = tmp->to<IR::Type_Type>())
            tmp = tt->type;
        if (auto stype = tmp->to<IR::Type_StructLike>()) {
            // currently only support structs with 1 or 2 identical fields in registers;
            // backend will flag an error if it is not.
            utype = stype->fields.front()->type;
        } else {
            utype = rtype; } }
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

    auto apply_name = reg_path->name + "_" + act->name;
    auto* externalName = new IR::StringLiteral(IR::ID("." + apply_name));
    auto *annots = new IR::Annotations();
    annots->addAnnotation(IR::ID("name"), externalName);

    if (!reg_info.reg_action) {
        auto apply = new IR::Function("apply",
                new IR::Type_Method(IR::Type_Void::get(), apply_params, "apply"), body);
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

    auto control = findContext<IR::P4Control>();
    BUG_CHECK(control, "No control found for P4 Action ", act);

    for (auto reg : self.action_register_calls[act]) {
        RegInfo reg_info;
        for (auto call : reg.second) {
            reg_info = createRegisterAction(reg_info, call, act);
            reg_info.reg_execute = createRegisterExecute(reg_info.reg_execute, call, act);
        }

        auto reg_action = reg_info.reg_action;
        auto reg_execute = reg_info.reg_execute;
        BUG_CHECK(reg_action, "Cannot create register action for register reads or "
                            "writes within P4 Action %1%", act);
        BUG_CHECK(reg_execute, "Cannot create register execute call for register reads or "
                            "writes within P4 Action %1%", act);

        self.control_register_actions[control].push_back(reg_action);

        LOG3(" Adding execute in " << act->name << " for " << reg.first->toString() << ": "
            << reg_execute);

        self.action_register_exec_calls[act][reg.first] = reg_execute;
    }

    return false;
}

/*
 * Check the number of register actions attached to registers. It cannot exceed 4.
 * This is a Tofino 1/2/3 HW restriction.
 */
void RegisterReadWrite::AnalyzeActionWithRegisterCalls::end_apply() {
    std::map<const IR::Declaration_Instance *, int> count;
    for (auto act_map : self.action_register_exec_calls) {
        for (auto reg_map : act_map.second) {
            auto reg = reg_map.first;
            if (count.count(reg) == 0)
                count[reg] = 1;
            else
                count[reg]++;
        }
    }
    for (auto count_item : count) {
        if (count_item.second > Device::statefulAluSpec().MaxInstructions)
            ::error(ErrorType::ERR_UNSUPPORTED_ON_TARGET,
                "%1%: too many actions try to access the register. The target limits the number "
                "of actions accessing a single register to %2%. Reorganize your code to meet "
                "this restriction.", count_item.first, Device::statefulAluSpec().MaxInstructions);
    }
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
    if (auto em = method->to<P4::ExternMethod>()) {
        auto reg = em->object->to<IR::Declaration_Instance>();
        if (member->member == "read") {
            LOG1(" Register extern found: " << member << " in action : " << act->name);
            self.action_register_calls[act][reg].insert(stmt);
        }
        if (member->member == "write") {
            LOG1(" Register extern found: " << member << " in action : " << act->name);
            self.action_register_calls[act][reg].insert(stmt);
        }
    }
    return false;
}

/*
 * Check that all uses of a register within a single action use the same addressing.
 * This is a Tofino 1/2/3 HW restriction.
 */
void RegisterReadWrite::CollectRegisterReadsWrites::end_apply() {
#if HAVE_FLATROCK
    if (Device::currentDevice() == Device::FLATROCK) return;
#endif  // HAVE_FLATROCK

    for (auto act_map : self.action_register_calls) {
        auto act = act_map.first;
        const IR::Expression *first_addr = nullptr;
        auto first_reg = act_map.second.begin()->first;
        auto first_reg_type_spec = first_reg->type->to<IR::Type_Specialized>();
        // When compiling for the v1model, type information seems to be a bit different than
        // for PSA and T*NA architectures. With v1model, the template parameters are of the
        // type IR::Type_Name. Type_Name::width_bits() suggests to use getTypeType. It gives
        // correct result for all archs.
        auto first_reg_type_type = self.typeMap->getTypeType(
            first_reg_type_spec->arguments->at(0)->getNode(), true);
        auto first_width = first_reg_type_type->width_bits();
        for (auto reg_map : act_map.second) {
            auto reg = reg_map.first;
            auto reg_type_spec = first_reg->type->to<IR::Type_Specialized>();
            // See above.
            auto reg_type_type = self.typeMap->getTypeType(
                reg_type_spec->arguments->at(0)->getNode(), true);
            auto width = reg_type_type->width_bits();
            if (first_width != width)
                ::error(ErrorType::ERR_UNSUPPORTED_ON_TARGET,
                    "%1%: widths of all registers used within a single action have to "
                    "be the same. Widths of the following registers differ:\n%2%%3%",
                    act, first_reg, reg);
            for (auto reg_set : reg_map.second) {
                auto mce = RegisterReadWrite::extractRegisterReadWrite(reg_set).first;
                if (!mce) {
                    ::fatal_error(ErrorType::ERR_UNSUPPORTED,
                        "%1%: Registers support only calls or assignments of the following forms:\n"
                        "  register.write(index, source);\n"
                        "  destination = register.read(index);\n"
                        "  destination = register.read(index)[M:N];\n"
                        "  destination = (cast)register.read(index);\n"
                        "If more complex calls or assignments are required, try to use "
                        "the RegisterAction extern.", reg_set);
                }
                if (first_addr == nullptr) {
                    first_addr = mce->arguments->at(0)->expression;
                } else {
                    auto *addr = mce->arguments->at(0)->expression;
                    if (!first_addr->equiv(*addr))
                        ::error(ErrorType::ERR_UNSUPPORTED_ON_TARGET,
                            "%1%: uses of all registers within a single action have to "
                            "use the same addressing. The following uses differ:\n%2%%3%",
                            act, first_addr, addr);
                }
            }
        }
    }
}

bool RegisterReadWrite::MoveRegisterParameters::preorder(IR::P4Control *c) {
    IR::IndexedVector<IR::Declaration> reg_params;
    for (auto *decl : c->controlLocals) {
        auto *type = self.typeMap->getType(decl);
        if (auto *canonical = type->to<IR::Type_SpecializedCanonical>())
            type = canonical->baseType;
        if (auto *ext = type->to<IR::Type_Extern>())
            if (ext->name == "RegisterParam")
                reg_params.push_back(decl);
    }
    for (auto *decl : reg_params)
        c->controlLocals.removeByName(decl->getName());
    c->controlLocals.prepend(reg_params);
    return true;
}

}  // namespace BFN
