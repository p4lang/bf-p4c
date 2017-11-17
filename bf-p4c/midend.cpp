#include "midend.h"
#include "arch/native.h"
#include "arch/simple_switch.h"
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
#include "frontends/p4/uniqueNames.h"
#include "frontends/p4/unusedDeclarations.h"
#include "midend/actionsInlining.h"
#include "midend/actionSynthesis.h"
#include "midend/compileTimeOps.h"
#include "midend/convertEnums.h"
#include "midend/copyStructures.h"
#include "midend/eliminateTuples.h"
#include "midend/expandLookahead.h"
#include "midend/local_copyprop.h"
#include "midend/localizeActions.h"
#include "midend/moveConstructors.h"
#include "midend/nestedStructs.h"
#include "midend/predication.h"
#include "midend/removeLeftSlices.h"
#include "midend/removeParameters.h"
#include "midend/removeReturns.h"
#include "midend/simplifyKey.h"
#include "midend/simplifySelectCases.h"
#include "midend/simplifySelectList.h"
#include "midend/tableHit.h"
#include "midend/validateProperties.h"
#include "common/blockmap.h"
#include "common/check_header_alignment.h"

namespace BFN {

/**
This class implements a policy suitable for the ConvertEnums pass.
The policy is: convert all enums that are not part of the v1model.
Use 32-bit values for all enums.
*/
class EnumOn32Bits : public P4::ChooseEnumRepresentation {
    bool convert(const IR::Type_Enum* type) const override {
        if (type->srcInfo.isValid()) {
            unsigned line = type->srcInfo.getStart().getLineNumber();
            auto sfl = Util::InputSources::instance->getSourceLine(line);
            cstring sourceFile = sfl.fileName;
            if (sourceFile.endsWith(P4V1::V1Model::instance.file.name))
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
        if (skip->find(control->name) != skip->end())
            return false;
        return true;
    }
};

/**
 * Policy for SimplifyKey that treats a key as complex if it's not one of (1) a
 * simple lvalue, (2) a call to isValid(), or (3) a mask applied to a simple
 * lvalue.
 */
class NonMaskLeftValueOrIsValid : public P4::KeyIsComplex {
    P4::NonLeftValueOrIsValid nonLeftValueOrIsValid;
    P4::NonMaskLeftValue nonMaskLeftValue;
 public:
    NonMaskLeftValueOrIsValid(P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
        : nonLeftValueOrIsValid(refMap, typeMap), nonMaskLeftValue(typeMap)
    { }
    bool isTooComplex(const IR::Expression* expression) const override {
        return nonLeftValueOrIsValid.isTooComplex(expression) &&
               nonMaskLeftValue.isTooComplex(expression);
    }
};

class MidEndLast : public PassManager {
 public:
    MidEndLast() { setName("MidEndLast"); }
};

MidEnd::MidEnd(BFN_Options& options) {
    // we may come through this path even if the program is actually a P4 v1.0 program
    setName("MidEnd");
    refMap.setIsV1(true);
    auto evaluator = new P4::EvaluatorPass(&refMap, &typeMap);
    auto skip_controls = new std::set<cstring>();
    cstring args_to_skip[] = { "ingress_deparser", "egress_deparser"};

    addPasses({
        new P4::TypeChecking(&refMap, &typeMap, true),
        new BFN::CheckHeaderAlignment(&typeMap),
        new P4::ConvertEnums(&refMap, &typeMap, new EnumOn32Bits()),
        new P4::RemoveReturns(&refMap),
        new P4::MoveConstructors(&refMap),
        new P4::RemoveAllUnusedDeclarations(&refMap),
        new P4::ClearTypeMap(&typeMap),
        evaluator,
        new P4::Inline(&refMap, &typeMap, evaluator),
        // translate architecture after program inlining to
        // avoid handling abitrary parameters in user defined control blocks
        (options.arch == "v1model") ?
            new BFN::SimpleSwitchTranslation(&refMap, &typeMap, options /*map*/) : nullptr,
        (options.arch == "native") ?
            new BFN::NormalizeNativeProgram(&refMap, &typeMap, options /*map*/) : nullptr,
        new P4::InlineActions(&refMap, &typeMap),
        new P4::LocalizeAllActions(&refMap),
        new P4::UniqueNames(&refMap),
        new P4::UniqueParameters(&refMap, &typeMap),
        new P4::SimplifyControlFlow(&refMap, &typeMap),
        new P4::RemoveActionParameters(&refMap, &typeMap),
        new P4::SimplifyKey(&refMap, &typeMap,
                            new NonMaskLeftValueOrIsValid(&refMap, &typeMap)),
        new P4::RemoveExits(&refMap, &typeMap),
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::StrengthReduction(),
        new P4::SimplifySelectCases(&refMap, &typeMap, true),  // constant keysets
        new P4::ExpandLookahead(&refMap, &typeMap),
        new P4::SimplifyParsers(&refMap),
        new P4::StrengthReduction(),
        new P4::EliminateTuples(&refMap, &typeMap),

        new P4::CopyStructures(&refMap, &typeMap),
        new P4::NestedStructs(&refMap, &typeMap),
        new P4::SimplifySelectList(&refMap, &typeMap),
        new P4::Predication(&refMap),
        new P4::MoveDeclarations(),  // more may have been introduced
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::LocalCopyPropagation(&refMap, &typeMap),
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::StrengthReduction(),
        new P4::MoveDeclarations(),
        new P4::ValidateTableProperties({"implementation", "size", "counters",
                                         "meters", "size", "support_timeout"}),
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
        new P4::TypeChecking(&refMap, &typeMap, true),
        // XXX(zma) : assuming tofino & jbay have same arch for now
        (options.arch == "native") ? nullptr : new FillFromBlockMap(&refMap, &typeMap),
        evaluator,
        new VisitFunctor([this, evaluator]() { toplevel = evaluator->getToplevelBlock(); }),
        new MidEndLast
    });
}

}  // namespace BFN
