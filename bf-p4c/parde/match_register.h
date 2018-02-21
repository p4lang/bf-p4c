#ifndef EXTENSIONS_BF_P4C_PARDE_MATCH_REGISTER_H_
#define EXTENSIONS_BF_P4C_PARDE_MATCH_REGISTER_H_

#include <iostream>
#include "lib/cstring.h"

class JSONGenerator;
class JSONLoader;

class MatchRegister {
    static int g_id;

 public:
    MatchRegister() { }
    explicit MatchRegister(cstring);
    MatchRegister(cstring n, size_t s)
        : name(n), size(s) {
        id = ++g_id;
    }

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

    bool operator<(const MatchRegister& other) const {
        // XXX(yumin): If you want to use std::set<T>::count(T) as contains()
        // make sure to compare every field. Otherwise, here A("byte1", 1) B("byte2", 1)
        // will be considered as equal, A < B => false && B < A => false.
        if (name == other.name) {
            return size < other.size; }
        return id < other.id;
    }
};

std::ostream& operator<<(std::ostream& out, const MatchRegister& c);
JSONGenerator& operator<<(JSONGenerator& out, const MatchRegister& c);

#endif /* EXTENSIONS_BF_P4C_PARDE_MATCH_REGISTER_H_ */
