#include "bf-p4c/common/type_categories.h"

#include <algorithm>
#include "bf-p4c/common/path_linearizer.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"

namespace BFN {

bool isIntrinsicMetadataType(const IR::Type* type) {
    BUG_CHECK(!type->is<IR::Type_Name>(), "Trying to categorize a Type_Name; "
              "you can avoid this problem by getting types from a TypeMap");
    auto* annotated = type->to<IR::IAnnotated>();
    if (!annotated) return false;
    auto* intrinsicMetadata = annotated->getAnnotation("__intrinsic_metadata");
    return bool(intrinsicMetadata);
}

bool isCompilerGeneratedType(const IR::Type* type) {
    BUG_CHECK(!type->is<IR::Type_Name>(), "Trying to categorize a Type_Name; "
              "you can avoid this problem by getting types from a TypeMap");
    auto* annotated = type->to<IR::IAnnotated>();
    if (!annotated) return false;
    auto* intrinsicMetadata = annotated->getAnnotation("__compiler_generated");
    return bool(intrinsicMetadata);
}

bool isMetadataType(const IR::Type* type) {
    BUG_CHECK(!type->is<IR::Type_Name>(), "Trying to categorize a Type_Name; "
              "you can avoid this problem by getting types from a TypeMap");
    return type->is<IR::Type_Struct>() || isIntrinsicMetadataType(type);
}

bool isHeaderType(const IR::Type* type) {
    BUG_CHECK(!type->is<IR::Type_Name>(), "Trying to categorize a Type_Name; "
              "you can avoid this problem by getting types from a TypeMap");
    return type->is<IR::Type_Header>() && !isIntrinsicMetadataType(type);
}

bool isPrimitiveType(const IR::Type* type) {
    BUG_CHECK(!type->is<IR::Type_Name>(), "Trying to categorize a Type_Name; "
              "you can avoid this problem by getting types from a TypeMap");
    return type->is<IR::Type_Bits>() ||
           type->is<IR::Type_InfInt>() ||
           type->is<IR::Type_Boolean>();
}

bool isMetadataReference(const LinearPath& path, P4::TypeMap* typeMap) {
    auto* lastComponent = path.components.back();
    return std::all_of(path.components.begin(), path.components.end(),
                       [&](const IR::Expression* component) {
        auto* type = typeMap->getType(component);
        BUG_CHECK(type, "No type for path component: %1%", component);
        if (component == lastComponent)
            return isMetadataType(type) || isPrimitiveType(type);
        return isMetadataType(type);
    });
}

bool isHeaderReference(const LinearPath& path, P4::TypeMap* typeMap) {
    // If the last component has header type, this is trivially a header
    // reference.
    auto* lastComponent = path.components.back();
    auto* lastComponentType = typeMap->getType(lastComponent);
    BUG_CHECK(lastComponentType, "No type for path component: %1%",
              lastComponent);
    if (isHeaderType(lastComponentType)) return true;

    // This is also a header reference if the last component is a field of
    // primitive type and the previous component has header type.
    if (path.components.size() < 2) return false;
    auto* nextToLastComponent = path.components[path.components.size() - 2];
    auto* nextToLastComponentType = typeMap->getType(nextToLastComponent);
    BUG_CHECK(nextToLastComponentType, "No type for path component: %1%",
              nextToLastComponent);
    return isHeaderType(nextToLastComponentType) &&
           isPrimitiveType(lastComponentType);
}

bool isPrimitiveReference(const LinearPath& path, P4::TypeMap* typeMap) {
    auto* lastComponent = path.components.back();
    auto* lastComponentType = typeMap->getType(lastComponent);
    BUG_CHECK(lastComponentType, "No type for path component: %1%",
              lastComponent);
    return isPrimitiveType(lastComponentType);
}

bool isPrimitiveFieldReference(const LinearPath& path, P4::TypeMap* typeMap) {
    if (path.components.size() < 2) return false;
    auto* nextToLastComponent = path.components[path.components.size() - 2];
    auto* nextToLastComponentType = typeMap->getType(nextToLastComponent);
    BUG_CHECK(nextToLastComponentType, "No type for path component: %1%",
              nextToLastComponent);
    auto* lastComponent = path.components.back();
    auto* lastComponentType = typeMap->getType(lastComponent);
    BUG_CHECK(lastComponentType, "No type for path component: %1%",
              lastComponent);
    return nextToLastComponentType->is<IR::Type_StructLike>() &&
           isPrimitiveType(lastComponentType);
}

bool isSubobjectOfParameter(const LinearPath& path, P4::ReferenceMap* refMap) {
    return bool(getContainingParameter(path, refMap));
}

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

}  // namespace BFN
