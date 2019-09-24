#include "desugar_varbit_extract.h"
#include "frontends/common/constantFolding.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/utils.h"

struct CollectVariables : public Inspector {
    bool preorder(const IR::Expression* expr) override {
        if (expr->is<IR::Member>() || expr->is<IR::Slice>() ||
            expr->is<IR::TempVar>()) {
            rv.push_back(expr);
            return false;
        }
        return true;
    }

    std::vector<const IR::Expression*> rv;

    CollectVariables() { }
};

struct EvaluateForVar : public PassManager {
    struct SubstituteVar : public Transform {
        const IR::Expression* var;
        unsigned val;

        IR::Node* preorder(IR::Expression* expr) override {
            if (expr->equiv(*var)) {
                auto width = var->type->width_bits();
                auto constant = new IR::Constant(IR::Type::Bits::get(width), val);
                return constant;
            } else {
                return expr;
            }
        }

        SubstituteVar(const IR::Expression* var, unsigned val) :
            var(var), val(val) { }
    };

    EvaluateForVar(P4::ReferenceMap* rm, P4::TypeMap* tm,
                   const IR::Expression* var, unsigned val) :
            refMap(*rm), typeMap(*tm) {
        addPasses({
            new SubstituteVar(var, val),
            new P4::ConstantFolding(&refMap, &typeMap, false)
        });
    }

    // ConstantFolding has side effects on typeMap, make these local copies
    // so that we don't modify the original map
    P4::ReferenceMap refMap;
    P4::TypeMap typeMap;
};

const IR::Constant* CollectVarbitExtract::evaluate(const IR::Expression* varsize_expr,
                                        const IR::Expression* encode_var, unsigned val) {
    auto clone = varsize_expr->clone();

    EvaluateForVar evaluator(refMap, typeMap, encode_var, val);
    auto rv = clone->apply(evaluator);

    auto constant = rv->to<IR::Constant>();
    BUG_CHECK(constant, "varsize expr did not evaluate to constant?");

    return constant;
}

bool CollectVarbitExtract::is_legal_runtime_value(const IR::Expression* verify,
        const IR::Expression* encode_var, unsigned val) {
    auto clone = verify->clone();

    EvaluateForVar evaluator(refMap, typeMap, encode_var, val);
    auto rv = clone->apply(evaluator);

    if (auto bl = rv->to<IR::BoolLiteral>()) {
        if (bl->value == 0)
            return false;
    }

    return true;
}

bool CollectVarbitExtract::is_legal_runtime_value(const IR::ParserState* state,
        const IR::Expression* encode_var, unsigned val) {
    if (state_to_verify_exprs.count(state)) {
        for (auto verify : state_to_verify_exprs.at(state)) {
            if (!is_legal_runtime_value(verify, encode_var, val))
                return false;
        }
    }

    return true;
}

void check_compile_time_constant(const IR::Constant* c,
                                 const IR::MethodCallExpression* call,
                                 int varbit_field_size,
                                 bool zero_ok = false) {
    if (c->asInt() < 0 || (!zero_ok && c->asInt() == 0)) {
        std::stringstream hint;

        if (BackendOptions().langVersion == CompilerOptions::FrontendVersion::P4_16)
            hint << "Please make sure the encoding variable is cast to bit<32>.";

        ::fatal_error("Varbit field size expression evaluates to invalid value %1%: %2% \n%3%",
                      c->asInt(), call, hint.str());
    }

    if (c->asInt() % 8) {
        ::fatal_error("Varbit field size expression evaluates to non byte-aligned value %1%: %2%",
                      c->asInt(), call);
    }

    if (c->asInt() > varbit_field_size) {
        ::fatal_error("%1% exceeds varbit field size %2%: %3%",
                      c->asInt(), varbit_field_size, call);
    }
}

