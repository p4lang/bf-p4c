#include "marshal.h"
#include "ir/ir.h"

std::string MarshaledFrom::toString() const {
    std::stringstream tmp;
    tmp << *this;
    return tmp.str();
}

void MarshaledFrom::toJSON(P4::JSONGenerator& json) const {
    json << *this;
}

/* static */
MarshaledFrom MarshaledFrom::fromJSON(P4::JSONLoader&) {
    BUG("Uninmplemented");
    return MarshaledFrom();
}
