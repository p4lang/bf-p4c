/**
 * \defgroup T2naArchTranslation BFN::T2naArchTranslation
 * \ingroup ArchTranslation
 * \brief Set of passes that translate T2NA architecture.
 */
#ifndef BF_P4C_ARCH_T2NA_H_
#define BF_P4C_ARCH_T2NA_H_

#include "ir/ir.h"
#include "ir/pass_manager.h"

#include "arch.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

class BFN_Options;

namespace BFN {

/**
 * \ingroup T2naSwitchTranslation
 * \brief PassManager that governs normalization of T2NA architecture.
 */
struct T2naArchTranslation : public PassManager {
    T2naArchTranslation(P4::ReferenceMap* refMap,
                        P4::TypeMap* typeMap,
                        BFN_Options& options);

    ProgramPipelines pipelines;
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_T2NA_H_ */
