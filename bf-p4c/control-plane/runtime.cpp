#include "bf-p4c/control-plane/bfruntime_ext.h"
#include "bf-p4c/control-plane/runtime.h"
#include "bf-p4c/control-plane/bfruntime_arch_handler.h"
#include "bf-p4c/control-plane/p4runtime_force_std.h"

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/arch/rewrite_action_selector.h"

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "midend/eliminateNewtype.h"
#include "lib/nullstream.h"

namespace BFN {

// P4C-3520 : Certain names are reserved for BF-RT and cannot be used on
// controls. Pass checks for control names overlapping restricted ones, append
// to the list as required.
class CheckReservedNames : public Inspector {
    std::set<cstring> reservedNames = { "snapshot" };
    bool preorder(const IR::Type_ArchBlock* b) override {
        LOG3(" Checking block " << b);
        auto name = b->name.toString();
        if (reservedNames.count(name) > 0)
            ::error("Block name in p4 cannot contain BF-RT reserved name (%s) : %s",
                    name, b->toString());
        return false;
    }

 public:
    CheckReservedNames() {}
};

void generateRuntime(const IR::P4Program* program,
                       const BFN_Options& options) {
    // If the user didn't ask for us to generate P4Runtime, skip the analysis.
    bool doNotGenerateP4Info = options.p4RuntimeFile.isNullOrEmpty() &&
            options.p4RuntimeFiles.isNullOrEmpty() &&
            options.p4RuntimeEntriesFile.isNullOrEmpty() &&
            options.p4RuntimeEntriesFiles.isNullOrEmpty() &&
            options.bfRtSchema.isNullOrEmpty();
    bool generateP4Info = !doNotGenerateP4Info;

    bool doNotGenerateBFRT = options.bfRtSchema.isNullOrEmpty();
    bool generateBFRT = !doNotGenerateBFRT;

    if (doNotGenerateP4Info && doNotGenerateBFRT) return;

    auto p4RuntimeSerializer = P4::P4RuntimeSerializer::get();

    // By design we can use the same architecture handler implementation for
    // both TNA and T2NA.
    p4RuntimeSerializer->registerArch("psa", new PSAArchHandlerBuilder());
    p4RuntimeSerializer->registerArch("tna", new TofinoArchHandlerBuilder());
    p4RuntimeSerializer->registerArch("t2na", new TofinoArchHandlerBuilder());
#if HAVE_CLOUDBREAK
    p4RuntimeSerializer->registerArch("t3na", new TofinoArchHandlerBuilder());
#endif
#if HAVE_FLATROCK
    p4RuntimeSerializer->registerArch("t5na", new TofinoArchHandlerBuilder());
#endif

    auto arch = P4::P4RuntimeSerializer::resolveArch(options);

    if (Log::verbose())
        std::cout << "Generating P4Runtime output for architecture " << arch << std::endl;

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

    // Generate P4Info o/p
    if (generateP4Info) {
        auto p4Runtime = p4RuntimeSerializer->generateP4Runtime(program, arch);

        if (options.p4RuntimeForceStdExterns) {
            auto p4RuntimeStd = convertToStdP4Runtime(p4Runtime);
            p4RuntimeSerializer->serializeP4RuntimeIfRequired(p4RuntimeStd, options);
        } else {
            p4RuntimeSerializer->serializeP4RuntimeIfRequired(p4Runtime, options);
        }
        if (::errorCount() > 0) return;
    }

    // Generate BFRT json o/p
    if (generateBFRT) {
        std::ostream* out = openFile(options.bfRtSchema, false);
        if (!out) {
            ::error("Couldn't open BF-RT schema file: %1%", options.bfRtSchema);
            return;
        }

        // New types must be eliminated to resolve their bitwidths to be
        // generated in BF-RT json.
        auto typeChecking = new BFN::TypeChecking(&refMap, &typeMap);
        program = program->apply(P4::EliminateNewtype(&refMap, &typeMap, typeChecking));
        program->apply(CheckReservedNames());

        auto p4Runtime = p4RuntimeSerializer->generateP4Runtime(program, arch);
        auto *bfrt = new BFRT::BFRuntimeSchemaGenerator(*p4Runtime.p4Info);
        bfrt->serializeBFRuntimeSchema(out);
        if (::errorCount() > 0) return;
    }
}

}  // namespace BFN
