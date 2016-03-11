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
#include "frontends/p4v1/p4-parse.h"
#include "frontends/p4v1.2/p4v1.2-parse.h"
#include "frontends/p4v1.2/v12_frontend.h"
#include "frontends/common/constantFolding.h"
#include "frontends/common/header_type.h"
#include "frontends/common/parseInput.h"
#include "frontends/common/typecheck.h"
#include "common/extract_maupipe.h"
#include "common/blockmap.h"
#include "tofinoOptions.h"

extern void test_tofino_backend(const IR::Tofino::Pipe *, const Tofino_Options *);

int main(int ac, char **av) {
    setup_gc_logging();
    setup_signals();

    Tofino_Options options;
    if (options.process(ac, av) != nullptr)
        options.setInputFile();
    if (ErrorReporter::instance.getErrorCount() > 0)
        return 1;

    FILE* in = options.preprocess();
    if (!in) return 1;

    if (options.target != "tofino") {
        error("only supported target is 'tofino'");
        return 1; }
    const IR::Tofino::Pipe *maupipe = nullptr;

    bool v1 = options.langVersion == CompilerOptions::FrontendVersion::P4v1;
#if 0
    auto program = parseP4File(options);
#else
    switch (options.langVersion) {
    case CompilerOptions::FrontendVersion::P4v1: {
        auto program = parse_p4v1_file(options.file, in);
        options.closeInput(in);
        PassManager fe = {
            new P4V12::ConstantFolding(nullptr, nullptr),
            new CheckHeaderTypes,
            new HeaderTypeMaxLengthCalculator,
            new TypeCheck,
        };
        program = program->apply(fe);
        if (verbose) {
            std::cout << "-------------------------------------------------" << std::endl
                      << "Initial program" << std::endl
                      << "-------------------------------------------------" << std::endl;
            if (verbose > 1)
                dump(program);
            else
                std::cout << *program << std::endl; }
        maupipe = extract_maupipe(program);
        break; }
    case CompilerOptions::FrontendVersion::P4v1_2: {
        auto program = parse_p4v1_2_file(options.file, in);
#endif
        program = run_v12_frontend(options, program, v1);
        if (verbose) {
            std::cout << "-------------------------------------------------" << std::endl
                      << "Initial program" << std::endl
                      << "-------------------------------------------------" << std::endl;
            if (verbose > 1)
                dump(program);
            else
                std::cout << *program << std::endl; }
        P4V12::EvaluatorPass evaluator(v1);
        PassManager midend = {
            &evaluator,
            new FillFromBlockMap(&evaluator),
        };
        program = program->apply(midend);
        if (verbose) {
            std::cout << "-------------------------------------------------" << std::endl
                      << "After midend" << std::endl
                      << "-------------------------------------------------" << std::endl;
            if (verbose > 1)
                dump(program);
            else
                std::cout << *program << std::endl; }
        maupipe = extract_maupipe(program);
#if 1
        break; }
    default:
        BUG("Unexpected frontend"); }
#endif

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
