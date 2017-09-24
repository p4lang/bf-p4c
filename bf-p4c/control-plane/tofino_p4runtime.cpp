/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "bf-p4c/control-plane/tofino_p4runtime.h"

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/control-plane/synthesize_valid_field.h"
#include "bf-p4c/common/remap_intrin.h"
#include "control-plane/p4RuntimeSerializer.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/simplify.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/uniqueNames.h"
#include "ir/ir.h"
#include "lib/nullstream.h"
#include "midend/actionsInlining.h"
#include "midend/dontcareArgs.h"
#include "midend/eliminateTuples.h"
#include "midend/inlining.h"
#include "midend/localizeActions.h"
#include "midend/moveConstructors.h"
#include "midend/removeParameters.h"
#include "midend/removeReturns.h"

namespace BFN {

void serializeP4Runtime(const IR::P4Program* program,
                        const BFN_Options& options) {
    // If the user didn't ask for us to generate P4Runtime, skip the analysis.
    if (options.p4RuntimeFile.isNullOrEmpty() &&
        options.p4RuntimeEntriesFile.isNullOrEmpty())
        return;

    if (Log::verbose())
        std::cout << "Generating P4Runtime output" << std::endl;

    // Generate a new version of the program that satisfies the prerequisites of
    // the P4Runtime analysis code.
    // XXX(seth): Long term, generateP4Runtime() should be able to operate on
    // the version of the program we have after the frontend, without any
    // dependencies on additional passes. Clearly we have a way to go.
    P4::ReferenceMap refMap;
    refMap.setIsV1(true);
    P4::TypeMap typeMap;
    auto* evaluator = new P4::EvaluatorPass(&refMap, &typeMap);
    PassManager p4RuntimeFixups = {
        // These are prerequisites of LocalizeAllActions.
        evaluator,
        new P4::Inline(&refMap, &typeMap, evaluator),
        new P4::InlineActions(&refMap, &typeMap),
        // We currently can't handle global actions; they need to be associated
        // with a table.
        new P4::LocalizeAllActions(&refMap),
        // We need to run these to avoid issues with duplicate or illegal names.
        // (This is likely mostly or entirely due to the inlining passes above.)
        new P4::UniqueNames(&refMap),
        new P4::UniqueParameters(&refMap, &typeMap),
        // We can only handle a very restricted class of action parameters - the
        // types need to be bit<> or int<> - so we fail without this pass.
        new P4::RemoveActionParameters(&refMap, &typeMap),
        // We need a $valid$ field preinserted before we generate P4Runtime.
        // XXX(seth): This is just a temporary hack using the existing pass from
        // BMV2. In the long term, we'll want to write a similar pass for Tofino
        // that both satisfies the needs of P4Runtime and produces IR that will
        // simplify the backend.
        new SynthesizeValidField(&refMap, &typeMap),
        // We currently can't handle tuples.
        new P4::EliminateTuples(&refMap, &typeMap),
        new RemapIntrinsics,
        // Update types and reevaluate the program.
        new P4::TypeChecking(&refMap, &typeMap, /* updateExpressions = */ true),
        evaluator
    };
    auto* p4RuntimeProgram = program->apply(p4RuntimeFixups);
    auto* evaluatedProgram = evaluator->getToplevelBlock();

    BUG_CHECK(p4RuntimeProgram && evaluatedProgram,
              "Failed to transform the program into a "
              "P4Runtime-compatible form");

    auto p4Runtime =
      generateP4Runtime(p4RuntimeProgram, evaluatedProgram, &refMap, &typeMap);

    if (!options.p4RuntimeFile.isNullOrEmpty()) {
        std::ostream* out = openFile(options.p4RuntimeFile, false);
        if (!out) {
            ::error("Couldn't open P4Runtime API file: %1%", options.p4RuntimeFile);
            return;
        }

        p4Runtime.serializeP4InfoTo(out, options.p4RuntimeFormat);
    }

    if (!options.p4RuntimeEntriesFile.isNullOrEmpty()) {
        std::ostream* out = openFile(options.p4RuntimeEntriesFile, false);
        if (!out) {
            ::error("Couldn't open P4Runtime static entries file: %1%",
                    options.p4RuntimeEntriesFile);
            return;
        }

        p4Runtime.serializeEntriesTo(out, options.p4RuntimeFormat);
    }
}

}  // namespace BFN
