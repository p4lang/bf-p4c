#ifndef EXTENSIONS_BF_P4C_COMMON_COLLECT_GLOBAL_PRAGMA_H_
#define EXTENSIONS_BF_P4C_COMMON_COLLECT_GLOBAL_PRAGMA_H_

#include <vector>
#include "ir/ir.h"

class CollectGlobalPragma : public Inspector {
    static const std::vector<cstring> *g_global_pragma_names;
    std::vector<const IR::Annotation*> global_pragmas_;
    bool preorder(const IR::Annotation *) override;

 public:
    const std::vector<const IR::Annotation*>& global_pragmas() const { return global_pragmas_; }
};

#endif /* EXTENSIONS_BF_P4C_COMMON_COLLECT_GLOBAL_PRAGMA_H_ */
