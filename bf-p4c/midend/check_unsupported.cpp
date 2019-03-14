#include "bf-p4c/midend/check_unsupported.h"
#include "frontends/p4/methodInstance.h"

namespace BFN {

void CheckUnsupported::postorder(const IR::P4Table *tbl) {
    if (auto *key = tbl->getKey()) {
        int lpm_count = 0;
        for (auto &ke : key->keyElements) {
            if (ke->matchType->path->name == "lpm")
                ++lpm_count;
        }
        if (lpm_count > 1)
            error(ErrorType::ERR_UNSUPPORTED, "table %2% Cannot match on multiple fields using "
                  "lpm match type", tbl->srcInfo, tbl->name.originalName);
    }
}

}  // namespace BFN
