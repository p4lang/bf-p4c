#ifndef BF_P4C_ARCH_ARCHITECTURE_H_
#define BF_P4C_ARCH_ARCHITECTURE_H_

#include <boost/algorithm/string.hpp>
#include <boost/optional.hpp>
#include <set>
#include "ir/ir.h"
#include "ir/namemap.h"
#include "lib/path.h"
#include "frontends/common/options.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/uniqueNames.h"
#include "frontends/p4/sideEffects.h"
#include "frontends/p4/methodInstance.h"
#include "midend/actionsInlining.h"
#include "midend/localizeActions.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/ir/gress.h"
#include "program_structure.h"

namespace BFN {

/// Find and remove extern method calls that the P4 programmer has requested by
/// excluded from translation using the `@dont_translate_extern_method` pragma.
/// Currently this pragma is only supported on actions; it takes as an argument
/// a list of strings that identify extern method calls to remove from the action
/// body.
struct RemoveExternMethodCallsExcludedByAnnotation : public Transform {
    const IR::MethodCallStatement*
    preorder(IR::MethodCallStatement* call) override {
        auto* action = findContext<IR::P4Action>();
        if (!action) return call;

        auto* callExpr = call->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(callExpr, "Malformed method call IR: %1%", call);

        auto* dontTranslate = action->getAnnotation("dont_translate_extern_method");
        if (!dontTranslate) return call;
        for (auto* excluded : dontTranslate->expr) {
            auto* excludedMethod = excluded->to<IR::StringLiteral>();
            if (!excludedMethod) {
                ::error("Non-string argument to @dont_translate_extern_method: "
                        "%1%", excluded);
                return call;
            }

            if (excludedMethod->value == callExpr->toString()) {
                ::warning("Excluding method call from translation due to "
                          "@dont_translate_extern_method: %1%", call);
                return nullptr;
            }
        }

        return call;
    }
};

/// The translation pass only renames intrinsic metadata. If the width of the
/// metadata is also changed after the translation, then this pass will insert
/// appropriate cast to the RHS of the assignment.
class CastFixup : public Transform {
    ProgramStructure* structure;

 public:
    explicit CastFixup(ProgramStructure* structure)
            : structure(structure) { CHECK_NULL(structure); setName("CastFixup"); }
    const IR::AssignmentStatement* postorder(IR::AssignmentStatement* node) override {
        auto left = node->left;
        auto right = node->right;

        if (auto mem = left->to<IR::Member>()) {
            if (auto path = mem->expr->to<IR::PathExpression>()) {
                MetadataField field{path->path->name, mem->member.name};
                auto it = structure->metadataTypeMap.find(field);
                if (it != structure->metadataTypeMap.end()) {
                    auto type = IR::Type::Bits::get(it->second);
                    if (type != right->type) {
                        if (right->type->is<IR::Type_Boolean>()) {
                            if (right->to<IR::BoolLiteral>()->value == true) {
                                right = new IR::Constant(type, 1);
                            } else {
                                right = new IR::Constant(type, 0);
                            }
                        } else {
                            right = new IR::Cast(type, right);
                        }
                        return new IR::AssignmentStatement(node->srcInfo, left, right);
                    }
                }
            }
        }
        return node;
    }
};

class GenerateTofinoProgram : public Transform {
    ProgramStructure* structure;
 public:
    explicit GenerateTofinoProgram(ProgramStructure* structure)
            : structure(structure) { CHECK_NULL(structure); setName("GenerateTofinoProgram"); }
    //
    const IR::Node* preorder(IR::P4Program* program) override {
        prune();
        auto *rv = structure->create(program);
        LOG1("program" << program);
        return rv;
    }
};

class TranslationFirst : public PassManager {
 public:
    TranslationFirst() { setName("TranslationFirst"); }
};

class TranslationLast : public PassManager {
 public:
    TranslationLast() { setName("TranslationLast"); }
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_ARCHITECTURE_H_ */
