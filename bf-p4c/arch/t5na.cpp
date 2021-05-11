#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/cloner.h"
#include "midend/validateProperties.h"
#include "midend/copyStructures.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/arch/check_extern_invocation.h"
#include "bf-p4c/arch/t5na.h"
#include "bf-p4c/arch/fromv1.0/phase0.h"
#include "bf-p4c/arch/rewrite_action_selector.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/device.h"
#include "bf-p4c/parde/field_packing.h"
#include "bf-p4c/midend/type_checker.h"

namespace BFN {

T5naArchTranslation::T5naArchTranslation(P4::ReferenceMap *refMap,
                                         P4::TypeMap *typeMap, BFN_Options &options) {
    addDebugHook(options.getDebugHook());
    addPasses({
        new RewriteControlAndParserBlocks(refMap, typeMap),
        new RestoreParams(options),
        new CheckTNAExternInvocation(refMap, typeMap),
        new LoweringType(),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
        new P4::ValidateTableProperties({"implementation", "size", "counters", "meters",
                                         "filters", "idle_timeout", "registers",
                                         "requires_versioning", "atcam", "alpm", "proxy_hash",
                                         /* internal table property, not exposed to customer */
                                         "as_alpm", "number_partitions", "subtrees_per_partition",
                                         "atcam_subset_width", "shift_granularity"}),
        new BFN::RewriteActionSelector(refMap, typeMap),
        new ConvertPhase0(refMap, typeMap),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
