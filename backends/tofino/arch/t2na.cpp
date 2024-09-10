#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "midend/validateProperties.h"
#include "backends/tofino/arch/arch.h"
#include "backends/tofino/arch/add_t2na_meta.h"
#include "backends/tofino/arch/check_extern_invocation.h"
#include "backends/tofino/arch/fromv1.0/phase0.h"
#include "backends/tofino/arch/t2na.h"
#include "backends/tofino/arch/rewrite_action_selector.h"
#include "backends/tofino/bf-p4c-options.h"
#include "backends/tofino/midend/type_checker.h"

namespace BFN {

T2naArchTranslation::T2naArchTranslation(P4::ReferenceMap *refMap,
                                         P4::TypeMap *typeMap, BFN_Options &options) {
    setName("T2naArchTranslation");
    addDebugHook(options.getDebugHook());
    addPasses({
        new AddT2naMeta(),
        new RewriteControlAndParserBlocks(refMap, typeMap),
        new RestoreParams(options, refMap, typeMap),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        new CheckT2NAExternInvocation(refMap, typeMap),
        new LoweringType(),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        new P4::ValidateTableProperties({"implementation", "size", "counters", "meters",
                                         "filters", "idle_timeout", "registers",
                                         "requires_versioning", "atcam", "alpm", "proxy_hash",
                                         /* internal table property, not exposed to customer */
                                         "as_alpm", "number_partitions", "subtrees_per_partition",
                                         "atcam_subset_width", "shift_granularity"}),
        new RewriteActionSelector(refMap, typeMap),
        new ConvertPhase0(refMap, typeMap),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
