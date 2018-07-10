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
// to collect the table resource usages, but we only output the resources node of context.json.
//
// \TODO: The amount of context.json info should be revisited, as we may need additional
// information for visualization (including the compiler logs).
class OutputAsm : public PassManager {
 private:
    const BFN_Options &_options;
    bool _success;

    // logical pipe id to support generating bfa for 64q, 32q and 16q.
    // If compiling for 64q arch, all pipes are programmed with the same binary,
    // the only used logical pipe id is 0.
    // If compiling for 32q arch, use logical pipe id 0 and 1.
    // If compiling for 16q arch, use logical pipe id 0, 1, 2, 3.
    // In all cases, logical pipe id 0 is used for the external-facing pipe (pipe
    // that has connection to external interface), logical pipe id 1, 2, 3 are used
    // for internal-face pipe (pipes that use internal loopback).
    int pipe_id;

    BFN::Visualization _visualization;

    void end_apply() override {
        if (!_options.debugInfo)  // generate resources info only if invoked with -g
            return;
        if (_success) {
            if (!_options.outputFiles.at(pipe_id)) {
                return;
            }
            cstring resourcesFile = _options.outputFiles.at(pipe_id) + ".res.json";
            LOG2("ASM generation for resources: " << resourcesFile);
            std::ofstream ctxt_stream(_options.outputFiles.at(pipe_id), std::ios_base::app);
            ctxt_stream << "resources: \"" << resourcesFile << "\"" << std::endl << std::flush;
            std::ofstream res(resourcesFile);
            res << _visualization << std::endl << std::flush;
        } else {
            // The compilation was unsuccessful, but we still need to put out debug info
            // into context.json. However, the assembler is not going to be invoked, so
            // we need to output all the necessary .json here.
            // Also, we should not throw any exceptions from this code, as we should already
            // know what failed, so we catch all exceptions and ignore them.
            try {
                Util::JsonObject ctxtJson;
                const time_t now = time(NULL);
                char build_date[1024];
                strftime(build_date, 1024, "%c", localtime(&now));

                std::string outputDir(_options.outputDir.c_str());
                outputDir += "/pipe.";
                outputDir += std::to_string(pipe_id);
                int rc = mkdir(outputDir.c_str(), 0755);
                if (rc != 0 && errno != EEXIST) {
                    std::cerr << "Failed to create directory: " << outputDir << std::endl;
                    return;
                }
                LOG2("Generating outputs under " << outputDir);
                std::string dir(outputDir);

                LOG2("ASM: context.json generation for failed compile: " << dir << "context.json");
                ctxtJson.emplace("build_date", new Util::JsonValue(build_date));
                ctxtJson.emplace("schema_version", new Util::JsonValue("1.3.9"));
                ctxtJson.emplace("compiler_version", new Util::JsonValue(BF_P4C_VERSION));
                ctxtJson.emplace("program_name", new Util::JsonValue(_options.programName));
                ctxtJson.emplace("run_id", new Util::JsonValue(RunId::getId()));
                ctxtJson.emplace("learn_quanta", new Util::JsonArray());
                ctxtJson.emplace("dynamic_hash_calculations", new Util::JsonArray());
                ctxtJson.emplace("parser", new Util::JsonObject());
                ctxtJson.emplace("phv_allocation", new Util::JsonArray());
                ctxtJson.emplace("tables", new Util::JsonArray());
                ctxtJson.emplace("configuration_cache", new Util::JsonArray());
                ctxtJson.emplace("resources", _visualization.getResourcesNode());

                std::ofstream res(dir + "context.json");
                ctxtJson.serialize(res);
                res << std::endl << std::flush;
            } catch (...) {}  // Do nothing. If we failed to produce context.json, too bad!
        }
    }

