#include <cmath>
#include "bf-p4c/device.h"
#include "intrinsic_metadata.h"
#include "portable_switch.h"
#include "rewrite_packet_path.h"
#include "lib/bitops.h"
#include "midend/convertEnums.h"
#include "bridge_metadata.h"
#include "midend/copyStructures.h"

namespace BFN {

namespace PSA {
//////////////////////////////////////////////////////////////////////////////////////////////

class PacketPathTo8Bits : public P4::ChooseEnumRepresentation {
    bool convert(const IR::Type_Enum *type) const override {
        LOG1("Type Enum name " << type);
        if (type->name != "PacketPath_t") {
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
        if (node->name == "PortId_t"         ||
            node->name == "MulticastGroup_t" ||
            node->name == "ClassOfService_t" ||
            node->name == "PacketLength_t"   ||
            node->name == "Timestamp_t"      ||
            node->name == "EgressInstance_t") return;

        structure->type_declarations.emplace(node->name, node);
    }
    void postorder(const IR::Type_Enum* node) override
    { structure->enums.emplace(node->name, node); }
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
            new IR::StructField("bridged_metadata",
                typeMap->getTypeType(
                    structure->psaPacketPathTypes.at("deparser::bridge_md"), true)));

        cgm->fields.push_back(new IR::StructField("drop", IR::Type::Boolean::get()));
        cgm->fields.push_back(new IR::StructField("resubmit", IR::Type::Boolean::get()));
        cgm->fields.push_back(new IR::StructField("clone_i2e", IR::Type::Boolean::get()));
        cgm->fields.push_back(new IR::StructField("clone_e2e", IR::Type::Boolean::get()));

        for (auto f : bridged_fields) {
            cgm->fields.push_back(f);
        }

        structure->type_declarations.emplace("compiler_generated_metadata_t", cgm);
    }

    void process_packet_path_params(const IR::P4Parser* node) {
        if (node->name == structure->getBlockName(PSA::ProgramStructure::INGRESS_PARSER)) {
            LOG1("create parser resubmit metadata");
            auto param = node->getApplyParameters()->getParameter(4);
            structure->psaPacketPathNames.emplace("parser::resubmit_md", param->name);
            structure->psaPacketPathTypes.emplace("parser::resubmit_md", param->type);
            param = node->getApplyParameters()->getParameter(5);
            structure->psaPacketPathNames.emplace("parser::recirc_md", param->name);
            structure->psaPacketPathTypes.emplace("parser::recirc_md", param->type);
        } else if (node->name == structure->getBlockName(PSA::ProgramStructure::EGRESS_PARSER)) {
            LOG1("create parser clone metadata");
            auto param = node->getApplyParameters()->getParameter(4);
            structure->psaPacketPathNames.emplace("parser::bridge_md", param->name);
            structure->psaPacketPathTypes.emplace("parser::bridge_md", param->type);
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
            structure->psaPacketPathNames.emplace("parser::clone_i2e_md", param->name);
            structure->psaPacketPathTypes.emplace("parser::clone_i2e_md", param->type);
            param = node->getApplyParameters()->getParameter(6);
            structure->psaPacketPathNames.emplace("parser::clone_e2e_md", param->name);
            structure->psaPacketPathTypes.emplace("parser::clone_e2e_md", param->type);
        }
    }

    void process_packet_path_params(const IR::P4Control* node) {
        if (node->name == structure->getBlockName(PSA::ProgramStructure::INGRESS_DEPARSER)) {
            LOG1("create egress parser resubmit metadata");
            auto param = node->getApplyParameters()->getParameter(1);
            structure->psaPacketPathNames.emplace("deparser::clone_i2e_md", param->name);
            structure->psaPacketPathTypes.emplace("deparser::clone_i2e_md", param->type);
            param = node->getApplyParameters()->getParameter(2);
            structure->psaPacketPathNames.emplace("deparser::resubmit_md", param->name);
            structure->psaPacketPathTypes.emplace("deparser::resubmit_md", param->type);
            param = node->getApplyParameters()->getParameter(3);
            structure->psaPacketPathNames.emplace("deparser::bridge_md", param->name);
            structure->psaPacketPathTypes.emplace("deparser::bridge_md", param->type);
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
        } else if (node->name == structure->getBlockName(PSA::ProgramStructure::EGRESS_DEPARSER)) {
            LOG1("create egress deparser recirc/clone metadata");
            auto param = node->getApplyParameters()->getParameter(1);
            structure->psaPacketPathNames.emplace("deparser::clone_e2e_md", param->name);
            structure->psaPacketPathTypes.emplace("deparser::clone_e2e_md", param->type);
            param = node->getApplyParameters()->getParameter(2);
            structure->psaPacketPathNames.emplace("deparser::recirc_md", param->name);
            structure->psaPacketPathTypes.emplace("deparser::recirc_md", param->type);
        }
    }

 private:
    PSA::ProgramStructure* structure;
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    ordered_set<IR::StructField*> bridged_fields;
};

class ConstructSymbolTable : public Inspector {
    PSA::ProgramStructure* structure;
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

