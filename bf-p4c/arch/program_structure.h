#ifndef EXTENSIONS_TOFINO_ARCH_PROGRAM_STRUCTURE_H_
#define EXTENSIONS_TOFINO_ARCH_PROGRAM_STRUCTURE_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"

namespace Tofino {

/// Experimental implementation of programStructure to facilitate the
/// translation between P4-16 program of different architecture.
class ProgramStructure {
 protected:
    void mkTypes();
    void mkControls();
    void mkExterns();
    void mkParsers();
    void mkDeparsers();
    void mkMain();

 public:
    IR::IndexedVector<IR::Node>* declarations;
    IR::IndexedVector<IR::Node>* tofinoArchTypes;

    ProgramStructure();
    void include(cstring filename, IR::IndexedVector<IR::Node>* decls);
    void include14(cstring filename, IR::IndexedVector<IR::Node>* decls);
    const IR::P4Program* translate(Util::SourceInfo info);

    std::map<const IR::Member*, const IR::Member*>  metadataMap;

    std::vector<const IR::P4Control*>   controls;
    std::vector<const IR::P4Parser*>    parsers;
    std::vector<const IR::Type_Extern*> externs;
    std::vector<const IR::Type_Header*> headers;
    std::vector<const IR::Type_Struct*> structs;
    std::vector<const IR::Declaration_Instance*> declaration_instances;

    /// system metadata is metadata from v1model or p4-14 intrinsic_metadata
    std::map<cstring, const IR::Node*> system_metadata;
    /// user metadata is metadata defined in user program
    std::map<cstring, const IR::Node*> user_metadata;

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

}  // namespace Tofino

#endif  /* EXTENSIONS_TOFINO_ARCH_PROGRAM_STRUCTURE_H_ */
