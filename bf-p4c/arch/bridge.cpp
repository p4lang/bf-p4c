#include "bridge.h"
#include "frontends/p4/methodInstance.h"
#include "bf-p4c/common/flexible_packing.h"

namespace BFN {

bool CollectBridgedFieldsUse::preorder(const IR::MethodCallExpression* expr) {
    auto mi = P4::MethodInstance::resolve(expr, refMap, typeMap);
    if (!mi)
        return false;
    if (auto em = mi->to<P4::ExternMethod>()) {
        auto type_name = em->originalExternType->name;

        LOG1("method " << expr);
        if (type_name != "packet_in" && type_name != "packet_out" && type_name != "Resubmit")
            return false;

        auto hdr = em->getActualParameters()->getParameter("hdr");
        if (!hdr)
            return false;
        LOG1("param " << hdr);

        boost::optional<gress_t> thread = boost::none;
        auto parser = findContext<IR::BFN::TnaParser>();
        if (parser)
            thread = parser->thread;

        auto deparser = findContext<IR::BFN::TnaDeparser>();
        if (deparser)
            thread = deparser->thread;

        if (auto param = hdr->to<IR::Parameter>()) {
            if (auto type = param->type->to<IR::Type_StructLike>()) {
                if (findFlexibleAnnotation(type)) {
                    auto u = new Use();
                    u->object = em->object;
                    u->bridgedType = hdr->type;
                    u->method = em->method->name;
                    if (em->method->name == "emit")
                        u->access = READ;
                    else if (em->method->name == "extract")
                        u->access = WRITE;
                    u->thread = thread;
                    LOG1("u " << thread << " access " << u->access);
                    bridge_use_single_pipe.push_back(*u);
                }
            } else if (param->type->is<IR::BFN::Type_FixedSizeHeader>()) {
                auto u = new Use();
                u->object = em->object;
                u->bridgedType = hdr->type;
                u->method = em->method->name;
                if (em->method->name == "emit")
                    u->access = READ;
                else if (em->method->name == "extract")
                    u->access = WRITE;
                u->thread = thread;
                LOG1("u " << thread << " access " << u->access);
                bridge_use_single_pipe.push_back(*u);
            }
        }
    }
    return false;
}

void CollectBridgedFieldsUse::updatePipeInfo(const IR::BFN::Pipe* pipe) {
    for (auto& use : bridge_use_single_pipe) {
        use.pipe = pipe;
        bridge_use_all.push_back(use);
    }
    bridge_use_single_pipe.clear();
}

PipeAndGress
CollectBridgedFieldsUse::toPipeAndGress(
        const IR::BFN::Pipe* pw, gress_t pw_thread,
        const IR::BFN::Pipe* pr, gress_t pr_thread) {
    return std::make_pair(std::make_pair(pw->name, pw_thread), std::make_pair(pr->name, pr_thread));
}

IR::Vector<IR::BFN::BridgePipe>*
CollectBridgedFieldsUse::getPipes() {
    auto pipes = new IR::Vector<IR::BFN::BridgePipe>();
    for (auto use : bridge_use_all) {
        cstring name = use.bridgedType->to<IR::Type_StructLike>()->name;
        if (use.access == READ) {
            read_set[name].push_back(use);
        } else if (use.access == WRITE) {
            write_set[name].push_back(use);
        }
    }

    ordered_set<PipeAndGress> pipe_and_gress;

    for (auto use : read_set) {
        if (!write_set.count(use.first))
            continue;
        for (auto pr : use.second) {
            for (auto pw : write_set.at(use.first)) {
                if (pipe_and_gress.count(toPipeAndGress(pw.pipe, *pw.thread, pr.pipe, *pr.thread)))
                    continue;
                pipe_and_gress.insert(toPipeAndGress(pw.pipe, *pw.thread, pr.pipe, *pr.thread));

                LOG3("header " << use.first
                        << " is read in " << pr.pipe->name << "(" << pr.thread << ")"
                        << " and written in " << pw.pipe->name << "(" << pw.thread << ")");
                auto pipe = new IR::BFN::BridgePipe();
                pipe->global_pragmas = collect_pragma.global_pragmas();
                pipe->thread[INGRESS] = pr.pipe->thread[*pr.thread];
                pipe->pipe[INGRESS] = pr.pipe->name;
                pipe->thread[EGRESS] = pw.pipe->thread[*pw.thread];
                pipe->pipe[EGRESS] = pw.pipe->name;
                pipes->push_back(pipe);
            }
        }
    }

    return pipes;
}

}  // namespace BFN