 public:
    explicit OutputAsm(const BFN::Backend &b, const int& pipe_id,
                       const BFN_Options& o, bool success = true) :
        _options(o), _success(success), pipe_id(pipe_id) {
        setStopOnError(false);
        addPasses({ new BFN::AsmOutput(b.get_phv(), b.get_clot(),
                                       b.get_defuse(), o, success, pipe_id),
                    &_visualization
                    });
        setName("Assembly output");
    }
};

/// use pipe.n to generate output directory.
void execute_backend(const IR::BFN::Pipe* maupipe, int pipe_id, BFN_Options& options) {
    if (::errorCount() > 0)
        return;
    if (!maupipe)
        return;

    if (Log::verbose())
        std::cout << "Compiling" << std::endl;


    BFN::Backend backend(options);
    try {
        maupipe = maupipe->apply(backend);
    } catch (Util::P4CExceptionBase &ex) {
        // expect that all compiler failures to be derived from P4CExceptionBase
        // compiler bugs or program errors are a different exception hierarchy -- are they?
        std::cerr << ex.what() << std::endl;

        // produce resource nodes in context.json regardless of failures
        std::cerr << "compilation failed: producing ctxt.json" << std::endl;
        OutputAsm as(backend, pipe_id, options, false);
        maupipe->apply(as);

        if (Log::verbose())
            std::cerr << "Failed." << std::endl;
        return;
    } catch (std::exception &e) {
        std::cerr << e.what() << std::endl;
        if (Log::verbose())
            std::cerr << "Failed." << std::endl;
        return;
    }

    // output the .bfa file
    OutputAsm as(backend, pipe_id, options);
    maupipe->apply(as);
}

int main(int ac, char **av) {
    setup_gc_logging();
    setup_signals();

    AutoCompileContext autoBFNContext(new BFNContext);
    auto& options = BFNContext::get().options();

    if (!options.process(ac, av) || ::errorCount() > 0)
        return 1;

    options.setInputFile();
    Device::init(options.target);

    // FIXME -- should be based on the architecture option
    P4V1::Converter::createProgramStructure = P4V1::TNA_ProgramStructure::create;

    auto hook = options.getDebugHook();

    auto program = P4::parseP4File(options);
    if (!program || ::errorCount() > 0)
        return 1;

    BFNOptionPragmaParser optionsPragmaParser;
    program->apply(P4::ApplyOptionsPragmas(optionsPragmaParser));

    program = P4::FrontEnd(hook).run(options, program, true);
    if (!program)
        return 1;

    // If we just want to prettyprint to p4_16, running the frontend is sufficient.
    if (!options.prettyPrintFile.isNullOrEmpty())
        return ::errorCount();

    log_dump(program, "Initial program");

    BFN::generateP4Runtime(program, options);
    if (::errorCount() > 0)
        return 1;

    BFN::MidEnd midend(options);
    midend.addDebugHook(hook);
    // so far, everything is still under the same program for 32q, generate two separate threads
    program = program->apply(midend);
    if (!program)
        return 1;
    log_dump(program, "After midend");

    // create the archive manifest
    Logging::Manifest manifest(options);

    // generate graphs
    // In principle this should not fail, so we call it before the backend
    if (options.create_graphs) {
        std::string graphsDir(options.outputDir.c_str());
        graphsDir += "/graphs";
        int rc = mkdir(graphsDir.c_str(), 0755);
        if (rc != 0 && errno != EEXIST) {
            std::cerr << "Failed to create directory: " << graphsDir << std::endl;
            return 1;
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

    // convert midend IR to backend IR
    BFN::BackendConverter conv(&midend.refMap, &midend.typeMap, midend.toplevel);
    conv.convert(program, options);
    if (::errorCount() > 0)
        return 1;

    for (auto& kv : conv.pipe) {
        execute_backend(kv.second, kv.first, options);
        manifest.addContext(kv.first, "context.json");
    }
    // generate the archive manifest
    manifest.serialize();

    if (Log::verbose())
        std::cout << "Done." << std::endl;
    return ::errorCount() > 0;
}
