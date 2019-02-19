#ifndef BF_P4C_ARCH_ARCH_H_
#define BF_P4C_ARCH_ARCH_H_

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
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/arch/program_structure.h"

namespace BFN {

enum class ARCH { TNA, T2NA, PSA, V1MODEL };

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

class GenerateTofinoProgram : public Transform {
    ProgramStructure* structure;
 public:
    explicit GenerateTofinoProgram(ProgramStructure* structure)
            : structure(structure) { CHECK_NULL(structure); setName("GenerateTofinoProgram"); }

    const IR::Node* preorder(IR::P4Program* program) override {
        auto *rv = structure->create(program);
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

class ArchTranslation : public PassManager {
 public:
    ArchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap, BFN_Options& options);
};

enum ArchBlock_t {
    PARSER = 0,
    MAU,
    DEPARSER,
    BLOCK_TYPE
};

struct BlockInfo {
    int index;
    // XXX(amresh); In addition to the index, we need the pipe name to generate
    // a fully qualified name in case of multipipe scenarios.
    cstring pipe;
    gress_t gress;

    // which port to configure using this impl.
    std::vector<int> portmap;

    ArchBlock_t type;
    BlockInfo(int index, cstring pipe, gress_t gress, ArchBlock_t type)
            : index(index), pipe(pipe), gress(gress), type(type) {}
    void dbprint(std::ostream& out) {
        out << "index " << index << " ";
        out << "pipe" << pipe << " ";
        out << "gress " << gress << " ";
        out << "type " << type << std::endl;
    }
};

using ProgramThreads = std::map<std::pair<int, gress_t>, const IR::BFN::P4Thread*>;
using BlockInfoMapping = std::map<const IR::Node*, BlockInfo>;

class ParseTna : public Inspector {
 public:
    ParseTna() { }

    // parse tna pipeline with single parser.
    void parseSingleParserPipeline(const IR::PackageBlock* block, unsigned index) {
        auto thread_i = new IR::BFN::P4Thread();
        auto pipe = block->node->to<IR::Declaration_Instance>()->Name();
        auto ingress_parser = block->getParameterValue("ingress_parser");
        if (auto parsers = ingress_parser->to<IR::PackageBlock>()) {
            parseMultipleParserInstances(parsers, pipe, thread_i, INGRESS);
        } else {
            BlockInfo ip(index, pipe, INGRESS, PARSER);
            thread_i->parsers.push_back(ingress_parser->to<IR::ParserBlock>()->container);
            toBlockInfo.emplace(ingress_parser->to<IR::ParserBlock>()->container, ip); }

        auto ingress = block->getParameterValue("ingress");
        BlockInfo ig(index, pipe, INGRESS, MAU);
        thread_i->mau = ingress->to<IR::ControlBlock>()->container;
        toBlockInfo.emplace(ingress->to<IR::ControlBlock>()->container, ig);

        auto ingress_deparser = block->getParameterValue("ingress_deparser");
        BlockInfo id(index, pipe, INGRESS, DEPARSER);
        thread_i->deparser = ingress_deparser->to<IR::ControlBlock>()->container;
        toBlockInfo.emplace(ingress_deparser->to<IR::ControlBlock>()->container, id);

        threads.emplace(std::make_pair(index, INGRESS), thread_i);

        auto thread_e = new IR::BFN::P4Thread();
        auto egress_parser = block->getParameterValue("egress_parser");
        if (auto parsers = egress_parser->to<IR::PackageBlock>()) {
            parseMultipleParserInstances(parsers, pipe, thread_e, EGRESS);
        } else {
            BlockInfo ep(index, pipe, EGRESS, PARSER);
            thread_e->parsers.push_back(egress_parser->to<IR::ParserBlock>()->container);
            toBlockInfo.emplace(egress_parser->to<IR::ParserBlock>()->container, ep); }

        auto egress = block->getParameterValue("egress");
        thread_e->mau = egress->to<IR::ControlBlock>()->container;
        BlockInfo eg(index, pipe, EGRESS, MAU);
        toBlockInfo.emplace(egress->to<IR::ControlBlock>()->container, eg);

        auto egress_deparser = block->getParameterValue("egress_deparser");
        thread_e->deparser = egress_deparser->to<IR::ControlBlock>()->container;
        BlockInfo ed(index, pipe, EGRESS, DEPARSER);
        toBlockInfo.emplace(egress_deparser->to<IR::ControlBlock>()->container, ed);

        threads.emplace(std::make_pair(index, EGRESS), thread_e);

        if (auto ghost = block->findParameterValue("ghost")) {
            auto ghost_cb = ghost->to<IR::ControlBlock>()->container;
            auto thread_g = new IR::BFN::P4Thread();
            thread_g->mau = ghost_cb;
            threads.emplace(std::make_pair(index, GHOST), thread_g);
            toBlockInfo.emplace(ghost_cb, BlockInfo(index, pipe, GHOST, MAU));
        }
    }

    using DefaultPortMap = std::map<int, std::vector<int>>;

    void parsePortMapAnnotation(const IR::PackageBlock* block, DefaultPortMap& map) {
        if (auto anno = block->node->getAnnotation("default_portmap")) {
            int index = 0;
            for (auto expr : anno->expr) {
                std::vector<int> ports;
                if (auto cst = expr->to<IR::Constant>()) {
                    ports.push_back(cst->asInt());
                } else if (auto list = expr->to<IR::ListExpression>()) {
                    for (auto expr : list->components) {
                        ports.push_back(expr->to<IR::Constant>()->asInt());
                    }
                }
                map[index] = ports;
                index++;
            }
        }
    }

