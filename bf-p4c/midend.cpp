#include "midend.h"

#include "frontends/common/constantFolding.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "frontends/p4/moveDeclarations.h"
#include "frontends/p4/simplify.h"
#include "frontends/p4/simplifyDefUse.h"
#include "frontends/p4/simplifyParsers.h"
#include "frontends/p4/strengthReduction.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/unusedDeclarations.h"
#include "midend/actionSynthesis.h"
#include "midend/compileTimeOps.h"
#include "midend/complexComparison.h"
#include "midend/convertEnums.h"
#include "midend/copyStructures.h"
#include "midend/defuse.h"
#include "midend/eliminateTuples.h"
#include "midend/eliminateNewtype.h"
#include "midend/eliminateSerEnums.h"
#include "midend/eliminateTypedefs.h"
#include "midend/expandEmit.h"
#include "midend/expandLookahead.h"
#include "midend/flattenInterfaceStructs.h"
#include "midend/local_copyprop.h"
#include "midend/nestedStructs.h"
#include "midend/move_to_egress.h"
#include "midend/orderArguments.h"
#include "midend/predication.h"
#include "midend/remove_action_params.h"
#include "midend/removeLeftSlices.h"
#include "midend/removeMiss.h"
#include "midend/removeSelectBooleans.h"
#include "midend/removeExits.h"
#include "midend/replaceSelectRange.h"
#include "midend/simplifyBitwise.h"
#include "midend/simplifyKey.h"
#include "midend/simplifySelectCases.h"
#include "midend/simplifySelectList.h"
#include "midend/alpm.h"
#include "midend/tableHit.h"
#include "midend/validateProperties.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/midend/action_synthesis_policy.h"
#include "bf-p4c/midend/annotate_with_in_hash.h"
#include "bf-p4c/midend/blockmap.h"
#include "bf-p4c/midend/check_header_alignment.h"
#include "bf-p4c/midend/check_unsupported.h"
#include "bf-p4c/midend/check_design_pattern.h"
#include "bf-p4c/midend/copy_block_pragmas.h"
#include "bf-p4c/midend/copy_header.h"
#include "bf-p4c/midend/elim_cast.h"
#include "bf-p4c/midend/fold_constant_hashes.h"
#include "bf-p4c/midend/desugar_varbit_extract.h"
#include "bf-p4c/midend/normalize_params.h"
#include "bf-p4c/midend/ping_pong_generation.h"
#include "bf-p4c/midend/register_read_write.h"
#include "bf-p4c/midend/rewrite_egress_intrinsic_metadata_header.h"
#include "bf-p4c/midend/rewrite_flexible_header.h"
#include "bf-p4c/midend/simplifyIfStatement.h"
#include "bf-p4c/midend/simplify_nested_if.h"
#include "bf-p4c/midend/simplify_args.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/midend/simplify_key_policy.h"
#include "bf-p4c/control-plane/tofino_p4runtime.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/logging/source_info_logging.h"

namespace BFN {

/**
 * This class implements a pass to convert optional match type to ternary.
 * Optional is a special case of ternary which allows for 2 cases
 *
 * 1) Is Valid = true , mask = all 1's (Exact Match)
 * 2) Is Valid = false, mask = dont care (Any value) 
 *
 * The control plane API does the necessary checks for valid use cases and
 * programs the ternary accordingly.
 *
 * Currently the support exists in PSA & V1Model. But as the pass is common to
 * all archs, in future if TNA needs this simply add 'optional' to tofino.p4
 * JIRAs - P4C-3592 / DRV-4743
 *
 * BF-RT API Additions:
 * https://wiki.ith.intel.com/display/BXDHOME/BFRT+Optional+match+support
 */
class OptionalToTernaryMatchTypeConverter: public Transform {
 public:
    const IR::Node* postorder(IR::PathExpression *path) {
        auto *key = findContext<IR::KeyElement>();
        if (!key) return path;
        LOG3("OptionalToTernaryMatchTypeConverter postorder : " << path);
        if (path->toString() != "optional") return path;
        return new IR::PathExpression("ternary");
    }
};


/**
This class implements a policy suitable for the ConvertEnums pass.
The policy is: convert all enums that are not part of the architecture files, and
are not used as the output type from a RegisterAction.  These latter enums will get
a special encoding later to be compatible with the stateful alu predicate output.
Use 32-bit values for all enums.
*/
class EnumOn32Bits : public P4::ChooseEnumRepresentation {
    std::set<cstring> reserved_enums = {
            "MeterType_t", "MeterColor_t", "CounterType_t", "SelectorMode_t", "HashAlgorithm_t",
            "MathOp_t", "CloneType", "ChecksumAlgorithm_t" };

