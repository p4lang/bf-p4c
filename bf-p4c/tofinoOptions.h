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

    Tofino_Options() {
        registerOption("--trivpa", nullptr,
            [this](const char *) { trivial_phvalloc = true; return true; },
            "use the trivial PHV allocator");
        registerOption("--phvintf", nullptr,
            [this](const char *) { phv_interference = false; return false; },
            "do not use cluster_phv_interference interference-graph based PHV reduction");
        registerOption("--phvslice", nullptr,
            [this](const char *) { phv_slicing = false; return false; },
            "do not use cluster_phv_slicing based PHV slices");
        registerOption("--phvover", nullptr,
            [this](const char *) { phv_overlay = false; return false; },
            "use cluster_phv_overlay based PHV overlays");
        target = "tofino";
    }
};

#endif /* TOFINO_TOFINOOPTIONS_H_ */
