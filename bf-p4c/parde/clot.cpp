#include "clot.h"

#include <iostream>
#include <sstream>

#include "lib/exceptions.h"
#include "lib/cstring.h"
#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"

int Clot::tagCnt = 0;

cstring Clot::toString() const {
    std::stringstream tmp;
    tmp << *this;
    return tmp.str();
}

Clot::Clot(cstring name) {
    std::string str(name);

    if (str.length() <= 5 || str.substr(0, 4) != "clot" || !isdigit(str[5]))
        BUG("Invalid clot '%s'", name);

    char* end = nullptr;
    auto v = std::strtol(str.substr(5).c_str(), &end, 10);

    if (*end)
        BUG("Invalid clot '%s'", name);

    tag = v;
}

unsigned Clot::length_in_bits() const {
    unsigned rv = 0;
    for (auto f : all_fields)
        rv += f->size;
    return rv;
}

unsigned Clot::length_in_bytes() const {
    BUG_CHECK(length_in_bits() % 8 == 0, "clot not byte aligned?");
    return length_in_bits() / 8;
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

bool Clot::is_csum_field(const PHV::Field* field) const {
    for (auto f : csum_fields)
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
    return out << "clot " << c.tag;
}

JSONGenerator& operator<<(JSONGenerator& out, const Clot c) {
    return out << c.toString();
}
