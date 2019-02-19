#include "v1_converters.h"
#include "v1_program_structure.h"
#include "lib/ordered_map.h"

namespace BFN {

namespace V1 {
//////////////////////////////////////////////////////////////////////////////////////////////

const IR::Node* ControlConverter::postorder(IR::Declaration_Instance* node) {
    return substitute<IR::Declaration_Instance>(node); }

const IR::Node* ControlConverter::postorder(IR::MethodCallStatement* node) {
    return substitute<IR::MethodCallStatement>(node); }

const IR::Node* ControlConverter::postorder(IR::Property* node) {
    return substitute<IR::Property>(node); }

const IR::Node* ParserConverter::postorder(IR::AssignmentStatement* node) {
    return substitute<IR::AssignmentStatement>(node); }

const IR::Node* ParserConverter::postorder(IR::Member* node) {
    return substitute<IR::Member>(node); }

const IR::Node* IngressControlConverter::preorder(IR::P4Control* node) {
    auto params = node->type->getApplyParameters();
    BUG_CHECK(params->size() == 3, "%1% Expected 3 parameters for ingress", node);

    auto* paramList = new IR::ParameterList;
    ordered_map<cstring, cstring> tnaParams;

    auto* headers = params->parameters.at(0);
    tnaParams.emplace("hdr", headers->name);
    paramList->push_back(headers);

    auto* meta = params->parameters.at(1);
    tnaParams.emplace("md", meta->name);
    paramList->push_back(meta);

    // add ig_intr_md
    auto path = new IR::Path("ingress_intrinsic_metadata_t");
    auto type = new IR::Type_Name(path);
    auto param = new IR::Parameter("ig_intr_md", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md", param->name);
    paramList->push_back(param);

    // add ig_intr_md_from_prsr
    path = new IR::Path("ingress_intrinsic_metadata_from_parser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_from_prsr", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md_from_prsr", param->name);
    paramList->push_back(param);

    // add ig_intr_md_for_dprsr
    path = new IR::Path("ingress_intrinsic_metadata_for_deparser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_dprsr", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md_for_dprsr", param->name);
    paramList->push_back(param);

    // add ig_intr_md_for_tm
    path = new IR::Path("ingress_intrinsic_metadata_for_tm_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md_for_tm", param->name);
    paramList->push_back(param);

    // add compiler generated struct
    path = new IR::Path("compiler_generated_metadata_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("compiler_generated_meta", IR::Direction::InOut, type);
    tnaParams.emplace("compiler_generated_meta", param->name);
    paramList->push_back(param);

    auto controlType = new IR::Type_Control("ingress", paramList);

    auto controlLocals = new IR::IndexedVector<IR::Declaration>();
    controlLocals->append(structure->ingressDeclarations);
    controlLocals->append(node->controlLocals);

    auto result = new IR::BFN::TnaControl(node->srcInfo, "ingress", controlType,
                                                   node->constructorParams, *controlLocals,
                                                   node->body, tnaParams, INGRESS);
    return result;
}

const IR::Node* EgressControlConverter::preorder(IR::P4Control *node) {
    auto params = node->type->getApplyParameters();
    BUG_CHECK(params->size() == 3, "%1% Expected 3 parameters for egress", node);

    auto* paramList = new IR::ParameterList;
    ordered_map<cstring, cstring> tnaParams;

    auto* headers = params->parameters.at(0);
    tnaParams.emplace("hdr", headers->name);
    paramList->push_back(headers);

    auto* meta = params->parameters.at(1);
    tnaParams.emplace("md", meta->name);
    paramList->push_back(meta);

    // add eg_intr_md
    auto path = new IR::Path("egress_intrinsic_metadata_t");
    auto type = new IR::Type_Name(path);
    IR::Parameter* param = nullptr;
    if (structure->backward_compatible)
        param = new IR::Parameter("eg_intr_md", IR::Direction::InOut, type);
    else
        param = new IR::Parameter("eg_intr_md", IR::Direction::In, type);
    tnaParams.emplace("eg_intr_md", param->name);
    paramList->push_back(param);

    // add eg_intr_md_from_prsr
    path = new IR::Path("egress_intrinsic_metadata_from_parser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_from_prsr", IR::Direction::In, type);
    tnaParams.emplace("eg_intr_md_from_prsr", param->name);
    paramList->push_back(param);

    // add eg_intr_md_for_dprsr
    path = new IR::Path("egress_intrinsic_metadata_for_deparser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_dprsr", IR::Direction::InOut, type);
    tnaParams.emplace("eg_intr_md_for_dprsr", param->name);
    paramList->push_back(param);

    // add eg_intr_md_for_oport
    path = new IR::Path("egress_intrinsic_metadata_for_output_port_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_oport", IR::Direction::InOut, type);
    tnaParams.emplace("eg_intr_md_for_oport", param->name);
    paramList->push_back(param);

    /// XXX(hanw) following two parameters are added and should be removed after
    /// the defuse analysis is moved to the midend and bridge metadata is implemented.

    // add ig_intr_md_from_prsr
    path = new IR::Path("ingress_intrinsic_metadata_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md", param->name);
    paramList->push_back(param);

    // add ig_intr_md_for_tm
    path = new IR::Path("ingress_intrinsic_metadata_for_tm_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md_for_tm", param->name);
    paramList->push_back(param);

    // add ig_intr_md_from_prsr
    path = new IR::Path("ingress_intrinsic_metadata_from_parser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_from_prsr", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md_from_prsr", param->name);
    paramList->push_back(param);

    // add compiler generated struct
    path = new IR::Path("compiler_generated_metadata_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("compiler_generated_meta", IR::Direction::InOut, type);
    tnaParams.emplace("compiler_generated_meta", param->name);
    paramList->push_back(param);

    auto controlType = new IR::Type_Control("egress", paramList);

    auto controlLocals = new IR::IndexedVector<IR::Declaration>();
    controlLocals->append(structure->egressDeclarations);
    controlLocals->append(node->controlLocals);

    auto result = new IR::BFN::TnaControl(node->srcInfo, "egress", controlType,
                                                   node->constructorParams, *controlLocals,
                                                   node->body, tnaParams, EGRESS);
    return result;
}

const IR::Node* IngressDeparserConverter::preorder(IR::P4Control* node) {
    auto deparser = node->apply(cloner);
    auto params = deparser->type->getApplyParameters();
    BUG_CHECK(params->size() == 2, "%1% Expected 2 parameters for deparser", deparser);

    auto* paramList = new IR::ParameterList;
    ordered_map<cstring, cstring> tnaParams;

    auto* packetOut = params->parameters.at(0);
    tnaParams.emplace("pkt", packetOut->name);
    paramList->push_back(packetOut);

    // add header
    auto hdr = deparser->getApplyParameters()->parameters.at(1);
    auto param = new IR::Parameter(hdr->name, hdr->annotations,
                                   IR::Direction::InOut, hdr->type);
    tnaParams.emplace("hdr", param->name);
    paramList->push_back(param);

    // add metadata
    CHECK_NULL(structure->user_metadata);
    auto meta = structure->user_metadata;
    param = new IR::Parameter(meta->name, meta->annotations,
                              IR::Direction::In, meta->type);
    tnaParams.emplace("md", param->name);
    paramList->push_back(param);

    // add deparser intrinsic metadata
    auto path = new IR::Path("ingress_intrinsic_metadata_for_deparser_t");
    auto type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_dprsr", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md_for_dprsr", param->name);
    paramList->push_back(param);

    // add intrinsic metadata
    path = new IR::Path("ingress_intrinsic_metadata_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md", param->name);
    paramList->push_back(param);

    // add compiler generated struct
    path = new IR::Path("compiler_generated_metadata_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("compiler_generated_meta", IR::Direction::InOut, type);
    tnaParams.emplace("compiler_generated_meta", param->name);
    paramList->push_back(param);

    auto controlType = new IR::Type_Control("ingressDeparserImpl", paramList);

    auto controlLocals = new IR::IndexedVector<IR::Declaration>();
    controlLocals->append(structure->ingressDeparserDeclarations);
    controlLocals->append(node->controlLocals);

    auto statements = new IR::IndexedVector<IR::StatOrDecl>();
    statements->append(structure->ingressDeparserStatements);
    statements->append(deparser->body->components);
    auto body = new IR::BlockStatement(deparser->body->srcInfo, *statements);

    auto result = new IR::BFN::TnaDeparser(deparser->srcInfo, "ingressDeparserImpl",
                                                   controlType, deparser->constructorParams,
                                                   *controlLocals, body, tnaParams, INGRESS);
    return result;
}

const IR::Node* EgressDeparserConverter::preorder(IR::P4Control* node) {
    /**
     * create clone for all path expressions in the egress deparser.
     * Otherwise, resolveReference will fail because the path expression may reference
     * to a type in another control block.
     */
    auto deparser = node->apply(cloner);

    auto params = deparser->type->getApplyParameters();
    BUG_CHECK(params->size() == 2, "%1% Expected 2 parameters for deparser", deparser);

    auto* paramList = new IR::ParameterList;
    ordered_map<cstring, cstring> tnaParams;

    auto* packetOut = params->parameters.at(0);
    tnaParams.emplace("pkt", packetOut->name);
    paramList->push_back(packetOut);

    // add header
    auto hdr = deparser->getApplyParameters()->parameters.at(1);
    auto param = new IR::Parameter(hdr->name, hdr->annotations,
                                   IR::Direction::InOut, hdr->type);
    tnaParams.emplace("hdr", param->name);
    paramList->push_back(param);

    // add metadata
    CHECK_NULL(structure->user_metadata);
    auto meta = structure->user_metadata;
    param = new IR::Parameter(meta->name, meta->annotations,
                              IR::Direction::In, meta->type);
    tnaParams.emplace("md", param->name);
    paramList->push_back(param);

    // add eg_intr_md_for_dprsr
    auto path = new IR::Path("egress_intrinsic_metadata_for_deparser_t");
    auto type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_dprsr", IR::Direction::In, type);
    tnaParams.emplace("eg_intr_md_for_dprsr", param->name);
    paramList->push_back(param);

    // add eg_intr_md_from_prsr
    path = new IR::Path("egress_intrinsic_metadata_from_parser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_from_prsr", IR::Direction::In, type);
    tnaParams.emplace("eg_intr_md_from_prsr", param->name);
    paramList->push_back(param);

    // add eg_intr_md
    path = new IR::Path("egress_intrinsic_metadata_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md", IR::Direction::In, type);
    tnaParams.emplace("eg_intr_md", param->name);
    paramList->push_back(param);

    // add ig_intr_md
    path = new IR::Path("ingress_intrinsic_metadata_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md", param->name);
    paramList->push_back(param);

    // add ig_intr_md_for_tm
    path = new IR::Path("ingress_intrinsic_metadata_for_tm_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md_for_tm", param->name);
    paramList->push_back(param);

    // add compiler generated struct
    path = new IR::Path("compiler_generated_metadata_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("compiler_generated_meta", IR::Direction::InOut, type);
    tnaParams.emplace("compiler_generated_meta", param->name);
    paramList->push_back(param);

    auto controlType = new IR::Type_Control("egressDeparserImpl", paramList);

    auto controlLocals = new IR::IndexedVector<IR::Declaration>();
    controlLocals->append(structure->egressDeparserDeclarations);
    controlLocals->append(node->controlLocals);

    auto statements = new IR::IndexedVector<IR::StatOrDecl>();
    statements->append(structure->egressDeparserStatements);
    statements->append(deparser->body->components);
    auto body = new IR::BlockStatement(deparser->body->srcInfo, *statements);

    auto result = new IR::BFN::TnaDeparser(deparser->srcInfo, "egressDeparserImpl",
                                                   controlType, deparser->constructorParams,
                                                   *controlLocals, body, tnaParams, EGRESS);
    return result;
}

const IR::Node* IngressParserConverter::postorder(IR::P4Parser *node) {
    auto parser = node->apply(cloner);
    auto params = parser->type->getApplyParameters();
    BUG_CHECK(params->size() == 4, "%1%: Expected 4 parameters for parser", parser);

    auto* paramList = new IR::ParameterList;
    ordered_map<cstring, cstring> tnaParams;

    auto* packetIn = params->parameters.at(0);
    tnaParams.emplace("pkt", packetIn->name);
    paramList->push_back(packetIn);

    auto* headers = params->parameters.at(1);
    tnaParams.emplace("hdr", headers->name);
    paramList->push_back(headers);

    auto* meta = parser->getApplyParameters()->parameters.at(2);
    auto* param = new IR::Parameter(meta->name, meta->annotations,
                                    IR::Direction::Out, meta->type);
    tnaParams.emplace("md", meta->name);
    paramList->push_back(param);

    // add ig_intr_md
    auto path = new IR::Path("ingress_intrinsic_metadata_t");
    auto type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md", IR::Direction::Out, type);
    tnaParams.emplace("ig_intr_md", param->name);
    paramList->push_back(param);

    // add ig_intr_md_from_prsr
    path = new IR::Path("ingress_intrinsic_metadata_from_parser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_from_prsr", IR::Direction::Out, type);
    tnaParams.emplace("ig_intr_md_from_prsr", param->name);
    paramList->push_back(param);

    // add ig_intr_md_for_tm
    path = new IR::Path("ingress_intrinsic_metadata_for_tm_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::Out, type);
    tnaParams.emplace("ig_intr_md_for_tm", param->name);
    paramList->push_back(param);

    // add compiler generated struct
    path = new IR::Path("compiler_generated_metadata_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("compiler_generated_meta", IR::Direction::InOut, type);
    tnaParams.emplace("compiler_generated_meta", param->name);
    paramList->push_back(param);

    auto parser_type = new IR::Type_Parser("ingressParserImpl", paramList);

    auto parserLocals = new IR::IndexedVector<IR::Declaration>();
    parserLocals->append(structure->ingressParserDeclarations);
    parserLocals->append(node->parserLocals);

    for (auto* state : parser->states) {
        auto it = structure->ingressParserStatements.find(state->name);
        if (it != structure->ingressParserStatements.end()) {
            auto* s = const_cast<IR::ParserState*>(state);
            for (auto* stmt : it->second)
                s->components.push_back(stmt);
        }
    }

    auto result = new IR::BFN::TnaParser(parser->srcInfo, "ingressParserImpl",
                                                  parser_type, parser->constructorParams,
                                                  *parserLocals, parser->states,
                                                  tnaParams, INGRESS);
    return result;
}

const IR::Node* EgressParserConverter::postorder(IR::Declaration_Variable* node) {
    return new IR::Declaration_Variable(node->srcInfo, node->name,
                                        node->type, node->initializer->apply(cloner));
}

const IR::Node* EgressParserConverter::postorder(IR::P4Parser* node) {
    auto parser = node->apply(cloner);
    auto params = parser->type->getApplyParameters();
    /// assume we are dealing with egress parser
    BUG_CHECK(params->size() == 4, "%1%: Expected 4 parameters for parser", parser);

    auto* paramList = new IR::ParameterList;
    ordered_map<cstring, cstring> tnaParams;

    auto* packetIn = params->parameters.at(0);
    tnaParams.emplace("pkt", packetIn->name);
    paramList->push_back(packetIn);

    auto* headers = params->parameters.at(1);
    tnaParams.emplace("hdr", headers->name);
    paramList->push_back(headers);

    auto* meta = params->parameters.at(2);
    auto* param = new IR::Parameter(meta->name, meta->annotations,
                                    IR::Direction::Out, meta->type);
    tnaParams.emplace("md", meta->name);
    paramList->push_back(param);

    // add eg_intr_md
    auto path = new IR::Path("egress_intrinsic_metadata_t");
    auto type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md", IR::Direction::Out, type);
    tnaParams.emplace("eg_intr_md", param->name);
    paramList->push_back(param);

    // add eg_intr_md_from_prsr
    path = new IR::Path("egress_intrinsic_metadata_from_parser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_from_prsr", IR::Direction::Out, type);
    tnaParams.emplace("eg_intr_md_from_prsr", param->name);
    paramList->push_back(param);

    // add ig_intr_md
    path = new IR::Path("ingress_intrinsic_metadata_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md", param->name);
    paramList->push_back(param);

    // add ig_intr_md_for_tm
    path = new IR::Path("ingress_intrinsic_metadata_for_tm_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md_for_tm", param->name);
    paramList->push_back(param);

    // add compiler generated struct
    path = new IR::Path("compiler_generated_metadata_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("compiler_generated_meta", IR::Direction::InOut, type);
    tnaParams.emplace("compiler_generated_meta", param->name);
    paramList->push_back(param);

    IR::IndexedVector<IR::Declaration> parserLocals;
    parserLocals.append(structure->egressParserDeclarations);
    parserLocals.append(node->parserLocals);

    for (auto* state : parser->states) {
        auto it = structure->egressParserStatements.find(state->name);
        if (it != structure->egressParserStatements.end()) {
            auto* s = const_cast<IR::ParserState*>(state);
            for (auto* stmt : it->second)
                s->components.push_back(stmt);
        }
    }

    auto parser_type = new IR::Type_Parser("egressParserImpl", paramList);
    auto result = new IR::BFN::TnaParser(parser->srcInfo, "egressParserImpl",
                                                  parser_type, parser->constructorParams,
                                                  parserLocals, parser->states,
                                                  tnaParams, EGRESS);
    return result;
}

//////////////////////////////////////////////////////////////////////////////////////////////

const IR::Node* TypeNameExpressionConverter::postorder(IR::TypeNameExpression* node) {
    auto typeName = node->typeName->to<IR::Type_Name>();
    auto path = typeName->path->to<IR::Path>();
    auto mapped = enumsToTranslate.find(path->name);
    if (mapped != enumsToTranslate.end()) {
        auto newName = mapped->second;
        if (!newName)
            return node;
        auto newType = structure->enums.find(newName);
        if (newType == structure->enums.end()) {
            BUG("Cannot translation for type ", node);
            return node;
        }
        return new IR::TypeNameExpression(node->srcInfo, newType->second,
                                          new IR::Type_Name(newName));
    }
    return node;
}

const IR::Node* TypeNameExpressionConverter::postorder(IR::Member *node) {
    if (!node->expr->is<IR::TypeNameExpression>())
        return node;
    auto name = node->member;
    auto mapped = fieldsToTranslate.find(name);
    if (mapped != fieldsToTranslate.end()) {
        auto newName = mapped->second;
        return new IR::Member(node->srcInfo, node->expr, newName);
    }
    return node;
}

/// map path expression
const IR::Node* PathExpressionConverter::postorder(IR::Member *node) {
    auto membername = node->member.name;
    auto expr = node->expr->to<IR::PathExpression>();
    if (!expr) return node;
    auto pathname = expr->path->name;
    using PathAndMember = std::pair<cstring, cstring>;
    static std::set<PathAndMember> reportedErrors;

    gress_t thread;
    if (auto* parser = findContext<IR::BFN::TnaParser>()) {
        thread = parser->thread;
    } else if (auto* control = findContext<IR::BFN::TnaControl>()) {
        thread = control->thread;
    } else if (auto* control = findContext<IR::BFN::TnaDeparser>()) {
        thread = control->thread;
    } else {
        LOG3("Member expression " << node << " is not inside a translated control; "
             "won't translate it");
        return node;
    }

    auto& nameMap = thread == INGRESS ? structure->ingressMetadataNameMap
                                      : structure->egressMetadataNameMap;
    auto& otherMap = thread == INGRESS ? structure->egressMetadataNameMap
                                       : structure->ingressMetadataNameMap;
    BUG_CHECK(!nameMap.empty(), "metadata translation map cannot be empty");

    if (auto type = node->type->to<IR::Type_Bits>()) {
        auto it = nameMap.find(MetadataField{pathname, membername, type->size});
        if (it != nameMap.end()) {
            auto expr = new IR::PathExpression(it->second.structName);
            auto member = new IR::Member(node->srcInfo, expr, it->second.fieldName);
            member->type = IR::Type::Bits::get(it->second.width);

            IR::Expression* result = member;

            if (it->second.offset != 0) {
                result = new IR::Slice(result, it->second.offset + it->second.width - 1,
                                       it->second.offset);
            }
            if (it->first.width != it->second.width && findOrigCtxt<IR::Operation>()) {
                result = new IR::Cast(IR::Type::Bits::get(it->first.width), result);
            }

            LOG3("Translating " << node << " to " << result);
            return result;
        } else if (otherMap.count(MetadataField{pathname, membername, type->size})) {
            auto wasReported = reportedErrors.insert(PathAndMember(pathname, membername));
            if (wasReported.second)
                ::error("%1% is not accessible in the %2% pipe", node, toString(thread));
        } else if (pathname == "standard_metadata") {
            ::error("standard_metadata field %1% cannot be translated, you "
                    "cannot use it in your program", node);
        }
    }
    LOG4("No translation found for " << node);
    return node;
}

/// The translation pass only renames intrinsic metadata. If the width of the
/// metadata is also changed after the translation, then this pass will insert
/// appropriate cast to the RHS of the assignment.
const IR::Node*
PathExpressionConverter::postorder(IR::AssignmentStatement* node) {
    auto left = node->left;
    auto right = node->right;

    if (auto mem = left->to<IR::Member>()) {
        auto type = mem->type->to<IR::Type_Bits>();
        if (!type)
            return node;
        if (auto path = mem->expr->to<IR::PathExpression>()) {
            MetadataField field{path->path->name, mem->member.name, type->size};
            auto it = structure->targetMetadataSet.find(field);
            if (it != structure->targetMetadataSet.end()) {
                auto type = IR::Type::Bits::get(it->width);
                if (type != right->type) {
                    if (right->type->is<IR::Type_Boolean>()) {
                        if (right->to<IR::BoolLiteral>()->value == true) {
                            right = new IR::Constant(type, 1);
                        } else {
                            right = new IR::Constant(type, 0);
                        }
                    } else {
                        right = new IR::Cast(type, right);
                    }
                    return new IR::AssignmentStatement(node->srcInfo, left, right);
                }
            }
        }
    }
    return node;
}

//////////////////////////////////////////////////////////////////////////////////////////////
const IR::Node* ExternConverter::postorder(IR::Member *node) {
    auto orig = getOriginal<IR::Member>();
    auto it = structure->typeNamesToDo.find(orig);
    if (it != structure->typeNamesToDo.end())
        return it->second;
    return node;
}

/// The meter
const IR::Node* MeterConverter::postorder(IR::MethodCallStatement* node) {
    auto orig = getOriginal<IR::MethodCallStatement>();
    auto mce = orig->methodCall->to<IR::MethodCallExpression>();

    auto member = mce->method->to<IR::Member>();
    BUG_CHECK(member->member == "execute_meter",
              "unexpected meter method %1%", member->member);
    auto method = new IR::Member(node->srcInfo, member->expr, "execute");

    auto meterColor = mce->arguments->at(1)->expression;
    auto size = meterColor->type->width_bits();
    BUG_CHECK(size != 0, "meter color cannot be bit<0>");
    auto args = new IR::Vector<IR::Argument>();
    args->push_back(mce->arguments->at(0));
    auto methodcall = new IR::MethodCallExpression(node->srcInfo, method, args);
    IR::AssignmentStatement* assign = nullptr;
    if (size > 8) {
        assign = new IR::AssignmentStatement(
                meterColor, new IR::Cast(IR::Type::Bits::get(size), methodcall));
    } else if (size < 8) {
        assign = new IR::AssignmentStatement(meterColor, new IR::Slice(methodcall, size - 1, 0));
    } else {
        assign = new IR::AssignmentStatement(meterColor, methodcall);
    }
    return assign;
}

const IR::Node* DirectMeterConverter::postorder(IR::MethodCallStatement* node) {
    auto orig = getOriginal<IR::MethodCallStatement>();
    auto mce = orig->methodCall->to<IR::MethodCallExpression>();

    auto member = mce->method->to<IR::Member>();
    auto method = new IR::Member(node->srcInfo, member->expr, "execute");
    auto args = new IR::Vector<IR::Argument>();

    auto meter_pe = member->expr->to<IR::PathExpression>();
    BUG_CHECK(meter_pe != nullptr, "Direct meter is not a path expression");


    auto inst = refMap->getDeclaration(meter_pe->path);
    auto annot = inst->getAnnotation("pre_color");
    if (annot != nullptr) {
        args->push_back(new IR::Argument(new IR::Cast(IR::Type::Bits::get(2), annot->expr.at(0))));
    }

    auto meterColor = mce->arguments->at(0)->expression;
    auto size = meterColor->type->width_bits();
    BUG_CHECK(size != 0, "meter color width cannot be bit<0>");
    auto methodcall = new IR::MethodCallExpression(node->srcInfo, method, args);
    IR::AssignmentStatement* assign = nullptr;
    if (size > 8) {
        assign = new IR::AssignmentStatement(
                meterColor, new IR::Cast(IR::Type::Bits::get(size), methodcall));
    } else if (size < 8) {
        assign = new IR::AssignmentStatement(meterColor, new IR::Slice(methodcall, size - 1, 0));
    } else {
        assign = new IR::AssignmentStatement(meterColor, methodcall);
    }
    return assign;
}

const IR::Node* RegisterConverter::postorder(IR::MethodCallStatement* node) {
    auto orig = getOriginal<IR::MethodCallStatement>();
    auto mce = orig->methodCall->to<IR::MethodCallExpression>();
    auto member = mce->method->to<IR::Member>();

    if (member->member != "read") return node;

    auto method = new IR::Member(node->srcInfo, member->expr, "read");
    auto args = new IR::Vector<IR::Argument>({mce->arguments->at(1)});
    auto methodcall = new IR::MethodCallExpression(node->srcInfo, method, args);
    auto assign = new IR::AssignmentStatement(mce->arguments->at(0)->expression, methodcall);

    return assign;
}
//////////////////////////////////////////////////////////////////////////////////////////////

const IR::Node* ParserPriorityConverter::postorder(IR::AssignmentStatement* node) {
    auto parserPriority = new IR::PathExpression("ig_prsr_ctrl_priority");
    auto member = new IR::Member(parserPriority, "set");
    auto result = new IR::MethodCallStatement(node->srcInfo, member,
                                              { new IR::Argument(node->right) });
    return result;
}

const IR::Node* ParserCounterConverter::postorder(IR::AssignmentStatement* ) {
    auto stmt = getOriginal<IR::AssignmentStatement>();
    auto parserCounter = new IR::PathExpression("ig_prsr_ctrl_parser_counter");
    auto right = stmt->right;

    // Remove any casts around the source of the assignment.
    if (auto cast = right->to<IR::Cast>()) {
        if (cast->destType->is<IR::Type_Bits>()) {
            right = cast->expr;
        }
    }

    IR::MethodCallStatement *methodCall = nullptr;
    if (right->to<IR::Constant>() || right->to<IR::Member>()) {
        // Load operation
        methodCall = new IR::MethodCallStatement(
            stmt->srcInfo, new IR::Member(parserCounter, "set"), { new IR::Argument(stmt->right) });
    } else if (auto add = right->to<IR::Add>()) {
        // Add operaton.
        auto member = add->left->to<IR::Member>();
        BUG_CHECK(member != nullptr, "Expression for parser counter is not supported %1%",
                  stmt->srcInfo);

        auto pathExpr = member->expr->to<IR::PathExpression>();
        if (pathExpr) {
            auto path = pathExpr->path->to<IR::Path>();
            if (path->name == "ig_prsr_ctrl" && member->member == "parser_counter")
                return new IR::MethodCallStatement(
                    stmt->srcInfo, new IR::Member(parserCounter, "increment"),
                    { new IR::Argument(add->right) });
        }

        methodCall =  new IR::MethodCallStatement(
                stmt->srcInfo,
                new IR::Member(parserCounter, "set"),
                { new IR::Argument(new IR::Cast(IR::Type::Bits::get(8), right)) });
    }

    return methodCall;
}

const IR::Node* ParserCounterSelectionConverter::postorder(IR::Member* node) {
    auto parserCounter = new IR::PathExpression("ig_prsr_ctrl_parser_counter");
    auto methodCall =  new IR::MethodCallExpression(
        node->srcInfo, new IR::Member(parserCounter, "get"), new IR::Vector<IR::Argument>());
    return methodCall;
}

}  // namespace V1



}  // namespace BFN
