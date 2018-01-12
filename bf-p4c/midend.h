#ifndef BF_P4C_MIDEND_H_
#define BF_P4C_MIDEND_H_

#include "bf-p4c/bf-p4c-options.h"
#include "ir/ir.h"
#include "frontends/common/options.h"
#include "frontends/p4/evaluator/evaluator.h"

namespace BFN {

class MidEnd : public PassManager {
 public:
    // These will be accurate when the mid-end completes evaluation
    P4::ReferenceMap    refMap;
    P4::TypeMap         typeMap;
    IR::ToplevelBlock   *toplevel = nullptr;  // Should this be const?

    explicit MidEnd(BFN_Options& options);
};

}  // namespace BFN

#endif /* BF_P4C_MIDEND_H_ */
