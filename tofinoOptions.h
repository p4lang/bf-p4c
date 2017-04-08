#ifndef TOFINO_TOFINOOPTIONS_H_
#define TOFINO_TOFINOOPTIONS_H_

#include <getopt.h>
#include "frontends/common/options.h"

class Tofino_Options : public CompilerOptions {
 public:
    bool trivial_phvalloc = false;

    Tofino_Options() {
        registerOption("--oldpa", nullptr,
            [this](const char *) { trivial_phvalloc = true; return true; },
            "use the old (trivial) PHV allocator");
        registerOption("--trivpa", nullptr,
            [this](const char *) { trivial_phvalloc = true; return true; },
            "use the trivial PHV allocator");
        target = "tofino";
    }
};

#endif /* TOFINO_TOFINOOPTIONS_H_ */
