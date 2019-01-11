#include "bridge_metadata.h"

#include <boost/range/adaptor/sliced.hpp>

#include <algorithm>
#include <string>
#include <functional>
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeMap.h"
#include "bf-p4c/arch/psa_program_structure.h"
#include "bf-p4c/arch/internal/collect_bridged_fields.h"
#include "bf-p4c/midend/path_linearizer.h"
#include "bf-p4c/lib/pad_alignment.h"

namespace BFN {
namespace {

static const cstring bridged_metadata_header = "^bridged_metadata_header";

struct BridgeIngressToEgress : public Transform {
    BridgeIngressToEgress(const ordered_set<FieldRef>& fieldsToBridge,
                          const ordered_map<FieldRef, BridgedFieldInfo>& fieldInfo,
                          P4::ReferenceMap* refMap,
                          P4::TypeMap* typeMap)
      : refMap(refMap), typeMap(typeMap), fieldsToBridge(fieldsToBridge),
        fieldInfo(fieldInfo) { }

    profile_t init_apply(const IR::Node* root) override {
        // Construct the bridged metadata header type.
        IR::IndexedVector<IR::StructField> fields;

        // We always need to bridge at least one byte of metadata; it's used to
        // indicate to the egress parser that it's dealing with bridged metadata
        // rather than mirrored data. (We could pack more information in there,
        // too, but we don't right now.)
        fields.push_back(new IR::StructField("^bridged_metadata_indicator",
                                             IR::Type::Bits::get(8)));

        // The rest of the fields come from CollectBridgedFields.
        // TODO(yumin): for __pad__ field, we should have a global variable to name
        // them to avoid conflict.
        unsigned padFieldId = 0;
        for (auto& bridgedField : fieldsToBridge) {
            cstring fieldName = bridgedField.first + bridgedField.second;
            fieldName = fieldName.replace('.', '_');
            bridgedHeaderFieldNames.emplace(bridgedField, fieldName);

            BUG_CHECK(fieldInfo.count(bridgedField),
                      "No field info for bridged field %1%%2%?",
                      bridgedField.first, bridgedField.second);
            auto& info = fieldInfo.at(bridgedField);

            const int alignment = getAlignment(info.type->width_bits());
            if (alignment != 0) {
                cstring padFieldName = "__pad_";
                padFieldName += cstring::to_cstring(padFieldId++);
                auto* fieldAnnotations = new IR::Annotations({
                    new IR::Annotation(IR::ID("hidden"), { }) });
                fields.push_back(new IR::StructField(padFieldName,
                                                     fieldAnnotations,
                                                     IR::Type::Bits::get(alignment)));
            }

            fields.push_back(new IR::StructField(fieldName, info.type));
        }

        auto* layoutKind = new IR::StringLiteral(IR::ID("flexible"));
        bridgedHeaderType =
          new IR::Type_Header(bridged_metadata_header, new IR::Annotations({
              new IR::Annotation(IR::ID("layout"), {layoutKind})
          }), fields);

        // We'll inject a field containing the new header into the user metadata
        // struct. Figure out which type that is.
        // XXX(seth): Long term, we really want to be using the
        // compiler-generated package parameter to hold this kind of thing.
        forAllMatching<IR::BFN::TranslatedP4Control>(root,
                      [&](const IR::BFN::TranslatedP4Control* control) {
            if (!cgMetadataStructName.isNullOrEmpty()) return;
            auto p4ParamName = control->tnaParams.at("compiler_generated_meta");
            auto* params = control->type->getApplyParameters();
            auto* param = params->getParameter(p4ParamName);
            BUG_CHECK(param, "Couldn't find param %1% on control: %2%",
                      p4ParamName, control);
            auto* paramType = typeMap->getType(param);
            BUG_CHECK(paramType, "Couldn't find type for: %1%", param);
            BUG_CHECK(paramType->is<IR::Type_StructLike>(),
                      "User metadata parameter type isn't structlike %2%: %1%",
                      paramType, typeid(*paramType).name());
            cgMetadataStructName = paramType->to<IR::Type_StructLike>()->name;
        });

        BUG_CHECK(!cgMetadataStructName.isNullOrEmpty(),
                  "Couldn't determine the P4 name of the TNA compiler generated  metadata "
                  "struct parameter 'md'");

        return Transform::init_apply(root);
    }

