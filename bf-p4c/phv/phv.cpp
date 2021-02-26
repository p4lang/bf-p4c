#include "bf-p4c/phv/phv.h"

#include <cstring>
#include <iostream>
#include <sstream>

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
        case Type::MB: kind_ = Kind::mocha;    size_ = Size::b8;  break;
        case Type::MH: kind_ = Kind::mocha;    size_ = Size::b16; break;
        case Type::MW: kind_ = Kind::mocha;    size_ = Size::b32; break;
        case Type::DB: kind_ = Kind::dark;     size_ = Size::b8;  break;
        case Type::DH: kind_ = Kind::dark;     size_ = Size::b16; break;
        case Type::DW: kind_ = Kind::dark;     size_ = Size::b32; break;
        default: BUG("Unknown PHV type"); }
}

Type::Type(const char* name, bool abort_if_invalid) {
    const char* n = name;

    switch (*n) {
        case 'T': kind_ = Kind::tagalong; n++; break;
        case 'M': kind_ = Kind::mocha;    n++; break;
        case 'D': kind_ = Kind::dark;     n++; break;
        default:  kind_ = Kind::normal; }

    switch (*n++) {
        case 'B': size_ = Size::b8;  break;
        case 'H': size_ = Size::b16; break;
        case 'W': size_ = Size::b32; break;
        default:
            size_ = Size::null;
            if (abort_if_invalid)
                BUG("Invalid PHV type '%s'", name); }

    if (*n && abort_if_invalid)
        BUG("Invalid PHV type '%s'", name);
}

unsigned Type::log2sz() const {
    switch (size_) {
       case Size::b8:   return 0;
       case Size::b16:  return 1;
       case Size::b32:  return 2;
       default: BUG("Called log2sz() on an invalid container");
    }
}

cstring Type::toString() const {
    std::stringstream tmp;
    tmp << *this;
    return tmp.str();
}

Container::Container(const char *name, bool abort_if_invalid) {
    const char *n = name + strcspn(name, "0123456789");
    type_ = Type(std::string(name, n - name).c_str(), abort_if_invalid);

    char *end = nullptr;
    auto v = strtol(n, &end, 10);
    index_ = v;
    if (end == n || *end || index_ != static_cast<unsigned long>(v)) {
        type_ = Type();
        if (abort_if_invalid)
            BUG("Invalid register '%s'", name); }
}

cstring Container::toString() const {
    std::stringstream tmp;
    tmp << *this;
    return tmp.str();
}

void Container::toJSON(JSONGenerator& json) const {
    json << *this;
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
        case PHV::Kind::mocha:    return out << "M";
        case PHV::Kind::dark:     return out << "D";
        default:    BUG("Unknown PHV container kind");
    }
}

std::ostream& operator<<(std::ostream& out, const PHV::Size sz) {
    switch (sz) {
        case PHV::Size::b8:  return out << "B";
        case PHV::Size::b16: return out << "H";
        case PHV::Size::b32: return out << "W";
        default:             return out << "null";
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

std::ostream& operator<<(std::ostream& out, const PHV::FieldUse u) {
    return out << u.toString();
}

std::ostream& operator<<(std::ostream& out, const StageAndAccess s) {
    return out << " [ " << s.first << ", " << s.second << "] ";
}

}  // namespace PHV
