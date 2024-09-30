#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/cloner.h"
#include "ir/pass_manager.h"
#include "ir/visitor.h"
#include "midend/validateProperties.h"
#include "midend/copyStructures.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/arch/check_extern_invocation.h"
#include "bf-p4c/arch/t5na.h"
#include "bf-p4c/arch/fromv1.0/phase0.h"
#include "bf-p4c/arch/rewrite_action_selector.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/device.h"
#include "bf-p4c/parde/field_packing.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/arch/tna/t5na_program_structure.h"

namespace BFN {

class TransformTnatoT5na : public PassManager {
    // Basic maps
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

    /**
     * Translates and saves all of the definitions for T5NA
     * and TNA, so they can later be added/removed.
     */
    class IncludeT5na : public Inspector {
     public:
        explicit IncludeT5na(T5naProgramStructure* structure)
            : structure(structure)
        { CHECK_NULL(structure); }

        void postorder(const IR::P4Program*) override {
            structure->include("t5na.p4", &structure->targetTypes);
            structure->include("tna.p4", &structure->targetTypesToRemove);
        }
     private:
        T5naProgramStructure* structure;
    };

    /**
     * Analyzes the program and saves all of the definitions.
     * Also determines which controls/parsers are used together in
     * pipes and as which parts of those pipes.
     */
    class AnalyzeProgram : public Inspector {
        const IR::Path *getP4ControlPathFromPipeArgument(const IR::Argument* arg) {
            auto cce = arg->expression->to<IR::ConstructorCallExpression>();
            if (!cce) return nullptr;
            auto tn = cce->constructedType->to<IR::Type_Name>();
            if (!tn) return nullptr;
            return tn->path;
        }
        cstring getP4ControlNameFromPipeArgument(const IR::Argument* arg) {
            auto path = getP4ControlPathFromPipeArgument(arg);
            if (path)
                return path->name.name;
            else
                return "";
        }

     public:
        explicit AnalyzeProgram(T5naProgramStructure* structure,
                                P4::ReferenceMap *refMap, P4::TypeMap *typeMap)
            : structure(structure), refMap(refMap), typeMap(typeMap)
        { CHECK_NULL(structure); }

