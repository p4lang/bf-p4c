#include "midend.h"

#include "frontends/common/constantFolding.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "frontends/p4/moveDeclarations.h"
#include "frontends/p4/simplify.h"
#include "frontends/p4/simplifyParsers.h"
#include "frontends/p4/strengthReduction.h"
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
#include "midend/flattenHeaders.h"
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
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/midend/blockmap.h"
#include "bf-p4c/midend/check_header_alignment.h"
#include "bf-p4c/midend/elim_cast.h"
#include "bf-p4c/midend/check_unsupported.h"
#include "bf-p4c/midend/elim_typedef.h"
#include "bf-p4c/midend/simplify_emit_args.h"
#include "bf-p4c/midend/inline_subparser.h"
#include "bf-p4c/midend/normalize_params.h"
#include "bf-p4c/midend/rewrite_egress_intrinsic_metadata_header.h"
#include "bf-p4c/midend/simplify_nested_if.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/common/rewrite_flexible_struct.h"
#include "bf-p4c/ir/tofino_write_context.h"

namespace BFN {

/**
This class implements a policy suitable for the ConvertEnums pass.
The policy is: convert all enums that are not part of the architecture files.
Use 32-bit values for all enums.
*/
class EnumOn32Bits : public P4::ChooseEnumRepresentation {
    std::set<cstring> reserved_enums = {
            "MeterType_t", "MeterColor_t", "CounterType_t", "SelectorMode_t", "HashAlgorithm_t",
            "MathOp_t", "CloneType" };

    bool convert(const IR::Type_Enum* type) const override {
        LOG1("convert ? " << type->name);
        if (reserved_enums.count(type->name))
            return false;
        return true; }

    unsigned enumSize(unsigned) const override { return 32; }
};

/**
This class implements a policy suitable for the SynthesizeActions pass:
  - do not synthesize actions for the controls whose names are in the specified set.
    For example, we expect that the code in the deparser will not use any
    tables or actions.
  - do not combine statements with data dependencies (except on Hash.get) into a single action
  - do not combine uses of externs (other than Hash) into one action
  The hash exceptions above are because a common idiom is to use a hash function to hash some
  data and use the result as the index into a table execute method.  We prefer keeping that in
  one action as we can do it directly; if split it requires extra PHV (to hold the hash value)
  and an extra stage.

  It would probably be better to allow ActionSynthesis to combine stuff as much as possible and
  later split actions that don't work in a sinlge cycle.  We don't yet have a general action
  splitting/rewriting pass, however, and this is simpler for now.
*/
class ActionSynthesisPolicy : public P4::ActionSynthesisPolicy {
    // set of controls where actions are not synthesized
    const std::set<cstring> *skip;

    bool convert(const Visitor::Context *, const IR::P4Control* control) override {
        if (control->is<IR::BFN::TnaDeparser>()) {
            return false;
        }
        for (auto c : *skip)
            if (control->name == c)
                return false;
        return true;
    }

    static const IR::Type_Extern *externType(const IR::Type *type) {
        if (auto *spec = type->to<IR::Type_SpecializedCanonical>())
            type = spec->baseType;
        return type->to<IR::Type_Extern>(); }

    class FindPathsWritten : public Inspector, TofinoWriteContext {
        std::set<cstring>       &writes;
        bool preorder(const IR::PathExpression *pe) {
            if (isWrite()) writes.insert(pe->toString());
            return false; }
        bool preorder(const IR::Member *m) {
            if (isWrite()) writes.insert(m->toString());
            return false; }
        bool preorder(const IR::AssignmentStatement *assign) {
            // special case -- ignore writing the result of a 'hash.get' call to a var,
            // as we can use that directly in the same action (hash is computed in ixbar hash)
            if (auto *mc = assign->right->to<IR::MethodCallExpression>()) {
                if (auto *m = mc->method->to<IR::Member>()) {
                    if (auto *et = externType(m->expr->type)) {
                        if (et->name == "Hash" && m->member == "get") return false; } } }
            return true; }

