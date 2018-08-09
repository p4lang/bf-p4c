#include "midend.h"

#include "frontends/common/constantFolding.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "frontends/p4/moveDeclarations.h"
#include "frontends/p4/simplify.h"
#include "frontends/p4/simplifyParsers.h"
#include "frontends/p4/strengthReduction.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/unusedDeclarations.h"
#include "midend/actionSynthesis.h"
#include "midend/compileTimeOps.h"
#include "midend/complexComparison.h"
#include "midend/convertEnums.h"
#include "midend/copyStructures.h"
#include "midend/eliminateTuples.h"
#include "midend/eliminateNewtype.h"
#include "midend/eliminateSerEnums.h"
#include "midend/expandEmit.h"
#include "midend/expandLookahead.h"
#include "midend/local_copyprop.h"
#include "midend/nestedStructs.h"
#include "midend/orderArguments.h"
#include "midend/predication.h"
#include "midend/removeLeftSlices.h"
#include "midend/removeParameters.h"
#include "midend/removeSelectBooleans.h"
#include "midend/removeExits.h"
#include "midend/simplifyBitwise.h"
#include "midend/simplifyKey.h"
#include "midend/simplifySelectCases.h"
#include "midend/simplifySelectList.h"
#include "midend/tableHit.h"
#include "midend/validateProperties.h"
#include "common/blockmap.h"
#include "common/check_header_alignment.h"
#include "common/flatten_emit_args.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/common/normalize_params.h"
#include "bf-p4c/parde/unroll_parser_counter.h"
#include "bf-p4c/parde/inline_subparser.h"

namespace BFN {

/**
This class implements a policy suitable for the ConvertEnums pass.
The policy is: convert all enums that are not part of the architecture files.
Use 32-bit values for all enums.
*/
class EnumOn32Bits : public P4::ChooseEnumRepresentation {
    bool convert(const IR::Type_Enum* type) const override {
        if (type->srcInfo.isValid()) {
            auto sourceFile = type->srcInfo.getSourceFile();
            if (sourceFile.endsWith("v1model.p4") ||
                sourceFile.endsWith("psa.p4") ||
                sourceFile.endsWith("tofino.p4") ||
                sourceFile.endsWith("tofino2.p4") ||
                sourceFile.endsWith("stratum.p4"))
                // Don't convert any of the standard enums
                return false;
        }
        return true;
    }
    unsigned enumSize(unsigned) const override
    { return 32; }
};

/**
This class implements a policy suitable for the SynthesizeActions pass.
The policy is: do not synthesize actions for the controls whose names
are in the specified set.
For example, we expect that the code in the deparser will not use any
tables or actions.
*/
class SkipControls : public P4::ActionSynthesisPolicy {
    // set of controls where actions are not synthesized
    const std::set<cstring> *skip;

 public:
    explicit SkipControls(const std::set<cstring> *skip) : skip(skip) { CHECK_NULL(skip); }
    bool convert(const IR::P4Control* control) const {
        if (control->is<IR::BFN::TranslatedP4Deparser>()) {
            return false;
        }
        for (auto c : *skip)
            if (control->name == c)
                return false;
        return true;
    }
};

class IsPhase0 : public P4::KeyIsSimple {
 public:
    IsPhase0() { }

