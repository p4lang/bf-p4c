#include "clot.h"

#include <iostream>
#include <sstream>

#include "lib/exceptions.h"
#include "lib/cstring.h"
#include "ir/json_loader.h"
#include "bf-p4c/phv/phv_fields.h"

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

unsigned Clot::length() const {
    unsigned len = 0;
    for (auto f : all_fields)
        len += f->size;
    BUG_CHECK(len % 8 == 0, "clot not byte aligned?");
    return len / 8;
}

unsigned Clot::offset(const PHV::Field* field) const {
    unsigned offset = 0;
    bool found = false;

    for (auto f : all_fields) {
        if (f == field) {
            found = true;
            break;
        }
        offset += f->size;
    }

    BUG_CHECK(found, "field not in clot");
    return offset / 8;
}

bool Clot::is_phv_field(const PHV::Field* field) const {
    for (auto f : phv_fields)
        if (f == field)
            return true;
    return false;
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

