#ifndef EXTENSIONS_BF_P4C_MIDEND_SIMPLIFY_ARGS_H_
#define EXTENSIONS_BF_P4C_MIDEND_SIMPLIFY_ARGS_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/cloner.h"
#include "midend/flattenHeaders.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/midend/check_header_alignment.h"

namespace BFN {

/**
 * This passes flattened nested struct within a struct, as well as
 * nested struct within a header.
 *
 * The corresponding pass in p4lang/p4c FlattenInterfaceStruct and
 * FlattenHeader create field name with a leading '_' and a trailing
 * number which is not compatible with how we name field in brig.
 * In addition, the FlattenInterfaceStruct pass does not seem to
 * work correctly, that is, typeChecking seems to fail after
 * the FlattenInterfaceStruct pass.
 *
 * So I decided to not use those two passes for now.
 */
class FlattenHeader : public Modifier {
    P4::ClonePathExpressions cloner;
    const P4::TypeMap* typeMap;
    IR::Type_Header* flattenedHeader;
    std::vector<cstring> nameSegments{};
    std::vector<const IR::Annotations*> allAnnotations{};
    cstring makeName(cstring sep) const;
    void flattenType(const IR::Type* type);
    const IR::Annotations* mergeAnnotations() const;

    const IR::Member* flattenedMember;
    std::vector<cstring> memberSegments{};
    std::map<cstring, cstring> fieldNameMap;
    std::map<cstring, std::tuple<const IR::Expression*, cstring>> replacementMap;
    cstring makeMember(cstring sep) const;
    void flattenMember(const IR::Member* member);
    const IR::Member* doFlattenMember(const IR::Member* member);

    std::vector<cstring> pathSegments{};
    cstring makePath(cstring sep) const;
    void flattenStructInitializer(const IR::StructInitializerExpression* e,
            IR::IndexedVector<IR::NamedExpression>* c);
    IR::StructInitializerExpression*
        doFlattenStructInitializer(const IR::StructInitializerExpression* e);
    IR::ListExpression* flatten_list(const IR::ListExpression* args);
    void explode(const IR::Expression*, IR::Vector<IR::Expression>*);

 public:
    explicit FlattenHeader(P4::TypeMap* typeMap) : typeMap(typeMap) {}
    bool preorder(IR::Type_Header* header) override;
    bool preorder(IR::Member* member) override;
    void postorder(IR::Member* member) override;
    bool preorder(IR::MethodCallExpression* mc) override;
};

/**
 * Assume header type are flattend, no nested struct.
 */
class EliminateHeaders : public Transform {
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;

 public:
    EliminateHeaders(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) :
        refMap(refMap), typeMap(typeMap) { setName("EliminateHeaders"); }
    std::map<cstring, IR::Vector<IR::Type>> rewriteTupleType;
    std::map<const IR::MethodCallExpression* , const IR::Type*> rewriteOtherType;
    const IR::Node* preorder(IR::Argument* arg) override;
    void elimConcat(IR::Vector<IR::Expression>& output, const IR::Concat* expr);
};

class RewriteTypeArguments : public Transform {
     const EliminateHeaders* eeh;
 public:
    explicit RewriteTypeArguments(const EliminateHeaders* eeh) : eeh(eeh) {}
    const IR::Node* preorder(IR::Type_Struct* type_struct) override;
    const IR::Node* preorder(IR::MethodCallExpression* mc) override;
};
/**
 * This pass manager performs the following simplification on headers
 * and emit() methods.
 *
 * 1. header h {
 *      struct s {
 *        bit<8> f0;
 *      }
 *    }
 *
 *   is converted to
 *
 *   header h {
 *      bit<8> _s_f0;
 *   }
 *
 * 2. emit(hdr) is converted to
 *    emit({hdr.f0, hdr.f1})
 *
 * 3. header h {
 *       @flexible
 *       struct s0 {
 *          bit<8> f0;
 *       }
 *       @flexible
 *       struct s1 {
 *          bit<8> f0;
 *       }
 *    }
 *
 *    is converted to
 *
 *    header h {
 *       bit<8> _s0_f0 @flexible;
 *       bit<8> _s1_f0 @flexible;
 *    }
 */

/**
 * XXX(hanw): We can probably simplify this pass manager by combining
 * the following four passes into fewer passes.
 */
class SimplifyEmitArgs : public PassManager {
 public:
    SimplifyEmitArgs(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
        auto eliminateHeaders = new EliminateHeaders(refMap, typeMap);
        auto rewriteTypeArguments = new RewriteTypeArguments(eliminateHeaders);
        passes.push_back(new FlattenHeader(typeMap));
        passes.push_back(new P4::ClearTypeMap(typeMap));
        passes.push_back(new BFN::TypeChecking(refMap, typeMap, true));
        passes.push_back(eliminateHeaders);
        passes.push_back(rewriteTypeArguments);
        passes.push_back(new P4::ClearTypeMap(typeMap));
        passes.push_back(new BFN::TypeChecking(refMap, typeMap, true));
        passes.push_back(new PadFlexibleField(refMap, typeMap)),
        passes.push_back(new P4::ClearTypeMap(typeMap));
        passes.push_back(new BFN::TypeChecking(refMap, typeMap, true));
    }
};

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_MIDEND_SIMPLIFY_ARGS_H_ */