#include <libgen.h>
#include <limits.h>
#include <signal.h>
#include <stdio.h>
#include <sys/stat.h>
#include <iostream>
#include <string>

#include "asm.h"
#include "backend.h"
#include "bf-p4c-options.h"
#include "bf-p4c/control-plane/tofino_p4runtime.h"
#include "bf-p4c/visualization.h"
#include "bf-p4c/logging/filelog.h"
#include "common/extract_maupipe.h"
#include "common/run_id.h"
#include "device.h"
#include "frontends/p4/frontend.h"
#include "frontends/p4/createBuiltins.h"
#include "frontends/p4/validateParsedProgram.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4-14/header_type.h"
#include "frontends/p4-14/typecheck.h"
#include "frontends/common/applyOptionsPragmas.h"
#include "frontends/common/parseInput.h"
#include "fromv1.0/programStructure.h"
#include "backends/graphs/controls.h"
#include "backends/graphs/parsers.h"
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/compile_context.h"
#include "lib/crash.h"
#include "lib/gc.h"
#include "lib/log.h"
#include "lib/exceptions.h"
#include "logging/manifest.h"
#include "midend.h"
#include "version.h"

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

// This structure is sensitive to whether the pass is called for a successful
// compilation or a failed compilation. A successful compilation will output the .bfa
// file and a json file for resources. It is unlikely that the ASM output will generate
// an exception, but if it does, it should be caught by main (in p4c-barefoot.cpp).  If
// it is called with a failed pass, we should still apply the BFN::Visualization pass
// to collect the table resource usages, but we only output the resources file.
//
class OutputAsm : public PassManager {
 private:
    const BFN_Options &_options;
    bool _success;
    cstring pipeName;

    BFN::Visualization _visualization;
    const Util::JsonObject &_primitives;

    void end_apply() override {
        // Set output dir
        std::string outputDir(_options.outputDir.c_str());
        if (_options.langVersion == BFN_Options::FrontendVersion::P4_16) {
            outputDir = outputDir + "/" + pipeName;
        }
        int rc = mkdir(outputDir.c_str(), 0755);
        if (rc != 0 && errno != EEXIST) {
            std::cerr << "Failed to create directory: " << outputDir << std::endl;
            return;
        }
        LOG2("Generating outputs under " << outputDir);
        std::string dir(outputDir);
        cstring outputFile = dir + "/" + _options.programName + ".bfa";
        std::ofstream ctxt_stream(outputFile, std::ios_base::app);

        if (_success) {
            // Always output primitives json file (info used by model for
            // logging actions)
            cstring primitivesFile = dir + "/" + _options.programName + ".prim.json";
            LOG2("ASM generation for primitives: " << primitivesFile);
            ctxt_stream << "primitives: \"" <<
                primitivesFile << "\"" << std::endl << std::flush;
            std::ofstream prim(primitivesFile);
            _primitives.serialize(prim);
            prim << std::endl << std::flush;
        }
        if (_options.debugInfo) {  // generate resources info only if invoked with -g
            // Output resources json file
            cstring resourcesFile = dir + "/" + _options.programName + ".res.json";
            LOG2("ASM generation for resources: " << resourcesFile);
            std::ofstream res(resourcesFile);
            res << _visualization << std::endl << std::flush;

            // \TODO: how much info do we need from context.json in
            // the case of a failed compilation?
        }
    }


 public:
    explicit OutputAsm(const BFN::Backend &b, const BFN_Options& o,
                        cstring pipeName, const Util::JsonObject& p,
                       bool success = true) :
        _options(o), _success(success), pipeName(pipeName), _primitives(p) {
        setStopOnError(false);
        addPasses({ new BFN::AsmOutput(b.get_phv(), b.get_clot(), b.get_defuse(), o,
                                       pipeName, success),
                    &_visualization
                    });
        setName("Assembly output");
    }
};

/// use pipe.n to generate output directory.
void execute_backend(const IR::BFN::Pipe* maupipe, BFN_Options& options) {
    if (::errorCount() > 0)
        return;
    if (!maupipe)
        return;

    if (Log::verbose())
        std::cout << "Compiling " << maupipe->name << std::endl;

    BFN::Backend backend(options, maupipe->id);
    try {
        maupipe = maupipe->apply(backend);
    } catch (Util::P4CExceptionBase &ex) {
        // produce resource nodes in context.json regardless of failures
        std::cerr << "compilation failed: producing ctxt.json" << std::endl;
        OutputAsm as(backend, options, maupipe->name, backend.get_prim_json(), false);
        maupipe->apply(as);

        if (Log::verbose())
            std::cerr << "Failed." << std::endl;
        throw;
    }

    // output the .bfa file
    if (maupipe) {
        OutputAsm as(backend, options, maupipe->name, backend.get_prim_json());
        maupipe->apply(as); }
}

