#ifndef EXTENSIONS_BF_P4C_ARCH_PROGRAM_STRUCTURE_H_
#define EXTENSIONS_BF_P4C_ARCH_PROGRAM_STRUCTURE_H_

#include "ir/ir.h"
#include "ir/namemap.h"
#include "lib/ordered_set.h"
#include "bf-p4c/ir/gress.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"

namespace BFN {

using MetadataMap = ordered_map<cstring, IR::MetadataInfo*>;
using SimpleNameMap = std::map<cstring, cstring>;
using TranslationMap = ordered_map<const IR::Node*, const IR::Node*>;
using NodeNameMap = ordered_map<const IR::Node*, cstring>;

// used by checksum translation
using ChecksumSourceMap = ordered_map<const IR::Member*,
                                      const IR::MethodCallExpression*>;

/// A helper struct used to construct the metadata remapping tables.
struct MetadataField {
    cstring structName;
    cstring fieldName;
    int width;

    bool operator<(const MetadataField& other) const {
        if (structName != other.structName)
            return structName < other.structName;
        return fieldName < other.fieldName;
    }

    bool operator==(const MetadataField& other) const {
        return structName == other.structName &&
               fieldName == other.fieldName;
    }
};

template<class converter>
class TranslationUnit {
 public:
    IR::Node* originalNode;
    IR::Node* translatedNode;
    converter* conv;
    // convert();
};

struct ProgramStructure {
    static const cstring INGRESS_PARSER;
    static const cstring INGRESS;
    static const cstring INGRESS_DEPARSER;
    static const cstring EGRESS_PARSER;
    static const cstring EGRESS;
    static const cstring EGRESS_DEPARSER;

    /// read architecture definition in 'filename', output a list of
    /// IR::Node in 'decl'
    void include(cstring filename, IR::IndexedVector<IR::Node>* decls);

    IR::IndexedVector<IR::Node>                  declarations;
    IR::IndexedVector<IR::Node>                  targetTypes;
    /// target architecture types
    ordered_set<cstring>                         errors;
    ordered_map<cstring, const IR::Type_Enum*>   enums;

    TranslationMap                               counters;
    TranslationMap                               direct_counters;
    TranslationMap                               meters;
    TranslationMap                               direct_meters;

    NodeNameMap                                  nameMap;

    /// maintain program declarations to reprint a valid P16 program
    ordered_map<cstring, const IR::P4Control*>   controls;
    ordered_map<cstring, const IR::P4Parser*>    parsers;
    ordered_map<cstring, const IR::Type_Declaration*> type_declarations;
    ordered_map<cstring, const IR::Declaration_Instance*> global_instances;
    std::vector<const IR::Type_Action*>          action_types;

    /// program control block names from P14
    const IR::ToplevelBlock*                     toplevel;

    /// all unique names in the program
    std::set<cstring>                            unique_names = {"checksum", "hash", "random"};

    /// map standard parser and control block name to
    /// arbitrary name assigned by user.
    ordered_map<cstring, cstring>                blockNames;
    cstring getBlockName(cstring name);

    std::vector<const IR::Declaration *>         ingressDeclarations;
    std::vector<const IR::Declaration *>         egressDeclarations;
    std::vector<const IR::Declaration *>         ingressDeparserDeclarations;
    std::vector<const IR::Declaration *>         egressDeparserDeclarations;
    std::vector<const IR::StatOrDecl *>          ingressDeparserStatements;
    safe_vector<const IR::StatOrDecl *>          egressDeparserStatements;
    std::vector<const IR::Declaration *>         ingressParserDeclarations;
    std::vector<const IR::Declaration *>         egressParserDeclarations;

    ordered_map<const IR::Member*, const IR::Member*> membersToDo;
    /// maintain the paths to translate and their thread info
    ordered_map<const IR::Member*, const IR::Member*> pathsToDo;
    ordered_map<const IR::Member*, gress_t>           pathsThread;
    ordered_map<const IR::Member*, const IR::Member*> typeNamesToDo;

    /// Map from pre-translation metadata fields to post-translation metadata
    /// fields. The mapping may be different for each thread.
    std::map<MetadataField, MetadataField> ingressMetadataNameMap;
    std::map<MetadataField, MetadataField> egressMetadataNameMap;
    std::set<MetadataField> targetMetadataSet;

    void addMetadata(gress_t gress, MetadataField src, MetadataField dst) {
        auto &nameMap = (gress == gress_t::INGRESS) ?
                        ingressMetadataNameMap : egressMetadataNameMap;
        nameMap.emplace(src, dst);
        targetMetadataSet.insert(dst);
    }

    void addMetadata(MetadataField src, MetadataField dst) {
        addMetadata(gress_t::INGRESS, src, dst);
        addMetadata(gress_t::EGRESS, src, dst);
    }

    void createErrors();
    void createTofinoArch();
    void createTypes();
    void createActions();

    virtual void createParsers() = 0;
    virtual void createControls() = 0;
    virtual void createMain() = 0;
    virtual const IR::P4Program* create(const IR::P4Program* program) = 0;
};

namespace V1 {

/// Experimental implementation of programStructure to facilitate the
/// translation between P4-16 program of different architecture.
struct ProgramStructure : BFN::ProgramStructure {
    // maintain symbol tables for program transformation
    ChecksumSourceMap                            checksums;

    // map ingress/egress to hash
    TranslationMap                               meterCalls;
    TranslationMap                               directMeterCalls;
    TranslationMap                               hashCalls;
    TranslationMap                               resubmitCalls;
    TranslationMap                               digestCalls;
    TranslationMap                               cloneCalls;
    TranslationMap                               dropCalls;
    TranslationMap                               randomCalls;
    TranslationMap                               executeMeterCalls;
    // parser related translations
    TranslationMap                               priorityCalls;
    TranslationMap                               parserCounterCalls;
    SimpleNameMap                                parserCounterNames;
    TranslationMap                               parserCounterSelects;

    /// user program specific info
    cstring type_h;
    cstring type_m;
    const IR::Parameter *user_metadata;

    void createParsers() override;
    void createControls() override;
    void createMain() override;
    const IR::P4Program *create(const IR::P4Program *program) override;
};

}  // namespace V1

namespace PSA {

struct ProgramStructure : BFN::ProgramStructure {
    cstring type_ih;
    cstring type_im;
    cstring type_eh;
    cstring type_em;

    ordered_map<cstring, TranslationMap>  methodcalls;

    // map the resub_md and recirc_md to the user-provided name and type.
    ordered_map<cstring, cstring> psaPacketPathNames;
    ordered_map<cstring, const IR::Type*> psaPacketPathTypes;

    void createParsers() override;
    void createControls() override;
    void createMain() override;
    const IR::P4Program *create(const IR::P4Program *program) override;
};

}  // namespace PSA

}  // namespace BFN

#endif  /* EXTENSIONS_BF_P4C_ARCH_PROGRAM_STRUCTURE_H_ */