    IR::Type_StructLike* preorder(IR::Type_StructLike* type) override {
        prune();
        if (type->name != cgMetadataStructName) return type;

        LOG1("Will inject the new field");

        // Inject the new field. This will give us access to the bridged
        // metadata type everywhere in the program.
        type->fields.push_back(new IR::StructField("^bridged_metadata",
                                                   new IR::Type_Name(bridged_metadata_header)));
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
        auto* tnaContext = findContext<IR::BFN::TranslatedP4Parser>();
        BUG_CHECK(tnaContext, "Parser state %1% not within translated parser?",
                  state->name);
        if (tnaContext->thread != INGRESS) return state;

        auto cgMetadataParam = tnaContext->tnaParams.at("compiler_generated_meta");

        // Add "compiler_generated_meta.^bridged_metadata.^bridged_metadata_indicator = 0;".
        {
            auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                          IR::ID("^bridged_metadata"));
            auto* fieldMember =
              new IR::Member(member, IR::ID("^bridged_metadata_indicator"));
            auto* value = new IR::Constant(IR::Type::Bits::get(8), 0);
            auto* assignment = new IR::AssignmentStatement(fieldMember, value);
            state->components.push_back(assignment);
        }

        // Add "md.^bridged_metadata.setValid();"
        {
            auto cgMetadataParam = tnaContext->tnaParams.at("compiler_generated_meta");
            auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                          IR::ID("^bridged_metadata"));
            auto* method = new IR::Member(member, IR::ID("setValid"));
            auto* args = new IR::Vector<IR::Argument>;
            auto* callExpr = new IR::MethodCallExpression(method, args);
            state->components.push_back(new IR::MethodCallStatement(callExpr));
        }

        return state;
    }

