#include "bf-p4c/arch/psa_converters.h"
#include "bf-p4c/arch/psa_program_structure.h"
#include "bf-p4c/arch/program_structure.h"
#include "lib/ordered_map.h"

namespace BFN {

namespace PSA {

const IR::Node* ControlConverter::postorder(IR::Declaration_Instance* node) {
    auto* orig = getOriginal<IR::Declaration_Instance>();
    if (structure->_map.count(orig)) {
        auto result = structure->_map.at(orig);
        return result; }
    return node;
}

const IR::Node* ControlConverter::postorder(IR::IfStatement* node) {
    auto* orig = getOriginal<IR::IfStatement>();
    if (structure->_map.count(orig)) {
        LOG1(" delete " << orig);
        auto result = structure->_map.at(orig);
        return result; }
    return node;
}

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
    param = new IR::Parameter("compiler_generated_meta", IR::Direction::InOut, type);
    tnaParams.emplace("compiler_generated_meta", param->name);
    paramList->push_back(param);

    auto parser_type = new IR::Type_Parser("ingressParserImpl", paramList);

    auto parserLocals = new IR::IndexedVector<IR::Declaration>();
    parserLocals->append(structure->ingressParserDeclarations);
    parserLocals->append(node->parserLocals);

    auto result = new IR::BFN::TranslatedP4Parser(parser->srcInfo, "ingressParserImpl",
                                                  parser_type, parser->constructorParams,
                                                  *parserLocals, parser->states,
                                                  tnaParams, INGRESS);
    return result;
}

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
    param = new IR::Parameter("compiler_generated_meta", IR::Direction::InOut, type);
    tnaParams.emplace("compiler_generated_meta", param->name);
    paramList->push_back(param);

    auto parser_type = new IR::Type_Parser("egressParserImpl", paramList);
    auto result = new IR::BFN::TranslatedP4Parser(parser->srcInfo, "egressParserImpl",
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
    param = new IR::Parameter("compiler_generated_meta", IR::Direction::InOut, type);
    tnaParams.emplace("compiler_generated_meta", param->name);
    paramList->push_back(param);

    auto controlType = new IR::Type_Control("ingress", paramList);

    auto controlLocals = new IR::IndexedVector<IR::Declaration>();
    controlLocals->append(structure->ingressDeclarations);
    controlLocals->append(node->controlLocals);

    auto body = new IR::IndexedVector<IR::StatOrDecl>();
    body->append(node->body->components);
    body->append(structure->ingressStatements);

    auto result = new IR::BFN::TranslatedP4Control(node->srcInfo, "ingress", controlType,
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
    param = new IR::Parameter("compiler_generated_meta", IR::Direction::InOut, type);
    tnaParams.emplace("compiler_generated_meta", param->name);
    paramList->push_back(param);

    auto controlType = new IR::Type_Control("egress", paramList);

    auto controlLocals = new IR::IndexedVector<IR::Declaration>();
    controlLocals->append(structure->egressDeclarations);
    controlLocals->append(node->controlLocals);

    auto body = new IR::IndexedVector<IR::StatOrDecl>();
    body->append(node->body->components);
    body->append(structure->egressStatements);

    auto result = new IR::BFN::TranslatedP4Control(node->srcInfo, "egress", controlType,
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

    auto result = new IR::BFN::TranslatedP4Deparser(deparser->srcInfo, "ingressDeparserImpl",
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

    auto result = new IR::BFN::TranslatedP4Deparser(deparser->srcInfo, "egressDeparserImpl",
                                                    controlType, deparser->constructorParams,
                                                    *controlLocals, body, tnaParams, EGRESS);
    return result;
}

const IR::Node* TypeNameExpressionConverter::postorder(IR::TypeNameExpression* node) {
    auto typeName = node->typeName->to<IR::Type_Name>();
    auto path = typeName->path->to<IR::Path>();
    auto mapped = enumsToTranslate.find(path->name);
    if (mapped != enumsToTranslate.end()) {
        auto newName = mapped->second;
        auto newType = structure->enums.find(newName);
        if (newType == structure->enums.end()) {
            BUG("No translation for type ", node);
            return node;
        }
        auto retval =
            new IR::TypeNameExpression(node->srcInfo, newType->second, new IR::Type_Name(newName));
        return retval;
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
    if (auto* parser = findContext<IR::BFN::TranslatedP4Parser>()) {
        thread = parser->thread;
    } else if (auto* control = findContext<IR::BFN::TranslatedP4Control>()) {
        thread = control->thread;
    } else if (auto* control = findContext<IR::BFN::TranslatedP4Deparser>()) {
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
                auto path = new IR::PathExpression("compiler_generated_meta");
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
    }
    LOG4("No translation found for " << node);
    return node;
}

}  // namespace PSA

}  // namespace BFN
