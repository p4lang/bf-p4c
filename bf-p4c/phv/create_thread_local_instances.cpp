/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "bf-p4c/phv/create_thread_local_instances.h"

#include "bf-p4c/ir/thread_visitor.h"

namespace {

using ThreadLocalMetadataMapping =
    std::map<const IR::Metadata*, const IR::Metadata*>;

/// Create thread-local versions of variables and parser states.
struct CreateInstancesForThread : public Modifier, ThreadVisitor {
    explicit CreateInstancesForThread(gress_t th) : ThreadVisitor(th) { }

    /// The thread-local versions of each metadata struct; consumed by
    /// CreateThreadLocalMetadata.
    ThreadLocalMetadataMapping localMetadata;

 private:
    /// Prepend "thread-name::" to the names of headers and metadata structs.
    bool preorder(IR::HeaderOrMetadata* header) override {
        header->name = IR::ID(cstring::to_cstring(VisitingThread(this)) +
                              "::" + header->name);
        if (auto* metadata = header->to<IR::Metadata>())
            localMetadata[getOriginal()->to<IR::Metadata>()] = metadata;
        return false;
    }

    /// Prepend "thread-name::" to every parse state.
    bool preorder(IR::BFN::ParserState *ps) override {
        ps->name = cstring::to_cstring(VisitingThread(this)) + "::" + ps->name;
        return true;
    }

    /// Prepend "thread-name::" to TempVars.
    bool preorder(IR::TempVar *var) override {
        var->name = cstring::to_cstring(VisitingThread(this)) + "::" + var->name;
        return false;
    }
};

/// Update the set of metadata structs in `BFN::Pipe::metadata` to refer to
/// the thread-local versions of the structs.
struct CreateThreadLocalMetadata : public Modifier {
    CreateThreadLocalMetadata(const ThreadLocalMetadataMapping* ingressMetadata,
                              const ThreadLocalMetadataMapping* egressMetadata)
      : localMetadata{ingressMetadata, egressMetadata} {
        CHECK_NULL(ingressMetadata);
        CHECK_NULL(egressMetadata);
    }

 private:
    bool preorder(IR::BFN::Pipe* pipe) override {
        // Replace the global metadata variables in the program with
        // thread-local versions. There are at most two thread-local versions of
        // each variable; there may be fewer than two if the variable is only
        // used by one thread.
        IR::NameMap<IR::Metadata> instancedMetadata;
        for (auto& item : pipe->metadata) {
            cstring name = item.first;
            auto* metadata = item.second;
            for (auto gress : { INGRESS, EGRESS }) {
                auto gressName = cstring::to_cstring(gress) + "::" + name;
                auto& gressMetadata = *localMetadata[gress];
                if (gressMetadata.find(metadata) != gressMetadata.end())
                    instancedMetadata.addUnique(gressName, gressMetadata.at(metadata));
            }
        }

        pipe->metadata = instancedMetadata;
        return false;
    }

    const ThreadLocalMetadataMapping* localMetadata[2];
};

}  // namespace

CreateThreadLocalInstances::CreateThreadLocalInstances() {
    auto* createIngressInstances = new CreateInstancesForThread(INGRESS);
    auto* createEgressInstances = new CreateInstancesForThread(EGRESS);
    addPasses({
        createIngressInstances,
        createEgressInstances,
        new CreateThreadLocalMetadata(&createIngressInstances->localMetadata,
                                      &createEgressInstances->localMetadata)
    });
}
