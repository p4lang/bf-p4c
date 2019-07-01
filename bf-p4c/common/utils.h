#ifndef EXTENSIONS_BF_P4C_COMMON_UTILS_H_
#define EXTENSIONS_BF_P4C_COMMON_UTILS_H_

#include <iostream>
#include "lib/error_catalog.h"
#include "lib/exceptions.h"
#include "lib/gc.h"
#include "ir/ir.h"

struct DumpPipe : public Inspector {
    const char *heading;
    DumpPipe() : heading(nullptr) {}
    explicit DumpPipe(const char *h) : heading(h) {}
#if BAREFOOT_INTERNAL
    bool preorder(const IR::Node *pipe) override {
        if (LOGGING(1)) {
            if (heading) {
                std::cout << "-------------------------------------------------" << std::endl
                          << heading << std::endl
                          << "-------------------------------------------------" << std::endl;
                size_t maxMem = 0;
                size_t memUsed = gc_mem_inuse(&maxMem)/(1024*1024);
                maxMem = maxMem/(1024*1024);
                std::cout << "*** mem in use = " << memUsed << "MB, heap size = "
                          << maxMem << "MB" << std::endl;
            }
            if (LOGGING(2))
                dump(pipe);
            else
                std::cout << *pipe << std::endl;
        }
        return false;
    }
#endif  // BAREFOOT_INTERNAL
};


/// Report an error with the given message and exit.
template <typename... T>
inline void fatal_error(const char* format, T... args) {
    ::error(format, args...);
    throw Util::CompilationError("Compilation failed!");
}

/// Report an error with the error type and given message and exit.
template <typename... T>
inline void fatal_error(int kind, const char* format, T... args) {
    ::error(kind, format, args...);
    throw Util::CompilationError("Compilation failed!");
}


#endif /* EXTENSIONS_BF_P4C_COMMON_UTILS_H_ */
