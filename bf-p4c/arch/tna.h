#ifndef BF_P4C_ARCH_TNA_H_
#define BF_P4C_ARCH_TNA_H_

#include "ir/ir.h"
#include "arch.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

class BFN_Options;

namespace BFN {

/**
 * Normalize a TNA program's control and package instantiations so that later
 * passes don't need to account for minor variations in the architecture.
 *
 * The TNA architecture includes a number of `@optional` parameters to controls.
 * Users who don't need the metadata in these parameters can avoid some
 * boilerplate by leaving them out of the parameter list of the controls they
 * instantiate the TNA package with. This makes life easier for the user, but it
 * means that the compiler must contend with TNA programs which may or may not
 * include these parameters.
 *
 * To make things simpler for the rest of the midend and backend, this pass
 * reintroduces all the optional parameters.
 *
 * @pre The IR represents a valid TNA program, and all midend passes have run.
 * @post The IR represents a valid TNA program with all `@optional` parameters
 * specified by the architecture present.
 */
struct NormalizeNativeProgram : public PassManager {
    NormalizeNativeProgram(P4::ReferenceMap* refMap,
                           P4::TypeMap* typeMap,
                           BFN_Options& options);
};

struct LowerTofinoToStratum : public PassManager {
    LowerTofinoToStratum(P4::ReferenceMap* refMap,
                         P4::TypeMap* typeMap,
                         BFN_Options& options);

    ProgramThreads threads;
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_TNA_H_ */
