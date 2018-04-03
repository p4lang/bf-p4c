#include "bf-p4c/arch/native.h"
#include "bf-p4c/bf-p4c-options.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/cloner.h"

namespace {

/// @return true if `control` is the instantiation of the given standard control.
/// The standard control is identified by the name of the corresponding parameter
/// to the architecture package.
bool isStandardControl(cstring standardControlName,
                       const IR::P4Control* control,
                       P4::EvaluatorPass* evaluator) {
    BUG_CHECK(evaluator->getToplevelBlock(), "No top level block?");
    auto* package = evaluator->getToplevelBlock()->getMain();
    BUG_CHECK(package, "No main?");
    auto* standardControlBlock = package->findParameterValue(standardControlName);
    BUG_CHECK(standardControlBlock, "Couldn't find standard control %1%",
              standardControlName);
    BUG_CHECK(standardControlBlock->is<IR::ControlBlock>(),
              "Standard control %1% has unexpected type: %2%",
              standardControlName, standardControlBlock);
    auto* standardControl =
      standardControlBlock->to<IR::ControlBlock>()->container;
    return control == standardControl;
}

}  // namespace

namespace BFN {

/// Restore all `@optional` parameters to the controls specified by the
/// architecture.
struct RestoreOptionalParams : public Transform {
    explicit RestoreOptionalParams(P4::EvaluatorPass* evaluator)
      : evaluator(evaluator) { }

    IR::P4Control* preorder(IR::P4Control* control) override {
        prune();

        if (isStandardControl("ingress", getOriginal<IR::P4Control>(), evaluator))
            return restoreIngressOptionalParams(control);
        if (isStandardControl("egress", getOriginal<IR::P4Control>(), evaluator))
            return restoreEgressOptionalParams(control);
        return control;
    }

    IR::P4Control* restoreIngressOptionalParams(IR::P4Control* control) {
        auto* params = control->type->getApplyParameters();
        auto* paramList = new IR::ParameterList;
        ordered_map<cstring, cstring> tnaParams;

        auto* headers = params->parameters.at(0);
        tnaParams.emplace("hdr", headers->name);
        paramList->push_back(headers);

        auto* meta = params->parameters.at(1);
        tnaParams.emplace("md", meta->name);
        paramList->push_back(meta);

        auto* ig_intr_md = params->parameters.at(2);
        tnaParams.emplace("ig_intr_md", ig_intr_md->name);
        paramList->push_back(ig_intr_md);

        if (params->size() <= 3) {
            // add ig_intr_md_from_prsr
            auto* path = new IR::Path("ingress_intrinsic_metadata_from_parser_t");
            auto* type = new IR::Type_Name(path);
            auto* param = new IR::Parameter("ig_intr_md_from_prsr", IR::Direction::In, type);
            tnaParams.emplace("ig_intr_md_from_prsr", param->name);
            paramList->push_back(param);
        } else {
            auto* param = params->parameters.at(3);
            tnaParams.emplace("ig_intr_md_from_prsr", param->name);
            paramList->push_back(param);
        }

        if (params->size() <= 4) {
            // add ig_intr_md_for_tm
            auto* path = new IR::Path("ingress_intrinsic_metadata_for_tm_t");
            auto* type = new IR::Type_Name(path);
            auto* param = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::InOut, type);
            tnaParams.emplace("ig_intr_md_for_tm", param->name);
            paramList->push_back(param);
        } else {
            auto* param = params->parameters.at(4);
            tnaParams.emplace("ig_intr_md_for_tm", param->name);
            paramList->push_back(param);
        }

        if (params->size() <= 5) {
            // add ig_intr_md_for_mb
            auto* path = new IR::Path("ingress_intrinsic_metadata_for_mirror_buffer_t");
            auto* type = new IR::Type_Name(path);
            auto* param = new IR::Parameter("ig_intr_md_for_mb", IR::Direction::InOut, type);
            tnaParams.emplace("ig_intr_md_for_mb", param->name);
            paramList->push_back(param);
        } else {
            auto* param = params->parameters.at(5);
            tnaParams.emplace("ig_intr_md_for_mb", param->name);
            paramList->push_back(param);
        }

