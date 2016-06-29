#include "midend.h"
#include "midend/inlining.h"
#include "midend/moveDeclarations.h"
#include "midend/uniqueNames.h"
#include "midend/removeReturns.h"
#include "midend/moveConstructors.h"
#include "midend/actionSynthesis.h"
#include "midend/local_copyprop.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/toP4/toP4.h"
#include "frontends/p4/simplify.h"
#include "frontends/p4/unusedDeclarations.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4/strengthReduction.h"
#include "common/blockmap.h"

Tofino::MidEnd::MidEnd(const CompilerOptions& options)
        : isv1(options.isv1()), evaluator(&refMap, &typeMap) {
    stop_on_error = true;
    setName("Midend");
    addPasses({
        // Proper semantics for uninitialzed local variables in parser states:
        // headers must be invalidated
        new P4::TypeChecking(&refMap, &typeMap, false, isv1),
        new P4::ResetHeaders(&typeMap),
        // Give each local declaration a unique internal name
        new P4::UniqueNames(&refMap, isv1),
        // Move all local declarations to the beginning
        new P4::MoveDeclarations(),
        new P4::ResolveReferences(&refMap, isv1),
        new P4::RemoveReturns(&refMap),
        // Move some constructor calls into temporaries
        new P4::MoveConstructors(&refMap, isv1),
        new P4::ResolveReferences(&refMap, isv1),
        new P4::RemoveUnusedDeclarations(&refMap),
        new P4::TypeChecking(&refMap, &typeMap, false, isv1),
        &evaluator,
        new VisitFunctor([this](const IR::Node *n)->const IR::Node *{
            return evaluator.getToplevelBlock()->getMain() ? n : nullptr; }),
        new P4::DiscoverInlining(&toInline, &refMap, &typeMap, &evaluator),
        new P4::InlineDriver(&toInline, new P4::GeneralInliner(), isv1),
        new P4::RemoveAllUnusedDeclarations(&refMap, isv1),
        new P4::TypeChecking(&refMap, &typeMap, false, isv1),
        new P4::DiscoverActionsInlining(&actionsToInline, &refMap, &typeMap),
        new P4::InlineActionsDriver(&actionsToInline, new P4::ActionsInliner(), isv1),
        new P4::RemoveAllUnusedDeclarations(&refMap, isv1),
        new P4::TypeChecking(&refMap, &typeMap, false, isv1),
        new P4::SimplifyControlFlow(&refMap, &typeMap),
        new P4::TypeChecking(&refMap, &typeMap, false, isv1),
        new P4::RemoveExits(&refMap, &typeMap),
        new P4::TypeChecking(&refMap, &typeMap, false, isv1),
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::StrengthReduction(),
        new P4::TypeChecking(&refMap, &typeMap, false, isv1, true),
        new P4::LocalCopyPropagation(&typeMap),
        new P4::MoveDeclarations(),  // more may have been introduced
        // Create actions for statements that can't be done in control blocks.
        new P4::TypeChecking(&refMap, &typeMap, false, isv1),
        new P4::SynthesizeActions(&refMap, &typeMap),
        // Move all stand-alone actions to custom tables
        new P4::TypeChecking(&refMap, &typeMap, false, isv1),
        new P4::MoveActionsToTables(&refMap, &typeMap),
        new P4::TypeChecking(&refMap, &typeMap, false, isv1, true),
        &evaluator,
        new FillFromBlockMap(&refMap, &typeMap),
    });
}