bool CollectVarbitExtract::enumerate_varbit_field_values(
        const IR::MethodCallExpression* call,
        const IR::ParserState* state,
        const IR::StructField* varbit_field,
        const IR::Expression* varsize_expr,
        const IR::Expression*& encode_var,
        std::map<unsigned, const IR::Constant*>& compile_time_constants,
        std::set<unsigned>& reject_values) {
    CollectVariables find_encode_var;
    varsize_expr->apply(find_encode_var);

    if (find_encode_var.rv.size() == 0)
        ::fatal_error("No varbit length encoding variable in %1%.", call);
    else if (find_encode_var.rv.size() > 1)
        ::fatal_error("Varbit expression %1% contains more than one variables.", call);

    encode_var = find_encode_var.rv[0];

    unsigned long var_bitwidth = encode_var->type->width_bits();

    if (var_bitwidth > 32) {  // already checked in frontend?
        ::fatal_error("Varbit length encoding variable requires more than 32 bits: %1%",
                      encode_var);
    }

    unsigned branches_needed = 0;

    for (unsigned long i = 0; i < (1UL << var_bitwidth); i++) {
        if (is_legal_runtime_value(state, encode_var, i)) {
            auto c = evaluate(varsize_expr, encode_var, i);

            auto varbit_field_size = varbit_field->type->to<IR::Type_Varbits>()->size;
            if (!c->fitsInt() || c->asInt() > varbit_field_size) {
                reject_values.insert(i);
                LOG4("compile time constant exceeds varbit field size: " << c->asUnsigned());
            } else {
                check_compile_time_constant(c, call, varbit_field_size, true);
                compile_time_constants[i] = c;
            }
        } else {
            reject_values.insert(i);
        }

        branches_needed++;

        if (branches_needed > 100)
            break;
    }

    if (branches_needed > 100) {
        ::fatal_error("Varbit extract requires too many parser branches to implement. "
                  "Consider rewriting the variable length expression to reduce "
                  "the number of possible runtime values: %1%", call);
        return false;
    }

    LOG2(varsize_expr << " needs " << branches_needed << "to implement");
    LOG2(varsize_expr << " evaluate to compile time constants:");

    for (auto& kv : compile_time_constants)
        LOG2(encode_var << " = " << kv.first << " : " << kv.second);

    for (auto& v : reject_values)
        LOG2(encode_var << " = " << v << " : reject");

    return true;
}

void CollectVarbitExtract::enumerate_varbit_field_values(
        const IR::MethodCallExpression* call,
        const IR::ParserState* state,
        const IR::Expression* varsize_expr,
        const IR::Type_Header* hdr_type) {
    if (state_to_varbit_header.count(state)) {
        P4C_UNIMPLEMENTED("%1%: multiple varbit fields in a parser state"
                              " is currently unsupported", call);
    }

    const IR::StructField* varbit_field = hdr_type->fields.back();

    const IR::Expression* encode_var = nullptr;
    std::map<unsigned, const IR::Constant*> compile_time_constants;
    std::set<unsigned> reject_values;

    if (auto c = varsize_expr->to<IR::Constant>()) {
        auto varbit_field_size = varbit_field->type->to<IR::Type_Varbits>()->size;

        check_compile_time_constant(c, call, varbit_field_size);
        compile_time_constants[0] = c;  // use 0 as key, but really don't care
    } else {
        bool ok = enumerate_varbit_field_values(call, state, varbit_field, varsize_expr,
                                      encode_var, compile_time_constants, reject_values);
        if (!ok) return;
    }

    state_to_varbit_header[state] = hdr_type;
    state_to_varbit_field[state] = varbit_field;
    state_to_encode_var[state] = encode_var;

    varbit_field_to_compile_time_constants[varbit_field] = compile_time_constants;
    varbit_field_to_reject_values[varbit_field] = reject_values;

    header_type_to_varbit_field[hdr_type] = varbit_field;
    varbit_field_to_extract_call[varbit_field] = call;
}

const IR::StructField* get_varbit_structfield(const IR::Member* member) {
    auto header = member->expr->to<IR::Member>();
    auto headerType = header->type->to<IR::Type_Header>();
    for (auto field : headerType->fields) {
        if (field->name == member->member) {
            return field;
        }
    }
    BUG("No varbit found in %1%", header);
    return nullptr;
}

bool CollectVarbitExtract::preorder(const IR::AssignmentStatement* astmt) {
    if (auto state = findContext<IR::ParserState>()) {
        bool seen_varbit = state_to_varbit_header.count(state);
        if (!seen_varbit) return false;
        auto right = astmt->right;
        if (right->is<IR::BFN::ReinterpretCast>()) {
            right = right->to<IR::BFN::ReinterpretCast>()->expr;
        }
        auto mc = right->to<IR::MethodCallExpression>();
        if (auto* method = mc->method->to<IR::Member>()) {
            if (auto path = method->expr->to<IR::PathExpression>()) {
                auto type = path->type->to<IR::Type_Extern>();
                if (!type) return false;
                if (type->name != "Checksum") return false;
                if (method->member == "verify") {
                    state_to_csum_verify[state] = astmt;
                }
            }
        }
    }
    return false;
}

