#ifndef TOFINO_TOFINOOPTIONS_H_
#define TOFINO_TOFINOOPTIONS_H_

#include <getopt.h>
#include "frontends/common/options.h"

class Tofino_Options : public CompilerOptions {
 public:
    bool trivial_phvalloc = false;
    bool phv_interference = false;

    Tofino_Options() {
        registerOption("--oldpa", nullptr,
            [this](const char *) { trivial_phvalloc = true; return true; },
            "use the old (trivial) PHV allocator");
        registerOption("--trivpa", nullptr,
            [this](const char *) { trivial_phvalloc = true; return true; },
            "use the trivial PHV allocator");
        registerOption("--phvintf", nullptr,
            [this](const char *) { phv_interference = true; return true; },
            "use cluster_phv_interference based PHV reduction");
        target = "tofino";
    }
};

#endif /* TOFINO_TOFINOOPTIONS_H_ */
