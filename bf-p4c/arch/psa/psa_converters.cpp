#include "bf-p4c/arch/bridge_metadata.h"
#include "bf-p4c/arch/program_structure.h"
#include "programStructure.h"
#include "psa_converters.h"
#include "lib/ordered_map.h"

namespace BFN {

namespace PSA {

const IR::Node* HashConverter::postorder(IR::MethodCallExpression* node) {
    auto member = node->method->to<IR::Member>();
    BUG_CHECK(member->member == "get_hash",
              "unexpected Hash method %1%", member->member);
    auto method = new IR::Member(node->srcInfo, member->expr, "get");

    auto typeArgs = new IR::Vector<IR::Type>();
    auto args = new IR::Vector<IR::Argument>();
    auto args_size = node->arguments->size();
        ERROR_CHECK(args_size == 1 || args_size == 3, "incorrect number of arguments"
                                                      "to the get_hash() method");
    if (args_size == 1) {
        typeArgs->push_back(node->arguments->at(0)->expression->type);
        args->push_back(node->arguments->at(0));
    } else if (args_size == 3) {
        // tna swapped argument 0 and 1
        // FIXME -- TNA has no 3 arg get?
        typeArgs->push_back(node->arguments->at(0)->expression->type);
        args->push_back(node->arguments->at(1));
        args->push_back(node->arguments->at(0));
        args->push_back(node->arguments->at(2));
    }
    return new IR::MethodCallExpression(node->srcInfo, method, typeArgs, args);
}

const IR::Node* RandomConverter::postorder(IR::MethodCallExpression* node) {
    auto member = node->method->to<IR::Member>();
    BUG_CHECK(member->member == "read",
              "unexpected Random method %1%", member->member);
    auto method = new IR::Member(node->srcInfo, member->expr, "get");
    auto args = new IR::Vector<IR::Argument>();
    return new IR::MethodCallExpression(node->srcInfo, method, args);
}

// Convert meter.execute(idx) to meter.execute(idx), discard inferred psa type.
const IR::Node* MeterConverter::postorder(IR::MethodCallExpression* node) {
    auto member = node->method->to<IR::Member>();
    if (auto path = member->expr->to<IR::PathExpression>()) {
        auto pathExpr = new IR::PathExpression(path->path->name);
        auto method = new IR::Member(node->srcInfo, pathExpr, "execute");
        auto args = new IR::Vector<IR::Argument>();
        args->push_back(node->arguments->at(0));
        return new IR::MethodCallExpression(node->srcInfo, method, args);
    }
    BUG("Unhandled case");
    return nullptr;
}

const IR::Node* ControlConverter::postorder(IR::Declaration_Instance* node) {
    return substitute<IR::Declaration_Instance>(node); }

const IR::Node* ControlConverter::postorder(IR::MethodCallExpression* node) {
    return substitute<IR::MethodCallExpression>(node); }

const IR::Node* ControlConverter::postorder(IR::IfStatement* node) {
    return substitute<IR::IfStatement>(node); }

const IR::Node* ControlConverter::postorder(IR::StatOrDecl* node) {
    return substitute<IR::StatOrDecl>(node); }

const IR::Node* ControlConverter::postorder(IR::Property* p) {
    boost::optional<cstring> newName = boost::none;
    if (p->name.name == "psa_implementation")
        newName = "implementation";
    else if (p->name.name == "psa_direct_counter")
        newName = "counters";
    else if (p->name.name == "psa_direct_meter")
        newName = "meters";
    else if (p->name.name == "psa_idle_timeout")
        newName = "idle_timeout";
    else if (p->name.name == "psa_empty_group_action")
        LOG1("ERROR: psa_empty_group_action is not supported");
    if (newName != boost::none)
        return new IR::Property(p->srcInfo, *newName, p->annotations, p->value, p->isConstant);
    return p;
}

const IR::Node* ControlConverter::postorder(IR::Member* node) {
    return substitute<IR::Member>(node); }

const IR::Node* IngressParserConverter::postorder(IR::P4Parser *node) {
    auto parser = node->apply(cloner);
    auto params = parser->type->getApplyParameters();
    BUG_CHECK(params->size() == 6, "%1%: Expected 6 parameters for parser", parser);

    auto* paramList = new IR::ParameterList;
    ordered_map<cstring, cstring> tnaParams;

    auto* packetIn = params->getParameter(0);
    tnaParams.emplace("pkt", packetIn->name);
    paramList->push_back(packetIn);

    auto* headers = params->getParameter(1);
    tnaParams.emplace("hdr", headers->name);
    paramList->push_back(headers);

    auto* meta = parser->getApplyParameters()->getParameter(2);
    auto* param = new IR::Parameter(meta->name, meta->annotations,
                                    IR::Direction::Out, meta->type);
    tnaParams.emplace("ig_md", meta->name);
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
    param = new IR::Parameter(BFN::COMPILER_META, IR::Direction::InOut, type);
    tnaParams.emplace(BFN::COMPILER_META, param->name);
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

const IR::Node* ParserConverter::postorder(IR::Declaration_Instance* decl) {
    return substitute<IR::Declaration_Instance>(decl); }

const IR::Node* ParserConverter::postorder(IR::StatOrDecl* node) {
    return substitute<IR::StatOrDecl>(node); }

const IR::Node* ParserConverter::postorder(IR::MethodCallExpression* node) {
    return substitute<IR::MethodCallExpression>(node); }

const IR::Node* EgressParserConverter::postorder(IR::P4Parser* node) {
    auto parser = node->apply(cloner);
    auto params = parser->type->getApplyParameters();
    /// assume we are dealing with egress parser
    BUG_CHECK(params->size() == 7, "%1%: Expected 7 parameters for parser", parser);

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
    tnaParams.emplace("eg_md", meta->name);
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
    param = new IR::Parameter(BFN::COMPILER_META, IR::Direction::InOut, type);
    tnaParams.emplace(BFN::COMPILER_META, param->name);
    paramList->push_back(param);

    auto parser_type = new IR::Type_Parser("egressParserImpl", paramList);
    for (auto* state : parser->states) {
        auto it = structure->egressParserStatements.find(state->name);
        if (it != structure->egressParserStatements.end()) {
            auto* s = const_cast<IR::ParserState*>(state);
            for (auto* stmt : it->second)
                s->components.push_back(stmt);
        }
    }
    auto result = new IR::BFN::TnaParser(parser->srcInfo, "egressParserImpl",
                                                  parser_type, parser->constructorParams,
                                                  parser->parserLocals, parser->states,
                                                  tnaParams, EGRESS);
    return result;
}

const IR::Node* IngressControlConverter::postorder(IR::P4Control* node) {
    auto params = node->type->getApplyParameters();
    BUG_CHECK(params->size() == 4, "%1% Expected 4 parameters for ingress", node);

    auto* paramList = new IR::ParameterList;
    ordered_map<cstring, cstring> tnaParams;

    auto* headers = params->parameters.at(0);
    tnaParams.emplace("hdr", headers->name);
    paramList->push_back(headers);

    auto* meta = params->parameters.at(1);
    tnaParams.emplace("ig_md", meta->name);
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
    param = new IR::Parameter("ig_intr_md_from_parser", IR::Direction::In, type);
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
    param = new IR::Parameter(BFN::COMPILER_META, IR::Direction::InOut, type);
    tnaParams.emplace(BFN::COMPILER_META, param->name);
    paramList->push_back(param);

    auto controlType = new IR::Type_Control("ingress", paramList);

    auto controlLocals = new IR::IndexedVector<IR::Declaration>();
    controlLocals->append(structure->ingressDeclarations);
    controlLocals->append(node->controlLocals);

    auto body = new IR::IndexedVector<IR::StatOrDecl>();
    body->append(node->body->components);
    body->append(structure->ingressStatements);

    auto result = new IR::BFN::TnaControl(node->srcInfo, "ingress", controlType,
         node->constructorParams, *controlLocals,
         new IR::BlockStatement(node->body->annotations, *body), tnaParams, INGRESS);
    return result;
}

const IR::Node* EgressControlConverter::postorder(IR::P4Control *node) {
    auto params = node->type->getApplyParameters();
    BUG_CHECK(params->size() == 4, "%1% Expected 4 parameters for egress", node);

    auto* paramList = new IR::ParameterList;
    ordered_map<cstring, cstring> tnaParams;

    auto* headers = params->parameters.at(0);
    tnaParams.emplace("hdr", headers->name);
    paramList->push_back(headers);

    auto* meta = params->parameters.at(1);
    tnaParams.emplace("eg_md", meta->name);
    paramList->push_back(meta);

    // add eg_intr_md
    auto path = new IR::Path("egress_intrinsic_metadata_t");
    auto type = new IR::Type_Name(path);
    auto param = new IR::Parameter("eg_intr_md", IR::Direction::In, type);
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

    /// XXX(hanw) following three parameters are added and should be removed after
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
    param = new IR::Parameter(BFN::COMPILER_META, IR::Direction::InOut, type);
    tnaParams.emplace(BFN::COMPILER_META, param->name);
    paramList->push_back(param);

    auto controlType = new IR::Type_Control("egress", paramList);

    auto controlLocals = new IR::IndexedVector<IR::Declaration>();
    controlLocals->append(structure->egressDeclarations);
    controlLocals->append(node->controlLocals);

    auto body = new IR::IndexedVector<IR::StatOrDecl>();
    body->append(node->body->components);
    body->append(structure->egressStatements);

    auto result = new IR::BFN::TnaControl(node->srcInfo, "egress", controlType,
        node->constructorParams, *controlLocals,
        new IR::BlockStatement(node->body->annotations, *body), tnaParams, EGRESS);
    return result;
}

const IR::Node* IngressDeparserConverter::postorder(IR::P4Control* node) {
    auto deparser = node->apply(cloner);
    auto params = deparser->type->getApplyParameters();
    BUG_CHECK(params->size() == 7, "%1% Expected 7 parameters for deparser", deparser);

    auto* paramList = new IR::ParameterList;
    ordered_map<cstring, cstring> tnaParams;

    auto* packetOut = params->parameters.at(0);
    tnaParams.emplace("pkt", packetOut->name);
    paramList->push_back(packetOut);

    // add header
    auto hdr = deparser->getApplyParameters()->parameters.at(4);
    auto param = new IR::Parameter(hdr->name, hdr->annotations,
                                   IR::Direction::InOut, hdr->type);
    tnaParams.emplace("hdr", param->name);
    paramList->push_back(param);

    // add metadata
    auto meta = deparser->getApplyParameters()->parameters.at(5);
    param = new IR::Parameter(meta->name, meta->annotations,
                              IR::Direction::In, meta->type);
    tnaParams.emplace("metadata", param->name);
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
    param = new IR::Parameter(COMPILER_META, IR::Direction::InOut, type);
    tnaParams.emplace(COMPILER_META, param->name);
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

const IR::Node* EgressDeparserConverter::postorder(IR::P4Control* node) {
    auto deparser = node->apply(cloner);

    auto params = deparser->type->getApplyParameters();
    BUG_CHECK(params->size() == 7, "%1% Expected 7 parameters for deparser", deparser);

    auto* paramList = new IR::ParameterList;
    ordered_map<cstring, cstring> tnaParams;

    auto* packetOut = params->parameters.at(0);
    tnaParams.emplace("pkt", packetOut->name);
    paramList->push_back(packetOut);

    // add header
    auto hdr = deparser->getApplyParameters()->parameters.at(3);
    auto param = new IR::Parameter(hdr->name, hdr->annotations,
                                   IR::Direction::InOut, hdr->type);
    tnaParams.emplace("hdr", param->name);
    paramList->push_back(param);

    // add metadata
    auto meta = deparser->getApplyParameters()->parameters.at(4);
    param = new IR::Parameter(meta->name, meta->annotations,
                              IR::Direction::In, meta->type);
    tnaParams.emplace("metadata", param->name);
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
    param = new IR::Parameter(COMPILER_META, IR::Direction::InOut, type);
    tnaParams.emplace(COMPILER_META, param->name);
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

const IR::Node* TypeNameExpressionConverter::postorder(IR::TypeNameExpression* node) {
    auto typeName = node->typeName->to<IR::Type_Name>();
    auto path = typeName->path->to<IR::Path>();
    auto mapped = enumsToTranslate.find(path->name);
    if (mapped != enumsToTranslate.end()) {
        cstring newName = mapped->second.first;
        bool isSerEnum = mapped->second.second;
        IR::TypeNameExpression* retval;
        if (isSerEnum) {
            if (!structure->ser_enums.count(newName))
                BUG("No translation for type %1%", node);
            auto newType = structure->ser_enums.at(newName);
            retval = new IR::TypeNameExpression(node->srcInfo,
                    newType, new IR::Type_Name(newName));
        } else {
            if (!structure->enums.count(newName))
                BUG("No translation for type %1%", node);
            auto newType = structure->enums.at(newName);
            retval = new IR::TypeNameExpression(node->srcInfo,
                    newType, new IR::Type_Name(newName));
        }
        return retval;
    }
    return node;
}

const IR::Node* TypeNameExpressionConverter::postorder(IR::Member* member) {
    if (!member->expr->type->is<IR::Type_SerEnum>())
        return member;
    auto type = member->expr->type->to<IR::Type_SerEnum>();
    if (serEnumWidth.count(type->name.name)) {
        auto width = serEnumWidth.at(type->name.name);
        return new IR::Cast(IR::Type_Bits::get(width), member);
    }
    return member;
}

const IR::Node* TypeNameConverter::postorder(IR::Type_Name* node) {
    auto path = node->path->to<IR::Path>();
    auto mapped = enumsToTranslate.find(path->name);
    if (mapped != enumsToTranslate.end()) {
        cstring newName = mapped->second.first;
        return new IR::Type_Name(newName);
    }
    return node;
}

/// map path expression
const IR::Node* PathExpressionConverter::postorder(IR::Member *node) {
    auto membername = node->member.name;
    auto expr = node->expr->to<IR::PathExpression>();
    if (!expr) return node;
    auto pathname = expr->path->name;

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
    if (auto type = node->type->to<IR::Type_Bits>()) {
        BUG_CHECK(!nameMap.empty(), "metadata translation map cannot be empty");
        auto it = nameMap.find(MetadataField{pathname, membername, type->size});
        if (it != nameMap.end()) {
            IR::Expression* expr;
            if (it->second.isCG) {
                auto path = new IR::PathExpression(COMPILER_META);
                expr = new IR::Member(path, it->second.structName);
            } else {
                expr = new IR::PathExpression(it->second.structName);
            }
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
        }
    } else if (node->type->to<IR::Type_Enum>()) {
        auto it = nameMap.find(MetadataField{pathname, membername, 0});
        if (it != nameMap.end()) {
            auto expr = new IR::PathExpression(it->second.structName);
            auto result = new IR::Member(node->srcInfo, expr, it->second.fieldName);
            LOG3("Translating " << node << " to " << result);
            return result;
        }
    } else if (node->type->to<IR::Type_Boolean>()) {
        auto it = nameMap.find(MetadataField{pathname, membername, 1});
        if (it != nameMap.end()) {
            auto expr = new IR::PathExpression(it->second.structName);
            auto result = new IR::Member(node->srcInfo, expr, it->second.fieldName);
            LOG3("Translating " << node << " to " << result);
            return result;
        }
    } else if (node->type->to<IR::Type_Error>()) {
        auto it = nameMap.find(MetadataField{pathname, membername, 1});
        if (it != nameMap.end()) {
            auto expr = new IR::PathExpression(it->second.structName);
            auto result = new IR::Member(node->srcInfo, expr, it->second.fieldName);
            LOG3("Translating " << node << " to " << result);
            return result;
        }
    }
    LOG4("No translation found for " << node);
    return node;
}

}  // namespace PSA

}  // namespace BFN
