#ifndef BF_P4C_ARCH_BRIDGE_H_
#define BF_P4C_ARCH_BRIDGE_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/common/pragma/collect_global_pragma.h"

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/extract_maupipe.h"
#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/midend/blockmap.h"
#include "bf-p4c/midend/normalize_params.h"
#include "bf-p4c/midend/param_binding.h"
#include "bf-p4c/midend/simplify_references.h"
#include "bf-p4c/midend/type_checker.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/methodInstance.h"
#include "bf-p4c/logging/source_info_logging.h"

namespace BFN {

/**
 * \defgroup bridged_packing Packing of bridged and fixed-size headers
 * \ingroup post_midend
 * \brief Overview of passes that adjust packing of bridged headers
 *
 * Packing of bridged headers is performed in order to satisfy constraints induced
 * by the processing threads where the bridged headers are used.
 * Bridging can be used from an ingress to an egress processing thread of a possibly
 * different pipe, from an egress to an ingress processing thread of the same pipe
 * in the case of a folded program, or the combination of both.
 *
 * The egress to ingress bridging is available on Tofino 32Q with loopbacks present
 * at pipes 1 and 3. It is not available on Tofino 64Q with no loopbacks.
 *
 * The case of the combination of both bridging in a folded program is shown below:
 *
 * \dot
 * digraph folded_pipeline {
 *   layout=neato
 *   node [shape=box,style="rounded,filled",fontname="sans-serif,bold",
 *     margin="0.05,0.05",color=dodgerblue3,fillcolor=dodgerblue3,fontcolor=white,fontsize=10]
 *   edge [fontname="sans-serif",color=gray40,fontcolor=gray40,fontsize=10]
 *   IG0 [label="pipe0:ingress", pos="-1,1!"]
 *   EG0 [label="pipe0:egress", pos="1,1!"]
 *   IG1 [label="pipe1:ingress", pos="-1,0!"]
 *   EG1 [label="pipe1:egress", pos="1,0!"]
 *   IG0 -> EG1
 *   EG1 -> IG1 [label="32Q loopback"]
 *   IG1 -> EG0
 * }
 * \enddot
 *
 * Packets are processed in a "logical" pipe(line) that spans multiple "physical" pipe(line)s.
 * Using the backend's terminology, the packet is processed by four threads
 * of the IR::BFN::Pipe::thread_t type in a run-to-completion manner.
 *
 * All bridged headers needs to be analyzed in all threads they are used in.
 * They are emitted by the source thread and extracted by the destination thread.
 * In the case above, if a bridged header is used in all threads, the analysis is
 * performed on pairs (pipe0:ingress, pipe1:egress), (pipe1:egress, pipe1:ingress),
 * and (pipe1:ingress, pipe0:egress) (following the arrows).
 *
 * Packing of bridged headers is performed only for the headers/structs
 * with the \@flexible annotation and for resubmit headers,
 * which are fixed-sized (transformed into the IR::BFN::Type_FixedSizeHeader type in midend).
 *
 * The steps are as follows:
 *
 * 1. BFN::BridgedPacking:
 *    Perform some auxiliary passes and convert the midend IR towards the backend IR
 *    (BackendConverter).
 * 2. BFN::BridgedPacking -> ExtractBridgeInfo::preorder(IR::P4Program):
 *    Find usages of bridged headers (CollectBridgedFieldsUse).
 * 3. BFN::BridgedPacking -> ExtractBridgeInfo::end_apply():
 *    For all pairs of gresses where the bridged headers are used, perform some auxiliary
 *      backend passes (under PackFlexibleHeaders) and collect the constraints of
 *      bridged headers (FlexiblePacking).
 * 4. BFN::BridgedPacking -> ExtractBridgeInfo::end_apply()
 *    -> PackFlexibleHeaders::solve() -> FlexiblePacking::solve()
 *    -> PackWithConstraintSolver::solve() -> ConstraintSolver::solve():
 *    Use Z3 solver to find a satisfying packing of the bridged headers,
 *      which is stored in the RepackedHeaderTypes map.
 * 5. BFN::BridgedPacking -> PadFixedSizeHeaders:
 *    Look for fixed-size headers and add their adjusted packing to the RepackedHeaderTypes map.
 * 6. The modifications of the auxiliary passes performed in 1., the converted backend IR,
 *      and the modifications of auxiliary backend passes performed in 3. are thrown away.
 * 7. BFN::SubstitutePackedHeaders -> ReplaceFlexibleType::postorder:
 *    The solution found by the Z3 solver is used to substitute the original bridged headers
 *      with adjusted ones. Fixed-size headers are also substituted with adjusted ones.
 * 8. BFN::SubstitutePackedHeaders:
 *    Perform the same auxiliary passes and convert the IR towards the backend IR as in 1.
 *      and perform the PostMidEndLast pass.
 */

using PipeAndGress = std::pair<std::pair<cstring, gress_t>, std::pair<cstring, gress_t>>;

using BridgeLocs = ordered_map<std::pair<cstring, gress_t>, IR::HeaderRef*>;

class CollectBridgedFieldsUse : public Inspector {
 public:
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

