#include "marshal.h"
#include "ir/ir.h"

std::string MarshaledFrom::toString() const {
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
