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

#if !defined(BAREFOOT_INTERNAL) || defined(NDEBUG)
// Catch all exceptions in production or release environment
#define BFP4C_CATCH_EXCEPTIONS 1
#endif

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

    /// Output a skeleton context.json in case compilation fails.
    /// It is required by all our tools. If the assembler can get far enough, it will overwrite it.
    void outputContext() {
        cstring ctxtFileName = _outputDir + "/context.json";
        std::ofstream ctxtFile(ctxtFileName);
        rapidjson::StringBuffer sb;
        rapidjson::PrettyWriter<rapidjson::StringBuffer> writer(sb);
        writer.StartObject();
        const time_t now = time(NULL);
        char build_date[1024];
        strftime(build_date, 1024, "%c", localtime(&now));
        writer.Key("build_date"); writer.String(build_date);
        writer.Key("program_name");
        writer.String(std::string(_options.programName + ".p4").c_str());
        writer.Key("run_id"); writer.String(RunId::getId().c_str());
        writer.Key("schema_version"); writer.String(CONTEXT_SCHEMA_VERSION);
        writer.Key("compiler_version"); writer.String(BF_P4C_VERSION);
        writer.Key("target"); writer.String(std::string(_options.target).c_str());
        writer.Key("tables"); writer.StartArray(); writer.EndArray();
        writer.Key("phv_allocation"); writer.StartArray(); writer.EndArray();
        writer.Key("parser");
        writer.StartObject();
        writer.Key("ingress"); writer.StartArray(); writer.EndArray();
        writer.Key("egress"); writer.StartArray(); writer.EndArray();
        writer.EndObject();
        writer.Key("learn_quanta"); writer.StartArray(); writer.EndArray();
        writer.Key("dynamic_hash_calculations"); writer.StartArray(); writer.EndArray();
        writer.Key("configuration_cache"); writer.StartArray(); writer.EndArray();
        writer.Key("driver_options");
        writer.StartObject();
        writer.Key("hash_parity_enabled"); writer.Bool(false);
        writer.EndObject();
        writer.EndObject();  // end of context
        ctxtFile << sb.GetString();
        ctxtFile.flush();
        ctxtFile.close();
        auto contextDir = BFNContext::get().getOutputDirectory("", _pipeId)
            .substr(_options.outputDir.size()+1);
        Logging::Manifest::getManifest().addContext(_pipeId, contextDir + "context.json");
    }

    void end_apply() override {
        cstring outputFile = _outputDir + "/" + _options.programName + ".bfa";
        std::ofstream ctxt_stream(outputFile, std::ios_base::app);

        Logging::Manifest &manifest = Logging::Manifest::getManifest();
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
            // relative path to the output directory
            manifest.addResources(_pipeId, resourcesFile.substr(_options.outputDir.size()+1));
        }
        if (!_success) {
            // \TODO: how much info do we need from context.json in
            // the case of a failed compilation?
            outputContext();
            // and output the manifest if it failed, since we're not going to have the chance
            // again. However, for successful compilation, GenerateOutputs gets called for every
            // pipe, and thus we don't want to output the manifest here.
            manifest.setSuccess(_success);
            manifest.serialize();
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
        addPasses({ &_dynhash,  // Verifies that the hash is valid before the dump of
                                // information in assembly
                    new BFN::AsmOutput(b.get_phv(), b.get_clot(), b.get_defuse(),
                                       b.get_flexible_packing(), b.get_nxt_tbl(),
                                       o, success),
                    o.debugInfo ? new PhvLogging(phvLogFile.c_str(), b.get_phv(), b.get_clot(),
                                                 *b.get_phv_logging(), b.get_defuse(),
                                                 b.get_table_alloc()) : nullptr,
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

    auto pipeName = maupipe->name;
    BFN::Backend backend(options, maupipe->id);
#if BFP4C_CATCH_EXCEPTIONS
    try {
#endif  // BFP4C_CATCH_EXCEPTIONS
        maupipe = maupipe->apply(backend);
        bool success = maupipe != nullptr;
        GenerateOutputs as(backend, options, maupipe->id, backend.get_prim_json(), success);
        if (maupipe)
            maupipe->apply(as);
#if BFP4C_CATCH_EXCEPTIONS
    } catch (...) {
        GenerateOutputs as(backend, options, maupipe->id, backend.get_prim_json(), false);
        if (maupipe)
            maupipe->apply(as);

        if (Log::verbose())
            std::cerr << "Failed." << std::endl;
        throw;
    }
#endif  // BFP4C_CATCH_EXCEPTIONS
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
#if BFP4C_CATCH_EXCEPTIONS
    // Internal compiler error
    constexpr unsigned INTERNAL_COMPILER_ERROR = 4;
#endif  // BFP4C_CATCH_EXCEPTIONS

    AutoCompileContext autoBFNContext(new BFNContext);
    auto& options = BackendOptions();

    if (!options.process(ac, av) || ::errorCount() > 0)
        return INVOCATION_ERROR;

    options.setInputFile();
    Logging::FileLog::setOutputDir(options.outputDir);
    Device::init(options.target);

#if BFP4C_CATCH_EXCEPTIONS
    try {
#endif  // BFP4C_CATCH_EXCEPTIONS
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

#if !BAREFOOT_INTERNAL
    // turn all errors into "fatal errors" by exiting on the first error encountered
    BFNContext::get().errorReporter().setMaxErrorCount(1);
#endif

    // create the archive manifest
    Logging::Manifest &manifest = Logging::Manifest::getManifest();

    /// setup the context to know which pipes are available in the program: for logging and
    /// other output declarations.
    BFNContext::get().discoverPipes(program, midend.toplevel);

    // convert midend IR to backend IR
    BFN::BackendConverter conv(&midend.refMap, &midend.typeMap, midend.toplevel);
    conv.convertTnaProgram(program, options);
    if (::errorCount() > 0)
        return PROGRAM_ERROR;

    // setup the pipes and the architecture config early, so that the manifest is
    // correct even if there are errors in the backend.
    for (auto& pipe : conv.pipe)
        manifest.setPipe(pipe->id, pipe->name.name);
    manifest.addArchitecture(conv.getThreads());

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
    }

    // and output the manifest. This gets called for successful compilation.
    manifest.setSuccess(::errorCount() == 0);
    manifest.serialize();

    if (Log::verbose())
        std::cout << "Done." << std::endl;
    return ::errorCount() > 0 ? COMPILER_ERROR : SUCCESS;

#if BFP4C_CATCH_EXCEPTIONS
    // catch all exceptions here
    } catch (const Util::CompilerBug &e) {
        std::cerr << e.what() << std::endl;
        return COMPILER_ERROR;
    } catch (const Util::CompilerUnimplemented &e) {
        std::cerr << e.what() << std::endl;
        return COMPILER_ERROR;
    } catch (const Util::CompilationError &e) {
        std::cerr << e.what() << std::endl;
        return PROGRAM_ERROR;
    } catch (...) {
        std::cerr << "Internal compiler error. Please submit a bug report with your code."
                  << std::endl;
        return INTERNAL_COMPILER_ERROR;
    }
#endif  // BFP4C_CATCH_EXCEPTIONS
}