    bool isSimple(const IR::Expression *, const Visitor::Context *ctxt) override {
        while (true) {
            if (ctxt == nullptr)
                return false;
            auto *n = ctxt->node;
            if (n->is<IR::P4Program>())
                return false;
            if (auto table = n->to<IR::P4Table>()) {
                auto annot = table->getAnnotations();
                if (annot->getSingle("phase0")) {
                    return true;
                }
                return false;
            }
            ctxt = ctxt->parent;
        }
        return false;
    }
};


/**
 * This function implements a policy suitable for the LocalCopyPropagation pass.
 * The policy is: do not local copy propagate for assignment statement
 * setting the output param of a register action.
 * This function returns true if the localCopyPropagation should be enabled;
 * It returns false if the localCopyPropagation should be disabled for the current statement.
 */
template <class T> inline const T *findContext(const Visitor::Context *c) {
    while ((c = c->parent))
        if (auto *rv = dynamic_cast<const T *>(c->node)) return rv;
    return nullptr; }

bool skipRegisterActionOutput(const Visitor::Context *ctxt, const IR::Expression *) {
    auto c = findContext<IR::Declaration_Instance>(ctxt);
    if (!c) return true;

    auto type = c->type->to<IR::Type_Specialized>();
    if (!type) return true;

    auto name = type->baseType->to<IR::Type_Name>();
    if (name->path->name != "RegisterAction" &&
        name->path->name != "LearnAction" &&
        name->path->name != "selector_action")
        return true;

    auto f = findContext<IR::Function>(ctxt);
    if (!f) return true;

    auto method = f->type->to<IR::Type_Method>();
    if (!method) return true;

    auto params = method->parameters->to<IR::ParameterList>();
    if (!params) return true;

    auto assign = dynamic_cast<const IR::AssignmentStatement*>(ctxt->parent->node);
    if (!assign) return true;

    auto dest_path = assign->left->to<IR::PathExpression>();
    if (!dest_path) return true;

    for (unsigned i = 1; i < params->size(); ++i)
        if (auto param = params->parameters.at(i)->to<IR::Parameter>())
            if (dest_path->path->name == param->name)
                return false;

    return true;
}

class MidEndLast : public PassManager {
 public:
    MidEndLast() { setName("MidEndLast"); }
};

MidEnd::MidEnd(BFN_Options& options) {
    // we may come through this path even if the program is actually a P4 v1.0 program
    setName("MidEnd");;;
    refMap.setIsV1(true);
    auto evaluator = new P4::EvaluatorPass(&refMap, &typeMap);
    auto skip_controls = new std::set<cstring>();
    cstring args_to_skip[] = { "ingress_deparser", "egress_deparser"};

    addPasses({
        new P4::EliminateNewtype(&refMap, &typeMap),
        new P4::EliminateSerEnums(&refMap, &typeMap),
        new P4::TypeChecking(&refMap, &typeMap, true),
        new BFN::CheckHeaderAlignment(&typeMap),
        new P4::ConvertEnums(&refMap, &typeMap, new EnumOn32Bits()),
        new P4::RemoveActionParameters(&refMap, &typeMap),
        new P4::OrderArguments(&refMap, &typeMap),
        new BFN::ArchTranslation(&refMap, &typeMap, options),
        new P4::SimplifyControlFlow(&refMap, &typeMap),
        new P4::SimplifyKey(
            &refMap, &typeMap,
            new P4::OrPolicy(new P4::OrPolicy(new P4::IsValid(&refMap, &typeMap), new P4::IsMask()),
                             new BFN::IsPhase0())),
        new P4::RemoveExits(&refMap, &typeMap),
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::StrengthReduction(),
        new P4::SimplifySelectCases(&refMap, &typeMap, true),  // constant keysets
        new P4::ExpandLookahead(&refMap, &typeMap),
        new P4::ExpandEmit(&refMap, &typeMap),
        new P4::SimplifyParsers(&refMap),
        new P4::StrengthReduction(),
        new P4::EliminateTuples(&refMap, &typeMap),
        new P4::SimplifyComparisons(&refMap, &typeMap),
        new InlineSubparserParameter(&refMap),  // run before CopyStructures
        new P4::CopyStructures(&refMap, &typeMap),
        new P4::NestedStructs(&refMap, &typeMap),
        new P4::SimplifySelectList(&refMap, &typeMap),
        new P4::RemoveSelectBooleans(&refMap, &typeMap),
        new P4::Predication(&refMap),
        new P4::MoveDeclarations(),  // more may have been introduced
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::SimplifyBitwise(),
        new P4::LocalCopyPropagation(&refMap, &typeMap, skipRegisterActionOutput),
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::StrengthReduction(),
        new P4::MoveDeclarations(),
        (options.arch == "psa")
            ? new P4::ValidateTableProperties({"implementation", "size", "psa_direct_counters",
                                               "psa_direct_meters", "idle_timeout"})
            : nullptr,
        (options.arch == "v1model")
            ? new P4::ValidateTableProperties(
                  {"implementation", "size", "counters", "meters", "idle_timeout"})
            : nullptr,
        (options.arch == "tna")
            ? new P4::ValidateTableProperties({"implementation", "size", "counters", "meters",
                                               "filters", "idle_timeout", "registers"})
            : nullptr,
        new P4::SimplifyControlFlow(&refMap, &typeMap),
        new P4::CompileTimeOperations(),
        new P4::TableHit(&refMap, &typeMap),
        evaluator,
        new VisitFunctor([=](const IR::Node *root) -> const IR::Node * {
            auto toplevel = evaluator->getToplevelBlock();
            auto main = toplevel->getMain();
            if (main == nullptr)
                // nothing further to do
                return nullptr;
            for (auto arg : args_to_skip) {
                if (!main->getConstructorParameters()->getDeclByName(arg))
                    continue;
                if (auto a = main->getParameterValue(arg))
                    if (auto ctrl = a->to<IR::ControlBlock>())
                        skip_controls->emplace(ctrl->container->name);
            }
            return root;
        }),
        new P4::SynthesizeActions(&refMap, &typeMap, new SkipControls(skip_controls)),
        new P4::MoveActionsToTables(&refMap, &typeMap),
        new P4::UniqueNames(&refMap),
        new P4::UniqueParameters(&refMap, &typeMap),
        new P4::TypeChecking(&refMap, &typeMap, true),
        evaluator,
        new VisitFunctor([this, evaluator]() { toplevel = evaluator->getToplevelBlock(); }),
        new NormalizeParams(&refMap, &typeMap, toplevel),
        new P4::TypeChecking(&refMap, &typeMap, true),
        new FillFromBlockMap(&refMap, &typeMap),
        new FlattenEmitArgs(),
        new UnrollParserCounter(&refMap, &typeMap),
        evaluator,
        new VisitFunctor([this, evaluator]() { toplevel = evaluator->getToplevelBlock(); }),
        new MidEndLast,
    });
}

}  // namespace BFN
