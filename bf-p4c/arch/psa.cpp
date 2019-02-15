#include <cmath>
#include <fstream>
#include "bf-p4c/device.h"
#include "intrinsic_metadata.h"
#include "psa.h"
#include "rewrite_packet_path.h"
#include "lib/bitops.h"
#include "midend/convertEnums.h"
#include "bridge_metadata.h"
#include "midend/copyStructures.h"
#include "midend/validateProperties.h"
#include "psa_program_structure.h"
#include "psa_converters.h"
#include "bf-p4c/midend/type_checker.h"

namespace BFN {

namespace PSA {
//////////////////////////////////////////////////////////////////////////////////////////////

class PacketPathTo8Bits : public P4::ChooseEnumRepresentation {
    bool convert(const IR::Type_Enum *type) const override {
        LOG1("Type Enum name " << type);
        if (type->name != "PSA_PacketPath_t") {
            return false;
        }
        return true;
    }

    unsigned enumSize(unsigned /* size */) const override { return 8; }
};

class AnalyzeProgram : public Inspector {
    template<class P4Type, class BlockType>
    void analyzeArchBlock(cstring gressName, cstring blockName, cstring type) {
        auto main = structure->toplevel->getMain();
        auto gress = main->findParameterValue(gressName);
        CHECK_NULL(gress);
        auto gressPackage = gress->to<IR::PackageBlock>();
        CHECK_NULL(gressPackage);
        auto block = gressPackage->findParameterValue(blockName);
        CHECK_NULL(block);
        auto blockType = block->to<BlockType>();
        CHECK_NULL(blockType);
        LOG1("find block " << blockType->container->name << " of type " << type);
        structure->blockNames.emplace(type, blockType->container->name);
    }

 public:
    explicit AnalyzeProgram(PSA::ProgramStructure* structure,
                            P4::ReferenceMap *refMap, P4::TypeMap *typeMap)
        : structure(structure), refMap(refMap), typeMap(typeMap)
    { CHECK_NULL(structure); setName("AnalyzePsaProgram"); }

