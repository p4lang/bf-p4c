#include "bf-p4c/control-plane/tofino_p4runtime.h"

#include "bf-p4c/bf-p4c-options.h"
#include "control-plane/p4RuntimeSerializer.h"
#include "lib/nullstream.h"

namespace BFN {

void generateP4Runtime(const IR::P4Program* program,
                       const BFN_Options& options) {
    // If the user didn't ask for us to generate P4Runtime, skip the analysis.
    if (options.p4RuntimeFile.isNullOrEmpty() &&
        options.p4RuntimeEntriesFile.isNullOrEmpty())
        return;

    if (Log::verbose())
        std::cout << "Generating P4Runtime output" << std::endl;

    auto p4Runtime = P4::generateP4Runtime(program);

    if (!options.p4RuntimeFile.isNullOrEmpty()) {
        std::ostream* out = openFile(options.p4RuntimeFile, false);
        if (!out) {
            ::error("Couldn't open P4Runtime API file: %1%", options.p4RuntimeFile);
            return;
        }

        p4Runtime.serializeP4InfoTo(out, options.p4RuntimeFormat);
    }

    if (!options.p4RuntimeEntriesFile.isNullOrEmpty()) {
        std::ostream* out = openFile(options.p4RuntimeEntriesFile, false);
        if (!out) {
            ::error("Couldn't open P4Runtime static entries file: %1%",
                    options.p4RuntimeEntriesFile);
            return;
        }

        p4Runtime.serializeEntriesTo(out, options.p4RuntimeFormat);
    }
}

}  // namespace BFN
