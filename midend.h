#ifndef TOFINO_MIDEND_H_
#define TOFINO_MIDEND_H_

#include "frontends/common/options.h"
#include "frontends/common/typeMap.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "midend/inlining.h"
#include "midend/actionsInlining.h"

namespace Tofino {

class MidEnd : public PassManager {
    const bool                  isv1;
    P4::EvaluatorPass           evaluator;
    P4::ReferenceMap            refMap;
    P4::TypeMap                 typeMap;
    P4::InlineWorkList          toInline;
    P4::ActionsInlineList       actionsToInline;

 public:
    explicit MidEnd(const CompilerOptions &options);
    P4::BlockMap *getBlockMap() { return evaluator.getBlockMap(); }
};

}  // namespace Tofino

#endif /* TOFINO_MIDEND_H_ */
