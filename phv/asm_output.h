#ifndef _TOFINO_PHV_ASM_OUTPUT_H_
#define _TOFINO_PHV_ASM_OUTPUT_H_

#include "phv_fields.h"
#include "lib/stringref.h"

class PhvAsmOutput {
    const PhvInfo     &phv;
    friend std::ostream &operator<<(std::ostream &, const PhvAsmOutput &);
public:
    PhvAsmOutput(const PhvInfo &p) : phv(p) {}
};

class canon_name {
    StringRef   name;
    friend std::ostream &operator<<(std::ostream &, canon_name);
public:
    canon_name(StringRef n) : name(n) {}
};

#endif /* _TOFINO_PHV_ASM_OUTPUT_H_ */
