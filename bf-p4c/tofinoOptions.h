#ifndef TOFINO_TOFINOOPTIONS_H_
#define TOFINO_TOFINOOPTIONS_H_

#include <getopt.h>
#include "frontends/common/options.h"

class Tofino_Options : public CompilerOptions {
 public:
    bool trivial_phvalloc = false;
    bool phv_interference = true;
    bool phv_slicing = true;
    bool phv_overlay = true;
    bool ignorePHVOverflow = false;
    bool native_arch = false;

    Tofino_Options() {
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
        target = "tofino-v1model-barefoot";
    }
};

#endif /* TOFINO_TOFINOOPTIONS_H_ */
