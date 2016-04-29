#include "midend.h"
#include "midend/actionsInlining.h"
#include "midend/inlining.h"
#include "midend/moveDeclarations.h"
#include "midend/uniqueNames.h"
#include "midend/removeReturns.h"
#include "midend/moveConstructors.h"
#include "midend/actionSynthesis.h"
#include "frontends/common/typeMap.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/toP4/toP4.h"
#include "frontends/p4/simplify.h"
#include "frontends/p4/unusedDeclarations.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4/strengthReduction.h"
#include "common/blockmap.h"

Tofino::MidEnd::MidEnd(const CompilerOptions& options)
        : isv1(options.isv1()), evaluator(options.isv1()) {
    stop_on_error = true;
    addPasses({
        // Give each local declaration a unique internal name
        new P4::UniqueNames(isv1),
        // Move all local declarations to the beginning
        new P4::MoveDeclarations(),
        new P4::ResolveReferences(&refMap, isv1),
        new P4::RemoveReturns(&refMap, true),
        // Move some constructor calls into temporaries
        new P4::MoveConstructors(isv1),
        new P4::ResolveReferences(&refMap, isv1),
        new P4::RemoveUnusedDeclarations(&refMap),
        &evaluator,
        new VisitFunctor([this](const IR::Node *n)->const IR::Node *{
            return evaluator.getBlockMap()->getMain() ? n : nullptr; }),
    });

    auto inliner = new P4::GeneralInliner();
    auto actInl = new P4::DiscoverActionsInlining(&actionsToInline, &refMap, &typeMap);
    actInl->allowDirectActionCalls = true;  // these will be eliminated by 'SynthesizeActions'

    auto midStream = options.dumpStream("midend");

    addPasses({
        new P4::DiscoverInlining(&toInline, evaluator.getBlockMap()),
        new P4::InlineDriver(&toInline, inliner, isv1),
        new P4::RemoveAllUnusedDeclarations(isv1),
        new P4::TypeChecking(&refMap, &typeMap, isv1),
        actInl,
        new P4::InlineActionsDriver(&actionsToInline, new P4::ActionsInliner(), isv1),
        new P4::RemoveAllUnusedDeclarations(isv1),
        new P4::SimplifyControlFlow(),
        new P4::ResolveReferences(&refMap, isv1),
        new P4::RemoveReturns(&refMap, false),  // remove exits
        new P4::TypeChecking(&refMap, &typeMap, isv1),
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::StrengthReduction(),
        new P4::MoveDeclarations(),  // more may have been introduced
        // Create actions for statements that can't be done in control blocks.
        new P4::TypeChecking(&refMap, &typeMap, isv1),
        new P4::SynthesizeActions(&refMap, &typeMap),
        // Move all stand-alone actions to custom tables
        new P4::TypeChecking(&refMap, &typeMap, isv1),
        new P4::MoveActionsToTables(&refMap, &typeMap),
        new P4::ToP4(midStream, options.file),
        &evaluator,
        new FillFromBlockMap(&evaluator),
    });
}
