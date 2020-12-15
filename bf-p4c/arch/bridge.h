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

// A Tna program specifies the packet processing logic on individual pipe in
// Tofino. In a 32q program, a packet may be processed by multiple pipes, which
// forms a 'logical' pipeline that spans multiple 'physical' pipe in Tofino.
// For example, a typical 32q program process a packet in the following order:
//
// ig0 -> eg1 -> ig1 -> eg0
//
// Using the backend's terminology, the packet is processed by 4 threads of
// IR::BFN::thread_t type in a run-to-completion manner. Because of this
// construction, the bridging header shared by these 4 threads must conform to
// the constraint induced by all of these threads, which makes it potentially
// more difficult to allocate in terms of PHV. That's the price to pay for more
// capacity. However, user does not have pay the price if no bridge header is
// shared by more than two threads. The allocation for the latter case would be
// as difficult as a regular 64q program.
//
// The goal of the this pass is to analyze the use of Serializer extern in the
// program to infer how bridge header is shared between threads. In the end, this
// pass builds objects that will be used by bridge header packing algorithm to
// automatically optimize the layout of bridge header to save bandwidth.
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

// Apply this pass manager to IR::P4Program after midend processing.
// Returns IR::P4Program after flexible metadata packing.
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
 * Replace @flexible type definition with packed version
 */
class SubstitutePackedHeaders : public PassManager {
    ParamBinding* bindings;
    ApplyEvaluator *evaluator;
    BackendConverter *conv;
    RepackedHeaderTypes &map;

 public:
    P4::ReferenceMap refMap;
    P4::TypeMap typeMap;
    IR::Vector<IR::BFN::Pipe> pipe;
    ordered_map<int, const IR::BFN::Pipe*> pipes;

 public:
    SubstitutePackedHeaders(BFN_Options& options, RepackedHeaderTypes& repackedMap,
                            CollectSourceInfoLogging& sourceInfoLogging);
    const ProgramThreads &getThreads() const { return conv->getThreads(); }
    const IR::ToplevelBlock *getToplevelBlock() const { return evaluator->toplevel; }
};


}  // namespace BFN

#endif /* BF_P4C_ARCH_BRIDGE_H_ */
