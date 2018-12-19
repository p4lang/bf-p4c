#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/cloner.h"
#include "midend/validateProperties.h"
#include "bf-p4c/arch/tna.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/arch/check_extern_invocation.h"

namespace BFN {

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

/// Restore all parameters to the controls and parsers as specified by the /
/// architecture.
struct RestoreParams: public Transform {
    explicit RestoreParams(BFN_Options &options, P4::EvaluatorPass* evaluator)
      : options(options), evaluator(evaluator) { }

    IR::BFN::TranslatedP4Control* preorder(IR::BFN::TranslatedP4Control* control) {
        auto* params = control->type->getApplyParameters();
        auto* paramList = new IR::ParameterList;
        ordered_map<cstring, cstring> tnaParams;

        if (control->thread == INGRESS) {
            prune();

            auto* headers = params->parameters.at(0);
            tnaParams.emplace("hdr", headers->name);

            auto* meta = params->parameters.at(1);
            tnaParams.emplace("ig_md", meta->name);

            auto* ig_intr_md = params->parameters.at(2);
            tnaParams.emplace("ig_intr_md", ig_intr_md->name);

            auto* ig_intr_md_from_prsr = params->parameters.at(3);
            tnaParams.emplace("ig_intr_md_from_prsr", ig_intr_md_from_prsr->name);

            auto* ig_intr_md_for_dprsr = params->parameters.at(4);
            tnaParams.emplace("ig_intr_md_for_dprsr", ig_intr_md_for_dprsr->name);

            auto* ig_intr_md_for_tm = params->parameters.at(5);
            tnaParams.emplace("ig_intr_md_for_tm", ig_intr_md_for_tm->name);

            // Check for optional ghost_intrinsic_metadata_t for t2na arch
            if (options.arch == "t2na" && params->parameters.size() > 6) {
                auto* gh_intr_md = params->parameters.at(6);
                tnaParams.emplace("gh_intr_md", gh_intr_md->name);
            }
        } else if (control->thread == EGRESS) {
            prune();

            auto* headers = params->parameters.at(0);
            tnaParams.emplace("hdr", headers->name);

            auto* meta = params->parameters.at(1);
            tnaParams.emplace("eg_md", meta->name);

            auto* eg_intr_md = params->parameters.at(2);
            tnaParams.emplace("eg_intr_md", eg_intr_md->name);

            auto* eg_intr_md_from_prsr = params->parameters.at(3);
            tnaParams.emplace("eg_intr_md_from_prsr", eg_intr_md_from_prsr->name);

            auto* eg_intr_md_for_dprsr = params->parameters.at(4);
            tnaParams.emplace("eg_intr_md_for_dprsr", eg_intr_md_for_dprsr->name);

            auto* eg_intr_md_for_oport = params->parameters.at(5);
            tnaParams.emplace("eg_intr_md_for_oport", eg_intr_md_for_oport->name);
        }

        return new IR::BFN::TranslatedP4Control(control->srcInfo, control->name,
                                                control->type,
                                                control->constructorParams, control->controlLocals,
                                                control->body, tnaParams, control->thread);
    }

    IR::BFN::TranslatedP4Parser* preorder(IR::BFN::TranslatedP4Parser* parser) {
        auto* params = parser->type->getApplyParameters();
        auto* paramList = new IR::ParameterList;
        ordered_map<cstring, cstring> tnaParams;

        if (parser->thread == INGRESS) {
            prune();

            auto* packet = params->parameters.at(0);
            tnaParams.emplace("pkt", packet->name);
            paramList->push_back(packet);

            auto* headers = params->parameters.at(1);
            tnaParams.emplace("hdr", headers->name);
            paramList->push_back(headers);

            auto* meta = params->parameters.at(2);
            tnaParams.emplace("ig_md", meta->name);
            paramList->push_back(meta);

            auto* ig_intr_md = params->parameters.at(3);
            tnaParams.emplace("ig_intr_md", ig_intr_md->name);
            paramList->push_back(ig_intr_md);
        } else if (parser->thread == EGRESS) {
            prune();

            auto* packet = params->parameters.at(0);
            tnaParams.emplace("pkt", packet->name);
            paramList->push_back(packet);

            auto* headers = params->parameters.at(1);
            tnaParams.emplace("hdr", headers->name);
            paramList->push_back(headers);

            auto* meta = params->parameters.at(2);
            tnaParams.emplace("eg_md", meta->name);
            paramList->push_back(meta);

            auto* eg_intr_md = params->parameters.at(3);
            tnaParams.emplace("eg_intr_md", eg_intr_md->name);
            paramList->push_back(eg_intr_md);
        }

        auto parser_type = new IR::Type_Parser(parser->type->name, paramList);
        return new IR::BFN::TranslatedP4Parser(parser->srcInfo, parser->name,
                                                parser_type,
                                                parser->constructorParams, parser->parserLocals,
                                                parser->states, tnaParams, parser->thread);
    }

    BFN_Options &options;
    P4::EvaluatorPass* evaluator;
};

struct RewriteControlAndParserBlocks : Transform {
    explicit RewriteControlAndParserBlocks(BlockInfoMapping *bmap)
        : bmap(bmap) {}

    const IR::Node* postorder(IR::P4Parser *node) override {
        auto orig = getOriginal();
        if (!bmap->count(orig)) {
            BUG("P4Parser is mutated after evaluation");
            return node;
        }
        auto binfo = bmap->at(orig);
        auto rv = new IR::BFN::TranslatedP4Parser(
            node->srcInfo, node->name,
            node->type, node->constructorParams,
            node->parserLocals, node->states,
            {}, binfo.gress);
        return rv;
    }

