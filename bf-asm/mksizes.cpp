#include <iostream>
#include <stdint.h>

int main() {
    if (sizeof(unsigned long long) == 2*sizeof(uintptr_t))
        std::cout << "#define uint2ptr_t unsigned long long" << std::endl;
    else if (sizeof(unsigned long) == 2*sizeof(uintptr_t))
        std::cout << "#define uint2ptr_t unsigned long" << std::endl;
    else if (sizeof(unsigned) == 2*sizeof(uintptr_t))
        std::cout << "#define uint2ptr_t unsigned" << std::endl;
    else if (sizeof(unsigned long)*2 == sizeof(uintptr_t))
        std::cout << "#define uinthptr_t unsigned long" << std::endl;
    else if (sizeof(unsigned)*2 == sizeof(uintptr_t))
        std::cout << "#define uinthptr_t unsigned" << std::endl;
    else if (sizeof(unsigned short)*2 == sizeof(uintptr_t))
        std::cout << "#define uinthptr_t unsigned short" << std::endl;
    else {
        std::cerr << "Can't find a type that is 2x or 1/2x a uinputr_t" << std::endl;
        return 1; }
    return 0;
}
