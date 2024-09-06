#include "marshal.h"
#include "ir/ir.h"

cstring MarshaledFrom::toString() const {
    std::stringstream tmp;
    tmp << *this;
    return tmp.str();
}

void MarshaledFrom::toJSON(JSONGenerator& json) const {
    json << *this;
}

/* static */
MarshaledFrom MarshaledFrom::fromJSON(JSONLoader&) {
    BUG("Uninmplemented");
    return MarshaledFrom();
}

JSONGenerator& operator<<(JSONGenerator& out, const MarshaledFrom& c) {
    return out << c.toString();
}

std::ostream& operator<<(std::ostream& s, const MarshaledFrom& m) {
    s << "(" << m.gress << ", " << m.field_name << ", " << m.pre_padding << ")";
    return s;
}
