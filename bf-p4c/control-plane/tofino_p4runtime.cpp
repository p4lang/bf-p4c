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

#include "control-plane/p4RuntimeSerializer.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/typeMap.h"
#include "ir/ir.h"
#include "lib/nullstream.h"
#include "bf-p4c/control-plane/synthesize_valid_field.h"
#include "bf-p4c/bf-p4c-options.h"

namespace BFN {

void serializeP4Runtime(const IR::P4Program* program,
                        const BFN_Options& options) {
    // If the user didn't ask for us to generate P4Runtime, skip the analysis.
    if (options.p4RuntimeFile.isNullOrEmpty() &&
        options.p4RuntimeEntriesFile.isNullOrEmpty())
        return;

    if (Log::verbose())
        std::cout << "Generating P4Runtime output" << std::endl;

    // Generate a new version of the program that replaces all references to
    // `isValid()` with references to a BMV2-like `$valid$` field.
    // XXX(seth): This is just a temporary hack using the existing pass from
    // BMV2. In the long term, we'll want to write a similar pass for Tofino
    // that both satisfies the needs of P4Runtime and produces IR that will
    // simplify the backend.
    P4::ReferenceMap refMap;
    refMap.setIsV1(true);
    P4::TypeMap typeMap;
    auto* evaluator = new P4::EvaluatorPass(&refMap, &typeMap);
    PassManager p4RuntimeFixups = {
        new SynthesizeValidField(&refMap, &typeMap),
        new P4::TypeChecking(&refMap, &typeMap),
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
