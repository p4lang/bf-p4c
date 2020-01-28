#include "bf-p4c/post_midend.h"
#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/midend/check_header_alignment.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/backend.h"
#include "bf-p4c/midend/simplify_args.h"
#include "midend/local_copyprop.h"
#include "frontends/p4/typeMap.h"

namespace BFN {

/*
 * Replace the repacked bridge header in midend
 */
class ReplaceFlexHeaderTypes : public Transform {
    RepackedHeaderTypes* map;

 public:
    explicit ReplaceFlexHeaderTypes(RepackedHeaderTypes* map):
        map(map) {}

    const IR::Node* preorder(IR::Type_StructLike* type) override {
        auto name = type->name;
        if (map->count(name)) {
            LOG3("replace " << map->at(name));
            return map->at(name); }
        return type;
    }

    bool isPadding(const IR::StructField* f) {
        if (f->getAnnotation("padding"))
            return true;
        return false;
    }

    bool findPaddingField(const IR::Type_StructLike* st) {
        for (auto f : st->fields) {
            auto anno = f->getAnnotation("padding");
            if (anno != nullptr)
                return true; }
        return false;
    }

    // rewrite struct initializer expression according to the
    // packed flexible header format.
    const IR::Node* preorder(IR::StructInitializerExpression* expr) override {
        if (auto st = expr->type->to<IR::Type_StructLike>()) {
            if (map->count(st->name) == 0)
                return expr;
            auto type = map->at(st->name);
            LOG3("expr " << expr << " type " << type);
            if (findPaddingField(type)) {
                auto comp = new IR::IndexedVector<IR::NamedExpression>;
                for (auto f : type->fields) {
                    auto decl = expr->components.getDeclaration(f->name);
                    if (!decl) {
                        if (isPadding(f)) {
                            auto ne = new IR::NamedExpression(f->name,
                                    new IR::Constant(f->type, 0));
                            comp->push_back(ne);
                        }
                        LOG3(" decl " << f);
                    } else {
                        LOG3(" padding " << f);
                        auto c = decl->to<IR::NamedExpression>();
                        if (isPadding(f)) {
                            auto ne = new IR::NamedExpression(f->name,
                                    new IR::Constant(f->type, 0));
                            comp->push_back(ne);
                        } else {
                            comp->push_back(c);
                        }
                    }
                }
                // if
                return new IR::StructInitializerExpression(expr->typeName, *comp);
            }
        }
        return expr;
    }
};

bool flattenFlexibleHeader(const Visitor::Context *ctxt, const IR::Type_StructLike* e) {
    if (e->getAnnotation("flexible"))
        return true;
    for (auto f : e->fields) {
        auto anno = f->getAnnotation("flexible");
        if (anno != nullptr)
            return true; }
    return false;
}

class PostMidEndLast : public PassManager {
 public:
    PostMidEndLast() { setName("PostMidEndLast"); }
};

/*
 * Only visit BFN::BridgePipe created for flexible packing
 */
class OptimizeBridgeMetadataPacking : public Inspector {
    const BFN_Options& options;
    RepackedHeaderTypes* map;

 public:
    explicit OptimizeBridgeMetadataPacking(const BFN_Options& options, RepackedHeaderTypes* map) :
        options(options), map(map) {}

    bool preorder(const IR::BFN::Toplevel* tl) override {
        visit(tl->bridge_pipes);
        return false;
    }

    bool preorder(const IR::BFN::BridgePipe* pipe) override {
        auto pack = new PackFlexibleHeaders(options);
        pack->addDebugHook(options.getDebugHook(), true);
        pipe->apply(*pack);
        for (auto h : pack->getPackedHeaders()) {
            map->emplace(h.first, h.second);
        }
        return false;
    }
};

// Invariants:
//  - must be applied to IR::P4Program node that can be type-checked
//  - must generated IR::P4Program node that can still be type-checked.
// Post condition:
//  - vector of backend pipes for the corresponding p4 program.
//  - if bridge_packing is enabled, a transformed IR::P4Program
//        with @flexible header repacked.
// SimplifyReference transforms IR::P4Program towards the
// backend IR representation, as a result, the transformed
// P4Program no longer type-check.
PostMidEnd::PostMidEnd(BFN_Options& options, RepackedHeaderTypes *map,
        bool with_bridge_packing) : map(map) {
    refMap.setIsV1(true);
    bindings = new ParamBinding(&typeMap,
        options.langVersion == CompilerOptions::FrontendVersion::P4_14);
    conv = new BackendConverter(&refMap, &typeMap, bindings, pipe);
    evaluator = new BFN::ApplyEvaluator(&refMap, &typeMap);
    auto typeChecking = new BFN::TypeChecking(&refMap, &typeMap);

    addPasses({
        (!with_bridge_packing && map != nullptr) ? new ReplaceFlexHeaderTypes(map) : nullptr,
        new P4::ClearTypeMap(&typeMap),
        new BFN::TypeChecking(&refMap, &typeMap, true),
        new RenameArchParams(&refMap, &typeMap),
        new FillFromBlockMap(&refMap, &typeMap),
        evaluator,
        bindings,
        conv,
        // reserved for bridge packing passes
        with_bridge_packing ? new VisitFunctor([this, options, map]() {
            conv->getTop()->apply(OptimizeBridgeMetadataPacking(options, map));
        }) : nullptr,
        // debug print
        (!with_bridge_packing) ? new PostMidEndLast : nullptr,
    });
}

}  // namespace BFN
