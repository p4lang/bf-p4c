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
using ExternInstanceMap = ordered_map<const IR::Declaration_Instance*,
                                      const IR::Declaration_Instance*>;
using ExternMethodMap = ordered_map<const IR::MethodCallExpression*,
                                    const IR::MethodCallExpression*>;
using ExternFunctionMap = ordered_map<const IR::MethodCallStatement*,
                                      const IR::Statement*>;
using ExternFunctionNameMap = ordered_map<const IR::MethodCallStatement*, cstring>;

using StatementMap = ordered_map<const IR::Statement*, const IR::Statement*>;
using StatementNameMap = ordered_map<const IR::Statement*, cstring>;

// used by parser counter translation
using MemberStatementMap = ordered_map<const IR::Node*, const IR::Node*>;

// used by checksum translation
using ChecksumSourceMap = ordered_map<const IR::Member*,
                                      const IR::MethodCallExpression*>;

/// Experimental implementation of programStructure to facilitate the
/// translation between P4-16 program of different architecture.
class ProgramStructure {
 public:
    /// read architecture definition in 'filename', output a list of
    /// IR::Node in 'decl'
    void include(cstring filename, IR::IndexedVector<IR::Node>* decls);
    void include14(cstring filename, IR::IndexedVector<IR::Node>* decls);

    IR::IndexedVector<IR::Node>                  declarations;
    IR::IndexedVector<IR::Node>                  tofinoArchTypes;

    /// target architecture types
    ordered_set<cstring>                         errors;
    ordered_set<const IR::Type_MatchKind*>       match_kinds;
    ordered_map<cstring, const IR::Type_Enum*>   enums;
    ordered_map<cstring, const IR::Type_Extern*> extern_types;
    ordered_map<cstring, const IR::Type_Typedef*> typedefs;
    ordered_set<cstring>                         unique_declarations;

    /// maintain program declarations to reprint a valid P16 program
    ordered_map<cstring, const IR::P4Control*>   controls;
    ordered_map<cstring, const IR::P4Parser*>    parsers;
    ordered_map<cstring, const IR::Type_Header*> header_types;
    ordered_map<cstring, const IR::Type_Struct*> struct_types;
    ordered_map<cstring, const IR::Type_HeaderUnion*> header_union_types;
    ordered_map<cstring, const IR::Type_Typedef*> typedef_types;
    std::vector<const IR::Type_Action*>          action_types;

    // maintain symbol tables for program transformation
    ChecksumSourceMap                            checksums;

    // map ingress/egress to hash
    ExternInstanceMap                            counters;
    ExternInstanceMap                            direct_counters;
    ExternInstanceMap                            meters;
    ExternInstanceMap                            direct_meters;
    ExternMethodMap                              counterCalls;
    ExternMethodMap                              directCounterCalls;
    ExternMethodMap                              meterCalls;
    ExternFunctionMap                            directMeterCalls;
    ExternFunctionMap                            hashCalls;
    ExternFunctionNameMap                        hashNames;
    ExternFunctionMap                            resubmitCalls;
    ExternFunctionMap                            digestCalls;
    ExternFunctionMap                            cloneCalls;
    ExternFunctionMap                            dropCalls;
    ExternFunctionMap                            randomCalls;
    ExternFunctionNameMap                        randomNames;

    // parser related translations
    StatementMap                                 priorityCalls;
    StatementNameMap                             priorityNames;
    StatementMap                                 parserCounterCalls;
    SimpleNameMap                                parserCounterNames;
    MemberStatementMap                           parserCounterSelects;

    /// system metadata is metadata from v1model or p4-14 intrinsic_metadata
    ordered_map<cstring, const IR::Node*>        system_metadata;
    IR::IndexedVector<IR::Node>                  user_program;

    /// user program specific info
    cstring                                      type_h;
    cstring                                      type_m;
    const IR::Parameter*                         user_metadata;
    std::vector<const IR::Declaration *>         ingressDeclarations;
    std::vector<const IR::Declaration *>         egressDeclarations;
    std::vector<const IR::Declaration *>         ingressDeparserDeclarations;
    std::vector<const IR::Declaration *>         egressDeparserDeclarations;
    std::vector<const IR::StatOrDecl *>          ingressDeparserStatements;
    safe_vector<const IR::StatOrDecl *>          egressDeparserStatements;
    std::vector<const IR::Declaration *>         ingressParserDeclarations;

    ordered_map<const IR::Member*, const IR::Member*> membersToDo;
    /// maintain the paths to translate and their thread info
    ordered_map<const IR::Member*, const IR::Member*> pathsToDo;
    ordered_map<const IR::Member*, gress_t>           pathsThread;
    ordered_map<const IR::Member*, const IR::Member*> typeNamesToDo;

    /// map from source extern type to dest extern type
    /// this map is populated by manually by the ReplaceArchitecture pass.
    ordered_map<cstring, cstring>                 externNameMap;

    /// map metadata identified by a tuple {structure name, field name}
    /// to another metadata identified by the same tuple
    std::map<std::pair<cstring, cstring>, std::pair<cstring, cstring>> metadataNameMap;
    std::map<std::pair<cstring, cstring>, unsigned> metadataTypeMap;

    /// all unique names in the program
    std::set<cstring>                            unique_names;

    /// program control block names from P14
    const IR::ToplevelBlock*                     toplevel;

    /// map standard parser and control block name to
    /// arbitrary name assigned by user.
    ordered_map<cstring, cstring>                blockNames;
    cstring getBlockName(cstring name);

    void createErrors();
    void createEnums();
    void createTofinoArch();
    void createTypes();
    void createActions();
    void createExterns();
    void cvtExpressions();
    void createParsers();
    void createControls();
    void createMain();
    const IR::P4Program* create(const IR::P4Program* program);
};

}  // namespace BFN

#endif  /* EXTENSIONS_BF_P4C_ARCH_PROGRAM_STRUCTURE_H_ */
