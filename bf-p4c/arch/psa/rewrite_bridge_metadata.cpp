#include <boost/range/adaptor/sliced.hpp>

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeMap.h"
#include "bf-p4c/arch/collect_bridged_fields.h"
#include "bf-p4c/arch/intrinsic_metadata.h"
#include "bf-p4c/midend/path_linearizer.h"
#include "bf-p4c/midend/type_checker.h"
#include "rewrite_bridge_metadata.h"

namespace BFN {

struct PsaBridgeIngressToEgress : public Transform {
    PsaBridgeIngressToEgress(P4::ReferenceMap* refMap,
                             P4::TypeMap* typeMap,
                             PSA::ProgramStructure* structure)
        : structure(structure), refMap(refMap), typeMap(typeMap) {}
    IR::IndexedVector<IR::StructField> fields;
    profile_t init_apply(const IR::Node* root) override {
        // Construct the bridged metadata header type.
        // We always need to bridge at least one byte of metadata; it's used to
        // indicate to the egress parser that it's dealing with bridged metadata
        // rather than mirrored data. (We could pack more information in there,
        // too, but we don't right now.)
        fields.push_back(new IR::StructField(BRIDGED_MD_INDICATOR,
                         IR::Type::Bits::get(8)));

        // The rest of the fields come from CollectBridgedFields.
        for (auto& bridgedField : structure->bridgedType->to<IR::Type_StructLike>()->fields) {
            auto *fieldAnnotations = new IR::Annotations();
            fieldAnnotations->annotations.push_back(
                            new IR::Annotation(IR::ID("flexible"), {}));
            fields.push_back(new IR::StructField(bridgedField->name, fieldAnnotations,
                                                 bridgedField->type));
        }
        return Transform::init_apply(root);
    }

    IR::Type_StructLike* postorder(IR::Type_StructLike* type) override {
        prune();
        if (type->name == structure->bridgedType->to<IR::Type_StructLike>()->name) {
           type->fields = fields;
        }
        return type;
    }

    IR::ParserState* preorder(IR::ParserState* state) override {
        prune();
        if (state->name == "__ingress_metadata")
            return updateIngressMetadataState(state);
        else if (state->name == "__bridged_metadata")
            return updateBridgedMetadataState(state);
        return state;
    }

    IR::ParserState* updateIngressMetadataState(IR::ParserState* state) {
        auto* tnaContext = findContext<IR::BFN::TnaParser>();
        BUG_CHECK(tnaContext, "Parser state %1% not within translated parser?",
                  state->name);
        if (tnaContext->thread != INGRESS) return state;

        auto cgMetadataParam = tnaContext->tnaParams.at(COMPILER_META);

        // Add "compiler_generated_meta.^bridged_metadata.^bridged_metadata_indicator = 0;".
        {
            auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                          IR::ID(BRIDGED_MD));
            auto* fieldMember =
                new IR::Member(member, IR::ID(BRIDGED_MD_INDICATOR));
            auto* value = new IR::Constant(IR::Type::Bits::get(8), 0);
            auto* assignment = new IR::AssignmentStatement(fieldMember, value);
            state->components.push_back(assignment);
        }

        // Add "md.^bridged_metadata.setValid();"
        {
            auto cgMetadataParam = tnaContext->tnaParams.at(COMPILER_META);
            auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                          IR::ID(BRIDGED_MD));
            auto* method = new IR::Member(member, IR::ID("setValid"));
            auto* args = new IR::Vector<IR::Argument>;
            auto* callExpr = new IR::MethodCallExpression(method, args);
            state->components.push_back(new IR::MethodCallStatement(callExpr));
        }