        if (params->size() <= 6) {
            // add ig_intr_md_for_dprsr
            auto* path = new IR::Path("ingress_intrinsic_metadata_for_deparser_t");
            auto* type = new IR::Type_Name(path);
            auto* param = new IR::Parameter("ig_intr_md_for_dprsr", IR::Direction::InOut, type);
            tnaParams.emplace("ig_intr_md_for_dprsr", param->name);
            paramList->push_back(param);
        } else {
            auto* param = params->parameters.at(6);
            tnaParams.emplace("ig_intr_md_for_dprsr", param->name);
            paramList->push_back(param);
        }
/*
        if (params->size() <= 7) {
            // add compiler_generated_metadata
            auto* path = new IR::Path("compiler_generated_metadata_t");
            auto* type = new IR::Type_Name(path);
            auto* param = new IR::Parameter("compiler_generated_meta", IR::Direction::InOut, type);
            tnaParams.emplace("compiler_generated_meta", param->name);
            paramList->push_back(param);
        } else {
            auto* param = params->parameters.at(7);
            tnaParams.emplace("compiler_generated_meta", param->name);
            paramList->push_back(param);
        }
*/
        auto* controlType = new IR::Type_Control(control->type->name, paramList);

        auto* result = new IR::BFN::TranslatedP4Control(control->srcInfo, control->name,
                                                controlType,
                                                control->constructorParams, control->controlLocals,
                                                control->body, tnaParams, INGRESS);
        return result;
    }

