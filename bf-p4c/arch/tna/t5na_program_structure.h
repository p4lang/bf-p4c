#ifndef EXTENSIONS_BF_P4C_ARCH_TNA_T5NA_PROGRAM_STRUCTURE_H_
#define EXTENSIONS_BF_P4C_ARCH_TNA_T5NA_PROGRAM_STRUCTURE_H_

#include "bf-p4c/arch/program_structure.h"
#include "ir/ir.h"
#include "ir/namemap.h"
#include "lib/ordered_set.h"
#include "bf-p4c/ir/gress.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"

namespace BFN {

struct T5naProgramStructure : ProgramStructure {
    static const cstring EXTRA_METADATA_STRING;

    void createTypes();
    void createParsers() override;
    void createControls() override;
    void createMain() override;
    void createTofinoArch();
    void createPipeline();

    // We want to also keep TNA architecture definitions to remove them
    IR::IndexedVector<IR::Node> targetTypesToRemove;

    // Keep instances of pipes
    std::vector<const IR::Declaration_Instance *> pipeInstances;
    // Keep main/switch instance
    const IR::Declaration_Instance *mainInstance = nullptr;
    const IR::Type_Package *pipePackage = nullptr;

    // Keep information about controls and what they represent
    std::set<cstring> ingressParsers;
    std::set<cstring> ingressControls;
    std::set<cstring> ingressDeparsers;
    std::set<cstring> egressParsers;
    std::set<cstring> egressControls;
    std::set<cstring> egressDeparsers;

    // Map egress->ingress and ingress->egress for pipes
    ordered_map<cstring, const IR::P4Control *> correspondingIngress;
    ordered_map<cstring, const IR::P4Control *> correspondingEgress;

    // Additional statements per control block
    std::map<cstring, std::vector<const IR::StatOrDecl *>> controlsStatements;
    // Ingress -> (modified headers -> replaced metadata)
    // This is kept so that we can move hdr modifications to metadata
    std::map<cstring, std::map<cstring, const IR::Member *>> hdrFieldToMdMap;
    // Here we can keep what extra structures to add into each metadata structure
    std::map<cstring, std::vector<const IR::StructField *>> mdTypeExtraFields;
    ordered_map<cstring, const IR::Type_Struct *> newTypeDeclarations;

    const IR::P4Program *create(const IR::P4Program *program) override;

    T5naProgramStructure() :
        ProgramStructure() { }
};

}  // namespace BFN

#endif  /* EXTENSIONS_BF_P4C_ARCH_TNA_T5NA_PROGRAM_STRUCTURE_H_ */
