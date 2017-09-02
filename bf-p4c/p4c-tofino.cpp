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
#include "frontends/p4/createBuiltins.h"
#include "frontends/p4/validateParsedProgram.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4-14/header_type.h"
#include "frontends/p4-14/typecheck.h"
#include "frontends/common/parseInput.h"
#include "common/extract_maupipe.h"
#include "midend.h"
#include "midend/actionsInlining.h"
#include "tofinoOptions.h"
#include "version.h"
#include "tofino/control-plane/tofino_p4runtime.h"
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
    vector<cstring> supported_arch = { "tofino-v1model-barefoot", "tofino-native-barefoot" };
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

    auto it = std::find(supported_arch.begin(), supported_arch.end(), options.target);
    if (it == supported_arch.end()) {
        error("target '%s' not supported", options.target);
        return 1; }

    auto program = P4::parseP4File(options);

    program = P4::FrontEnd(hook).run(options, program, true);
    if (!program)
        return 1;
    log_dump(program, "Initial program");

    if (options.target == "tofino-v1model-barefoot" && options.native_arch) {
        Tofino::SimpleSwitchTranslation translation(options);
        translation.addDebugHook(hook);
        program = program->apply(translation);
        if (!program)
            return 1;
        log_dump(program, "After TNA translation");
    }

    Tofino::MidEnd midend(options);
    midend.addDebugHook(hook);
    program = program->apply(midend);
    if (!program)
        return 1;
    log_dump(program, "After midend");

    if (!options.p4RuntimeFile.isNullOrEmpty())
        Tofino::serializeP4Runtime(program, options);

    if (ErrorReporter::instance.getErrorCount() > 0)
        return 1;

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
