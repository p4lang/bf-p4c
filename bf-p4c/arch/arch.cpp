#include "bf-p4c/arch/arch.h"
#include "bf-p4c/arch/psa.h"
#include "bf-p4c/arch/tna.h"
#include "bf-p4c/arch/t2na.h"
#include "bf-p4c/arch/v1model.h"
#include "bf-p4c/device.h"

namespace BFN {

ArchTranslation::ArchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                 BFN_Options& options) {
    if (options.arch == "v1model") {
        passes.push_back(new BFN::SimpleSwitchTranslation(refMap, typeMap, options /*map*/));
    } else if (options.arch == "tna") {
        if (Device::currentDevice() == Device::TOFINO) {
            passes.push_back(new BFN::TnaArchTranslation(refMap, typeMap, options));
        }
        if (Device::currentDevice() == Device::JBAY) {
            WARNING("TNA architecture is not supported on a Tofino2 device."
                    "The compilation may produce wrong binary."
                    "Consider invoking the compiler with --arch t2na.");
            passes.push_back(new BFN::T2naArchTranslation(refMap, typeMap, options));
        }
    } else if (options.arch == "t2na") {
        if (Device::currentDevice() == Device::JBAY) {
            passes.push_back(new BFN::T2naArchTranslation(refMap, typeMap, options));
        }
    } else if (options.arch == "psa") {
        passes.push_back(new BFN::PortableSwitchTranslation(refMap, typeMap, options /*map*/));
    } else {
        P4C_UNIMPLEMENTED("Cannot handle architecture %1%", options.arch);
    }
}

// parse tna pipeline with single parser.
void ParseTna::parseSingleParserPipeline(const IR::PackageBlock* block, unsigned index) {
    auto thread_i = new IR::BFN::P4Thread();
    auto pipe = block->node->to<IR::Declaration_Instance>()->Name();
    bool isMultiParserProgram = (block->type->name == "MultiParserPipeline");
    if (isMultiParserProgram) {
        auto ingress_parser = block->getParameterValue("ig_prsr");
        auto parsers = ingress_parser->to<IR::PackageBlock>();
        parseMultipleParserInstances(parsers, pipe, thread_i, INGRESS);
    } else {
        auto ingress_parser = block->getParameterValue("ingress_parser");
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
    if (isMultiParserProgram) {
        auto egress_parser = block->getParameterValue("eg_prsr");
        auto parsers = egress_parser->to<IR::PackageBlock>();
        parseMultipleParserInstances(parsers, pipe, thread_e, EGRESS);
    } else {
        auto egress_parser = block->getParameterValue("egress_parser");
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


void ParseTna::parsePortMapAnnotation(const IR::PackageBlock* block, DefaultPortMap& map) {
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

void ParseTna::parseMultipleParserInstances(const IR::PackageBlock* block,
        cstring pipe, IR::BFN::P4Thread *thread, gress_t gress) {
    int index = 0;
    DefaultPortMap map;
    parsePortMapAnnotation(block, map);
    for (auto param : block->constantValue) {
        if (!param.second) continue;
        if (!param.second->is<IR::ParserBlock>()) continue;
        auto p = param.first->to<IR::Parameter>();
        cstring archName = gress == INGRESS ? "ig_prsr" : "eg_prsr";
        auto decl = block->node->to<IR::Declaration_Instance>();
        if (decl)
            archName = decl->controlPlaneName();
        archName = p ? archName + "." + p->name : "";

        BlockInfo block_info(index, pipe, gress, PARSER, archName);
        if (map.count(index) != 0)
            block_info.portmap.insert(block_info.portmap.end(),
                    map[index].begin(), map[index].end());
        thread->parsers.push_back(param.second->to<IR::ParserBlock>()->container);
        toBlockInfo.emplace(param.second->to<IR::ParserBlock>()->container, block_info);
        index++;
    }
    hasMultipleParsers = true;
}

bool ParseTna::preorder(const IR::PackageBlock* block) {
    auto pos = 0;
    for (auto param : block->constantValue) {
        if (!param.second) continue;
        if (!param.second->is<IR::PackageBlock>()) continue;
        parseSingleParserPipeline(param.second->to<IR::PackageBlock>(), pos++);
        if (pos > 1) hasMultiplePipes = true;
    }
    return false;
}

const IR::Node* DoRewriteControlAndParserBlocks::postorder(IR::P4Parser *node) {
    auto orig = getOriginal();
    if (!block_info->count(orig)) {
        ::error(ErrorType::ERR_INVALID, "parser. You are compiling for the %2% "
                "P4 architecture.\n"
                "Please verify that you included the correct architecture file.",
                node, BackendOptions().arch);
        return node;
    }
    auto binfoItr = block_info->equal_range(orig);
    auto binfo = binfoItr.first->second;
    auto rv = new IR::BFN::TnaParser(
            node->srcInfo, node->name,
            node->type, node->constructorParams,
            node->parserLocals, node->states,
            {}, binfo.gress, binfo.portmap);
    block_info->erase(binfoItr.first);
    return rv;
}

const IR::Node* DoRewriteControlAndParserBlocks::postorder(IR::P4Control *node) {
    auto orig = getOriginal();
    if (!block_info->count(orig)) {
        ::error(ErrorType::ERR_INVALID, "control. You are compiling for the %2% "
                "P4 architecture.\n"
                "Please verify that you included the correct architecture file.",
                node, BackendOptions().arch);
        return node;
    }
    auto binfoItr = block_info->equal_range(orig);
    auto binfo = binfoItr.first->second;
    if (binfo.type == ArchBlock_t::MAU) {
        auto rv = new IR::BFN::TnaControl(
                node->srcInfo, node->name, node->type,
                node->constructorParams, node->controlLocals,
                node->body, {}, binfo.gress);
        return rv;
    } else if (binfo.type == ArchBlock_t::DEPARSER) {
        auto rv = new IR::BFN::TnaDeparser(
                node->srcInfo, node->name, node->type,
                node->constructorParams, node->controlLocals,
                node->body, {}, binfo.gress);
        return rv;
    }
    block_info->erase(binfoItr.first);
    return node;
}

IR::BFN::TnaControl* RestoreParams::preorder(IR::BFN::TnaControl* control) {
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

IR::BFN::TnaParser* RestoreParams::preorder(IR::BFN::TnaParser* parser) {
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

}  // namespace BFN
