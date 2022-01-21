#ifndef BF_P4C_COMMON_CHECK_UNINITIALIZED_READ_H_
#define BF_P4C_COMMON_CHECK_UNINITIALIZED_READ_H_

#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "ir/ir.h"

class CheckUninitializedRead : public Inspector {
 private:
    const FieldDefUse &defuse;
    const PhvInfo &phv;
    const PHV::Pragmas &pragmas;
    static bool printed;
 public:
    CheckUninitializedRead(
         const FieldDefUse &defuse,
         const PhvInfo &phv,
         const PHV::Pragmas &pragmas) :
         defuse(defuse), phv(phv), pragmas(pragmas) {}
    static void set_printed() {printed = true;}

    // unset_printed is intended to be only used in gtest unit test, the reason to unset printed is
    // because gtest may call CheckUninitializedRead multiple times, but warning message will only
    // presented once. Therefore, gtest may not capture the warning message.
    static void unset_printed() {printed = false;}
    void end_apply() override;
};


#endif /* BF_P4C_COMMON_CHECK_UNINITIALIZED_READ_H_ */
