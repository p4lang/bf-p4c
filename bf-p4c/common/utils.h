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
    bool preorder(const IR::Node *pipe) override;
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