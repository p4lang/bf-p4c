#include "frontend.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/arch/fromv1.0/programStructure.h"
#include "bf-p4c/common/parse_annotations.h"
#include "bf-p4c/logging/event_logger.h"
#include "bf-p4c/lib/error_type.h"
#include "frontends/common/applyOptionsPragmas.h"
#include "frontends/common/options.h"
#include "frontends/common/parseInput.h"
#include "frontends/p4/frontend.h"
#include "frontends/p4/fromv1.0/converters.h"
#include "lib/error.h"

// TODO(MichalKekely): Probably better to actually expose the original
//          FindRecirculated and inherit from it, which will allow
//          to just rewrite the postorder function. Also it might
//          allow us to check which pass is the one we are looking
//          for better.
// This is a simple update of the original convertor that just allows
// recirculate to have parameter of action param/68, that we allow.
// In the original p4c converter the pass FindRecirculated does not allow this.
// All we do here is replace FindRecirculated pass with a updated pass that allows this
class FindRecirculatedAllowingPort : public Inspector {
    P4V1::ProgramStructure* structure;

    void add(const IR::Primitive* primitive, unsigned operand) {
        if (primitive->operands.size() <= operand)
            return;
        auto expression = primitive->operands.at(operand);
        if (!expression->is<IR::PathExpression>()) {
            ::error("%1%: expected a field list", expression);
            return;
        }
        auto nr = expression->to<IR::PathExpression>();
        auto fl = structure->field_lists.get(nr->path->name);
        if (fl == nullptr) {
            ::error("%1%: Expected a field list", expression);
            return;
        }
        LOG3("Recirculated " << nr->path->name);
        structure->allFieldLists.emplace(fl);
    }

 public:
    explicit FindRecirculatedAllowingPort(P4V1::ProgramStructure* structure): structure(structure)
    { CHECK_NULL(structure); setName("FindRecirculatedAllowingPort"); }

    void postorder(const IR::Primitive* primitive) override {
        if (primitive->name == "recirculate") {
            // exclude recirculate(68) and recirculate(local_port)
            auto operand = primitive->operands.at(0);
            if (operand->is<IR::Constant>() || operand->is<IR::ActionArg>()) {
                LOG3("Ignoring field list extraction for " << primitive);
            } else {
                add(primitive, 0);
            }
        } else if (primitive->name == "resubmit") {
            add(primitive, 0);
        } else if (primitive->name.startsWith("clone") && primitive->operands.size() == 2) {
            add(primitive, 1);
        }
    }
};
class ConverterAllowingRecirculate : public P4V1::Converter {
 public:
    ConverterAllowingRecirculate() : P4V1::Converter() {
        // At least some sanity check if the P4V1::Converter didn't change
        BUG_CHECK(passes.size() == 14, "Expected different passes in P4V1::Converter");
        // Replace 7th pass, which should be the FindRecirculated
        passes[6] = new FindRecirculatedAllowingPort(structure);
    }
};

const IR::P4Program* run_frontend() {
    // Initialize the Barefoot-specific error types, in case they aren't already initialized.
    BFN::ErrorType::getErrorTypes();

    auto& options = BackendOptions();
    auto hook = options.getDebugHook();

    const IR::P4Program* program = nullptr;
    if (options.arch == "tna" && options.langVersion == CompilerOptions::FrontendVersion::P4_14) {
        program = P4::parseP4File<P4V1::TnaConverter>(options);
    } else {
        // XXX(hanw): used by 14-to-v1model path, to be removed
        P4V1::Converter::createProgramStructure = P4V1::TNA_ProgramStructure::create;
        program = P4::parseP4File<ConverterAllowingRecirculate>(options);
    }
    if (!program || ::errorCount() > 0)
        return program;

    BFNOptionPragmaParser optionsPragmaParser;
    program->apply(P4::ApplyOptionsPragmas(optionsPragmaParser));

    auto frontend = P4::FrontEnd(BFN::ParseAnnotations());
    frontend.addDebugHook(hook);
    frontend.addDebugHook(EventLogger::getDebugHook());
    return frontend.run(options, program, options.skip_seo);
}