    bool preorder(const IR::P4Program*) override {
        analyzeArchBlock<IR::P4Parser, IR::ParserBlock>(
            "ingress", "ip", PSA::ProgramStructure::INGRESS_PARSER);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
            "ingress", "ig", PSA::ProgramStructure::INGRESS);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
            "ingress", "id", PSA::ProgramStructure::INGRESS_DEPARSER);
        analyzeArchBlock<IR::P4Parser, IR::ParserBlock>(
            "egress", "ep", PSA::ProgramStructure::EGRESS_PARSER);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
            "egress", "eg", PSA::ProgramStructure::EGRESS);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
            "egress", "ed", PSA::ProgramStructure::EGRESS_DEPARSER);
        return true;
    }
    void postorder(const IR::Type_Action* node) override
    { structure->action_types.push_back(node); }
    void postorder(const IR::Type_StructLike* node) override
    { structure->type_declarations.emplace(node->name, node); }
    void postorder(const IR::Type_Typedef* node) override {
        structure->type_declarations.emplace(node->name, node);
    }
    void postorder(const IR::Type_Enum* node) override {
        structure->enums.emplace(node->name, node);
    }
    void postorder(const IR::P4Parser* node) override {
        structure->parsers.emplace(node->name, node);
        process_packet_path_params(node);
    }
    void postorder(const IR::P4Control* node) override {
        structure->controls.emplace(node->name, node);
        process_packet_path_params(node);
    }

    // 'compiler_generated_metadata_t' is the last struct in the program.
    void end_apply() override {
        auto* cgAnnotation = new IR::Annotations({
             new IR::Annotation(IR::ID("__compiler_generated"), { })});

        auto cgm = new IR::Type_Struct("compiler_generated_metadata_t", cgAnnotation);
        cgm->fields.push_back(
            new IR::StructField("mirror_id", IR::Type::Bits::get(10)));
        cgm->fields.push_back(
            new IR::StructField("packet_path", IR::Type::Bits::get(8)));
        // TODO(hanw): Map clone_src + clone_digest_id to packet_path
        cgm->fields.push_back(
            new IR::StructField("clone_src", IR::Type::Bits::get(4)));
        cgm->fields.push_back(
            new IR::StructField("clone_digest_id", IR::Type::Bits::get(4)));
        // add bridged_metadata header
        cgm->fields.push_back(
            new IR::StructField("^bridged_metadata",
                typeMap->getTypeType(structure->bridge.p4Type, true)));

        cgm->fields.push_back(new IR::StructField("drop", IR::Type::Boolean::get()));
        cgm->fields.push_back(new IR::StructField("resubmit", IR::Type::Boolean::get()));
        cgm->fields.push_back(new IR::StructField("clone_i2e", IR::Type::Boolean::get()));
        cgm->fields.push_back(new IR::StructField("clone_e2e", IR::Type::Boolean::get()));

        for (auto f : bridged_fields) {
            cgm->fields.push_back(f);
        }

        structure->type_declarations.emplace("compiler_generated_metadata_t", cgm);
    }

    // program structure keeps a map from architecture param name to user-provided param name
    // it also keeps the relevant information to translate resubmit/clone/recirc operation to tna.
    void process_packet_path_params(const IR::P4Parser* node) {
        if (node->name == structure->getBlockName(PSA::ProgramStructure::INGRESS_PARSER)) {
            auto param = node->getApplyParameters()->getParameter(1);
            structure->ingress_parser.psaParams.emplace("hdr", param->name);
            param = node->getApplyParameters()->getParameter(2);
            structure->ingress_parser.psaParams.emplace("metadata", param->name);
            param = node->getApplyParameters()->getParameter(3);
            structure->ingress_parser.psaParams.emplace("istd", param->name);
            param = node->getApplyParameters()->getParameter(4);
            structure->resubmit.paramNameInParser = param->name;
            structure->resubmit.p4Type = param->type;
            structure->ingress_parser.psaParams.emplace("resubmit_metadata", param->name);
            param = node->getApplyParameters()->getParameter(5);
            structure->recirculate.paramNameInParser = param->name;
            structure->recirculate.p4Type = param->type;
            structure->ingress_parser.psaParams.emplace("recirc_metadata", param->name);
        } else if (node->name == structure->getBlockName(PSA::ProgramStructure::EGRESS_PARSER)) {
            auto param = node->getApplyParameters()->getParameter(1);
            structure->egress_parser.psaParams.emplace("hdr", param->name);
            param = node->getApplyParameters()->getParameter(2);
            structure->egress_parser.psaParams.emplace("metadata", param->name);
            param = node->getApplyParameters()->getParameter(3);
            structure->egress_parser.psaParams.emplace("istd", param->name);
            param = node->getApplyParameters()->getParameter(4);
            structure->bridge.paramNameInParser = param->name;
            structure->bridge.p4Type = param->type;
            structure->egress_parser.psaParams.emplace("normal_metadata", param->name);
            // add translation for bridged metadata
            auto bridge_md_type = typeMap->getTypeType(param->type, true);
            for (auto f : bridge_md_type->to<IR::Type_StructLike>()->fields) {
                structure->addMetadata(EGRESS,
                    MetadataField{param->name, f->name, f->type->width_bits()},
                    MetadataField{"^bridged_metadata", f->name,
                        f->type->width_bits(), true /* isCG */});
            }
            structure->bridgedType = bridge_md_type;
            param = node->getApplyParameters()->getParameter(5);
            structure->clone_i2e.paramNameInParser = param->name;
            structure->clone_i2e.p4Type = param->type;
            structure->egress_parser.psaParams.emplace("clone_i2e_metadata", param->name);
            param = node->getApplyParameters()->getParameter(6);
            structure->clone_e2e.paramNameInParser = param->name;
            structure->clone_e2e.p4Type = param->type;
            structure->egress_parser.psaParams.emplace("clone_e2e_metadata", param->name);
        }
    }

    void analyzeIfStatement(const IR::IfStatement* ifStatement) {
        CHECK_NULL(ifStatement);
        if (!ifStatement->ifTrue || ifStatement->ifFalse) {
            return;
        }
        auto mce = ifStatement->condition->to<IR::MethodCallExpression>();
        if (!mce) return;
        auto mi = P4::MethodInstance::resolve(mce, refMap, typeMap);
        if (auto ef = mi->to<P4::ExternFunction>()) {
            auto name = ef->method->name;
            if (name == "psa_resubmit") {
                structure->resubmit.ifStatements.push_back(ifStatement);
            } else if (name == "psa_clone_i2e") {
                structure->clone_i2e.ifStatements.push_back(ifStatement);
            } else if (name == "psa_clone_e2e") {
                structure->clone_e2e.ifStatements.push_back(ifStatement);
            } else if (name == "psa_recirculate") {
                structure->recirculate.ifStatements.push_back(ifStatement);
            } else if (name == "psa_normal") {
                structure->bridge.ifStatements.push_back(ifStatement);
            }
        }
    }

    // assume only used in deparser.
    void collectPacketPathInfo(const IR::P4Control* node) {
        for (auto stmt : node->body->components) {
            if (auto ifStatement = stmt->to<IR::IfStatement>()) {
                analyzeIfStatement(ifStatement);
            }
        }
    }

    void process_packet_path_params(const IR::P4Control* node) {
        if (node->name == structure->getBlockName(ProgramStructure::INGRESS_DEPARSER)) {
            auto param = node->getApplyParameters()->getParameter(1);
            structure->clone_i2e.paramNameInDeparser = param->name;
            structure->clone_i2e.p4Type = param->type;
            param = node->getApplyParameters()->getParameter(2);
            structure->resubmit.paramNameInDeparser = param->name;
            structure->resubmit.p4Type = param->type;
            param = node->getApplyParameters()->getParameter(3);
            structure->bridge.paramNameInDeparser = param->name;
            structure->bridge.p4Type = param->type;
            // add translation for bridged metadata
            auto bridge_md_type = typeMap->getTypeType(param->type, true);
            for (auto f : bridge_md_type->to<IR::Type_StructLike>()->fields) {
                structure->addMetadata(INGRESS,
                    MetadataField{param->name, f->name, f->type->width_bits()},
                    MetadataField{"^bridged_metadata", f->name,
                                  f->type->width_bits(), true /* isCG */});
                bridged_fields.emplace(new IR::StructField(f->name,
                            IR::Type::Bits::get(f->type->width_bits())));
            }
            param = node->getApplyParameters()->getParameter(4);
            structure->ingress_deparser.psaParams.emplace("hdr", param->name);
            param = node->getApplyParameters()->getParameter(5);
            structure->ingress_deparser.psaParams.emplace("metadata", param->name);
            param = node->getApplyParameters()->getParameter(6);
            structure->ingress_deparser.psaParams.emplace("istd", param->name);
            collectPacketPathInfo(node);
        } else if (node->name == structure->getBlockName(ProgramStructure::EGRESS_DEPARSER)) {
            auto param = node->getApplyParameters()->getParameter(1);
            structure->clone_e2e.paramNameInDeparser = param->name;
            structure->clone_e2e.p4Type = param->type;
            param = node->getApplyParameters()->getParameter(2);
            structure->recirculate.paramNameInDeparser = param->name;
            structure->recirculate.p4Type = param->type;
            param = node->getApplyParameters()->getParameter(3);
            structure->egress_deparser.psaParams.emplace("hdr", param->name);
            param = node->getApplyParameters()->getParameter(4);
            structure->egress_deparser.psaParams.emplace("metadata", param->name);
            param = node->getApplyParameters()->getParameter(5);
            structure->egress_deparser.psaParams.emplace("istd", param->name);
            param = node->getApplyParameters()->getParameter(6);
            structure->egress_deparser.psaParams.emplace("edstd", param->name);
            collectPacketPathInfo(node);
        } else if (node->name == structure->getBlockName(ProgramStructure::INGRESS)) {
            auto param = node->getApplyParameters()->getParameter(0);
            structure->ingress.psaParams.emplace("hdr", param->name);
            param = node->getApplyParameters()->getParameter(1);
            structure->ingress.psaParams.emplace("metadata", param->name);
            param = node->getApplyParameters()->getParameter(2);
            structure->ingress.psaParams.emplace("istd", param->name);
            param = node->getApplyParameters()->getParameter(3);
            structure->ingress.psaParams.emplace("ostd", param->name);
        } else if (node->name == structure->getBlockName(ProgramStructure::EGRESS)) {
            auto param = node->getApplyParameters()->getParameter(0);
            structure->egress.psaParams.emplace("hdr", param->name);
            param = node->getApplyParameters()->getParameter(1);
            structure->egress.psaParams.emplace("metadata", param->name);
            param = node->getApplyParameters()->getParameter(2);
            structure->egress.psaParams.emplace("istd", param->name);
            param = node->getApplyParameters()->getParameter(3);
            structure->egress.psaParams.emplace("ostd", param->name);
        }
    }

 private:
    PSA::ProgramStructure* structure;
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    ordered_set<IR::StructField*> bridged_fields;
};