        return state;
    }

    IR::ParserState* updateBridgedMetadataState(IR::ParserState* state) {
        auto* tnaContext = findContext<IR::BFN::TnaParser>();
        BUG_CHECK(tnaContext, "Parser state %1% not within translated parser?",
                  state->name);
        if (tnaContext->thread != EGRESS) return state;

        // Add "pkt.extract(md.^bridged_metadata);"
        auto packetInParam = tnaContext->tnaParams.at("pkt");
        auto* method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));

        auto cgMetadataParam = tnaContext->tnaParams.at(COMPILER_META);
        auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                      IR::ID(BRIDGED_MD));
        auto* args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto* callExpr = new IR::MethodCallExpression(method, args);
        state->components.push_back(new IR::MethodCallStatement(callExpr));
        // add assignment
        auto pathname = structure->egress_parser.psaParams.at("metadata");
        auto path = new IR::PathExpression(pathname);
        auto mdType = typeMap->getTypeType(structure->metadataType, true);
        for (auto& bridgedField : structure->bridgedType->to<IR::Type_StructLike>()->fields) {
            auto leftMember = new IR::Member(path, bridgedField->name);
            for (auto f : mdType->to<IR::Type_StructLike>()->fields) {
                if (f->name == bridgedField->name) {
                    auto rightMember = new IR::Member(member, bridgedField->name);
                    auto setMetadata = new IR::AssignmentStatement(leftMember, rightMember);
                    state->components.push_back(setMetadata);
                    break;
                }
            }
        }
        return state;
    }


    IR::BFN::TnaDeparser*
    preorder(IR::BFN::TnaDeparser* deparser) override {
        prune();
        if (deparser->thread != INGRESS)
            return deparser;
        return updateIngressDeparser(deparser);
    }

    IR::BFN::TnaDeparser*
    updateIngressDeparser(IR::BFN::TnaDeparser* control) {
        // Add "pkt.emit(md.^bridged_metadata);" as the first statement in the
        // ingress deparser.
        auto packetOutParam = control->tnaParams.at("pkt");
        auto* method = new IR::Member(new IR::PathExpression(packetOutParam),
                                      IR::ID("emit"));

        auto cgMetadataParam = control->tnaParams.at(COMPILER_META);
        auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                      IR::ID(BRIDGED_MD));
        auto* args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto* callExpr = new IR::MethodCallExpression(method, args);

        auto* body = control->body->clone();
        body->components.insert(body->components.begin(),
                                new IR::MethodCallStatement(callExpr));
        control->body = body;
        return control;
    }

    PSA::ProgramStructure* structure;
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

// Find the assignment to bridged metadata from ingress deparser
// and move them to the end of ingress.
struct FindBridgeMetadataAssignment : public Transform {
    FindBridgeMetadataAssignment(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                 PSA::ProgramStructure* structure)
        : refMap(refMap), typeMap(typeMap), structure(structure) { }

    const IR::Parameter* getContainingParameter(const LinearPath& path,
                                                P4::ReferenceMap* refMap) {
        auto* topLevelPath = path.components[0]->to<IR::PathExpression>();
        BUG_CHECK(topLevelPath, "Path-like expression tree was rooted in "
            "non-path expression: %1%", path.components[0]);
        auto* decl = refMap->getDeclaration(topLevelPath->path);
        BUG_CHECK(decl, "No declaration for top level path in path-like "
            "expression: %1%", topLevelPath);
        return decl->to<IR::Parameter>();
    }

    bool isHeaderType(const IR::Type* type) {
        BUG_CHECK(!type->is<IR::Type_Name>(), "Trying to categorize a Type_Name; "
            "you can avoid this problem by getting types from a TypeMap");
        return type->is<IR::Type_Header>();
    }

    bool isBridgedMetadata(const IR::Type* type) {
        BUG_CHECK(!type->is<IR::Type_Name>(), "Trying to categorize a Type_Name; "
            "you can avoid this problem by getting types from a TypeMap");
        if (!isHeaderType(type))
            return false;
        auto headerType = type->to<IR::Type_Header>();
        LOG1("header type " << headerType);
        if (auto bridgeHeader = structure->bridgedType->to<IR::Type_StructLike>())
            return headerType->name == bridgeHeader->name;
        return false;
    }

