#ifndef _TOFINO2_NATIVE_ARCHITECTURE_
#define _TOFINO2_NATIVE_ARCHITECTURE_

#if   __TARGET_TOFINO__ == 2
#include "tofino2_specs.p4"
#elif __TARGET_TOFINO__ == 3    /* <CLOUDBREAK_ONLY> */
#include "tofino3_specs.p4"     /* <CLOUDBREAK_ONLY> */
#else
#error Target does not support tofino2 native architecture
#endif

#include "tofino2_arch.p4"

#endif /* _TOFINO2_NATIVE_ARCHITECTURE_ */