struct TranslatePacketPathIfStatement : public Transform {
    TranslatePacketPathIfStatement(const PacketPathInfo& info, PSA::ProgramStructure* structure,
                                   gress_t gress)
        : info(info), structure(structure), gress(gress)
    { setName("TranslatePacketPathIfStatement"); }

    const IR::Expression *preorder(IR::MethodCallExpression *mce) override {
        if (auto expr = mce->method->to<IR::PathExpression>()) {
            if (auto path = expr->path->to<IR::Path>()) {
                if (path->name == "psa_resubmit") {
                    generated_metadata = "__resubmit_data";
                    auto expr = new IR::LAnd(
                        new IR::Member(
                            new IR::PathExpression("compiler_generated_meta"), IR::ID("drop")),
                        new IR::Member(
                            new IR::PathExpression("compiler_generated_meta"), IR::ID("resubmit")));
                    return expr;
                } else if (path->name == "psa_clone_i2e") {
                    generated_metadata = "__clone_i2e_data";
                    auto expr = new IR::Member(
                        new IR::PathExpression("compiler_generated_meta"), IR::ID("clone_i2e"));
                    return expr;
                } else if (path->name == "psa_clone_e2e") {
                    generated_metadata = "__clone_e2e_data";
                    auto expr = new IR::Member(
                        new IR::PathExpression("compiler_generated_meta"), IR::ID("clone_e2e"));
                    return expr;
                } else if (path->name == "psa_recirculate") {
                    generated_metadata = "__recirculate_data";
                    // FIXME: !istd.drop && (edstd.egress_port == PORT_RECIRCULATE)
                    auto expr = new IR::LNot(new IR::Member(
                        new IR::PathExpression("compiler_generated_meta"), IR::ID("drop")));
                    return expr;
                } else if (path->name == "psa_normal") {
                    auto expr = new IR::LAnd(
                        new IR::LNot(new IR::Member(
                            new IR::PathExpression("compiler_generated_meta"), IR::ID("drop"))),
                        new IR::LNot(new IR::Member(
                            new IR::PathExpression("compiler_generated_meta"),
                            IR::ID("resubmit"))));
                    return expr;
                }
            }
        }
        return mce;
    }

