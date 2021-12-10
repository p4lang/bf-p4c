#ifndef BF_P4C_COMMON_CHECK_UNINITIALIZED_READ_H_
#define BF_P4C_COMMON_CHECK_UNINITIALIZED_READ_H_

#include "ir/ir.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

class CheckUninitializedRead : public Inspector {
 private:
    const FieldDefUse &defuse;
    const PhvInfo &phv;
    const PHV::Pragmas &pragmas;
 public:
    CheckUninitializedRead(
         const FieldDefUse &defuse,
         const PhvInfo &phv,
         const PHV::Pragmas &pragmas) :
         defuse(defuse), phv(phv), pragmas(pragmas) {}
    void end_apply() override;
};


#endif /* BF_P4C_COMMON_CHECK_UNINITIALIZED_READ_H_ */