    struct Use {
        const IR::Type* type;
        cstring name;
        cstring method;
        gress_t thread;

        bool operator<(const Use& other) const {
            if (name != other.name)
                return name < other.name;
            if (type != other.type)
                return type < other.type;
            if (method != other.method)
                return method < other.method;
            return thread < other.thread;
        }

        bool operator==(const Use& other) const {
            return name == other.name &&
                type == other.type &&
                method == other.method &&
                thread == other.thread;
        }
    };

    ordered_set<Use> bridge_uses;

    friend std::ostream& operator<<(std::ostream&, const Use& u);

 public:
    CollectBridgedFieldsUse(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) :
    refMap(refMap), typeMap(typeMap) {}

    void postorder(const IR::MethodCallExpression* mc) override;
};

struct BridgeContext {
    int pipe_id;
    BFN::CollectBridgedFieldsUse::Use use;
    IR::BFN::Pipe::thread_t thread;
};

class ExtractBridgeInfo : public Inspector {
    const BFN_Options& options;
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    BackendConverter *conv;
    ParamBinding* bindings;
    RepackedHeaderTypes &map;
    CollectGlobalPragma collect_pragma;

 public:
    ordered_map<int, ordered_set<CollectBridgedFieldsUse::Use>> all_uses;

    ExtractBridgeInfo(BFN_Options& options,
            P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
            BackendConverter* conv, ParamBinding* bindings,
            RepackedHeaderTypes& ht) :
        options(options), refMap(refMap), typeMap(typeMap), conv(conv),
        bindings(bindings), map(ht) {}

    std::vector<const IR::BFN::Pipe*>*
        generate_bridge_pairs(std::vector<BridgeContext>&);

    bool preorder(const IR::P4Program* program) override;
    void end_apply(const IR::Node*) override;
};

/**
 * \ingroup bridged_packing
 * \brief The pass analyzes the usage of bridged headers and adjusts their packing.
 *
 * @pre Apply this pass manager to IR::P4Program after midend processing.
 * @post The RepackedHeaderTypes map filled in with adjusted packing of bridged headers.
 */
class BridgedPacking : public PassManager {
    ParamBinding* bindings;
    ApplyEvaluator *evaluator;
    BackendConverter *conv;
    RepackedHeaderTypes &map;
    ExtractBridgeInfo* extractBridgeInfo;

 public:
    P4::ReferenceMap refMap;
    P4::TypeMap typeMap;

 public:
    BridgedPacking(BFN_Options& options, RepackedHeaderTypes& repackMap,
                   CollectSourceInfoLogging& sourceInfoLogging);

    IR::Vector<IR::BFN::Pipe> pipe;
    ordered_map<int, const IR::BFN::Pipe*> pipes;
};

/**
 * \ingroup bridged_packing
 * \brief The pass substitutes bridged headers with adjusted ones
 *        and converts the IR into the backend form.
 */
class SubstitutePackedHeaders : public PassManager {
    ParamBinding* bindings;
    ApplyEvaluator *evaluator;
    BackendConverter *conv;

 public:
    P4::ReferenceMap refMap;
    P4::TypeMap typeMap;
    IR::Vector<IR::BFN::Pipe> pipe;
    ordered_map<int, const IR::BFN::Pipe*> pipes;

 public:
    SubstitutePackedHeaders(BFN_Options& options, const RepackedHeaderTypes& repackedMap,
                            CollectSourceInfoLogging& sourceInfoLogging);
    const ProgramThreads &getThreads() const { return conv->getThreads(); }
    const IR::ToplevelBlock *getToplevelBlock() const { return evaluator->toplevel; }
};


}  // namespace BFN

#endif /* BF_P4C_ARCH_BRIDGE_H_ */
