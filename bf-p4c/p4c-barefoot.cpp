#include <libgen.h>
#include <limits.h>
#include <signal.h>
#include <stdio.h>
#include <sys/stat.h>
#include <iostream>
#include <string>

#include "asm.h"
#include "backend.h"
#include "backends/graphs/controls.h"
#include "bf-p4c-options.h"
#include "bf-p4c/common/parse_annotations.h"
#include "bf-p4c/control-plane/tofino_p4runtime.h"
#include "bf-p4c/lib/error_type.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/logging/phv_logging.h"
#include "bf-p4c/logging/resources.h"
#include "bf-p4c/mau/dynhash.h"
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
#include "arch/fromv1.0/programStructure.h"
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/compile_context.h"
#include "lib/crash.h"
#include "lib/exceptions.h"
#include "lib/gc.h"
#include "lib/log.h"
#include "lib/nullstream.h"
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
class GenerateOutputs : public PassManager {
 private:
    const BFN_Options &_options;
    int  _pipeId;
    bool _success;
    std::string _outputDir;

    BFN::Visualization _visualization;
    BFN::DynamicHashJson _dynhash;
    const Util::JsonObject &_primitives;

    void end_apply() override {
        cstring outputFile = _outputDir + "/" + _options.programName + ".bfa";
        std::ofstream ctxt_stream(outputFile, std::ios_base::app);

        if (_success) {
            // Always output primitives json file (info used by model for logging actions)
            cstring primitivesFile = _outputDir + "/" + _options.programName + ".prim.json";
            LOG2("ASM generation for primitives: " << primitivesFile);
            ctxt_stream << "primitives: \"" << primitivesFile << "\"" << std::endl << std::flush;
            std::ofstream prim(primitivesFile);
            _primitives.serialize(prim);
            prim << std::endl << std::flush;

            // Output dynamic hash json file
            cstring dynHashFile = _outputDir + "/" + _options.programName + ".dynhash.json";
            LOG2("ASM generation for dynamic hash: " << dynHashFile);
            ctxt_stream << "dynhash: \"" << dynHashFile << "\"" << std::endl << std::flush;
            std::ofstream dynhash(dynHashFile);
            dynhash << _dynhash << std::endl << std::flush;
        }
        if (_options.debugInfo) {  // generate resources info only if invoked with -g
            // Output resources json file
            auto logsDir = BFNContext::get().getOutputDirectory("logs", _pipeId);
            cstring resourcesFile = logsDir + "/resources.json";
            LOG2("ASM generation for resources: " << resourcesFile);
            std::ofstream res(resourcesFile);
            res << _visualization << std::endl << std::flush;
            Logging::Manifest &manifest = Logging::Manifest::getManifest();
            // relative path to the output directory
            manifest.addResources(_pipeId, resourcesFile.substr(_options.outputDir.size()+1));

            // \TODO: how much info do we need from context.json in
            // the case of a failed compilation?
        }
    }

 public:
    explicit GenerateOutputs(const BFN::Backend &b, const BFN_Options& o,
                             int pipeId, const Util::JsonObject& p,
                             bool success = true) :
        _options(o), _pipeId(pipeId), _success(success),
        _visualization(b.get_clot()), _dynhash(b.get_phv()), _primitives(p) {
        setStopOnError(false);
        _outputDir = BFNContext::get().getOutputDirectory("", pipeId);
        if (_outputDir == "") exit(1);
        auto logsDir = BFNContext::get().getOutputDirectory("logs", pipeId);
        std::string phvLogFile(logsDir + "/phv.json");
        addPasses({ new BFN::AsmOutput(b.get_phv(), b.get_clot(), b.get_defuse(), o, success),
                    new PhvLogging(phvLogFile.c_str(), b.get_phv(), *b.get_phv_logging(),
                                   b.get_defuse(), b.get_table_alloc()),
                    &_visualization,
                    &_dynhash
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

    auto pipeName = maupipe->name;
    BFN::Backend backend(options, maupipe->id);
    try {
        maupipe = maupipe->apply(backend);
        bool success = maupipe != nullptr;
        GenerateOutputs as(backend, options, maupipe->id, backend.get_prim_json(), success);
        if (maupipe)
            maupipe->apply(as);
    } catch (Util::P4CExceptionBase &ex) {
        // produce resource nodes in context.json regardless of failures
        #if BAREFOOT_INTERNAL
            std::cerr << "compilation failed: producing context.json" << std::endl;
        #endif

        GenerateOutputs as(backend, options, maupipe->id, backend.get_prim_json(), false);
        if (maupipe)
            maupipe->apply(as);

        if (Log::verbose())
            std::cerr << "Failed." << std::endl;
        throw;
    }
}

int main(int ac, char **av) {
    setup_gc_logging();
    setup_signals();
    // initialize the Barefoot specific error types
    BFN::ErrorType::getErrorTypes();

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
#if !BAREFOOT_INTERNAL
    // Internal compiler error
    constexpr unsigned INTERNAL_COMPILER_ERROR = 4;
#endif

    AutoCompileContext autoBFNContext(new BFNContext);
    auto& options = BackendOptions();

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

    program = P4::FrontEnd(BFN::ParseAnnotations(), hook).run(options, program, true);

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
    midend.addDebugHook(hook, true);
    // so far, everything is still under the same program for 32q, generate two separate threads
    program = program->apply(midend);
    if (!program)
        return PROGRAM_ERROR;  // still did not reach the backend for fitting issues
    log_dump(program, "After midend");

    if (!midend.toplevel)
        return PROGRAM_ERROR;

    // turn all errors into "fatal errors" by exiting on the first error encountered
    BFNContext::get().errorReporter().setMaxErrorCount(1);

    // create the archive manifest
    Logging::Manifest &manifest = Logging::Manifest::getManifest();

    /// setup the context to know which pipes are available in the program: for logging and
    /// other output declarations.
    BFNContext::get().discoverPipes(program, midend.toplevel);

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
        manifest.setPipe(pipe->id, pipe->name.name);
        // generate graphs
        // In principle this should not fail, so we call it before the backend
        if (options.create_graphs) {
            auto graphsDir = BFNContext::get().getOutputDirectory("graphs", pipe->id);
            // set the pipe for the visitors to compute the output dir
            manifest.setRefAndTypeMap(&midend.refMap, &midend.typeMap);
            auto toplevel = midend.toplevel;
            if (toplevel != nullptr) {
                LOG2("Generating control graphs");
                // FIXME(cc): this should move to the manifest graph generation to work per-pipe
                graphs::ControlGraphs cgen(&midend.refMap, &midend.typeMap, graphsDir);
                toplevel->getMain()->apply(cgen);
                toplevel->getMain()->apply(manifest);  // generate entries for controls in manifest
            }
            LOG2("Generating parser graphs");
            program->apply(manifest);  // generate graph entries for parsers in manifest
        }

#if BAREFOOT_INTERNAL
        if (!options.skipped_pipes.count(pipe->name))
            execute_backend(pipe, options);
#else
            execute_backend(pipe, options);
#endif
        auto contextDir = BFNContext::get().getOutputDirectory("", pipe->id)
            .substr(options.outputDir.size()+1);
        manifest.addContext(pipe->id, contextDir + "context.json");
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
        return INTERNAL_COMPILER_ERROR;
    }
#endif  // !BAREFOOT_INTERNAL
}
