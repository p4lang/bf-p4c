#ifndef EXTENSIONS_BF_P4C_COMMON_UTILS_H_
#define EXTENSIONS_BF_P4C_COMMON_UTILS_H_

#include <iostream>
#include "lib/error_catalog.h"
#include "lib/exceptions.h"
#include "lib/gc.h"
#include "ir/ir.h"

#if defined(__GNUC__) && __GNUC__ < 7
#define BFN_FALLTHROUGH /* fall through */
#define BFN_MAYBE_UNUSED __attribute__((unused))
#else
#define BFN_FALLTHROUGH [[fallthrough]]
#define BFN_MAYBE_UNUSED [[maybe_unused]]
#endif

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

#ifdef BAREFOOT_INTERNAL
#define INTERNAL_WARNING(...)   warning(ErrorType::WARN_UNSUPPORTED, __VA_ARGS__)
#else
#define INTERNAL_WARNING(...)   BUG(__VA_ARGS__)
#endif


/// Check if ghost control is present on any pipes other than current pipe given
/// by pipe_id argument
bool ghost_only_on_other_pipes(int pipe_id);

/// Separate out key and mask from an input key string
/// Input: "vrf & 0xff0f", Output: std::pair<"vrf", "0xff0f">
std::pair<cstring, cstring> get_key_and_mask(const cstring &input);

const IR::Vector<IR::Expression>* getListExprComponents(const IR::Node& node);

#endif /* EXTENSIONS_BF_P4C_COMMON_UTILS_H_ */