    IR::P4Control* restoreEgressOptionalParams(IR::P4Control* control) {
        auto* params = control->type->getApplyParameters();
        auto* paramList = new IR::ParameterList;
        ordered_map<cstring, cstring> tnaParams;

        auto* headers = params->parameters.at(0);
        tnaParams.emplace("hdr", headers->name);
        paramList->push_back(headers);

        auto* meta = params->parameters.at(1);
        tnaParams.emplace("md", meta->name);
        paramList->push_back(meta);

        auto* eg_intr_md = params->parameters.at(2);
        tnaParams.emplace("eg_intr_md", eg_intr_md->name);
        paramList->push_back(eg_intr_md);

        if (params->size() <= 3) {
            // add eg_intr_md_from_prsr
            auto* path = new IR::Path("egress_intrinsic_metadata_from_parser_t");
            auto* type = new IR::Type_Name(path);
            auto* param = new IR::Parameter("eg_intr_md_from_prsr", IR::Direction::In, type);
            tnaParams.emplace("eg_intr_md_from_prsr", param->name);
            paramList->push_back(param);
        } else {
            auto* param = params->parameters.at(3);
            tnaParams.emplace("eg_intr_md_from_prsr", param->name);
            paramList->push_back(param);
        }

        if (params->size() <= 4) {
            // add eg_intr_md_for_mb
            auto* path = new IR::Path("egress_intrinsic_metadata_for_mirror_buffer_t");
            auto* type = new IR::Type_Name(path);
            auto* param = new IR::Parameter("eg_intr_md_for_mb", IR::Direction::InOut, type);
            tnaParams.emplace("eg_intr_md_for_mb", param->name);
            paramList->push_back(param);
        } else {
            auto* param = params->parameters.at(4);
            tnaParams.emplace("eg_intr_md_for_mb", param->name);
            paramList->push_back(param);
        }

        if (params->size() <= 5) {
            // add eg_intr_md_for_oport
            auto* path = new IR::Path("egress_intrinsic_metadata_for_output_port_t");
            auto* type = new IR::Type_Name(path);
            auto* param = new IR::Parameter("eg_intr_md_for_oport", IR::Direction::InOut, type);
            tnaParams.emplace("eg_intr_md_for_oport", param->name);
            paramList->push_back(param);
        } else {
            auto* param = params->parameters.at(5);
            tnaParams.emplace("eg_intr_md_for_oport", param->name);
            paramList->push_back(param);
        }

        if (params->size() <= 6) {
            // add eg_intr_md_for_dprsr
            auto* path = new IR::Path("egress_intrinsic_metadata_for_deparser_t");
            auto* type = new IR::Type_Name(path);
            auto* param = new IR::Parameter("eg_intr_md_for_deparser", IR::Direction::InOut, type);
            tnaParams.emplace("eg_intr_md_for_dprsr", param->name);
            paramList->push_back(param);
        } else {
            auto* param = params->parameters.at(6);
            tnaParams.emplace("eg_intr_md_for_dprsr", param->name);
            paramList->push_back(param);
        }

        if (params->size() <= 7) {
            // add ig_intr_md
            auto* path = new IR::Path("ingress_intrinsic_metadata_t");
            auto* type = new IR::Type_Name(path);
            auto* param = new IR::Parameter("ig_intr_md", IR::Direction::InOut, type);
            tnaParams.emplace("ig_intr_md", param->name);
            paramList->push_back(param);
        } else {
            auto* param = params->parameters.at(7);
            tnaParams.emplace("ig_intr_md", param->name);
            paramList->push_back(param);
        }

        if (params->size() <= 8) {
            // add ig_intr_md_for_tm
            auto* path = new IR::Path("ingress_intrinsic_metadata_for_tm_t");
            auto* type = new IR::Type_Name(path);
            auto* param = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::InOut, type);
            tnaParams.emplace("ig_intr_md_for_tm", param->name);
            paramList->push_back(param);
        } else {
            auto* param = params->parameters.at(8);
            tnaParams.emplace("ig_intr_md_for_tm", param->name);
            paramList->push_back(param);
        }
/*
        if (params->size() <= 9) {
            // add compiler_generated_metadata
            auto* path = new IR::Path("compiler_generated_metadata_t");
            auto* type = new IR::Type_Name(path);
            auto* param = new IR::Parameter("compiler_generated_meta", IR::Direction::InOut, type);
            tnaParams.emplace("compiler_generated_meta", param->name);
            paramList->push_back(param);
        } else {
            auto* param = params->parameters.at(9);
            tnaParams.emplace("compiler_generated_meta", param->name);
            paramList->push_back(param);
        }
*/
        auto* controlType = new IR::Type_Control(control->type->name, paramList);

        return new IR::BFN::TranslatedP4Control(control->srcInfo, control->name, controlType,
                                                control->constructorParams, control->controlLocals,
                                                control->body, tnaParams, EGRESS);
    }

    P4::EvaluatorPass* evaluator;
};

struct MapPackageBlockToThread : Inspector {
    MapPackageBlockToThread(P4::EvaluatorPass* evaluator, IR::BFN::P4Thread *ingress,
                            IR::BFN::P4Thread *egress)
        : evaluator(evaluator), ingress(ingress), egress(egress) {
        setName("MapPackageBlockToThread");
    }

    bool preorder(const IR::P4Program* ) {
        auto toplevel = evaluator->getToplevelBlock();
        auto main = toplevel->getMain();
        if (auto blk = main->getParameterValue("ingress_parser")) {
            if (auto pb = blk->to<IR::ParserBlock>()) {
                ingress->parser = pb->container; }}
        if (auto blk = main->getParameterValue("ingress")) {
            if (auto cb = blk->to<IR::ControlBlock>()) {
                ingress->mau = cb->container; }}
        if (auto blk = main->getParameterValue("ingress_deparser")) {
            if (auto cb = blk->to<IR::ControlBlock>()) {
                ingress->deparser = cb->container; }}
        if (auto blk = main->getParameterValue("egress_parser")) {
            if (auto pb = blk->to<IR::ParserBlock>()) {
                egress->parser = pb->container; }}
        if (auto blk = main->getParameterValue("egress")) {
            if (auto cb = blk->to<IR::ControlBlock>()) {
                egress->mau = cb->container; }}
        if (auto blk = main->getParameterValue("egress_deparser")) {
            if (auto cb = blk->to<IR::ControlBlock>()) {
                egress->deparser = cb->container; }}
        return false;
    }

