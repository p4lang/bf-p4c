/**
 * \defgroup bf_p4c Overview of bf-p4c
 * \brief Overview of passes performed by the bf-p4c binary.
 *
 * The compiler goes through this sequence of high-level passes:
 * 1. Frontend
 *   * Parses input P4 file
 *   * Creates IR
 *   * See bf-p4c/frontend.h, bf-p4c/frontend.cpp, and p4c/frontends/
 * 2. Generate P4 Runtime
 *   * Creates the Barefoot runtime JSON file
 *   * Currently also:
 *     * replaces typedefs (P4::EliminateTypedef) – this is also done in midend
 *     * rewrites action selectors to newer syntax (BFN::RewriteActionSelector)
 *   * See bf-p4c/control-plane/p4runtime.h, bf-p4c/control-plane/p4runtime.cpp,
 *     p4c/control-plane/p4RuntimeSerializer.h, and p4c/control-plane/p4RuntimeSerializer.cpp
 * 3. \ref midend
 * 4. \ref post_midend
 *   * Bridge Packing
 *     * Flexible header repack (bridged metadata egress->ingress)
 *   * Substitute Packed Headers
 *     * Transforms the IR towards backend IR (vector of pipes, no longer able to be type-checked)
 *     * Replaces flexible type definition with packed version
 *   * See bf-p4c/arch/bridge.h and bf-p4c/arch/bridge.cpp
 * 5. Source Info Logging
 *   * Creates a JSON file with source info for P4I
 *   * This is done via information that were collected in different parts of the compiler
 *     by CollectSourceInfoLogging
 *   * See bf-p4c/logging/source_info_logging.h and bf-p4c/logging/source_info_logging.cpp
 * 6. Generate graphs
 *   * Essentially a backend for generating graphs of programs
 *   * See p4c/backends/graphs/
 * 7. \ref backend
 */

/**
 * \defgroup post_midend Post-midend
 * \brief Overview of post-midend passes
 *
 * Post-midend passes follow midend; they adjust packing of bridged and fixed-size headers
 * and convert midend IR towards backend IR.
 */

// The following comments of the namespaces are here to make sure they are present in Doxygen.
/**
 * @namespace BFN
 * @brief The namespace encapsulating Barefoot/Intel-specific stuff
 */
/**
 * @namespace IR
 * @brief The namespace encapsulating %IR node classes
 */
/**
 * @namespace PHV
 * @brief The namespace encapsulating PHV-related stuff
 */
/**
 * @namespace Test
 * @brief The namespace encapsulating test-related stuff
 */

//  All C includes should come before the first C++ include, according to one of our Git hooks.
#include <libgen.h>
#include <sys/stat.h>
#include <unistd.h>

#include <climits>
#include <csignal>
#include <cstdio>
#include <iostream>
#include <string>

