#include <iostream>
#include "disasm.h"

Disasm *Disasm::create(std::string target) {
#define CREATE_TARGET(TARGET, ...) if (target == Target::TARGET::name) return new Disasm::TARGET;
    FOR_ALL_TARGETS(CREATE_TARGET);
#undef CREATE_TARGET
    std::cerr << "Unsupported target " << target << std::endl;
    return nullptr;
}
