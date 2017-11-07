#include "clot.h"

#include <iostream>
#include <sstream>
#include "lib/exceptions.h"

int Clot::tagCnt = 0;

cstring Clot::toString() const {
    std::stringstream tmp;
    tmp << *this;
    return tmp.str();
}

Clot::Clot(cstring name) {
    std::string str(name);

    if (str.length() <= 4 || str.substr(0, 4) != "CLOT" || !isdigit(str[4]))
        BUG("Invalid CLOT '%s'", name);

    char* end = nullptr;
    auto v = std::strtol(str.substr(4).c_str(), &end, 10);

    if (*end)
        BUG("Invalid CLOT '%s'", name);

    tag = v;
}

void Clot::toJSON(JSONGenerator& json) const {
    json << *this;
}

/* static */ Clot Clot::fromJSON(JSONLoader& json) {
    if (auto* v = json.json->to<JsonString>())
        return Clot(v->c_str());
    BUG("Couldn't decode JSON value to clot");
    return Clot();
}

std::ostream& operator<<(std::ostream& out, const Clot c) {
    return out << "CLOT" << c.tag;
}

JSONGenerator& operator<<(JSONGenerator& out, const Clot c) {
    return out << c.toString();
}

