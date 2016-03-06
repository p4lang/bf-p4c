#ifndef _TOFINO_COMMON_ASM_OUTPUT_H_
#define _TOFINO_COMMON_ASM_OUTPUT_H_

#include "lib/stringref.h"

StringRef trim_asm_name(StringRef name);

class canon_name {
    StringRef   name;
    friend std::ostream &operator<<(std::ostream &, canon_name);
 public:
    explicit canon_name(StringRef n) : name(n) {}
};

#endif /* _TOFINO_COMMON_ASM_OUTPUT_H_ */