        void postorder(const IR::Type_Action* node) override {
            structure->action_types.push_back(node);
        }
        void postorder(const IR::Type_StructLike* node) override {
            structure->type_declarations.emplace(node->name, node);
        }
        void postorder(const IR::Type_Typedef* node) override {
            structure->type_declarations.emplace(node->name, node);
        }
        void postorder(const IR::Type_Enum* node) override {
            structure->enums.emplace(node->name, node);
        }
        void postorder(const IR::Type_SerEnum* node) override {
            structure->ser_enums.emplace(node->name, node);
        }
        void postorder(const IR::P4Parser* node) override {
            structure->parsers.emplace(node->name, node);
        }
        void postorder(const IR::P4Control* node) override {
            structure->controls.emplace(node->name, node);
        }
        void postorder(const IR::Declaration_Instance* node) override {
            auto type = node->type->to<IR::Type_Specialized>();
            if (!type) return;
            auto baseType = type->baseType->to<IR::Type_Name>();
            if (!baseType) return;
            auto name = baseType->path->name.name;
            if (name == "Pipeline") {
                structure->pipeInstances.push_back(node);
                auto args = node->arguments;
                BUG_CHECK(args->size() == 6, "%1%: Expected 6 arguments for pipe", pipe);
                // Save which controls are used as what
                // IngressParser
                auto ingressParserName = getP4ControlNameFromPipeArgument(args->at(0));
                structure->ingressParsers.insert(ingressParserName);
                // Ingress
                auto ingressName = getP4ControlNameFromPipeArgument(args->at(1));
                structure->ingressControls.insert(ingressName);
                // IngressDeparser
                structure->ingressDeparsers.insert(getP4ControlNameFromPipeArgument(args->at(2)));
                // EgressParser
                structure->egressParsers.insert(getP4ControlNameFromPipeArgument(args->at(3)));
                // Egress
                auto egressName = getP4ControlNameFromPipeArgument(args->at(4));
                structure->egressControls.insert(egressName);
                // EgressDeparser
                auto egressDeparserName = getP4ControlNameFromPipeArgument(args->at(5));
                structure->egressDeparsers.insert(egressDeparserName);
                // Also for each egress, egress deparser map which
                // ingress corresponds to it
                // (so we can later use the same headers/metadata for both)
                // This should be N->1 mapping otherwise it might not work
                auto iDecl = refMap->getDeclaration(
                    getP4ControlPathFromPipeArgument(args->at(1)));
                CHECK_NULL(iDecl);
                auto ingress = iDecl->to<IR::P4Control>();
                CHECK_NULL(ingress);
                if ((structure->correspondingIngress.count(egressName) &&
                     structure->correspondingIngress[egressName] != ingress) ||
                    (structure->correspondingIngress.count(egressDeparserName) &&
                     structure->correspondingIngress[egressDeparserName] != ingress)) {
                    ::P4::error("T5NA translation from TNA does not support egress deparser/egress"
                            " used with multiple different ingresses.");
                }
                auto eDecl = refMap->getDeclaration(
                    getP4ControlPathFromPipeArgument(args->at(4)));
                CHECK_NULL(eDecl);
                auto egress = eDecl->to<IR::P4Control>();
                CHECK_NULL(egress);
                if (structure->correspondingEgress.count(ingressName) &&
                    structure->correspondingEgress[ingressName] != egress) {
                    ::P4::error("T5NA translation from TNA does not support ingress"
                            " used with multiple different egresses.");
                }
                structure->correspondingIngress[egressName] = ingress;
                structure->correspondingIngress[egressDeparserName] = ingress;
                structure->correspondingEgress[ingressName] = egress;
            } else if (name == "Switch") {
                structure->mainInstance = node;
            } else if (name == "MultiParserSwitch") {
                ::P4::error("T5NA does not support MultiParserSwitch");
            }
        }

     private:
        T5naProgramStructure* structure;
        P4::ReferenceMap *refMap;
        P4::TypeMap *typeMap;
    };

    /**
     * Collects all of the modifications of header fields within control
     * blocks that are used as ingress. Those need to be later saved into
     * metadata and bridged.
     */
    class CollectIngressHdrModifications : public Inspector {
        class ChangePathName : public Transform {
         public:
            IR::Node *postorder(IR::Path* path) {
                if (path->name.name == from) {
                    return new IR::Path(to);
                } else {
                    return path;
                }
            }

            explicit ChangePathName(cstring from,
                                    cstring to) :
                from(from), to(to) {}
         private:
            cstring from;
            cstring to;
        };

     public:
        explicit CollectIngressHdrModifications(T5naProgramStructure* structure,
                                                P4::ReferenceMap *refMap, P4::TypeMap *typeMap)
            : structure(structure), refMap(refMap), typeMap(typeMap)
        { CHECK_NULL(structure); }

