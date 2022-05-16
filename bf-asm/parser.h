#ifndef BF_ASM_PARSER_H_
#define BF_ASM_PARSER_H_

#include "target.h"
#include "asm-types.h"
#include "vector.h"
#include "json.h"
#include "sections.h"

class BaseParser : virtual public Configurable {
 protected:
    int lineno = -1;
};

class BaseAsmParser : public Section {
 public:
    explicit BaseAsmParser(const char *name_) : Section(name_) {}
};

#endif /* BF_ASM_PARSER_H_ */
