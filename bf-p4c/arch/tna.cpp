#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/cloner.h"
#include "midend/validateProperties.h"
#include "midend/copyStructures.h"
#include "bf-p4c/arch/tna.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/arch/check_extern_invocation.h"
#include "bf-p4c/device.h"
#include "bf-p4c/lib/pad_alignment.h"
#include "bf-p4c/parde/field_packing.h"
#include "bf-p4c/common/rewrite_flexible_struct.h"
#include "bf-p4c/midend/type_checker.h"

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
                                                control->body, tnaParams,
                                                control->thread, control->pipeName);
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
                                                parser->states, tnaParams, parser->thread,
                                                parser->phase0, parser->pipeName);
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
        auto pipeName = (bmap->size() == 6) ? "" : binfo.pipe;
        auto rv = new IR::BFN::TranslatedP4Parser(
            node->srcInfo, node->name,
            node->type, node->constructorParams,
            node->parserLocals, node->states,
            {}, binfo.gress, pipeName);
        return rv;
    }

    const IR::Node* postorder(IR::P4Control *node) override {
        auto orig = getOriginal();
        if (!bmap->count(orig)) {
            BUG("P4Control is mutated after evaluation");
            return node;
        }
        auto binfo = bmap->at(orig);
        auto pipeName = (bmap->size() == 6) ? "" : binfo.pipe;
        if (binfo.type == ArchBlockType::MAU) {
            auto rv = new IR::BFN::TranslatedP4Control(
                node->srcInfo, node->name, node->type,
                node->constructorParams, node->controlLocals,
                node->body, {}, binfo.gress, binfo.pipe);
            return rv;
        } else if (binfo.type == ArchBlockType::DEPARSER) {
            auto rv = new IR::BFN::TranslatedP4Deparser(
                node->srcInfo, node->name, node->type,
                node->constructorParams, node->controlLocals,
                node->body, {}, binfo.gress, pipeName);
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

/* Check if phase0 extern - port_metadata_unpack - is used in the program.
 * Since we can have multiple ingress parsers, we create a map of parser -
 * fields to extract for each parser
 * Fields can be specified as a Type_Header/Type_Struct
 */
typedef std::map<const IR::BFN::TranslatedP4Parser*,
            std::pair<cstring, const IR::Type_StructLike*>> Phase0CallMap;
class CheckPhaseZeroExtern: public Inspector {
 public:
    CheckPhaseZeroExtern(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
        Phase0CallMap *phase0_calls) : refMap(refMap), typeMap(typeMap),
                                       phase0_calls(phase0_calls) {
            setName("CheckPhaseZeroExtern");
        }

    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    Phase0CallMap *phase0_calls;

 private:
    bool preorder(const IR::MethodCallExpression* expr) override {
        LOG3("visiting method call expression: " << expr);
        auto mi = P4::MethodInstance::resolve(expr, refMap, typeMap);
        // Get extern method
        if (auto extFunction = mi->to<P4::ExternFunction>()) {
            auto extFuncExpr = extFunction->expr;
            // Check if method call is a phase0 extern
            if (extFuncExpr &&
                    extFuncExpr->toString() == BFN::ExternPortMetadataUnpackString) {
                auto parser = findOrigCtxt<IR::BFN::TranslatedP4Parser>();
                ERROR_CHECK(parser->thread == INGRESS,
                        "Phase0 Extern %1% cannot be set in egress",
                        BFN::ExternPortMetadataUnpackString);
                if (phase0_calls) {
                    ERROR_CHECK(phase0_calls->count(parser) == 0,
                        "Multiple Phase0 Externs "
                        "(%1%) not allowed on a parser",
                        BFN::ExternPortMetadataUnpackString);
                    cstring keyName = "";
                    if (auto stmt = findOrigCtxt<IR::AssignmentStatement>())
                        keyName = stmt->left->toString();
                    if (auto fields =  extFuncExpr->type->to<IR::Type_StructLike>()) {
                        (*phase0_calls)[parser] = std::make_pair(keyName, fields);
                        LOG4("Found phase0 extern in parser");
                    }
                }
                return false;
            }
        }
        return true;
    }
};

/* Use the header map generated in CheckPhase0Extern to update the Phase0 Node
 * in IR with relevant headers
 */
class UpdatePhase0NodeInParser: public Transform {
 public:
    explicit UpdatePhase0NodeInParser(
        Phase0CallMap *phase0_calls, IR::IndexedVector<IR::Node> *decls)
        : phase0_calls(phase0_calls), declarations(decls) {
        setName("UpdatePhase0NodeInParser");
    }

    Phase0CallMap *phase0_calls;
    IR::IndexedVector<IR::Node> *declarations;
    int phase0_count = 0;

 private:
    IR::IndexedVector<IR::StructField>* canPackDataIntoPhase0(
                const IR::IndexedVector<IR::StructField>* fields, const int phase0Size) {
        // Generate the phase 0 data layout.
        BFN::FieldPacking *packing = new BFN::FieldPacking();
        for (auto* param : *fields) {
            BUG_CHECK(param->type, "No type for phase 0 parameter %1%?", param);

            // Align the field so that its LSB lines up with a byte boundary,
            // which (usually) reproduces the behavior of the PHV allocator.
            // XXX(amresh): Once phase0 node is properly supported in the
            // backend, we won't need this (or any padding), so we should remove
            // it at that point.
            const int fieldSize = param->type->width_bits();
            const int alignment = getAlignment(fieldSize);
            packing->padToAlignment(8, alignment);
            packing->appendField(new IR::PathExpression(param->name),
                                 param->name, fieldSize);
            packing->padToAlignment(8);
        }

        packing->padToAlignment(phase0Size);

        // Make sure we didn't overflow.
        ERROR_CHECK(int(packing->totalWidth) == phase0Size,
          "Exceeded port metadata field packing size, should be exactly %1% bits",
          phase0Size);

        // Use the layout to construct a type for phase 0 data.
        IR::IndexedVector<IR::StructField> *packFields = new IR::IndexedVector<IR::StructField>();
        unsigned padFieldId = 0;
        for (auto& packedField : *packing) {
            if (packedField.isPadding()) {
                cstring padFieldName = "__pad_";
                padFieldName += cstring::to_cstring(padFieldId++);
                auto* padFieldType = IR::Type::Bits::get(packedField.width);
                packFields->push_back(new IR::StructField(padFieldName, new IR::Annotations({
                        new IR::Annotation(IR::ID("hidden"), { })
                    }), padFieldType));
                continue;
            }

            auto* fieldType = IR::Type::Bits::get(packedField.width);
            packFields->push_back(new IR::StructField(packedField.source, fieldType));
        }

        return packFields;
    }

    // Populate Phase0 Node in Parser & generate new Phase0 Header type
    IR::BFN::TranslatedP4Parser* preorder(IR::BFN::TranslatedP4Parser *parser) {
        if (parser->thread == EGRESS) return parser;
        auto *origParser = getOriginal<IR::BFN::TranslatedP4Parser>();
        auto size = Device::numMaxChannels();
        auto tableName = parser->name + ".$PORT_METADATA";
        if (!parser->pipeName.isNullOrEmpty())
            tableName = parser->pipeName + "." + tableName;
        auto actionName = "set_port_metadata";
        auto keyName = "phase0_data";
        cstring hdrName = "__phase0_header" + std::to_string(phase0_count);
        auto handle = 0x20 << 24 | phase0_count++ << 16;

        // If no extern is specified inject phase0 in parser
        auto* fields = new IR::IndexedVector<IR::StructField>();
        int phase0Size = Device::pardeSpec().bitPhase0Size();
        fields->push_back(new IR::StructField(keyName,
                              IR::Type::Bits::get(phase0Size)));
        auto *packedFields = canPackDataIntoPhase0(fields, phase0Size);

        // If extern present update phase0 with extern info
        if (phase0_calls && phase0_calls->count(origParser)) {
            auto pmdHeader = (*phase0_calls)[origParser];
            if (auto *pmdFields = pmdHeader.second) {
                keyName = pmdHeader.first;
                hdrName = pmdFields->name.toString();
                packedFields = canPackDataIntoPhase0(&pmdFields->fields, phase0Size);
            }
        }
        parser->phase0 =
            new IR::BFN::Phase0(packedFields, size, handle, tableName, actionName, keyName);

        // The parser header needs the total phase0 bit to be extracted/skipped.
        // We check if there is any additional ingress padding for port metadata
        // and add it to the header
        auto parserPackedFields = packedFields->clone();
        int ingress_padding = Device::pardeSpec().bitIngressPrePacketPaddingSize();
        if (ingress_padding) {
            auto *fieldType = IR::Type::Bits::get(ingress_padding);
            parserPackedFields->push_back(new IR::StructField("__ingress_pad__",
                                        fieldType));
        }
        auto phase0_type = new IR::Type_Header(hdrName, *parserPackedFields);
        declarations->push_back(phase0_type);

        LOG4("Adding phase0 to Ingress Parser " << parser->phase0);
        return parser;
    }
};

// Replace phase0 struct/header declaration to new phase0 header with flexible
// layout annotation for backend
class UpdatePhase0Header: public Transform {
 public:
    explicit UpdatePhase0Header(IR::IndexedVector<IR::Node>* decls)
        : declarations(decls) {
        setName("UpdatePhase0Header");
    }

    IR::IndexedVector<IR::Node> *declarations;

 private:
    IR::Node* preorder(IR::Type_Struct* s) {
        LOG3("visiting struct : " << s);
        if (auto* d = declarations->getDeclaration(s->name.toString())) {
            LOG4("modifying struct " << s << " to header " << d->to<IR::Type_Header>());
            return d->to<IR::Node>()->clone();
        }
        return s;
    }
};

/* A Phase0 assignment statement in IR is converted into an extract for the
 * backend Parser
 * E.g.
 * Before => ig_md.port_md = port_metadata_unpack<my_port_metadata_t>(pkt);
 * After  => pkt.extract<my_port_metadata_t>(ig_md.port_md);
 *
 * A Phase0 method call expression in IR is converted into an extract for the
 * backend Parser
 * E.g.
 * Before => port_metadata_unpack<my_port_metadata_t>(pkt);
 * After  => pkt.advance(64); // for Tofino
 * After  => pkt.advance(192); // for Tofino2
 * The advance bits are determined by
 * Device::pardeSpec().bitPhase0Size() + Device::pardeSpec().bitIngressPrePacketPaddingSize()
 * as specified in bf-p4c/parde/parde_spec.h
 *
 * Used when we dont wish to extract the fields but simply advance or skip
 * through phase0 or port metadata
 */
class ConvertPhase0AssignToExtract: public Transform {
 public:
    ConvertPhase0AssignToExtract(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) :
        refMap(refMap), typeMap(typeMap) {
            setName("ConvertPhase0MceToExtract");
        }

    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

 private:
    IR::MethodCallExpression* generate_phase0_extract_method_call(
            const IR::Expression* lExpr, const IR::MethodCallExpression *rExpr) {
        auto mi = P4::MethodInstance::resolve(rExpr, refMap, typeMap);
        // Check if phase0 extern method call exists within the assignment
        if (auto extFunction = mi->to<P4::ExternFunction>()) {
            auto extFuncExpr = extFunction->expr;
            if (extFuncExpr &&
                    extFuncExpr->toString() == BFN::ExternPortMetadataUnpackString) {
                // Create packet extract method call to replace extern
                auto parser = findOrigCtxt<IR::BFN::TranslatedP4Parser>();
                auto packetInParam = parser->tnaParams.at("pkt");
                auto* args = new IR::Vector<IR::Argument>();
                if (lExpr) {
                    IR::Argument* a = new IR::Argument(lExpr);
                    if (auto p0Type = lExpr->type->to<IR::Type_Struct>()) {
                        auto *p0Hdr = new IR::Type_Header(p0Type->name, p0Type->fields);
                        if (auto *m = lExpr->to<IR::Member>()) {
                            auto *p0Member = new IR::Member(p0Hdr, m->expr, m->member);
                            a = new IR::Argument(p0Member);
                        }
                    }
                    args->push_back(a);
                    auto* method = new IR::Member(new IR::PathExpression(packetInParam),
                                              IR::ID("extract"));
                    auto* callExpr = new IR::MethodCallExpression(method,
                                                rExpr->typeArguments, args);
                    LOG4("modified phase0 extract method call : " << callExpr);
                    return callExpr;
                } else {
                    auto* method = new IR::Member(new IR::PathExpression(packetInParam),
                                              IR::ID("advance"));
                    unsigned p0Size = static_cast<unsigned>(Device::pardeSpec().bitPhase0Size()
                                            + Device::pardeSpec().bitIngressPrePacketPaddingSize());
                    IR::Type_Bits* p0Bits = IR::Type::Bits::get(p0Size)->clone();
                    auto* a = new IR::Argument(new IR::Constant(p0Bits, p0Size));
                    args->push_back(a);
                    auto* callExpr = new IR::MethodCallExpression(method,
                                                new IR::Vector<IR::Type>(), args);
                    LOG4("modified phase0 extract method call : " << callExpr);
                    return callExpr;
                }
            }
        }
        return nullptr;
    }

    IR::Node* preorder(IR::MethodCallExpression* expr) override {
        LOG3("visiting method call expr: " << expr);
        auto* extract = generate_phase0_extract_method_call(nullptr, expr);
        if (extract) return extract;
        return expr;
    }

    IR::Node* preorder(IR::AssignmentStatement* stmt) override {
        LOG3("visiting assignment stmt: " << stmt);
        auto* lExpr = stmt->left;
        auto* rExpr = stmt->right->to<IR::MethodCallExpression>();
        if (!lExpr || !rExpr) return stmt;
        auto* extract = generate_phase0_extract_method_call(lExpr, rExpr);
        if (extract) {
            prune();
            return new IR::MethodCallStatement(extract);
        }
        return stmt;
    }
};

TnaArchTranslation::TnaArchTranslation(P4::ReferenceMap *refMap,
        P4::TypeMap *typeMap, BFN_Options &options) {
    setName("TnaArchTranslation");
    addDebugHook(options.getDebugHook());
    auto* evaluator = new P4::EvaluatorPass(refMap, typeMap);
    auto* parseTna = new ParseTna(&threads /* not used */);
    auto* phase0_calls = new Phase0CallMap();
    auto* decls = new IR::IndexedVector<IR::Node>();
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
        new BFN::TypeChecking(refMap, typeMap, true),
        new P4::ValidateTableProperties({"implementation", "size", "counters", "meters",
                                         "filters", "idle_timeout", "registers"}),
        new CheckPhaseZeroExtern(refMap, typeMap, phase0_calls),
        new UpdatePhase0NodeInParser(phase0_calls, decls),
        new UpdatePhase0Header(decls),
        new ConvertPhase0AssignToExtract(refMap, typeMap),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
    });
}

T2naArchTranslation::T2naArchTranslation(P4::ReferenceMap *refMap,
        P4::TypeMap *typeMap, BFN_Options &options) {
    setName("T2naArchTranslation");
    addDebugHook(options.getDebugHook());
    auto* evaluator = new P4::EvaluatorPass(refMap, typeMap);
    auto* parseTna = new ParseTna(&threads /* not used */);
    auto* phase0_calls = new Phase0CallMap();
    auto* decls = new IR::IndexedVector<IR::Node>();
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
        new BFN::TypeChecking(refMap, typeMap, true),
        new P4::ValidateTableProperties({"implementation", "size", "counters", "meters",
                                         "filters", "idle_timeout", "registers"}),
        new CheckPhaseZeroExtern(refMap, typeMap, phase0_calls),
        new UpdatePhase0NodeInParser(phase0_calls, decls),
        new UpdatePhase0Header(decls),
        new ConvertPhase0AssignToExtract(refMap, typeMap),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
