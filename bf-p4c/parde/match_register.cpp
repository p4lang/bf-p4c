#include "match_register.h"

#include <string>
#include <sstream>
#include "ir/ir.h"

cstring MatchRegister::toString() const {
    std::stringstream tmp;
    tmp << *this;
    return tmp.str();
}

MatchRegister::MatchRegister(cstring n) : name(n) {
    std::string str(name);
    if (str.length() < 4)
        BUG("Invalid parser match register '%s'", name);

    if (str.substr(0, 4) == "byte")
        size = 1;
    else if (str.substr(0, 4) == "half")
        size = 2;
    else
        BUG("Invalid parser match register '%s'", name);

    if (str.length() > 4) {
        char* end = nullptr;
        auto v = std::strtol(str.substr(4).c_str(), &end, 10);

        if (*end)
            BUG("Invalid parser match register '%s'", name);

        id = v;
    }
}

void MatchRegister::toJSON(JSONGenerator& json) const {
    json << *this;
}

/* static */
MatchRegister MatchRegister::fromJSON(JSONLoader& json) {
    if (auto* v = json.json->to<JsonString>())
        return MatchRegister(v->c_str());
    BUG("Couldn't decode JSON value to parser match register");
    return MatchRegister();
}

std::ostream& operator<<(std::ostream& out, const MatchRegister& c) {
    return out << c.name;
}

JSONGenerator& operator<<(JSONGenerator& out, const MatchRegister& c) {
    return out << c.toString();
}
