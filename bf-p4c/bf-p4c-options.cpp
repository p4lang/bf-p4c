#include "bf-p4c-options.h"
#include <libgen.h>
#include <sys/stat.h>
#include <algorithm>
#include <cstring>
#include <set>
#include <unordered_set>
#include <vector>
#include <boost/algorithm/string.hpp>
#include "ir/ir.h"
#include "ir/visitor.h"
#include "lib/cstring.h"
#include "version.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/common/parse_annotations.h"
#include "bf-p4c/common/pragma/all_pragmas.h"
#include "bf-p4c/common/pragma/collect_global_pragma.h"
#include "bf-p4c/common/pragma/pragma.h"
#include "bf-p4c/lib/error_type.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/logging/manifest.h"
#include "frontends/parsers/parserDriver.h"

static bool check_exclusive(bool option1, std::string option1Arg,
                            bool option2, std::string option2Arg) {
    if (option1 && option2) {
        ::error("Options %1% and %2% cannot be used together. Please specify only one option",
                option1Arg, option2Arg);
        return false;
    }
    return true;
}

BFN_Options::BFN_Options() {
    target = "tofino";
    arch   = "v1model";

    compilerVersion = BF_P4C_VERSION;

    registerOption("-o", "dir",
                   [this](const char* arg) { outputDir = arg; return true; },
                   "Write output to outdir.\n");
    registerOption("--allowUnimplemented", nullptr,
        [this](const char *) { allowUnimplemented = true; return true; },
        "Allow assembly generation even if there are unimplemented features in the P4 code");
    registerOption("--display-power-budget", nullptr,
        [this](const char *) { display_power_budget = true; return true; },
        "Display MAU power summary after compilation");
    registerOption("--disable-power-check", nullptr,
        [this](const char *) {
            if (!check_exclusive(true, "--disable-power-check",
                                (max_power > 0.0), "--set-max-power"))
                return false;
            if (!check_exclusive(true, "--disable-power-check",
                                no_power_check, "--no-power-check"))
                return false;
            disable_power_check = true;
            return true; },
        "Raises the threshold for the power budget check",
        OptionFlags::Hide);
    registerOption("--set-max-power", "arg",
        [this](const char* arg) {
            if (!check_exclusive(true, "--set-max-power",
                                disable_power_check, "--disable_power_check"))
                return false;
            if (!check_exclusive(true, "--set-max-power",
                                no_power_check, "--no-power-check"))
                return false;
            max_power = std::atof(arg);
            if (max_power <= 0.0) {
                ::error("Invalid max power set %s", arg);
                return false;
            }
            return true; },
         "Set maximum power allowed");
    registerOption("--disable-mpr-config", nullptr,
        [this](const char *) { disable_mpr_config = true; return true; },
        "Disables MPR configuration, switching all tables to be always run.",
        OptionFlags::Hide);
    registerOption("--enable-mpr-config", nullptr,
        [this](const char *) { disable_mpr_config = false; return true; },
        "Enables MPR configuration.",  // Just intended for debugging if switch off by default
        OptionFlags::Hide);
    registerOption("--force-match-dependency", nullptr,
        [this](const char *) { force_match_dependency = true; return true; },
        "Forces all MAU stages to have a match dependency to the previous stage.",
        OptionFlags::Hide);
#if BAREFOOT_INTERNAL
    registerOption("--no-power-check", nullptr,
        [this](const char *) {
            if (!check_exclusive(true, "--no-power-check",
                                disable_power_check, "--disable_power_check"))
                return false;
            if (!check_exclusive(true, "--no-power-check",
                                (max_power > 0.0), "--set-max-power"))
                return false;
            no_power_check = true;
            return true; },
        "Turns off the MAU power budget check",
        OptionFlags::Hide);
    registerOption("--disable-egress-latency-padding", nullptr,
        [this](const char *) { disable_egress_latency_padding = true; return true; },
        "disable egress latency padding",
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
    registerOption("--tof2lab44-workaround", nullptr,
        [this](const char *) { tof2lab44_workaround = true; return true; },
        "enable workaround for tofino2 A0 issue (tof2lab44)",
        OptionFlags::Hide);
    registerOption("--seo", nullptr,
        [this](const char *) { skip_seo = false; return true; },
        "do frontend side-effect ordering",
        OptionFlags::Hide);
    registerOption("--no-seo", nullptr,
        [this](const char *) { skip_seo = true; return true; },
        "skip frontend side-effect ordering",
        OptionFlags::Hide);
    registerOption("--long-branch-backtrack", nullptr,
        [this](const char *) { table_placement_long_branch_backtrack = true; return true; },
        "backtrack in table placement when long branch pressure seems too high",
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
#if BAREFOOT_INTERNAL
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
#endif
    registerOption("--no-clot", nullptr,
        [this](const char *) {
            use_clot = false;
            return true;
        }, "Do not use clots in Tofino2");
    registerOption("--no-tagalong", nullptr,
        [this](const char *) {
            no_tagalong = true;
            return true;
        }, "Do not use tagalong PHV containers in Tofino");
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
    registerOption("--auto-init-metadata", nullptr,
        [this](const char *) {
            auto_init_metadata = true;
            ::warning(ErrorType::WARN_DEPRECATED,
                "The --auto-init-metadata command-line option is deprecated and will be "
                "removed in a future release. Please modify your P4 source to use the "
                "%s annotation instead.",
                PragmaAutoInitMetadata::name);
            return true;
        },
        "DEPRECATED. Use the pa_auto_init_metadata annotation instead. "
        "Automatically initialize metadata to false or 0. This is always enabled for P4_14. "
        "Initialization of individual fields can be disabled by using the pa_no_init annotation.");
    registerOption("--disable-dark-allocation", nullptr,
        [this](const char *) { disable_dark_allocation = true; return true; },
        "Disable allocation to dark containers");
    registerOption("--disable-parser-state-merging", nullptr,
        [this](const char *) { disable_parser_state_merging = true; return true; },
        "Disable parser state merging");
    registerOption("--decaf", nullptr,
        [this](const char *) { decaf = true; return true; },
        "Apply decaf optimization");
    registerOption("--table-placement-in-order", nullptr,
        [this](const char *) { table_placement_in_order = true; return true; },
        "Do not reorder tables in a basic block");
    registerOption("--disable_backfill", nullptr,
        [this](const char *) { disable_table_placement_backfill = true; return true; },
        "Do not backfill tables in table placement");
    registerOption("--disable_split_attached", nullptr,
        [this](const char *) { disable_split_attached = true; return true; },
        "Do not split meters or registers across stages");
    registerOption("--bf-rt-schema", "file",
        [this](const char *arg) { bfRtSchema = arg; return true; },
        "Generate and write BF-RT JSON schema to the specified file");
    registerOption("--backward-compatible", nullptr,
        [this](const char *) {
            backward_compatible = true;
            ::warning(ErrorType::WARN_DEPRECATED,
                "The --backward-compatible command-line option is deprecated and will be "
                "removed in a future release. Please modify your P4 source to use the "
                "%s annotation instead.",
                PragmaBackwardCompatible::name);
            return true; },
        "DEPRECATED. Use the backward_compatible annotation instead. "
        "Set compiler to be backward compatible with p4c-tofino.");
    registerOption("--verbose", nullptr,
        [this](const char *) { verbose = true; return true; },
        "Set compiler verbosity logging");
    registerOption("--infer-payload-offset", nullptr,
        [this](const char *) { infer_payload_offset = true; return true; },
        "Infer payload offset (Tofino2 only)");
    registerOption("--parser-timing-reports", nullptr,
        [this](const char *) { parser_timing_reports = true; return true; },
        "Report parser timing summary");
    registerOption("--parser-bandwidth-opt", nullptr,
        [this](const char *) {
            parser_bandwidth_opt = true;
            ::warning(ErrorType::WARN_DEPRECATED,
                "The --parser-bandwidth-opt command-line option is deprecated and will be "
                "removed in a future release. Please modify your P4 source to use the "
                "%s annotation instead.",
                PragmaParserBandwidthOpt::name);
            return true; },
        "DEPRECATED. Use the pa_parser_bandwidth_opt annotation instead. "
        "Optimize for parser bandwidth.");
    registerOption("--egress-intrinsic-metadata-opt", nullptr,
        [this](const char *) { egress_intr_md_opt = true; return true; },
        "Optimize unused egress intrinsic metadata");
    registerOption("--p4runtime-force-std-externs", nullptr,
        [this](const char *) { p4RuntimeForceStdExterns = true; return true; },
        "Generate P4Info file using standard extern messages instead of Tofino-specific ones, for "
        "a P4 program written for a Tofino-specific arch.");
    registerOption("--disable-tofino1-exit", nullptr,
        [this](const char *) { disable_direct_exit = true; return true; },
        "Disable Tofino1-specific immediate exit optimization");
    registerOption("--disable-longbranch", nullptr,
        [this](const char *) { disable_long_branch = true; return true; },
        "Disable use of long branches");
    registerOption("--enable-longbranch", nullptr,
                   [this](const char *) {
                       if (Device::numLongBranchTags() > 0) {
                           disable_long_branch = false;
                       } else {
                           error("--enable-longbranch not supported on %s", Device::name());
                           disable_long_branch = true; }
                       return true; },
                   "Enable use of long branches");
    registerOption("--help-pragmas", nullptr,
                   [](const char *) {
                       BFN::ParseAnnotations();  // populate the pragma lists
                       BFN::Pragma::printHelp(std::cout);
                       std::cout.flush();
                       exit(0);
                       return false; },
                   "Print the documentation about supported pragmas and exit.");
    registerOption("--help-warnings", nullptr,
                   [](const char *) {
                       BFN::ErrorType::getErrorTypes().printWarningsHelp(std::cout);
                       exit(0);
                       return false; },
                   "Print a list of compiler diagnostics that can be silenced or turned "
                   "into errors via --Wdisable and --Werror.");
    registerOption("--relax-phv-init", "arg",
        [this](const char* arg) {
            int temp = std::atoi(arg);
            if ((!temp && (*arg != '0')) || (temp < 0) || (temp > 2)) {
                ::error("Invalid PHV initialization relaxation value %s. Valid arguments: {0|1|2}",
                        arg);
                return false;
            }
            relax_phv_init = temp;
            return true; },
            "Relax PHV initialization. Default:0 "
            "Values 1 and 2 incrementally relax PHV initialization in later MAU stages in order "
            "to relax PHV Allocation in earlier MAU stages; this may affect table placement");
    registerOption("--quick-phv-alloc", nullptr,
        [this](const char *) {
            quick_phv_alloc = true;
            ::warning(ErrorType::WARN_DEPRECATED,
                "The --quick-phv-alloc command-line option is deprecated and will be "
                "removed in a future release. Please modify your P4 source to use the "
                "%s annotation instead.",
                PragmaQuickPhvAlloc::name);
            return true; },
         "DEPRECATED. Use the pa_quick_phv_alloc annotation instead. "
         "Reduce PHV allocation search space for faster compilation");
#if BAREFOOT_INTERNAL
    registerOption("--alt-phv-alloc", nullptr,
        [this](const char *) { alt_phv_alloc = true; return true; },
         "Alternate PHV allocation ordering (trivial alloc before table placement, "
         "real allocation after)");
#endif
    registerOption("--traffic-limit", "arg",
        [this](const char* arg) {
            int temp = std::atoi(arg);
            if ((!temp && (*arg != '0')) || (temp <= 0) || (temp > 100)) {
                ::error("Invalid traffic limit % value %s. Valid arguments: {1..100}",
                        arg);
                return false;
            }
            traffic_limit = temp;
            return true; },
            "Input traffic limit as a %. Default: 100 % "
            "The input load or traffic limit as a percentage. "
            "A 100% traffic limit indicates 1 incoming packet every cycle");
    registerOption("--num-stages-override", "num",
        [this] (const char *arg) {
            std::string argStr(arg);
            try {
                std::size_t end;
                int tmp = std::stoi(argStr, &end);
                if (end != argStr.size() || tmp <= 0) throw;
                num_stages_override = tmp;
            } catch(...) {
                ::error("Invalid number of MAU stages %s. Enter positive integer.", arg);
                return false;
            }
            return true;
        }, "Reduce number of MAU stages available for compiler. Defaults to "
           "max number of stages available for given device. This may affect table placement");
    registerOption("--enable-event-logger", nullptr,
        [this] (const char *) { enable_event_logger = true; return true; },
        "Enable logging to Event Logger. Creates events.json in output folder.");
    registerOption(
        "--excludeBackendPasses", "pass1[,pass2]",
        [this](const char* arg) {
            excludeBackendPasses = true;
            auto copy = strdup(arg);
            while (auto pass = strsep(&copy, ","))
                passesToExcludeBackend.push_back(pass);
            return true;
        },
        "Exclude passes from backend passes whose name is equal\n"
        "to one of `passX' strings.\n");
    registerOption("--disable-parse-min-depth-limit", nullptr,
        [this] (const char *) { disable_parse_min_depth_limit = true; return true; },
        "Disable parser minimum depth limiting. (Tofino 1 egress parser only.)");
    registerOption("--disable-parse-max-depth-limit", nullptr,
        [this] (const char *) { disable_parse_max_depth_limit = true; return true; },
        "Disable parser maximum depth limiting. (Tofino 1 egress parser only.)");
    registerOption(
        "--disable-parse-depth-limit", nullptr,
        [this](const char *) {
            disable_parse_min_depth_limit = true;
            disable_parse_max_depth_limit = true;
            return true;
        },
        "Disable parser minimum and maximum depth limiting. Equivalent to "
        "\"--disable-parse-min-depth-limit --disable-parse-max-depth-limit\"");
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
        {"tofino2a0", "v1model"},
  #endif  /* BAREFOOT_INTERNAL */
        {"tofino2", "tna"},
        {"tofino2", "t2na"},
  #if BAREFOOT_INTERNAL
        {"tofino2h", "tna"},
        {"tofino2h", "t2na"},
  #endif  /* BAREFOOT_INTERNAL */
        {"tofino2m", "tna"},
        {"tofino2m", "t2na"},
        {"tofino2u", "tna"},
        {"tofino2u", "t2na"},
        {"tofino2a0", "tna"},
        {"tofino2a0", "t2na"},
  #if HAVE_CLOUDBREAK
        {"tofino3", "v1model"},
        {"tofino3", "tna"},
        {"tofino3", "t2na"},
        {"tofino3", "t3na"},
  #endif /* HAVE_CLOUDBREAK */
  #if HAVE_FLATROCK
        {"tofino5", "v1model"},
  #if BAREFOOT_INTERNAL
        {"tofino5", "tna"},
        {"tofino5", "t2na"},
        {"tofino5", "t3na"},
  #endif /* BAREFOOT_INTERNAL */
        {"tofino5", "t5na"},
  #endif /* HAVE_FLATROCK */
    };

    // !!!!!!!!!!!!
    // Attention: the variant values need to be the same as the ones defined
    // in driver/p4c.tofino2.cfg
    // !!!!!!!!!!!!
    static const std::map<cstring, unsigned int> supportedT2Variants = {
        {"tofino2",  1},
        {"tofino2u", 1},
        {"tofino2m", 2},
        {"tofino2h", 3},
        {"tofino2a0", 4}
    };

    // need this before processing options in the base class for gtest
    // which is corrupting outputDir data member (on Linux!). Why?
    // Don't know, and I'm at the end of my patience with it ...
    if (!processed) outputDir = ".";

    // sde installs p4include directory to $SDE/install/share/p4c/p4include
    // and installs p4c to $SDE/install/bin/
    //
    // Therefore, we need to search ../share/p4c/p4include from the
    // directory that p4c resides in.
    searchForIncludePath(p4includePath,
            {"../share/p4c/p4include"}, exename(argv[0]));

    searchForIncludePath(p4_14includePath,
            {"../share/p4c/p4_14include"}, exename(argv[0]));

    auto remainingOptions = CompilerOptions::process(argc, argv);

    // P4_14 programs should have backward_compatible set to true
    if (langVersion == FrontendVersion::P4_14) {
        backward_compatible = true;
    }

    if (!processed) {
        processed = true;

        Target t = { target, arch };
        if (!supportedTargets.count(t)) {
            ::error("Target '%s-%s' is not supported", target, arch);
            return remainingOptions;
        }

        if (target == "tofino") {
            preprocessor_options += " -D__TARGET_TOFINO__=1";
        } else if (target == "tofino2" || target == "tofino2h" || target == "tofino2m" ||
                   target == "tofino2u" || target == "tofino2a0") {
            preprocessor_options += " -D__TARGET_TOFINO__=2";
            preprocessor_options += " -D__TOFINO2_VARIANT__=" +
                std::to_string(supportedT2Variants.at(target));
#if HAVE_CLOUDBREAK
        } else if (target == "tofino3") {
            preprocessor_options += " -D__TARGET_TOFINO__=3";
#endif /* HAVE_CLOUDBREAK */
#if HAVE_FLATROCK
        } else if (target == "tofino5") {
            preprocessor_options += " -D__TARGET_TOFINO__=5";
#endif /* HAVE_FLATROCK */
        } else {
            BUG("Unknown target %s", target);
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
        char *filePath = strndup(inputFile.c_str(), inputFile.size());
        char *program_name_ptr = basename(filePath);
        BUG_CHECK(program_name_ptr, "No valid output argument");
        std::string program_name(program_name_ptr);
        programName = cstring(program_name.substr(0, program_name.rfind(".")));
        free(filePath);

        // same here, could have used dirname(const_char<char *>())
        if (!outputDir || outputDir == ".")
            outputDir = cstring(programName + "." + target);
        auto rc = BFNContext::get().getOutputDirectory();  // the root output dir
        if (!rc)
            return remainingOptions;
    }

    return remainingOptions;
}

/* static */ BFNContext& BFNContext::get() {
    return CompileContextStack::top<BFNContext>();
}

thread_local BFN_Options* BFNContext::optionsInstance = nullptr;

BFN_Options& BFNContext::options() {
    return optionsInstance ? *optionsInstance : primaryOptions;
}

void BFNContext::setBackendOptions(BFN_Options *options) {
    BUG_CHECK(!optionsInstance || optionsInstance == &primaryOptions,
              "Attempt to create new backend options while non-primary options are active");
    optionsInstance = options;
}

void BFNContext::clearBackendOptions() {
    BUG_CHECK(optionsInstance != &primaryOptions,
        "Attempt to destroy backend options while primary options are active");
    optionsInstance = nullptr;
}

cstring BFNContext::getOutputDirectory(const cstring &suffix, int pipe_id) {
    auto dir = options().outputDir;
    if (pipe_id >= 0) {
        auto pipeName = getPipeName(pipe_id);
        if (pipeName && options().langVersion == BFN_Options::FrontendVersion::P4_16)
            dir = options().outputDir + "/" + pipeName + (suffix ? "/" + suffix : "");
        else
            dir = options().outputDir + (suffix ? "/" + suffix : "");
    }
    // tokenize the relative path and create each directory. Would be nice to have a mkpath ...
    char *start, *relPath;
    start = relPath = strdup(dir.substr(options().outputDir.size()+1).c_str());
    if (start) {
        char *relName;
        auto relDir = options().outputDir;
        while ((relName = strsep(&relPath, "/")) != nullptr) {
            relDir +=  cstring("/") + relName;
            int rc = mkdir(relDir.c_str(), 0755);
            if (rc != 0 && errno != EEXIST) {
                ::error("Failed to create directory: %1%", relDir);
                return "";
            }
        }
        free(start);
    } else {
        int rc = mkdir(dir.c_str(), 0755);
        if (rc != 0 && errno != EEXIST) {
            ::error("Failed to create directory: %1%", dir);
            return "";
        }
    }
    return dir;
}

void BFNContext::discoverPipes(const IR::P4Program *program, const IR::ToplevelBlock* toplevel) {
    auto main = toplevel->getMain();
    auto pipe_id = 0;
    for (auto pkg : main->constantValue) {
        if (!pkg.second) continue;
        if (!pkg.second->is<IR::PackageBlock>()) continue;
        auto getPipeName = [program, pipe_id]() -> cstring {
            auto mainDecls = program->getDeclsByName("main")->toVector();
            if (mainDecls->size() == 0) return nullptr;  // no main
            auto decl = mainDecls->at(0);
            auto expr = decl->to<IR::Declaration_Instance>()->arguments->at(pipe_id)->expression;
            if (!expr->is<IR::PathExpression>()) return nullptr;
            return expr->to<IR::PathExpression>()->path->name;
        };
        auto pipeName = getPipeName();
        if (pipeName) {
            _pipes.emplace(pipe_id, pipeName);
            Logging::Manifest::getManifest().setPipe(pipe_id, pipeName);
        }
        pipe_id++;
    }
    LOG4("discoverPipes found:");
    for (auto p : _pipes) LOG4("[" << p.first << ", " << p.second << "]");
}

ErrorReporter& BFNContext::errorReporter() {
    return bfErrorReporter;
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
    if (pragmaName == "pa_quick_phv_alloc")
        BFNContext::get().options().quick_phv_alloc = true;
    else if (pragmaName == "pa_parser_bandwidth_opt")
        BFNContext::get().options().parser_bandwidth_opt = true;
    else if (pragmaName == "backward_compatible")
        BFNContext::get().options().backward_compatible = true;
    else if (pragmaName == "gfm_parity_enable")
        BFNContext::get().options().disable_gfm_parity = false;
    return P4COptionPragmaParser::tryToParse(annotation);
}

boost::optional<P4::IOptionPragmaParser::CommandLineOptions>
BFNOptionPragmaParser::parseCompilerOption(const IR::Annotation* annotation) {
    // See `supported_cmd_line_pragmas` in glass/p4c_tofino/target/tofino/compile.py:205
    static const std::map<cstring, bool> cmdLinePragmas = {
        { "--no-dead-code-elimination",  false },
        { "--force-match-dependency",    false },
        { "--metadata-overlay",          false },
        { "--placement",                 true },
        { "--placement-order",           false },
        { "--auto-init-metadata",        true },  // brig only
        { "--decaf",                     true },  // brig only
        { "--infer-payload-offset",      true },
        { "--relax-phv-init",            true },
        { "--excludeBackendPasses",      true },
        { "--disable-parse-depth-limit", false },
        { "--disable-parse-min-depth-limit", true },  // brig only
        { "--disable-parse-max-depth-limit", true },  // brig only
        { "--num-stages-override", true },  // brig only
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
        // Try to convert the parsed expression to a valid option string
        cstring optionString = "";
        if (auto* argString = arg->to<IR::StringLiteral>()) {
            optionString = argString->value;
        } else {
            // The expression is not a IR::StringLiteral, but it can still be a valid integer
            if (auto* argConstant = arg->to<IR::Constant>()) {
                optionString = std::to_string(argConstant->asInt());
            } else {
                // The expression is neither a IR::StringLiteral or IR::Constant and so is invalid
                ::warning("@pragma command_line arguments must be strings or integers: %1%",
                        annotation);
                return boost::none;
            }
        }

        if (first && !cmdLinePragmas.count(optionString)) {
            ::warning("Unknown @pragma command_line %1%", annotation);
            return boost::none;
        }
        if (first && !cmdLinePragmas.at(optionString)) {
            ::warning("@pragma command_line %1% is disabled in this "
                      "compiler version", annotation);
            return boost::none;
        }
        // trim the options off --placement
        if (first && optionString == "--placement") {
            newOptions->push_back(optionString.c_str());
            break;
        }
        first = false;
        newOptions->push_back(optionString.c_str());
    }

    return newOptions;
}
