#include "bf-p4c/control-plane/bfruntime.h"
#include "bf-p4c/control-plane/tofino_p4runtime.h"
#include "bf-p4c/control-plane/bfruntime_arch_handler.h"
#include "bf-p4c/control-plane/p4runtime_force_std.h"

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/arch/rewrite_action_selector.h"

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "lib/nullstream.h"

namespace BFN {

void generateP4Runtime(const IR::P4Program* program,
                       const BFN_Options& options) {
    // If the user didn't ask for us to generate P4Runtime, skip the analysis.
    if (options.p4RuntimeFile.isNullOrEmpty() &&
        options.p4RuntimeFiles.isNullOrEmpty() &&
        options.p4RuntimeEntriesFile.isNullOrEmpty() &&
        options.p4RuntimeEntriesFiles.isNullOrEmpty() &&
        options.bfRtSchema.isNullOrEmpty()) {
        return;
    }

    auto p4RuntimeSerializer = P4::P4RuntimeSerializer::get();

    // By design we can use the same architecture handler implementation for
    // both TNA and T2NA.
    p4RuntimeSerializer->registerArch("psa", new PSAArchHandlerBuilder());
    p4RuntimeSerializer->registerArch("tna", new TofinoArchHandlerBuilder());
    p4RuntimeSerializer->registerArch("t2na", new TofinoArchHandlerBuilder());
    p4RuntimeSerializer->registerArch("t3na", new TofinoArchHandlerBuilder());

    auto arch = P4::P4RuntimeSerializer::resolveArch(options);

    if (Log::verbose())
        std::cout << "Generating P4Runtime output for architecture " << arch << std::endl;


    if (options.p4RuntimeForceStdExterns && (arch != "tna" && arch != "t2na" && arch != "t3na")) {
        ::error("--p4runtime-force-std-externs can only be used with "
                "Tofino-specific architectures, such as 'tna'");
        return;
    }

    // Typedefs in P4 source are replaced in the midend. However since bf
    // runtime runs before midend, we run the pass to eliminate typedefs here to
    // facilitate bf-rt json generation.
    // Note: This can be removed if typedef elimination pass moves to frontend.
    P4::ReferenceMap    refMap;
    P4::TypeMap         typeMap;
    refMap.setIsV1(true);
    program = program->apply(P4::EliminateTypedef(&refMap, &typeMap));
    program = program->apply(SetDefaultSize(false /* warn */));

    if (arch != "psa") {
        // Following ActionSelector API has been retired, we convert them
        // to the new syntax before generating BFRT json.
        // ActionSelector(bit<32> size, Hash<_> hash, SelectorMode_t mode);
        // ActionSelector(bit<32> size, Hash<_> hash, SelectorMode_t mode, Register<bit<1>, _> reg);
        // NOTE: this can be removed when we remove old syntax from tofino.p4.
        program = program->apply(RewriteActionSelector(&refMap, &typeMap));
    }

    auto p4Runtime = p4RuntimeSerializer->generateP4Runtime(program, arch);

    if (options.p4RuntimeForceStdExterns) {
        auto p4RuntimeStd = convertToStdP4Runtime(p4Runtime);
        p4RuntimeSerializer->serializeP4RuntimeIfRequired(p4RuntimeStd, options);
    } else {
        p4RuntimeSerializer->serializeP4RuntimeIfRequired(p4Runtime, options);
    }

    if (!options.bfRtSchema.isNullOrEmpty()) {
        std::ostream* out = openFile(options.bfRtSchema, false);
        if (!out) {
            ::error("Couldn't open BF-RT schema file: %1%", options.bfRtSchema);
            return;
        }

        BFRT::serializeBfRtSchema(out, p4Runtime);
    }
}

}  // namespace BFN
