#include <stdio.h>
#include <signal.h>
#include <string>
#include <iostream>

#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/crash.h"
#include "lib/gc.h"
#include "lib/log.h"
#include "lib/exceptions.h"
#include "frontends/p4-14/p4-14-parse.h"
#include "frontends/p4/p4-parse.h"
#include "frontends/p4/frontend.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4-14/header_type.h"
#include "frontends/p4-14/typecheck.h"
#include "frontends/common/parseInput.h"
#include "common/extract_maupipe.h"
#include "midend.h"
#include "midend/actionsInlining.h"
#include "tofinoOptions.h"

extern void test_tofino_backend(const IR::Tofino::Pipe *, const Tofino_Options *);

int main(int ac, char **av) {
    setup_gc_logging();
    setup_signals();

    Tofino_Options options;
    if (options.process(ac, av) != nullptr)
        options.setInputFile();
    auto hook = options.getDebugHook();
    if (ErrorReporter::instance.getErrorCount() > 0)
        return 1;
    options.preprocessor_options += " -D__TARGET_TOFINO__";

    FILE* in = options.preprocess();
    if (!in) return 1;

    if (options.target != "tofino") {
        error("only supported target is 'tofino'");
        return 1; }
    const IR::Tofino::Pipe *maupipe = nullptr;

    bool v1 = options.isv1();
    if (v1 && !options.v12_path) {
        auto program = parse_P4_14_file(options, in);
        options.closeInput(in);
        PassManager fe = {
            new P4::ConstantFolding(nullptr, nullptr),
            new CheckHeaderTypes,
            new HeaderTypeMaxLengthCalculator,
            new TypeCheck,
            new P4_14::InlineActions,
        };
        fe.setName("V1FrontEnd");
        fe.addDebugHook(hook);
        program = program->apply(fe);
        if (!program)
            return 1;
        if (verbose) {
            std::cout << "-------------------------------------------------" << std::endl
                      << "Initial program" << std::endl
                      << "-------------------------------------------------" << std::endl;
            if (verbose > 1)
                dump(program);
            else
                std::cout << *program << std::endl; }
        maupipe = extract_maupipe(program);
    } else {
        auto program = parseP4File(options);
        program = FrontEnd().run(options, program);
        if (!program)
            return 1;
        if (verbose) {
            std::cout << "-------------------------------------------------" << std::endl
                      << "Initial program" << std::endl
                      << "-------------------------------------------------" << std::endl;
            if (verbose > 1)
                dump(program);
            else
                std::cout << *program << std::endl; }
        Tofino::MidEnd midend(options);
        midend.addDebugHook(hook);
        program = program->apply(midend);
        if (!program)
            return 1;
        if (verbose) {
            std::cout << "-------------------------------------------------" << std::endl
                      << "After midend" << std::endl
                      << "-------------------------------------------------" << std::endl;
            if (verbose > 1)
                dump(program);
            else
                std::cout << *program << std::endl; }
        maupipe = extract_maupipe(program); }

    if (ErrorReporter::instance.getErrorCount() > 0)
        return 1;
    if (!maupipe)
        return 1;

    if (verbose)
        std::cout << "Compiling" << std::endl;

    test_tofino_backend(maupipe, &options);

    if (verbose)
        std::cout << "Done." << std::endl;
    return ErrorReporter::instance.getErrorCount() > 0;
}
