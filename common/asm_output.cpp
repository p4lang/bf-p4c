#include "asm_output.h"

StringRef trim_asm_name(StringRef name) {
    if (auto *p = name.findlast('['))
        name = name.before(p);
    if (auto *p = name.findlast(':'))
        name = name.after(p+1);
    return name;
}

