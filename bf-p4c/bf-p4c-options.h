#ifndef EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_
#define EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_

#include "frontends/common/applyOptionsPragmas.h"
#include "frontends/common/options.h"
#include "lib/cstring.h"

class BFN_Options : public CompilerOptions {
 public:
    bool trivial_phvalloc = false;
    bool phv_interference = true;
    bool cluster_interference = true;
    bool phv_slicing = true;
    bool phv_overlay = true;
    bool allowUnimplemented = false;
    bool debugInfo = false;
    bool no_deadcode_elimination = false;
    bool forced_placement = false;
    bool use_clot = true;
    bool jbay_analysis = false;
    bool use_pa_solitary = false;
    float phv_scale_factor = 1;
    bool create_graphs = false;
    bool privatization = false;
    bool decaf = false;
    bool always_init_metadata = false;
    bool disable_init_metadata = false;
    bool disable_parser_state_merging = false;
    bool backward_compatible = false;
    bool display_power_budget = false;
    bool disable_power_check = false;
    bool adjust_egress_packet_length = true;
    bool parser_timing_reports = false;
    bool parser_bandwidth_opt = false;
    bool egress_intr_md_opt = false;
    std::set<cstring> disabled_pragmas;
#if BAREFOOT_INTERNAL || 1
    // FIXME -- Cmake does not consistently set BAREFOOT_INTERNAL for all source
    // files (why?), so having the layout of any class depend on it will result in
    // different object files disagreeing on the layout, leading to random memory
    // corruption.  So we always include these fields; they're just unused in release
    // The particular problem seems to be with gtest -- gtest source files are built
    // with BAREFOOT_INTERNAL unset, whil backend files are built with it set.
    std::set<cstring> skipped_pipes;
    bool no_power_check = false;
    bool stage_allocation = false;
#endif
    bool verbose = false;

    cstring bfRtSchema = "";
    bool p4RuntimeForceStdExterns = false;
    cstring programName;
    cstring outputDir = nullptr;    // output directory, default "programName.device"

    BFN_Options();

    /// Process the command line arguments and set options accordingly.
    std::vector<const char*>* process(int argc, char* const argv[]) override;
};

// forward declarations so we do not include ir-generated.h
namespace IR {
class P4Program;      // NOLINT(build/forward_decl)
class ToplevelBlock;  // NOLINT(build/forward_decl)
}

/// A CompileContext for bf-p4c.
class BFNContext final : public P4CContext {
 public:
    /// @return the current compilation context, which must be of type
    /// BFNContext.
    static BFNContext& get();

    /// @return the compiler options for this compilation context.
    BFN_Options& options() final;

    /// Return a string that represents a path to an output directory:
    /// options.outputDir + pipename + suffix
    ///
    /// If the @param pipe is not set (-1) return just options.outputDir.
    /// No other files except for the manifest should be stored in the
    /// root. If the the @param suffix is empty, return options.outputDir + pipename.
    ///
    /// The structure of the output directory is:
    /// options.outputDir / manifest.json
    ///          for each pipe
    ///                   / pipeName/context.json
    ///                   / pipeName/tofino[x].bin
    ///                   / pipeName/program.bfa
    ///                   / pipeName/program.res.json
    ///                   / pipeName/logs/
    ///                   / pipeName/graphs/
    ///
    /// If the directory does not exists, it is created. If the
    /// creation fails print an error message and return an empty
    /// string.
    cstring getOutputDirectory(const cstring &suffix = cstring(), int pipe_id = -1);

    /// identify the pipelines in the program and setup the _pipes map
    void discoverPipes(const IR::P4Program *, const IR::ToplevelBlock *);

    /// Return the pipeline name or empty if the program has not been parsed
    cstring &getPipeName(int pipe_id) {
        static cstring empty("");
        if (_pipes.count(pipe_id))
            return _pipes.at(pipe_id);
        return empty;
    }

 private:
    bool isRecognizedDiagnostic(cstring diagnostic) final;

    /// Compiler options for this compilation context.
    BFN_Options optionsInstance;

    /// The pipelines for this compilation: pairs of <pipe_id, pipename>
    /// These are needed for ensuring a consistent output directory
    std::map<int, cstring> _pipes;
};

inline BFN_Options& BackendOptions() { return BFNContext::get().options(); }

/**
 * An IOptionPragmaParser implementation that supports Barefoot-specific
 * pragmas.
 *
 * In addition to the pragmas supported by P4COptionPragmaParser,
 * BFNOptionPragmaParser recognizes:
 *  - p4-14: @pragma command_line [command line arguments]
 *  - p4-16: @command_line([command line arguments])
 */
class BFNOptionPragmaParser : public P4::P4COptionPragmaParser {
 public:
    boost::optional<CommandLineOptions>
    tryToParse(const IR::Annotation* annotation) override;

 private:
    boost::optional<CommandLineOptions>
    parseCompilerOption(const IR::Annotation* annotation);
};

#endif /* EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_ */
