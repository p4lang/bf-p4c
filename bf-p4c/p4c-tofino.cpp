#include <stdio.h>
#include <signal.h>
#include <string>
#include <iostream>

#include "backend.h"
#include "device.h"
#include "ir/ir.h"
#include "ir/dbprint.h"
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
#include "frontends/common/parseInput.h"
#include "common/extract_maupipe.h"
#include "midend.h"
#include "midend/actionsInlining.h"
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

    BFN_Options options;

    if (options.process(ac, av) != nullptr)
        options.setInputFile();

    if (ErrorReporter::instance.getErrorCount() > 0)
        return 1;

    Device::init(options.device());

    if (!options.targetSupported()) {
         error("target '%s' not supported", options.target);
         return 1; }

    auto hook = options.getDebugHook();

    auto program = P4::parseP4File(options);

    program = P4::FrontEnd(hook).run(options, program, true);
    if (!program)
        return 1;
    log_dump(program, "Initial program");

    BFN::MidEnd midend(options);
    midend.addDebugHook(hook);
    program = program->apply(midend);
    if (!program)
        return 1;
    log_dump(program, "After midend");

    if (!options.p4RuntimeFile.isNullOrEmpty())
        BFN::serializeP4Runtime(program, options);

    if (ErrorReporter::instance.getErrorCount() > 0)
        return 1;

    auto maupipe = extract_maupipe(program, options);

    if (ErrorReporter::instance.getErrorCount() > 0)
        return 1;
    if (!maupipe)
        return 1;

    if (Log::verbose())
    std::cout << "Compiling" << std::endl;

    BFN::Backend backend(options);
    maupipe = maupipe->apply(backend);

    if (Log::verbose())
        std::cout << "Done." << std::endl;
    return ErrorReporter::instance.getErrorCount() > 0;
}
