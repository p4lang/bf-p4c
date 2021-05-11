#if __TARGET_TOFINO__ == 1
#include "tofino1arch.p4"
#elif __TARGET_TOFINO__ == 2
#include "tofino2arch.p4"
#elif __TARGET_TOFINO__ == 3    /* CLOUDBREAK_ONLY */
#include "tofino3arch.p4"       /* CLOUDBREAK_ONLY */
#elif __TARGET_TOFINO__ == 5    /* FLATROCK_ONLY */
#include "tofino1arch.p4"       /* FLATROCK_ONLY */
#else
#error Target does not support tofino native architecture
#endif
