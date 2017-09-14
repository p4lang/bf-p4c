#ifndef BF_P4C_PHV_ASM_OUTPUT_H_
#define BF_P4C_PHV_ASM_OUTPUT_H_

#include "phv_fields.h"
#include "lib/stringref.h"
#include "bf-p4c/common/asm_output.h"

class PhvAsmOutput {
    const PhvInfo     &phv;
    friend std::ostream &operator<<(std::ostream &, const PhvAsmOutput &);
 public:
    explicit PhvAsmOutput(const PhvInfo &p) : phv(p) {}
};

#endif /* BF_P4C_PHV_ASM_OUTPUT_H_ */
