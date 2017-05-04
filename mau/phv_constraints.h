#ifndef _TOFINO_MAU_PHV_CONSTRAINTS_H_
#define _TOFINO_MAU_PHV_CONSTRAINTS_H_

#include "mau_visitor.h"
#include "tofino/phv/phv_fields.h"

class MauPhvConstraints : public MauInspector {
    PhvInfo     &phv;
 public:
    explicit MauPhvConstraints(PhvInfo &p) : phv(p) {}
};

#endif /* _TOFINO_MAU_PHV_CONSTRAINTS_H_ */
