#include "clot.h"

#include <algorithm>
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

void Clot::add_field(FieldKind kind, const PHV::Field* field, unsigned offset) {
    switch (kind) {
    case PHV:
        phv_fields_.push_back(field);
        break;

    case CHECKSUM:
        csum_fields_.push_back(field);
        break;

    case OTHER:
        break;
    }

    all_fields_.push_back(field);
    field_offsets[field] = offset;
}

unsigned Clot::bit_offset(const PHV::Field* field) const {
    BUG_CHECK(field_offsets.count(field), "field %s not in CLOT %d", field->name, tag);
    return field_offsets.at(field);
}

unsigned Clot::byte_offset(const PHV::Field* field) const {
    return bit_offset(field) / 8;
}

template <class T> bool contains(const std::vector<T> vec, const T elt) {
    // Assumes == operator is appropriately defined for T.
    return std::find(vec.begin(), vec.end(), elt) != vec.end();
}

bool Clot::is_phv_field(const PHV::Field* field) const {
    return contains(phv_fields_, field);
}

bool Clot::is_csum_field(const PHV::Field* field) const {
    return contains(csum_fields_, field);
}

bool Clot::has_field(const PHV::Field* field) const {
    return field_offsets.count(field);
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