    bool convert(const IR::Type_Enum* type) const override {
        LOG1("convert ? " << type->name);
        if (reserved_enums.count(type->name))
            return false;
        return true; }

    unsigned enumSize(unsigned) const override { return 32; }

 public:
    class FindStatefulEnumOutputs : public Inspector {
        EnumOn32Bits &self;
        void postorder(const IR::Declaration_Instance *di) {
            if (auto *ts = di->type->to<IR::Type_Specialized>()) {
                auto bt = ts->baseType->toString();
                unsigned idx = 0;
                if (bt.startsWith("DirectRegisterAction")) {
                    idx = 1;
                } else if (bt.startsWith("RegisterAction")) {
                    idx = 2;
                } else if (bt.startsWith("LearnAction")) {
                    idx = 3;
                } else if (bt.startsWith("MinMaxAction")) {
                    idx = 2;
                } else {
                    return; }
                while (idx < ts->arguments->size()) {
                    auto return_type = ts->arguments->at(idx);
                    if (return_type->is<IR::Type_Name>())
                        self.reserved_enums.insert(return_type->toString());
                    ++idx; }
            }
        }

     public:
        explicit FindStatefulEnumOutputs(EnumOn32Bits &self) : self(self) {}
    };
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
    if (!name->path->name.name.endsWith("Action"))
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

bool skipFlexibleHeader(const Visitor::Context *, const IR::Type_StructLike* e) {
    if (e->getAnnotation("flexible"))
        return false;
    return true;
}

// FIXME -- perhaps just remove this pass altogether and check for unsupported
// div/mod in instruction selection.
class CompileTimeOperations : public P4::CompileTimeOperations {
    bool preorder(const IR::Declaration_Instance *di) {
#ifdef HAVE_JBAY
        // JBay supports (limited) div/mod in RegisterAction
        if (Device::currentDevice() == Device::JBAY
#if HAVE_CLOUDBREAK
            || Device::currentDevice() == Device::CLOUDBREAK
#endif /* HAVE_CLOUDBREAK */
        ) {
            if (auto st = di->type->to<IR::Type_Specialized>()) {
                if (st->baseType->path->name.name.endsWith("Action"))
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
    setName("MidEnd");
    refMap.setIsV1(true);
    auto typeChecking = new BFN::TypeChecking(&refMap, &typeMap);
    auto typeInference = new BFN::TypeInference(&refMap, &typeMap, true);
    auto evaluator = new BFN::EvaluatorPass(&refMap, &typeMap);
    auto skip_controls = new std::set<cstring>();
    cstring args_to_skip[] = { "ingress_deparser", "egress_deparser"};
    auto *enum_policy = new EnumOn32Bits;

    sourceInfoLogging = new CollectSourceInfoLogging(refMap);

    addPasses({
        new P4::RemoveMiss(&refMap, &typeMap),
        new P4::EliminateNewtype(&refMap, &typeMap, typeChecking),
        new P4::EliminateSerEnums(&refMap, &typeMap, typeChecking),
        new BFN::TypeChecking(&refMap, &typeMap, true),
        new BFN::CheckUnsupported(&refMap, &typeMap),
        new BFN::RemoveActionParameters(&refMap, &typeMap, typeChecking),
        new P4::OrderArguments(&refMap, &typeMap, typeChecking),
        new BFN::OptionalToTernaryMatchTypeConverter(),
        new BFN::ArchTranslation(&refMap, &typeMap, options),
        new BFN::TypeChecking(&refMap, &typeMap, true),
        new BFN::CheckDesignPattern(&refMap, &typeMap),  // add checks for p4 design pattern here.
        new BFN::SetDefaultSize(true /* warn */),  // set default table size to 512 if not set.
        new EnumOn32Bits::FindStatefulEnumOutputs(*enum_policy),
        new P4::ConvertEnums(&refMap, &typeMap, enum_policy, typeChecking),
        new P4::ConstantFolding(&refMap, &typeMap, true, typeChecking),
        new P4::EliminateTypedef(&refMap, &typeMap, typeChecking),
        new P4::SimplifyControlFlow(&refMap, &typeMap, typeChecking),
        new P4::SimplifyKey(&refMap, &typeMap,
            BFN::KeyIsSimple::getPolicy(refMap, typeMap), typeChecking),
        Device::currentDevice() != Device::TOFINO || options.disable_direct_exit ?
            new P4::RemoveExits(&refMap, &typeMap, typeChecking) : nullptr,
        new P4::ConstantFolding(&refMap, &typeMap, true, typeChecking),
        new BFN::ElimCasts(&refMap, &typeMap),
        new BFN::AlpmImplementation(&refMap, &typeMap),
        new BFN::TypeChecking(&refMap, &typeMap, true),
        new P4::StrengthReduction(&refMap, &typeMap, typeChecking),
        new P4::SimplifySelectCases(&refMap, &typeMap, true, typeChecking),  // constant keysets
        new P4::ExpandLookahead(&refMap, &typeMap, typeChecking),
        new P4::ExpandEmit(&refMap, &typeMap, typeChecking),
        new P4::SimplifyParsers(&refMap),
        new P4::ReplaceSelectRange(&refMap, &typeMap),
        new P4::StrengthReduction(&refMap, &typeMap, typeChecking),
        new P4::EliminateTuples(&refMap, &typeMap, typeChecking, typeInference),
        new P4::SimplifyComparisons(&refMap, &typeMap, typeChecking),
        new BFN::CopyHeaders(&refMap, &typeMap, typeChecking),
        // must run after copy structure
        new P4::SimplifyIfStatement(&refMap, &typeMap),
        new RewriteFlexibleStruct(&refMap, &typeMap),
        new SimplifyEmitArgs(&refMap, &typeMap),
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
#if BAREFOOT_INTERNAL
        new ComputeDefUse,  // otherwise unused; testing for CI coverage
#endif
#if HAVE_FLATROCK
        Device::currentDevice() == Device::FLATROCK ? new MoveToEgress(evaluator) : 0,
#endif
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
                new ActionSynthesisPolicy(skip_controls, &refMap, &typeMap), typeChecking),
        new P4::MoveActionsToTables(&refMap, &typeMap, typeChecking),
        new CopyBlockPragmas(&refMap, &typeMap, typeChecking, {"stage"}),
        (options.egress_intr_md_opt) ?
            new RewriteEgressIntrinsicMetadataHeader(&refMap, &typeMap) : nullptr,
        new DesugarVarbitExtract(&refMap, &typeMap),
        new PingPongGeneration(&refMap, &typeMap),
        new RegisterReadWrite(&refMap, &typeMap, typeChecking),
        new BFN::AnnotateWithInHash(&refMap, &typeMap, typeChecking),
        new BFN::FoldConstantHashes(&refMap, &typeMap, typeChecking),

        // Collects source info for logging. Call this after all transformations are complete.
        sourceInfoLogging,

        new MidEndLast,
    });
}

}  // namespace BFN
