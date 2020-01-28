#ifndef BF_P4C_POST_MIDEND_H_
#define BF_P4C_POST_MIDEND_H_

#include "ir/ir.h"
#include "frontends/p4/typeMap.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "bf-p4c/midend/param_binding.h"
#include "bf-p4c/common/extract_maupipe.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/midend/normalize_params.h"
#include "bf-p4c/midend/blockmap.h"
#include "bf-p4c/midend/simplify_references.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/flexible_packing.h"

namespace BFN {

// Apply this pass manager to IR::P4Program after midend processing.
// Returns IR::P4Program after flexible metadata packing.
class PostMidEnd : public PassManager {
    ParamBinding* bindings;
    ApplyEvaluator *evaluator;
    BackendConverter *conv;
    RepackedHeaderTypes *map;

 public:
    P4::ReferenceMap refMap;
    P4::TypeMap typeMap;

 public:
    PostMidEnd(BFN_Options& options, RepackedHeaderTypes* repackMap,
               bool with_bridge_packing = false);

    IR::Vector<IR::BFN::Pipe> pipe;

    const ProgramThreads &getThreads() const { return conv->getThreads(); }
    const IR::ToplevelBlock *getToplevelBlock() const { return evaluator->toplevel; }
};

}  // namespace BFN

#endif /* BF_P4C_POST_MIDEND_H_ */