    const IR::Node* postorder(IR::P4Control *node) override {
        auto orig = getOriginal();
        if (!bmap->count(orig)) {
            BUG("P4Control is mutated after evaluation");
            return node;
        }
        auto binfo = bmap->at(orig);
        if (binfo.type == ArchBlockType::MAU) {
            auto rv = new IR::BFN::TranslatedP4Control(
                node->srcInfo, node->name, node->type,
                node->constructorParams, node->controlLocals,
                node->body, {}, binfo.gress);
            return rv;
        } else if (binfo.type == ArchBlockType::DEPARSER) {
            auto rv = new IR::BFN::TranslatedP4Deparser(
                node->srcInfo, node->name, node->type,
                node->constructorParams, node->controlLocals,
                node->body, {}, binfo.gress);
            return rv;
        }
        return node;
    }

    BlockInfoMapping *bmap;
};

class LoweringType : public Transform {
    std::map<cstring, unsigned> enum_encoding;

 public:
    LoweringType() {}

    // lower MeterColor_t to bit<2> because it is used
    const IR::Node* postorder(IR::Type_Enum* node) override {
        if (node->name == "MeterColor_t")
            enum_encoding.emplace(node->name, 2);
        return node;
    }

    const IR::Node* postorder(IR::Type_Name* node) override {
        auto name = node->path->name;
        if (enum_encoding.count(name)) {
            auto size = enum_encoding.at(name);
            return new IR::Type_Bits(size, false);
        }
        return node;
    }
};

/* XXX(hanw): annotation is used by the backend to generate a node
 * in context.json for driver consumption.
 * This is a short-team solution to reuse the implementation
 * in the backend from P4-14 phase0 support. A longer term
 * support needs to handle the to-be-finalized phase0 extractor
 * extern.
 */
class InsertPhaseZeroAnnotation : public Transform {
 public:
    InsertPhaseZeroAnnotation() { setName("InsertPhaseZeroAnnotation"); }

    cstring keyName;

 private:
    const IR::P4Program* preorder(IR::P4Program* program) override {
        auto* annos = new IR::Annotations();
        auto* layoutKind = new IR::StringLiteral(IR::ID("flexible"));
        annos->addAnnotation(IR::ID("layout"), {layoutKind});
        auto* fields = new IR::IndexedVector<IR::StructField>();
        fields->push_back(new IR::StructField("phase0_data", IR::Type::Bits::get(64)));
        auto phase0_type = new IR::Type_Header("__phase0_header", annos, *fields);

        // Inject an explicit declaration for the phase 0 data type into the
        // program.
        LOG4("Injecting declaration for phase 0 type: " << phase0_type);
        IR::IndexedVector<IR::Node> declarations;
        declarations.push_back(phase0_type);
        program->objects.insert(program->objects.begin(),
                                declarations.begin(), declarations.end());
        return program;
    }

    const IR::Node* preorder(IR::BFN::TranslatedP4Parser* parser) override {
        if (parser->thread != INGRESS) {
            prune();
            return parser;
        }
        if (parser->tnaParams.count("ig_intr_md")) {
            keyName = parser->tnaParams.at("ig_intr_md");

            LOG3("visiting ingress parser");
            auto* annotation = new IR::Annotation("phase0", {
                    new IR::StringLiteral(IR::ID("$PORT_METADATA")),
                    new IR::StringLiteral(IR::ID(".set_port_metadata")),
                    new IR::TypeNameExpression(new IR::Type_Name("__phase0_header")),
                    new IR::StringLiteral(keyName)
            });
            LOG4("Injecting @phase0 annotation onto parser" << parser->name << ": " << annotation);
            auto* parserType = parser->type->clone();
            parserType->annotations = parserType->annotations->add(annotation);
            parser->type = parserType;
        }
        return parser;
    }
};

TnaArchTranslation::TnaArchTranslation(P4::ReferenceMap *refMap,
        P4::TypeMap *typeMap, BFN_Options &options) {
    setName("TnaArchTranslation");
    addDebugHook(options.getDebugHook());
    auto* evaluator = new P4::EvaluatorPass(refMap, typeMap);
    auto* parseTna = new ParseTna(&threads /* not used */);
    addPasses({
        evaluator,
        new VisitFunctor([evaluator, parseTna]() {
        auto toplevel = evaluator->getToplevelBlock();
            toplevel->getMain()->apply(*parseTna);
        }),
        new RewriteControlAndParserBlocks(&parseTna->toBlockInfo),
        new RestoreParams(options, evaluator),
        new CheckTNAExternInvocation(refMap, typeMap),
        new LoweringType(),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        new InsertPhaseZeroAnnotation,
        new P4::ValidateTableProperties({"implementation", "size", "counters", "meters",
                                         "filters", "idle_timeout", "registers"}),
    });
}

T2naArchTranslation::T2naArchTranslation(P4::ReferenceMap *refMap,
        P4::TypeMap *typeMap, BFN_Options &options) {
    setName("T2naArchTranslation");
    addDebugHook(options.getDebugHook());
    auto* evaluator = new P4::EvaluatorPass(refMap, typeMap);
    auto* parseTna = new ParseTna(&threads /* not used */);
    addPasses({
        evaluator,
        new VisitFunctor([evaluator, parseTna]() {
        auto toplevel = evaluator->getToplevelBlock();
            toplevel->getMain()->apply(*parseTna);
        }),
        new RewriteControlAndParserBlocks(&parseTna->toBlockInfo),
        new RestoreParams(options, evaluator),
        new CheckT2NAExternInvocation(refMap, typeMap),
        new LoweringType(),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        new InsertPhaseZeroAnnotation,
        new P4::ValidateTableProperties({"implementation", "size", "counters", "meters",
                                         "filters", "idle_timeout", "registers"}),
    });
}

}  // namespace BFN