    IR::ParserState* updateBridgedMetadataState(IR::ParserState* state) {
        auto* tnaContext = findContext<IR::BFN::TranslatedP4Parser>();
        BUG_CHECK(tnaContext, "Parser state %1% not within translated parser?",
                  state->name);
        if (tnaContext->thread != EGRESS) return state;

        // Add "pkt.extract(md.^bridged_metadata);"
        auto packetInParam = tnaContext->tnaParams.at("pkt");
        auto* method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));

        auto cgMetadataParam = tnaContext->tnaParams.at("compiler_generated_meta");
        auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                      IR::ID("^bridged_metadata"));
        auto* args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto* callExpr = new IR::MethodCallExpression(method, args);
        state->components.push_back(new IR::MethodCallStatement(callExpr));

        // Copy all of the bridged fields to their final locations.
        for (auto& bridgedField : fieldsToBridge) {
            auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                          IR::ID("^bridged_metadata"));
            auto* fieldMember =
              new IR::Member(member, bridgedHeaderFieldNames.at(bridgedField));

            auto bridgedFieldParam = tnaContext->tnaParams.at(bridgedField.first);
            auto* bridgedMember =
              transformAllMatching<IR::PathExpression>(fieldInfo.at(bridgedField).refTemplate,
                                  [&](const IR::PathExpression*) {
                  return new IR::PathExpression(bridgedFieldParam);
            })->to<IR::Expression>();

            auto* assignment = new IR::AssignmentStatement(bridgedMember, fieldMember);
            state->components.push_back(assignment);
        }

        return state;
    }

    IR::BFN::TranslatedP4Control*
    preorder(IR::BFN::TranslatedP4Control* control) override {
        if (control->thread != INGRESS)
            return control;
        return updateIngressControl(control);
    }

    IR::BFN::TranslatedP4Control*
    updateIngressControl(IR::BFN::TranslatedP4Control* control) {
        auto cgMetadataParam = control->tnaParams.at("compiler_generated_meta");

        // Inject code to copy all of the bridged fields into the bridged
        // metadata header. This will run at the very end of the ingress
        // control, so it'll get the final values of the fields.
        auto* body = control->body->clone();

        for (auto& bridgedField : fieldsToBridge) {
            auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                          IR::ID("^bridged_metadata"));
            auto* fieldMember =
              new IR::Member(member, bridgedHeaderFieldNames.at(bridgedField));

            auto bridgedFieldParam = control->tnaParams.at(bridgedField.first);
            auto* bridgedMember =
              transformAllMatching<IR::PathExpression>(fieldInfo.at(bridgedField).refTemplate,
                                  [&](const IR::PathExpression*) {
                  return new IR::PathExpression(bridgedFieldParam);
            })->to<IR::Expression>();

            auto* assignment = new IR::AssignmentStatement(fieldMember, bridgedMember);
            body->components.push_back(assignment);
        }

        control->body = body;
        return control;
    }

    IR::BFN::TranslatedP4Deparser*
    preorder(IR::BFN::TranslatedP4Deparser* deparser) override {
        prune();
        if (deparser->thread != INGRESS)
            return deparser;
        return updateIngressDeparser(deparser);
    }

    IR::BFN::TranslatedP4Deparser*
    updateIngressDeparser(IR::BFN::TranslatedP4Deparser* control) {
        // Add "pkt.emit(md.^bridged_metadata);" as the first statement in the
        // ingress deparser.
        auto packetOutParam = control->tnaParams.at("pkt");
        auto* method = new IR::Member(new IR::PathExpression(packetOutParam),
                                      IR::ID("emit"));

        auto cgMetadataParam = control->tnaParams.at("compiler_generated_meta");
        auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                      IR::ID("^bridged_metadata"));
        auto* args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto* callExpr = new IR::MethodCallExpression(method, args);

        auto* body = control->body->clone();
        body->components.insert(body->components.begin(),
                                new IR::MethodCallStatement(callExpr));
        control->body = body;
        return control;
    }

    IR::Node* preorder(IR::MethodCallStatement* node) override {
        auto* call = node->methodCall;
        auto* pa = call->method->to<IR::PathExpression>();
        if (!pa) return node;
        if (pa->path->name != "bypass_egress") return node;

        auto stmts = new IR::IndexedVector<IR::StatOrDecl>();
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr,
                           "bypass_egress() must be used in a control block");
        auto meta = new IR::PathExpression("ig_intr_md_for_tm");
        auto flag = new IR::Member(meta, "bypass_egress");
        auto ftype = IR::Type::Bits::get(1);
        auto assign = new IR::AssignmentStatement(flag, new IR::Constant(ftype, 1));
        stmts->push_back(assign);

        auto* member = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                            IR::ID("^bridged_metadata"));
        auto* method = new IR::Member(member, IR::ID("setInvalid"));
        auto* args = new IR::Vector<IR::Argument>;
        auto* callExpr = new IR::MethodCallExpression(method, args);
        stmts->push_back(new IR::MethodCallStatement(callExpr));
        return stmts;
    }

    const IR::P4Program* postorder(IR::P4Program *program) override {
        LOG4("Injecting declaration for bridge metadata type: " << bridgedHeaderType);
        program->objects.insert(program->objects.begin(), bridgedHeaderType);
        return program;
    }

    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;

    const ordered_set<FieldRef>& fieldsToBridge;
    const ordered_map<FieldRef, BridgedFieldInfo>& fieldInfo;

    ordered_map<FieldRef, cstring> bridgedHeaderFieldNames;
    const IR::Type_Header* bridgedHeaderType = nullptr;
    cstring cgMetadataStructName;
};

}  // namespace