     public:
        explicit FindPathsWritten(std::set<cstring> &w) : writes(w) {} };

    class DependsOnPaths : public Inspector {
        std::set<cstring>       &paths;
        bool                    rv = false;
        bool preorder(const IR::PathExpression *pe) {
            if (paths.count(pe->toString())) rv = true;
            return !rv; }
        bool preorder(const IR::Member *m) {
            if (paths.count(m->toString())) rv = true;
            return !rv; }
        bool preorder(const IR::Node *) { return !rv; }

     public:
        explicit operator bool() { return rv; }
        DependsOnPaths(const IR::Node *n, std::set<cstring> &p) : paths(p), rv(false) {
            n->apply(*this); } };

    class ReferencesExtern : public Inspector {
        bool                    rv = false;
        bool preorder(const IR::PathExpression *pe) {
            if (rv) return false;
            auto *et = externType(pe->type);
            if (et && et->name != "Hash") {
                rv = true; }
            return !rv; }
        bool preorder(const IR::Node *) { return !rv; }

     public:
        explicit operator bool() { return rv; }
        explicit ReferencesExtern(const IR::Node *n) { n->apply(*this); } };

    bool can_combine(const Visitor::Context *, const IR::BlockStatement *blk,
                     const IR::StatOrDecl *stmt) override {
        std::set<cstring>       writes;
        if (ReferencesExtern(blk) && ReferencesExtern(stmt)) return false;
        blk->apply(FindPathsWritten(writes));
        return !DependsOnPaths(stmt, writes); }