bool CollectVarbitExtract::preorder(const IR::MethodCallExpression* call) {
    if (auto state = findContext<IR::ParserState>()) {
        bool seen_varbit = state_to_varbit_header.count(state);

        if (auto method = call->method->to<IR::Member>()) {
            if (method->member == "extract") {
                auto dest = (*call->arguments)[0]->expression;
                auto hdr_type = dest->type->to<IR::Type_Header>();

                if (call->arguments->size() == 2) {
                    auto varsize_expr = (*call->arguments)[1]->expression;

                    LOG3("found varbit in " << state->name);
                    LOG3("varsize expr is " << varsize_expr);

                    if (seen_varbit) {
                        P4C_UNIMPLEMENTED("%1%: multiple varbit fields in a parser state"
                              " is currently unsupported", call);
                    }

                    enumerate_varbit_field_values(call, state, varsize_expr, hdr_type);

                    auto parser = findContext<IR::BFN::TnaParser>();
                    state_to_parser[state] = parser;
                    seen_varbit = true;
                } else if (seen_varbit) {
                    P4C_UNIMPLEMENTED("%1%: current compiler implementation requires the"
                          " varbit header to be extracted last in the parser state", call);
                }
            } else if (method->member == "add" || method->member == "subtract") {
                auto path = method->expr->to<IR::PathExpression>();
                if (!path) return false;
                auto type = path->type->to<IR::Type_Extern>();
                if (!type) return false;
                if (type->name != "Checksum") return false;

                if (auto add_expr = (*call->arguments)[0]->expression->to<IR::ListExpression>()) {
                    for (auto field : add_expr->components) {
                        if (auto member = field->to<IR::Member>()) {
                            if (member->type->is<IR::Type_Varbits>()) {
                                if (method->member == "subtract") {
                                    P4C_UNIMPLEMENTED("Checksum subtract is currently not "
                                         "supported to have varbit fields %1%", call);
                                }
                                varbit_field_to_csum_call
                                        [get_varbit_structfield(member)].insert(call);
                            }
                        }
                    }
                }
            }
        } else if (auto path = call->method->to<IR::PathExpression>()) {
            if (path->path->name == "verify") {
                auto verify_expr = (*call->arguments)[0]->expression;
                state_to_verify_exprs[state].insert(verify_expr);
            }
       }
    }
    return false;
}

static cstring create_instance_name(cstring name) {
    std::string str(name.c_str());
    str = str.substr(0, str.length() - 2);
    return str.c_str();
}

static IR::Type_Header*
create_varbit_header_type(cstring orig_header,
                          const IR::StructField* varbit_field, unsigned length) {
    cstring name = create_instance_name(orig_header) + "_" + varbit_field->name + "_"
                   + cstring::to_cstring(length) + "b_t";

    auto hdr = new IR::Type_Header(name);
    auto field_type = IR::Type::Bits::get(length);
    auto field = new IR::StructField("field", field_type);
    hdr->fields.push_back(field);
    return hdr;
}

Modifier::profile_t RewriteVarbitUses::init_apply(const IR::Node* root) {
    for (auto& pv : cve.state_to_varbit_field)
        create_branches(pv.first, pv.second);

    return Modifier::init_apply(root);
}

static IR::MethodCallStatement*
create_extract_statement(const IR::BFN::TnaParser* parser,
                         const IR::PathExpression* path,
                         cstring header) {
    auto packetInParam = parser->tnaParams.at("pkt");
    auto method = new IR::Member(new IR::PathExpression(packetInParam), IR::ID("extract"));
    auto args = new IR::Vector<IR::Argument>(
         { new IR::Argument(new IR::Member(path, header)) });
    auto *callExpr = new IR::MethodCallExpression(method, args);
    return new IR::MethodCallStatement(callExpr);
}

static IR::MethodCallStatement*
create_add_statement(const IR::Member* method,
                     const IR::PathExpression* path,
                     const IR::Type_Header* header) {
    auto listVec = IR::Vector<IR::Expression>();
    cstring headerName = create_instance_name(header->name);
    for (auto f : header->fields) {
        listVec.push_back(new IR::Member(f->type, new IR::Member(path, headerName), f->name));
    }
    auto args = new IR::Vector<IR::Argument>({ new IR::Argument(
                new IR::ListExpression(listVec))});
    auto addCall = new IR::MethodCallExpression(method, args);
    return new IR::MethodCallStatement(addCall);
}

