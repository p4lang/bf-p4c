#ifndef EXTENSIONS_BF_P4C_COMMON_FRONT_END_POLICY_H_
#define EXTENSIONS_BF_P4C_COMMON_FRONT_END_POLICY_H_

#include "frontends/p4/frontend.h"

namespace BFN {

struct FrontEndPolicy : P4::FrontEndPolicy {
    P4::ParseAnnotations *getParseAnnotations() const override { return pars; }

    bool skipSideEffectOrdering() const override { return skip_side_effect_ordering; }

    explicit FrontEndPolicy(P4::ParseAnnotations *parseAnnotations)
        : pars(parseAnnotations), skip_side_effect_ordering(false) {}

    explicit FrontEndPolicy(P4::ParseAnnotations *parseAnnotations, bool skip_side_effect_ordering)
        : pars(parseAnnotations), skip_side_effect_ordering(skip_side_effect_ordering) {}

 private:
    P4::ParseAnnotations *pars;
    bool skip_side_effect_ordering;
};

}  // namespace BFN

#endif  /* EXTENSIONS_BF_P4C_COMMON_FRONT_END_POLICY_H_ */
