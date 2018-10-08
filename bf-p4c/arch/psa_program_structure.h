#ifndef EXTENSIONS_BF_P4C_ARCH_PSA_PROGRAM_STRUCTURE_H_
#define EXTENSIONS_BF_P4C_ARCH_PSA_PROGRAM_STRUCTURE_H_

#include "ir/ir.h"
#include "ir/namemap.h"
#include "lib/ordered_set.h"
#include "bf-p4c/arch/program_structure.h"
#include "bf-p4c/arch/psa_model.h"
#include "bf-p4c/ir/gress.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"

namespace BFN {

namespace PSA {

// structure to describe the info related to resubmit/clone/recirc in a PSA program
struct PacketPathInfo {
    /// The name of the resubmit_metadata in ingress parser param.
    cstring paramNameInParser;

    /// The name of the resubmit_metadata in egress deparser param.
    cstring paramNameInDeparser;

    /// name in compiler_generated_meta
    cstring generatedName;

    /// Map user-defined name to arch-defined param name in source block.
    ordered_map<cstring, cstring> srcParams;

    /// Map arch-defined param name to user-defined name in dest block.
    ordered_map<cstring, cstring> dstParams;

    /// A P4 type for the resubmit data, based on the type of the parameter to
    /// the parser.
    const IR::Type* p4Type = nullptr;
    // the statements in deparser to emit resubmit metadata, in PSA, the emit
    // is represented with assignments to out parameter in the deparser block.
    // the source typically has the following code pattern.
    // if (psa_resubmit(istd)) {
    //    resub_meta = user_meta.resub_meta;
    // }
    std::vector<const IR::IfStatement*> ifStatements;

    ordered_map<const IR::StatOrDecl*, std::vector<const IR::Node*>> fieldLists;
};

using ParamInfo = ordered_map<cstring, cstring>;

struct PsaBlockInfo {
    ParamInfo psaParams;
};

enum PSA_TYPES {
    TYPE_IH = 0, TYPE_IM, TYPE_EH, TYPE_EM, TYPE_NM,
    TYPE_CI2EM, TYPE_CE2EM, TYPE_RESUBM, TYPE_RECIRCM,
    PSA_TOTAL_TYPES};

struct ProgramStructure : BFN::ProgramStructure {
    cstring type_params[PSA_TOTAL_TYPES];

    PsaModel &psa_model;

    ordered_map<cstring, TranslationMap> methodcalls;

    // map the resub_md and recirc_md to the user-provided name and type.
    ordered_map<cstring, cstring> psaPacketPathNames;
    ordered_map<cstring, const IR::Type *> psaPacketPathTypes;

    const IR::Type* bridgedType;

    PacketPathInfo resubmit;
    PacketPathInfo clone_i2e;
    PacketPathInfo clone_e2e;
    PacketPathInfo recirculate;
    PacketPathInfo bridge;

    PsaBlockInfo ingress_parser;
    PsaBlockInfo ingress;
    PsaBlockInfo ingress_deparser;
    PsaBlockInfo egress_parser;
    PsaBlockInfo egress;
    PsaBlockInfo egress_deparser;

    void createParsers() override;
    void createControls() override;
    void createMain() override;
    void createPipeline();

    const IR::P4Program *create(const IR::P4Program *program) override;

    ProgramStructure() :
        BFN::ProgramStructure(), psa_model(PsaModel::instance) { }
};

}  // namespace PSA

}  // namespace BFN

#endif  /* EXTENSIONS_BF_P4C_ARCH_PSA_PROGRAM_STRUCTURE_H_ */
