#include "bf-p4c/post_midend.h"
#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/common/bridged_packing.h"
#include "bf-p4c/midend/check_header_alignment.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/backend.h"
#include "bf-p4c/midend/simplify_args.h"
#include "midend/local_copyprop.h"
#include "frontends/p4/typeMap.h"

namespace BFN {

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

    addPasses({
        (!with_bridge_packing && map != nullptr) ? new ReplaceFlexibleType(*map) : nullptr,
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
