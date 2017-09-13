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

#include "tofino/control-plane/tofino_p4runtime.h"

#include "control-plane/p4RuntimeSerializer.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/typeMap.h"
#include "ir/ir.h"
#include "lib/nullstream.h"
#include "tofino/control-plane/synthesize_valid_field.h"
#include "tofino/tofinoOptions.h"

namespace BFN {

void serializeP4Runtime(const IR::P4Program* program,
                        const Tofino_Options& options) {
    if (Log::verbose())
        std::cout << "Generating P4Runtime output" << std::endl;

    std::ostream* out = openFile(options.p4RuntimeFile, false);
    if (!out) {
        ::error("Couldn't open %1%", options.p4RuntimeFile);
        return;
    }

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
    PassManager p4runtimeFixups = {
        new SynthesizeValidField(&refMap, &typeMap),
        new P4::TypeChecking(&refMap, &typeMap),
        evaluator
    };
    auto* p4runtimeProgram = program->apply(p4runtimeFixups);

    serializeP4Runtime(out, p4runtimeProgram, evaluator->getToplevelBlock(),
                       &refMap, &typeMap, options.p4RuntimeFormat);
}

}  // namespace BFN
