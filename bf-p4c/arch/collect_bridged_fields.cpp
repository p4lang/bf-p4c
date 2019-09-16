#include "collect_bridged_fields.h"

#include <boost/range/adaptor/sliced.hpp>

#include "bf-p4c/arch/bridge_metadata.h"
#include "bf-p4c/midend/path_linearizer.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "ir/ir.h"

namespace BFN {
namespace {

using TnaParams = CollectBridgedFields::TnaParams;

bool isMetadataType(const IR::Type* type) {
    if (type->is<IR::Type_Struct>()) return true;
    if (auto* annotated = type->to<IR::IAnnotated>()) {
        /// XXX(hanw): note that we are looking for the annotation in stratum.p4
        auto* intrinsicMetadata = annotated->getAnnotation("__intrinsic_metadata");
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

template <typename Func>
void forAllTouchedFields(const LinearPath& linearPath, P4::TypeMap* typeMap,
                         Func func) {
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

    auto* lastComponentType = typeMap->getType(components.back());
    BUG_CHECK(lastComponentType,
              "Couldn't find type for: %1%", components.back());
    if (auto* structType = lastComponentType->to<IR::Type_StructLike>()) {
        fullPathStr.push_back('.');
        cstring fullPath(fullPathStr);
        for (auto* field : structType->fields) {
            auto* fieldType = typeMap->getType(field);
            BUG_CHECK(fieldType, "Couldn't find type for: %1%", field);
            auto* fieldExpr =
              new IR::Member(fieldType, components.back(), IR::ID(field->name));
            func(fullPath + field->name, fieldType, fieldExpr);
        }
    } else {
        func(cstring(fullPathStr), lastComponentType, components.back());
    }
}

}  // namespace

CollectBridgedFields::CollectBridgedFields(P4::ReferenceMap* refMap,
                                           P4::TypeMap* typeMap)
  : refMap(refMap), typeMap(typeMap) {
    joinFlows = true;
    visitDagOnce = false;
}

CollectBridgedFields* CollectBridgedFields::clone() const {
    auto* rv = new CollectBridgedFields(*this);
    LOG4("[==CLONE==] old: " << static_cast<const void*>(this)
         << " new: " << static_cast<const void*>(rv));
    for (auto fieldRef : mustWrite[EGRESS]) {
        LOG4("[==CLONE old==] " << static_cast<const void*>(this)
             << " mustWrite[EGRESS] :: " << fieldRef.first << fieldRef.second);
    }
    for (auto fieldRef : rv->mustWrite[EGRESS]) {
        LOG4("[==CLONE new==] " << static_cast<void*>(rv) << " mustWrite[EGRESS] :: "
             << fieldRef.first << fieldRef.second);
    }
    return rv;
}

void CollectBridgedFields::flow_merge(Visitor& otherVisitor) {
    auto& other = dynamic_cast<CollectBridgedFields&>(otherVisitor);
    LOG4("[==MERGE==] left: " << static_cast<const void*>(this) << " right: "
         << static_cast<const void*>(&other));
    for (auto fieldRef : mustWrite[EGRESS]) {
        LOG4("[==MERGE left==] " << static_cast<void*>(this) << " mustWrite[EGRESS] :: "
             << fieldRef.first << fieldRef.second);
    }
    for (auto fieldRef : other.mustWrite[EGRESS]) {
        LOG4("[==MERGE right==] " << static_cast<void*>(&other) << " mustWrite[EGRESS] :: "
             << fieldRef.first << fieldRef.second);
    }
    for (auto thread : { INGRESS, EGRESS }) {
        mayReadUninitialized[thread] |= other.mayReadUninitialized[thread];
        mayWrite[thread] |= other.mayWrite[thread];
        mustWrite[thread] &= other.mustWrite[thread];
        fieldInfo.insert(other.fieldInfo.begin(), other.fieldInfo.end());
    }
    for (auto fieldRef : mustWrite[EGRESS]) {
        LOG4("[==MERGE final==] " << static_cast<void*>(this) << " mustWrite[EGRESS] :: "
             << fieldRef.first << fieldRef.second);
    }
}

boost::optional<CollectBridgedFields::TnaContext>
CollectBridgedFields::findTnaContext() const {
    if (auto* control = findContext<IR::BFN::TnaControl>())
        return TnaContext(control->thread, control->tnaParams);
    else if (auto* parser = findContext<IR::BFN::TnaParser>())
        return TnaContext(parser->thread, parser->tnaParams);
    else if (auto* deparser = findContext<IR::BFN::TnaDeparser>())
        return TnaContext(deparser->thread, deparser->tnaParams);
    else
        return boost::none;
    // FIXME(zma) the code above could use better abstraction?
}

bool CollectBridgedFields::analyzePathlikeExpression(const IR::Expression* expr) {
    // If we're not inside a TNA parser, deparser or control, ignore this expression.
    auto tnaContext = findTnaContext();
    if (!tnaContext) {
        LOG4("[CollectBridgedFields]  no TNA context!");
        return false;
    }

    const gress_t currentThread = tnaContext->first;
    const TnaParams& visibleTnaParams = tnaContext->second;

    const bool exprIsRead = isRead();
    const bool exprIsWrite = isWrite();
    if (!exprIsRead && !exprIsWrite) {
        LOG2("Won't bridge expression which is neither a read nor a "
             "write: " << expr);
        return false;
    }

    PathLinearizer linearizer;
    expr->apply(linearizer);
    if (!linearizer.linearPath) {
        LOG2("Won't bridge complex or invalid expression: " << expr);
        return false;
    }
    auto& linearPath = *linearizer.linearPath;
    if (!isMetadata(linearPath, typeMap)) {
        LOG2("Won't bridge non-metadata expression: " << expr);
        return false;
    }
    auto tnaParam = containingTnaParam(linearPath, visibleTnaParams, refMap);
    if (!tnaParam) {
        LOG2("Won't bridge metadata which isn't a subobject of a TNA "
             "standard parameter: " << expr);
        return false;
    }
    LOG2("Expression touches TNA standard parameter subobject; considering "
         "for bridging: " << expr);
    forAllTouchedFields(linearPath, typeMap, [&](cstring field,
                                                 const IR::Type* fieldType,
                                                 const IR::Expression* fieldExpr) {
        FieldRef fieldRef(*tnaParam, field);
        fieldInfo.emplace(fieldRef, BridgedFieldInfo{fieldType, fieldExpr});
        if (exprIsRead && !mustWrite[currentThread].count(fieldRef)) {
            LOG2("Found possibly-uninitialized read for " << fieldRef.first
                 << fieldRef.second);
            mayReadUninitialized[currentThread].emplace(fieldRef);
        }
        if (exprIsWrite) {
            LOG2("Found write for " << fieldRef.first << fieldRef.second);
            mayWrite[currentThread].emplace(fieldRef);
            mustWrite[currentThread].emplace(fieldRef);
        }
    });
    return false;
}

bool CollectBridgedFields::preorder(const IR::Annotation* annot) {
    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            ::warning("%1%", "@pragma pa_do_not_bridge's arguments must be string literals,"
                      " skipped");
            return false; }
        return true;
    };

