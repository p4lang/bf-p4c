#include "bf-p4c/arch/bridge_metadata.h"

#include <boost/range/adaptor/sliced.hpp>

#include <algorithm>
#include <string>
#include <functional>

#include "bf-p4c/arch/internal/collect_bridged_fields.h"
#include "bf-p4c/common/path_linearizer.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeMap.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"

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
        unsigned padFieldId = 0;
        for (auto& bridgedField : fieldsToBridge) {
            cstring fieldName = bridgedField.first + bridgedField.second;
            fieldName = fieldName.replace('.', '_');
            bridgedHeaderFieldNames.emplace(bridgedField, fieldName);

            BUG_CHECK(fieldInfo.count(bridgedField),
                      "No field info for bridged field %1%%2%?",
                      bridgedField.first, bridgedField.second);
            auto& info = fieldInfo.at(bridgedField);

            const int nextByteBoundary = 8 * ((info.type->width_bits() + 7) / 8);
            const int alignment = nextByteBoundary - info.type->width_bits();
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
            auto* args = new IR::Vector<IR::Expression>;
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
        auto* args = new IR::Vector<IR::Expression>({ member });
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
        prune();
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
        auto* args = new IR::Vector<IR::Expression>({ member });
        auto* callExpr = new IR::MethodCallExpression(method, args);

        auto* body = control->body->clone();
        body->components.insert(body->components.begin(),
                                new IR::MethodCallStatement(callExpr));
        control->body = body;
        return control;
    }

    const IR::P4Program* postorder(IR::P4Program *program) override {
        LOG4("Injecting declaration for bridge metadata type: " << bridgedHeaderType);
        program->declarations.insert(program->declarations.begin(), bridgedHeaderType);
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

using TnaParams = CollectBridgedFields::TnaParams;

struct CopyPropagateBridgedMetadata : public Transform {
    CopyPropagateBridgedMetadata(const ordered_set<FieldRef>& bmMap,
                  const ordered_map<FieldRef, cstring>& bridgedHeaderFieldNames,
                  P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
        : bmMap(bmMap), bridgedHeaderFieldNames(bridgedHeaderFieldNames),
          refMap(refMap), typeMap(typeMap) {}

    using TnaParams = ordered_map<cstring, cstring>;
    using TnaContext = std::pair<gress_t, const TnaParams&>;

    profile_t init_apply(const IR::Node* root) override {
        for (auto kv : bmMap) {
            LOG4("path of bridged fields : " << kv.first << " " << kv.second);
        }
        return Transform::init_apply(root);
    }

    boost::optional<CopyPropagateBridgedMetadata::TnaContext> findTnaContext() const {
        if (auto* control = findContext<IR::BFN::TranslatedP4Control>())
            return TnaContext(control->thread, control->tnaParams);
        else if (auto* parser = findContext<IR::BFN::TranslatedP4Parser>())
            return TnaContext(parser->thread, parser->tnaParams);
        else if (auto* deparser = findContext<IR::BFN::TranslatedP4Deparser>())
            return TnaContext(deparser->thread, deparser->tnaParams);
        else
            return boost::none;
    }

    boost::optional<cstring>
    containingTnaParam(const LinearPath& linearPath, const TnaParams& tnaParams,
                       P4::ReferenceMap* refMap) {
        auto* topLevelPath = linearPath.components[0]->to<IR::PathExpression>();
        BUG_CHECK(topLevelPath, "Path-like expression tree was rooted in "
            "non-path expression: %1%", linearPath.components[0]);
        auto* decl = refMap->getDeclaration(topLevelPath->path);
        BUG_CHECK(decl, "No declaration for top level path in path-like "
            "expression: %1%", topLevelPath);
        auto* param = decl->to<IR::Parameter>();
        if (!param) return boost::none;
        for (auto& item : tnaParams) {
            cstring tnaParam = item.first;
            cstring p4Param = item.second;
            if (param->name == p4Param) return tnaParam;
        }
        return boost::none;
    }

    bool isMetadataType(const IR::Type* type) {
        if (type->is<IR::Type_Struct>()) return true;
        if (auto* annotated = type->to<IR::IAnnotated>()) {
            auto* intrinsicMetadata = annotated->getAnnotation("intrinsic_metadata");
            if (intrinsicMetadata) return true;
        }
        return false;
    }

    bool isMetadataOrPrimitiveType(const IR::Type* type) {
        return isMetadataType(type) || type->is<IR::Type_Bits>() ||
               type->is<IR::Type_InfInt>() || type->is<IR::Type_Boolean>();
    }

    bool isMetadata(const LinearPath& path, P4::TypeMap* typeMap) {
        auto* lastComponent = path.components.back();
        return std::all_of(path.components.begin(), path.components.end(),
                           [&](const IR::Expression* component) {
            LOG2("isMetadata? checking component: " << component);
            auto* type = typeMap->getType(component);
            BUG_CHECK(type, "Couldn't find type for: %1%", component);
            LOG3("isMetadata? type is: " << type);
            if (component == lastComponent) return isMetadataOrPrimitiveType(type);
            return isMetadataType(type);
        });
    }

    const IR::Node* analyzePathlikeExpression(IR::Expression* expr) {
        // a field is either a path expressin or a member
        if (!expr->is<IR::PathExpression>() && !expr->is<IR::Member>())
            return expr;

        auto tnaContext = findTnaContext();
        if (!tnaContext) {
            LOG4("[CollectBridgedFields]  no TNA context!");
            return expr;
        }

        auto* orig = getOriginal<IR::Expression>();
        PathLinearizer linearizer;
        orig->apply(linearizer);
        if (!linearizer.linearPath) {
            LOG2("Won't replace complex or invalid expression: " << expr);
            return expr;
        }

        auto& linearPath = *linearizer.linearPath;
        if (!isMetadata(linearPath, typeMap)) {
            LOG2("Won't bridge non-metadata expression: " << expr);
            return expr;
        }

        const gress_t currentThread = tnaContext->first;
        const TnaParams& visibleTnaParams = tnaContext->second;

        auto tnaParam = containingTnaParam(linearPath, visibleTnaParams, refMap);
        if (!tnaParam) {
            LOG2("Won't bridge metadata which isn't a subobject of a TNA "
                     "standard parameter: " << expr);
            return expr;
        }

        using sliced = boost::adaptors::sliced;

        std::string fullPathStr;
        auto& components = linearPath.components;
        for (auto* component : components | sliced(1, components.size())) {
            fullPathStr.push_back('.');
            if (auto* path = component->to<IR::PathExpression>())
                fullPathStr.append(path->path->name.name.c_str());
            else if (auto* member = component->to<IR::Member>())
                fullPathStr.append(member->member.name.c_str());
            else
                BUG("Unexpected path-like expression component: %1%", component);
        }

        cstring fullPath(fullPathStr);
        FieldRef fieldRef(*tnaParam, fullPath);
        if (bmMap.find(fieldRef) != bmMap.end()) {
            LOG4("Need to replace expression " << expr);
            auto cgMetadataParam = tnaContext->second.at("compiler_generated_meta");
            auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                          IR::ID("^bridged_metadata"));
            auto* fieldMember =
                new IR::Member(member, bridgedHeaderFieldNames.at(fieldRef));
            return fieldMember;
        }
        return expr;
    }

    const IR::Node* postorder(IR::Member* member) override {
        return analyzePathlikeExpression(member);
    }

    const IR::Node* postorder(IR::PathExpression* path) override {
        return analyzePathlikeExpression(path);
    }

    const ordered_set<FieldRef>& bmMap;
    const ordered_map<FieldRef, cstring>& bridgedHeaderFieldNames;
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

}  // namespace

BridgeMetadata::BridgeMetadata(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
    auto* collectBridgedFields = new CollectBridgedFields(refMap, typeMap);
    auto* bridgeIngressToEgress = new BridgeIngressToEgress(collectBridgedFields->fieldsToBridge,
            collectBridgedFields->fieldInfo, refMap, typeMap);
    addPasses({
        collectBridgedFields,
        bridgeIngressToEgress,
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        new CopyPropagateBridgedMetadata(collectBridgedFields->fieldsToBridge,
                          bridgeIngressToEgress->bridgedHeaderFieldNames,
                          refMap, typeMap)
    });
}

}  // namespace BFN