        // Start collection for Ingress control node
        bool preorder(const IR::P4Control* node) override {
            hdrFieldModifications.clear();
            currentHdrName = nullptr;
            auto name = node->name.name;
            if (!structure->ingressControls.count(name))
                return false;
            auto type = node->type;
            auto params = type->getApplyParameters();
            BUG_CHECK(params->size() >= 2, "%1%: Expected at least 2 parameters for control",
                                            name);
            auto* param = params->getParameter(0);
            currentHdrName = param->name.name;
            param = params->getParameter(1);
            currentMetaName = param->name.name;
            currentMetaType = param->type->to<IR::Type_Name>();
            CHECK_NULL(currentMetaType);
            LOG4("Started collecting header assignments for: " << name <<
                    " (headers name: " << currentHdrName << ")");
            return true;
        }
        // Collect all hdr modifications
        bool preorder(const IR::AssignmentStatement* node) override {
            if (!currentHdrName)
                return false;
            auto left = node->left;
            const IR::Member* dst = nullptr;
            if (auto sl = left->to<IR::Slice>()) {
                dst = sl->e0->to<IR::Member>();
            } else {
                dst = node->left->to<IR::Member>();
            }
            if (!dst)
                return false;
            auto dstName = dst->toString();
            if (dstName.startsWith(currentHdrName+".")) {
                LOG4("  Collected: " << dstName);
                hdrFieldModifications[dstName] = dst;
            }
            return false;
        }
        void postorder(const IR::P4Control* node) override {
            auto nodeName = node->name.name;
            if (!currentHdrName)
                return;

            // Get also corresponding egress name
            cstring egressName = nullptr;
            cstring egressMetaName = nullptr;
            cstring egressHdrName = nullptr;
            if (structure->correspondingEgress.count(nodeName)) {
                auto egress = structure->correspondingEgress[nodeName];
                egressName = egress->name.name;
                auto params = egress->type->getApplyParameters();
                BUG_CHECK(params->size() >= 2, "%1%: Expected at least 2 parameters for control",
                                                egressName);
                auto* param = params->getParameter(0);
                egressHdrName = param->name.name;
                param = params->getParameter(1);
                egressMetaName = param->name.name;
            }


            IR::IndexedVector<IR::StructField> newMetadataStructFields;
            cstring newMetadataStructInstName =
                "__" + nodeName + T5naProgramStructure::EXTRA_METADATA_STRING;
            cstring newMetadataStructName = newMetadataStructInstName + "_h"_cs;
            // Create new structure with extra fields for this ingress
            for (auto hdrField : hdrFieldModifications) {
                auto fieldName = hdrField.first;
                auto metaFieldName = fieldName.replace('.', '_');
                auto fieldType = hdrField.second->type;
                newMetadataStructFields.push_back(new IR::StructField(metaFieldName, fieldType));
            }
            auto newMetadataStruct = new IR::Type_Struct(newMetadataStructName,
                                                         newMetadataStructFields);
            // Add it into declarations
            structure->newTypeDeclarations.emplace(newMetadataStructInstName, newMetadataStruct);
            // Also save it as new StructField of metadata definition
            CHECK_NULL(currentMetaType);
            structure->mdTypeExtraFields[currentMetaType->path->name.name].push_back(
                new IR::StructField(newMetadataStructInstName,
                                    new IR::Type_Name(new IR::Path(newMetadataStructName))));

            // Also create new members referencing created metadata field for each
            // modified hdr field
            for (auto hdrField : hdrFieldModifications) {
                auto fieldName = hdrField.first;
                auto metaFieldName = fieldName.replace('.', '_');
                auto fieldMember = hdrField.second;
                auto fieldType = fieldMember->type;
                // Create and save a new member refference
                // <metadata>.__<ingress>_extra_bridged_metadata.<fieldName with _>
                auto metaMember = new IR::Member(
                                    fieldType,
                                    new IR::Member(
                                        newMetadataStruct,
                                        new IR::PathExpression(
                                            currentMetaType,
                                            new IR::Path(currentMetaName)),
                                        newMetadataStructInstName),
                                    metaFieldName);
                structure->hdrFieldToMdMap[nodeName][fieldName] = metaMember;
                // Create extra statements for ingress (new metadata = hdrs)
                structure->controlsStatements[nodeName].push_back(
                    new IR::AssignmentStatement(metaMember->clone(), fieldMember->clone()));
                // And for egress (hdrs = new metadata)
                if (egressName) {
                    // Egress might have a different metadata name, just update it
                    const IR::Expression* egressMetaMember;
                    const IR::Expression* egressFieldMember;
                    ChangePathName metaNameChanger(currentMetaName, egressMetaName);
                    egressMetaMember = metaMember->apply(metaNameChanger);
                    ChangePathName hdrNameChanger(currentHdrName, egressHdrName);
                    egressFieldMember = fieldMember->apply(hdrNameChanger);
                    structure->controlsStatements[egressName].push_back(
                        new IR::AssignmentStatement(egressFieldMember, egressMetaMember));
                }
            }
        }

