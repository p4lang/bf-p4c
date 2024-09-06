#ifndef _TOFINO1_NATIVE_ARCHITECTURE_
#define _TOFINO1_NATIVE_ARCHITECTURE_

#if   __TARGET_TOFINO__ == 1
#include "tofino1_specs.p4"
#elif __TARGET_TOFINO__ == 2
#include "tofino2_specs.p4"
#elif __TARGET_TOFINO__ == 3    /* <CLOUDBREAK_ONLY> */
#include "tofino3_specs.p4"     /* <CLOUDBREAK_ONLY> */
#elif __TARGET_TOFINO__ == 5    /* <FLATROCK_ONLY> */
#include "tofino1_specs.p4"     /* <FLATROCK_ONLY> */
#else
#error Target does not support tofino native architecture
#endif

#include "tofino1_arch.p4"

#endif /* _TOFINO1_NATIVE_ARCHITECTURE_ */
