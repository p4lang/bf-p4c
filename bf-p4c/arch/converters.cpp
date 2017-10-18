#include "converters.h"
#include "program_structure.h"

namespace BFN {

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

const IR::Node* ControlConverter::postorder(IR::MethodCallExpression* node) {
    auto* orig = getOriginal<IR::MethodCallExpression>();
    RETURN_TRANSLATED_NODE_IF_FOUND(meterCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(directMeterCalls);
    return node;
}

const IR::Node* ControlConverter::postorder(IR::MethodCallStatement* node) {
    auto* orig = getOriginal<IR::MethodCallStatement>();
    RETURN_TRANSLATED_NODE_IF_FOUND(hashCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(randomCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(resubmitCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(cloneCalls);
    RETURN_TRANSLATED_NODE_IF_FOUND(dropCalls);
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
    RETURN_TRANSLATED_NODE_IF_FOUND(parserCounterSelects);
    return node;
}

const IR::Node* IngressControlConverter::preorder(IR::P4Control* node) {
    auto params = node->type->getApplyParameters();
    BUG_CHECK(params->size() == 3, "%1% Expected 3 parameters for ingress", node);
    auto paramList = new IR::ParameterList({node->getApplyParameters()->parameters.at(0),
                                            node->getApplyParameters()->parameters.at(1)});
    // add ig_intr_md
    auto path = new IR::Path("ingress_intrinsic_metadata_t");
    auto type = new IR::Type_Name(path);
    auto param = new IR::Parameter("ig_intr_md", IR::Direction::In, type);
    paramList->push_back(param);

    // add ig_intr_md_from_prsr
    path = new IR::Path("ingress_intrinsic_metadata_from_parser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_from_parser_aux", IR::Direction::In, type);
    paramList->push_back(param);

    // add ig_intr_md_for_tm
    path = new IR::Path("ingress_intrinsic_metadata_for_tm_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::Out, type);
    paramList->push_back(param);

    // add ig_intr_md_for_mb
    path = new IR::Path("ingress_intrinsic_metadata_for_mirror_buffer_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_mb", IR::Direction::Out, type);
    paramList->push_back(param);

    // add ig_intr_md_for_dprsr
    path = new IR::Path("ingress_intrinsic_metadata_for_deparser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_deparser", IR::Direction::Out, type);
    paramList->push_back(param);

    auto controlType = new IR::Type_Control("ingress", paramList);

    auto controlLocals = new IR::IndexedVector<IR::Declaration>();
    controlLocals->append(structure->ingressDeclarations);
    controlLocals->append(node->controlLocals);

    auto result = new IR::P4Control(node->srcInfo, "ingress", controlType,
                                    node->constructorParams, *controlLocals,
                                    node->body);
    return result;
}

const IR::Node* EgressControlConverter::preorder(IR::P4Control *node) {
    auto params = node->type->getApplyParameters();
    BUG_CHECK(params->size() == 3, "%1% Expected 3 parameters for egress", node);
    auto paramList = new IR::ParameterList({node->getApplyParameters()->parameters.at(0),
                                            node->getApplyParameters()->parameters.at(1)});
    // add eg_intr_md
    auto path = new IR::Path("egress_intrinsic_metadata_t");
    auto type = new IR::Type_Name(path);
    auto param = new IR::Parameter("eg_intr_md", IR::Direction::In, type);
    paramList->push_back(param);

    // add eg_intr_md_from_prsr
    path = new IR::Path("egress_intrinsic_metadata_from_parser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_from_parser_aux", IR::Direction::In, type);
    paramList->push_back(param);

    // add eg_intr_md_for_mb
    path = new IR::Path("egress_intrinsic_metadata_for_mirror_buffer_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_mb", IR::Direction::Out, type);
    paramList->push_back(param);

    // add eg_intr_md_for_oport
    path = new IR::Path("egress_intrinsic_metadata_for_output_port_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_oport", IR::Direction::Out, type);
    paramList->push_back(param);

    // add ig_intr_md_for_dprsr
    path = new IR::Path("egress_intrinsic_metadata_for_deparser_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_deparser", IR::Direction::Out, type);
    paramList->push_back(param);

    auto controlType = new IR::Type_Control("egress", paramList);

    auto controlLocals = new IR::IndexedVector<IR::Declaration>();
    controlLocals->append(structure->egressDeclarations);
    controlLocals->append(node->controlLocals);

    auto result = new IR::P4Control(node->srcInfo, "egress", controlType,
                                    node->constructorParams, *controlLocals,
                                    node->body);
    return result;
}

const IR::Node* IngressDeparserConverter::preorder(IR::P4Control* node) {
    auto deparser = node->apply(cloner);
    auto params = deparser->type->getApplyParameters();
    BUG_CHECK(params->size() == 2, "%1% Expected 2 parameters for deparser", deparser);
    auto paramList = new IR::ParameterList({deparser->getApplyParameters()->parameters.at(0)});

    // add header
    auto hdr = deparser->getApplyParameters()->parameters.at(1);
    auto param = new IR::Parameter(hdr->name, hdr->annotations,
                                   IR::Direction::InOut, hdr->type);
    paramList->push_back(param);

    // add metadata
    CHECK_NULL(structure->user_metadata);
    auto meta = structure->user_metadata;
    param = new IR::Parameter(meta->name, meta->annotations,
                              IR::Direction::In, meta->type);
    paramList->push_back(param);

    // add deparser intrinsic metadata
    auto path = new IR::Path("ingress_intrinsic_metadata_for_deparser_t");
    auto type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_deparser", IR::Direction::In, type);
    paramList->push_back(param);

    // add mirror
    path = new IR::Path("mirror_packet");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("mirror", IR::Direction::None, type);
    paramList->push_back(param);

    // add resubmit
    path = new IR::Path("resubmit_packet");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("resubmit", IR::Direction::None, type);
    paramList->push_back(param);

    auto controlType = new IR::Type_Control("ingressDeparserImpl", paramList);

    auto controlLocals = new IR::IndexedVector<IR::Declaration>();
    controlLocals->append(structure->ingressDeparserDeclarations);
    controlLocals->append(node->controlLocals);

    auto statements = new IR::IndexedVector<IR::StatOrDecl>();
    statements->append(structure->ingressDeparserStatements);
    statements->append(deparser->body->components);
    auto body = new IR::BlockStatement(deparser->body->srcInfo, *statements);

    auto result = new IR::P4Control(deparser->srcInfo, "ingressDeparserImpl", controlType,
                                    deparser->constructorParams, *controlLocals, body);
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
    auto paramList = new IR::ParameterList({deparser->getApplyParameters()->parameters.at(0)});

    // add header
    auto hdr = deparser->getApplyParameters()->parameters.at(1);
    auto param = new IR::Parameter(hdr->name, hdr->annotations,
                                   IR::Direction::InOut, hdr->type);
    paramList->push_back(param);

    // add metadata
    CHECK_NULL(structure->user_metadata);
    auto meta = structure->user_metadata;
    param = new IR::Parameter(meta->name, meta->annotations,
                              IR::Direction::In, meta->type);
    paramList->push_back(param);

    // add eg_intr_md_for_dprsr
    auto path = new IR::Path("egress_intrinsic_metadata_for_deparser_t");
    auto type = new IR::Type_Name(path);
    param = new IR::Parameter("eg_intr_md_for_deparser", IR::Direction::In, type);
    paramList->push_back(param);

    // add mirror
    path = new IR::Path("mirror_packet");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("mirror", IR::Direction::None, type);
    paramList->push_back(param);

    auto controlType = new IR::Type_Control("egressDeparserImpl", paramList);

    auto controlLocals = new IR::IndexedVector<IR::Declaration>();
    controlLocals->append(structure->egressDeparserDeclarations);
    controlLocals->append(node->controlLocals);

    auto statements = new IR::IndexedVector<IR::StatOrDecl>();
    statements->append(structure->egressDeparserStatements);
    statements->append(deparser->body->components);
    auto body = new IR::BlockStatement(deparser->body->srcInfo, *statements);

    auto result = new IR::P4Control(deparser->srcInfo, "egressDeparserImpl", controlType,
                                    deparser->constructorParams, *controlLocals, body);
    return result;
}

const IR::Node* IngressParserConverter::postorder(IR::P4Parser *node) {
    auto parser = node->apply(cloner);
    auto params = parser->type->getApplyParameters();
    BUG_CHECK(params->size() == 4, "%1%: Expected 4 parameters for parser", parser);
    auto paramList = new IR::ParameterList({parser->getApplyParameters()->parameters.at(0),
                                            parser->getApplyParameters()->parameters.at(1),
                                            parser->getApplyParameters()->parameters.at(2)});
    // add ig_intr_md
    auto path = new IR::Path("ingress_intrinsic_metadata_t");
    auto type = new IR::Type_Name(path);
    auto param = new IR::Parameter("ig_intr_md", IR::Direction::Out, type);
    paramList->push_back(param);

    // add ig_intr_md_for_tm
    path = new IR::Path("ingress_intrinsic_metadata_for_tm_t");
    type = new IR::Type_Name(path);
    param = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::Out, type);
    paramList->push_back(param);

    auto parser_type = new IR::Type_Parser("ingressParserImpl", paramList);

    auto parserLocals = new IR::IndexedVector<IR::Declaration>();
    parserLocals->append(structure->ingressParserDeclarations);
    parserLocals->append(node->parserLocals);

    auto result = new IR::P4Parser(parser->srcInfo, "ingressParserImpl", parser_type,
                                   parser->constructorParams, *parserLocals,
                                   parser->states);
    return result;
}

const IR::Node* EgressParserConverter::postorder(IR::AssignmentStatement* ) {
    // remove all set_metadata from egress parser
    return nullptr;
}

const IR::Node* EgressParserConverter::postorder(IR::P4Parser* node) {
    auto parser = node->apply(cloner);
    auto params = parser->type->getApplyParameters();
    /// assume we are dealing with egress parser
    BUG_CHECK(params->size() == 4, "%1%: Expected 4 parameters for parser", parser);
    auto paramList = new IR::ParameterList({parser->getApplyParameters()->parameters.at(0),
                                            parser->getApplyParameters()->parameters.at(1),
                                            parser->getApplyParameters()->parameters.at(2)});
    // add ig_intr_md
    auto path = new IR::Path("egress_intrinsic_metadata_t");
    auto type = new IR::Type_Name(path);
    auto param = new IR::Parameter("eg_intr_md", IR::Direction::Out, type);
    paramList->push_back(param);
    auto parser_type = new IR::Type_Parser("egressParserImpl", paramList);
    auto result = new IR::P4Parser(parser->srcInfo, "egressParserImpl", parser_type,
                                   parser->constructorParams, parser->parserLocals,
                                   parser->states);
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
    CHECK_NULL(expr);
    auto pathname = expr->path->name;

    BUG_CHECK(!structure->metadataMap.empty(), "metadata translation map cannot be empty");
    auto it = structure->metadataMap.find(std::make_pair(pathname, membername));
    if (it != structure->metadataMap.end()) {
        auto expr = new IR::PathExpression(it->second.first);
        auto result = new IR::Member(node->srcInfo, expr, it->second.second);
        return result;
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
    auto it = structure->hashNames.find(orig);
    if (it != structure->hashNames.end()) {
        hashName = it->second; }

    auto member = new IR::Member(new IR::PathExpression(hashName), "get_hash");

    auto src_size = pBase->type->width_bits();
    auto dst_size = pDest->type->width_bits();
    if (src_size != dst_size) {
        WARNING("casting bit<" << src_size << "> to bit<" << dst_size << ">");
        return new IR::AssignmentStatement(pDest,
                   new IR::Cast(IR::Type_Bits::get(dst_size),
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
    auto it = structure->randomNames.find(orig);
    if (it != structure->randomNames.end()) {
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

        auto typeArgs = node->arguments->at(0);
        BUG_CHECK(typeArgs->is<IR::Constant>(),
                  "Expected constant argument in %1%", type->path->name);

        auto constant = typeArgs->to<IR::Constant>();
        auto typeBits = constant->type->to<IR::Type_Bits>();
        auto args = new IR::Vector<IR::Type>({ typeBits });
        auto specializedType = new IR::Type_Specialized(new IR::Type_Name("counter"), args);
        auto instanceArgs = new IR::Vector<IR::Expression>({node->arguments->at(1),
                                                            node->arguments->at(0)});
        return new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                            specializedType, instanceArgs);
    } else {
        BUG("unexpected type in counter declaration ", node);
    }
    return node;
}

const IR::Node* CounterConverter::postorder(IR::ConstructorCallExpression *node) {
    BUG("counter constructor call is not converted");
    return node;
}

/*
 * counter<_>(counter_type_t.PACKETS) counter_name;
 */
const IR::Node* DirectCounterConverter::postorder(IR::Declaration_Instance* node) {
    return new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                        new IR::Type_Name("direct_counter"), node->arguments);
}

const IR::Node* MeterConverter::postorder(IR::Declaration_Instance* node) {
    if (auto type = node->type->to<IR::Type_Name>()) {
        BUG_CHECK(type->path->name == "meter",
                  "meter converter cannot be applied to %1%", type->path->name);

        auto typeArgs = node->arguments->at(0);
        BUG_CHECK(typeArgs->is<IR::Constant>(),
                  "Expected constant argument in %1%", type->path->name);

        auto constant = typeArgs->to<IR::Constant>();
        auto typeBits = constant->type->to<IR::Type_Bits>();
        auto args = new IR::Vector<IR::Type>({ typeBits });
        auto specializedType = new IR::Type_Specialized(new IR::Type_Name("meter"), args);
        auto instanceArgs = new IR::Vector<IR::Expression>({node->arguments->at(1),
                                                            node->arguments->at(0)});
        return new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                            specializedType, instanceArgs);
    } else {
        BUG("unexpected type in meter declaration ", node);
    }
    return node;
}

const IR::Node* MeterConverter::postorder(IR::ConstructorCallExpression *node) {
    BUG("meter constructor call is not converted");
    return node;
}

const IR::Node* MeterConverter::postorder(IR::MethodCallExpression* node) {
    auto member = node->method->to<IR::Member>();
    BUG_CHECK(member->member == "execute_meter",
              "unexpected meter method %1%", member->member);
    auto method = new IR::Member(node->srcInfo, member->expr, "execute");

    auto meterColor = node->arguments->at(1);
    auto size = meterColor->type->width_bits();
    BUG_CHECK(size != 0, "meter color cannot be bit<0>");
    auto args = new IR::Vector<IR::Expression>();
    args->push_back(node->arguments->at(0));
    if (size != 2) {
        WARNING("casting argument " <<  node->arguments->at(1) << " to bit<2>");
        args->push_back(new IR::Cast(IR::Type_Bits::get(2), node->arguments->at(1)));
    }
    return new IR::MethodCallExpression(node->srcInfo, method, args);
}
/**
 * direct_meter(meter_type_t.PACKETS) meter_name;
 * XXX(hanw): changed direct_meter<bit<32>> to direct_meter
 */
const IR::Node* DirectMeterConverter::postorder(IR::Declaration_Instance* node) {
    return new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                        new IR::Type_Name("direct_meter"), node->arguments);
}

const IR::Node* DirectMeterConverter::postorder(IR::MethodCallExpression* node) {
    auto member = node->method->to<IR::Member>();
    if (member->member == "read") {
        auto method = new IR::Member(node->srcInfo, member->expr, "execute");

        auto meterColor = node->arguments->at(0);
        auto size = meterColor->type->width_bits();
        BUG_CHECK(size != 0, "meter color width cannot be bit<0>");
        auto args = new IR::Vector<IR::Expression>();
        if (size != 2) {
            WARNING("casting argument " << node->arguments->at(0) << " to bit<2>");
            args->push_back(new IR::Cast(IR::Type_Bits::get(2), node->arguments->at(0)));
        }
        return new IR::MethodCallExpression(node->srcInfo, method, node->typeArguments, args);
    } else {
        BUG("Unexpected direct_meter method %s", member->member);
        return node;
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////

const IR::Node* ParserPriorityConverter::postorder(IR::AssignmentStatement* node) {
    auto stmt = getOriginal<IR::AssignmentStatement>();
    auto name = cstring::make_unique(structure->unique_names, "packet_priority", '_');
    structure->unique_names.insert(name);
    structure->priorityNames.emplace(stmt, name);

    auto type = new IR::Type_Name("priority");
    auto inst = new IR::Declaration_Instance(name, type, new IR::Vector<IR::Expression>());
    structure->ingressParserDeclarations.push_back(inst);

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
}  // namespace BFN