    bool isCompilerGeneratedType(const IR::Type* type) {
        BUG_CHECK(!type->is<IR::Type_Name>(), "Trying to categorize a Type_Name; "
            "you can avoid this problem by getting types from a TypeMap");
        auto* annotated = type->to<IR::IAnnotated>();
        if (!annotated) return false;
        auto* intrinsicMetadata = annotated->getAnnotation("__compiler_generated");
        return bool(intrinsicMetadata);
    }

    IR::Node* postorder(IR::AssignmentStatement* assignment) override {
        auto ctxt = findOrigCtxt<IR::BFN::TnaDeparser>();
        if (!ctxt) {
            return assignment;
        }
        PathLinearizer linearizer;
        assignment->left->apply(linearizer);

        // If the destination of the write isn't a path-like expression, or if it's
        // too complex to analyze, err on the side of caution and don't remove it.
        if (!linearizer.linearPath) {
            LOG4("Won't remove ingress deparser assignment to complex object: "
                     << assignment);
            return assignment;
        }

        auto& path = *linearizer.linearPath;
        auto* param = getContainingParameter(path, refMap);
        if (!param) {
            LOG4("Won't remove ingress deparser assignment to local object: "
                     << assignment);
            return assignment;
        }
        auto* paramType = typeMap->getType(param);
        BUG_CHECK(paramType, "No type for param: %1%", param);
        LOG4("param type " << paramType);
        if (!isCompilerGeneratedType(paramType)) {
            LOG4("Won't remove ingress deparser assignment to non compiler-generated object: "
                     << assignment);
            return assignment;
        }

        if (path.components.size() < 2)
            return assignment;
        auto* nextToLastComponent = path.components[path.components.size() - 2];
        auto* nextToLastComponentType = typeMap->getType(nextToLastComponent);
        BUG_CHECK(nextToLastComponentType, "No type for path component: %1%",
                  nextToLastComponent);

        if (!isBridgedMetadata(nextToLastComponentType)) {
            LOG4("Won't remove ingress deparser assignment to non-bridged metadata: "
                 << assignment);
            return assignment;
        }

        // This is a write to bridged metadata; remove it.
        LOG4("Removing ingress deparser assignment to bridged metadata: " << assignment);
        bridgedFieldAssignments.push_back(assignment);
        return nullptr;
    }

    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
    PSA::ProgramStructure* structure;
    IR::IndexedVector<IR::StatOrDecl> bridgedFieldAssignments;
};

struct MoveBridgeMetadataAssignment : public Transform {
    explicit MoveBridgeMetadataAssignment(
            IR::IndexedVector<IR::StatOrDecl>* bridgedFieldAssignments)
    : bridgedFieldAssignments(bridgedFieldAssignments) { }

    IR::BFN::TnaControl*
    preorder(IR::BFN::TnaControl* control) override {
        prune();
        if (control->thread != INGRESS)
            return control;
        return updateIngressControl(control);
    }

    IR::BFN::TnaControl*
    updateIngressControl(IR::BFN::TnaControl* control) {
        // Inject code to copy all of the bridged fields into the bridged
        // metadata header. This will run at the very end of the ingress
        // control, so it'll get the final values of the fields.
        auto* body = control->body->clone();
        body->components.append(*bridgedFieldAssignments);
        control->body = body;
        return control;
    }

    IR::IndexedVector<IR::StatOrDecl>* bridgedFieldAssignments;
};

AddPsaBridgeMetadata::AddPsaBridgeMetadata(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                           PSA::ProgramStructure* structure) {
    auto* bridgeIngressToEgress = new PsaBridgeIngressToEgress(refMap, typeMap, structure);
    auto* findBridgedMetaAssignments = new FindBridgeMetadataAssignment(refMap, typeMap,
                                                                                structure);
    addPasses({
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
        bridgeIngressToEgress,
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
        findBridgedMetaAssignments,
        new MoveBridgeMetadataAssignment(&findBridgedMetaAssignments->bridgedFieldAssignments),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
