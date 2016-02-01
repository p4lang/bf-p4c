#include <stdio.h>
#include <boost/program_options.hpp>
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
parse_input(const Tofino_Options &options, cstring filename, FILE* stream, bool closeFile) {
    const IR::Global* program = nullptr;
    switch (options.langVersion) {
    case CompilerOptions::FrontendVersion::P4v1:
        program = parse_p4v1_file(filename, stream);
        if (closeFile) {
            int exitCode = pclose(stream);
            if (exitCode != 0) {
                ::error("Preprocessor returned exit code %d; aborting compilation", exitCode);
                return nullptr;
            }
        }
        break;
    case CompilerOptions::FrontendVersion::P4v1_2: {
        const IR::P4V12Program* v12 = parse_p4v1_2_file(filename, stream);
        if (closeFile) {
            int exitCode = pclose(stream);
            if (exitCode != 0) {
                ::error("Preprocessor returned exit code %d; aborting compilation", exitCode);
                return nullptr;
            }
        }
        v12 = run_v12_frontend(options, v12);
        exit(v12 == nullptr);  // TODO: remove this
        break; }
    default:
        throw Util::CompilerBug("Unexpected frontend"); }
    return program;
}


int main(int ac, char **av) {
    const IR::Global *program = nullptr;

    Tofino_Options options;
    int optind = options.parse(ac, av);
    if (optind < ac - 1) {
        ::error("Only only input file must be specified");
        options.usage();
        return 1;
    } else if (optind >= ac) {
        ::error("No input files specified");
        options.usage();
        return 1;
    } else {
        options.setInputFile(av[optind]);
    }

    setup_gc_logging();

    FILE* in = nullptr;
    cstring file = options.file;
    bool close_pipe = false;

    if (file == "-") {
        file = "<stdin>";
        in = stdin;
    } else {
#ifdef __clang__
        /* FIXME -- while clang has a 'cpp' executable, its broken and doesn't work right, so
         * we need to run clang -E instead.  This should be managed by autoconf (figure out how
         * to portably run the c preprocessor) */
        std::string cmd("cc -E -x c");
#else
        std::string cmd("cpp");
#endif
        cmd += " -undef -nostdinc -D__TARGET_TOFINO__ " + options.preprocessor_options + " " + file;
        if (verbose)
            std::cout << "Invoking preprocessor " << std::endl << cmd << std::endl;
        in = popen(cmd.c_str(), "r");
        if (in == nullptr) {
            perror("Error invoking preprocessor");
            return 1;
        }
        close_pipe = true;
    }

    if (options.doNotCompile) {
        char *line = NULL;
        size_t len = 0;
        ssize_t read;

        while ((read = getline(&line, &len, in)) != -1)
            printf("%s", line);

        int exitCode = 0;
        if (close_pipe)
            exitCode = pclose(in);
        return exitCode != 0;
    }

    if (in != nullptr)
        program = parse_input(options, file, in, close_pipe);
    else
        std::cerr << "No input file" << std::endl;

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
    if (verbose)
        std::cout << "Done." << std::endl;

    return ErrorReporter::instance.getErrorCount() > 0;
}
