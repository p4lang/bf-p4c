#ifndef EXTENSIONS_BF_P4C_ARCH_PROGRAM_STRUCTURE_H_
#define EXTENSIONS_BF_P4C_ARCH_PROGRAM_STRUCTURE_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"

namespace BFN {

/// Experimental implementation of programStructure to facilitate the
/// translation between P4-16 program of different architecture.
class ProgramStructure {
 public:
    IR::IndexedVector<IR::Node>* declarations;
    IR::IndexedVector<IR::Node>* tofinoArchTypes;

    ProgramStructure() {
        declarations = new IR::IndexedVector<IR::Node>();
        tofinoArchTypes = new IR::IndexedVector<IR::Node>();
    }
    void include(cstring filename, IR::IndexedVector<IR::Node>* decls);
    void include14(cstring filename, IR::IndexedVector<IR::Node>* decls);
    const IR::P4Program* translate(Util::SourceInfo info);

    std::map<const IR::Member*, const IR::Member*>  metadataMap;

    std::vector<const IR::P4Control*>   controls;
    std::vector<const IR::P4Parser*>    parsers;
    std::vector<const IR::Type_Extern*> externs;
    std::map<cstring, const IR::Type_Header*> headers;
    std::vector<const IR::Type_Struct*> structs;
    std::vector<const IR::Declaration_Instance*> declaration_instances;

    // XXX(hanw): create an IR::Tofino primitve type for resubmit.
    std::vector<const IR::Type_Header*> extern_resubmit;
    std::vector<const IR::Type_Header*> extern_recirculate;
    std::vector<const IR::Type_Header*> extern_clone;

    /// system metadata is metadata from v1model or p4-14 intrinsic_metadata
    std::map<cstring, const IR::Node*> system_metadata;

    bool isOldSystemMetadata(cstring name) {
        auto it = system_metadata.find(name);
        return it != system_metadata.end();
    }

    IR::ConstructorCallExpression* mkConstructorCallExpression(cstring name) {
        auto args = new IR::Vector<IR::Expression>();
        auto path = new IR::Path(name);
        auto type = new IR::Type_Name(path);
        auto call = new IR::ConstructorCallExpression(type, args);
        return call;
    }
};

}  // namespace BFN

#endif  /* EXTENSIONS_BF_P4C_ARCH_PROGRAM_STRUCTURE_H_ */
