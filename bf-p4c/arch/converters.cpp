#include "converters.h"
#include "program_structure.h"
#include "lib/ordered_map.h"

namespace BFN {

namespace V1 {
//////////////////////////////////////////////////////////////////////////////////////////////

#define RETURN_TRANSLATED_NODE_IF_FOUND(NAME) do {                           \
    auto it_##NAME = structure->NAME.find(orig);                    \
    if (it_##NAME != structure->NAME.end()) {                       \
        LOG3("Translate " << orig << " to " << it_##NAME->second);  \
        return it_##NAME->second; }                                 \
    } while (false)

const IR::Node* ControlConverter::postorder(IR::Member* node) {
    auto* orig = getOriginal<IR::Member>();
    RETURN_TRANSLATED_NODE_IF_FOUND(membersToDo);
    RETURN_TRANSLATED_NODE_IF_FOUND(pathsToDo);
    RETURN_TRANSLATED_NODE_IF_FOUND(typeNamesToDo);
    return node;
}

const IR::Node* ControlConverter::postorder(IR::Declaration_Instance* node) {
    auto* orig = getOriginal<IR::Declaration_Instance>();
    RETURN_TRANSLATED_NODE_IF_FOUND(counters);
    RETURN_TRANSLATED_NODE_IF_FOUND(meters);
    RETURN_TRANSLATED_NODE_IF_FOUND(direct_counters);
    RETURN_TRANSLATED_NODE_IF_FOUND(direct_meters);
    return node;
}

const IR::Node* ControlConverter::postorder(IR::MethodCallStatement* node) {
    auto* orig = getOriginal<IR::MethodCallStatement>();
    RETURN_TRANSLATED_NODE_IF_FOUND(meterCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(directMeterCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(hashCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(randomCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(resubmitCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(digestCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(cloneCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(dropCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(executeMeterCalls);
    return node;
}

const IR::Node* ParserConverter::postorder(IR::AssignmentStatement* node) {
    auto* orig = getOriginal<IR::AssignmentStatement>();
    RETURN_TRANSLATED_NODE_IF_FOUND(priorityCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(parserCounterCalls);
    return node;
}

const IR::Node* ParserConverter::postorder(IR::Member* node) {
    auto* orig = getOriginal<IR::Member>();
    RETURN_TRANSLATED_NODE_IF_FOUND(pathsToDo);
    RETURN_TRANSLATED_NODE_IF_FOUND(typeNamesToDo);
    RETURN_TRANSLATED_NODE_IF_FOUND(parserCounterSelects);
    return node;
}

const IR::Node* IngressControlConverter::preorder(IR::P4Control* node) {
    auto params = node->type->getApplyParameters();
    BUG_CHECK(params->size() == 3, "%1% Expected 3 parameters for ingress", node);

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
    param = new IR::Parameter("ig_intr_md_from_parser_aux", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md_from_prsr", param->name);
    paramList->push_back(param);

    // add ig_intr_md_for_tm
    path = new IR::Path("ingress_intrinsic_metadata_for_tm_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md_for_tm", param->name);
    paramList->push_back(param);

    // add ig_intr_md_for_mb
    path = new IR::Path("ingress_intrinsic_metadata_for_mirror_buffer_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_mb", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md_for_mb", param->name);
    paramList->push_back(param);

    // add ig_intr_md_for_dprsr
    path = new IR::Path("ingress_intrinsic_metadata_for_deparser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_deparser", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md_for_dprsr", param->name);
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

    auto result = new IR::BFN::TranslatedP4Control(node->srcInfo, "ingress", controlType,
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
    param = new IR::Parameter("eg_intr_md_from_parser_aux", IR::Direction::In, type);
    tnaParams.emplace("eg_intr_md_from_prsr", param->name);
    paramList->push_back(param);

    // add eg_intr_md_for_mb
    path = new IR::Path("egress_intrinsic_metadata_for_mirror_buffer_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_mb", IR::Direction::InOut, type);
    tnaParams.emplace("eg_intr_md_for_mb", param->name);
    paramList->push_back(param);

    // add eg_intr_md_for_oport
    path = new IR::Path("egress_intrinsic_metadata_for_output_port_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_oport", IR::Direction::InOut, type);
    tnaParams.emplace("eg_intr_md_for_oport", param->name);
    paramList->push_back(param);

    // add eg_intr_md_for_dprsr
    path = new IR::Path("egress_intrinsic_metadata_for_deparser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_deparser", IR::Direction::InOut, type);
    tnaParams.emplace("eg_intr_md_for_dprsr", param->name);
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

    auto result = new IR::BFN::TranslatedP4Control(node->srcInfo, "egress", controlType,
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
    tnaParams.emplace("metadata", param->name);
    paramList->push_back(param);

    // add ingress intrinsic metadata
    auto path = new IR::Path("ingress_intrinsic_metadata_t");
    auto type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md", param->name);
    paramList->push_back(param);

    // add mirror buffer intrinsic metadata
    path = new IR::Path("ingress_intrinsic_metadata_for_mirror_buffer_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_mb", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md_for_mb", param->name);
    paramList->push_back(param);

    // add deparser intrinsic metadata
    path = new IR::Path("ingress_intrinsic_metadata_for_deparser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_deparser", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md_for_deparser", param->name);
    paramList->push_back(param);

    // add mirror
    path = new IR::Path("mirror_packet");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("mirror", IR::Direction::None, type);
    tnaParams.emplace("mirror", param->name);
    paramList->push_back(param);

    // add resubmit
    path = new IR::Path("resubmit_packet");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("resubmit", IR::Direction::None, type);
    tnaParams.emplace("resubmit", param->name);
    paramList->push_back(param);

    // add digest
    path = new IR::Path("learning_packet");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("learning", IR::Direction::None, type);
    tnaParams.emplace("learning", param->name);
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

    auto result = new IR::BFN::TranslatedP4Control(deparser->srcInfo, "ingressDeparserImpl",
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
    tnaParams.emplace("metadata", param->name);
    paramList->push_back(param);

    // add mirror buffer intrinsic metadata
    auto path = new IR::Path("egress_intrinsic_metadata_for_mirror_buffer_t");
    auto type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_mb", IR::Direction::In, type);
    tnaParams.emplace("eg_intr_md_for_mb", param->name);
    paramList->push_back(param);

    // add eg_intr_md_for_dprsr
    path = new IR::Path("egress_intrinsic_metadata_for_deparser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_deparser", IR::Direction::In, type);
    tnaParams.emplace("eg_intr_md_for_dprsr", param->name);
    paramList->push_back(param);

    // add mirror
    path = new IR::Path("mirror_packet");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("mirror", IR::Direction::None, type);
    tnaParams.emplace("mirror", param->name);
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

    auto result = new IR::BFN::TranslatedP4Control(deparser->srcInfo, "egressDeparserImpl",
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
    param = new IR::Parameter("ig_intr_md_from_parser_aux", IR::Direction::Out, type);
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
    param = new IR::Parameter("eg_intr_md_from_parser_aux", IR::Direction::Out, type);
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

    auto parser_type = new IR::Type_Parser("egressParserImpl", paramList);
    auto result = new IR::BFN::TranslatedP4Parser(parser->srcInfo, "egressParserImpl",
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

const IR::Node* MemberExpressionConverter::postorder(IR::Member *node) {
    // XXX(hanw) TBD
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
    auto it = nameMap.find(MetadataField{pathname, membername});
    if (it != nameMap.end()) {
        auto expr = new IR::PathExpression(it->second.structName);
        auto result = new IR::Member(node->srcInfo, expr, it->second.fieldName);
        const unsigned bitWidth = structure->metadataTypeMap.at(it->second);
        result->type = IR::Type::Bits::get(bitWidth);
        LOG3("Translating " << node << " to " << result);
        return result;
    }
    if (otherMap.count(MetadataField{pathname, membername}))
        error("%s is not accessible in the %s pipe", node, toString(thread));
    LOG4("No translation found for " << node);
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

const IR::Node* HashConverter::postorder(IR::MethodCallStatement* node) {
    auto orig = getOriginal<IR::MethodCallStatement>();
    auto mce = orig->methodCall->to<IR::MethodCallExpression>();

    BUG_CHECK(mce->arguments->size() > 4, "insufficient arguments to hash() function");
    auto pDest = mce->arguments->at(0);
    auto pBase = mce->arguments->at(2);
    auto pData = mce->arguments->at(3);
    auto pMax = mce->arguments->at(4);
    auto args = new IR::Vector<IR::Expression>( { pData, pBase, pMax });

    cstring hashName;
    auto it = structure->nameMap.find(orig);
    if (it != structure->nameMap.end()) {
        hashName = it->second; }

    auto member = new IR::Member(new IR::PathExpression(hashName), "get_hash");

    auto dst_size = mce->typeArguments->at(0)->width_bits();
    auto src_size = mce->typeArguments->at(1)->width_bits();
    if (src_size != dst_size) {
        WARNING("casting bit<" << src_size << "> to bit<" << dst_size << ">");
        return new IR::AssignmentStatement(pDest,
                   new IR::Cast(IR::Type::Bits::get(dst_size),
                       new IR::MethodCallExpression(node->srcInfo, member, args)));
    }
    return new IR::AssignmentStatement(pDest,
               new IR::MethodCallExpression(node->srcInfo, member, args));
}

const IR::Node* RandomConverter::postorder(IR::MethodCallStatement* node) {
    auto orig = getOriginal<IR::MethodCallStatement>();
    auto mce = orig->methodCall->to<IR::MethodCallExpression>();

    auto dest = mce->arguments->at(0);
    // ignore lower bound
    auto hi = mce->arguments->at(2);
    auto args = new IR::Vector<IR::Expression>();
    args->push_back(hi);

    cstring randName;
    auto it = structure->nameMap.find(orig);
    if (it != structure->nameMap.end()) {
        randName = it->second; }

    auto method = new IR::PathExpression(randName);
    auto member = new IR::Member(method, "get");
    auto call = new IR::MethodCallExpression(node->srcInfo, member, args);
    auto stmt = new IR::AssignmentStatement(dest, call);
    return stmt;
}

const IR::Node* CounterConverter::postorder(IR::Declaration_Instance *node) {
    if (auto type = node->type->to<IR::Type_Name>()) {
        BUG_CHECK(type->path->name == "counter",
                  "counter converter cannot be applied to %1%", type->path->name);

        auto typeArgs = new IR::Vector<IR::Type>();
        // type<W>
        if (auto anno = node->annotations->getSingle("min_width")) {
            auto min_width = anno->expr.at(0)->as<IR::Constant>().asInt();
            typeArgs->push_back(IR::Type::Bits::get(min_width));
        } else {
            auto min_width = IR::Type::Bits::get(32);
            typeArgs->push_back(min_width);
            WARNING("Could not infer min_width for counter %s, using bit<32>" << node);
        }
        // type<S>
        if (auto s = node->arguments->at(0)->to<IR::Constant>()) {
            typeArgs->push_back(s->type->to<IR::Type_Bits>());
        }

        auto specializedType = new IR::Type_Specialized(new IR::Type_Name("Counter"), typeArgs);
        return new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                            specializedType, node->arguments);
    } else {
        BUG("unexpected type in counter declaration ", node);
    }
    return node;
}

const IR::Node* CounterConverter::postorder(IR::ConstructorCallExpression *node) {
    BUG("counter constructor call is not converted");
    return node;
}

const IR::Node* DirectCounterConverter::postorder(IR::Declaration_Instance* node) {
    auto typeArgs = new IR::Vector<IR::Type>();
    if (auto anno = node->annotations->getSingle("min_width")) {
        auto min_width = anno->expr.at(0)->as<IR::Constant>().asInt();
        typeArgs->push_back(IR::Type::Bits::get(min_width));
    } else {
        auto min_width = IR::Type::Bits::get(32);
        typeArgs->push_back(min_width);
        WARNING("Could not infer min_width for counter %s, using bit<32>" << node);
    }
    auto specializedType = new IR::Type_Specialized(new IR::Type_Name("DirectCounter"), typeArgs);
    return new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                        specializedType, node->arguments);
}

const IR::Node* MeterConverter::postorder(IR::Declaration_Instance* node) {
    if (auto type = node->type->to<IR::Type_Name>()) {
        BUG_CHECK(type->path->name == "meter",
                  "meter converter cannot be applied to %1%", type->path->name);

        auto typeArgs = new IR::Vector<IR::Type>();
        if (auto s = node->arguments->at(0)->to<IR::Constant>()) {
            typeArgs->push_back(s->type->to<IR::Type_Bits>());
        }
        auto specializedType = new IR::Type_Specialized(new IR::Type_Name("Meter"), typeArgs);
        return new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                            specializedType, node->arguments);
    } else {
        BUG("unexpected type in meter declaration ", node);
    }
    return node;
}

const IR::Node* MeterConverter::postorder(IR::ConstructorCallExpression *node) {
    BUG("meter constructor call is not converted");
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

    auto meterColor = mce->arguments->at(1);
    auto size = meterColor->type->width_bits();
    BUG_CHECK(size != 0, "meter color cannot be bit<0>");
    auto statements = new IR::IndexedVector<IR::StatOrDecl>();
    auto args = new IR::Vector<IR::Expression>();
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
    statements->push_back(assign);
    return statements;
}

const IR::Node* DirectMeterConverter::postorder(IR::Declaration_Instance* node) {
    return new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                        new IR::Type_Name("DirectMeter"), node->arguments);
}

const IR::Node* DirectMeterConverter::postorder(IR::MethodCallStatement* node) {
    auto orig = getOriginal<IR::MethodCallStatement>();
    auto mce = orig->methodCall->to<IR::MethodCallExpression>();

    auto member = mce->method->to<IR::Member>();
    auto method = new IR::Member(node->srcInfo, member->expr, "execute");

    auto meterColor = mce->arguments->at(0);
    auto size = meterColor->type->width_bits();
    BUG_CHECK(size != 0, "meter color width cannot be bit<0>");
    auto methodcall = new IR::MethodCallExpression(node->srcInfo, method,
                                                   new IR::Vector<IR::Expression>());
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

//////////////////////////////////////////////////////////////////////////////////////////////

const IR::Node* ParserPriorityConverter::postorder(IR::AssignmentStatement* node) {
    auto stmt = getOriginal<IR::AssignmentStatement>();
    auto name = cstring::make_unique(structure->unique_names, "packet_priority", '_');
    structure->unique_names.insert(name);
    structure->nameMap.emplace(stmt, name);

    auto type = new IR::Type_Name("priority");
    auto inst = new IR::Declaration_Instance(name, type, new IR::Vector<IR::Expression>());
    structure->ingressParserDeclarations.push_back(inst);
    structure->egressParserDeclarations.push_back(inst->clone());

    auto member = new IR::Member(new IR::PathExpression(name), "set");
    auto result = new IR::MethodCallStatement(node->srcInfo, member, { node->right });
    return result;
}

const IR::Node* ParserCounterConverter::postorder(IR::AssignmentStatement* ) {
    auto stmt = getOriginal<IR::AssignmentStatement>();
    auto left = stmt->left;
    cstring base_name;
    if (auto member = left->to<IR::Member>())
        base_name = member->member;
    else
        base_name = "parser_counter";
    auto name = cstring::make_unique(structure->unique_names, base_name, '_');
    structure->unique_names.insert(name);
    structure->parserCounterNames.emplace(base_name, name);

    auto type = new IR::Type_Name("parser_counter");
    auto inst = new IR::Declaration_Instance(name, type, new IR::Vector<IR::Expression>());
    structure->ingressParserDeclarations.push_back(inst);
    structure->egressParserDeclarations.push_back(inst->clone());

    P4C_UNIMPLEMENTED("parser counter translation is not implemented");
    return nullptr;
}

const IR::Node* ParserCounterSelectionConverter::postorder(IR::Member* node) {
    auto member = getOriginal<IR::Member>();
    auto base_name = member->member;
    auto it = structure->parserCounterNames.find(base_name);
    if (it == structure->parserCounterNames.end())
        return node;
    auto method = new IR::Member(new IR::PathExpression(it->second), "is_zero");
    auto result = new IR::MethodCallStatement(node->srcInfo, method, {});
    return result;
}

}  // namespace V1

//////////////////////////////////////////////////////////////////////////////////////////////

namespace PSA {

const IR::Node* ParserConverter::postorder(IR::Member* node) {
    auto *orig = getOriginal<IR::Member>();
    RETURN_TRANSLATED_NODE_IF_FOUND(pathsToDo);
    RETURN_TRANSLATED_NODE_IF_FOUND(typeNamesToDo);
    return node;
}

const IR::Node* IngressParserConverter::postorder(IR::P4Parser *node) {
    auto parser = node->apply(cloner);
    auto params = parser->type->getApplyParameters();
    BUG_CHECK(params->size() == 6, "%1%: Expected 6 parameters for parser", parser);

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
    param = new IR::Parameter("ig_intr_md_from_parser_aux", IR::Direction::Out, type);
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
    param = new IR::Parameter("eg_intr_md_from_parser_aux", IR::Direction::Out, type);
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

const IR::Node* ControlConverter::postorder(IR::Member* node) {
    auto* orig = getOriginal<IR::Member>();
    RETURN_TRANSLATED_NODE_IF_FOUND(membersToDo);
    RETURN_TRANSLATED_NODE_IF_FOUND(pathsToDo);
    RETURN_TRANSLATED_NODE_IF_FOUND(typeNamesToDo);
    return node;
}

const IR::Node* IngressControlConverter::preorder(IR::P4Control* node) {
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
    param = new IR::Parameter("ig_intr_md_from_parser_aux", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md_from_prsr", param->name);
    paramList->push_back(param);

    // add ig_intr_md_for_tm
    path = new IR::Path("ingress_intrinsic_metadata_for_tm_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md_for_tm", param->name);
    paramList->push_back(param);

    // add ig_intr_md_for_mb
    path = new IR::Path("ingress_intrinsic_metadata_for_mirror_buffer_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_mb", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md_for_mb", param->name);
    paramList->push_back(param);

    // add ig_intr_md_for_dprsr
    path = new IR::Path("ingress_intrinsic_metadata_for_deparser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_deparser", IR::Direction::InOut, type);
    tnaParams.emplace("ig_intr_md_for_dprsr", param->name);
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

    auto result = new IR::BFN::TranslatedP4Control(node->srcInfo, "ingress", controlType,
                                                   node->constructorParams, *controlLocals,
                                                   node->body, tnaParams, INGRESS);
    return result;
}

const IR::Node* EgressControlConverter::preorder(IR::P4Control *node) {
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
    param = new IR::Parameter("eg_intr_md_from_parser_aux", IR::Direction::In, type);
    tnaParams.emplace("eg_intr_md_from_prsr", param->name);
    paramList->push_back(param);

    // add eg_intr_md_for_mb
    path = new IR::Path("egress_intrinsic_metadata_for_mirror_buffer_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_mb", IR::Direction::InOut, type);
    tnaParams.emplace("eg_intr_md_for_mb", param->name);
    paramList->push_back(param);

    // add eg_intr_md_for_oport
    path = new IR::Path("egress_intrinsic_metadata_for_output_port_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_oport", IR::Direction::InOut, type);
    tnaParams.emplace("eg_intr_md_for_oport", param->name);
    paramList->push_back(param);

    // add eg_intr_md_for_dprsr
    path = new IR::Path("egress_intrinsic_metadata_for_deparser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_deparser", IR::Direction::InOut, type);
    tnaParams.emplace("eg_intr_md_for_dprsr", param->name);
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

    auto result = new IR::BFN::TranslatedP4Control(node->srcInfo, "egress", controlType,
                                                   node->constructorParams, *controlLocals,
                                                   node->body, tnaParams, EGRESS);
    return result;
}

const IR::Node* IngressDeparserConverter::preorder(IR::P4Control* node) {
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

    // add ingress intrinsic metadata
    auto path = new IR::Path("ingress_intrinsic_metadata_t");
    auto type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md", param->name);
    paramList->push_back(param);

    // add mirror buffer intrinsic metadata
    path = new IR::Path("ingress_intrinsic_metadata_for_mirror_buffer_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_mb", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md_for_mb", param->name);
    paramList->push_back(param);

    // add deparser intrinsic metadata
    path = new IR::Path("ingress_intrinsic_metadata_for_deparser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_deparser", IR::Direction::In, type);
    tnaParams.emplace("ig_intr_md_for_deparser", param->name);
    paramList->push_back(param);

    // add mirror
    path = new IR::Path("mirror_packet");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("mirror", IR::Direction::None, type);
    tnaParams.emplace("mirror", param->name);
    paramList->push_back(param);

    // add resubmit
    path = new IR::Path("resubmit_packet");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("resubmit", IR::Direction::None, type);
    tnaParams.emplace("resubmit", param->name);
    paramList->push_back(param);

    // add digest
    path = new IR::Path("learning_packet");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("learning", IR::Direction::None, type);
    tnaParams.emplace("learning", param->name);
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

    auto result = new IR::BFN::TranslatedP4Control(deparser->srcInfo, "ingressDeparserImpl",
                                                   controlType, deparser->constructorParams,
                                                   *controlLocals, body, tnaParams, INGRESS);
    return result;
}

const IR::Node* EgressDeparserConverter::preorder(IR::P4Control* node) {
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

    // add mirror buffer intrinsic metadata
    auto path = new IR::Path("egress_intrinsic_metadata_for_mirror_buffer_t");
    auto type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_mb", IR::Direction::In, type);
    tnaParams.emplace("eg_intr_md_for_mb", param->name);
    paramList->push_back(param);

    // add eg_intr_md_for_dprsr
    path = new IR::Path("egress_intrinsic_metadata_for_deparser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_deparser", IR::Direction::In, type);
    tnaParams.emplace("eg_intr_md_for_dprsr", param->name);
    paramList->push_back(param);

    // add mirror
    path = new IR::Path("mirror_packet");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("mirror", IR::Direction::None, type);
    tnaParams.emplace("mirror", param->name);
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

    auto result = new IR::BFN::TranslatedP4Control(deparser->srcInfo, "egressDeparserImpl",
                                                   controlType, deparser->constructorParams,
                                                   *controlLocals, body, tnaParams, EGRESS);
    return result;
}

const IR::Node* MemberExpressionConverter::postorder(IR::Member *node) {
    // XXX(hanw) TBD
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
    } else {
        LOG3("Member expression " << node << " is not inside a translated control; "
                "won't translate it");
        return node;
    }

    auto& nameMap = thread == INGRESS ? structure->ingressMetadataNameMap
                                      : structure->egressMetadataNameMap;
    BUG_CHECK(!nameMap.empty(), "metadata translation map cannot be empty");
    auto it = nameMap.find(MetadataField{pathname, membername});
    if (it != nameMap.end()) {
        auto expr = new IR::PathExpression(it->second.structName);
        auto result = new IR::Member(node->srcInfo, expr, it->second.fieldName);
        const unsigned bitWidth = structure->metadataTypeMap.at(it->second);
        result->type = IR::Type::Bits::get(bitWidth);
        LOG3("Translating " << node << " to " << result);
        return result;
    }
    LOG4("No translation found for " << node);
    return node;
}

}  // namespace PSA

}  // namespace BFN
