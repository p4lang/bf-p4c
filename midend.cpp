#include "midend.h"
#include "midend/actionsInlining.h"
#include "midend/inlining.h"
#include "midend/moveDeclarations.h"
#include "midend/uniqueNames.h"
#include "midend/removeReturns.h"
#include "midend/moveConstructors.h"
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

Tofino::MidEnd::MidEnd(bool v1) : isv1(v1), evaluator0(v1), evaluator1(v1) {
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
        &evaluator0,
        new VisitFunctor([this](const IR::Node *n)->const IR::Node *{
            return evaluator0.getBlockMap()->getMain() ? n : nullptr; }),
    });

    auto inliner = new P4::GeneralInliner();
    auto actInl = new P4::DiscoverActionsInlining(&actionsToInline, &refMap, &typeMap);
    actInl->allowDirectActionCalls = false;

    addPasses({
        new P4::DiscoverInlining(&toInline, evaluator0.getBlockMap()),
        new P4::InlineDriver(&toInline, inliner, isv1),
        new PassRepeated {
            // remove useless callees
            new P4::ResolveReferences(&refMap, isv1),
            new P4::RemoveUnusedDeclarations(&refMap),
        },
        // new P4::ToP4(debugStream, options.file),
        new P4::ResolveReferences(&refMap, isv1),
        new P4::TypeChecker(&refMap, &typeMap, true, true),
        actInl,
        new P4::InlineActionsDriver(&actionsToInline, new P4::ActionsInliner(), isv1),
        new PassRepeated {
            new P4::ResolveReferences(&refMap, isv1),
            new P4::RemoveUnusedDeclarations(&refMap),
        },
        new P4::SimplifyControlFlow(),
        new P4::ResolveReferences(&refMap, isv1),
        new P4::TypeChecker(&refMap, &typeMap),
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::StrengthReduction(),
        new P4::UniqueNames(isv1),
        new P4::MoveDeclarations(),
        new P4::ResolveReferences(&refMap, isv1),
        new P4::RemoveReturns(&refMap, false),  // remove exits
        &evaluator1,
        new FillFromBlockMap(&evaluator1),
    });
}
