#ifndef EXTENSIONS_BF_P4C_LIB_LOG_FIXUP_H_
#define EXTENSIONS_BF_P4C_LIB_LOG_FIXUP_H_

#include "lib/log.h"

class logfix {
    std::string text;
    friend std::ostream &operator<<(std::ostream &out, const logfix &lf) {
        bool newline = false;
        for (char ch : lf.text) {
            if (newline) out << Log::endl;
            if (!(newline = ch == '\n')) out << ch;
        }
        return out;
    }
 public:
    explicit logfix(std::string s) : text(s) {}
    explicit logfix(const std::stringstream &ss) : text(ss.str()) {}
};

#endif  /* EXTENSIONS_BF_P4C_LIB_LOG_FIXUP_H_ */
