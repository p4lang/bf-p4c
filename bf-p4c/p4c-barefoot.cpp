#include <libgen.h>
#include <limits.h>
#include <signal.h>
#include <stdio.h>
#include <iostream>
#include <string>

#include "arch/simple_switch.h"
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
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/compile_context.h"
#include "lib/crash.h"
#include "lib/gc.h"
#include "lib/log.h"
#include "lib/exceptions.h"
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
    BFN::Visualization _visualization;

    void end_apply() override {
        if (!_options.debugInfo)  // generate resources info only if invoked with -g
            return;
        if (_success) {
            cstring resourcesFile = _options.outputFile + ".res.json";
            LOG2("ASM generation for resources: " << resourcesFile);
            std::ofstream ctxt_stream(_options.outputFile, std::ios_base::app);
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

                char *program_name_ptr = basename(const_cast<char *>(_options.outputFile.c_str()));
                if (!program_name_ptr)
                    return;  // failed to get the program_name
                std::string program_name(program_name_ptr);
                program_name.erase(program_name.size()-4, 4);  // remove ".bfa"

                char *dir_name_ptr = dirname(const_cast<char *>(_options.outputFile.c_str()));
                if (!dir_name_ptr)
                    return;   // failed to retrieve the directory
                std::string dir(dir_name_ptr);

                LOG2("ASM: context.json generation for failed compile: " << dir << "context.json");
                ctxtJson.emplace("build_date", new Util::JsonValue(build_date));
                ctxtJson.emplace("schema_version", new Util::JsonValue("1.3.9"));
                ctxtJson.emplace("compiler_version", new Util::JsonValue(BF_P4C_VERSION));
                ctxtJson.emplace("program_name", new Util::JsonValue(program_name));
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
    explicit OutputAsm(const BFN::Backend &b, const BFN_Options& o, bool success = true) :
        _options(o), _success(success) {
        setStopOnError(false);
        addPasses({ new BFN::AsmOutput(b.get_phv(), b.get_clot(), o, success),
                    &_visualization
                    });
        setName("Assembly output");
    }
};

int main(int ac, char **av) {
    setup_gc_logging();
    setup_signals();

    AutoCompileContext autoBFNContext(new BFNContext);
    auto& options = BFNContext::get().options();

    if (!options.process(ac, av) || ::errorCount() > 0)
        return 1;

    options.setInputFile();
    Device::init(options.device);

    auto hook = options.getDebugHook();

    auto program = P4::parseP4File(options);
    if (!program || ::errorCount() > 0)
        return 1;

    BFNOptionPragmaParser optionsPragmaParser;
    program->apply(P4::ApplyOptionsPragmas(optionsPragmaParser));

    program = P4::FrontEnd(hook).run(options, program, true);
    if (!program)
        return 1;
    log_dump(program, "Initial program");

    BFN::generateP4Runtime(program, options);
    if (::errorCount() > 0)
        return 1;

    BFN::MidEnd midend(options);
    midend.addDebugHook(hook);
    program = program->apply(midend);
    if (!program)
        return 1;
    log_dump(program, "After midend");

    auto maupipe = BFN::extract_maupipe(program, options);

    if (::errorCount() > 0)
        return 1;
    if (!maupipe)
        return 1;

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
        OutputAsm as(backend, options, false);
        maupipe->apply(as);

        if (Log::verbose())
            std::cerr << "Failed." << std::endl;
        return 1;
    } catch (std::exception &e) {
        std::cerr << e.what() << std::endl;
        if (Log::verbose())
            std::cerr << "Failed." << std::endl;
        return 1;
    }

    // output the .bfa file
    OutputAsm as(backend, options);
    maupipe->apply(as);

    if (Log::verbose())
        std::cout << "Done." << std::endl;
    return ::errorCount() > 0;
}
