#include "bridge.h"

#include <iostream>
#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/common/bridged_packing.h"
#include "bf-p4c/common/size_of.h"
#include "bf-p4c/midend/check_header_alignment.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/backend.h"
#include "bf-p4c/midend/simplify_args.h"
#include "midend/local_copyprop.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4/strengthReduction.h"
#include "frontends/p4/reassociation.h"
#include "frontends/p4/uselessCasts.h"
#include "frontends/p4/typeMap.h"

namespace BFN {

// Collect the 'emit' and 'extract' call on @flexible headers. We need to
// consider constraints both briding and mirror/resubmit, as a field may
// be used in both places.
void CollectBridgedFieldsUse::postorder(const IR::MethodCallExpression* expr) {
    auto mi = P4::MethodInstance::resolve(expr, refMap, typeMap);
    if (!mi)
        return;
    auto em = mi->to<P4::ExternMethod>();
    if (!em)
        return;
    if (em->method->name != "emit" &&
        em->method->name != "extract")
        return;

    auto type_name = em->originalExternType->name;
    if (type_name != "packet_in" &&
        type_name != "packet_out" &&
        type_name != "Resubmit" &&
        type_name != "Mirror")
        return;

    boost::optional<gress_t> thread = boost::make_optional(false, gress_t());
    auto parser = findContext<IR::BFN::TnaParser>();
    if (parser)
        thread = parser->thread;

    auto deparser = findContext<IR::BFN::TnaDeparser>();
    if (deparser)
        thread = deparser->thread;

    // neither parser or deparser
    if (thread == boost::none)
        return;

    // expected number of argument
    size_t arg_count = 1;
    if (type_name == "Mirror")
        arg_count = 2;

    if (expr->arguments->size() < arg_count)
        return;

    auto dest = (*expr->arguments)[arg_count - 1]->expression;
    const IR::Type* type = nullptr;
    if (auto *hdr = dest->to<IR::HeaderRef>()) {
        type = hdr->type;
    } else if (auto *hdr = dest->to<IR::StructExpression>()) {
        type = hdr->type;
    }

    if (type == nullptr)
        return;

    bool need_packing = false;
    if (auto ty = type->to<IR::Type_StructLike>()) {
        if (findFlexibleAnnotation(ty)) {
            need_packing = true;
        }
    } else if (type->is<IR::BFN::Type_FixedSizeHeader>()) {
        need_packing = true;
    }
    if (!need_packing)
        return;

    Use u;
    u.type = type;
    u.method = em->method->name;
    u.thread = *thread;

    if (auto ty = type->to<IR::Type_StructLike>())
        u.name = ty->name;

    bridge_uses.insert(u);
}

class PostMidEndLast : public PassManager {
 public:
    PostMidEndLast() { setName("PostMidEndLast"); }
};

/**
 * XXX(hanw): some code duplication with extract_mau_pipe, needs to refactor ParseTna to
 * provide a mechanism to iterate directly on TNA pipelines.
 */
bool ExtractBridgeInfo::preorder(const IR::P4Program* program) {
    ApplyEvaluator eval(refMap, typeMap);
    auto new_program = program->apply(eval);

    auto toplevel = eval.getToplevelBlock();
    BUG_CHECK(toplevel, "toplevel cannot be nullptr");

    auto main = toplevel->getMain();
    auto arch = new ParseTna();
    main->apply(*arch);

    /// SimplifyReferences passes are fixup passes that modifies the visited IR tree.
    /// Unfortunately, the modifications by simplifyReferences will transform IR tree towards
    /// the backend IR, which means we can no longer run typeCheck pass after applying
    /// simplifyReferences to the frontend IR.
    auto simplifyReferences = new SimplifyReferences(bindings, refMap, typeMap);

    // collect and set global_pragmas
    new_program->apply(collect_pragma);

    auto npipe = 0;
    for (auto pkg : main->constantValue) {
        // collect per pipe bridge uses
        CollectBridgedFieldsUse collectBridgedFields(refMap, typeMap);
        if (!pkg.second) continue;
        if (!pkg.second->is<IR::PackageBlock>()) continue;
        std::vector<gress_t> gresses = {INGRESS, EGRESS};
        for (auto gress : gresses) {
            if (!arch->threads.count(std::make_pair(npipe, gress))) {
                ::error("Unable to find thread %1%", npipe);
                return false; }
            auto thread = arch->threads.at(std::make_pair(npipe, gress));
            thread = thread->apply(*simplifyReferences);
            for (auto p : thread->parsers) {
                if (auto parser = p->to<IR::BFN::TnaParser>()) {
                    parser->apply(collectBridgedFields);
                }
            }
            if (auto dprsr = dynamic_cast<const IR::BFN::TnaDeparser *>(thread->deparser)) {
                dprsr->apply(collectBridgedFields);
            }
        }
        all_uses.emplace(npipe, collectBridgedFields.bridge_uses);
        npipe++;
    }

    return false;
}

std::vector<const IR::BFN::Pipe*>*
ExtractBridgeInfo::generate_bridge_pairs(std::vector<BridgeContext>& all_context) {
    std::vector<BridgeContext> all_emits;
    std::vector<BridgeContext> all_extracts;

    for (auto context : all_context) {
        if (context.use.method == "emit") {
            all_emits.push_back(context);
        } else if (context.use.method == "extract") {
            all_extracts.push_back(context);
        }
    }

    auto pipes = new std::vector<const IR::BFN::Pipe*>();
    for (auto emit : all_emits) {
        for (auto extract : all_extracts) {
            // cannot bridge from ingress to ingress or egress to egress
            if (emit.use.thread == extract.use.thread)
                continue;
            // can only bridge from egress to ingress in the same pipe
            if (emit.use.thread == EGRESS && extract.use.thread == INGRESS &&
                emit.pipe_id != extract.pipe_id)
                continue;
            LOG3("pipe " << emit.pipe_id << " " << emit.use <<
                 " pipe " << extract.pipe_id << " " << extract.use);
            auto pipe = new IR::BFN::Pipe;
            // emit and extract has the same pointer to pragma
            pipe->global_pragmas = collect_pragma.global_pragmas();
            pipe->thread[INGRESS] = emit.thread;
            pipe->thread[EGRESS] = extract.thread;
            pipes->push_back(pipe);
        }
    }

    return pipes;
}

void ExtractBridgeInfo::end_apply(const IR::Node*) {
    ordered_map<cstring, ordered_set<std::pair<int, CollectBridgedFieldsUse::Use>>> uses_by_name;
    for (auto kv : all_uses) {
        LOG1("pipe " << kv.first);
        for (auto u : kv.second) {
            LOG1("\t " << u);
            uses_by_name[u.name].insert(std::make_pair(kv.first, u));
        }
    }
    ordered_set<cstring> candidates;
    for (auto kv : uses_by_name)
        candidates.insert(kv.first);

    auto pack = new PackFlexibleHeaders(options, candidates, map);

    for (auto kv : uses_by_name) {
        std::vector<BridgeContext> bridge_infos;
        for (auto u : kv.second) {
            auto pipe_id = u.first;
            auto pipe = conv->getPipes().at(pipe_id);
            auto thread = pipe->thread[u.second.thread];
            BridgeContext ctxt = {pipe_id, u.second, thread};
            bridge_infos.push_back(ctxt);
        }

        auto bridgePath = generate_bridge_pairs(bridge_infos);

        for (auto p : *bridgePath) {
            LOG3("XXX: collect flexible fields for " << kv.first);
            p->apply(*pack);
        }
    }
    pack->solve();
}

// Invariants:
//  - must be applied to IR::P4Program node that can be type-checked
//  - must generated IR::P4Program node that can still be type-checked.
// Post condition:
//  - vector of backend pipes for the corresponding p4 program.
//  - if bridge_packing is enabled, a transformed IR::P4Program
//        with @flexible header repacked.
// SimplifyReference transforms IR::P4Program towards the
// backend IR representation, as a result, the transformed
// P4Program no longer type-check.
BridgedPacking::BridgedPacking(BFN_Options& options, RepackedHeaderTypes& map,
                               CollectSourceInfoLogging& sourceInfoLogging)
    : map(map) {
    refMap.setIsV1(true);
    bindings = new ParamBinding(&typeMap,
        options.langVersion == CompilerOptions::FrontendVersion::P4_14);
    conv = new BackendConverter(&refMap, &typeMap, bindings, pipe, pipes, sourceInfoLogging);
    evaluator = new BFN::ApplyEvaluator(&refMap, &typeMap);
    extractBridgeInfo = new ExtractBridgeInfo(options, &refMap, &typeMap, conv, bindings, map);
    auto typeChecking = new BFN::TypeChecking(&refMap, &typeMap, true);

    addPasses({
        new P4::ClearTypeMap(&typeMap),
        typeChecking,
        new BFN::ConvertSizeOfToConstant(),
        PassRepeated({
            new P4::ConstantFolding(&refMap, &typeMap, true, typeChecking),
            new P4::StrengthReduction(&refMap, &typeMap, typeChecking),
            new P4::Reassociation(),
            new P4::UselessCasts(&refMap, &typeMap)
        }),
        typeChecking,
        new RenameArchParams(&refMap, &typeMap),
        new FillFromBlockMap(&refMap, &typeMap),
        evaluator,
        bindings,
        conv,  // map name to IR::BFN::Pipe
        extractBridgeInfo,
        new PadFixedSizeHeaders(map),
        // new OptimizeBridgeMetadataPacking(options, map, extractBridgeInfo),
    });
}

SubstitutePackedHeaders::SubstitutePackedHeaders(BFN_Options& options,
                                                 const RepackedHeaderTypes &map,
                                                 CollectSourceInfoLogging& sourceInfoLogging) {
    refMap.setIsV1(true);
    bindings = new ParamBinding(&typeMap,
        options.langVersion == CompilerOptions::FrontendVersion::P4_14);
    conv = new BackendConverter(&refMap, &typeMap, bindings, pipe, pipes, sourceInfoLogging);
    evaluator = new BFN::ApplyEvaluator(&refMap, &typeMap);
    auto typeChecking = new BFN::TypeChecking(&refMap, &typeMap, true);

    addPasses({
        new ReplaceFlexibleType(map),
        new P4::ClearTypeMap(&typeMap),
        typeChecking,
        new BFN::ConvertSizeOfToConstant(),
        PassRepeated({
            new P4::ConstantFolding(&refMap, &typeMap, true, typeChecking),
            new P4::StrengthReduction(&refMap, &typeMap, typeChecking),
            new P4::Reassociation(),
            new P4::UselessCasts(&refMap, &typeMap)
        }),
        typeChecking,
        new RenameArchParams(&refMap, &typeMap),
        new FillFromBlockMap(&refMap, &typeMap),
        evaluator,
        bindings,
        conv,
        new PostMidEndLast,
    });
}

std::ostream& operator<<(std::ostream &out, const CollectBridgedFieldsUse::Use& u) {
    out << u.method;
    if (auto type = u.type->to<IR::Type_StructLike>()) {
        out << " " << type->name.name;
    }
    out << " in " << u.thread << ";";
    return out;
}

}  // namespace BFN
