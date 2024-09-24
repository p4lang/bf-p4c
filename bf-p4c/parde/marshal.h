#ifndef PARDE_MARSHAL_H_
#define PARDE_MARSHAL_H_

#include <iostream>
#include "lib/cstring.h"
#include "bf-p4c/ir/gress.h"

using namespace P4;

class JSONGenerator;
class JSONLoader;

namespace P4 {

struct MarshaledFrom {
    // use those two to uniquely identify a field.
    gress_t gress;
    cstring field_name;
    /// Here the `pre` and `post` is in network order, which means, on the wire
    /// the oreder is [pre_padding, field, post_padding].
    /// TODO: currently, we do not have post_padding. When we create padding for
    /// those marshalable fields, we append paddings before the field.
    size_t pre_padding;
    // size_t post_padding;

    cstring toString() const;

    bool operator==(const MarshaledFrom& other) const {
        return gress == other.gress && field_name == other.field_name
               && pre_padding == other.pre_padding;
    }

    /// JSON serialization/deserialization.
    void toJSON(JSONGenerator& json) const;
    static MarshaledFrom fromJSON(JSONLoader& json);

    MarshaledFrom()
        : gress(INGRESS), field_name(""), pre_padding(0) { }
    MarshaledFrom(gress_t gress, cstring name)
        : gress(gress), field_name(name), pre_padding(0) { }
    MarshaledFrom(gress_t gress, cstring name, size_t pre_padding)
        : gress(gress), field_name(name), pre_padding(pre_padding) { }
};

std::ostream& operator<<(std::ostream& s, const MarshaledFrom& m);
JSONGenerator& operator<<(JSONGenerator& out, const MarshaledFrom& c);

}  // namespace P4

#endif /* PARDE_MARSHAL_H_ */
