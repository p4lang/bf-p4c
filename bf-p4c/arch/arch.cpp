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
#if HAVE_CLOUDBREAK
        if (Device::currentDevice() == Device::CLOUDBREAK) {
            passes.push_back(new BFN::T2naArchTranslation(refMap, typeMap, options));
        }
    } else if (options.arch == "t3na") {
        if (Device::currentDevice() == Device::CLOUDBREAK) {
            passes.push_back(new BFN::T2naArchTranslation(refMap, typeMap, options));
        }
#endif
    } else if (options.arch == "psa") {
        passes.push_back(new BFN::PortableSwitchTranslation(refMap, typeMap, options /*map*/));
    } else {
        P4C_UNIMPLEMENTED("Cannot handle architecture %1%", options.arch);
    }
}

// parse tna pipeline with single parser.
void ParseTna::parseSingleParserPipeline(const IR::PackageBlock* block, unsigned index) {
    auto thread_i = new IR::BFN::P4Thread();
    bool isMultiParserProgram = (block->type->name == "MultiParserPipeline");
    cstring pipe = "";
    auto decl = block->node->to<IR::Declaration_Instance>();
    // If no declaration found (anonymous instantiation) get the pipe name from arch definition
    if (decl) {
        pipe = decl->Name();
    } else {
        auto cparams = mainBlock->getConstructorParameters();
        auto idxParam = cparams->getParameter(index);
        pipe = idxParam->name;
    }
    BUG_CHECK(!pipe.isNullOrEmpty(),
        "Cannot determine pipe name for pipe block at index %d", index);

    if (isMultiParserProgram) {
        auto ingress_parsers = block->getParameterValue("ig_prsr");
        BUG_CHECK(ingress_parsers->is<IR::PackageBlock>(), "Expected PackageBlock");
        parseMultipleParserInstances(ingress_parsers->to<IR::PackageBlock>(),
                                                        pipe, thread_i, INGRESS);
    } else {
        auto ingress_parser = block->getParameterValue("ingress_parser");
        BlockInfo ip(index, pipe, INGRESS, PARSER);
        BUG_CHECK(ingress_parser->is<IR::ParserBlock>(), "Expected ParserBlock");
        thread_i->parsers.push_back(ingress_parser->to<IR::ParserBlock>()->container);
        toBlockInfo.emplace(ingress_parser->to<IR::ParserBlock>()->container, ip);
    }

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
    mainBlock = block;

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
                node->body, {}, binfo.gress, binfo.pipe);
        return rv;
    } else if (binfo.type == ArchBlock_t::DEPARSER) {
        auto rv = new IR::BFN::TnaDeparser(
                node->srcInfo, node->name, node->type,
                node->constructorParams, node->controlLocals,
                node->body, {}, binfo.gress, binfo.pipe);
        return rv;
    }
    block_info->erase(binfoItr.first);
    return node;
}

void add_param(ordered_map<cstring, cstring>& tnaParams,
        const IR::ParameterList* params, cstring hdr, int index) {
    if (int(params->parameters.size()) > index) {
        auto* param = params->parameters.at(index);
        tnaParams.emplace(hdr, param->name);
    }
}

IR::BFN::TnaControl* RestoreParams::preorder(IR::BFN::TnaControl* control) {
    auto* params = control->type->getApplyParameters();
    ordered_map<cstring, cstring> tnaParams;
    prune();
    if (control->thread == INGRESS) {
        add_param(tnaParams, params, "hdr", 0);
        add_param(tnaParams, params, "ig_md", 1);
        add_param(tnaParams, params, "ig_intr_md", 2);
        add_param(tnaParams, params, "ig_intr_md_from_prsr", 3);
        add_param(tnaParams, params, "ig_intr_md_for_dprsr", 4);
        add_param(tnaParams, params, "ig_intr_md_for_tm", 5);
        // Check for optional ghost_intrinsic_metadata_t for t2na arch
        if (options.arch == "t2na") {
            add_param(tnaParams, params, "gh_intr_md", 6);
        }
    } else if (control->thread == EGRESS) {
        add_param(tnaParams, params, "hdr", 0);
        add_param(tnaParams, params, "eg_md", 1);
        add_param(tnaParams, params, "eg_intr_md", 2);
        add_param(tnaParams, params, "eg_intr_md_from_prsr", 3);
        add_param(tnaParams, params, "eg_intr_md_for_dprsr", 4);
        add_param(tnaParams, params, "eg_intr_md_for_oport", 5);
    }

    return new IR::BFN::TnaControl(control->srcInfo, control->name,
                                   control->type,
                                   control->constructorParams, control->controlLocals,
                                   control->body, tnaParams, control->thread,
                                   control->pipeName);
}

IR::BFN::TnaParser* RestoreParams::preorder(IR::BFN::TnaParser* parser) {
    auto* params = parser->type->getApplyParameters();
    ordered_map<cstring, cstring> tnaParams;

    prune();
    if (parser->thread == INGRESS) {
        add_param(tnaParams, params, "pkt", 0);
        add_param(tnaParams, params, "hdr", 1);
        add_param(tnaParams, params, "ig_md", 2);
        add_param(tnaParams, params, "ig_intr_md", 3);
        add_param(tnaParams, params, "ig_intr_md_for_tm", 4);
        add_param(tnaParams, params, "ig_intr_md_from_prsr", 5);
    } else if (parser->thread == EGRESS) {
        add_param(tnaParams, params, "pkt", 0);
        add_param(tnaParams, params, "hdr", 1);
        add_param(tnaParams, params, "eg_md", 2);
        add_param(tnaParams, params, "eg_intr_md", 3);
        add_param(tnaParams, params, "eg_intr_md_from_prsr", 4);
    }

    return new IR::BFN::TnaParser(parser->srcInfo, parser->name,
                                  parser->type,
                                  parser->constructorParams, parser->parserLocals,
                                  parser->states, tnaParams, parser->thread,
                                  parser->phase0, parser->pipeName, parser->portmap);
}

IR::BFN::TnaDeparser* RestoreParams::preorder(IR::BFN::TnaDeparser* control) {
    auto* params = control->type->getApplyParameters();
    ordered_map<cstring, cstring> tnaParams;

    prune();
    if (control->thread == INGRESS) {
        add_param(tnaParams, params, "pkt", 0);
        add_param(tnaParams, params, "hdr", 1);
        add_param(tnaParams, params, "metadata", 2);
        add_param(tnaParams, params, "ig_intr_md_for_dprsr", 3);
        add_param(tnaParams, params, "ig_intr_md", 4);
    } else if (control->thread == EGRESS) {
        add_param(tnaParams, params, "pkt", 0);
        add_param(tnaParams, params, "hdr", 1);
        add_param(tnaParams, params, "metadata", 2);
        add_param(tnaParams, params, "eg_intr_md_for_dprsr", 3);
        add_param(tnaParams, params, "eg_intr_md", 4);
        add_param(tnaParams, params, "eg_intr_md_from_prsr", 5);
    }

    return new IR::BFN::TnaDeparser(control->srcInfo, control->name,
                                    control->type,
                                    control->constructorParams, control->controlLocals,
                                    control->body, tnaParams, control->thread,
                                    control->pipeName);
}

}  // namespace BFN
