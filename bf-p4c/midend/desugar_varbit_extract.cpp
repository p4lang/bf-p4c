#include "desugar_varbit_extract.h"
#include "frontends/common/constantFolding.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/device.h"
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
        std::map<unsigned, unsigned>& match_to_length,
        std::map<unsigned, unsigned>& length_to_match,
        std::set<unsigned>& reject_matches,
        cstring header_name) {
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
    bool too_many_branches = false;

    for (unsigned long i = 0; i < (1UL << var_bitwidth); i++) {
        if (is_legal_runtime_value(state, encode_var, i)) {
            auto c = evaluate(varsize_expr, encode_var, i);

            auto varbit_field_size = varbit_field->type->to<IR::Type_Varbits>()->size;
            if (!c->fitsInt() || c->asInt() > varbit_field_size) {
                reject_matches.insert(i);
                LOG4("compile time constant exceeds varbit field size: " << c->asUnsigned());
            } else {
                check_compile_time_constant(c, call, varbit_field_size, true);
                match_to_length[i] = c->asUnsigned();
                length_to_match[c->asUnsigned()] = i;
            }
        } else {
            reject_matches.insert(i);
        }

        branches_needed++;

        if (branches_needed > 1024) {
            too_many_branches = true;
            break;
        }
    }

    if (too_many_branches) {
        ::fatal_error("Varbit extract requires too many parser branches to implement. "
                  "Consider rewriting the variable length expression to reduce "
                  "the number of possible runtime values: %1%", call);
        return false;
    }

    LOG2(varsize_expr << " needs " << branches_needed << " branches to implement");
    LOG2(varsize_expr << " evaluate to compile time constants:");

    for (auto& kv : match_to_length)
        LOG2(encode_var << " = " << kv.first << " : " << kv.second);

    for (auto& v : reject_matches)
        LOG2(encode_var << " = " << v << " : reject");
    varbit_hdr_instance_to_variable_state[header_name] = state;
    return true;
}

