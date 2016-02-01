#ifndef BACKENDS_TOFINO_TOFINOOPTIONS_H_
#define BACKENDS_TOFINO_TOFINOOPTIONS_H_

#include <getopt.h>
#include "frontends/common/options.h"

class Tofino_Options : public CompilerOptions {
 public:
    int phv_alloc;

    void usage() {
        CompilerOptions::usage();
        usageStream << "Additional options: " << std::endl;
        usageStream << "  --nopa        Do not perform PHV allocation" << std::endl;
    }

    int parse(int argc, char* const argv[]) {
        (void)CompilerOptions::parse(argc, argv);
        static struct option long_options[] = {
            { "nopa",       no_argument,       &phv_alloc, 0 },
            { 0,            0,                 0, 0 }
        };

        int opt;
        while ((opt = getopt_long(argc, argv, "", long_options, 0)) >= 0) {
            switch (opt) {
                case 0:
                default:
                    break; } }
        return optind;
    }
};

#endif /* BACKENDS_TOFINO_TOFINOOPTIONS_H_ */
