#ifndef TOFINO_TOFINOOPTIONS_H_
#define TOFINO_TOFINOOPTIONS_H_

#include <getopt.h>
#include "frontends/common/options.h"

class Tofino_Options : public CompilerOptions {
 public:
    cstring phv_ortools = cstring();
    bool trivial_phvalloc = false;
    int v12_path = 0;

    Tofino_Options() {
        registerOption("--oldpa", nullptr,
            [this](const char *) { trivial_phvalloc = true; return true; },
            "use the old (trivial) PHV allocator");
        registerOption("--trivpa", nullptr,
            [this](const char *) { trivial_phvalloc = true; return true; },
            "use the trivial PHV allocator");
        registerOption("--ortools", nullptr,
            [this](const char *arg) { phv_ortools = arg ? arg : "default"; return true; },
            "use ortools-based PHV allocation");
        registerOption("--v12_path", nullptr,
            [this](const char*) { v12_path = 1; return true; },
            "Use v1->v1.2 conversion path");
        target = "tofino";
    }
};

#endif /* TOFINO_TOFINOOPTIONS_H_ */