    void parseMultipleParserInstances(const IR::PackageBlock* block,
            cstring pipe, IR::BFN::P4Thread *thread, gress_t gress) {
        int index = 0;
        DefaultPortMap map;
        parsePortMapAnnotation(block, map);
        for (auto param : block->constantValue) {
            if (!param.second) continue;
            if (!param.second->is<IR::ParserBlock>()) continue;
            BlockInfo block_info(index, pipe, gress, PARSER);
            if (map.count(index) != 0)
                block_info.portmap.insert(block_info.portmap.end(),
                        map[index].begin(), map[index].end());
            thread->parsers.push_back(param.second->to<IR::ParserBlock>()->container);
            toBlockInfo.emplace(param.second->to<IR::ParserBlock>()->container, block_info);
            index++;
        }
    }

    bool preorder(const IR::PackageBlock* block) override {
        auto pos = 0;
        for (auto param : block->constantValue) {
            if (!param.second) continue;
            if (!param.second->is<IR::PackageBlock>()) continue;
            parseSingleParserPipeline(param.second->to<IR::PackageBlock>(), pos++);
        }
        return false;
    }

 public:
    ProgramThreads threads;
    BlockInfoMapping toBlockInfo;
};

struct DoRewriteControlAndParserBlocks : Transform {
 public:
    explicit DoRewriteControlAndParserBlocks(BlockInfoMapping* block_info) :
            block_info(block_info) {}

    const IR::Node* postorder(IR::P4Parser *node) override {
        auto orig = getOriginal();
        if (!block_info->count(orig)) {
            BUG("P4Parser is mutated after evaluation");
            return node;
        }
        auto binfo = block_info->at(orig);
        auto pipeName = (block_info->size() == 6) ? "" : binfo.pipe;
        auto rv = new IR::BFN::TnaParser(
                node->srcInfo, node->name,
                node->type, node->constructorParams,
                node->parserLocals, node->states,
                {}, binfo.gress, pipeName, binfo.portmap);
        return rv;
    }

    const IR::Node* postorder(IR::P4Control *node) override {
        auto orig = getOriginal();
        if (!block_info->count(orig)) {
            BUG("P4Control is mutated after evaluation");
            return node;
        }
        auto binfo = block_info->at(orig);
        auto pipeName = (block_info->size() == 6) ? "" : binfo.pipe;
        if (binfo.type == ArchBlock_t::MAU) {
            auto rv = new IR::BFN::TnaControl(
                    node->srcInfo, node->name, node->type,
                    node->constructorParams, node->controlLocals,
                    node->body, {}, binfo.gress, binfo.pipe);
            return rv;
        } else if (binfo.type == ArchBlock_t::DEPARSER) {
            auto rv = new IR::BFN::TnaDeparser(
                    node->srcInfo, node->name, node->type,
                    node->constructorParams, node->controlLocals,
                    node->body, {}, binfo.gress, pipeName);
            return rv;
        }
        return node;
    }

 private:
    BlockInfoMapping* block_info;
};

// This pass rewrites the IR::P4Parser and IR::P4Control node to
// IR::BFN::TnaParser, IR::BFN::TnaControl
// IR::BFN::TnaDeparser.
// The latter three classes are used in the midend till extract_maupipe,
// which is then converted to IR::BFN::Parser, IR::BFN::Pipe and
// IR::BFN::Deparser.
struct RewriteControlAndParserBlocks : public PassManager {
 public:
    RewriteControlAndParserBlocks(P4::ReferenceMap* refMap,
                                  P4::TypeMap* typeMap) {
        auto* evaluator = new P4::EvaluatorPass(refMap, typeMap);
        auto* parseTna = new ParseTna();
        passes.push_back(evaluator);
        passes.push_back(new VisitFunctor([evaluator, parseTna]() {
            auto toplevel = evaluator->getToplevelBlock();
            toplevel->getMain()->apply(*parseTna);
        }));
        passes.push_back(new DoRewriteControlAndParserBlocks(&parseTna->toBlockInfo));
    }
};

/// Restore all parameters to the controls and parsers as specified by the /
/// architecture.
struct RestoreParams: public Transform {
    explicit RestoreParams(BFN_Options &options) : options(options) { }

    IR::BFN::TnaControl* preorder(IR::BFN::TnaControl* control) {
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

        return new IR::BFN::TnaControl(control->srcInfo, control->name,
                                                control->type,
                                                control->constructorParams, control->controlLocals,
                                                control->body, tnaParams, control->thread,
                                                control->pipeName);
    }

    IR::BFN::TnaParser* preorder(IR::BFN::TnaParser* parser) {
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
        return new IR::BFN::TnaParser(parser->srcInfo, parser->name,
                                               parser_type,
                                               parser->constructorParams, parser->parserLocals,
                                               parser->states, tnaParams, parser->thread,
                                               parser->phase0, parser->pipeName, parser->portmap);
    }

    BFN_Options &options;
};

/// XXX(hanw): probably should be done before translation
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

}  // namespace BFN

#endif /* BF_P4C_ARCH_ARCH_H_ */
