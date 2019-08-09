#ifndef EXTENSIONS_BF_P4C_PHV_PRAGMA_PHV_PRAGMAS_H_
#define EXTENSIONS_BF_P4C_PHV_PRAGMA_PHV_PRAGMAS_H_

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/phv/pragma/pa_atomic.h"
#include "bf-p4c/phv/pragma/pa_alias.h"
#include "bf-p4c/phv/pragma/pa_container_size.h"
#include "bf-p4c/phv/pragma/pa_container_type.h"
#include "bf-p4c/phv/pragma/pa_deparser_zero.h"
#include "bf-p4c/phv/pragma/pa_mutually_exclusive.h"
#include "bf-p4c/phv/pragma/pa_no_init.h"
#include "bf-p4c/phv/pragma/pa_no_overlay.h"
#include "bf-p4c/phv/pragma/pa_solitary.h"

namespace PHV {
namespace pragma {

constexpr const char* NOT_PARSED         = "not_parsed";
constexpr const char* NOT_DEPARSED       = "not_deparsed";
constexpr const char* DISABLE_DEPARSE_ZERO = "pa_disable_deparse_0_optimization";

}   // namespace pragma

class Pragmas : public PassManager {
 public:
    /// @returns true if for the associated @pragmaName, the @gress is either ingress or egress.
    static bool gressValid(cstring pragmaName, cstring gress) {
        if (gress != "ingress" && gress != "egress") {
            ::warning("@pragma %1%'s first argument must either be ingress/egress, "
                      "instead of %2%, skipped", pragmaName, gress);
            return false;
        }
        return true;
    }

 private:
    PragmaContainerSize         pa_container_sizes_i;
    PragmaMutuallyExclusive     pa_mutually_exclusive_i;
    PragmaSolitary              pa_solitary_i;
    PragmaAtomic                pa_atomic_i;
    PragmaNoOverlay             pa_no_overlay_i;
    PragmaContainerType         pa_container_type_i;
    PragmaNoInit                pa_no_init_i;
    PragmaDeparserZero          pa_deparser_zero_i;

 public:
    const PragmaContainerSize& pa_container_sizes() const { return pa_container_sizes_i; }
    PragmaContainerSize& pa_container_sizes()             { return pa_container_sizes_i; }

    const PragmaMutuallyExclusive& pa_mutually_exclusive() const { return pa_mutually_exclusive_i; }
    PragmaMutuallyExclusive& pa_mutually_exclusive()             { return pa_mutually_exclusive_i; }

    const PragmaSolitary& pa_solitary() const { return pa_solitary_i; }
    PragmaSolitary& pa_solitary()             { return pa_solitary_i; }

    const PragmaAtomic& pa_atomic() const { return pa_atomic_i; }
    PragmaAtomic& pa_atomic()             { return pa_atomic_i; }

    const PragmaNoOverlay& pa_no_overlay() const { return pa_no_overlay_i; }
    PragmaNoOverlay& pa_no_overlay()             { return pa_no_overlay_i; }

    const PragmaContainerType& pa_container_type() const { return pa_container_type_i; }
    PragmaContainerType& pa_container_type()             { return pa_container_type_i; }

    const PragmaNoInit& pa_no_init() const  { return pa_no_init_i; }
    PragmaNoInit& pa_no_init()              { return pa_no_init_i; }

    const PragmaDeparserZero& pa_deparser_zero() const    { return pa_deparser_zero_i; }
    PragmaDeparserZero& pa_deparser_zero()                { return pa_deparser_zero_i; }

    explicit Pragmas(PhvInfo& phv, const BFN_Options &options)
        : pa_container_sizes_i(phv, options.disabled_pragmas),
          pa_mutually_exclusive_i(phv, options.disabled_pragmas),
          pa_solitary_i(phv, options.disabled_pragmas),
          pa_atomic_i(phv, options.disabled_pragmas),
          pa_no_overlay_i(phv, options.disabled_pragmas),
          pa_container_type_i(phv, options.disabled_pragmas),
          pa_no_init_i(phv, options.disabled_pragmas),
          pa_deparser_zero_i(phv, options.disabled_pragmas) {
        addPasses({
            &pa_container_sizes_i,
            &pa_mutually_exclusive_i,
            options.use_pa_solitary ? &pa_solitary_i : nullptr,
            &pa_atomic_i,
            &pa_no_overlay_i,
            &pa_container_type_i,
            &pa_no_init_i,
            &pa_deparser_zero_i
        });
    }

    // Constructor only used for GTest.
    explicit Pragmas(PhvInfo& phv)
        : pa_container_sizes_i(phv),
          pa_mutually_exclusive_i(phv),
          pa_solitary_i(phv),
          pa_atomic_i(phv),
          pa_no_overlay_i(phv),
          pa_container_type_i(phv),
          pa_no_init_i(phv),
          pa_deparser_zero_i(phv) {
        addPasses({
            &pa_container_sizes_i,
            &pa_mutually_exclusive_i,
            &pa_solitary_i,
            &pa_atomic_i,
            &pa_no_overlay_i,
            &pa_container_type_i,
            &pa_no_init_i,
            &pa_deparser_zero_i
        });
    }
};

}  // namespace PHV

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PHV_PRAGMAS_H_ */
