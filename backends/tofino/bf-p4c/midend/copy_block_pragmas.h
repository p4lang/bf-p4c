#ifndef BF_P4C_MIDEND_COPY_BLOCK_PRAGMAS_H_
#define BF_P4C_MIDEND_COPY_BLOCK_PRAGMAS_H_

#include "ir/ir.h"
#include "frontends/p4/typeChecking/typeChecker.h"

/**
 * \ingroup midend
 * \brief Pass that copies block annotations to the block's tables.
 */
class CopyBlockPragmas : public PassManager {
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    std::set<cstring> pragmas;
    std::map<const IR::P4Table *, ordered_map<cstring, const IR::Annotation *>>   toAdd;
    class FindPragmasFromApply;
    class CopyToTables;

 public:
    CopyBlockPragmas(P4::ReferenceMap *refMap, P4::TypeMap *typeMap, P4::TypeChecking *typeChecking,
                     std::set<cstring> pragmas);
    CopyBlockPragmas(P4::ReferenceMap *refMap, P4::TypeMap *typeMap, std::set<cstring> pragmas)
    : CopyBlockPragmas(refMap, typeMap, new P4::TypeChecking(refMap, typeMap), pragmas) {}
};

#endif /* BF_P4C_MIDEND_COPY_BLOCK_PRAGMAS_H_ */