    auto pragmaName = annot->name.name;
    if (pragmaName != "pa_do_not_bridge") return true;

    LOG4("[CollectBridgedFields] Do Not Bridge pragma: " << annot);
    auto& exprs = annot->expr;
    // Check pragma arguments
    if (exprs.size() != 2) {
        ::warning("@pragma pa_do_not_bridge must have 2 arguments (gress and field name)"
                ", only %1% argument found, skipped", exprs.size());
        return true; }

    auto gress = exprs[0]->to<IR::StringLiteral>();
    auto field = exprs[1]->to<IR::StringLiteral>();
    if (!check_pragma_string(gress) || !check_pragma_string(field))
        return true;

    // Check gress
    if (gress->value != "ingress" && gress->value != "egress") {
        ::warning("@pragma pa_do_not_bridge's first argument must either be ingress/egress, "
                  "instead of %1%, skipped", gress);
        return true; }

    // Warning if an egress field is bridged. Bridge the ingress version in that case
    if (gress->value == "egress")
        ::warning("@pragma pa_do_not_bridge marks egress field %1% as not bridged, bridging "
                  "ingress field instead", field);

    // The fieldRef object names start with a . followed by the field name
    cstring fieldName = "." + field->value;
    doNotBridge.insert(fieldName);
    LOG1("@pragma do_not_bridge set for " << field);

    return true;
}

bool CollectBridgedFields::preorder(const IR::Member* member) {
    LOG4("[CollectBridgedFields] visit " << member);
    return analyzePathlikeExpression(member);
}

bool CollectBridgedFields::preorder(const IR::PathExpression* path) {
    return analyzePathlikeExpression(path);
}

void CollectBridgedFields::end_apply() {
    // A field must be bridged if it may be read uninitialized in egress and
    // it may be written in ingress.
    for (auto& fieldRef : mayReadUninitialized[EGRESS]) {
        if (mayWrite[INGRESS].count(fieldRef)) {
            cstring fieldName = fieldRef.first + fieldRef.second;
            if (doNotBridge.count(fieldRef.second)) {
                LOG1("Not Bridging field: " << fieldName << " marked by pa_do_not_bridge");
            } else {
                std::string f_name(fieldName.c_str());
                if (f_name.find(COMPILER_META) != std::string::npos
                    && (f_name.find("mirror_source") != std::string::npos ||
                        f_name.find("mirror_id") != std::string::npos)) {
                    continue;
                }

                LOG1("Bridging field: " << fieldName);
                fieldsToBridge.emplace(fieldRef);
            }
        }
    }
}


}  // namespace BFN
