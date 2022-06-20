#ifndef BF_ASM_PARSER_H_
#define BF_ASM_PARSER_H_

#include "target.h"
#include "asm-types.h"
#include "vector.h"
#include "json.h"
#include "sections.h"

/**
 * @brief Base class of Tofino parser in assembler
 *
 * For Tofino 1/2/3, the class Parser is derived and for Flatrock,
 * the class FlatrockParser is derived.
 */
class BaseParser : virtual public Configurable {
 protected:
    int lineno = -1;
};

/**
 * @brief Base class of parser assembly section
 */
class BaseAsmParser : public Section {
 public:
    explicit BaseAsmParser(const char *name_) : Section(name_) {}
};

#endif /* BF_ASM_PARSER_H_ */
