#ifndef BACKENDS_TOFINO_TOFINOOPTIONS_H_
#define BACKENDS_TOFINO_TOFINOOPTIONS_H_

#include <getopt.h>
#include "frontends/common/options.h"

class Tofino_Options : public CompilerOptions {
 public:
    int phv_alloc;

    Tofino_Options() {
        registerOption("--nopa", nullptr,
                       [this](const char*) { phv_alloc = 1; return true; },
                       "Do not perform PHV allocation");
    }
};

#endif /* BACKENDS_TOFINO_TOFINOOPTIONS_H_ */
