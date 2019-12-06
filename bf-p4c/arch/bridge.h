#ifndef BF_P4C_ARCH_BRIDGE_H_
#define BF_P4C_ARCH_BRIDGE_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/common/pragma/collect_global_pragma.h"

namespace BFN {

// Process the serializer externs in the program.
// - find out the vector of pipelines that share the same bridge header.
// - convert serializer extern to packet_out extern.
class ProcessSerializerExtern : public PassManager {
 public:
    ProcessSerializerExtern() {}
};

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

class CollectBridgedFieldsUse : public Inspector {
 public:
    struct Use {
        const IR::IDeclaration* object;
        const IR::Type* bridgedType;
        const IR::BFN::Pipe* pipe;
        cstring method;
        unsigned access;
        boost::optional<gress_t> thread;

        cstring getName() { return object->getName().name; }
    };

    static constexpr unsigned READ = PHV::FieldUse::READ;
    static constexpr unsigned WRITE = PHV::FieldUse::WRITE;

    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    CollectGlobalPragma& collect_pragma;

    // set of sequences of pipelines that use the same bridge header
    std::vector<const IR::BFN::Pipe *> pipelines;

    std::vector<Use> bridge_use_single_pipe;
    std::vector<Use> bridge_use_all;

    ordered_map<cstring, std::vector<Use>> read_set;
    ordered_map<cstring, std::vector<Use>> write_set;


 public:
    CollectBridgedFieldsUse(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
            CollectGlobalPragma& p) :
    refMap(refMap), typeMap(typeMap), collect_pragma(p) {}

    bool preorder(const IR::MethodCallExpression* mc) override;

    IR::Vector<IR::BFN::BridgePipe>* getPipes();
    void updatePipeInfo(const IR::BFN::Pipe* p);
    PipeAndGress toPipeAndGress(const IR::BFN::Pipe*, gress_t, const IR::BFN::Pipe*, gress_t);
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_BRIDGE_H_ */