IR::ParserState*
RewriteVarbitUses::create_branch_state(const IR::BFN::TnaParser* parser,
        const IR::Expression* select, const IR::StructField* varbit_field, unsigned length) {
    IR::IndexedVector<IR::StatOrDecl> statements;

    auto header = varbit_field_to_header_types[varbit_field][length];

    auto call = cve.varbit_field_to_extract_call.at(varbit_field);
    auto path = (*call->arguments)[0]->expression->to<IR::Member>()
                                     ->expr->to<IR::PathExpression>();

    auto extract = create_extract_statement(parser, path, create_instance_name(header->name));
    statements.push_back(extract);

    if (cve.varbit_field_to_csum_call.count(varbit_field)) {
        for (auto call : cve.varbit_field_to_csum_call.at(varbit_field)) {
            auto method = call->method->to<IR::Member>();
            statements.push_back(create_add_statement(method, path, header));
        }
    }
    cstring name = "parse_" + varbit_field->name + "_" + cstring::to_cstring(length) + "b";
    auto branch_state = new IR::ParserState(name, statements, select);

    LOG3("create state " << name);

    return branch_state;
}

void RewriteVarbitUses::create_branches(const IR::ParserState* state,
                                         const IR::StructField* varbit_field) {
    ordered_map<unsigned, const IR::ParserState*> match_to_branch_state;

    auto parser = cve.state_to_parser.at(state);
    auto orig_header = cve.state_to_varbit_header.at(state);
    auto encode_var = cve.state_to_encode_var.at(state);

    auto& value_map = cve.varbit_field_to_compile_time_constants.at(varbit_field);

    cstring no_option_state_name = "parse_" + varbit_field->name + "_0b";

    for (auto& kv : value_map) {
        auto match = kv.first;
        auto length = kv.second->asUnsigned();

        if (length) {
            auto header = create_varbit_header_type(orig_header->name, varbit_field, length);
            varbit_field_to_header_types[varbit_field][length] = header;

            const IR::Expression* select = nullptr;

            if (encode_var)
                select = new IR::PathExpression(no_option_state_name);
            else  // unconditional transition (varsize expr is constant)
                select = state->selectExpression;

            auto branch_state = create_branch_state(parser, select, varbit_field, length);
            match_to_branch_state[match] = branch_state;
        } else {
            IR::IndexedVector<IR::StatOrDecl> statements;
            if (cve.state_to_csum_verify.count(state)) {
                statements.push_back(cve.state_to_csum_verify.at(state));
            }
            auto no_option_state = new IR::ParserState(no_option_state_name, statements,
                                                       state->selectExpression);
            match_to_branch_state[match] = no_option_state;
        }
    }

    state_to_branches[state] = match_to_branch_state;
}

bool RewriteVarbitUses::preorder(IR::BFN::TnaParser* parser) {
    auto orig = getOriginal<IR::P4Parser>();

    bool has_varbit = false;

    for (auto& kv : cve.state_to_parser) {
        if (kv.second == orig) {
            has_varbit = true;
            break;
        }
    }

    if (!has_varbit)
        return true;

    for (auto& kv : state_to_branches) {
        if (cve.state_to_parser.at(kv.first) == orig) {
            for (auto& ms : kv.second)
                parser->states.push_back(ms.second);
        }
    }

    return true;
}

static IR::SelectCase *
create_select_case(unsigned bitwidth, unsigned value, unsigned mask, cstring next_state) {
    auto type = IR::Type::Bits::get(bitwidth);
    auto value_expr = new IR::Constant(type, value);
    auto mask_expr = new IR::Constant(type, mask);
    auto next_state_expr = new IR::PathExpression(next_state);
    return new IR::SelectCase(new IR::Mask(value_expr, mask_expr), next_state_expr);
}

