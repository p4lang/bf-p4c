#ifndef _cloudbreak_phv_h_
#define _cloudbreak_phv_h_

#include "../jbay/phv.h"

class Target::Cloudbreak::Phv : public Target::JBay::Phv {
    target_t type() const override { return TOFINO3; }
};

#endif /* _cloudbreak_phv_h_ */
