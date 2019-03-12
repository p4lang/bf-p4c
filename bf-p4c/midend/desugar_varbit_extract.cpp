#include "desugar_varbit_extract.h"
#include "frontends/common/constantFolding.h"

struct FindLengthEncodingVar : public Inspector {
    profile_t init_apply(const IR::Node* r) override {
        root = r;
        return Inspector::init_apply(r);
    }

    bool preorder(const IR::Member* member) override {
        // already checked in frontend?
        if (hdr_type != member->expr->type) {
            ::error("The current compiler implementation of varbit requires the"
                    " length encoding variable %1% to belong in the same header"
                    " of the varbit field %2%", member, hdr_type);
        }

        rv.push_back(member);
        return false;
    }

    const IR::Node* root = nullptr;
    const IR::Type_Header* hdr_type;
    std::vector<const IR::Member*> rv;

    explicit FindLengthEncodingVar(const IR::Type_Header* hdr_type) : hdr_type(hdr_type) { }
};

struct EvaluateForVar : public PassManager {
    struct SubstituteVar : public Transform {
        const IR::Member* var;
        unsigned val;

        IR::Node* preorder(IR::Member* member) override {
            if (member->equiv(*var)) {
                auto width = var->type->width_bits();
                auto constant = new IR::Constant(IR::Type::Bits::get(width), val);
                return constant;
            } else {
                return member;
            }
        }

        SubstituteVar(const IR::Member* var, unsigned val) :
            var(var), val(val) { }
    };

