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
#include "frontends/parsers/parserDriver.h"

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
    registerOption("--skip-compilation", "pipe1[,pipe2]",
        [this](const char* arg) {
        auto copy = strdup(arg);
        while (auto pipe = strsep(&copy, ","))
            skipped_pipes.insert(cstring(pipe));
        return true;},
        "Skip compiling pipes whose name contains one of the 'pipeX' substring",
        OptionFlags::Hide);
    registerOption("--stage-alloc", nullptr,
        [this](const char *) { stage_allocation = true; return true; },
        "Write out PHV allocation based on stage based allocation",
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
    registerOption("--placement", "arg",
        [this](const char *arg) {
          forced_placement = true;
          if (arg != nullptr) {
              if (std::strcmp(arg, "pragma") != 0) {
                ::error("Invalid placement argument '%s'.  Only 'pragma' is supported.", arg);
              }
          }
          return true; },
        "Ignore all dependencies during table placement",
        OptionFlags::OptionalArgument);
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
    registerOption("--disable-init-metadata", nullptr,
        [this](const char *) { disable_init_metadata = true; return true; },
        "Disable metadata initialization");
    registerOption("--decaf", nullptr,
        [this](const char *) { decaf = true; return true; },
        "Apply decaf optimization");
    registerOption("--bf-rt-schema", "file",
        [this](const char *arg) { bfRtSchema = arg; return true; },
        "Generate and write BF-RT JSON schema to the specified file");
    registerOption("--backward-compatible", nullptr,
        [this](const char *) { backward_compatible = true; return true; },
        "Set compiler to be backward compatible with p4c-tofino");
    registerOption("--verbose", nullptr,
        [this](const char *) { verbose = true; return true; },
        "Set compiler verbosity logging");
    registerOption("--disable-egress-packet-length-adjust", nullptr,
        [this](const char *) { adjust_egress_packet_length = false; return true; },
        "Do not adjust egress packet length");
    registerOption("--parser-timing-reports", nullptr,
        [this](const char *) { parser_timing_reports = true; return true; },
        "Report parser timing summary");
    registerOption("--parser-bandwidth-opt", nullptr,
        [this](const char *) { parser_bandwidth_opt = true; return true; },
        "Optimize for parser bandwidth");
    registerOption("--egress-intrinsic-metadata-opt", nullptr,
        [this](const char *) { egress_intr_md_opt = true; return true; },
        "Optimize unused egress intrinsic metadata");
    registerOption("--p4runtime-force-std-externs", nullptr,
        [this](const char *) { p4RuntimeForceStdExterns = true; return true; },
        "Generate P4Info file using standard extern messages instead of Tofino-specific ones, for "
        "a P4 program written for a Tofino-specific arch.");
}

using Target = std::pair<cstring, cstring>;
std::vector<const char*>* BFN_Options::process(int argc, char* const argv[]) {
    static const ordered_set<Target> supportedTargets = {
        {"tofino", "v1model"},
        {"tofino", "tna"},
        {"tofino", "psa"},
  #if BAREFOOT_INTERNAL
        // allow p4-14 support on Tofino2 only for internal builds
        {"tofino2", "v1model"},
        {"tofino2h", "v1model"},
        {"tofino2m", "v1model"},
        {"tofino2u", "v1model"},
  #endif  /* BAREFOOT_INTERNAL */
        {"tofino2", "tna"},
        {"tofino2", "t2na"},
        {"tofino2h", "tna"},
        {"tofino2h", "t2na"},
        {"tofino2m", "tna"},
        {"tofino2m", "t2na"},
        {"tofino2u", "tna"},
        {"tofino2u", "t2na"},
    };
    // BFN_Options::process is called twice: once from the main, and once
    // from applyPragmaOptions to handle pragma command_line.
    // This variable prevents doing the actions below twice, since the
    // pragma command line will only invoke the callbacks for the
    // respective options.
    static bool processed = false;

    // need this before processing options in the base class for gtest
    // which is corrupting outputDir data member (on Linux!). Why?
    // Don't know, and I'm at the end of my patience with it ...
    if (!processed) outputDir = ".";

    auto remainingOptions = CompilerOptions::process(argc, argv);

    if (!processed) {
        processed = true;

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
        if (!outputDir || outputDir == ".")
            outputDir = cstring(programName + "." + target);
        int rc = mkdir(outputDir.c_str(), 0755);
        if (rc != 0 && errno != EEXIST) {
            std::cerr << "Failed to create directory: " << outputDir << std::endl;
            return remainingOptions;
        }
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
    if (pragmaName == "command_line")
        return parseCompilerOption(annotation);
    return P4COptionPragmaParser::tryToParse(annotation);
}

boost::optional<P4::IOptionPragmaParser::CommandLineOptions>
BFNOptionPragmaParser::parseCompilerOption(const IR::Annotation* annotation) {
    // See `supported_cmd_line_pragmas` in glass/p4c_tofino/target/tofino/compile.py:205
    static const std::map<cstring, bool> cmdLinePragmas = {
        { "--no-dead-code-elimination", false },
        { "--force-match-dependency",   false },
        { "--metadata-overlay",         false },
        { "--placement",                true },
        { "--placement-order",          false },
        { "--disable-init-metadata",    true },  // brig only
        { "--decaf",                    true }   // brig only
    };

    boost::optional<CommandLineOptions> newOptions;
    newOptions.emplace();

    // Parsing of option pragmas is done early in the compiler, before P4₁₆
    // annotations are parsed, so we are responsible for doing our own parsing
    // here.
    auto args = &annotation->expr;
    if (args->empty()) {
        auto parseResult =
            P4::P4ParserDriver::parseExpressionList(annotation->srcInfo,
                                                    annotation->body);
        if (parseResult != nullptr) {
            args = parseResult;
        }
    }

    bool first = true;
    for (auto* arg : *args) {
        auto* argString = arg->to<IR::StringLiteral>();
        if (!argString) {
            ::warning("@pragma command_line arguments must be strings: %1%",
                      annotation);
            return boost::none;
        }
        if (first && !cmdLinePragmas.count(argString->value)) {
            ::warning("Unknown @pragma command_line %1%", annotation);
            return boost::none;
        }
        if (first && !cmdLinePragmas.at(argString->value)) {
            ::warning("@pragma command_line %1% is disabled in this "
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