bool RewriteVarbitUses::preorder(IR::ParserState* state) {
    auto orig = getOriginal<IR::ParserState>();

    if (!state_to_branches.count(orig))
        return true;

    auto& match_to_branch_state = state_to_branches.at(orig);

    IR::Vector<IR::SelectCase> select_cases;

    auto varbit_field = cve.state_to_varbit_field.at(orig);
    auto encode_var = cve.state_to_encode_var.at(orig);

    if (encode_var) {
        unsigned var_bitwidth = encode_var->type->width_bits();
        unsigned var_mask = (1 << var_bitwidth) - 1;

        for (auto& ms : match_to_branch_state) {
            auto match = ms.first;
            auto next_state = ms.second;

            auto select_case = create_select_case(var_bitwidth, match, var_mask, next_state->name);
            select_cases.push_back(select_case);
        }

        for (auto reject : cve.varbit_field_to_reject_values.at(varbit_field)) {
            auto select_case = create_select_case(var_bitwidth, reject, var_mask, "reject");
            select_cases.push_back(select_case);
        }

        IR::Vector<IR::Expression> select_on;
        select_on.push_back(encode_var);

        auto select = new IR::SelectExpression(new IR::ListExpression(select_on), select_cases);
        state->selectExpression = select;
    } else {  // unconditional transition (varsize expr is constant)
        BUG_CHECK(match_to_branch_state.size() == 1 &&
                  match_to_branch_state.count(0), "unconditional branch does not exist?");

        auto next_state = match_to_branch_state.at(0);
        auto path = new IR::PathExpression(next_state->name);
        state->selectExpression = path;
    }
    // Removing verify call from the original state
    if (cve.state_to_csum_verify.count(orig)) {
       IR::IndexedVector<IR::StatOrDecl> components;
       for (auto a : orig->components) {
           if (!cve.state_to_csum_verify.at(orig)->equiv(*a)) {
               components.push_back(a);
           }
       }
       state->components = components;
    }

    return true;
}

bool RewriteVarbitUses::preorder(IR::MethodCallExpression* call) {
    auto state = findContext<IR::ParserState>();
    if (state) {
        if (auto method = call->method->to<IR::Member>()) {
            if (method->member == "extract") {
                if (call->arguments->size() == 2) {
                    auto dest = (*call->arguments)[0];
                    auto args = new IR::Vector<IR::Argument>();
                    args->push_back(dest);
                    call->arguments = args;
                }
            }
        }
    }

    return true;
}

static IR::MethodCallStatement*
create_emit_statement(const IR::Member* method, const IR::Expression* path, cstring header) {
    auto args = new IR::Vector<IR::Argument>(
        { new IR::Argument(new IR::Member(path, header)) } );
    auto call = new IR::MethodCallExpression(method, args);
    auto emit = new IR::MethodCallStatement(call);
    return emit;
}

bool RewriteVarbitUses::preorder(IR::BlockStatement* block) {
    auto deparser = findContext<IR::BFN::TnaDeparser>();
    if (deparser) {
        IR::IndexedVector<IR::StatOrDecl> components;

        for (auto stmt : block->components) {
            components.push_back(stmt);

            if (auto mc = stmt->to<IR::MethodCallStatement>()) {
                auto mce = mc->methodCall;

                if (auto method = mce->method->to<IR::Member>()) {
                    if (method->member == "emit") {
                        auto arg = (*mce->arguments)[0];
                        auto type = arg->expression->type->to<IR::Type_Header>();

                        if (cve.header_type_to_varbit_field.count(type)) {
                            auto varbit_field = cve.header_type_to_varbit_field.at(type);

                            for (auto& kv : varbit_field_to_header_types.at(varbit_field)) {
                                auto path = arg->expression->to<IR::Member>()->expr;
                                auto emit = create_emit_statement(method, path,
                                                   create_instance_name(kv.second->name));
                                components.push_back(emit);
                            }
                        }
                    }
                }
            }
        }

        block->components = components;
    }

    return true;
}

