#include "match_register.h"

#include <sstream>
#include "ir/json_loader.h"

cstring MatchRegister::toString() const {
    std::stringstream tmp;
    tmp << *this;
    return tmp.str();
}

MatchRegister::MatchRegister(cstring nm)
    : name(nm) {
    // This is a dummy implementation.
    // TODO(yumin): JBAY use different name and layouts.
    if (nm == "half") {
        size = 2;
        id = 0;
    } else if (nm == "byte0") {
        size = 1;
        id = 2;
    } else if (nm == "byte1") {
        size = 1;
        id = 3;
    }
}

void MatchRegister::toJSON(JSONGenerator& json) const {
    json << *this;
}

/* static */
MatchRegister MatchRegister::fromJSON(JSONLoader& json) {
    if (auto* v = json.json->to<JsonString>())
        return MatchRegister(v->c_str());
    BUG("Couldn't decode JSON value to clot");
    return MatchRegister();
}

std::ostream& operator<<(std::ostream& out, const MatchRegister& c) {
    return out << c.name;
}

JSONGenerator& operator<<(JSONGenerator& out, const MatchRegister& c) {
    return out << c.toString();
}
