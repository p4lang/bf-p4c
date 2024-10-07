#ifndef EXTENSIONS_BF_P4C_COMMON_AUTOINDENT_H_
#define EXTENSIONS_BF_P4C_COMMON_AUTOINDENT_H_

#include "lib/log.h"

/// A RAII helper that indents when it's created and unindents by the same
/// amount when it's destroyed.
/// TODO: This should live in indent.h.
struct AutoIndent {
    explicit AutoIndent(indent_t& indent, int indentBy = 1)
      : indent(indent), indentBy(indentBy) { indent += indentBy; }
    ~AutoIndent() { indent -= indentBy; }

 private:
    indent_t& indent;
    int indentBy;
};

#endif /* EXTENSIONS_BF_P4C_COMMON_AUTOINDENT_H_ */