    P4::EvaluatorPass *evaluator;
    IR::BFN::P4Thread *ingress;
    IR::BFN::P4Thread *egress;
};

struct RewriteControlAndParserBlocks : Transform {
    RewriteControlAndParserBlocks(IR::BFN::P4Thread *ingress, IR::BFN::P4Thread *egress)
    : ingress(ingress), egress(egress) {
        CHECK_NULL(ingress); CHECK_NULL(egress);
    }

    const IR::Node* postorder(IR::P4Parser *node) override {
        auto orig = getOriginal();
        if (orig == ingress->parser) {
            auto rv = new IR::BFN::TranslatedP4Parser(
                node->srcInfo, node->name,
                node->type, node->constructorParams,
                node->parserLocals, node->states,
                {}, INGRESS);
            return rv;
        } else if (orig == egress->parser) {
            auto rv = new IR::BFN::TranslatedP4Parser(
                node->srcInfo, node->name,
                node->type, node->constructorParams,
                node->parserLocals, node->states,
                {}, EGRESS);
            return rv;
        } else {
            BUG("P4Parser is mutated after evaluation");
            return node;
        }
    }

    const IR::Node* postorder(IR::P4Control *node) override {
        auto orig = getOriginal();
        if (orig == ingress->mau) {
            auto rv = new IR::BFN::TranslatedP4Control(
                node->srcInfo, node->name, node->type,
                node->constructorParams, node->controlLocals,
                node->body, {}, INGRESS);
            return rv;
        } else if (orig == ingress->deparser) {
            auto rv = new IR::BFN::TranslatedP4Deparser(
                node->srcInfo, node->name, node->type,
                node->constructorParams, node->controlLocals,
                node->body, {}, INGRESS);
            return rv;
        } else if (orig == egress->mau) {
            auto rv = new IR::BFN::TranslatedP4Control(
                node->srcInfo, node->name, node->type,
                node->constructorParams, node->controlLocals,
                node->body, {}, EGRESS);
            return rv;
        } else if (orig == egress->deparser) {
            auto rv = new IR::BFN::TranslatedP4Deparser(
                node->srcInfo, node->name, node->type,
                node->constructorParams, node->controlLocals,
                node->body, {}, EGRESS);
            return rv;
        } else {
            BUG("P4Control is mutated after evaluation");
            return node;
        }
    }

    IR::BFN::P4Thread *ingress;
    IR::BFN::P4Thread *egress;
};

/// Rewrite P4Control and P4Parser blocks to TranslatedP4Deparser,
/// TranslatedP4Control and TranslatedP4Parser.
NormalizeNativeProgram::NormalizeNativeProgram(P4::ReferenceMap* refMap,
                                               P4::TypeMap* typeMap,
                                               BFN_Options& options) {
    setName("NormalizeNativeProgram");
    addDebugHook(options.getDebugHook());
    auto* evaluator = new P4::EvaluatorPass(refMap, typeMap);
    addPasses({
        evaluator,
        new RestoreOptionalParams(evaluator),
        new P4::ClonePathExpressions,
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
    });
}

LowerTofinoToStratum::LowerTofinoToStratum(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
                                           BFN_Options &options) {
    setName("LowerTofinoToStratum");
    addDebugHook(options.getDebugHook());
    auto ingress = new IR::BFN::P4Thread();
    auto egress = new IR::BFN::P4Thread();
    auto* evaluator = new P4::EvaluatorPass(refMap, typeMap);
    addPasses({
        evaluator,
        new MapPackageBlockToThread(evaluator, ingress, egress),
        new RewriteControlAndParserBlocks(ingress, egress),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