 public:
    explicit ConstructSymbolTable(PSA::ProgramStructure* structure,
                                  P4::ReferenceMap *refMap, P4::TypeMap *typeMap)
            : structure(structure), refMap(refMap), typeMap(typeMap) {
        CHECK_NULL(structure); setName("ConstructPsaSymbolTable");
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
        auto w = node->arguments->at(2)->to<IR::Constant>()->asInt();
        typeArgs->push_back(IR::Type::Bits::get(w));

        auto args = new IR::Vector<IR::Expression>();
        args->push_back(node->arguments->at(0));

        auto specializedType = new IR::Type_Specialized(
            new IR::Type_Name("Hash"), typeArgs);
        auto hashName = cstring::make_unique(
            structure->unique_names, node->name + "__hash_", '_');
        structure->unique_names.insert(hashName);
        declarations->push_back(
            new IR::Declaration_Instance(hashName, specializedType, args));

        args = new IR::Vector<IR::Expression>();
        // size
        args->push_back(node->arguments->at(1));
        // hash
        args->push_back(new IR::PathExpression(hashName));
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
        args->push_back(sel_mode);

        declarations->push_back(new IR::Declaration_Instance(
            node->srcInfo, node->name, node->annotations, node->type, args));
        structure->_map.emplace(node, declarations);
    }

    void postorder(const IR::Declaration_Instance* node) override {
        if (auto ts = node->type->to<IR::Type_Specialized>()) {
            if (auto typeName = ts->baseType->to<IR::Type_Name>()) {
                auto name = typeName->path->name;
                if (name == "IngressPipeline") {
                    ERROR_CHECK(ts->arguments->size() == 6,
                              "expect IngressPipeline with 6 type arguments");
                    auto type_ih = ts->arguments->at(0)->to<IR::Type_Name>();
                    auto type_im = ts->arguments->at(1)->to<IR::Type_Name>();
                    structure->type_ih = type_ih->path->name;
                    structure->type_im = type_im->path->name;
                } else if (name == "EgressPipeline") {
                    ERROR_CHECK(ts->arguments->size() == 6,
                              "expect IngressPipeline with 6 type arguments");
                    auto type_eh = ts->arguments->at(0)->to<IR::Type_Name>();
                    auto type_em = ts->arguments->at(1)->to<IR::Type_Name>();
                    structure->type_eh = type_eh->path->name;
                    structure->type_em = type_em->path->name;
                }
            }
        } else if (auto typeName = node->type->to<IR::Type_Name>()) {
            auto name = typeName->path->name;
            if (name == "ActionSelector") {
                cvtActionSelector(node);
            }
        }
    }

    void addExternMethodCall(cstring name, const IR::Node* node) {
        LOG1("extern type " << name);
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
        } else if (auto ef = mi->to<P4::ExternFunction>()) {
            WARNING("extern function translation is not supported");
        }
    }

    void postorder(const IR::MethodCallExpression *node) override {
        auto mi = P4::MethodInstance::resolve(node, refMap, typeMap);
        if (auto em = mi->to<P4::ExternMethod>()) {
            cstring name = em->actualExternType->name;
            addExternMethodCall(name, node);
        } else if (auto ef = mi->to<P4::ExternFunction>()) {
            WARNING("extern function translation is not supported");
        }
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

    void setup_psa_typedef() {
        structure->type_declarations.emplace(
                "PortId_t", new IR::Type_Typedef("PortId_t", IR::Type_Bits::get(9)));
        structure->type_declarations.emplace(
                "MulticastGroup_t",
                new IR::Type_Typedef("MulticastGroup_t", IR::Type_Bits::get(16)));
        structure->type_declarations.emplace(
                "ClassOfService_t",
                new IR::Type_Typedef("ClassOfService_t", IR::Type_Bits::get(3)));
        structure->type_declarations.emplace(
                "PacketLength_t",
                new IR::Type_Typedef("PacketLength_t", IR::Type_Bits::get(14)));
        structure->type_declarations.emplace(
                "Timestamp_t",
                new IR::Type_Typedef("Timestamp_t", IR::Type_Bits::get(48)));
        structure->type_declarations.emplace(
                "EgressInstance_t",
                new IR::Type_Typedef("EgressInstance_t", IR::Type_Bits::get(16)));
    }

    void postorder(const IR::P4Program*) override {
        setup_metadata_map();
        structure->include("tofino/stratum.p4", &structure->targetTypes);
        structure->include("tofino/p4_14_prim.p4", &structure->targetTypes);
        for (auto decl : structure->targetTypes) {
            if (auto v = decl->to<IR::Type_Enum>()) {
                structure->enums.emplace(v->name, v);
            } else if (auto v = decl->to<IR::Type_Error>()) {
                for (auto mem : v->members) {
                    structure->errors.emplace(mem->name);
                }
            }
        }
        setup_psa_typedef();
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
        new P4::ConvertEnums(refMap, typeMap, new PSA::PacketPathTo8Bits),
        new P4::CopyStructures(refMap, typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        evaluator,
        new VisitFunctor([structure, evaluator]() {
            structure->toplevel = evaluator->getToplevelBlock(); }),
        new TranslationFirst(),
        new PSA::LoadTargetArchitecture(structure),
        new PSA::AnalyzeProgram(structure, refMap, typeMap),
        new PSA::ConstructSymbolTable(structure, refMap, typeMap),
        new GenerateTofinoProgram(structure),
        new TranslationLast(),
        new AddIntrinsicMetadata,
        new PSA::TranslatePacketPath(refMap, typeMap, structure),
        new AddPsaBridgeMetadata(refMap, typeMap, structure),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
    });
}



}  // namespace BFN
