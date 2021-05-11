#ifndef BF_P4C_ARCH_T5NA_H_
#define BF_P4C_ARCH_T5NA_H_

#include "ir/ir.h"
#include "arch.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

class BFN_Options;

namespace BFN {

struct T5naArchTranslation : public PassManager {
    T5naArchTranslation(P4::ReferenceMap* refMap,
                        P4::TypeMap* typeMap,
                        BFN_Options& options);

    ProgramThreads threads;
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_T5NA_H_ */