AddTnaBridgeMetadata::AddTnaBridgeMetadata(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
    auto* collectBridgedFields = new CollectBridgedFields(refMap, typeMap);
    auto* bridgeIngressToEgress = new BridgeIngressToEgress(collectBridgedFields->fieldsToBridge,
            collectBridgedFields->fieldInfo, refMap, typeMap);
    addPasses({
        collectBridgedFields,
        bridgeIngressToEgress,
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
    });
}

namespace {

struct PsaBridgeIngressToEgress : public Transform {
    PsaBridgeIngressToEgress(P4::ReferenceMap* refMap,
                             P4::TypeMap* typeMap,
                             PSA::ProgramStructure* structure)
        : structure(structure), refMap(refMap), typeMap(typeMap) {}

    profile_t init_apply(const IR::Node* root) override {
        // Construct the bridged metadata header type.
        IR::IndexedVector<IR::StructField> fields;

        // We always need to bridge at least one byte of metadata; it's used to
        // indicate to the egress parser that it's dealing with bridged metadata
        // rather than mirrored data. (We could pack more information in there,
        // too, but we don't right now.)
        fields.push_back(new IR::StructField("^bridged_metadata_indicator",
                                             IR::Type::Bits::get(8)));

        // The rest of the fields come from CollectBridgedFields.
        unsigned padFieldId = 0;
        for (auto& bridgedField : structure->bridgedType->to<IR::Type_StructLike>()->fields) {
            const int nextByteBoundary = 8 * ((bridgedField->type->width_bits() + 7) / 8);
            const int alignment = nextByteBoundary - bridgedField->type->width_bits();
            if (alignment != 0) {
                cstring padFieldName = "__pad_";
                padFieldName += cstring::to_cstring(padFieldId++);
                auto* fieldAnnotations = new IR::Annotations({
                    new IR::Annotation(IR::ID("hidden"), { }) });
                fields.push_back(new IR::StructField(padFieldName,
                    fieldAnnotations, IR::Type::Bits::get(alignment)));
            }

            fields.push_back(bridgedField);
        }

        auto* layoutKind = new IR::StringLiteral(IR::ID("flexible"));
        bridgedHeaderType =
            new IR::Type_Header(bridged_metadata_header, new IR::Annotations({
                 new IR::Annotation(IR::ID("layout"), {layoutKind})}), fields);

        return Transform::init_apply(root);
    }

    IR::Type_StructLike* preorder(IR::Type_StructLike* type) override {
        prune();
        if (type->name != "compiler_generated_metadata_t") return type;

        LOG1("Will inject the new field");

        // Inject the new field. This will give us access to the bridged
        // metadata type everywhere in the program.
        type->fields.push_back(new IR::StructField("^bridged_metadata",
                                                   new IR::Type_Name(bridged_metadata_header)));
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
        auto* tnaContext = findContext<IR::BFN::TranslatedP4Parser>();
        BUG_CHECK(tnaContext, "Parser state %1% not within translated parser?",
                  state->name);
        if (tnaContext->thread != INGRESS) return state;

        auto cgMetadataParam = tnaContext->tnaParams.at("compiler_generated_meta");

        // Add "compiler_generated_meta.^bridged_metadata.^bridged_metadata_indicator = 0;".
        {
            auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                          IR::ID("^bridged_metadata"));
            auto* fieldMember =
                new IR::Member(member, IR::ID("^bridged_metadata_indicator"));
            auto* value = new IR::Constant(IR::Type::Bits::get(8), 0);
            auto* assignment = new IR::AssignmentStatement(fieldMember, value);
            state->components.push_back(assignment);
        }

        // Add "md.^bridged_metadata.setValid();"
        {
            auto cgMetadataParam = tnaContext->tnaParams.at("compiler_generated_meta");
            auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                          IR::ID("^bridged_metadata"));
            auto* method = new IR::Member(member, IR::ID("setValid"));
            auto* args = new IR::Vector<IR::Argument>;
            auto* callExpr = new IR::MethodCallExpression(method, args);
            state->components.push_back(new IR::MethodCallStatement(callExpr));
        }

