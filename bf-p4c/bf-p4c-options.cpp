#include "bf-p4c-options.h"
#include <boost/algorithm/string.hpp>
#include <algorithm>
#include <unordered_set>
#include <vector>
#include "ir/ir.h"
#include "ir/visitor.h"
#include "version.h"

BFN_Options::BFN_Options() {
    target = "tofino-v1model-barefoot";
    compilerVersion = BF_P4C_VERSION;

    registerOption("--trivpa", nullptr,
        [this](const char *) { trivial_phvalloc = true; return true; },
        "use the trivial PHV allocator");
    registerOption("--nophvintf", nullptr,
        [this](const char *) { phv_interference = false; return true; },
        "do not use cluster_phv_interference interference-graph based PHV reduction");
    registerOption("--noclusterintf", nullptr,
        [this](const char *) { cluster_interference = false; return true; },
        "do not use cluster_to_cluster interference interference-graph based PHV reduction");
    registerOption("--nophvslice", nullptr,
        [this](const char *) { phv_slicing = false; return true; },
        "do not use cluster_phv_slicing based PHV slices");
    registerOption("--nophvover", nullptr,
        [this](const char *) { phv_overlay = false; return true; },
        "do not use cluster_phv_overlay based PHV overlays");
    registerOption("--allowUnimplemented", nullptr,
        [this](const char *) { allowUnimplemented = true; return true; },
        "allow assembly generation even if there are unimplemented features in the P4 code");
    registerOption("-g", nullptr,
        [this](const char *) { debugInfo = true; return true; },
        "generate debug information");
    registerOption("--no-dead-code-elimination", nullptr,
        [this](const char *) { no_deadcode_elimination = true; return true; },
        "do not use dead code elimination");
    registerOption("--placement", nullptr,
        [this](const char *) { forced_placement = true; return true; },
        "ignore all dependencies during table placement");
#if HAVE_JBAY
    registerOption("--use-clot", nullptr,
        [this](const char *) {
            use_clot = true;
            return true;
        }, "use clots in JBay");
    registerOption("--jbay-phv-analysis", nullptr,
        [this](const char *) {
            jbay_analysis = true;
            return true;
        }, "perform JBay mocha and dark analysis");
#endif
    registerOption("--virtual-phvs", nullptr,
        [this](const char *) { virtual_phvs = true; return true; },
        "allow virtual phvs");
    registerOption("--use-pa-solitary", nullptr,
        [this](const char *) { use_pa_solitary = true; return true; },
        "use phv solitary pragma");
}

std::vector<const char*>* BFN_Options::process(int argc, char* const argv[]) {
    static const std::unordered_set<cstring> supportedTargets = {
        "tofino-v1model-barefoot",
        "tofino-native-barefoot",
        "tofino-psa-barefoot",
#if HAVE_JBAY
        "jbay-v1model-barefoot",
        "jbay-native-barefoot",
#endif /* HAVE_JBAY */
    };

    auto remainingOptions = CompilerOptions::process(argc, argv);

    static bool processed = false;

    if (!processed) {
        if (!supportedTargets.count(target)) {
            ::error("Target '%s' is not supported", target);
            return remainingOptions;
        }

        std::vector<std::string> splits;
        std::string target_str(target.c_str());
        boost::split(splits, target_str, [](char c){return c == '-';});
        if (splits.size() != 3)
            BUG("Invalid target %s", target);

        device = splits[0];
        arch   = splits[1];
        vendor = splits[2];

        if (device == "tofino")
            preprocessor_options += " -D__TARGET_TOFINO__";
#if HAVE_JBAY
        else if (device == "jbay")
            preprocessor_options += " -D__TARGET_JBAY__";
#endif
        processed = true;
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
        "ccgf_contiguity_failure",
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
