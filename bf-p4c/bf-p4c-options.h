#ifndef EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_
#define EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_

#include <getopt.h>
#include <boost/algorithm/string.hpp>
#include "frontends/common/options.h"
#include "lib/safe_vector.h"
#include "version.h"

class BFN_Options : public CompilerOptions {
 public:
    bool trivial_phvalloc = false;
    bool phv_interference = true;
    bool phv_slicing = true;
    bool phv_overlay = true;
    bool ignorePHVOverflow = false;
    bool native_arch = false;
    bool allowUnimplemented = false;
    bool debugInfo = false;

    BFN_Options() {
        target = "tofino-v1model-barefoot";
        compilerVersion = P4C_TOFINO_VERSION;
        preprocessor_options += " -D__TARGET_TOFINO__";

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
        registerOption("--native", nullptr,
            [this](const char *) { native_arch = true; return true; },
            "use tofino native model as target architecture (experimental)");
        registerOption("--allowUnimplemented", nullptr,
            [this](const char *) { allowUnimplemented = true; return true; },
            "allow assembly generation even if there are unimplemented features in the P4 code");
        registerOption("-g", nullptr,
            [this](const char *) { debugInfo = true; return true; },
            "generate debug information");
    }

    bool targetSupported() {
        auto it = std::find(supported_targets.begin(), supported_targets.end(), target);
        return it != supported_targets.end();
    }

    static std::vector<std::string> parse_target(std::string target) {
        std::vector<std::string> splits;
        boost::split(splits, target, [](char c){return c == '-';});
        return splits;
    }

    cstring device() const {
        std::vector<std::string> splits = parse_target(target.c_str());
        return splits[0];
    }

    cstring arch() const {
        std::vector<std::string> splits = parse_target(target.c_str());
        return splits[1];
    }

    cstring vendor() const {
        std::vector<std::string> splits = parse_target(target.c_str());
        return splits[2];
    }

 private:
    static safe_vector<cstring> supported_targets;
};

#endif /* EXTENSIONS_BF_P4C_BF_P4C_OPTIONS_H_ */
