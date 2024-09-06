#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_MERGE_DESUGARED_VARBIT_VALIDS_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_MERGE_DESUGARED_VARBIT_VALIDS_H_

#include "ir/visitor.h"
#include "ir/pass_manager.h"
#include "lib/ordered_map.h"

class PhvInfo;
class ClotInfo;
class PragmaAlias;

class MergeDesugaredVarbitValids : public PassManager {
    ordered_map<cstring, const IR::Member*> field_expressions;

 public:
    explicit MergeDesugaredVarbitValids(const PhvInfo &phv, const ClotInfo &clot_info,
                                        PragmaAlias &pragma);
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_MERGE_DESUGARED_VARBIT_VALIDS_H_ */

