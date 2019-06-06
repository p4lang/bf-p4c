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

void Clot::add_slice(FieldKind kind, const PHV::FieldSlice* slice) {
    auto field = slice->field();

    switch (kind) {
    case MODIFIED:
        phv_fields_.insert(field);
        break;

    case READONLY:
        phv_fields_.insert(field);
        break;

    case CHECKSUM:
        BUG_CHECK(slice->is_whole_field(),
                  "Attempted to allocate checksum slice to CLOT %d: %s",
                  tag,
                  slice->shortString());
        csum_fields_.insert(field);
        break;

    case UNUSED:
        break;
    }

    all_slices_.push_back(slice);
    BUG_CHECK(!fields_to_slices_.count(field), "CLOT %d already has field %s", tag, field->name);
    fields_to_slices_[field] = slice;
}

unsigned Clot::length_in_byte() const {
    unsigned length_in_bits = 0;
    for (auto f : all_slices_)
        length_in_bits += f->range().size();

    BUG_CHECK(length_in_bits % 8 == 0,
              "CLOT %d has %d bits, which is not a whole number of bytes",
              tag, length_in_bits);

    return length_in_bits / 8;
}

unsigned Clot::bit_offset(const PHV::FieldSlice* slice) const {
    // XXX This should really use an std::map<FieldSlice*, unsigned, FieldSlice::Less>, but we
    // can't declare a field of this type, since we don't have access to FieldSlice::Less in clot.h

    unsigned offset = 0;
    for (auto mem : all_slices_) {
        if (PHV::FieldSlice::equal(slice, mem)) return offset;
        offset += mem->range().size();
    }

    BUG("Field %s not in %s", slice->shortString(), toString());
}

unsigned Clot::byte_offset(const PHV::FieldSlice* slice) const {
    return bit_offset(slice) / 8;
}

bool Clot::is_phv_field(const PHV::Field* field) const {
    return phv_fields_.count(field);
}

bool Clot::is_csum_field(const PHV::Field* field) const {
    return csum_fields_.count(field);
}

bool Clot::has_slice(const PHV::FieldSlice* slice) const {
    auto field = slice->field();
    if (!fields_to_slices_.count(field)) return false;
    return PHV::FieldSlice::equal(fields_to_slices_.at(field), slice);
}

bool Clot::is_first_field_in_clot(const PHV::Field* field) const {
    return all_slices_.at(0)->field() == field;
}

void Clot::set_slices(const std::vector<const PHV::FieldSlice*> slices) {
    all_slices_ = slices;

    // Check that all fields in the slices we were given is a subset of the existing fields. At the
    // same time, start fixing up fields_to_slices_.
    std::set<const PHV::Field*> fields;
    for (auto slice : slices) {
        auto field = slice->field();
        BUG_CHECK(fields_to_slices_.count(field),
                  "Found a foreign field %s when setting slices for CLOT %d",
                  field->name, tag);

        fields.insert(field);
        fields_to_slices_[field] = slice;
    }

    // Finish fixing up fields_to_slices_.
    for (auto it = fields_to_slices_.begin(); it != fields_to_slices_.end(); ) {
        if (fields.count(it->first))
          ++it;
        else
          it = fields_to_slices_.erase(it);
    }

    // Fix up phv_fields_.
    for (auto it = phv_fields_.begin(); it != phv_fields_.end(); ) {
        if (fields.count(*it))
            ++it;
        else
            it = phv_fields_.erase(it);
    }

    // Fix up csum_fields_.
    for (auto it = csum_fields_.begin(); it != csum_fields_.end(); ) {
        if (fields.count(*it))
            ++it;
        else
            it = csum_fields_.erase(it);
    }
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
