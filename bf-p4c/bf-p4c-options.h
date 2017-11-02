#ifndef EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_
#define EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_

#include <getopt.h>
#include "frontends/common/options.h"
#include "lib/safe_vector.h"
#include "version.h"

class BFN_Options : public CompilerOptions {
 public:
    cstring device = "tofino";
    cstring arch   = "v1model";
    cstring vendor = "barefoot";

    bool trivial_phvalloc = false;
    bool phv_interference = true;
    bool phv_slicing = true;
    bool phv_overlay = true;
    bool ignorePHVOverflow = false;
    bool allowUnimplemented = false;
    bool debugInfo = false;
    bool no_deadcode_elimination = false;
    bool forced_placement = false;

    BFN_Options() {
        target = "tofino-v1model-barefoot";
        compilerVersion = P4C_TOFINO_VERSION;

        registerOption("--trivpa", nullptr,
            [this](const char *) { trivial_phvalloc = true; return true; },
            "use the trivial PHV allocator");
        registerOption("--nophvintf", nullptr,
            [this](const char *) { phv_interference = false; return true; },
            "do not use cluster_phv_interference interference-graph based PHV reduction");
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
    }

    bool targetSupported() {
        auto it = std::find(supported_targets.begin(), supported_targets.end(), target);
        return it != supported_targets.end();
    }

    std::vector<const char*>* process(int argc, char* const argv[]);

 private:
    static safe_vector<cstring> supported_targets;
};

#endif /* EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_ */
