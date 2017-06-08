#include <stdio.h>
#include <signal.h>
#include <string>
#include <iostream>

#include "backend.h"
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/crash.h"
#include "lib/gc.h"
#include "lib/log.h"
#include "lib/exceptions.h"
#include "frontends/p4/frontend.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4-14/header_type.h"
#include "frontends/p4-14/typecheck.h"
#include "frontends/common/parseInput.h"
#include "common/extract_maupipe.h"
#include "common/frontend.h"
#include "common/remap_intrin.h"
#include "midend.h"
#include "midend/actionsInlining.h"
#include "tofinoOptions.h"
#include "version.h"

int main(int ac, char **av) {
    setup_gc_logging();
    setup_signals();

    Tofino_Options options;
    options.compilerVersion = P4C_TOFINO_VERSION;

    if (options.process(ac, av) != nullptr)
        options.setInputFile();
    auto hook = options.getDebugHook();
    if (ErrorReporter::instance.getErrorCount() > 0)
        return 1;
    options.preprocessor_options += " -D__TARGET_TOFINO__";

    if (options.target != "tofino") {
        error("only supported target is 'tofino'");
        return 1; }

    auto program = P4::parseP4File(options, new Tofino::ExternConverter);
    program = P4::FrontEnd(hook).run(options, program, true);
    if (!program)
        return 1;
    if (Log::verbose()) {
        std::cout << "-------------------------------------------------" << std::endl
                  << "Initial program" << std::endl
                  << "-------------------------------------------------" << std::endl;
        if (Log::verbosity() > 1)
            dump(program);
        else
            std::cout << *program << std::endl; }
    Tofino::MidEnd midend(options);
    midend.addDebugHook(hook);
    program = program->apply(midend);
    if (!program)
        return 1;
    if (Log::verbose()) {
        std::cout << "-------------------------------------------------" << std::endl
                  << "After midend" << std::endl
                  << "-------------------------------------------------" << std::endl;
        if (Log::verbosity() > 1)
            dump(program);
        else
            std::cout << *program << std::endl; }
    auto maupipe = extract_maupipe(program, options);

    if (ErrorReporter::instance.getErrorCount() > 0)
        return 1;
    if (!maupipe)
        return 1;

    if (Log::verbose())
        std::cout << "Compiling" << std::endl;

    Tofino::backend(maupipe, options);

    if (Log::verbose())
        std::cout << "Done." << std::endl;
    return ErrorReporter::instance.getErrorCount() > 0;
}