    const IR::Member *preorder(IR::Member *node) override {
        auto membername = node->member.name;
        auto expr = node->expr->to<IR::PathExpression>();
        if (!expr) return node;
        auto pathname = expr->path->name;

        if (pathname == info.paramNameInParser) {
            auto path = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                                       IR::ID(generated_metadata));
            auto member = new IR::Member(path, membername);
            return member;
        }

        if (pathname == info.paramNameInDeparser) {
            auto path = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                                       IR::ID(generated_metadata));
            auto member = new IR::Member(path, membername);
            return member;
        }

        if (gress == INGRESS) {
            if (pathname == structure->ingress_deparser.psaParams.at("metadata")) {
                auto path = new IR::PathExpression(structure->ingress.psaParams.at("metadata"));
                auto member = new IR::Member(path, membername);
                return member;
            } else if (pathname == structure->ingress_deparser.psaParams.at("hdr")) {
                auto path = new IR::PathExpression(structure->ingress.psaParams.at("hdr"));
                auto member = new IR::Member(path, membername);
                return member;
            }
        } else if (gress == EGRESS) {
             if (pathname == structure->egress_deparser.psaParams.at("metadata")) {
                auto path = new IR::PathExpression(structure->egress.psaParams.at("metadata"));
                auto member = new IR::Member(path, membername);
                return member;
            } else if (pathname == structure->egress_deparser.psaParams.at("hdr")) {
                auto path = new IR::PathExpression(structure->egress.psaParams.at("hdr"));
                auto member = new IR::Member(path, membername);
                return member;
            }
        }
        return node;
    }

    const IR::StatOrDecl* convert(const IR::Node* node) {
        auto result = node->apply(*this);
        return result->to<IR::StatOrDecl>();
    }

    const PacketPathInfo& info;
    PSA::ProgramStructure* structure;
    gress_t gress;
    cstring generated_metadata;
};