     private:
        T5naProgramStructure* structure;
        P4::ReferenceMap *refMap;
        P4::TypeMap *typeMap;
        std::map<cstring, const IR::Member *> hdrFieldModifications;
        cstring currentHdrName = nullptr;
        cstring currentMetaName = nullptr;
        const IR::Type_Name* currentMetaType = nullptr;
    };

    // TODO: Make this better
    class FixPortSizes : public Transform {
     public:
        IR::Node *postorder(IR::Type_Bits* tb) {
            // Port size of TNA
            if (tb->size != 9)
                return tb;
            auto as = findContext<IR::AssignmentStatement>();
            if (!as)
                return tb;
            auto member = as->right->to<IR::Member>();
            if (!member)
                member = as->left->to<IR::Member>();
            if (!member)
                return tb;
            if (member->member.name == "ingress_port" ||
                member->member.name == "egress_port" ||
                member->member.name == "ucast_egress_port")
                return new IR::Type_Bits(tb->srcInfo, 7, tb->expression, tb->isSigned);
            return tb;
        }

        FixPortSizes() {}
    };

 public:
    /**
     * Constructor that adds all of the passes.
     */
    TransformTnatoT5na(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) :
         refMap(refMap), typeMap(typeMap) {
        setName("TNA to T5NA transformation");
        auto structure = new BFN::T5naProgramStructure;
        auto evaluator = new P4::EvaluatorPass(refMap, typeMap);

        addPasses({
            new VisitFunctor([this]() {
                if (Architecture::currentArchitecture() != Architecture::TNA)
                    this->early_exit();
            }),
            new BFN::TypeChecking(refMap, typeMap, true),
            evaluator,
            new VisitFunctor([structure, evaluator]() {
                structure->toplevel = evaluator->getToplevelBlock(); }),
            new TranslationFirst(),
            new IncludeT5na(structure),
            new AnalyzeProgram(structure, refMap, typeMap),
            new CollectIngressHdrModifications(structure, refMap, typeMap),
            new GenerateTofinoProgram(structure),
            new FixPortSizes(),
            new TranslationLast(),
            // We might have copied some paths (even between gresses)
            // Just make sure they are all cloned, so typechecking
            // won't get them confused
            new P4::CloneExpressions(),
            new P4::ClearTypeMap(typeMap),
            // Some types might have changed from TNA to T5NA
            // Do TypeInference (TypeChecking assumes read only)
            new P4::ResolveReferences(refMap),
            new BFN::TypeInference(refMap, typeMap, false)
        });
    }
};

T5naArchTranslation::T5naArchTranslation(P4::ReferenceMap *refMap,
                                         P4::TypeMap *typeMap, BFN_Options &options) {
    addDebugHook(options.getDebugHook());
    addPasses({
        new TransformTnatoT5na(refMap, typeMap),
        new BFN::FindArchitecture(),  // after translation, arch is T5NA
        new RewriteControlAndParserBlocks(refMap, typeMap),
        new RestoreParams(options, refMap, typeMap),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
        new CheckTNAExternInvocation(refMap, typeMap),
        new LoweringType(),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
        new P4::ValidateTableProperties({"implementation", "size", "counters", "meters",
                                         "filters", "idle_timeout", "registers",
                                         "atcam", "alpm", "proxy_hash",
                                         /* internal table property, not exposed to customer */
                                         "as_alpm", "number_partitions", "subtrees_per_partition",
                                         "atcam_subset_width", "shift_granularity"}),
        new BFN::RewriteActionSelector(refMap, typeMap),
        new ConvertPhase0(refMap, typeMap),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
