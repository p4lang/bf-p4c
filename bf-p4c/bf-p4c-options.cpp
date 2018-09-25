#include "bf-p4c-options.h"
#include <libgen.h>
#include <string.h>
#include <sys/stat.h>
#include <boost/algorithm/string.hpp>
#include <algorithm>
#include <unordered_set>
#include <vector>
#include "ir/ir.h"
#include "ir/visitor.h"
#include "lib/cstring.h"
#include "version.h"
#include "bf-p4c/common/collect_global_pragma.h"

BFN_Options::BFN_Options() {
    target = "tofino";
    arch   = "v1model";
    compilerVersion = BF_P4C_VERSION;

    registerOption("-o", "dir",
                   [this](const char* arg) { outputDir = arg; return true; },
                   "Write output to outdir.\n");
    registerOption("--trivpa", nullptr,
        [this](const char *) { trivial_phvalloc = true; return true; },
        "Use the trivial PHV allocator");
    registerOption("--nophvintf", nullptr,
        [this](const char *) { phv_interference = false; return true; },
        "Do not use cluster_phv_interference interference-graph based PHV reduction");
    registerOption("--noclusterintf", nullptr,
        [this](const char *) { cluster_interference = false; return true; },
        "Do not use cluster_to_cluster interference interference-graph based PHV reduction");
    registerOption("--nophvslice", nullptr,
        [this](const char *) { phv_slicing = false; return true; },
        "Do not use cluster_phv_slicing based PHV slices");
    registerOption("--nophvover", nullptr,
        [this](const char *) { phv_overlay = false; return true; },
        "Do not use cluster_phv_overlay based PHV overlays");
    registerOption("--allowUnimplemented", nullptr,
        [this](const char *) { allowUnimplemented = true; return true; },
        "Allow assembly generation even if there are unimplemented features in the P4 code");
    registerOption("--display-power-budget", nullptr,
        [this](const char *) { display_power_budget = true; return true; },
        "Display MAU power summary after compilation");
    registerOption("--disable-power-check", nullptr,
        [this](const char *) { disable_power_check = true; return true; },
        "Raises the threshold for the power budget check",
        OptionFlags::Hide);
#if BAREFOOT_INTERNAL
    registerOption("--no-power-check", nullptr,
        [this](const char *) { no_power_check = true; return true; },
        "Turns off the MAU power budget check",
        OptionFlags::Hide);
    registerOption("--gen-mutine-ir", nullptr,
        [this](const char *) { only_gen_mutine_ir = true; return true; },
        "Generate an IR for mutine (p4v, p4testgen)",
        OptionFlags::Hide);
#endif
    registerOption("-g", nullptr,
        [this](const char *) { debugInfo = true; return true; },
        "Generate debug information");
    registerOption("--create-graphs", nullptr,
        [this](const char *) { create_graphs = true; return true; },
        "Create parse and table flow graphs");
    registerOption("--no-dead-code-elimination", nullptr,
        [this](const char *) { no_deadcode_elimination = true; return true; },
        "Do not use dead code elimination");
    registerOption("--placement", nullptr,
        [this](const char *) { forced_placement = true; return true; },
        "Ignore all dependencies during table placement");
#if HAVE_JBAY
    registerOption("--no-clot", nullptr,
        [this](const char *) {
            use_clot = false;
            return true;
        }, "Do not use clots in Tofino2");
    registerOption("--tofino2-phv-analysis", nullptr,
        [this](const char *) {
            jbay_analysis = true;
            return true;
        }, "Perform Tofino2 mocha and dark analysis");
#endif
    registerOption("--phv_scale_factor", "arg",
        [this](const char* arg) {
            float temp = std::atof(arg);
            if (temp <= 0.0) {
                ::error("Invalid phv scale factor %s", arg);
                return false;
            }
            phv_scale_factor = temp;
            return true; },
         "Scale number of phvs by a factor");
    registerOption("--disable-pragma", "arg",
        [this](const char* arg) {
            if (std::find(CollectGlobalPragma::g_global_pragma_names->begin(),
                          CollectGlobalPragma::g_global_pragma_names->end(),
                          arg)
                    == CollectGlobalPragma::g_global_pragma_names->end()) {
                ::error("Unsupported pragma specified with disable-pragma: %1%", arg);
                return false;
            }
            disabled_pragmas.insert(cstring(arg));
            return true; },
        "Disable specified pragmas");
    registerOption("--use-pa-solitary", nullptr,
        [this](const char *) { use_pa_solitary = true; return true; },
        "Use phv solitary pragma");
    registerOption("--no-phv-privatization", nullptr,
        [this](const char *) { privatization = false; return true; },
        "Do not use TPHV/PHV privatization");
    registerOption("--always-init-metadata", nullptr,
        [this](const char *) { always_init_metadata = true; return true; },
        "Insert a table to init metadata in the beginning of pipeline");
    registerOption("--bf-rt-schema", "file",
        [this](const char *arg) { bfRtSchema = arg; return true; },
        "Generate and write BF-RT JSON schema to the specified file");
    registerOption("--backward-compatible", nullptr,
        [this](const char *) { backward_compatible = true; return true; },
        "Set compiler to be backward compatible with p4c-tofino");
    registerOption("--verbose", nullptr,
        [this](const char *) { verbose = true; return true; },
        "Set compiler verbosity logging");
}