class TranslateProgram : public Inspector {
    PSA::ProgramStructure* structure;
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

 public:
    explicit TranslateProgram(PSA::ProgramStructure* structure,
                                  P4::ReferenceMap *refMap, P4::TypeMap *typeMap)
            : structure(structure), refMap(refMap), typeMap(typeMap) {
        CHECK_NULL(structure); setName("TranslateProgram");
    }


    void postorder(const IR::Member* node) override {
        ordered_set<cstring> toTranslateInControl = {"istd", "ostd"};
        ordered_set<cstring> toTranslateInParser = {"istd", "ostd"};
        auto gress = findOrigCtxt<IR::P4Control>();
        if (gress) {
            if (auto expr = node->expr->to<IR::PathExpression>()) {
                auto path = expr->path->to<IR::Path>();
                CHECK_NULL(path);
                auto it = toTranslateInControl.find(path->name);
                if (it != toTranslateInControl.end()) {
                    if (gress->name == structure->getBlockName(
                            PSA::ProgramStructure::INGRESS)) {
                        structure->pathsThread.emplace(node, INGRESS);
                        structure->pathsToDo.emplace(node, node);
                    } else if (gress->name == structure->getBlockName(
                            PSA::ProgramStructure::EGRESS)) {
                        structure->pathsThread.emplace(node, EGRESS);
                        structure->pathsToDo.emplace(node, node);
                    } else {
                        WARNING("path " << node << " in "
                                        << gress->name.name << " is not translated");
                    }
                }
            } else if (auto expr = node->expr->to<IR::TypeNameExpression>()) {
                auto tn = expr->typeName->to<IR::Type_Name>();
                CHECK_NULL(tn);
                structure->typeNamesToDo.emplace(node, node);
            } else {
                WARNING("Unable to translate path " << node);
            }
        }
        auto parser = findOrigCtxt<IR::P4Parser>();
        if (parser) {
            if (auto expr = node->expr->to<IR::PathExpression>()) {
                auto path = expr->path->to<IR::Path>();
                CHECK_NULL(path);
                auto it = toTranslateInParser.find(path->name);
                if (it == toTranslateInParser.end())
                    return;
                if (expr->type->is<IR::Type_Struct>()) {
                    structure->pathsToDo.emplace(node, node);
                } else {
                    WARNING("metadata " << node << " is not converted");
                }
            } else if (auto expr = node->expr->to<IR::TypeNameExpression>()) {
                auto tn = expr->typeName->to<IR::Type_Name>();
                CHECK_NULL(tn);
                structure->typeNamesToDo.emplace(node, node);
            } else {
                WARNING("Expression " << node << " is not converted");
            }
        }
    }

    void cvtActionSelector(const IR::Declaration_Instance* node) {
        auto declarations = new IR::IndexedVector<IR::Declaration>();

        // Create a new instance of Hash<W>
        auto typeArgs = new IR::Vector<IR::Type>();
        auto w = node->arguments->at(2)->expression->to<IR::Constant>()->asInt();
        typeArgs->push_back(IR::Type::Bits::get(w));

        auto args = new IR::Vector<IR::Argument>();
        args->push_back(node->arguments->at(0));

        auto specializedType = new IR::Type_Specialized(
            new IR::Type_Name("Hash"), typeArgs);
        auto hashName = cstring::make_unique(
            structure->unique_names, node->name + "__hash_", '_');
        structure->unique_names.insert(hashName);
        declarations->push_back(
            new IR::Declaration_Instance(hashName, specializedType, args));

        args = new IR::Vector<IR::Argument>();
        // size
        args->push_back(node->arguments->at(1));
        // hash
        args->push_back(new IR::Argument(new IR::PathExpression(hashName)));
        // selector_mode
        auto sel_mode = new IR::Member(
            new IR::TypeNameExpression("SelectorMode_t"), "FAIR");
        if (auto anno = node->annotations->getSingle("mode")) {
            auto mode = anno->expr.at(0)->to<IR::StringLiteral>();
            if (mode->value == "resilient")
                sel_mode->member = IR::ID("RESILIENT");
            else if (mode->value != "fair" && mode->value != "non_resilient")
                BUG("Selector mode provided for the selector is not supported", node);
        } else {
            WARNING("No mode specified for the selector %s. Assuming fair" << node);
        }
        args->push_back(new IR::Argument(sel_mode));

        declarations->push_back(new IR::Declaration_Instance(
            node->srcInfo, node->name, node->annotations, node->type, args));
        structure->_map.emplace(node, declarations);
    }

