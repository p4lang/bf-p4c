#include "clot.h"

#include <algorithm>
#include <iostream>
#include <sstream>

#include "lib/exceptions.h"
#include "lib/cstring.h"
#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"

std::map<gress_t, int> Clot::tagCnt;

cstring Clot::toString() const {
    std::stringstream tmp;
    tmp << "clot " << gress << "::" << tag;
    return tmp.str();
}

Clot::Clot(cstring name) {
    std::string str(name);

    // Ensure we have the "clot " prefix.
    if (str.length() <= 5 || str.substr(0, 5) != "clot ")
        BUG("Invalid CLOT: '%s'", name);

    // Ensure we have the "::" separator, and that it is immediately followed with a digit.
    auto identifier = str.substr(5);
    auto sep_pos = identifier.find("::");

    BUG_CHECK(sep_pos != std::string::npos &&
              identifier.length() > sep_pos + 2 &&
              isdigit(identifier[sep_pos + 2]),
        "Invalid CLOT: '%s'", name);

    // Parse out the gress.
    gress_t g;
    BUG_CHECK(identifier.substr(0, sep_pos) >> g, "Invalid CLOT: '%s'", name);

    // Parse out the CLOT id.
    char* end = nullptr;
    auto v = std::strtol(identifier.substr(sep_pos + 2).c_str(), &end, 10);
    if (*end) BUG("Invalid CLOT: '%s'", name);

    gress = g;
    tag = v;
}

void Clot::add_field(FieldKind kind,
                     const PHV::Field* field,
                     unsigned offset) {
    switch (kind) {
    case MODIFIED:
        phv_fields_.insert(field);
        phv_modified_fields_.insert(field);
        break;

    case READONLY:
        phv_fields_.insert(field);
        break;

    case CHECKSUM:
        csum_fields_.insert(field);
        break;

    case UNUSED:
        break;
    }

    all_fields_.push_back(field);
    field_offsets[field] = offset;
}

unsigned Clot::bit_offset(const PHV::Field* field) const {
    BUG_CHECK(field_offsets.count(field), "field %s not in %s", field->name, toString());
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
    return phv_fields_.count(field);
}

bool Clot::is_csum_field(const PHV::Field* field) const {
    return csum_fields_.count(field);
}

bool Clot::has_field(const PHV::Field* field) const {
    return contains(all_fields_, field);
}

void Clot::crop(int start_idx, int end_idx) {
    int num_fields = all_fields_.size();

    if (start_idx == 0 && end_idx == num_fields - 1)
        // Nothing to do.
        return;

    // Collect up the fields we're keeping, while removing the rest from auxiliary data structures
    // and computing the new start offset.
    std::vector<const PHV::Field*> all_fields;
    unsigned start_bits = this->start * 8;
    for (int idx = 0; idx < num_fields; idx++) {
        auto field = all_fields_.at(idx);
        if (start_idx <= idx && idx <= end_idx) {
            all_fields.push_back(field);
        } else {
            if (idx < start_idx) start_bits += field->size;
            phv_modified_fields_.erase(field);
            field_offsets.erase(field);
        }
    }

    // Fix up the CLOT's list of fields and the start offset.
    BUG_CHECK(start_bits % 8 == 0,
              "CLOT %d is not byte-aligned after adjustment: resulting offset is %d",
              tag, start_bits);
    start = start_bits / 8;
    all_fields_ = all_fields;
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