int main(int ac, char **av) {
    setup_gc_logging();
    setup_signals();

    // define a set of constants to return so we can decide what to do for
    // context,json generation, as we need to generate as much as we can
    // for failed programs
    constexpr unsigned SUCCESS = 0;
    // Backend error. This can be fitting or other issues in the backend, where we may have
    // hope to generate partial context and visualizations.
    constexpr unsigned COMPILER_ERROR = 1;
    // Program or programmer errors. Nothing to do until the program is fixed
    constexpr unsigned INVOCATION_ERROR = 2;
    constexpr unsigned PROGRAM_ERROR = 3;


    AutoCompileContext autoBFNContext(new BFNContext);
    auto& options = BFNContext::get().options();

    if (!options.process(ac, av) || ::errorCount() > 0)
        return INVOCATION_ERROR;

    options.setInputFile();
    Logging::FileLog::setOutputDir(options.outputDir);
    Device::init(options.target);

#if !BAREFOOT_INTERNAL
    // Catch all exceptions in production environment
    try {
#endif  // !BAREFOOT_INTERNAL
    // FIXME -- should be based on the architecture option
    P4V1::Converter::createProgramStructure = P4V1::TNA_ProgramStructure::create;

    auto hook = options.getDebugHook();

    auto program = P4::parseP4File(options);
    if (!program || ::errorCount() > 0)
        return PROGRAM_ERROR;

    BFNOptionPragmaParser optionsPragmaParser;
    program->apply(P4::ApplyOptionsPragmas(optionsPragmaParser));

    program = P4::FrontEnd(hook).run(options, program, true);

    // If there was an error in the frontend, we are likely to end up
    // with an invalid program for serialization, so we bail out here.
    if (!program || ::errorCount() > 0)
        return PROGRAM_ERROR;

    // If we just want to prettyprint to p4_16, running the frontend is sufficient.
    if (!options.prettyPrintFile.isNullOrEmpty())
        return ::errorCount() > 0 ? PROGRAM_ERROR : SUCCESS;

    log_dump(program, "Initial program");

    BFN::generateP4Runtime(program, options);
    if (::errorCount() > 0)
        return PROGRAM_ERROR;

    BFN::MidEnd midend(options);
    midend.addDebugHook(hook);
    // so far, everything is still under the same program for 32q, generate two separate threads
    program = program->apply(midend);
    if (!program)
        return PROGRAM_ERROR;  // still did not reach the backend for fitting issues
    log_dump(program, "After midend");

    // create the archive manifest
    Logging::Manifest &manifest = Logging::Manifest::getManifest();

    // generate graphs
    // In principle this should not fail, so we call it before the backend
    if (options.create_graphs) {
        std::string graphsDir(options.outputDir.c_str());
        graphsDir += "/graphs";
        int rc = mkdir(graphsDir.c_str(), 0755);
        if (rc != 0 && errno != EEXIST) {
            std::cerr << "Failed to create directory: " << graphsDir << std::endl;
            return INVOCATION_ERROR;
        }
        LOG2("Generating graphs under " << graphsDir);
        auto toplevel = midend.toplevel;
        if (toplevel != nullptr) {
            LOG2("Generating control graphs");
            graphs::ControlGraphs cgen(&midend.refMap, &midend.typeMap, graphsDir);
            toplevel->getMain()->apply(cgen);
            toplevel->getMain()->apply(manifest);  // generate entries for controls in manifest
        }
        LOG2("Generating parser graphs");
        graphs::ParserGraphs pgg(&midend.refMap, &midend.typeMap, graphsDir);
        program->apply(pgg);
        program->apply(manifest);  // generate graph entries for parsers in manifest
    }

    if (!midend.toplevel)
        return PROGRAM_ERROR;

    // convert midend IR to backend IR
    BFN::BackendConverter conv(&midend.refMap, &midend.typeMap, midend.toplevel);
    conv.convert(program, options);
    if (::errorCount() > 0)
        return PROGRAM_ERROR;

    if (options.dumpJsonFile) {
        // We just want to produce an IR for mutine (p4v & friends), so running
        // the midend is sufficient. Dump the IR to stdout and exit.
        auto &fileStr = options.dumpJsonFile != "-" ?
            *openFile(options.dumpJsonFile, false) : std::cout;
        LOG3("Output to " << options.dumpJsonFile);
        for (auto& pipe : conv.pipe)
            JSONGenerator(fileStr, true) << pipe << std::endl;
        return ::errorCount() > 0 ? PROGRAM_ERROR : SUCCESS;
    }

    for (auto& pipe : conv.pipe) {
#if BAREFOOT_INTERNAL
        if (!options.skipped_pipes.count(pipe->name))
            execute_backend(pipe, options);
#else
            execute_backend(pipe, options);
#endif
        std::string prefix = "";
        if (options.langVersion == BFN_Options::FrontendVersion::P4_16)
            prefix = pipe->name + "/";
        manifest.addContext(pipe->id, pipe->name, prefix + "context.json");
        if (options.debugInfo)
            manifest.addResources(pipe->id, prefix + options.programName + ".res.json");
    }

    manifest.addArchitecture(conv.getThreads());
    manifest.setSuccess(::errorCount() == 0);

    // generate the archive manifest
    manifest.serialize();

    if (Log::verbose())
        std::cout << "Done." << std::endl;
    return ::errorCount() > 0 ? COMPILER_ERROR : SUCCESS;

#if !BAREFOOT_INTERNAL
    // catch all exceptions here
    } catch (Util::CompilerBug e) {
        std::cerr << e.what() << std::endl;
        return COMPILER_ERROR;
    } catch (Util::CompilerUnimplemented e) {
        std::cerr << e.what() << std::endl;
        return COMPILER_ERROR;
    } catch (Util::CompilationError e) {
        std::cerr << e.what() << std::endl;
        return PROGRAM_ERROR;
    } catch (...) {
        std::cerr << "Internal compiler error. Please submit a bug report with your code."
                  << std::endl;
        return COMPILER_ERROR;
    }
#endif  // !BAREFOOT_INTERNAL
}
