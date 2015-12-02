#ifndef _TOFINO_PHV_ASM_OUTPUT_H_
#define _TOFINO_PHV_ASM_OUTPUT_H_

#include "phv_fields.h"

class PhvAsmOutput {
    const PhvInfo     &phv;
    friend std::ostream &operator<<(std::ostream &, const PhvAsmOutput &);
public:
    PhvAsmOutput(const PhvInfo &p) : phv(p) {}
};

#endif /* _TOFINO_PHV_ASM_OUTPUT_H_ */