using Target = std::pair<cstring, cstring>;
std::vector<const char*>* BFN_Options::process(int argc, char* const argv[]) {
    static const ordered_set<Target> supportedTargets = {
        {"tofino", "v1model"},
        {"tofino", "tna"},
        {"tofino", "psa"},
#if HAVE_JBAY
        {"tofino2", "v1model"},
        {"tofino2", "tna"},
        {"tofino2", "t2na"},
#endif /* HAVE_JBAY */
    };

    auto remainingOptions = CompilerOptions::process(argc, argv);

    static bool processed = false;

    if (!processed) {
        Target t = { target, arch };
        if (!supportedTargets.count(t)) {
            ::error("Target '%s-%s' is not supported", target, arch);
            return remainingOptions;
        }

        if (target == "tofino")
            preprocessor_options += " -D__TARGET_TOFINO__=1";
#if HAVE_JBAY
        else if (target == "tofino2")
            preprocessor_options += " -D__TARGET_TOFINO__=2";
#endif
        processed = true;
    }

    // Cache the names of the output directory and the program name
    cstring inputFile;
    if (remainingOptions && remainingOptions->size() >= 1) {
        inputFile = cstring(remainingOptions->at(0));
    } else {
        inputFile = cstring("dummy.p4i");
    }
    // A complicated way to get a string out of a string, however,
    // Calin says basename(const_cast<char *>()) does not work on
    // certain linux distro.
    size_t len = inputFile.size();
    char *buffer = new char[len+1];
    strncpy(buffer, inputFile.c_str(), len);

    char *program_name_ptr = basename(buffer);
    BUG_CHECK(program_name_ptr, "No valid output argument");
    std::string program_name(program_name_ptr);
    programName = cstring(program_name.substr(0, program_name.rfind(".")));
    delete [] buffer;

    // same here, could have used dirname(const_char<char *>())
    if (!outputDir.size() || outputDir == ".")
        outputDir = cstring(programName + "." + target);
    int rc = mkdir(outputDir.c_str(), 0755);
    if (rc != 0 && errno != EEXIST) {
        std::cerr << "Failed to create directory: " << outputDir << std::endl;
        return remainingOptions;
    }

    return remainingOptions;
}

/* static */ BFNContext& BFNContext::get() {
    return CompileContextStack::top<BFNContext>();
}

BFN_Options& BFNContext::options() {
    return optionsInstance;
}

bool BFNContext::isRecognizedDiagnostic(cstring diagnostic) {
    static const std::unordered_set<cstring> recognizedDiagnostics = {
        "phase0_annotation",
    };

    if (recognizedDiagnostics.count(diagnostic)) return true;
    return P4CContext::isRecognizedDiagnostic(diagnostic);
}

boost::optional<P4::IOptionPragmaParser::CommandLineOptions>
BFNOptionPragmaParser::tryToParse(const IR::Annotation* annotation) {
    auto pragmaName = annotation->name.name;
    if (pragmaName == "bf_p4c_compiler_option")
        return parseBrigCompilerOption(annotation);
    if (pragmaName == "command_line")
        return parseGlassCompilerOption(annotation);
    return P4COptionPragmaParser::tryToParse(annotation);
}

boost::optional<P4::IOptionPragmaParser::CommandLineOptions>
BFNOptionPragmaParser::parseBrigCompilerOption(const IR::Annotation* annotation) {
    boost::optional<CommandLineOptions> newOptions;
    newOptions.emplace();

    // XXX(seth): It'd be nice to have some mechanism for whitelisting
    // options so a P4 program from an untrusted source can't overwrite
    // your files or launch the missiles.
    for (auto* arg : annotation->expr) {
        auto* argString = arg->to<IR::StringLiteral>();
        if (!argString) {
            ::warning("@bf_p4c_compiler_option arguments must be strings: %1%",
                      annotation);
            return boost::none;
        }
        newOptions->push_back(argString->value.c_str());
    }

    return newOptions;
}

boost::optional<P4::IOptionPragmaParser::CommandLineOptions>
BFNOptionPragmaParser::parseGlassCompilerOption(const IR::Annotation* annotation) {
    // See `supported_cmd_line_pragmas` in glass/p4c_tofino/target/tofino/compile.py:205
    static const std::unordered_set<cstring> glassCmdLinePragmas = {
        "--no-dead-code-elimination",
        "--force-match-dependency",
        "--metadata-overlay",
        "--placement",
        "--placement-order",
    };

    // Glass command line pragmas supported in bf-p4c.
    // \TODO: would be nice to get the list directly from the compile options ...
    // for now, we hardcode them
    static const std::unordered_set<cstring> glassCmdLinePragmasAvailableInBrig = {
        // "--no-dead-code-elimination", \TODO: disabled until we fix issues with PHV
        "--placement",
    };

    boost::optional<CommandLineOptions> newOptions;
    newOptions.emplace();

    bool first = true;
    for (auto* arg : annotation->expr) {
        auto* argString = arg->to<IR::StringLiteral>();
        if (!argString) {
            ::warning("@pragma command_line arguments must be strings: %1%",
                      annotation);
            return boost::none;
        }
        if (first && !glassCmdLinePragmas.count(argString->value)) {
            ::warning("@pragma command_line %1% is not supported",
                      annotation);
            return boost::none;
        }
        if (first && !glassCmdLinePragmasAvailableInBrig.count(argString->value)) {
            ::warning("@pragma command_line %1% is not supported in this "
                      "compiler version", annotation);
            return boost::none;
        }
        // trim the options off --placement
        if (first && argString->value == "--placement") {
            newOptions->push_back(argString->value.c_str());
            break;
        }
        first = false;
        newOptions->push_back(argString->value.c_str());
    }

    return newOptions;
}
