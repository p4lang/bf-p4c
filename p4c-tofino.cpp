#include <stdio.h>
#include <string>
#include <iostream>

#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/log.h"
#include "lib/exceptions.h"
#include "frontends/p4v1/p4-parse.h"
#include "frontends/p4v1.2/p4v1.2-parse.h"
#include "frontends/p4v1.2/v12_frontend.h"
#include "frontends/common/constantFolding.h"
#include "frontends/common/header_type.h"
#include "frontends/common/typecheck.h"
#include "tofinoOptions.h"

extern void test_tofino_backend(const IR::Global *, const Tofino_Options *);
extern void setup_gc_logging();

static const IR::Global *
parse_input(const Tofino_Options &options, FILE* stream) {
    const IR::Global* program = nullptr;
    switch (options.langVersion) {
    case CompilerOptions::FrontendVersion::P4v1:
        program = parse_p4v1_file(options.file, stream);
        options.closeInput(stream);
        break;
    case CompilerOptions::FrontendVersion::P4v1_2: {
       ::error("This compiler currently only handles P4 v1.0");
       break;
    }
    default:
        BUG("Unexpected frontend"); }
    return program;
}


int main(int ac, char **av) {
    setup_gc_logging();

    const IR::Global *program = nullptr;

    Tofino_Options options;
    options.process(ac, av);
    options.setInputFile();
    if (ErrorReporter::instance.getErrorCount() > 0)
        return 1;

    FILE* in = options.preprocess();
    if (in != nullptr) {
        program = parse_input(options, in);
        if (ErrorReporter::instance.getErrorCount() > 0)
            return 1;
        if (!program)
            return 1;

        if (verbose)
            std::cout << "Compiling" << std::endl;
        PassManager fe = {
            new P4V12::ConstantFolding(nullptr, nullptr),
            new CheckHeaderTypes,
            new HeaderTypeMaxLengthCalculator,
            new TypeCheck,
        };
        program = program->apply(fe);

        if (options.target == "tofino")
            test_tofino_backend(program, &options);
    }
    if (verbose)
        std::cout << "Done." << std::endl;
    return ErrorReporter::instance.getErrorCount() > 0;
}
