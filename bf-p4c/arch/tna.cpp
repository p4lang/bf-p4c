/**
 * Copyright (C) 2024 Intel Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the
 * License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied.  See the License for the specific language governing permissions
 * and limitations under the License.
 *
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/cloner.h"
#include "midend/validateProperties.h"
#include "midend/copyStructures.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/arch/check_extern_invocation.h"
#include "bf-p4c/arch/tna.h"
#include "bf-p4c/arch/fromv1.0/phase0.h"
#include "bf-p4c/arch/rewrite_action_selector.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/device.h"
#include "bf-p4c/parde/field_packing.h"
#include "bf-p4c/midend/type_checker.h"

namespace BFN {

TnaArchTranslation::TnaArchTranslation(P4::ReferenceMap *refMap,
                                       P4::TypeMap *typeMap, BFN_Options &options) {
    setName("TnaArchTranslation");
    addDebugHook(options.getDebugHook());
    addPasses({
        new RewriteControlAndParserBlocks(refMap, typeMap),
        new RestoreParams(options, refMap, typeMap),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
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
