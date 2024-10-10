#ifndef EXTENSIONS_BF_P4C_PARDE_MATCH_REGISTER_H_
#define EXTENSIONS_BF_P4C_PARDE_MATCH_REGISTER_H_

#include <iostream>
#include "lib/cstring.h"

namespace P4 {

class JSONGenerator;
class JSONLoader;

class MatchRegister {
 public:
    MatchRegister();
    explicit MatchRegister(cstring);

    cstring toString() const;

    bool operator==(const MatchRegister& other) const {
        return name == other.name;
    }

    /// JSON serialization/deserialization.
    void toJSON(JSONGenerator& json) const;
    static MatchRegister fromJSON(JSONLoader& json);

    cstring name;
    size_t  size;
    int     id;

    static int s_id;

    bool operator<(const MatchRegister& other) const {
        if (size < other.size) return true;
        if (other.size < size) return false;
        if (id < other.id) return true;
        if (other.id > id) return false;
        return false;
    }

    friend std::ostream& operator<<(std::ostream& out, const MatchRegister& c);
};

inline std::ostream& operator<<(std::ostream& out, const MatchRegister& c) {
    return out << c.name;
}

}  // namespace P4

#endif /* EXTENSIONS_BF_P4C_PARDE_MATCH_REGISTER_H_ */
