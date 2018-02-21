#include "match_register.h"

#include <sstream>
#include "ir/json_loader.h"

int MatchRegister::g_id = 0;

cstring MatchRegister::toString() const {
    std::stringstream tmp;
    tmp << *this;
    return tmp.str();
}

MatchRegister::MatchRegister(cstring nm)
    : name(nm) {
    // This is a dummy implementation.
    if (nm == "half") {
        size = 2;
    } else {
        size = 1;
    }
    id = ++g_id;
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
