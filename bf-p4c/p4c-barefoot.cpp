#include <stdio.h>
#include <signal.h>
#include <string>
#include <iostream>

#include "backend.h"
#include "device.h"
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/compile_context.h"
#include "lib/crash.h"
#include "lib/gc.h"
#include "lib/log.h"
#include "lib/exceptions.h"
#include "frontends/p4/frontend.h"
#include "frontends/p4/createBuiltins.h"
#include "frontends/p4/validateParsedProgram.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4-14/header_type.h"
#include "frontends/p4-14/typecheck.h"
#include "frontends/common/applyOptionsPragmas.h"
#include "frontends/common/parseInput.h"
#include "common/extract_maupipe.h"
#include "midend.h"
#include "bf-p4c-options.h"
#include "bf-p4c/control-plane/tofino_p4runtime.h"
#include "arch/simple_switch.h"

static void log_dump(const IR::Node *node, const char *head) {
    if (!node || !LOGGING(1)) return;
    if (head)
        std::cout << '+' << std::setw(strlen(head)+6) << std::setfill('-') << "+\n| "
                  << head << " |\n" << '+' << std::setw(strlen(head)+3) << "+"
                  << std::endl << std::setfill(' ');
    if (LOGGING(2))
        dump(node);
    else
        std::cout << *node << std::endl;
}

int main(int ac, char **av) {
    setup_gc_logging();
    setup_signals();

    AutoCompileContext autoBFNContext(new BFNContext);
    auto& options = BFNContext::get().options();

    if (!options.process(ac, av) || ::errorCount() > 0)
        return 1;

    options.setInputFile();
    Device::init(options.device);

    auto hook = options.getDebugHook();

    auto program = P4::parseP4File(options);
    if (!program || ::errorCount() > 0)
        return 1;

    BFNOptionPragmaParser optionsPragmaParser;
    program->apply(P4::ApplyOptionsPragmas(optionsPragmaParser));

    program = P4::FrontEnd(hook).run(options, program, true);
    if (!program)
        return 1;
    log_dump(program, "Initial program");

    BFN::generateP4Runtime(program, options);
    if (::errorCount() > 0)
        return 1;

    BFN::MidEnd midend(options);
    midend.addDebugHook(hook);
    program = program->apply(midend);
    if (!program)
        return 1;
    log_dump(program, "After midend");

    bool useTna = (options.langVersion == CompilerOptions::FrontendVersion::P4_16 &&
                   options.arch == "native");
    auto maupipe = extract_maupipe(program, useTna);

    if (::errorCount() > 0)
        return 1;
    if (!maupipe)
        return 1;

    if (Log::verbose())
    std::cout << "Compiling" << std::endl;

    BFN::Backend backend(options);
    maupipe = maupipe->apply(backend);

    if (Log::verbose())
        std::cout << "Done." << std::endl;
    return ::errorCount() > 0;
}
