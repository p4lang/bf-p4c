/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "midend.h"
#include "backends/bmv2/inlining.h"
#include "frontends/common/constantFolding.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "frontends/p4/simplify.h"
#include "frontends/p4/strengthReduction.h"
#include "frontends/p4/toP4/toP4.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/unusedDeclarations.h"
#include "midend/actionsInlining.h"
#include "midend/actionSynthesis.h"
#include "midend/convertEnums.h"
#include "midend/local_copyprop.h"
#include "midend/localizeActions.h"
#include "midend/moveConstructors.h"
#include "midend/moveDeclarations.h"
#include "midend/removeLeftSlices.h"
#include "midend/removeParameters.h"
#include "midend/removeReturns.h"
#include "midend/resetHeaders.h"
#include "midend/simplifyExpressions.h"
#include "midend/simplifyKey.h"
#include "midend/simplifyParsers.h"
#include "midend/simplifySelect.h"
#include "midend/uniqueNames.h"


namespace Tofino {

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


MidEnd::MidEnd(CompilerOptions& options) {
    // we may come through this path even if the program is actually a P4 v1.0 program
    bool isv1 = options.isv1();
    auto evaluator = new P4::EvaluatorPass(&refMap, &typeMap, isv1);
    setName("MidEnd");

    addPasses({
        new P4::SimplifyParsers(&refMap, isv1),
        new P4::ConvertEnums(&refMap, &typeMap, isv1, new EnumOn32Bits()),
        new P4::ResetHeaders(&refMap, &typeMap, isv1),
        new P4::UniqueNames(&refMap, isv1),
        new P4::MoveDeclarations(),
        new P4::MoveInitializers(),
        new P4::SimplifyExpressions(&refMap, &typeMap, isv1),
        new P4::RemoveReturns(&refMap, isv1),
        new P4::MoveConstructors(&refMap, isv1),
        new P4::RemoveAllUnusedDeclarations(&refMap, isv1),
        new P4::ClearTypeMap(&typeMap),
        evaluator,

        new VisitFunctor([evaluator](const IR::Node *root) -> const IR::Node * {
            auto toplevel = evaluator->getToplevelBlock();
            if (toplevel->getMain() == nullptr)
                // nothing further to do
                return nullptr;
            return root; }),

        new P4::Inline(&refMap, &typeMap, evaluator, isv1),
        new P4::InlineActions(&refMap, &typeMap, isv1),
#if 0
        new P4::LocalizeAllActions(&refMap, isv1),
        new P4::UniqueParameters(&refMap, isv1),
        new P4::ClearTypeMap(&typeMap),
        new P4::SimplifyControlFlow(&refMap, &typeMap, isv1),
        new P4::RemoveParameters(&refMap, &typeMap, isv1),
        new P4::ClearTypeMap(&typeMap),
        new P4::SimplifyKey(&refMap, &typeMap, isv1,
                            new P4::NonLeftValue(&refMap, &typeMap)),
#endif
        new P4::ConstantFolding(&refMap, &typeMap, isv1),
        new P4::StrengthReduction(),
        new P4::SimplifySelect(&refMap, &typeMap, isv1, true), // constant keysets
        new P4::SimplifyParsers(&refMap, isv1),
        new P4::LocalCopyPropagation(&refMap, &typeMap, isv1),
        new P4::MoveDeclarations(),
        new P4::SimplifyControlFlow(&refMap, &typeMap, isv1),
        new P4::SynthesizeActions(&refMap, &typeMap, isv1),
        new P4::MoveActionsToTables(&refMap, &typeMap, isv1),

        new P4::TypeChecking(&refMap, &typeMap, isv1, true),
        evaluator,
    });
}

}  // namespace Tofino
