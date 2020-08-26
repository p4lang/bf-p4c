#ifndef BF_P4C_FRONTEND_H_
#define BF_P4C_FRONTEND_H_

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/arch/fromv1.0/programStructure.h"
#include "bf-p4c/common/parse_annotations.h"
#include "bf-p4c/lib/error_type.h"
#include "frontends/common/applyOptionsPragmas.h"
#include "frontends/common/options.h"
#include "frontends/common/parseInput.h"
#include "frontends/p4/frontend.h"
#include "frontends/p4/fromv1.0/converters.h"
#include "ir/ir.h"
#include "lib/error.h"

const IR::P4Program* run_frontend() {
    // Initialize the Barefoot-specific error types, in case they aren't already initialized.
    BFN::ErrorType::getErrorTypes();

    auto& options = BackendOptions();
    auto hook = options.getDebugHook();

    const IR::P4Program* program = nullptr;
    if (options.arch == "tna" && options.langVersion == CompilerOptions::FrontendVersion::P4_14) {
        program = P4::parseP4File<P4V1::TnaConverter>(options);
    } else {
        // XXX(hanw): used by 14-to-v1model path, to be removed
        P4V1::Converter::createProgramStructure = P4V1::TNA_ProgramStructure::create;
        program = P4::parseP4File(options);
    }
    if (!program || ::errorCount() > 0)
        return program;

    BFNOptionPragmaParser optionsPragmaParser;
    program->apply(P4::ApplyOptionsPragmas(optionsPragmaParser));

    return P4::FrontEnd(BFN::ParseAnnotations(), hook).run(options, program, options.skip_seo);
}

#endif  // BF_P4C_FRONTEND_H_
