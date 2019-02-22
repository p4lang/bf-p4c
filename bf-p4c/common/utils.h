#ifndef EXTENSIONS_BF_P4C_COMMON_UTILS_H_
#define EXTENSIONS_BF_P4C_COMMON_UTILS_H_

#include <iostream>
#include "lib/exceptions.h"

struct DumpPipe : public Inspector {
    const char *heading;
    DumpPipe() : heading(nullptr) {}
    explicit DumpPipe(const char *h) : heading(h) {}
#if BAREFOOT_INTERNAL
    bool preorder(const IR::Node *pipe) override {
        if (LOGGING(1)) {
            if (heading)
                std::cout << "-------------------------------------------------" << std::endl
                          << heading << std::endl
                          << "-------------------------------------------------" << std::endl;
            if (LOGGING(2))
                dump(pipe);
            else
                std::cout << *pipe << std::endl; }
        return false; }
#endif  // BAREFOOT_INTERNAL
};


/// Report an error with the given message and exit.
template <typename... T>
inline void fatal_error(const char* format, T... args) {
    ::error(format, args...);
    throw Util::CompilationError("Compilation failed!");
}


#endif /* EXTENSIONS_BF_P4C_COMMON_UTILS_H_ */