void CollectVarbitExtract::enumerate_varbit_field_values(
        const IR::MethodCallExpression* call,
        const IR::ParserState* state,
        const IR::Expression* varsize_expr,
        const IR::Type_Header* hdr_type,
        cstring headerName) {
    if (state_to_varbit_header.count(state)) {
        P4C_UNIMPLEMENTED("%1%: multiple varbit fields in a parser state"
                              " is currently unsupported", call);
    }


    const IR::StructField* varbit_field = nullptr;

    for (auto field : hdr_type->fields) {
        if (field->type->is<IR::Type::Varbits>()) {
            varbit_field = field;
            break;
        }
    }

    if (!varbit_field) return;
    varbit_hdr_instance_to_varbit_field[headerName] = varbit_field;
    const IR::Expression* encode_var = nullptr;
    std::map<unsigned, unsigned> match_to_length;
    std::map<unsigned, unsigned> length_to_match;
    std::set<unsigned> reject_matches;

    if (auto c = varsize_expr->to<IR::Constant>()) {
        auto varbit_field_size = varbit_field->type->to<IR::Type_Varbits>()->size;

        check_compile_time_constant(c, call, varbit_field_size);
        match_to_length[0] = c->asUnsigned();  // use 0 as key, but really don't care
        length_to_match[c->asUnsigned()] = 0;
        varbit_hdr_instance_to_constant_state[headerName][c->asUnsigned()] = state;
    } else {
        bool ok = enumerate_varbit_field_values(call, state, varbit_field, varsize_expr,
                            encode_var, match_to_length, length_to_match, reject_matches,
                            headerName);
        if (!ok) return;
    }

    state_to_varbit_header[state] = hdr_type;
    state_to_encode_var[state] = encode_var;
    state_to_match_to_length[state] = match_to_length;
    state_to_length_to_match[state] = length_to_match;
    state_to_reject_matches[state] = reject_matches;

    auto expr = (*call->arguments)[0]->expression;
    const IR::PathExpression* path = nullptr;
    if (expr->is<IR::Member>()) {
        path = (*call->arguments)[0]->expression->to<IR::Member>()
                                         ->expr->to<IR::PathExpression>();
    } else if (expr->is<IR::PathExpression>()) {
        path = expr->to<IR::PathExpression>();
    }

    varbit_field_to_extract_call_path[varbit_field] = path;

    state_to_header_instance[state] = headerName;
    header_type_to_varbit_field[hdr_type] = varbit_field;
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
        if (right->is<IR::BFN::ReinterpretCast>())
            right = right->to<IR::BFN::ReinterpretCast>()->expr;

        if (auto mc = right->to<IR::MethodCallExpression>()) {
            if (auto method = mc->method->to<IR::Member>()) {
                if (auto path = method->expr->to<IR::PathExpression>()) {
                    auto type = path->type->to<IR::Type_Extern>();
                    if (!type) return false;
                    if (type->name != "Checksum") return false;
                    if (method->member == "verify")
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
                auto expr = (*call->arguments)[0]->expression;

                if (call->arguments->size() == 2) {
                    auto varsize_expr = (*call->arguments)[1]->expression;

                    LOG3("found varbit in " << state->name);
                    LOG3("varsize expr is " << varsize_expr);

                    if (seen_varbit) {
                        P4C_UNIMPLEMENTED("%1%: multiple varbit fields in a parser state"
                              " is currently unsupported", call);
                    }
                    const IR::Type_Header* hdr_type = nullptr;
                    cstring headerName;

                    if (auto header = expr->to<IR::Member>()) {
                        hdr_type = header->type->to<IR::Type_Header>();
                        headerName = header->member;
                    } else if (auto headerPath = expr->to<IR::PathExpression>()) {
                        hdr_type = headerPath->type->to<IR::Type_Header>();
                        auto path = headerPath->path->to<IR::Path>();
                        headerName = path->name;
                    } else {
                        ::error("Unsupported header type %1%", expr);
                    }
                    enumerate_varbit_field_values(call, state, varsize_expr, hdr_type, headerName);

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
                                state_to_csum_add[state].insert(call);
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
typedef ordered_map<cstring,
             ordered_map<unsigned, IR::Type_Header*>> VarbitHeaderMap;

static void
create_varbit_header_type(const IR::Type_Header* orig_hdr, cstring orig_hdr_inst,
                          const IR::StructField* varbit_field, unsigned current_hdr_size,
                          unsigned varbit_field_size,
                          VarbitHeaderMap& varbit_hdr_instance_to_header_types) {
    if (!varbit_hdr_instance_to_header_types.count(orig_hdr_inst) ||
        !varbit_hdr_instance_to_header_types.at(orig_hdr_inst).count(varbit_field_size)) {
        cstring name = orig_hdr->name + "_" + orig_hdr_inst + "_" + varbit_field->name + "_"
                       + cstring::to_cstring(varbit_field_size) + "b_t";
        auto hdr = new IR::Type_Header(name);
        auto field_type = IR::Type::Bits::get(current_hdr_size);
        auto field = new IR::StructField("field", field_type);
        hdr->fields.push_back(field);
        varbit_hdr_instance_to_header_types[orig_hdr_inst][varbit_field_size] = hdr;
    }
}

Modifier::profile_t RewriteVarbitUses::init_apply(const IR::Node* root) {
    for (auto & hdr_len_state : cve.varbit_hdr_instance_to_constant_state) {
        // If the length is declared as a constant, the creation of branches
        // for each state should happen in the ascending order of the lengths
        unsigned prev_length = 0;
        auto varbit_field = cve.varbit_hdr_instance_to_varbit_field.at(hdr_len_state.first);
        for (auto len_state : hdr_len_state.second) {
             create_branches(len_state.second, varbit_field, prev_length);
             prev_length = len_state.first;
        }
    }
    for (auto& hdr_state : cve.varbit_hdr_instance_to_variable_state) {
        auto varbit_field = cve.varbit_hdr_instance_to_varbit_field.at(hdr_state.first);
        create_branches(hdr_state.second, varbit_field, 0);
    }
    return Modifier::init_apply(root);
}

static IR::MethodCallStatement*
create_extract_statement(const IR::BFN::TnaParser* parser,
                         const IR::PathExpression* path,
                         const IR::Type *type,
                         cstring header) {
    auto packetInParam = parser->tnaParams.at("pkt");
    auto method = new IR::Member(new IR::PathExpression(packetInParam), IR::ID("extract"));
    auto typeArgs = new IR::Vector<IR::Type>({ type });
    auto args = new IR::Vector<IR::Argument>(
         { new IR::Argument(new IR::Member(type, path, header)) });
    auto *callExpr = new IR::MethodCallExpression(method, typeArgs, args);
    return new IR::MethodCallStatement(callExpr);
}

static IR::MethodCallStatement*
create_add_statement(const IR::Member* method,
                     const IR::PathExpression* path,
                     const IR::Type_Header* header) {
    auto listVec = IR::Vector<IR::Expression>();
    auto headerName = create_instance_name(header->name);
    for (auto f : header->fields) {
        listVec.push_back(new IR::Member(f->type, new IR::Member(path, headerName), f->name));
    }
    auto args = new IR::Vector<IR::Argument>({ new IR::Argument(
                new IR::ListExpression(listVec))});
    auto typeArgs = new IR::Vector<IR::Type>({ args->at(0)->expression->type });
    auto addCall = new IR::MethodCallExpression(method, typeArgs, args);
    return new IR::MethodCallStatement(addCall);
}

const IR::ParserState*
RewriteVarbitUses::create_branch_state(const IR::BFN::TnaParser* parser,
        const IR::ParserState* state, const IR::Expression* select,
        const IR::StructField* varbit_field, unsigned length, cstring name) {
    for (auto& kv : state_to_branch_states) {
        auto p = cve.state_to_parser.at(kv.first);
        if (p == parser) {
            for (auto s : kv.second) {
                if (name == s.second->name)
                    return s.second;
            }
        }
    }

    IR::IndexedVector<IR::StatOrDecl> statements;
    auto hdr_instance = cve.state_to_header_instance.at(state);
    auto path = cve.varbit_field_to_extract_call_path.at(varbit_field);
    // Extract all the headers in map varbit_hdr_instance_to_header_types until
    // key is greater than length
    for (auto &header_to_length : varbit_hdr_instance_to_header_types[hdr_instance]) {
        auto header_length = header_to_length.first;
        if (header_length > length)
            break;
        auto header = header_to_length.second;
        auto varbit_hdr_inst = create_instance_name(header->name);
        auto extract = create_extract_statement(parser, path, header, varbit_hdr_inst);
        statements.push_back(extract);
        LOG3("Added extract statement for header " << header->name << " in state "
              << name);
        if (cve.state_to_csum_add.count(state)) {
            for (auto call : cve.state_to_csum_add.at(state)) {
                auto method = call->method->to<IR::Member>();
                statements.push_back(create_add_statement(method, path, header));
            }
        }
    }
    auto branch_state = new IR::ParserState(name, statements, select);

    LOG3("create state " << name);

    return branch_state;
}

const IR::ParserState*
RewriteVarbitUses::create_end_state(const IR::BFN::TnaParser* parser,
                                    const IR::ParserState* state, cstring name,
                                    const IR::StructField* varbit_field,
                                    const IR::Type_Header* orig_header,
                                    cstring orig_hdr_name) {
    for (auto& kv : state_to_branch_states) {
        auto p = cve.state_to_parser.at(kv.first);
        if (p == parser) {
            for (auto s : kv.second) {
                if (name == s.second->name)
                    return s.second;
            }
        }
    }

    for (auto& kv : state_to_end_state) {
        auto p = cve.state_to_parser.at(kv.first);
        if (p == parser) {
            if (name == kv.second->name)
                return kv.second;
        }
    }

    // If varbit field is in the middle of the header type, we need to create
    // a seperate header type for the fields that follow the varbit field.
    //
    // header xxx_t {
    //   bit<4>   a;
    //   bit<4>   b;
    //   varbit<320> c;
    //   bit<32>  x;
    //   bit<16>  y;
    // }

    cstring post_hdr_name = orig_hdr_name + "_" + varbit_field->name + "_post_t";
    auto post_hdr = new IR::Type_Header(post_hdr_name);

    bool seen_varbit = false;
    for (auto field : orig_header->fields) {
        if (seen_varbit)
            post_hdr->fields.push_back(field);

        if (field->type->is<IR::Type_Varbits>())
            seen_varbit = true;
    }

    IR::IndexedVector<IR::StatOrDecl> statements;

    auto path = cve.varbit_field_to_extract_call_path.at(varbit_field);

    if (post_hdr->fields.size()) {
        varbit_field_to_post_header_type[varbit_field] = post_hdr;

        auto post_hdr_inst = create_instance_name(post_hdr_name);
        auto extract = create_extract_statement(parser, path, post_hdr, post_hdr_inst);

        statements.push_back(extract);
    }

    if (cve.state_to_csum_add.count(state)) {
        for (auto call : cve.state_to_csum_add.at(state)) {
            auto method = call->method->to<IR::Member>();
            statements.push_back(create_add_statement(method, path, post_hdr));
        }
    }

    if (cve.state_to_csum_verify.count(state))
        statements.push_back(cve.state_to_csum_verify.at(state));

    return new IR::ParserState(name, statements, state->selectExpression);
}

void RewriteVarbitUses::create_branches(const IR::ParserState* state,
                                        const IR::StructField* varbit_field,
                                        unsigned prev_length) {
    ordered_map<unsigned, const IR::ParserState*> length_to_branch_state;

    auto parser = cve.state_to_parser.at(state);
    auto orig_hdr = cve.state_to_varbit_header.at(state);
    auto orig_hdr_inst = cve.state_to_header_instance.at(state);
    auto encode_var = cve.state_to_encode_var.at(state);

    auto& value_map = cve.state_to_length_to_match.at(state);

    cstring no_option_state_name = "parse_" + orig_hdr_inst + "_" + varbit_field->name + "_end";
    const IR::ParserState* no_option_state = nullptr;
    for (auto& kv : value_map) {
        auto length = kv.first;

        if (length) {
            create_varbit_header_type(orig_hdr, orig_hdr_inst,
                                      varbit_field, length-prev_length,
                                      length,
                                      varbit_hdr_instance_to_header_types);
            prev_length = length;

            const IR::Expression* select = nullptr;

            if (encode_var)
                select = new IR::PathExpression(no_option_state_name);
            else  // unconditional transition (varsize expr is constant)
                select = state->selectExpression;

            cstring name = "parse_" + orig_hdr_inst + "_" + varbit_field->name + "_" +
                    cstring::to_cstring(length) + "b";

            auto branch_state = create_branch_state(parser, state, select,
                                                    varbit_field, length, name);

            length_to_branch_state[length] = branch_state;
        } else {
            no_option_state = create_end_state(parser, state, no_option_state_name,
                                               varbit_field, orig_hdr, orig_hdr_inst);

            length_to_branch_state[length] = no_option_state;
        }
    }

    if (!no_option_state) {
        no_option_state = create_end_state(parser, state, no_option_state_name,
                                           varbit_field, orig_hdr, orig_hdr_inst);
    }

    state_to_branch_states[state] = length_to_branch_state;
    state_to_end_state[state] = no_option_state;
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

    std::set<const IR::ParserState*> states;

    for (auto& kv : state_to_branch_states) {
        if (cve.state_to_parser.at(kv.first) == orig) {
            for (auto& ms : kv.second)
                states.insert(ms.second);
        }
    }

    for (auto& kv : state_to_end_state) {
        if (cve.state_to_parser.at(kv.first) == orig) {
            states.insert(kv.second);
        }
    }

    for (auto s : states)
        parser->states.push_back(s);

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
    IR::IndexedVector<IR::StatOrDecl> components;
    for (auto a : orig->components) {
        // Remove verify call from original state
        if (cve.state_to_csum_verify.count(orig) &&
            cve.state_to_csum_verify.at(orig)->equiv(*a)) {
            continue;
        // Replace varbit header setInvalid
        } else if (auto assign = a->to<IR::AssignmentStatement>()) {
            find_and_replace_setinvalid(assign, components);
        }
        components.push_back(a);
    }
    state->components = components;

    if (!state_to_branch_states.count(orig))
        return true;

    auto& length_to_branch_state = state_to_branch_states.at(orig);
    auto& length_to_match = cve.state_to_length_to_match.at(orig);

    IR::Vector<IR::SelectCase> select_cases;

    auto encode_var = cve.state_to_encode_var.at(orig);

    if (encode_var) {
        unsigned var_bitwidth = encode_var->type->width_bits();
        unsigned var_mask = (1 << var_bitwidth) - 1;

        for (auto& ms : length_to_branch_state) {
            auto length = ms.first;
            auto match = length_to_match.at(length);
            auto next_state = ms.second;

            auto select_case = create_select_case(var_bitwidth, match, var_mask, next_state->name);
            select_cases.push_back(select_case);
        }

        for (auto reject : cve.state_to_reject_matches.at(orig)) {
            auto select_case = create_select_case(var_bitwidth, reject, var_mask, "reject");
            select_cases.push_back(select_case);
        }

        IR::Vector<IR::Expression> select_on;
        select_on.push_back(encode_var);

        auto select = new IR::SelectExpression(new IR::ListExpression(select_on), select_cases);
        state->selectExpression = select;
    }  else {  // unconditional transition (varsize expr is constant)
        BUG_CHECK(length_to_branch_state.size() == 1, "more than one unconditional branch?");

        auto next_state = length_to_branch_state.begin()->second;
        auto path = new IR::PathExpression(next_state->name);
        state->selectExpression = path;
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
create_emit_statement(const IR::Member* method, const IR::Type *type,
                      const IR::Expression* path, cstring header) {
    auto typeArgs = new IR::Vector<IR::Type>({ type });
    auto args = new IR::Vector<IR::Argument>(
        { new IR::Argument(new IR::Member(type, path, header)) } );
    auto call = new IR::MethodCallExpression(method, typeArgs, args);
    auto emit = new IR::MethodCallStatement(call);
    return emit;
}

IR::AssignmentStatement* create_valid_statement(const IR::Type_Header* hdr,
                                                 const IR::Expression* path,
                                                 bool value) {
    auto hdr_expr = new IR::Member(hdr, path, create_instance_name(hdr->name));
    auto left = new IR::Member(IR::Type::Bits::get(1), hdr_expr, "$valid");
    auto right = new IR::Constant(IR::Type::Bits::get(1), value);
    return new IR::AssignmentStatement(left, right);
}

void RewriteVarbitUses::find_and_replace_setinvalid(const IR::AssignmentStatement* assign,
                                                    IR::IndexedVector<IR::StatOrDecl>& component) {
    auto left = assign->left->to<IR::Member>();
    if (!left || left->member != "$valid")
        return;
    auto right = assign->right->to<IR::Constant>();
    if (!right)
        return;
    if (auto expr = left->expr->to<IR::Member>()) {
        if (varbit_hdr_instance_to_header_types.count(expr->member)) {
            if (right->asInt() == 1) {
                ::error("Cannot set a header %1% with varbit field as valid", expr);
            }
            for (auto &hdr : varbit_hdr_instance_to_header_types.at(expr->member)) {
                component.push_back(create_valid_statement(hdr.second, expr->expr, false));
            }
            auto varbit_field = cve.header_type_to_varbit_field.at(
                                              expr->type->to<IR::Type_Header>());
            if (varbit_field_to_post_header_type.count(varbit_field)) {
                component.push_back(create_valid_statement(
                       varbit_field_to_post_header_type.at(varbit_field), expr->expr, false));
            }
        }
    }
}

bool RewriteVarbitUses::preorder(IR::BlockStatement* block) {
    auto deparser = findContext<IR::BFN::TnaDeparser>();
    IR::IndexedVector<IR::StatOrDecl> components;
    for (auto stmt : block->components) {
        components.push_back(stmt);
        if (deparser) {
            if (auto mc = stmt->to<IR::MethodCallStatement>()) {
                auto mce = mc->methodCall;

                if (auto method = mce->method->to<IR::Member>()) {
                    if (method->member == "emit") {
                        auto arg = (*mce->arguments)[0];
                        auto type = arg->expression->type->to<IR::Type_Header>();

                        if (cve.header_type_to_varbit_field.count(type)) {
                            auto varbit_field = cve.header_type_to_varbit_field.at(type);
                            auto path = arg->expression->to<IR::Member>()->expr;
                            auto instance =  arg->expression->to<IR::Member>()->member;
                            for (auto& kv : varbit_hdr_instance_to_header_types.at(instance)) {
                                auto emit = create_emit_statement(method, kv.second, path,
                                                   create_instance_name(kv.second->name));
                                components.push_back(emit);
                            }

                            if (varbit_field_to_post_header_type.count(varbit_field)) {
                                auto type = varbit_field_to_post_header_type.at(varbit_field);
                                auto emit = create_emit_statement(method, type, path,
                                                   create_instance_name(type->name));
                                components.push_back(emit);
                            }
                        }
                    }
                }
            }
        } else {
            // Find setInvalid
            if (auto assign = stmt->to<IR::AssignmentStatement>()) {
                find_and_replace_setinvalid(assign, components);
            }
        }
    }
    if (components.size())
        block->components = components;

    return true;
}

IR::Vector<IR::Expression>
RewriteVarbitUses::filter_post_header_fields(const IR::Vector<IR::Expression>& components) {
    IR::Vector<IR::Expression> filtered;

    for (auto c : components) {
        if (auto member = c->to<IR::Member>()) {
            if (auto type = member->expr->type->to<IR::Type_Header>()) {
                if (cve.header_type_to_varbit_field.count(type)) {
                    auto varbit_field = cve.header_type_to_varbit_field.at(type);

                    if (varbit_field_to_post_header_type.count(varbit_field)) {
                        auto post = varbit_field_to_post_header_type.at(varbit_field);

                        bool is_in_post_header = false;

                        for (auto field : post->fields) {
                            if (field->name == member->member) {
                                is_in_post_header = true;
                                break;
                            }
                        }

                        if (is_in_post_header)
                            continue;
                    }
                }
            }
        }

        filtered.push_back(c);
    }

    return filtered;
}

bool RewriteVarbitUses::preorder(IR::ListExpression* list) {
    auto deparser = findContext<IR::BFN::TnaDeparser>();
    auto mc = findContext<IR::MethodCallExpression>();
    IR::Vector<IR::Expression> components;

    bool has_varbit = false;

    IR::Vector<IR::Type> varbit_types;

    if (!mc) return false;

    for (auto c : list->components) {
        if (auto member = c->to<IR::Member>()) {
            if (member->type->is<IR::Type_Varbits>()) {
                if (has_varbit)
                    ::error("More than one varbit expression in %1%", list);
                if (deparser) {
                    has_varbit = true;
                    auto path = member->expr->to<IR::Member>();

                    for (auto& kv : varbit_hdr_instance_to_header_types.at(path->member)) {
                        auto hdr = kv.second;
                        auto field = hdr->fields[0];

                        varbit_types.push_back(field->type);

                        auto member = new IR::Member(path->expr, create_instance_name(hdr->name));
                        auto hdr_field = new IR::Member(member, "field");

                        components.push_back(hdr_field);
                    }
                } else if (auto state = findOrigCtxt<IR::ParserState>()) {
                    if (cve.state_to_csum_add.count(state)) {
                        for (auto call : cve.state_to_csum_add.at(state)) {
                            if (call->equiv(*mc)) {
                                has_varbit = true;
                                break;
                            }
                        }
                    }
                }

                continue;
            }
        }

        components.push_back(c);
    }

    if (has_varbit) {
        list->components = components;

        if (auto tuple = list->type->to<IR::Type_BaseList>()) {
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

                        bool filter = false;

                        for (auto& kv : cve.header_type_to_varbit_field) {
                            if (kv.first->name == tuple_name) {
                                filter = true;
                                break;
                            }
                        }

                        // if the tuple type is the original header type
                        // we need to remove the fields after the varbit field from the
                        // tuple as they have been moved into its own header type and
                        // instance

                        if (filter)
                            list->components = filter_post_header_fields(components);
                    }
                } else if (type_args.size() > 1) {
                    ::error("More than one type in %1%", list);
                }
            }
        }
    }

    return true;
}

bool RewriteVarbitUses::preorder(IR::Member* member) {
    if (auto type = member->expr->type->to<IR::Type_Header>()) {
        if (cve.header_type_to_varbit_field.count(type)) {
            auto varbit_field = cve.header_type_to_varbit_field.at(type);

            if (varbit_field_to_post_header_type.count(varbit_field)) {
                auto post = varbit_field_to_post_header_type.at(varbit_field);

                bool is_in_post_header = false;

                for (auto field : post->fields) {
                    if (field->name == member->member) {
                        is_in_post_header = true;
                        break;
                    }
                }

                // rewrite path to fields that are after the varbit field
                // these fields have been moved into its own header type and instance

                if (is_in_post_header) {
                    auto path = member->expr->to<IR::Member>();
                    auto post_hdr = varbit_field_to_post_header_type.at(varbit_field);
                    auto post_hdr_inst = create_instance_name(post_hdr->name);
                    member->expr = new IR::Member(path->expr, post_hdr_inst);
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
    for (auto& kv : rvu.varbit_hdr_instance_to_header_types) {
        for (auto& lt : kv.second)
            program->objects.insert(program->objects.begin(), lt.second);
    }

    for (auto& kv : rvu.varbit_field_to_post_header_type)
        program->objects.insert(program->objects.begin(), kv.second);

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
        for (auto& kv : rvu.varbit_hdr_instance_to_header_types) {
            for (auto& lt : kv.second) {
                auto type = lt.second;
                auto field = new IR::StructField(create_instance_name(type->name),
                                     new IR::Type_Name(type->name));
                type_struct->fields.push_back(field);
            }
        }

        for (auto& kv : rvu.varbit_field_to_post_header_type) {
            auto type = kv.second;
            auto field = new IR::StructField(create_instance_name(type->name),
                                     new IR::Type_Name(type->name));
            type_struct->fields.push_back(field);
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
            if (field->type->is<IR::Type::Varbits>())
                break;

            fields.push_back(field);
        }

        header->fields = fields;
    }

    return true;
}