#include "asm.h"
#include "backend.h"
#include "backends/graphs/controls.h"
#include "backends/graphs/graph_visitor.h"
#include "bf-p4c/backend.h"
#include "bf-p4c/common/pragma/collect_global_pragma.h"
#include "bf-p4c/common/bridged_packing.h"
#include "bf-p4c/control-plane/runtime.h"
#include "bf-p4c/frontend.h"
#include "bf-p4c/lib/error_type.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/logging/phv_logging.h"
#include "bf-p4c/logging/source_info_logging.h"
#include "bf-p4c/logging/event_logger.h"
#include "bf-p4c/logging/resources.h"
#include "bf-p4c/mau/dynhash.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/mau/table_flow_graph.h"
#include "bf-p4c/parde/parser_header_sequences.h"
#include "common/extract_maupipe.h"
#include "common/run_id.h"
#include "device.h"
#include "frontends/p4/createBuiltins.h"
#include "frontends/p4/validateParsedProgram.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4-14/header_type.h"
#include "frontends/p4-14/typecheck.h"
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

    BFN::DynamicHashJson _dynhash;
    const Util::JsonObject &_primitives;
    const Util::JsonObject &_depgraph;

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
        writer.Key("mau_stage_characteristics"); writer.StartArray(); writer.EndArray();
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
            ctxt_stream << "primitives: \"" << _options.programName << ".prim.json\"" << std::endl;
            std::ofstream prim(primitivesFile);
            _primitives.serialize(prim);
            prim << std::endl << std::flush;

            // Output dynamic hash json file
            cstring dynHashFile = _outputDir + "/" + _options.programName + ".dynhash.json";
            LOG2("ASM generation for dynamic hash: " << dynHashFile);
            ctxt_stream << "dynhash: \"" << _options.programName << ".dynhash.json\"" << std::endl;
            std::ofstream dynhash(dynHashFile);
            dynhash << _dynhash << std::endl << std::flush;
        }
        if (_options.debugInfo) {  // Generate graphs only if invoked with -g
            auto graphsDir = BFNContext::get().getOutputDirectory("graphs", _pipeId);
            // Output dependency graph json file
            if (_depgraph.size() > 0) {
                cstring depFileName = "dep";
                cstring depFile = graphsDir + "/" + depFileName + ".json";
                LOG2("Dependency graph json generation for P4i: " << depFile);
                std::ofstream dep(depFile);
                _depgraph.serialize(dep);
                // relative path to the output directory
                // TBD: In manifest, add an option to indicate a program graph
                // which includes both ingress and egress. Currently the graph node
                // in manifest only accepts one gress since the dot graphs are
                // generated per gress. To satisfy schema we use INGRESS, this does
                // not have any affect on p4i interpretation.
                manifest.addGraph(_pipeId, "table", depFileName, INGRESS, ".json");
            }
        }

        // We produce the skeleton of context.json regardless the compilation succeeds or fails.
        // It is needed by visualization tool which can visualize some results even from failed
        // compilation.
        // If the compilation succeeds, then either assembler rewrites the skeleton
        // of context.json with real data or if assembler fails or crashes, skeleton
        // of context.json produced here is preserved and can be used by visualization tools.
        outputContext();

        if (!_success) {
            // Output the manifest if it failed, since we're not going to have the chance
            // again. However, for successful compilation, GenerateOutputs gets called for every
            // pipe, and thus we don't want to output the manifest here.
            manifest.setSuccess(_success);
            manifest.serialize();
        }
    }

 public:
    explicit GenerateOutputs(const BFN::Backend &b, const BFN_Options& o, int pipeId,
                             const Util::JsonObject& p, const Util::JsonObject& d,
                             bool success = true) :
        _options(o), _pipeId(pipeId), _success(success),
        _dynhash(b.get_phv()), _primitives(p), _depgraph(d) {
        setStopOnError(false);
        _outputDir = BFNContext::get().getOutputDirectory("", pipeId);
        if (_outputDir == "") exit(1);
        auto logsDir = BFNContext::get().getOutputDirectory("logs", pipeId);
        std::string phvLogFile(logsDir + "/phv.json");
        std::string resourcesLogFile(logsDir + "/resources.json");
        addPasses({ &_dynhash,  // Verifies that the hash is valid before the dump of
                                // information in assembly
                    new BFN::AsmOutput(b.get_phv(), b.get_clot(), b.get_defuse(),
                                       b.get_flexible_logging(), b.get_nxt_tbl(),
                                       b.get_power_and_mpr(),
                                       b.get_tbl_summary(), b.get_live_range_report(),
                                       b.get_parser_hdr_seqs(), o, success),
                    o.debugInfo ? new PhvLogging(phvLogFile.c_str(), b.get_phv(), b.get_clot(),
                                                 *b.get_phv_logging(), b.get_defuse(),
                                                 b.get_table_alloc(), b.get_tbl_summary())
                                                 : nullptr,
                    o.debugInfo ? new BFN::ResourcesLogging(b.get_clot(), resourcesLogFile,
                                                o.outputDir.c_str()) : nullptr
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
    backend.addDebugHook(EventLogger::getDebugHook(), true);
#if BFP4C_CATCH_EXCEPTIONS
    struct failure_guard : boost::noncopyable {
        failure_guard(BFN::Backend& backend, const IR::BFN::Pipe* maupipe)
            : backend(backend), maupipe(maupipe)
        {}
        ~failure_guard() {
            if (std::uncaught_exception()) {
                GenerateOutputs as(backend, backend.get_options(), maupipe->id,
                    backend.get_prim_json(), backend.get_json_graph(), false);
                if (maupipe)
                    maupipe->apply(as);

                if (Log::verbose())
                    std::cerr << "Failed." << std::endl;
            }
        }
        BFN::Backend& backend;
        const IR::BFN::Pipe* maupipe;
    };
    failure_guard guard(backend, maupipe);
#endif  // BFP4C_CATCH_EXCEPTIONS
    maupipe = maupipe->apply(backend);
    bool mau_success = maupipe != nullptr;
    bool comp_success = (::errorCount() > 0) ? false : true;
    GenerateOutputs as(backend, backend.get_options(), maupipe->id,
            backend.get_prim_json(), backend.get_json_graph(),
            mau_success && comp_success);
    if (maupipe)
        maupipe->apply(as);
}



static void reportStats_alwaysCallThisONCEshortlyBeforeExiting() {
    // Han indicated ≤1 ‘_’ per identifier is a required rule.
    auto& myErrorReporter { BFNContext::get().errorReporter() };
    //  The next 2 lines: creating variables just for readability of code.
    const unsigned long long   error_count = myErrorReporter.getErrorCount();
    const unsigned long long warning_count = myErrorReporter.getWarningCount();

    using namespace std;

    if ( get_has_output_already_been_silenced() ) {  //  we need to re-enable cerr
  //  no good ctors for this acc. to <https://m.cplusplus.com/reference/fstream/filebuf/open/> :-(
        static filebuf devStdErr;

        devStdErr.open("/dev/stderr", ios::out | ios::app);
        cerr.rdbuf(&devStdErr);

        // should we call “reset_has_output_already_been_silenced()” here?
    }

    cerr << endl;
    cerr << "Number of P4 compiler-proper ERRORs: "   <<   error_count << endl;
    cerr << "Number of P4 compiler-proper WARNINGs: " << warning_count << endl;
    cerr << endl;
}  //  end of reporting procedure



int return_from_main_politely(const int foo) {
    reportStats_alwaysCallThisONCEshortlyBeforeExiting();
    return foo;
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
    // PerPipeResourceAllocation error. This can be fitting or other issues in
    // the backend, where we may have hope to generate partial context and
    // visualizations.
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
        return return_from_main_politely(INVOCATION_ERROR);

    options.setInputFile();
    Device::init(options.target);

    // Initialize EventLogger
    if (BackendOptions().debugInfo) {
        // At least skeleton of events.json should be emitted alongside with other JSON files
        // so P4I knows what is the setup of the system.
        // Only enable actual events per user demand
        EventLogger::get().init(BFNContext::get().getOutputDirectory().c_str(), "events.json");
        if (BackendOptions().enable_event_logger) EventLogger::get().enable();
    }


#if BFP4C_CATCH_EXCEPTIONS
    try {
#endif  // BFP4C_CATCH_EXCEPTIONS
    auto* program = run_frontend();

    if (options.num_stages_override) {
        Device::overrideNumStages(options.num_stages_override);
        if (::errorCount() > 0) {
            return return_from_main_politely(INVOCATION_ERROR);
        }
    }

    // If there was an error in the frontend, we are likely to end up
    // with an invalid program for serialization, so we bail out here.
    if (!program || ::errorCount() > 0)
        return return_from_main_politely(PROGRAM_ERROR);

    // If we just want to prettyprint to p4_16, running the frontend is sufficient.
    if (!options.prettyPrintFile.isNullOrEmpty())
        return return_from_main_politely(::errorCount() > 0 ? PROGRAM_ERROR : SUCCESS);

    log_dump(program, "Initial program");

    // Dump frontend IR for p4i if debug (-g) was selected
    // Or if the --toJson was used
    if (BackendOptions().debugInfo || options.dumpJsonFile) {
        // Dump file is either whatever --toJson specifies or a default one for p4i
        cstring irFilePath = options.dumpJsonFile ?
                            options.dumpJsonFile :
                            BFNContext::get().getOutputDirectory() + "/frontend-ir.json";
        // Print out the IR for p4i after frontend (--toJson "-" signifies stdout)
        auto &irFile = irFilePath != "-" ?
                        *openFile(irFilePath, false) :
                        std::cout;
        LOG3("IR dump after frontend to " << irFilePath);
        JSONGenerator(irFile, true) << program << std::endl;
    }

    BFN::generateRuntime(program, options);
    if (::errorCount() > 0)
        return return_from_main_politely(PROGRAM_ERROR);

    auto hook = options.getDebugHook();
    BFN::MidEnd midend(options);
    midend.addDebugHook(hook, true);
    midend.addDebugHook(EventLogger::getDebugHook(), true);

    // so far, everything is still under the same program for 32q, generate two separate threads
    program = program->apply(midend);
    if (!program)
        // still did not reach the backend for fitting issues
        return return_from_main_politely(PROGRAM_ERROR);
    log_dump(program, "After midend");
    if (::errorCount() > 0)
        return return_from_main_politely(PROGRAM_ERROR);

    if (::errorCount() > 0)
        return return_from_main_politely(PROGRAM_ERROR);

    /* save the pre-packing p4 program */
    // return IR::P4Program with @flexible header packed
    auto map = new RepackedHeaderTypes;
    BridgedPacking bridgePacking(options, *map, *midend.sourceInfoLogging);
    bridgePacking.addDebugHook(hook, true);
    bridgePacking.addDebugHook(EventLogger::getDebugHook(), true);

    program->apply(bridgePacking);
    if (!program)
        return return_from_main_politely(PROGRAM_ERROR);
        // still did not reach the backend for fitting issues

    SubstitutePackedHeaders substitute(options, *map, *midend.sourceInfoLogging);
    substitute.addDebugHook(hook, true);
    substitute.addDebugHook(EventLogger::getDebugHook(), true);

    program = program->apply(substitute);
    log_dump(program, "After flexiblePacking");
    if (!program)
        // still did not reach the backend for fitting issues
        return return_from_main_politely(PROGRAM_ERROR);

    if (!substitute.getToplevelBlock())
        return return_from_main_politely(PROGRAM_ERROR);

    if (options.debugInfo) {
        program->apply(SourceInfoLogging(BFNContext::get().getOutputDirectory().c_str(),
                                         "source.json", *midend.sourceInfoLogging));
    }

#if !BAREFOOT_INTERNAL
    // turn all errors into "fatal errors" by exiting on the first error encountered
    BFNContext::get().errorReporter().setMaxErrorCount(1);
#endif

    // create the archive manifest
    Logging::Manifest &manifest = Logging::Manifest::getManifest();

    // Register event logger in manifest
    // Also register frontend IR dump
    if (BackendOptions().debugInfo) {
        manifest.setEventLog("events.json");
        manifest.setFrontendIrLog("frontend-ir.json");
    }

    // setup the pipes and the architecture config early, so that the manifest is
    // correct even if there are errors in the backend.
    for (auto& pipe : substitute.pipe)
        manifest.setPipe(pipe->id, pipe->name.name);
    manifest.addArchitecture(substitute.getThreads());

    for (auto& kv : substitute.pipes) {
        auto pipe = kv.second;
#if BAREFOOT_INTERNAL
        if (options.skipped_pipes.count(pipe->name)) continue;
#endif

        LOG3("Executing backend for pipe : " << pipe->name);
        manifest.setPipe(pipe->id, pipe->name.name);
        EventLogger::get().pipeChange(pipe->id);

        // generate graphs
        // In principle this should not fail, so we call it before the backend
        if (options.create_graphs) {
            auto graphsDir = BFNContext::get().getOutputDirectory("graphs", pipe->id);
            // set the pipe for the visitors to compute the output dir
            manifest.setRefAndTypeMap(&substitute.refMap, &substitute.typeMap);
            auto toplevel = substitute.getToplevelBlock();
            if (toplevel != nullptr) {
                LOG2("Generating control graphs");
                // FIXME(cc): this should move to the manifest graph generation to work per-pipe
                graphs::ControlGraphs cgen(&substitute.refMap, &substitute.typeMap, graphsDir);
                toplevel->getMain()->apply(cgen);
                // p4c frontend only saves the parser graphs into controlGraphsArray
                // (and does not output them)
                // Therefore we just create empty parser graphs
                std::vector<graphs::Graphs::Graph *> emptyParser;
                // And call graph visitor that actually outputs the graphs from the arrays
                cstring filePath("");
                graphs::Graph_visitor gvs(graphsDir, true, false, false, filePath);
                gvs.process(cgen.controlGraphsArray, emptyParser);
                toplevel->getMain()->apply(manifest);  // generate entries for controls in manifest
            }
            LOG2("Generating parser graphs");
            program->apply(manifest);  // generate graph entries for parsers in manifest
        }

        execute_backend(pipe, options);
    }

    // and output the manifest. This gets called for successful compilation.
    manifest.setSuccess(::errorCount() == 0);
    manifest.serialize();

    reportStats_alwaysCallThisONCEshortlyBeforeExiting();

    if (Log::verbose())
        std::cout << "Done." << std::endl;
    return ::errorCount() > 0 ? COMPILER_ERROR : SUCCESS;
    //     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // _intentionally_ not "return_from_main_politely"
    //   since the stats code has already been called, by this point.

#if BFP4C_CATCH_EXCEPTIONS
    // catch all exceptions here
    } catch (const Util::CompilerBug &e) {
        reportStats_alwaysCallThisONCEshortlyBeforeExiting();

#ifdef BAREFOOT_INTERNAL
        bool barefootInternal = true;
#else
        bool barefootInternal = false;
#endif

        if (std::string(e.what()).find(".p4(") != std::string::npos || barefootInternal)
            std::cerr << e.what() << std::endl;
        std::cerr << "Internal compiler error. Please submit a bug report with your code."
              << std::endl;
        return INTERNAL_COMPILER_ERROR;
    } catch (const Util::CompilerUnimplemented &e) {
        reportStats_alwaysCallThisONCEshortlyBeforeExiting();

        std::cerr << e.what() << std::endl;
        return COMPILER_ERROR;
    } catch (const Util::CompilationError &e) {
        reportStats_alwaysCallThisONCEshortlyBeforeExiting();

        std::cerr << e.what() << std::endl;
        return PROGRAM_ERROR;
#if BAREFOOT_INTERNAL
    } catch (const std::exception &e) {
        reportStats_alwaysCallThisONCEshortlyBeforeExiting();

        std::cerr << "Internal compiler error: " << e.what() << std::endl;
        return INTERNAL_COMPILER_ERROR;
#endif
    } catch (...) {
        reportStats_alwaysCallThisONCEshortlyBeforeExiting();

        std::cerr << "Internal compiler error. Please submit a bug report with your code."
                  << std::endl;
        return INTERNAL_COMPILER_ERROR;
    }
#endif  // BFP4C_CATCH_EXCEPTIONS
}
