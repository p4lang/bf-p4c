#ifndef EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_
#define EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_

#include <getopt.h>
#include <unordered_map>
#include "frontends/common/options.h"
#include "lib/safe_vector.h"
#include "version.h"

namespace IR {
class P4Program;
}  // namespace IR

/// An action to take when a diagnostic message is triggered.
enum class DiagnosticAction {
    Ignore,  /// Take no action and continue compilation.
    Warn,    /// Print a warning and continue compilation.
    Error    /// Print an error and signal that compilation should be aborted.
};

/**
 * Trigger a diagnostic message.
 *
 * @param DEFAULT_ACTION  The action (warn, error, etc.) to take if no action
 *                        was specified for this diagnostic on the command line
 *                        or via a pragma.
 * @param DIAGNOSTIC_NAME  A human-readable name for the diagnostic. This should
 *                         generally use only lower-case letters and underscores
 *                         so the diagnostic name is a valid P4 identifier.
 * @param OPTIONS  A reference to a BFN_Options instance; used to determine if
 *                 the user overrode the default action for this diagnostic.
 * @param FORMAT  A format for the diagnostic message, using the same style as
 *                '::warning' or '::error'.
 */
#define DIAGNOSE(DEFAULT_ACTION, DIAGNOSTIC_NAME, OPTIONS, FORMAT, ...) \
    do { \
        auto action = (OPTIONS).getDiagnosticAction(DIAGNOSTIC_NAME, DEFAULT_ACTION); \
        if (action == DiagnosticAction::Warn) \
            ::warning("[--Wwarn=" DIAGNOSTIC_NAME "] " FORMAT, __VA_ARGS__); \
        else if (action == DiagnosticAction::Error) \
            ::error("[--Werr=" DIAGNOSTIC_NAME "] " FORMAT, __VA_ARGS__); \
    } while (0)

/// Trigger a diagnostic message which is treated as a warning by default.
#define DIAGNOSE_WARN(DIAGNOSTIC_NAME, OPTIONS, ...) \
    DIAGNOSE(DiagnosticAction::Warn, DIAGNOSTIC_NAME, OPTIONS, __VA_ARGS__)

/// Trigger a diagnostic message which is treated as an error by default.
#define DIAGNOSE_ERROR(DIAGNOSTIC_NAME, OPTIONS, ...) \
    DIAGNOSE(DiagnosticAction::Error, DIAGNOSTIC_NAME, OPTIONS, __VA_ARGS__)

class BFN_Options : public CompilerOptions {
 public:
    cstring device = "tofino";
    cstring arch   = "v1model";
    cstring vendor = "barefoot";

    bool trivial_phvalloc = false;
    bool phv_interference = true;
    bool cluster_interference = true;
    bool phv_slicing = true;
    bool phv_overlay = true;
    bool ignorePHVOverflow = false;
    bool allowUnimplemented = false;
    bool debugInfo = false;
    bool no_deadcode_elimination = false;
    bool forced_placement = false;
    bool use_clot = false;

    /// A mapping from diagnostic names (as passed to the DIAGNOSE* macros) to
    /// actions that should be taken when those diagnostics are triggered.
    std::unordered_map<cstring, DiagnosticAction> diagnosticActions;

    BFN_Options() {
        target = "tofino-v1model-barefoot";
        compilerVersion = P4C_TOFINO_VERSION;

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
        registerOption("--ignore-overflow", nullptr,
            [this](const char *) { ignorePHVOverflow = true; return true; },
            "attempt to continue compiling even if PHV space is exhausted");
        registerOption("--allowUnimplemented", nullptr,
            [this](const char *) { allowUnimplemented = true; return true; },
            "allow assembly generation even if there are unimplemented features in the P4 code");
        registerOption("-g", nullptr,
            [this](const char *) { debugInfo = true; return true; },
            "generate debug information");
        registerOption("--no-deadcode-elimination", nullptr,
            [this](const char *) { no_deadcode_elimination = true; return true; },
            "do not use dead code elimination");
        registerOption("--placement", nullptr,
            [this](const char *) { forced_placement = true; return true; },
            "ignore all dependencies during table placement");
        registerOption("--use_clot", nullptr,
            [this](const char *) { use_clot = true; return true; },
            "use clots in JBay");
        registerOption("--Wdisable", "diagnostic",
            [this](const char *diagnostic) {
                setDiagnosticAction(diagnostic, DiagnosticAction::Ignore);
                return true;
            }, "Disable a compiler diagnostic");
        registerOption("--Wwarn", "diagnostic",
            [this](const char *diagnostic) {
                setDiagnosticAction(diagnostic, DiagnosticAction::Warn);
                return true;
            }, "Report a warning for a compiler diagnostic");
        // XXX(seth): It'd be nice if this were `--Werror`, but unfortunately
        // that one is already used in the p4c repo.
        registerOption("--Werr", "diagnostic",
            [this](const char *diagnostic) {
                setDiagnosticAction(diagnostic, DiagnosticAction::Error);
                return true;
            }, "Report an error for a compiler diagnostic");
    }

    bool targetSupported() {
        auto it = std::find(supported_targets.begin(), supported_targets.end(), target);
        return it != supported_targets.end();
    }

    /// @return the action to take for the given diagnostic, falling back to the
    /// default action if it wasn't overridden via the command line or a pragma.
    DiagnosticAction getDiagnosticAction(cstring diagnostic,
                                         DiagnosticAction defaultAction) const;

    /// Set the action to take for the given diagnostic.
    void setDiagnosticAction(cstring diagnostic, DiagnosticAction action);

    /// Process the command line arguments and set options accordingly.
    std::vector<const char*>* process(int argc, char* const argv[]);

    /// Set additional options that may be specified as pragmas or annotations in
    /// the program.
    void setFromPragmas(const IR::P4Program* program);

 private:
    static safe_vector<cstring> supported_targets;
};

#endif /* EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_ */
