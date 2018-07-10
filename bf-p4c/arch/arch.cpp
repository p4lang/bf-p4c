#include "bf-p4c/arch/arch.h"
#include "bf-p4c/arch/jna.h"
#include "bf-p4c/arch/psa.h"
#include "bf-p4c/arch/tna.h"
#include "bf-p4c/arch/v1model.h"

namespace BFN {

ArchTranslation::ArchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                 BFN_Options& options) {
    if (options.arch == "v1model") {
        passes.push_back(new BFN::SimpleSwitchTranslation(refMap, typeMap, options /*map*/));
#if HAVE_JBAY
        if (options.target == "jbay") {
            passes.push_back(new BFN::PortTNAToJBay(refMap, typeMap, options));
        }
#endif  // HAVE_JBAY
    } else if (options.arch == "tna") {
        if (options.target == "tofino") {
            passes.push_back(new BFN::LowerTofinoToStratum(refMap, typeMap, options));
        }
#if HAVE_JBAY
        if (options.target == "jbay") {
            WARNING("TNA architecture is not supported on JBay device."
                    "The compilation may produce wrong binary."
                    "Consider invoking the compiler with --arch jna.");
            passes.push_back(new BFN::LowerTofinoToStratum(refMap, typeMap, options));
        }
    } else if (options.arch == "jna") {
        if (options.target == "jbay") {
            passes.push_back(new BFN::LowerTofinoToStratum(refMap, typeMap, options));
        }
#endif  // HAVE_JBAY
    } else if (options.arch == "psa") {
        passes.push_back(new BFN::PortableSwitchTranslation(refMap, typeMap, options /*map*/));
    } else {
        P4C_UNIMPLEMENTED("Cannot handle architecture %1%", options.arch);
    }
}

}  // namespace BFN
