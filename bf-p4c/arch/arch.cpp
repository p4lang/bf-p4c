#include "bf-p4c/arch/arch.h"
#include "bf-p4c/arch/psa.h"
#include "bf-p4c/arch/tna.h"
#include "bf-p4c/arch/t2na.h"
#include "bf-p4c/arch/v1model.h"
#include "bf-p4c/device.h"

namespace BFN {

ArchTranslation::ArchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                 BFN_Options& options) {
    if (options.arch == "v1model") {
        passes.push_back(new BFN::SimpleSwitchTranslation(refMap, typeMap, options /*map*/));
#if HAVE_JBAY
        if (Device::currentDevice() == Device::JBAY) {
            passes.push_back(new BFN::PortTNAToJBay(refMap, typeMap, options));
        }
#endif  // HAVE_JBAY
    } else if (options.arch == "tna") {
        if (Device::currentDevice() == Device::TOFINO) {
            passes.push_back(new BFN::LowerTofinoToStratum(refMap, typeMap, options));
        }
#if HAVE_JBAY
        if (Device::currentDevice() == Device::JBAY) {
            WARNING("TNA architecture is not supported on a Tofino2 device."
                    "The compilation may produce wrong binary."
                    "Consider invoking the compiler with --arch t2na.");
            passes.push_back(new BFN::LowerTofinoToStratum(refMap, typeMap, options));
        }
    } else if (options.arch == "t2na") {
        if (Device::currentDevice() == Device::JBAY) {
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
