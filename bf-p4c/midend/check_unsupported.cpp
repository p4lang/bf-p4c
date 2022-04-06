#include "bf-p4c/midend/check_unsupported.h"
#include "frontends/p4/methodInstance.h"

namespace BFN {

bool CheckUnsupported::preorder(const IR::PathExpression* path_expression) {
    static const IR::Path SAMPLE3(IR::ID("sample3"), false);
    static const IR::Path SAMPLE4(IR::ID("sample4"), false);

    if (*path_expression->path == SAMPLE3 || *path_expression->path == SAMPLE4) {
        ::error(
            ErrorType::ERR_UNSUPPORTED,
            "Primitive %1% is not supported by the backend",
            path_expression->path);
        return false;
    }
    return true;
}

void CheckUnsupported::postorder(const IR::P4Table *tbl) {
    if (auto *key = tbl->getKey()) {
        int lpm_count = 0;
        for (auto &ke : key->keyElements) {
            if (ke->matchType->path->name == "lpm")
                ++lpm_count;
        }
        if (lpm_count > 1)
            error(ErrorType::ERR_UNSUPPORTED, "%1%table %2% Cannot match on multiple fields using "
                  "lpm match type", tbl->srcInfo, tbl->name.originalName);
    }
}

}  // namespace BFN
