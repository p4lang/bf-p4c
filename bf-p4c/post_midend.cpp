#include "bf-p4c/post_midend.h"

namespace BFN {

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
PostMidEnd::PostMidEnd(BFN_Options& options, bool with_bridge_packing) {
    refMap.setIsV1(true);
    bindings = new ParamBinding(&typeMap,
        options.langVersion == CompilerOptions::FrontendVersion::P4_14);

    conv = new BackendConverter(&refMap, &typeMap, bindings, pipe);
    evaluator = new BFN::ApplyEvaluator(&refMap, &typeMap);
    addPasses({
        new BFN::TypeChecking(&refMap, &typeMap, true),
        new RenameArchParams(&refMap, &typeMap),
        new FillFromBlockMap(&refMap, &typeMap),
        evaluator,
        bindings,
        conv,
        // reserved for bridge packing passes
    });
}

}  // namespace BFN
