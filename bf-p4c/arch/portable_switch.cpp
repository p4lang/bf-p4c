#include <cmath>
#include "bf-p4c/device.h"
#include "architecture.h"
#include "portable_switch.h"
#include "resubmit.h"

namespace BFN {

namespace PSA {
//////////////////////////////////////////////////////////////////////////////////////////////

/// @pre: assume no nested control block or parser block,
///       as a result, all declarations within a control block have different names.
/// @post: all user provided names for metadata are converted to standard names
///       assumed by the translation map in latter pass.
class NormalizeProgram : public Transform {
    ordered_map<cstring, std::vector<const IR::Node *> *> namescopes;
    ordered_map<cstring, cstring> renameMap;
    ordered_map<cstring, cstring> aliasMap;
 public:
    NormalizeProgram() {}
};

class AnalyzeProgram : public Inspector {
    ProgramStructure* structure;

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
        LOG1(blockType);
    }

 public:
    explicit AnalyzeProgram(ProgramStructure* structure) : structure(structure)
    { CHECK_NULL(structure); setName("AnalyzePsaProgram"); }

    void postorder(const IR::Type_Action* node) override
    { structure->action_types.push_back(node); }
    void postorder(const IR::Type_Struct* node) override
    { structure->struct_types.emplace(node->name, node); }
    void postorder(const IR::Type_Header* node) override
    { structure->header_types.emplace(node->name, node); }
    void postorder(const IR::Type_HeaderUnion* node) override
    { structure->header_union_types.emplace(node->name, node); }
    void postorder(const IR::Type_Typedef* node) override {
        if (node->name == "PortId_t"         ||
            node->name == "MulticastGroup_t" ||
            node->name == "ClassOfService_t" ||
            node->name == "PacketLength_t"   ||
            node->name == "Timestamp_t"      ||
            node->name == "EgressInstance_t") return;

        structure->typedef_types.emplace(node->name, node);
    }
    void postorder(const IR::Type_Enum* node) override
    { structure->enums.emplace(node->name, node); }
    void postorder(const IR::P4Parser* node) override
    { structure->parsers.emplace(node->name, node); }
    void postorder(const IR::P4Control* node) override
    { structure->controls.emplace(node->name, node); }
    void postorder(const IR::P4Program*) override {
        analyzeArchBlock<IR::P4Parser, IR::ParserBlock>(
                "ingress", "ip", ProgramStructure::INGRESS_PARSER);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                "ingress", "ig", ProgramStructure::INGRESS);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                "ingress", "id", ProgramStructure::INGRESS_DEPARSER);
        analyzeArchBlock<IR::P4Parser, IR::ParserBlock>(
                "egress", "ep", ProgramStructure::EGRESS_PARSER);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                "egress", "eg", ProgramStructure::EGRESS);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                "egress", "ed", ProgramStructure::EGRESS_DEPARSER);
    }

    // 'compiler_generated_metadata_t' is the last struct in the program.
    void end_apply() override {
        auto* cgAnnotation = new IR::Annotations({
             new IR::Annotation(IR::ID("__compiler_generated"), { })});
        auto cgm = new IR::Type_Struct("compiler_generated_metadata_t", cgAnnotation);
        auto pktPath = new IR::StructField("packet_path",
                                           structure->enums.at("PacketPath_t")->getP4Type());
        cgm->fields.push_back(pktPath);
        structure->struct_types.emplace("compiler_generated_metadata_t", cgm);
    }
};

class ConstructSymbolTable : public Inspector {
    ProgramStructure* structure;
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

 public:
    explicit ConstructSymbolTable(ProgramStructure* structure,
                                  P4::ReferenceMap *refMap, P4::TypeMap *typeMap)
            : structure(structure), refMap(refMap), typeMap(typeMap) {
        CHECK_NULL(structure); setName("ConstructPsaSymbolTable");
    }