    void cvtRandom(const IR::Declaration_Instance* node) {
        // TODO: check min/max of random, can only support 0 ~ 2**w-1 on tofino
        auto args = new IR::Vector<IR::Argument>();
        auto inst = new IR::Declaration_Instance(node->name, node->type, args);
        structure->_map.emplace(node, inst);
    }

    // top level PSA_Switch could instantiate anonymous instances of
    // IngressPipeline and EgressPipeline
    void process_package_instance(const IR::Type_Specialized* tp) {
        if (!tp->baseType->is<IR::Type_Name>())
            return;
        auto tn = tp->baseType->to<IR::Type_Name>();
        if (tn->path->name == "IngressPipeline") {
            structure->type_params[PSA::TYPE_IH] =
                    tp->arguments->at(0)->to<IR::Type_Name>()->path->name;
            structure->type_params[PSA::TYPE_IM] =
                    tp->arguments->at(1)->to<IR::Type_Name>()->path->name;
        } else if (tn->path->name == "EgressPipeline") {
            structure->type_params[PSA::TYPE_EH] =
                    tp->arguments->at(0)->to<IR::Type_Name>()->path->name;
            structure->type_params[PSA::TYPE_EM] =
                    tp->arguments->at(1)->to<IR::Type_Name>()->path->name;
        }
    }

    void postorder(const IR::Declaration_Instance* node) override {
        if (auto ts = node->type->to<IR::Type_Specialized>()) {
            if (!ts->baseType->is<IR::Type_Name>())
                return;
            auto name = ts->baseType->to<IR::Type_Name>();
            if (name->path->name == "PSA_Switch") {
                for (auto arg : *node->arguments) {
                    if (auto ctr = arg->expression->to<IR::ConstructorCallExpression>()) {
                        // skip PacketReplicationEngine and BufferingQueueingEngine
                        if (!ctr->constructedType->is<IR::Type_Specialized>())
                            continue;
                        auto type = ctr->constructedType->to<IR::Type_Specialized>();
                        process_package_instance(type);
                    }
                }
            } else if (name->path->name == "IngressPipeline" ||
                       name->path->name == "EgressPipeline") {
                process_package_instance(ts);
            } else if (name->path->name == "Random") {
                cvtRandom(node);
            }
        } else if (auto typeName = node->type->to<IR::Type_Name>()) {
            auto name = typeName->path->name;
            if (name == "ActionSelector") {
                cvtActionSelector(node);
            }
        }
    }

    void addExternMethodCall(cstring name, const IR::Node* node) {
        if (structure->methodcalls.count(name) == 0) {
            TranslationMap m;
            structure->methodcalls.emplace(name, m);
        }
        structure->methodcalls[name].emplace(node, node);
    }

    void postorder(const IR::MethodCallStatement *node) override {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        CHECK_NULL(mce);
        auto mi = P4::MethodInstance::resolve(node, refMap, typeMap);
        if (auto em = mi->to<P4::ExternMethod>()) {
            cstring name = em->actualExternType->name;
            addExternMethodCall(name, node);
        } else if (mi->is<P4::ExternFunction>()) {
            WARNING("extern function translation is not supported");
        }
    }

    void postorder(const IR::MethodCallExpression *node) override {
        auto mi = P4::MethodInstance::resolve(node, refMap, typeMap);
        if (auto em = mi->to<P4::ExternMethod>()) {
            cstring name = em->actualExternType->name;
            if (name == "Hash") {
                HashConverter conv(structure);
                structure->_map.emplace(node, node->apply(conv));
            } else if (name == "Random") {
                RandomConverter conv(structure);
                structure->_map.emplace(node, node->apply(conv));
            }
            addExternMethodCall(name, node);
        } else if (mi->is<P4::ExternFunction>()) {
            WARNING("extern function translation is not supported");
        }
    }