bool RewriteVarbitUses::preorder(IR::ListExpression* list) {
    auto deparser = findContext<IR::BFN::TnaDeparser>();
    auto mc = findContext<IR::MethodCallExpression>();
    IR::Vector<IR::Expression> components;

    bool has_varbit = false;

    IR::Vector<IR::Type> varbit_types;

    for (auto c : list->components) {
        if (auto member = c->to<IR::Member>()) {
            if (member->type->is<IR::Type_Varbits>()) {
                if (has_varbit)
                    ::error("More than one varbit expressions in %1%", list);

                auto type = member->expr->type->to<IR::Type_Header>();
                auto varbit_field = cve.header_type_to_varbit_field.at(type);
                if (deparser) {
                    has_varbit = true;
                    for (auto& kv : varbit_field_to_header_types.at(varbit_field)) {
                        auto path = member->expr->to<IR::Member>();
                        auto hdr = kv.second;
                        auto field = hdr->fields[0];

                        varbit_types.push_back(field->type);

                        auto member = new IR::Member(path->expr, create_instance_name(hdr->name));
                        auto hdr_field = new IR::Member(member, "field");

                        components.push_back(hdr_field);
                    }
                } else if (cve.varbit_field_to_csum_call.count(varbit_field)) {
                    for (auto call : cve.varbit_field_to_csum_call.at(varbit_field)) {
                        if (call->equiv(*mc)) {
                            has_varbit = true;
                            break;
                        }
                    }
                }
            }
        }

        if (!has_varbit)
            components.push_back(c);
    }
    if (has_varbit) {
        list->components = components;

        if (auto tuple = list->type->to<IR::Type_Tuple>()) {
            IR::Vector<IR::Type> types;

            for (auto type : tuple->components) {
                if (type->is<IR::Type_Varbits>()) {
                    for (auto vt : varbit_types)
                        types.push_back(vt);
                } else {
                    types.push_back(type);
                }
            }

            if (mc) {
                auto type_args = *(mc->typeArguments);

                if (type_args.size() == 1) {
                    auto tuple_type = type_args[0];
                    if (auto name = tuple_type->to<IR::Type_Name>()) {
                        auto tuple_name = name->path->name;
                        tuple_types_to_rewrite[tuple_name] = types;
                    }
                } else if (type_args.size() > 1) {
                    ::error("More than one type in type argument of %1%", list);
                }
            }
        }
    }

    return true;
}

IR::Node* RewriteParserVerify::preorder(IR::MethodCallStatement* stmt) {
    auto state = findContext<IR::ParserState>();
    if (state) {
        auto call = stmt->methodCall;

        if (auto path = call->method->to<IR::PathExpression>()) {
            if (path->path->name == "verify") {
                auto verify_expr = (*call->arguments)[0]->expression;

                CollectVariables find_var;
                verify_expr->apply(find_var);

                if (find_var.rv.size() == 1) {
                    for (auto& sv : cve.state_to_encode_var) {
                        if (sv.second->equiv(*(find_var.rv[0]))) {
                            LOG4("remove " << stmt << " absorbed in varbit rewrite");
                            return nullptr;
                        }
                    }
                }
            }
        }
    }

    return stmt;
}

bool RewriteVarbitTypes::preorder(IR::P4Program* program) {
    for (auto& kv : rvu.varbit_field_to_header_types) {
        for (auto& lt : kv.second)
            program->objects.insert(program->objects.begin(), lt.second);
    }

    // TODO add these to the header decl section instead of
    // prepending to beginning of program

    return true;
}

bool RewriteVarbitTypes::contains_varbit_header(IR::Type_Struct* type_struct) {
    for (auto field : type_struct->fields) {
        if (auto path = field->type->to<IR::Type_Name>()) {
            for (auto& kv : cve.header_type_to_varbit_field) {
                if (kv.first->name == path->path->name)
                    return true;
            }
        }
    }

    return false;
}

bool RewriteVarbitTypes::preorder(IR::Type_Struct* type_struct) {
    if (contains_varbit_header(type_struct)) {
        for (auto& kv : rvu.varbit_field_to_header_types) {
            for (auto& lt : kv.second) {
                auto type = lt.second;
                auto field = new IR::StructField(create_instance_name(type->name),
                                     new IR::Type_Name(type->name));
                type_struct->fields.push_back(field);
            }
        }
    } else {
        for (auto& kv : rvu.tuple_types_to_rewrite) {
            if (type_struct->name == kv.first) {
                type_struct->fields = {};

                int i = 0;
                for (auto type : kv.second) {
                    cstring name = kv.first + "_field_" + cstring::to_cstring(i++);
                    auto field = new IR::StructField(name, type);
                    type_struct->fields.push_back(field);
                }
            }
        }
    }

    return true;
}

bool RewriteVarbitTypes::preorder(IR::Type_Header* header) {
    auto orig = getOriginal<IR::Type_Header>();

    if (cve.header_type_to_varbit_field.count(orig)) {
        IR::IndexedVector<IR::StructField> fields;

        for (auto field : header->fields) {
            if (!field->type->is<IR::Type::Varbits>())
                fields.push_back(field);
        }

        header->fields = fields;
    }

    return true;
}