    void process_extern_declaration(const IR::Declaration_Instance* node, cstring name) {
        if (name == "Counter") {
            structure->counters.emplace(node, node);
        } else if (name == "DirectCounter") {
            structure->direct_counters.emplace(node, node);
        } else if (name == "Meter") {
            structure->meters.emplace(node, node);
        } else if (name == "DirectMeter") {
            structure->direct_meters.emplace(node, node);
        } else {
            WARNING("TypeName " << node << "is not converted");
        }
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
                            ProgramStructure::INGRESS)) {
                        structure->pathsThread.emplace(node, INGRESS);
                        structure->pathsToDo.emplace(node, node);
                    } else if (gress->name == structure->getBlockName(
                            ProgramStructure::EGRESS)) {
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

    void postorder(const IR::Declaration_Instance* node) override {
        if (auto ts = node->type->to<IR::Type_Specialized>()) {
            if (auto typeName = ts->baseType->to<IR::Type_Name>()) {
                if (typeName->path->name == "IngressPipeline") {
                    ERROR_CHECK(ts->arguments->size() == 6,
                              "expect IngressPipeline with 6 type arguments");
                    auto type_ih = ts->arguments->at(0)->to<IR::Type_Name>();
                    auto type_im = ts->arguments->at(1)->to<IR::Type_Name>();
                    structure->type_ih = type_ih->path->name;
                    structure->type_im = type_im->path->name;
                } else if (typeName->path->name == "EgressPipeline") {
                    ERROR_CHECK(ts->arguments->size() == 6,
                              "expect IngressPipeline with 6 type arguments");
                    auto type_eh = ts->arguments->at(0)->to<IR::Type_Name>();
                    auto type_em = ts->arguments->at(1)->to<IR::Type_Name>();
                    structure->type_eh = type_eh->path->name;
                    structure->type_em = type_em->path->name;
                } else {
                    process_extern_declaration(node, typeName->path->name);
                }
            }
        } else if (auto typeName = node->type->to<IR::Type_Name>()) {
            process_extern_declaration(node, typeName->path->name);
        } else {
            WARNING("Declaration instance " << node << " is not converted");
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
    ProgramStructure* structure;

 public:
    explicit LoadTargetArchitecture(ProgramStructure* structure) : structure(structure) {
        setName("PsaLoadTargetArchitecture");
        CHECK_NULL(structure);
    }

    void add_metadata(gress_t gress, cstring ss, cstring sf,
                     cstring ds, cstring df, unsigned w) {
        auto& nameMap = gress == INGRESS ? structure->ingressMetadataNameMap
                                         : structure->egressMetadataNameMap;
        nameMap.emplace(MetadataField{ss, sf}, MetadataField{ds, df});
        structure->metadataTypeMap.emplace(MetadataField{ds, df}, w);
    }

    void add_metadata(cstring ss, cstring sf, cstring ds, cstring df, unsigned w) {
        add_metadata(INGRESS, ss, sf, ds, df, w);
        add_metadata(EGRESS, ss, sf, ds, df, w);
    }

    void setup_metadata_map() {
        add_metadata(INGRESS, "istd", "ingress_port",
                     "ig_intr_md", "ingress_port", 9);
        add_metadata(EGRESS, "istd", "ingress_port",
                     "eg_intr_md", "ingress_port", 9);

        add_metadata(INGRESS, "istd", "ingress_timestamp", "ig_intr_md", "ingress_mac_tstamp", 48);
        add_metadata(INGRESS, "istd", "parser_error",
                     "ig_intr_md_from_prsr", "ingress_parser_err", 16);
        add_metadata(INGRESS, "ostd", "class_of_service", "ig_intr_md_for_tm", "ingress_cos", 3);
        add_metadata(INGRESS, "ostd", "drop", "ig_intr_md_for_tm", "drop_ctl", 3);
        add_metadata(INGRESS, "ostd", "multicast_group", "ig_intr_md_for_tm", "mcast_grp_a", 16);
        add_metadata(INGRESS, "ostd", "egress_port", "ig_intr_md_for_tm", "ucast_egress_port", 9);

        add_metadata(EGRESS, "istd", "egress_port", "eg_intr_md", "egress_port", 9);
        add_metadata(EGRESS, "istd", "egress_timestamp",
                     "eg_intr_md_for_dprsr", "egress_global_tstamp", 48);
        add_metadata(EGRESS, "istd", "parser_error",
                     "eg_intr_md_from_prsr", "egress_parser_err", 3);
        add_metadata(EGRESS, "ostd", "drop", "eg_intr_md_for_oport", "drop_ctl", 3);

        add_metadata(INGRESS, "istd", "packet_path",
                     "compiler_generated_meta", "packet_path", 4);
        add_metadata(EGRESS, "istd", "packet_path",
                     "compiler_generated_meta", "packet_path", 4);
    }

    void setup_psa_typedef() {
        structure->typedef_types.emplace(
                "PortId_t", new IR::Type_Typedef("PortId_t", IR::Type_Bits::get(9)));
        structure->typedef_types.emplace(
                "MulticastGroup_t",
                new IR::Type_Typedef("MulticastGroup_t", IR::Type_Bits::get(16)));
        structure->typedef_types.emplace(
                "ClassOfService_t",
                new IR::Type_Typedef("ClassOfService_t", IR::Type_Bits::get(3)));
        structure->typedef_types.emplace(
                "PacketLength_t",
                new IR::Type_Typedef("PacketLength_t", IR::Type_Bits::get(14)));
        structure->typedef_types.emplace(
                "Timestamp_t",
                new IR::Type_Typedef("Timestamp_t", IR::Type_Bits::get(48)));
        structure->typedef_types.emplace(
                "EgressInstance_t",
                new IR::Type_Typedef("EgressInstance_t", IR::Type_Bits::get(16)));
    }

    void postorder(const IR::P4Program*) override {
        setup_metadata_map();
        structure->include("tofino/stratum.p4", &structure->targetTypes);
        structure->include("tofino/p4_14_prim.p4", &structure->targetTypes);
        structure->include("tofino/p4_16_prim.p4", &structure->targetTypes);
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
    auto structure = new BFN::PSA::ProgramStructure;
    auto* findResubmitData = new PSA::FindResubmitData(structure);
    addPasses({
        evaluator,
        new VisitFunctor([structure, evaluator]() {
            structure->toplevel = evaluator->getToplevelBlock(); }),
        new BFN::TranslationFirst(),
        new BFN::PSA::NormalizeProgram(),
        new BFN::PSA::LoadTargetArchitecture(structure),
        new BFN::PSA::AnalyzeProgram(structure),
        findResubmitData,
        new BFN::PSA::ConstructSymbolTable(structure, refMap, typeMap),
        new BFN::GenerateTofinoProgram(structure),
        new BFN::TranslationLast(),
        new BFN::CastFixup(structure),
        new BFN::AddIntrinsicMetadata,
        new BFN::PSA::RewriteResubmitIfPresent(structure),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
    });
}
}  // namespace BFN