    EvaluateForVar(P4::ReferenceMap* rm, P4::TypeMap* tm,
                   const IR::Member* var, unsigned val) :
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

const IR::Constant* CollectVarbitExtract::evaluate(const IR::Expression* varsize,
                                            const IR::Member* var, unsigned val) {
    auto clone = varsize->clone();

    EvaluateForVar evaluator(refMap, typeMap, var, val);
    auto rv = clone->apply(evaluator);

    auto constant = rv->to<IR::Constant>();
    BUG_CHECK(constant, "varsize did not evaluate to constant?");

    return constant;
}

bool CollectVarbitExtract::is_legal_runtime_value(const IR::Expression* verify,
        const IR::Member* var, unsigned val) {
    auto clone = verify->clone();

    EvaluateForVar evaluator(refMap, typeMap, var, val);
    auto rv = clone->apply(evaluator);

    if (auto bl = rv->to<IR::BoolLiteral>()) {
        if (bl->value == 0)
            return false;
    }

    return true;
}

bool CollectVarbitExtract::is_legal_runtime_value(const IR::ParserState* state,
        const IR::Member* var, unsigned val) {
    if (state_to_verify_exprs.count(state)) {
        for (auto verify : state_to_verify_exprs.at(state)) {
            if (!is_legal_runtime_value(verify, var, val))
                return false;
        }
    }

    return true;
}

void CollectVarbitExtract::enumerate_varbit_field_values(
        const IR::MethodCallExpression* call,
        const IR::ParserState* state,
        const IR::Expression* varsize, const IR::Type_Header* hdr_type) {
    std::map<unsigned, const IR::Constant*> compile_time_constants;
    std::set<unsigned> reject_values;

    // check varbit field is last in header and state TODO

    const IR::StructField* varbit_field = nullptr;

    for (auto field : hdr_type->fields) {
        if (field->type->is<IR::Type::Varbits>()) {
            varbit_field = field;
            break;
        }
    }

    FindLengthEncodingVar find_var(hdr_type);
    varsize->apply(find_var);

    // TODO varsize expr is constant? p4_16_samples/equality-varbit-bmv2.p4

    if (find_var.rv.size() == 0)
        ::error("No varbit length encoding variable in %1%?", call);
    else if (find_var.rv.size() > 1)
        ::error("varbit expression %1% contains more than one variables?", call);

    auto var = find_var.rv[0];

    unsigned var_bitwidth = var->type->width_bits();

    if (var_bitwidth > 32)  // already checked in frontend?
        ::error("varbit length encoding variable requires more than 32 bits? %1%", var);

    for (int i = 0; i < (1 << var_bitwidth); i++) {
        if (is_legal_runtime_value(state, var, i)) {
            auto c = evaluate(varsize, var, i);

            if (c->asUnsigned() > varbit_field->type->to<IR::Type_Varbits>()->size) {
                LOG4("compile time constant exceeds varbit field size: " << c->asUnsigned());
                reject_values.insert(i);
            } else {
                compile_time_constants[i] = evaluate(varsize, var, i);
            }
        } else {
            reject_values.insert(i);
        }
    }

    LOG2(varsize << " evaluate to compile time constants:");

    for (auto& kv : compile_time_constants)
        LOG2(var << " = " << kv.first << " : " << kv.second);

    for (auto& v : reject_values)
        LOG2(var << " = " << v << " : reject");

    state_to_varbit_header[state] = hdr_type;
    state_to_varbit_field[state] = varbit_field;
    state_to_length_var[state] = var;

    varbit_field_to_compile_time_constants[varbit_field] = compile_time_constants;
    varbit_field_to_reject_values[varbit_field] = reject_values;

    header_type_to_varbit_field[hdr_type] = varbit_field;
    varbit_field_to_extract_call[varbit_field] = call;
}

bool CollectVarbitExtract::preorder(const IR::MethodCallExpression* call) {
    if (auto state = findContext<IR::ParserState>()) {
        if (auto method = call->method->to<IR::Member>()) {
            if (method->member == "extract") {
                auto dest = (*call->arguments)[0]->expression;
                auto hdr_type = dest->type->to<IR::Type_Header>();

                if (call->arguments->size() == 2) {
                    auto varsize = (*call->arguments)[1]->expression;

                    LOG3("found varbit in " << state->name);
                    LOG3("varsize is " << varsize);

                    enumerate_varbit_field_values(call, state, varsize, hdr_type);

                    auto parser = findContext<IR::BFN::TnaParser>();
                    state_to_parser[state] = parser;
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

Modifier::profile_t RewriteVarbitExtract::init_apply(const IR::Node* root) {
    for (auto& pv : cve.state_to_varbit_field)
        create_branches(pv.first, pv.second);

    return Modifier::init_apply(root);
}

bool RewriteVarbitExtract::preorder(IR::P4Program* program) {
    for (auto& kv : varbit_field_to_header_types) {
        for (auto& lt : kv.second)
            program->objects.insert(program->objects.begin(), lt.second);
    }

    // TODO add these to the header decl section instead of
    // prepending to beginning of program

    return true;
}

bool RewriteVarbitExtract::contains_varbit_header(IR::Type_Struct* type_struct) {
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

bool RewriteVarbitExtract::preorder(IR::Type_Struct* type_struct) {
    if (contains_varbit_header(type_struct)) {
        for (auto& kv : varbit_field_to_header_types) {
            for (auto& lt : kv.second) {
                auto type = lt.second;
                auto field = new IR::StructField(create_instance_name(type->name),
                                     new IR::Type_Name(type->name));
                type_struct->fields.push_back(field);
            }
        }
    }

    return true;
}

bool RewriteVarbitExtract::preorder(IR::Type_Header* header) {
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

IR::ParserState*
RewriteVarbitExtract::create_branch_state(const IR::BFN::TnaParser* parser,
        const IR::Expression* select, const IR::StructField* varbit_field, unsigned length) {
    IR::IndexedVector<IR::StatOrDecl> statements;

    auto header = varbit_field_to_header_types[varbit_field][length];

    auto call = cve.varbit_field_to_extract_call.at(varbit_field);
    auto path = (*call->arguments)[0]->expression->to<IR::Member>()
                                     ->expr->to<IR::PathExpression>();

    auto extract = create_extract_statement(parser, path, create_instance_name(header->name));
    statements.push_back(extract);

    cstring name = "parse_" + varbit_field->name + "_" + cstring::to_cstring(length) + "b";
    auto branch_state = new IR::ParserState(name, statements, select);

    LOG3("create state " << name);

    return branch_state;
}

void RewriteVarbitExtract::create_branches(const IR::ParserState* state,
                                         const IR::StructField* varbit_field) {
    ordered_map<unsigned, const IR::ParserState*> match_to_branch_state;

    auto parser = cve.state_to_parser.at(state);
    auto orig_header = cve.state_to_varbit_header.at(state);

    auto& value_map = cve.varbit_field_to_compile_time_constants.at(varbit_field);

    cstring no_option_state_name = "parse_" + varbit_field->name + "_no_option";

    for (auto& kv : value_map) {
        auto match = kv.first;
        auto length = kv.second->asUnsigned();

        if (length) {
            auto header = create_varbit_header_type(orig_header->name, varbit_field, length);
            varbit_field_to_header_types[varbit_field][length] = header;

            auto path = new IR::PathExpression(no_option_state_name);
            auto branch_state = create_branch_state(parser, path, varbit_field, length);
            match_to_branch_state[match] = branch_state;
        } else {
            IR::IndexedVector<IR::StatOrDecl> statements;
            auto no_option_state = new IR::ParserState(no_option_state_name, statements,
                                                       state->selectExpression);
            match_to_branch_state[match] = no_option_state;
        }
    }

    state_to_branches[state] = match_to_branch_state;
}

bool RewriteVarbitExtract::preorder(IR::BFN::TnaParser* parser) {
    auto orig = getOriginal<IR::P4Parser>();

    bool has_varbit = false;

    for (auto& kv : cve.state_to_parser) {
        if (kv.second == orig) {
            has_varbit = true;
            break;
        }
    }

    if (!has_varbit)
        return false;

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

bool RewriteVarbitExtract::preorder(IR::ParserState* state) {
    auto orig = getOriginal<IR::ParserState>();

    if (!state_to_branches.count(orig))
        return true;

    auto& match_to_branch_state = state_to_branches.at(orig);

    IR::Vector<IR::SelectCase> select_cases;

    auto varbit_field = cve.state_to_varbit_field.at(orig);
    auto var = cve.state_to_length_var.at(orig);
    unsigned var_bitwidth = var->type->width_bits();
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
    select_on.push_back(var);

    auto select = new IR::SelectExpression(new IR::ListExpression(select_on), select_cases);
    state->selectExpression = select;

    return true;
}

bool RewriteVarbitExtract::preorder(IR::MethodCallExpression* call) {
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

    return false;
}

static IR::MethodCallStatement*
create_emit_statement(const IR::Member* method, const IR::Expression* path, cstring header) {
    auto args = new IR::Vector<IR::Argument>(
        { new IR::Argument(new IR::Member(path, header)) } );
    auto call = new IR::MethodCallExpression(method, args);
    auto emit = new IR::MethodCallStatement(call);
    return emit;
}

bool RewriteVarbitExtract::preorder(IR::BlockStatement* block) {
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

    return false;
}

IR::Node* RewriteParserVerify::preorder(IR::MethodCallStatement* stmt) {
    auto state = findContext<IR::ParserState>();
    if (state) {
        auto call = stmt->methodCall;

        if (auto path = call->method->to<IR::PathExpression>()) {
            if (path->path->name == "verify") {
                auto verify_expr = (*call->arguments)[0]->expression;

                for (auto& kv : cve.state_to_varbit_header) {
                    auto header = kv.second;

                    FindLengthEncodingVar find_var(header);
                    verify_expr->apply(find_var);

                    if (find_var.rv.size() == 1) {
                        for (auto& sv : cve.state_to_length_var) {
                            if (sv.second->equiv(*(find_var.rv[0]))) {
                                LOG4("remove " << stmt << " absorbed in varbit rewrite");
                                return nullptr;
                            }
                        }
                    }
                }
            }
        }
    }

    return stmt;
}
