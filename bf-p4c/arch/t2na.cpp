#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "midend/validateProperties.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/arch/add_t2na_meta.h"
#include "bf-p4c/arch/check_extern_invocation.h"
#include "bf-p4c/arch/fromv1.0/phase0.h"
#include "bf-p4c/arch/t2na.h"
#include "bf-p4c/arch/rewrite_action_selector.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/midend/type_checker.h"

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
        new P4::ValidateTableProperties(
            {"implementation"_cs, "size"_cs, "counters"_cs, "meters"_cs, "filters"_cs,
             "idle_timeout"_cs, "registers"_cs, "requires_versioning"_cs, "atcam"_cs, "alpm"_cs,
             "proxy_hash"_cs,
             /* internal table property, not exposed to customer */
             "as_alpm"_cs, "number_partitions"_cs, "subtrees_per_partition"_cs,
             "atcam_subset_width"_cs, "shift_granularity"_cs}),
        new RewriteActionSelector(refMap, typeMap),
        new ConvertPhase0(refMap, typeMap),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