 public:
    explicit ActionSynthesisPolicy(const std::set<cstring> *skip) : skip(skip) { CHECK_NULL(skip); }
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
    if (!name->path->name.name.endsWith("Action") && name->path->name != "selector_action")
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

// FIXME -- perhaps just remove this pass altogether and check for unsupported
// div/mod in instruction selection.
class CompileTimeOperations : public P4::CompileTimeOperations {
    bool preorder(const IR::Declaration_Instance *di) {
#ifdef HAVE_JBAY
        // JBay supports (limited) div/mod in RegisterAction
        if (Device::currentDevice() == Device::JBAY) {
            if (auto st = di->type->to<IR::Type_Specialized>()) {
                if (st->baseType->path->name.name.endsWith("Action") ||
                    st->baseType->path->name == "selector_action")
                    return false; } }
#endif
        return true;
    }
};

class MidEndLast : public PassManager {
 public:
    MidEndLast() { setName("MidEndLast"); }
};

MidEnd::MidEnd(BFN_Options& options) {
    // we may come through this path even if the program is actually a P4 v1.0 program
    setName("MidEnd");;;
    refMap.setIsV1(true);
    auto typeChecking = new BFN::TypeChecking(&refMap, &typeMap);
    auto typeInference = new BFN::TypeInference(&refMap, &typeMap, true);
    auto evaluator = new BFN::EvaluatorPass(&refMap, &typeMap);
    auto skip_controls = new std::set<cstring>();
    cstring args_to_skip[] = { "ingress_deparser", "egress_deparser"};
    auto errorOnMethodCall = false;

    addPasses({
        new P4::EliminateNewtype(&refMap, &typeMap, typeChecking),
        new P4::EliminateSerEnums(&refMap, &typeMap, typeChecking),
        new BFN::TypeChecking(&refMap, &typeMap, true),
        new BFN::CheckUnsupported(&refMap, &typeMap),
        new BFN::CheckHeaderAlignment(&typeMap),
        new P4::RemoveActionParameters(&refMap, &typeMap, typeChecking),
        new P4::OrderArguments(&refMap, &typeMap, typeChecking),
        new BFN::ArchTranslation(&refMap, &typeMap, options),
        new P4::ConvertEnums(&refMap, &typeMap, new EnumOn32Bits(), typeChecking),
        new P4::EliminateTypedef(&refMap, &typeMap, typeChecking),
        new P4::SimplifyControlFlow(&refMap, &typeMap, typeChecking),
        new BFN::ElimCasts(&refMap, &typeMap),
        new P4::SimplifyKey(
            &refMap, &typeMap,
            new P4::OrPolicy(new P4::OrPolicy(new P4::IsValid(&refMap, &typeMap), new P4::IsMask()),
                             new BFN::IsPhase0()),
            typeChecking),
        new P4::RemoveExits(&refMap, &typeMap, typeChecking),
        new P4::ConstantFolding(&refMap, &typeMap, true, typeChecking),
        new P4::StrengthReduction(&refMap, &typeMap, typeChecking),
        new P4::SimplifySelectCases(&refMap, &typeMap, true, typeChecking),  // constant keysets
        new P4::ExpandLookahead(&refMap, &typeMap, typeChecking),
        new P4::ExpandEmit(&refMap, &typeMap, typeChecking),
        new P4::SimplifyParsers(&refMap),
        new P4::StrengthReduction(&refMap, &typeMap, typeChecking),
        new P4::EliminateTuples(&refMap, &typeMap, typeChecking, typeInference),
        new SimplifyEmitArgs(&refMap, &typeMap),
        new P4::SimplifyComparisons(&refMap, &typeMap, typeChecking),
        new InlineSubparserParameter(&refMap),  // run before CopyStructures
        // errorOnMethodCall argument in CopyStructures is defaulted to true.
        // This means methods or functions returning structs will be flagged as
        // an error. Here, we set this to false to allow such scenarios.
        // E.g. Phase0 extern function returns a header struct.
        new P4::CopyStructures(&refMap, &typeMap, errorOnMethodCall, typeChecking),
        new P4::NestedStructs(&refMap, &typeMap, typeChecking),
        new P4::SimplifySelectList(&refMap, &typeMap, typeChecking),
        new P4::RemoveSelectBooleans(&refMap, &typeMap, typeChecking),
        new P4::Predication(&refMap),
        new P4::MoveDeclarations(),  // more may have been introduced
        new P4::ConstantFolding(&refMap, &typeMap, true, typeChecking),
        new P4::SimplifyBitwise(),
        new P4::LocalCopyPropagation(&refMap, &typeMap, typeChecking, skipRegisterActionOutput),
        new P4::ConstantFolding(&refMap, &typeMap, true, typeChecking),
        new P4::StrengthReduction(&refMap, &typeMap, typeChecking),
        new P4::MoveDeclarations(),
        new P4::SimplifyNestedIf(&refMap, &typeMap, typeChecking),
        new P4::SimplifyControlFlow(&refMap, &typeMap, typeChecking),
        new CompileTimeOperations(),
        new P4::TableHit(&refMap, &typeMap, typeChecking),
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
        new P4::SynthesizeActions(&refMap, &typeMap,
                new ActionSynthesisPolicy(skip_controls), typeChecking),
        new P4::MoveActionsToTables(&refMap, &typeMap, typeChecking),
        (options.egress_intr_md_opt) ?
            new RewriteEgressIntrinsicMetadataHeader(&refMap, &typeMap) : nullptr,
        // must be done after copy structure, then we do not need to adjust
        // struct assignment. could be done in tna.cpp and t2na.cpp
        (options.arch == "tna" || options.arch == "t2na") ?
            new BFN::RewriteFlexibleStruct(&refMap, &typeMap) : nullptr,
        new RenameArchParams(&refMap, &typeMap),
        new FillFromBlockMap(&refMap, &typeMap),
        evaluator,
        new VisitFunctor([this, evaluator]() { toplevel = evaluator->getToplevelBlock(); }),
        new MidEndLast,
    });
}

}  // namespace BFN
