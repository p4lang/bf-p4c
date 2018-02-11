#ifndef EXTENSIONS_BF_P4C_PHV_PRAGMA_PHV_PRAGMAS_H_
#define EXTENSIONS_BF_P4C_PHV_PRAGMA_PHV_PRAGMAS_H_

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/phv/pragma/pa_container_size.h"
#include "bf-p4c/phv/pragma/pa_mutually_exclusive.h"
#include "bf-p4c/phv/pragma/pa_solitary.h"

namespace PHV {
namespace pragma {

constexpr const char* MUTUALLY_EXCLUSIVE = "pa_mutually_exclusive";
constexpr const char* CONTAINER_SIZE     = "pa_container_size";
constexpr const char* SOLITARY           = "pa_solitary";

}

class Pragmas : public PassManager {
 private:
    PragmaContainerSize         pa_container_sizes_i;
    PragmaMutuallyExclusive     pa_mutually_exclusive_i;
    PragmaSolitary              pa_solitary_i;

 public:
    PragmaContainerSize& pa_container_sizes() { return pa_container_sizes_i; }
    PragmaMutuallyExclusive& pa_mutually_exclusive() { return pa_mutually_exclusive_i; }
    PragmaSolitary& pa_solitary() { return pa_solitary_i; }

    explicit Pragmas(PhvInfo& phv, const BFN_Options &options)
        : pa_container_sizes_i(phv), pa_mutually_exclusive_i(phv), pa_solitary_i(phv) {
        addPasses({
            &pa_container_sizes_i,
            &pa_mutually_exclusive_i,
            options.use_pa_solitary ? &pa_solitary_i : nullptr,
        });
    }
};


}  // namespace PHV

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PHV_PRAGMAS_H_ */