    profile_t init_apply(const IR::Node* root) override {
        TranslatePacketPathIfStatement cvt_resubmit(structure->resubmit, structure, INGRESS);
        for (auto stmt : structure->resubmit.ifStatements) {
            structure->ingressStatements.push_back(cvt_resubmit.convert(stmt));
            structure->_map.emplace(stmt, nullptr);
        }
        TranslatePacketPathIfStatement cvt_ci2e(structure->clone_i2e, structure, INGRESS);
        for (auto stmt : structure->clone_i2e.ifStatements) {
            structure->ingressStatements.push_back(cvt_ci2e.convert(stmt));
            structure->_map.emplace(stmt, nullptr);
        }
        TranslatePacketPathIfStatement cvt_ce2e(structure->clone_e2e, structure, EGRESS);
        for (auto stmt : structure->clone_e2e.ifStatements) {
            structure->egressStatements.push_back(cvt_ce2e.convert(stmt));
            structure->_map.emplace(stmt, nullptr);
        }
        TranslatePacketPathIfStatement cvt_recirc(structure->recirculate, structure, EGRESS);
        for (auto stmt : structure->recirculate.ifStatements) {
            structure->egressStatements.push_back(cvt_recirc.convert(stmt));
            structure->_map.emplace(stmt, nullptr);
        }
        return Inspector::init_apply(root);
    }
};

class LoadTargetArchitecture : public Inspector {
    PSA::ProgramStructure* structure;

 public:
    explicit LoadTargetArchitecture(PSA::ProgramStructure* structure) : structure(structure) {
        setName("LoadTargetArchitecture");
        CHECK_NULL(structure);
    }

    void setup_metadata_map() {
        structure->addMetadata(INGRESS,
                               MetadataField{"istd", "ingress_port", 9},
                               MetadataField{"ig_intr_md", "ingress_port", 9});
        structure->addMetadata(EGRESS,
                               MetadataField{"istd", "ingress_port", 9},
                               MetadataField{"eg_intr_md", "ingress_port", 9});

        structure->addMetadata(INGRESS,
                               MetadataField{"istd", "ingress_timestamp", 48},
                               MetadataField{"ig_intr_md", "ingress_mac_tstamp", 48});
        structure->addMetadata(INGRESS,
                               MetadataField{"istd", "parser_error", 16},
                               MetadataField{"ig_intr_md_from_prsr", "ingress_parser_err", 16});
        structure->addMetadata(INGRESS,
                               MetadataField{"ostd", "class_of_service", 3},
                               MetadataField{"ig_intr_md_for_tm", "ingress_cos", 3});
        structure->addMetadata(INGRESS,
                               MetadataField{"ostd", "drop", 1},
                               MetadataField{"compiler_generated_meta", "drop", 1});
        structure->addMetadata(INGRESS, MetadataField{"ostd", "multicast_group", 16},
                               MetadataField{"ig_intr_md_for_tm", "mcast_grp_a", 16});
        structure->addMetadata(INGRESS,
                               MetadataField{"ostd", "egress_port", 9},
                               MetadataField{"ig_intr_md_for_tm", "ucast_egress_port", 9});
        structure->addMetadata(INGRESS, MetadataField{"ostd", "resubmit", 1},
                               MetadataField{"compiler_generated_meta", "resubmit", 1});
        structure->addMetadata(INGRESS, MetadataField{"ostd", "clone", 1},
                               MetadataField{"compiler_generated_meta", "clone_i2e", 1});
        structure->addMetadata(INGRESS,
                               MetadataField{"istd", "packet_path", 0},
                               MetadataField{"compiler_generated_meta", "packet_path", 0});

        structure->addMetadata(EGRESS,
                               MetadataField{"istd", "egress_port", 9},
                               MetadataField{"eg_intr_md", "egress_port", 9});
        structure->addMetadata(EGRESS,
                               MetadataField{"istd", "egress_timestamp", 48},
                               MetadataField{"eg_intr_md_for_dprsr", "egress_global_tstamp", 48});
        structure->addMetadata(EGRESS,
                               MetadataField{"istd", "parser_error", 3},
                               MetadataField{"eg_intr_md_from_prsr", "egress_parser_err", 3});
        structure->addMetadata(EGRESS,
                               MetadataField{"ostd", "drop", 1},
                               MetadataField{"compiler_generated_meta", "drop", 1});
        structure->addMetadata(EGRESS, MetadataField{"ostd", "clone", 1},
                               MetadataField{"compiler_generated_meta", "clone_e2e", 1});
        structure->addMetadata(EGRESS,
                               MetadataField{"istd", "packet_path", 0},
                               MetadataField{"compiler_generated_meta", "packet_path", 0});
        structure->addMetadata(MetadataField{"ostd", "clone_session_id", 10},
                               MetadataField{"compiler_generated_meta", "mirror_id", 10});
    }