        return state;
    }

    IR::ParserState* updateBridgedMetadataState(IR::ParserState* state) {
        auto* tnaContext = findContext<IR::BFN::TranslatedP4Parser>();
        BUG_CHECK(tnaContext, "Parser state %1% not within translated parser?",
                  state->name);
        if (tnaContext->thread != EGRESS) return state;

        // Add "pkt.extract(md.^bridged_metadata);"
        auto packetInParam = tnaContext->tnaParams.at("pkt");
        auto* method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));

        auto cgMetadataParam = tnaContext->tnaParams.at("compiler_generated_meta");
        auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                      IR::ID("^bridged_metadata"));
        auto* args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto* callExpr = new IR::MethodCallExpression(method, args);
        state->components.push_back(new IR::MethodCallStatement(callExpr));

        return state;
    }


    IR::BFN::TranslatedP4Deparser*
    preorder(IR::BFN::TranslatedP4Deparser* deparser) override {
        prune();
        if (deparser->thread != INGRESS)
            return deparser;
        return updateIngressDeparser(deparser);
    }

    IR::BFN::TranslatedP4Deparser*
    updateIngressDeparser(IR::BFN::TranslatedP4Deparser* control) {
        // Add "pkt.emit(md.^bridged_metadata);" as the first statement in the
        // ingress deparser.
        auto packetOutParam = control->tnaParams.at("pkt");
        auto* method = new IR::Member(new IR::PathExpression(packetOutParam),
                                      IR::ID("emit"));

        auto cgMetadataParam = control->tnaParams.at("compiler_generated_meta");
        auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                      IR::ID("^bridged_metadata"));
        auto* args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto* callExpr = new IR::MethodCallExpression(method, args);

        auto* body = control->body->clone();
        body->components.insert(body->components.begin(),
                                new IR::MethodCallStatement(callExpr));
        control->body = body;
        return control;
    }

    const IR::P4Program* postorder(IR::P4Program *program) override {
        LOG4("Injecting declaration for bridge metadata type: " << bridgedHeaderType);
        program->objects.insert(program->objects.begin(), bridgedHeaderType);
        return program;
    }

    PSA::ProgramStructure* structure;
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;

    const IR::Type_Header* bridgedHeaderType = nullptr;
};

// Find the assignment to bridged metadata from ingress deparser
// and move them to the end of ingress.
struct FindBridgeMetadataAssignment : public Transform {
    FindBridgeMetadataAssignment(P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
        : refMap(refMap), typeMap(typeMap) { }

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
        return headerType->name == "^bridged_metadata_header";
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
        auto ctxt = findOrigCtxt<IR::BFN::TranslatedP4Deparser>();
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
    IR::IndexedVector<IR::StatOrDecl> bridgedFieldAssignments;
};

struct MoveBridgeMetadataAssignment : public Transform {
    explicit MoveBridgeMetadataAssignment(
            IR::IndexedVector<IR::StatOrDecl>* bridgedFieldAssignments)
    : bridgedFieldAssignments(bridgedFieldAssignments) { }

    IR::BFN::TranslatedP4Control*
    preorder(IR::BFN::TranslatedP4Control* control) override {
        prune();
        if (control->thread != INGRESS)
            return control;
        return updateIngressControl(control);
    }

    IR::BFN::TranslatedP4Control*
    updateIngressControl(IR::BFN::TranslatedP4Control* control) {
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

}  // namespace

AddPsaBridgeMetadata::AddPsaBridgeMetadata(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                           PSA::ProgramStructure* structure) {
    auto* bridgeIngressToEgress = new PsaBridgeIngressToEgress(refMap, typeMap, structure);
    auto* findBridgedMetaAssignments = new FindBridgeMetadataAssignment(refMap, typeMap);
    addPasses({
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        bridgeIngressToEgress,
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        findBridgedMetaAssignments,
        new MoveBridgeMetadataAssignment(&findBridgedMetaAssignments->bridgedFieldAssignments),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
