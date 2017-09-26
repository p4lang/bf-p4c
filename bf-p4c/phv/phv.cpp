/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "bf-p4c/phv/phv.h"

#include <cstring>
#include <iostream>
#include <sstream>

#include "lib/exceptions.h"
#include "lib/cstring.h"
#include "ir/ir.h"
#include "ir/json_loader.h"

namespace PHV {

Type::Type(Type::TypeEnum te) {
    switch (te) {
        case Type::B:  kind_ = Kind::normal;   size_ = Size::b8;  break;
        case Type::H:  kind_ = Kind::normal;   size_ = Size::b16; break;
        case Type::W:  kind_ = Kind::normal;   size_ = Size::b32; break;
        case Type::TB: kind_ = Kind::tagalong; size_ = Size::b8;  break;
        case Type::TH: kind_ = Kind::tagalong; size_ = Size::b16; break;
        case Type::TW: kind_ = Kind::tagalong; size_ = Size::b32; break;
        default: BUG("Unknown PHV type"); }
}

Type::Type(const char* name) {
    const char* n = name;

    switch (*n) {
        case 'T': kind_ = Kind::tagalong; n++; break;
        default:  kind_ = Kind::normal; }

    switch (*n++) {
        case 'B': size_ = Size::b8;  break;
        case 'H': size_ = Size::b16; break;
        case 'W': size_ = Size::b32; break;
        default: BUG("Invalid PHV type '%s'", name); }

    if (*n)
        BUG("Invalid PHV type '%s'", name);
}

unsigned Type::log2sz() const {  // TODO(zma) get rid of this function
    switch (size_) {
       case Size::b8:   return 0;
       case Size::b16:  return 1;
       case Size::b32:  return 2;
       default: BUG("Called log2sz() on an invalid container");
    }
}

Container::Container(const char *name) {
    const char *n = name + strcspn(name, "0123456789");
    type_ = Type(std::string(name, n - name).c_str());

    char *end = nullptr;
    auto v = strtol(n, &end, 10);
    index_ = v;
    if (end == n || *end || index_ != v)
        BUG("Invalid register '%s'", name);
}

cstring Container::toString() const {
    std::stringstream tmp;
    tmp << *this;
    return tmp.str();
}

/* static */ Container Container::fromJSON(JSONLoader& json) {
    if (auto* v = json.json->to<JsonString>())
        return Container(v->c_str());
    BUG("Couldn't decode JSON value to container");
    return Container();
}

std::ostream& operator<<(std::ostream& out, const PHV::Kind k) {
    switch (k) {
        case PHV::Kind::normal:   return out << "";
        case PHV::Kind::tagalong: return out << "T";
        default:    BUG("Unknown PHV container kind");
    }
}

std::ostream& operator<<(std::ostream& out, const PHV::Size sz) {
    switch (sz) {
        case PHV::Size::b8:  return out << "B";
        case PHV::Size::b16: return out << "H";
        case PHV::Size::b32: return out << "W";
        default:    BUG("Unknown PHV container size");
    }
}

std::ostream& operator<<(std::ostream& out, PHV::Type t) {
    return out << t.kind() << t.size();
}

std::ostream& operator<<(std::ostream& out, const PHV::Container c) {
    return out << c.type() << c.index();
}

JSONGenerator& operator<<(JSONGenerator& out, const PHV::Container c) {
    return out << c.toString();
}

std::ostream& operator<<(std::ostream& out, ordered_set<const PHV::Container *>& c_set) {
    out << "{";
    for (auto &c : c_set) {
        out << *c << ",";
    }
    out << "}";
    return out;
}

}  // namespace PHV
