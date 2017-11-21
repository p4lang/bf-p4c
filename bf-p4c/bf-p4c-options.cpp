#include "bf-p4c-options.h"
#include <boost/algorithm/string.hpp>
#include <algorithm>
#include <unordered_set>
#include <vector>
#include "ir/ir.h"
#include "ir/visitor.h"

safe_vector<cstring> BFN_Options::supported_targets =
    {   "tofino-v1model-barefoot"
      , "tofino-native-barefoot"
#if HAVE_JBAY
      , "jbay-v1model-barefoot"
      , "jbay-native-barefoot"
#endif /* HAVE_JBAY */
    };

std::vector<const char*>* BFN_Options::process(int argc, char* const argv[]) {
    auto remainingOptions = CompilerOptions::process(argc, argv);

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
    else if (device == "jbay")
        preprocessor_options += " -D__TARGET_JBAY__";

    return remainingOptions;
}

DiagnosticAction
BFN_Options::getDiagnosticAction(cstring diagnostic,
                                 DiagnosticAction defaultAction) const {
    auto it = diagnosticActions.find(diagnostic);
    if (it != diagnosticActions.end()) return it->second;
    return defaultAction;
}

void BFN_Options::setDiagnosticAction(cstring diagnostic,
                                      DiagnosticAction action) {
    static const std::unordered_set<cstring> recognizedDiagnostics = {
        "ccgf_contiguity_failure",
        "unknown_diagnostic"
    };

    // Warn if the provided diagnostic isn't one that we recognize. This is just
    // to help the user find typos and the like; diagnostics will still work (or
    // not) even if they aren't in `recognizedDiagnostics`.
    if (!recognizedDiagnostics.count(diagnostic))
        DIAGNOSE_WARN("unknown_diagnostic", *this,
                      "Unrecognized diagnostic: %1%", diagnostic);

    switch (action) {
        case DiagnosticAction::Ignore:
            LOG1("Ignoring diagnostic: " << diagnostic); break;
        case DiagnosticAction::Warn:
            LOG1("Reporting warning for diagnostic: " << diagnostic); break;
        case DiagnosticAction::Error:
            LOG1("Reporting error for diagnostic: " << diagnostic); break;
    }

    diagnosticActions[diagnostic] = action;
}

namespace {

/**
 * Find P4-14 pragmas or P4-16 annotations which specify compiler or diagnostic
 * options and generate a sequence of command-line-like arguments which can be
 * processed by BFN_Options.
 *
 * CollectOptionsPragmas recognizes:
 *  - `pragma bf_p4c_compiler_option [command line arguments]`
 *  - `@bf_p4c_compiler_option([command line arguments])`
 *  - `pragma diagnostic [diagnostic name] [disable|warn|error]`
 *  - `@diagnostic([diagnostic name], ["disable"|"warn"|"error"])`
 *
 * Although P4-16 annotations are attached to a specific program construct, it
 * doesn't matter what these annotations are attached to; only their order in
 * the program matters. This allows these annotations to be used as if they were
 * top-level, standalone directives, and provides a natural translation path
 * from P4-14, where truly standalone pragmas are often used.
 */
struct CollectOptionsPragmas : public Inspector {
    std::vector<const char*> options;

    CollectOptionsPragmas() {
        // Add an initial "option" which will ultimately be ignored.
        // Util::Options::process() expects its arguments to be `argc` and
        // `argv`, so it skips over `argv[0]`, which would ordinarily be the
        // program name.
        options.push_back("(from pragmas)");
    }

    bool preorder(const IR::Annotation* annotation) {
        std::vector<const char*> newOptions;

        if (annotation->name.name == "bf_p4c_compiler_option") {
            // XXX(seth): It'd be nice to have some mechanism for whitelisting
            // options so a P4 program from an untrusted source can't overwrite
            // your files or launch the missiles.
            for (auto* arg : annotation->expr) {
                auto* argString = arg->to<IR::StringLiteral>();
                if (!argString) {
                    ::warning("@bf_p4c_compiler_option arguments must be strings: %1%",
                              annotation);
                    return false;
                }
                newOptions.push_back(argString->value.c_str());
            }
        } else if (annotation->name.name == "diagnostic") {
            if (annotation->expr.size() != 2) {
                ::warning("@diagnostic takes two arguments: %1%", annotation);
                return false;
            }

            auto* diagnosticName = annotation->expr[0]->to<IR::StringLiteral>();
            auto* diagnosticAction = annotation->expr[1]->to<IR::StringLiteral>();
            if (!diagnosticName || !diagnosticAction) {
                ::warning("@diagnostic arguments must be strings: %1%", annotation);
                return false;
            }

            cstring diagnosticOption;
            if (diagnosticAction->value == "disable") {
                diagnosticOption = "--Wdisable=";
            } else if (diagnosticAction->value == "warn") {
                diagnosticOption = "--Wwarn=";
            } else if (diagnosticAction->value == "error") {
                diagnosticOption = "--Werr=";
            } else {
                ::warning("@diagnostic's second argument must be 'disable', "
                          "'warn', or 'error': %1%", annotation);
                return false;
            }

            diagnosticOption += diagnosticName->value;
            newOptions.push_back(diagnosticOption.c_str());
        } else {
            return false;
        }

        LOG1("Adding options from pragma: " << annotation);
        options.insert(options.end(), newOptions.begin(), newOptions.end());
        return false;
    }
};

}  // namespace

void BFN_Options::setFromPragmas(const IR::P4Program* program) {
    CollectOptionsPragmas collectOptions;
    program->apply(collectOptions);

    // Process the options just as if they were specified at the command line.
    // XXX(seth): It'd be nice if the user's command line options took
    // precedence; currently, pragmas override the command line.
    process(collectOptions.options.size(),
            const_cast<char* const*>(collectOptions.options.data()));
}