    void analyzeTofinoModel() {
        for (auto decl : structure->targetTypes) {
            if (auto v = decl->to<IR::Type_Enum>()) {
                structure->enums.emplace(v->name, v);
            } else if (auto v = decl->to<IR::Type_Error>()) {
                for (auto mem : v->members) {
                    structure->errors.emplace(mem->name);
                }
            }
        }
    }

    void postorder(const IR::P4Program*) override {
        setup_metadata_map();
        char* drvP4IncludePath = getenv("P4C_16_INCLUDE_PATH");
        Util::PathName path(drvP4IncludePath ? drvP4IncludePath : p4includePath);
        char tempPath[PATH_MAX];
        snprintf(tempPath, PATH_MAX-1, "/tmp/arch_XXXXXX.p4");
        std::vector<const char *>filenames;
        if (Device::currentDevice() == Device::TOFINO)
            filenames.push_back("tofino.p4");
#if HAVE_JBAY
        else
            filenames.push_back("tofino2.p4");
#endif  // HAVE_JBAY
        filenames.push_back("tofino/stratum.p4");
        filenames.push_back("tofino/p4_14_prim.p4");

        // create a temporary file. The safe method is to create and open the file
        // in exclusive mode. Since we can only open a C++ stream with a hack, we'll close
        // the file and then open it again as an ofstream.
        auto fd = mkstemps(tempPath, 3);
        if (fd < 0) {
            ::error("Error mkstemp(%1%): %2%", tempPath, strerror(errno));
            return;
        }
        // close the file descriptor and open as stream
        close(fd);
        std::ofstream result(tempPath, std::ios::out);
        if (!result.is_open()) {
            ::error("Failed to open arch include file %1%", tempPath);
            return;
        }
        for (auto f : filenames) {
            Util::PathName fPath = path.join(f);
            std::ifstream inFile(fPath.toString(), std::ios::in);
            if (inFile.is_open()) {
                result << inFile.rdbuf();
                inFile.close();
            } else {
                ::error("Failed to open architecture include file %1%", fPath.toString());
                result.close();
                unlink(tempPath);
                return;
            }
        }
        result.close();
        structure->include(tempPath, &structure->targetTypes);
        unlink(tempPath);

        analyzeTofinoModel();
    }
};

}  // namespace PSA

PortableSwitchTranslation::PortableSwitchTranslation(
        P4::ReferenceMap* refMap, P4::TypeMap* typeMap, BFN_Options& options) {
    setName("Translation");
    addDebugHook(options.getDebugHook());
    auto evaluator = new P4::EvaluatorPass(refMap, typeMap);
    auto structure = new PSA::ProgramStructure;

    addPasses({
        new P4::ValidateTableProperties({"implementation", "size", "psa_direct_counters",
                                         "psa_direct_meters", "idle_timeout"}),
        new P4::ConvertEnums(refMap, typeMap, new PSA::PacketPathTo8Bits),
        new P4::CopyStructures(refMap, typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
        evaluator,
        new VisitFunctor(
            [structure, evaluator]() { structure->toplevel = evaluator->getToplevelBlock(); }),
        new TranslationFirst(),
        new PSA::LoadTargetArchitecture(structure),
        new PSA::AnalyzeProgram(structure, refMap, typeMap),
        new PSA::TranslateProgram(structure, refMap, typeMap),
        new GenerateTofinoProgram(structure),
        new AddIntrinsicMetadata,
        new PSA::RewritePacketPath(structure),
        new TranslationLast(),
        // new AddPsaBridgeMetadata(refMap, typeMap, structure),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
