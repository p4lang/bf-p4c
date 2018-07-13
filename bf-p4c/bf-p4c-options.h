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
    bool always_init_metadata = false;
    bool backward_compatible = false;
    bool display_power_budget = false;
    bool disable_power_check = false;
#if BAREFOOT_INTERNAL
    bool no_power_check = false;
#endif

    cstring bfRtSchema = "";
    std::vector<cstring> outputFiles;
    cstring outputDir;    // output directory, default "programName.device"
    cstring programName;  // name of the program (derived from first .bfa arg)

    BFN_Options();

    /// Process the command line arguments and set options accordingly.
    std::vector<const char*>* process(int argc, char* const argv[]) override;
};

/// A CompileContext for bf-p4c.
class BFNContext final : public P4CContext {
 public:
    /// @return the current compilation context, which must be of type
    /// BFNContext.
    static BFNContext& get();

    /// @return the compiler options for this compilation context.
    BFN_Options& options() final;

 private:
    bool isRecognizedDiagnostic(cstring diagnostic) final;

    /// Compiler options for this compilation context.
    BFN_Options optionsInstance;
};

/**
 * An IOptionPragmaParser implementation that supports Barefoot-specific
 * pragmas.
 *
 * In addition to the pragmas supported by P4COptionPragmaParser,
 * BFNOptionPragmaParser recognizes:
 *  - `pragma bf_p4c_compiler_option [command line arguments]`
 *  - `@bf_p4c_compiler_option([command line arguments])`
 *  - `pragma command_line [command line arguments]` (for Glass compatibility)
 */
class BFNOptionPragmaParser : public P4::P4COptionPragmaParser {
 public:
    boost::optional<CommandLineOptions>
    tryToParse(const IR::Annotation* annotation) override;

 private:
    boost::optional<CommandLineOptions>
    parseBrigCompilerOption(const IR::Annotation* annotation);

    boost::optional<CommandLineOptions>
    parseGlassCompilerOption(const IR::Annotation* annotation);
};

#endif /* EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_ */
